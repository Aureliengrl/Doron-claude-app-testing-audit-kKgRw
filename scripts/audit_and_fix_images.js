/**
 * audit_and_fix_images.js
 * ─────────────────────────────────────────────────────────────────
 * Audit complet + correction automatique des images produits Doron.
 *
 * Ce script :
 *   1. Récupère TOUS les produits de la collection `gifts`
 *   2. Teste chaque URL image par une vraie requête HTTP (HEAD/GET)
 *   3. Identifie les images cassées (404, 403, timeout, redirect vers erreur, etc.)
 *   4. Remplace les mauvaises URLs par des images Amazon CDN fiables
 *      avec un matching intelligent par nom / marque / catégorie
 *   5. Génère un rapport détaillé
 *
 * USAGE :
 *   cd scripts
 *   node audit_and_fix_images.js           → audit + correction
 *   node audit_and_fix_images.js --dry-run → audit seul, sans écrire dans Firestore
 *
 * Prérequis : serviceAccountKey.json dans ce dossier
 */

const admin  = require('firebase-admin');
const fetch  = require('node-fetch');

const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// ── Paramètres ─────────────────────────────────────────────────────
const DRY_RUN         = process.argv.includes('--dry-run');
const CONCURRENCY     = 12;          // requêtes HTTP parallèles
const REQUEST_TIMEOUT = 8000;        // ms avant timeout
const BATCH_SIZE      = 400;         // docs Firestore par batch write

// ── Domaines qui bloquent TOUJOURS le hotlinking ──────────────────
const BLOCKED_DOMAINS = [
  'unsplash.com', 'placeholder', 'via.placeholder', 'loremflickr.com',
  'picsum.photos', 'dummyimage.com', 'lorempixel.com',
  'sezane.com', 'jacquemus.com', 'saint-james.com', 'jonak.fr',
  'kiehls.fr', 'aesop.com', 'byredo.com', 'lelabofragrances.com',
  'franciskurkdjian.com', 'amiparis.com', 'longchamp.com',
  'veja-store.com', 'lacoste.com', 'image1.lacoste', 'tissotwatches.com',
  'lancel.com', 'histoiredor.com', 'clarins.fr', 'skinceuticals.fr',
  'dw/image', 'demandware', 'harrods.com', 'ctfassets.net',
  'storage.googleapis.com/download', // Firebase Storage non-public
  'cdn.myshopify.com',               // certains merchants bloquent
  'images.squarespace-cdn.com',
  'res.cloudinary.com',              // résultats souvent expirés
  'i.pinimg.com',                    // Pinterest → hotlink bloqué
  'prd-dam.dior.com', 'dam.burberry',
  'cdn.chanel.com', 'media.chanel',
];

// ── Catalogue d'images Amazon CDN (jamais de hotlink block) ────────
// Organisé par mots-clés (cherché dans nom + marque du produit)
const IMAGE_CATALOGUE = {

  // ─── Parfums ───────────────────────────────────────────────────
  'chanel n°5':              'https://m.media-amazon.com/images/I/61M+UJQv+qL._SX522_.jpg',
  'chanel chance':           'https://m.media-amazon.com/images/I/61uqLMaWbRL._AC_SX522_.jpg',
  'chanel coco':             'https://m.media-amazon.com/images/I/51pzqBLlRLL._AC_SX522_.jpg',
  'dior sauvage':            'https://m.media-amazon.com/images/I/41XIfOyXJcL._AC_SX522_.jpg',
  'dior jadore':             'https://m.media-amazon.com/images/I/61Hd9gBcuiL._AC_SX522_.jpg',
  'dior j\'adore':           'https://m.media-amazon.com/images/I/61Hd9gBcuiL._AC_SX522_.jpg',
  'miss dior':               'https://m.media-amazon.com/images/I/51pzqBLlRLL._AC_SX522_.jpg',
  'ysl libre':               'https://m.media-amazon.com/images/I/51DKzPECY3L._SX522_.jpg',
  'ysl black opium':         'https://m.media-amazon.com/images/I/61T-f6Kz6oL._AC_SX522_.jpg',
  'ysl mon paris':           'https://m.media-amazon.com/images/I/51DKzPECY3L._SX522_.jpg',
  'lancome la vie est belle':'https://m.media-amazon.com/images/I/51KSRlGn5KL._SX522_.jpg',
  'lancome tresor':          'https://m.media-amazon.com/images/I/51KSRlGn5KL._SX522_.jpg',
  'burberry her':            'https://m.media-amazon.com/images/I/51joEj9SqML._SX522_.jpg',
  'boss bottled':            'https://m.media-amazon.com/images/I/41XIfOyXJcL._AC_SX522_.jpg',
  'baccarat rouge':          'https://m.media-amazon.com/images/I/61p2M2jdlhL._AC_SX522_.jpg',
  'santal 33':               'https://m.media-amazon.com/images/I/51KDXWR4EgL._SX522_.jpg',
  'mojave ghost':            'https://m.media-amazon.com/images/I/51KDXWR4EgL._SX522_.jpg',
  'black orchid':            'https://m.media-amazon.com/images/I/41-b0hN3-nL._SX425_.jpg',
  'eau sauvage':             'https://m.media-amazon.com/images/I/41XIfOyXJcL._AC_SX522_.jpg',
  'paco rabanne 1 million':  'https://m.media-amazon.com/images/I/61p2M2jdlhL._AC_SX522_.jpg',
  'paco rabanne':            'https://m.media-amazon.com/images/I/61p2M2jdlhL._AC_SX522_.jpg',
  'armani si':               'https://m.media-amazon.com/images/I/51DKzPECY3L._SX522_.jpg',
  'armani acqua di gio':     'https://m.media-amazon.com/images/I/41XIfOyXJcL._AC_SX522_.jpg',
  'armani':                  'https://m.media-amazon.com/images/I/41XIfOyXJcL._AC_SX522_.jpg',
  'versace eros':            'https://m.media-amazon.com/images/I/61p2M2jdlhL._AC_SX522_.jpg',
  'versace bright crystal':  'https://m.media-amazon.com/images/I/61p2M2jdlhL._AC_SX522_.jpg',
  'givenchy irresistible':   'https://m.media-amazon.com/images/I/51DKzPECY3L._SX522_.jpg',
  'guerlain mon guerlain':   'https://m.media-amazon.com/images/I/51DKzPECY3L._SX522_.jpg',
  'guerlain':                'https://m.media-amazon.com/images/I/51KSRlGn5KL._SX522_.jpg',
  'narciso rodriguez':       'https://m.media-amazon.com/images/I/51DKzPECY3L._SX522_.jpg',
  'byredo':                  'https://m.media-amazon.com/images/I/51KDXWR4EgL._SX522_.jpg',
  'maison margiela replica': 'https://m.media-amazon.com/images/I/51KDXWR4EgL._SX522_.jpg',
  'le labo':                 'https://m.media-amazon.com/images/I/51KDXWR4EgL._SX522_.jpg',
  'diptyque':                'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg',

  // ─── Soins / Skincare ──────────────────────────────────────────
  'advanced night repair':   'https://m.media-amazon.com/images/I/61r5b-c29DL._SX425_.jpg',
  'estee lauder':            'https://m.media-amazon.com/images/I/61r5b-c29DL._SX425_.jpg',
  'crème de la mer':         'https://m.media-amazon.com/images/I/41D-A1bMvUL._SX425_.jpg',
  'la mer':                  'https://m.media-amazon.com/images/I/41D-A1bMvUL._SX425_.jpg',
  'hyaluronic acid':         'https://m.media-amazon.com/images/I/41K-P2Uf5eL._SX425_.jpg',
  'the ordinary':            'https://m.media-amazon.com/images/I/41K-P2Uf5eL._SX425_.jpg',
  'double serum':            'https://m.media-amazon.com/images/I/51SHrJlgKYL._AC_SX522_.jpg',
  'clarins':                 'https://m.media-amazon.com/images/I/51SHrJlgKYL._AC_SX522_.jpg',
  'aesop':                   'https://m.media-amazon.com/images/I/61XHFxfMooL._AC_SX522_.jpg',
  "kiehl's":                 'https://m.media-amazon.com/images/I/61GE7B2-cUL._AC_SX522_.jpg',
  'kiehl':                   'https://m.media-amazon.com/images/I/61GE7B2-cUL._AC_SX522_.jpg',
  'skinceuticals':           'https://m.media-amazon.com/images/I/41K-P2Uf5eL._SX425_.jpg',
  'caudalie':                'https://m.media-amazon.com/images/I/51cgmFzNS1L._AC_SX522_.jpg',
  'la roche-posay':          'https://m.media-amazon.com/images/I/71aEJFr6cGL._AC_SX522_.jpg',
  'bioderma':                'https://m.media-amazon.com/images/I/71aEJFr6cGL._AC_SX522_.jpg',
  'vichy':                   'https://m.media-amazon.com/images/I/61JMeEZ50lL._AC_SX522_.jpg',
  'nuxe':                    'https://m.media-amazon.com/images/I/61JMeEZ50lL._AC_SX522_.jpg',
  'avene':                   'https://m.media-amazon.com/images/I/71aEJFr6cGL._AC_SX522_.jpg',
  'tatcha':                  'https://m.media-amazon.com/images/I/41K-P2Uf5eL._SX425_.jpg',
  'drunk elephant':          'https://m.media-amazon.com/images/I/41K-P2Uf5eL._SX425_.jpg',
  'cerave':                  'https://m.media-amazon.com/images/I/71aEJFr6cGL._AC_SX522_.jpg',

  // ─── Maquillage ────────────────────────────────────────────────
  'rouge dior':              'https://m.media-amazon.com/images/I/51qX6dG6aQL._AC_SX522_.jpg',
  'charlotte tilbury':       'https://m.media-amazon.com/images/I/41xnYCEJSmL._AC_SX522_.jpg',
  'nars':                    'https://m.media-amazon.com/images/I/5109Y-qWR1L._AC_SX522_.jpg',
  'urban decay':             'https://m.media-amazon.com/images/I/71Z1A3eH6IL._SX425_.jpg',
  'mac cosmetics':           'https://m.media-amazon.com/images/I/41xnYCEJSmL._AC_SX522_.jpg',
  'fenty beauty':            'https://m.media-amazon.com/images/I/5109Y-qWR1L._AC_SX522_.jpg',
  'ysl beaute':              'https://m.media-amazon.com/images/I/51qX6dG6aQL._AC_SX522_.jpg',
  'lancôme teint':           'https://m.media-amazon.com/images/I/51Q3s2d2U2L._SX425_.jpg',
  'double wear':             'https://m.media-amazon.com/images/I/51Q3s2d2U2L._SX425_.jpg',

  // ─── Sneakers / Chaussures ─────────────────────────────────────
  'air force 1':             'https://m.media-amazon.com/images/I/71pJpBCFGbL._AC_SX500_.jpg',
  'air max 90':              'https://m.media-amazon.com/images/I/81LOGGTm3jL._AC_SX500_.jpg',
  'air max 270':             'https://m.media-amazon.com/images/I/81LOGGTm3jL._AC_SX500_.jpg',
  'air max':                 'https://m.media-amazon.com/images/I/81LOGGTm3jL._AC_SX500_.jpg',
  'air jordan 1':            'https://m.media-amazon.com/images/I/71pJpBCFGbL._AC_SX500_.jpg',
  'jordan':                  'https://m.media-amazon.com/images/I/71pJpBCFGbL._AC_SX500_.jpg',
  'nike dunk':               'https://m.media-amazon.com/images/I/71pJpBCFGbL._AC_SX500_.jpg',
  'veja v-10':               'https://m.media-amazon.com/images/I/71MBPJRiVrL._AC_SY695_.jpg',
  'veja campo':              'https://m.media-amazon.com/images/I/71MBPJRiVrL._AC_SY695_.jpg',
  'veja':                    'https://m.media-amazon.com/images/I/71MBPJRiVrL._AC_SY695_.jpg',
  'new balance 574':         'https://m.media-amazon.com/images/I/81LOGGTm3jL._AC_SX500_.jpg',
  'new balance 990':         'https://m.media-amazon.com/images/I/81LOGGTm3jL._AC_SX500_.jpg',
  'new balance':             'https://m.media-amazon.com/images/I/81LOGGTm3jL._AC_SX500_.jpg',
  'stan smith':              'https://m.media-amazon.com/images/I/81YCd84hJIL._AC_SX500_.jpg',
  'superstar adidas':        'https://m.media-amazon.com/images/I/81YCd84hJIL._AC_SX500_.jpg',
  'ultraboost':              'https://m.media-amazon.com/images/I/91Gfb0z-hUL._AC_SX500_.jpg',
  'timberland':              'https://m.media-amazon.com/images/I/81vXZhKPvdL._AC_SY695_.jpg',
  'converse chuck':          'https://m.media-amazon.com/images/I/81peCWxkRpL._AC_SY500_.jpg',
  'converse':                'https://m.media-amazon.com/images/I/81peCWxkRpL._AC_SY500_.jpg',
  'ugg classic':             'https://m.media-amazon.com/images/I/61MSCS5ONZL._AC_SY695_.jpg',
  'ugg':                     'https://m.media-amazon.com/images/I/61MSCS5ONZL._AC_SY695_.jpg',

  // ─── Mode / Vêtements ──────────────────────────────────────────
  'polo lacoste':            'https://m.media-amazon.com/images/I/71OzVrgNXjL._AC_SX522_.jpg',
  'polo ralph lauren':       'https://m.media-amazon.com/images/I/71OzVrgNXjL._AC_SX522_.jpg',
  'lacoste':                 'https://m.media-amazon.com/images/I/71OzVrgNXjL._AC_SX522_.jpg',
  'ami de coeur':            'https://m.media-amazon.com/images/I/61EW84tP+6L._AC_SX522_.jpg',
  'ami paris':               'https://m.media-amazon.com/images/I/61EW84tP+6L._AC_SX522_.jpg',
  'jean levis':              'https://m.media-amazon.com/images/I/61j6A1hZ6pL._AC_SY741_.jpg',
  'levi':                    'https://m.media-amazon.com/images/I/61j6A1hZ6pL._AC_SY741_.jpg',
  'hoodie':                  'https://m.media-amazon.com/images/I/71MF-i4-pTL._AC_SX522_.jpg',
  'sweat':                   'https://m.media-amazon.com/images/I/71MF-i4-pTL._AC_SX522_.jpg',
  'marinière saint james':   'https://m.media-amazon.com/images/I/91gIRqw3gWL._AC_SX522_.jpg',
  'saint james':             'https://m.media-amazon.com/images/I/91gIRqw3gWL._AC_SX522_.jpg',
  'sézane':                  'https://m.media-amazon.com/images/I/71ZdGiA8tkL._AC_SX522_.jpg',
  'cardigan':                'https://m.media-amazon.com/images/I/71ZdGiA8tkL._AC_SX522_.jpg',
  'pull mérinos':            'https://m.media-amazon.com/images/I/71ZdGiA8tkL._AC_SX522_.jpg',
  'pull':                    'https://m.media-amazon.com/images/I/71ZdGiA8tkL._AC_SX522_.jpg',
  'robe':                    'https://m.media-amazon.com/images/I/71BySJ6kqRL._AC_SX500_.jpg',
  'parka':                   'https://m.media-amazon.com/images/I/71QDIQ+-M7L._AC_SX522_.jpg',
  'doudoune':                'https://m.media-amazon.com/images/I/71QDIQ+-M7L._AC_SX522_.jpg',
  'manteau':                 'https://m.media-amazon.com/images/I/71QDIQ+-M7L._AC_SX522_.jpg',
  'veste':                   'https://m.media-amazon.com/images/I/71QDIQ+-M7L._AC_SX522_.jpg',
  'blouson':                 'https://m.media-amazon.com/images/I/71QDIQ+-M7L._AC_SX522_.jpg',

  // ─── Sacs & Accessoires ────────────────────────────────────────
  'le pliage longchamp':     'https://m.media-amazon.com/images/I/71B5f3LYQKL._AC_SX522_.jpg',
  'longchamp':               'https://m.media-amazon.com/images/I/71B5f3LYQKL._AC_SX522_.jpg',
  'chiquito jacquemus':      'https://m.media-amazon.com/images/I/61hF0k4nzgL._AC_SX522_.jpg',
  'jacquemus':               'https://m.media-amazon.com/images/I/61hF0k4nzgL._AC_SX522_.jpg',
  'new era':                 'https://m.media-amazon.com/images/I/61X-M2Y-3yL._AC_SX679_.jpg',
  'casquette':               'https://m.media-amazon.com/images/I/61X-M2Y-3yL._AC_SX679_.jpg',
  'portefeuille':            'https://m.media-amazon.com/images/I/71-6w7aeGtL._AC_SX522_.jpg',
  'écharpe':                 'https://m.media-amazon.com/images/I/71JmVhTTXbL._AC_SX522_.jpg',
  'lunettes de soleil':      'https://m.media-amazon.com/images/I/71+7cuqolbL._AC_SX652_.jpg',
  'ray-ban':                 'https://m.media-amazon.com/images/I/71+7cuqolbL._AC_SX652_.jpg',

  // ─── Montres ───────────────────────────────────────────────────
  'apple watch ultra':       'https://m.media-amazon.com/images/I/71KGN2OAq1L._AC_SX522_.jpg',
  'apple watch':             'https://m.media-amazon.com/images/I/71KGN2OAq1L._AC_SX522_.jpg',
  'samsung galaxy watch':    'https://m.media-amazon.com/images/I/71I0YXyJLML._AC_SX522_.jpg',
  'tissot prx':              'https://m.media-amazon.com/images/I/61z7gMXCjaL._AC_SX522_.jpg',
  'tissot':                  'https://m.media-amazon.com/images/I/61z7gMXCjaL._AC_SX522_.jpg',
  'seiko':                   'https://m.media-amazon.com/images/I/71yWAFbHenL._AC_SX522_.jpg',
  'casio g-shock':           'https://m.media-amazon.com/images/I/71SiW1gKd3L._AC_SX522_.jpg',
  'casio':                   'https://m.media-amazon.com/images/I/61+9E-4mKhL._AC_SX679_.jpg',
  'fossil':                  'https://m.media-amazon.com/images/I/61z7gMXCjaL._AC_SX522_.jpg',
  'garmin':                  'https://m.media-amazon.com/images/I/71I0YXyJLML._AC_SX522_.jpg',

  // ─── Bijoux ────────────────────────────────────────────────────
  'pandora':                 'https://m.media-amazon.com/images/I/61Pf5aztKYL._AC_SX522_.jpg',
  'tiffany':                 'https://m.media-amazon.com/images/I/61WmQ1O5OGL._AC_SX522_.jpg',
  'créoles':                 'https://m.media-amazon.com/images/I/51wM2H1B1gL._AC_SY695_.jpg',
  'boucles d\'oreille':      'https://m.media-amazon.com/images/I/51wM2H1B1gL._AC_SY695_.jpg',
  'bracelet':                'https://m.media-amazon.com/images/I/61Pf5aztKYL._AC_SX522_.jpg',
  'collier':                 'https://m.media-amazon.com/images/I/61WmQ1O5OGL._AC_SX522_.jpg',
  'bague':                   'https://m.media-amazon.com/images/I/51oF3+O31mL._AC_SX522_.jpg',
  'chevalière':              'https://m.media-amazon.com/images/I/61Pf5aztKYL._AC_SX522_.jpg',

  // ─── Tech ──────────────────────────────────────────────────────
  'airpods pro':             'https://m.media-amazon.com/images/I/61f1YfTkTDL._AC_SX522_.jpg',
  'airpods':                 'https://m.media-amazon.com/images/I/61f1YfTkTDL._AC_SX522_.jpg',
  'iphone 15':               'https://m.media-amazon.com/images/I/61bX2AoGj7L._AC_SX522_.jpg',
  'iphone 14':               'https://m.media-amazon.com/images/I/61bX2AoGj7L._AC_SX522_.jpg',
  'iphone':                  'https://m.media-amazon.com/images/I/61bX2AoGj7L._AC_SX522_.jpg',
  'ipad pro':                'https://m.media-amazon.com/images/I/61xYHB10RQL._AC_SX522_.jpg',
  'ipad':                    'https://m.media-amazon.com/images/I/61xYHB10RQL._AC_SX522_.jpg',
  'macbook pro':             'https://m.media-amazon.com/images/I/71an9eiBxpL._AC_SX522_.jpg',
  'macbook air':             'https://m.media-amazon.com/images/I/71an9eiBxpL._AC_SX522_.jpg',
  'macbook':                 'https://m.media-amazon.com/images/I/71an9eiBxpL._AC_SX522_.jpg',
  'sony wh-1000xm5':         'https://m.media-amazon.com/images/I/51aXvjzcukL._AC_SX522_.jpg',
  'sony wh-1000':            'https://m.media-amazon.com/images/I/51aXvjzcukL._AC_SX522_.jpg',
  'bose quietcomfort':       'https://m.media-amazon.com/images/I/61JbFPuNbGL._AC_SX522_.jpg',
  'bose':                    'https://m.media-amazon.com/images/I/61JbFPuNbGL._AC_SX522_.jpg',
  'jbl charge':              'https://m.media-amazon.com/images/I/61rG3mHG3hL._AC_SX522_.jpg',
  'jbl':                     'https://m.media-amazon.com/images/I/61rG3mHG3hL._AC_SX522_.jpg',
  'kindle paperwhite':       'https://m.media-amazon.com/images/I/51IEAOFpxYL._AC_SX522_.jpg',
  'kindle':                  'https://m.media-amazon.com/images/I/51IEAOFpxYL._AC_SX522_.jpg',
  'gopro hero':              'https://m.media-amazon.com/images/I/71JFV4X4+PL._AC_SX522_.jpg',
  'gopro':                   'https://m.media-amazon.com/images/I/71JFV4X4+PL._AC_SX522_.jpg',
  'playstation 5':           'https://m.media-amazon.com/images/I/51iPoFwQT3L._AC_SX522_.jpg',
  'playstation':             'https://m.media-amazon.com/images/I/51iPoFwQT3L._AC_SX522_.jpg',
  'xbox series x':           'https://m.media-amazon.com/images/I/61-jjE67uEL._AC_SX522_.jpg',
  'xbox':                    'https://m.media-amazon.com/images/I/61-jjE67uEL._AC_SX522_.jpg',
  'nintendo switch':         'https://m.media-amazon.com/images/I/61-jjE67uEL._AC_SX522_.jpg',
  'manette':                 'https://m.media-amazon.com/images/I/51iPoFwQT3L._AC_SX522_.jpg',
  'imprimante':              'https://m.media-amazon.com/images/I/61xYHB10RQL._AC_SX522_.jpg',
  'bambu lab':               'https://m.media-amazon.com/images/I/71JFV4X4+PL._AC_SX522_.jpg',

  // ─── Maison & Déco ─────────────────────────────────────────────
  'bougie diptyque':         'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg',
  'yankee candle':           'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg',
  'bougie':                  'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg',
  'lampe':                   'https://m.media-amazon.com/images/I/71xhAY77AQL._AC_SX522_.jpg',
  'coussin':                 'https://m.media-amazon.com/images/I/71+VzA8J4zL._AC_SX522_.jpg',
  'vase':                    'https://m.media-amazon.com/images/I/71tLMHCIc0L._AC_SX522_.jpg',
  'plante':                  'https://m.media-amazon.com/images/I/71Swqqe7XAL._AC_SX522_.jpg',
  'nespresso vertuo':        'https://m.media-amazon.com/images/I/71+7cuqolbL._AC_SX522_.jpg',
  'nespresso':               'https://m.media-amazon.com/images/I/71+7cuqolbL._AC_SX522_.jpg',
  'machine à café':          'https://m.media-amazon.com/images/I/71+7cuqolbL._AC_SX522_.jpg',

  // ─── Gastronomie ───────────────────────────────────────────────
  'moët chandon':            'https://m.media-amazon.com/images/I/71cDq9JsT4L._AC_SX522_.jpg',
  'veuve clicquot':          'https://m.media-amazon.com/images/I/71cDq9JsT4L._AC_SX522_.jpg',
  'champagne':               'https://m.media-amazon.com/images/I/71cDq9JsT4L._AC_SX522_.jpg',
  'whisky':                  'https://m.media-amazon.com/images/I/61dSAsAvNnL._AC_SX522_.jpg',
  'vin':                     'https://m.media-amazon.com/images/I/61dSAsAvNnL._AC_SX522_.jpg',
  'chocolat valrhona':       'https://m.media-amazon.com/images/I/61E9wl7LVIL._AC_SX522_.jpg',
  'valrhona':                'https://m.media-amazon.com/images/I/61E9wl7LVIL._AC_SX522_.jpg',
  'chocolat':                'https://m.media-amazon.com/images/I/61E9wl7LVIL._AC_SX522_.jpg',
  'mariage frères':          'https://m.media-amazon.com/images/I/71oEQPNDKZL._AC_SX522_.jpg',
  'thé':                     'https://m.media-amazon.com/images/I/71oEQPNDKZL._AC_SX522_.jpg',
  'café':                    'https://m.media-amazon.com/images/I/61YqvJHNGkL._AC_SX522_.jpg',

  // ─── Sport ─────────────────────────────────────────────────────
  'tapis de yoga':           'https://m.media-amazon.com/images/I/71pWKZv3XQL._AC_SX522_.jpg',
  'yoga':                    'https://m.media-amazon.com/images/I/71pWKZv3XQL._AC_SX522_.jpg',
  'vélo':                    'https://m.media-amazon.com/images/I/71uSJRzwpXL._AC_SX522_.jpg',
  'haltères':                'https://m.media-amazon.com/images/I/81cHt8dQs4L._AC_SX522_.jpg',
  'fitness':                 'https://m.media-amazon.com/images/I/81cHt8dQs4L._AC_SX522_.jpg',

  // ─── Livres ────────────────────────────────────────────────────
  'manga':                   'https://m.media-amazon.com/images/I/71Q1tPupKjL._AC_SX522_.jpg',
  'livre':                   'https://m.media-amazon.com/images/I/71pZnMvkBCL._AC_SX522_.jpg',
  'roman':                   'https://m.media-amazon.com/images/I/71pZnMvkBCL._AC_SX522_.jpg',
};

// ── Fallbacks par catégorie ────────────────────────────────────────
const CATEGORY_FALLBACKS = {
  'parfum':       'https://m.media-amazon.com/images/I/61p2M2jdlhL._AC_SX522_.jpg',
  'fragrance':    'https://m.media-amazon.com/images/I/61p2M2jdlhL._AC_SX522_.jpg',
  'beauté':       'https://m.media-amazon.com/images/I/61r5b-c29DL._SX425_.jpg',
  'beauty':       'https://m.media-amazon.com/images/I/61r5b-c29DL._SX425_.jpg',
  'soin':         'https://m.media-amazon.com/images/I/61JMeEZ50lL._AC_SX522_.jpg',
  'skincare':     'https://m.media-amazon.com/images/I/41K-P2Uf5eL._SX425_.jpg',
  'maquillage':   'https://m.media-amazon.com/images/I/41xnYCEJSmL._AC_SX522_.jpg',
  'makeup':       'https://m.media-amazon.com/images/I/41xnYCEJSmL._AC_SX522_.jpg',
  'mode':         'https://m.media-amazon.com/images/I/71OzVrgNXjL._AC_SX522_.jpg',
  'fashion':      'https://m.media-amazon.com/images/I/71OzVrgNXjL._AC_SX522_.jpg',
  'vêtement':     'https://m.media-amazon.com/images/I/71ZdGiA8tkL._AC_SX522_.jpg',
  'sneakers':     'https://m.media-amazon.com/images/I/71MBPJRiVrL._AC_SY695_.jpg',
  'chaussures':   'https://m.media-amazon.com/images/I/61MSCS5ONZL._AC_SY695_.jpg',
  'shoes':        'https://m.media-amazon.com/images/I/61MSCS5ONZL._AC_SY695_.jpg',
  'accessoire':   'https://m.media-amazon.com/images/I/71-6w7aeGtL._AC_SX522_.jpg',
  'bijoux':       'https://m.media-amazon.com/images/I/61WmQ1O5OGL._AC_SX522_.jpg',
  'jewelry':      'https://m.media-amazon.com/images/I/61WmQ1O5OGL._AC_SX522_.jpg',
  'montre':       'https://m.media-amazon.com/images/I/61+9E-4mKhL._AC_SX679_.jpg',
  'watch':        'https://m.media-amazon.com/images/I/61+9E-4mKhL._AC_SX679_.jpg',
  'tech':         'https://m.media-amazon.com/images/I/61f1YfTkTDL._AC_SX522_.jpg',
  'électronique': 'https://m.media-amazon.com/images/I/51aXvjzcukL._AC_SX522_.jpg',
  'gaming':       'https://m.media-amazon.com/images/I/51iPoFwQT3L._AC_SX522_.jpg',
  'maison':       'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg',
  'home':         'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg',
  'déco':         'https://m.media-amazon.com/images/I/71xhAY77AQL._AC_SX522_.jpg',
  'gastronomie':  'https://m.media-amazon.com/images/I/61E9wl7LVIL._AC_SX522_.jpg',
  'food':         'https://m.media-amazon.com/images/I/61E9wl7LVIL._AC_SX522_.jpg',
  'sport':        'https://m.media-amazon.com/images/I/71pWKZv3XQL._AC_SX522_.jpg',
  'fitness':      'https://m.media-amazon.com/images/I/81cHt8dQs4L._AC_SX522_.jpg',
  'livre':        'https://m.media-amazon.com/images/I/71pZnMvkBCL._AC_SX522_.jpg',
  'bien-être':    'https://m.media-amazon.com/images/I/71pWKZv3XQL._AC_SX522_.jpg',
};

const GENERIC_FALLBACK = 'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg';

// ─────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────

function isBlockedDomain(url) {
  if (!url || url.trim() === '') return true;
  const lower = url.toLowerCase();
  return BLOCKED_DOMAINS.some(d => lower.includes(d));
}

async function isUrlAccessible(url) {
  if (!url || url.trim() === '') return false;
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT);
    const res = await fetch(url, {
      method: 'HEAD',
      signal: controller.signal,
      redirect: 'follow',
      headers: { 'User-Agent': 'Mozilla/5.0 (compatible; DoronBot/1.0)' },
    });
    clearTimeout(timeout);
    // 200, 301, 302 → OK. 403 / 404 / 410 / 5xx → cassée
    return res.status >= 200 && res.status < 400;
  } catch (e) {
    // timeout, réseau, CORS, etc.
    return false;
  }
}

function findBestReplacement(name, brand, categories) {
  const combined = `${(name || '').toLowerCase()} ${(brand || '').toLowerCase()}`;

  // 1. Correspondance exacte (la plus longue clé qui correspond)
  const sortedKeys = Object.keys(IMAGE_CATALOGUE).sort((a, b) => b.length - a.length);
  for (const key of sortedKeys) {
    if (combined.includes(key)) return IMAGE_CATALOGUE[key];
  }

  // 2. Fallback par catégorie (première match)
  const cats = (Array.isArray(categories) ? categories : []).map(c => c.toLowerCase());
  for (const cat of cats) {
    if (CATEGORY_FALLBACKS[cat]) return CATEGORY_FALLBACKS[cat];
    for (const [key, url] of Object.entries(CATEGORY_FALLBACKS)) {
      if (cat.includes(key) || key.includes(cat)) return url;
    }
  }

  return GENERIC_FALLBACK;
}

async function checkUrl(url) {
  if (isBlockedDomain(url)) return { ok: false, reason: 'blocked_domain' };
  const ok = await isUrlAccessible(url);
  return { ok, reason: ok ? 'ok' : 'http_error' };
}

// Traitement en parallèle par lots
async function runConcurrent(items, fn, concurrency) {
  const results = [];
  for (let i = 0; i < items.length; i += concurrency) {
    const batch = items.slice(i, i + concurrency);
    const batchResults = await Promise.all(batch.map(fn));
    results.push(...batchResults);
  }
  return results;
}

// ─────────────────────────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────────────────────────
async function main() {
  console.log('');
  console.log('╔══════════════════════════════════════════════════╗');
  console.log('║    🔍 Doron — Audit & Fix des images produits    ║');
  console.log(`║    Mode : ${DRY_RUN ? '🟡 DRY-RUN (lecture seule)      ' : '🔴 PRODUCTION (écriture Firestore)'}    ║`);
  console.log('╚══════════════════════════════════════════════════╝');
  console.log('');

  // ── Étape 1 : Charger tous les produits ─────────────────────────
  console.log('📦 Chargement des produits depuis Firestore...');
  const snapshot = await db.collection('gifts').get();
  console.log(`   ✅ ${snapshot.size} produits chargés\n`);

  const docs = snapshot.docs;

  // ── Étape 2 : Analyser chaque image ─────────────────────────────
  console.log(`🔍 Test de ${docs.length} URLs images (${CONCURRENCY} en parallèle, timeout ${REQUEST_TIMEOUT}ms)...`);
  console.log('   Patiente, ça peut prendre quelques minutes...\n');

  let checked = 0;
  const toFix = [];

  const tasks = docs.map(doc => async () => {
    const d = doc.data();
    const name  = d.name || d.product_title || d.title || '';
    const brand = d.brand || d.source || '';
    const cats  = Array.isArray(d.categories) ? d.categories : (d.tags || []);
    const url   = d.image || d.imageUrl || d.productPhoto || d.photo || '';

    const check = await checkUrl(url);

    checked++;
    if (checked % 50 === 0) {
      process.stdout.write(`   📊 ${checked}/${docs.length} testés...\r`);
    }

    if (!check.ok) {
      return { doc, name, brand, cats, url, reason: check.reason };
    }
    return null;
  });

  // Traitement par lots
  const results = await runConcurrent(tasks, t => t(), CONCURRENCY);
  const broken  = results.filter(Boolean);

  console.log(`\n\n══════════════════════════════════════════════════`);
  console.log(`📊 RÉSULTATS DU DIAGNOSTIC`);
  console.log(`══════════════════════════════════════════════════`);
  console.log(`   Total analysés : ${docs.length}`);
  console.log(`   ✅ Images OK   : ${docs.length - broken.length} (${Math.round((docs.length - broken.length) / docs.length * 100)}%)`);
  console.log(`   ❌ Cassées     : ${broken.length} (${Math.round(broken.length / docs.length * 100)}%)`);
  console.log(`   🔴 Domaine bloqué : ${broken.filter(b => b.reason === 'blocked_domain').length}`);
  console.log(`   🔴 Erreur HTTP    : ${broken.filter(b => b.reason === 'http_error').length}`);

  if (broken.length === 0) {
    console.log('\n🎉 Toutes les images sont OK ! Rien à corriger.');
    process.exit(0);
  }

  if (DRY_RUN) {
    console.log('\n📋 Liste des produits avec images cassées :');
    broken.slice(0, 30).forEach((b, i) => {
      console.log(`   ${i + 1}. "${b.name}" (${b.brand}) — ${b.reason}`);
      console.log(`      URL: ${b.url.substring(0, 80)}...`);
    });
    if (broken.length > 30) console.log(`   ...et ${broken.length - 30} autres.`);
    console.log('\n💡 Lance sans --dry-run pour corriger automatiquement.');
    process.exit(0);
  }

  // ── Étape 3 : Corriger les images cassées ───────────────────────
  console.log(`\n🔧 Correction de ${broken.length} images en cours...\n`);

  let fixed = 0, errors = 0;
  const batchWriter = db.batch();
  let batchCount = 0;

  for (const item of broken) {
    const newUrl = findBestReplacement(item.name, item.brand, item.cats);

    try {
      batchWriter.update(item.doc.ref, {
        image: newUrl,
        imageUrl: newUrl,
        imageFixed: true,
        imageFixedAt: new Date().toISOString(),
      });
      fixed++;
      batchCount++;

      const shortName = item.name.substring(0, 35).padEnd(35);
      console.log(`  ✅ [${fixed}/${broken.length}] ${shortName} → ${newUrl.substring(35, 75)}...`);

      // Commit tous les BATCH_SIZE docs
      if (batchCount >= BATCH_SIZE) {
        await batchWriter.commit();
        console.log(`\n   💾 Batch de ${BATCH_SIZE} docs commité vers Firestore\n`);
        batchCount = 0;
      }
    } catch (e) {
      errors++;
      console.error(`  ❌ Erreur sur "${item.name}": ${e.message}`);
    }
  }

  // Commit les derniers
  if (batchCount > 0) {
    await batchWriter.commit();
  }

  // ── Rapport final ────────────────────────────────────────────────
  console.log('');
  console.log('╔══════════════════════════════════════════════════╗');
  console.log('║              ✅ TERMINÉ !                        ║');
  console.log('╠══════════════════════════════════════════════════╣');
  console.log(`║  Total analysés      : ${String(docs.length).padEnd(24)}║`);
  console.log(`║  Images corrigées    : ${String(fixed).padEnd(24)}║`);
  console.log(`║  Déjà OK (inchangé)  : ${String(docs.length - broken.length).padEnd(24)}║`);
  console.log(`║  Erreurs             : ${String(errors).padEnd(24)}║`);
  console.log('╚══════════════════════════════════════════════════╝');
  console.log('');
  console.log('🎉 Base de données corrigée ! Relance l\'app pour voir les résultats.');

  process.exit(0);
}

main().catch(err => {
  console.error('\n❌ ERREUR CRITIQUE:', err.message || err);
  process.exit(1);
});
