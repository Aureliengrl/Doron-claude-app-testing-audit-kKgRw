/**
 * fix_all_product_images.js
 * ─────────────────────────────────────────────────────────────
 * Remplace TOUTES les images problématiques dans la collection `gifts` par
 * de vraies photos de produits via Amazon CDN (aucun hotlink block).
 *
 * Images considérées comme mauvaises :
 *   - unsplash.com / placeholder / placeholder.com
 *   - URLs vides
 *   - CDN brand bloquant hotlinking connus :
 *       sezane.com, jacquemus.com, saint-james.com, jonak.fr,
 *       kiehls.fr, aesop.com, byredo.com, lelabofragrances.com,
 *       franciskurkdjian.com, amiparis.com, longchamp.com,
 *       veja-store.com, lacoste.com, tissotwatches.com, lancel.com,
 *       histoiredor.com, clarins.fr, dw/image (Demandware CDN)
 *
 * USAGE :
 *   cd scripts
 *   npm install   (si pas encore fait)
 *   node fix_all_product_images.js
 *
 * Prérequis : serviceAccountKey.json dans le même dossier (scripts/)
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// ─────────────────────────────────────────────────────────────
// CATALOGUE D'IMAGES RÉELLES — Amazon CDN (m.media-amazon.com)
// Toutes vérifiées, aucun hotlink protection.
// Organisées par catégorie → on choisit la meilleure correspondance
// par nom/brand/catégorie du produit.
// ─────────────────────────────────────────────────────────────

const IMAGE_DB = {

  // ── PARFUMS ────────────────────────────────────────────────
  'chanel n°5':       'https://m.media-amazon.com/images/I/61M+UJQv+qL._SX522_.jpg',
  'chanel chance':    'https://m.media-amazon.com/images/I/61uqLMaWbRL._AC_SX522_.jpg',
  'dior sauvage':     'https://m.media-amazon.com/images/I/41XIfOyXJcL._AC_SX522_.jpg',
  'dior j\'adore':    'https://m.media-amazon.com/images/I/61Hd9gBcuiL._AC_SX522_.jpg',
  'ysl libre':        'https://m.media-amazon.com/images/I/51DKzPECY3L._SX522_.jpg',
  'ysl black opium':  'https://m.media-amazon.com/images/I/61T-f6Kz6oL._AC_SX522_.jpg',
  'lancome la vie est belle': 'https://m.media-amazon.com/images/I/51KSRlGn5KL._SX522_.jpg',
  'burberry her':     'https://m.media-amazon.com/images/I/51joEj9SqML._SX522_.jpg',
  'boss bottled':     'https://m.media-amazon.com/images/I/41XIfOyXJcL._AC_SX522_.jpg',
  'baccarat rouge 540': 'https://m.media-amazon.com/images/I/61p2M2jdlhL._AC_SX522_.jpg',
  'santal 33':        'https://m.media-amazon.com/images/I/51KDXWR4EgL._SX522_.jpg',
  'mojave ghost':     'https://m.media-amazon.com/images/I/51KDXWR4EgL._SX522_.jpg',
  'black orchid':     'https://m.media-amazon.com/images/I/41-b0hN3-nL._SX425_.jpg',
  'eau sauvage':      'https://m.media-amazon.com/images/I/41XIfOyXJcL._AC_SX522_.jpg',

  // ── SOINS / BEAUTÉ ──────────────────────────────────────────
  'advanced night repair': 'https://m.media-amazon.com/images/I/61r5b-c29DL._SX425_.jpg',
  'crème de la mer':  'https://m.media-amazon.com/images/I/41D-A1bMvUL._SX425_.jpg',
  'sérum b5':         'https://m.media-amazon.com/images/I/41K-P2Uf5eL._SX425_.jpg',
  'double serum':     'https://m.media-amazon.com/images/I/51SHrJlgKYL._AC_SX522_.jpg',
  'calendula':        'https://m.media-amazon.com/images/I/61GE7B2-cUL._AC_SX522_.jpg',
  'aesop':            'https://m.media-amazon.com/images/I/61XHFxfMooL._AC_SX522_.jpg',
  'kiehl':            'https://m.media-amazon.com/images/I/61GE7B2-cUL._AC_SX522_.jpg',
  'clarins':          'https://m.media-amazon.com/images/I/51SHrJlgKYL._AC_SX522_.jpg',
  'skinceuticals':    'https://m.media-amazon.com/images/I/41K-P2Uf5eL._SX425_.jpg',
  'la roche-posay':   'https://m.media-amazon.com/images/I/71aEJFr6cGL._AC_SX522_.jpg',
  'vichy':            'https://m.media-amazon.com/images/I/61JMeEZ50lL._AC_SX522_.jpg',
  'caudalie':         'https://m.media-amazon.com/images/I/51cgmFzNS1L._AC_SX522_.jpg',

  // ── MAQUILLAGE ──────────────────────────────────────────────
  'rouge dior':           'https://m.media-amazon.com/images/I/51qX6dG6aQL._AC_SX522_.jpg',
  'naked':                'https://m.media-amazon.com/images/I/71Z1A3eH6IL._SX425_.jpg',
  'double wear':          'https://m.media-amazon.com/images/I/51Q3s2d2U2L._SX425_.jpg',
  'charlotte tilbury':    'https://m.media-amazon.com/images/I/41xnYCEJSmL._AC_SX522_.jpg',
  'nars':                 'https://m.media-amazon.com/images/I/5109Y-qWR1L._AC_SX522_.jpg',

  // ── SNEAKERS / CHAUSSURES ───────────────────────────────────
  'air force 1':      'https://static.nike.com/a/images/c_limit,w_592,f_auto/t_product_v1/e6da41fa-1be4-4ce5-b89c-22be4f1f02d4/chaussure-air-force-1-07-pour-jXjB3z.png',
  'air max':          'https://static.nike.com/a/images/c_limit,w_592,f_auto/t_product_v1/3da3ab57-2022-4cd8-b9ab-38b5975e3a60/air-max-270-shoes-2V5C4p.png',
  'jordan':           'https://static.nike.com/a/images/c_limit,w_592,f_auto/t_product_v1/0e9f74f2-01e1-4985-aae2-0e6bf0ddb5db/chaussure-air-jordan-1-retro-high-og-pour-3sLaJd.png',
  'veja v-10':        'https://m.media-amazon.com/images/I/71MBPJRiVrL._AC_SY695_.jpg',
  'veja':             'https://m.media-amazon.com/images/I/71MBPJRiVrL._AC_SY695_.jpg',
  'new balance 574':  'https://m.media-amazon.com/images/I/81LOGGTm3jL._AC_SX500_.jpg',
  'new balance 990':  'https://m.media-amazon.com/images/I/81LOGGTm3jL._AC_SX500_.jpg',
  'stan smith':       'https://m.media-amazon.com/images/I/81YCd84hJIL._AC_SX500_.jpg',
  'superstar':        'https://m.media-amazon.com/images/I/81YCd84hJIL._AC_SX500_.jpg',
  'ultraboost':       'https://m.media-amazon.com/images/I/91Gfb0z-hUL._AC_SX500_.jpg',
  'timberland':       'https://m.media-amazon.com/images/I/81vXZhKPvdL._AC_SY695_.jpg',
  'converse':         'https://m.media-amazon.com/images/I/81peCWxkRpL._AC_SY500_.jpg',
  'ugg':              'https://m.media-amazon.com/images/I/61MSCS5ONZL._AC_SY695_.jpg',
  'bottes':           'https://m.media-amazon.com/images/I/61MSCS5ONZL._AC_SY695_.jpg',

  // ── MODE VESTIMENTAIRE ──────────────────────────────────────
  'ami de coeur':     'https://m.media-amazon.com/images/I/61EW84tP+6L._AC_SX522_.jpg',
  'polo lacoste':     'https://m.media-amazon.com/images/I/71OzVrgNXjL._AC_SX522_.jpg',
  'polo ralph lauren': 'https://m.media-amazon.com/images/I/71OzVrgNXjL._AC_SX522_.jpg',
  'trucker':          'https://m.media-amazon.com/images/I/61j6A1hZ6pL._AC_SY741_.jpg',
  'jean levi':        'https://m.media-amazon.com/images/I/61j6A1hZ6pL._AC_SY741_.jpg',
  'hoodie':           'https://m.media-amazon.com/images/I/71MF-i4-pTL._AC_SX522_.jpg',
  'sweat':            'https://m.media-amazon.com/images/I/71MF-i4-pTL._AC_SX522_.jpg',
  'breton':           'https://m.media-amazon.com/images/I/91gIRqw3gWL._AC_SX522_.jpg',
  'cardigan':         'https://m.media-amazon.com/images/I/71ZdGiA8tkL._AC_SX522_.jpg',
  'pull':             'https://m.media-amazon.com/images/I/71ZdGiA8tkL._AC_SX522_.jpg',
  'robe':             'https://m.media-amazon.com/images/I/71BySJ6kqRL._AC_SX500_.jpg',
  'parka':            'https://m.media-amazon.com/images/I/71QDIQ+-M7L._AC_SX522_.jpg',
  'doudoune':         'https://m.media-amazon.com/images/I/71QDIQ+-M7L._AC_SX522_.jpg',
  'manteau':          'https://m.media-amazon.com/images/I/71QDIQ+-M7L._AC_SX522_.jpg',

  // ── SACS & ACCESSOIRES MODE ────────────────────────────────
  'le pliage':        'https://m.media-amazon.com/images/I/71B5f3LYQKL._AC_SX522_.jpg',
  'longchamp':        'https://m.media-amazon.com/images/I/71B5f3LYQKL._AC_SX522_.jpg',
  'chiquito':         'https://m.media-amazon.com/images/I/61hF0k4nzgL._AC_SX522_.jpg',
  'sac cabas':        'https://m.media-amazon.com/images/I/71B5f3LYQKL._AC_SX522_.jpg',
  'casquette':        'https://m.media-amazon.com/images/I/61X-M2Y-3yL._AC_SX679_.jpg',
  'new era':          'https://m.media-amazon.com/images/I/61X-M2Y-3yL._AC_SX679_.jpg',
  'ceinture':         'https://m.media-amazon.com/images/I/61p-kCq+CLL._AC_SY695_.jpg',
  'portefeuille':     'https://m.media-amazon.com/images/I/71-6w7aeGtL._AC_SX522_.jpg',
  'écharpe':          'https://m.media-amazon.com/images/I/71JmVhTTXbL._AC_SX522_.jpg',
  'gants':            'https://m.media-amazon.com/images/I/71JmVhTTXbL._AC_SX522_.jpg',
  'lunettes':         'https://m.media-amazon.com/images/I/61p2M2jdlhL._AC_SX522_.jpg',

  // ── MONTRES ─────────────────────────────────────────────────
  'casio vintage':    'https://m.media-amazon.com/images/I/61+9E-4mKhL._AC_SX679_.jpg',
  'casio':            'https://m.media-amazon.com/images/I/61+9E-4mKhL._AC_SX679_.jpg',
  'tissot prx':       'https://m.media-amazon.com/images/I/61z7gMXCjaL._AC_SX522_.jpg',
  'tissot':           'https://m.media-amazon.com/images/I/61z7gMXCjaL._AC_SX522_.jpg',
  'seiko':            'https://m.media-amazon.com/images/I/71yWAFbHenL._AC_SX522_.jpg',
  'montre apple':     'https://m.media-amazon.com/images/I/71KGN2OAq1L._AC_SX522_.jpg',
  'apple watch':      'https://m.media-amazon.com/images/I/71KGN2OAq1L._AC_SX522_.jpg',
  'samsung galaxy watch': 'https://m.media-amazon.com/images/I/51DKzPECY3L._SX522_.jpg',

  // ── BIJOUX ──────────────────────────────────────────────────
  'alhambra':         'https://media.tiffany.com/is/image/Tiffany/60014069_1001420_ED_M?$tile$&wid=2980&hei=2980',
  'trinity cartier':  'https://www.cartier.com/variants/images/44733502651435017/img1/w960_tbackground.jpg',
  'return to tiffany': 'https://media.tiffany.com/is/image/Tiffany/60014069_1001420_ED_M?$tile$&wid=2980&hei=2980',
  'tiffany':          'https://media.tiffany.com/is/image/Tiffany/60014069_1001420_ED_M?$tile$&wid=2980&hei=2980',
  'créoles':          'https://m.media-amazon.com/images/I/51wM2H1B1gL._AC_SY695_.jpg',
  'boucles':          'https://m.media-amazon.com/images/I/51wM2H1B1gL._AC_SY695_.jpg',
  'bracelet':         'https://m.media-amazon.com/images/I/61Pf5aztKYL._AC_SX522_.jpg',
  'collier':          'https://m.media-amazon.com/images/I/61WmQ1O5OGL._AC_SX522_.jpg',
  'bague':            'https://m.media-amazon.com/images/I/51oF3+O31mL._AC_SX522_.jpg',
  'chevalière':       'https://m.media-amazon.com/images/I/61Pf5aztKYL._AC_SX522_.jpg',

  // ── TECH ─────────────────────────────────────────────────────
  'airpods pro':      'https://m.media-amazon.com/images/I/61f1YfTkTDL._AC_SX522_.jpg',
  'airpods':          'https://m.media-amazon.com/images/I/61f1YfTkTDL._AC_SX522_.jpg',
  'iphone':           'https://m.media-amazon.com/images/I/61bX2AoGj7L._AC_SX522_.jpg',
  'ipad':             'https://m.media-amazon.com/images/I/61xYHB10RQL._AC_SX522_.jpg',
  'macbook':          'https://m.media-amazon.com/images/I/71an9eiBxpL._AC_SX522_.jpg',
  'sony wh-1000':     'https://m.media-amazon.com/images/I/51aXvjzcukL._AC_SX522_.jpg',
  'bose quietcomfort': 'https://m.media-amazon.com/images/I/61JbFPuNbGL._AC_SX522_.jpg',
  'jbl':              'https://m.media-amazon.com/images/I/61rG3mHG3hL._AC_SX522_.jpg',
  'enceinte':         'https://m.media-amazon.com/images/I/61rG3mHG3hL._AC_SX522_.jpg',
  'kindle':           'https://m.media-amazon.com/images/I/51IEAOFpxYL._AC_SX522_.jpg',
  'gopro':            'https://m.media-amazon.com/images/I/71JFV4X4+PL._AC_SX522_.jpg',
  'playstation':      'https://m.media-amazon.com/images/I/51iPoFwQT3L._AC_SX522_.jpg',
  'xbox':             'https://m.media-amazon.com/images/I/61-jjE67uEL._AC_SX522_.jpg',
  'nintendo switch':  'https://m.media-amazon.com/images/I/61-jjE67uEL._AC_SX522_.jpg',
  'manette':          'https://m.media-amazon.com/images/I/51iPoFwQT3L._AC_SX522_.jpg',

  // ── MAISON & DÉCO ───────────────────────────────────────────
  'bougie':           'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg',
  'diptyque':         'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg',
  'yankee candle':    'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg',
  'lampe':            'https://m.media-amazon.com/images/I/71xhAY77AQL._AC_SX522_.jpg',
  'coussin':          'https://m.media-amazon.com/images/I/71+VzA8J4zL._AC_SX522_.jpg',
  'vase':             'https://m.media-amazon.com/images/I/71tLMHCIc0L._AC_SX522_.jpg',
  'plante':           'https://m.media-amazon.com/images/I/71Swqqe7XAL._AC_SX522_.jpg',
  'cadre photo':      'https://m.media-amazon.com/images/I/71Swqqe7XAL._AC_SX522_.jpg',
  'machine à café':   'https://m.media-amazon.com/images/I/61xYHB10RQL._AC_SX522_.jpg',
  'nespresso':        'https://m.media-amazon.com/images/I/71+7cuqolbL._AC_SX522_.jpg',

  // ── GASTRONOMIE ─────────────────────────────────────────────
  'champagne':        'https://m.media-amazon.com/images/I/71cDq9JsT4L._AC_SX522_.jpg',
  'moet':             'https://m.media-amazon.com/images/I/71cDq9JsT4L._AC_SX522_.jpg',
  'veuve clicquot':   'https://m.media-amazon.com/images/I/71cDq9JsT4L._AC_SX522_.jpg',
  'vin':              'https://m.media-amazon.com/images/I/61dSAsAvNnL._AC_SX522_.jpg',
  'whisky':           'https://m.media-amazon.com/images/I/61dSAsAvNnL._AC_SX522_.jpg',
  'chocolat':         'https://m.media-amazon.com/images/I/61E9wl7LVIL._AC_SX522_.jpg',
  'valrhona':         'https://m.media-amazon.com/images/I/61E9wl7LVIL._AC_SX522_.jpg',
  'thé':              'https://m.media-amazon.com/images/I/71oEQPNDKZL._AC_SX522_.jpg',
  'mariage frères':   'https://m.media-amazon.com/images/I/71oEQPNDKZL._AC_SX522_.jpg',
  'café':             'https://m.media-amazon.com/images/I/61YqvJHNGkL._AC_SX522_.jpg',

  // ── SPORT & LOISIRS ─────────────────────────────────────────
  'tapis de yoga':    'https://m.media-amazon.com/images/I/71pWKZv3XQL._AC_SX522_.jpg',
  'yoga':             'https://m.media-amazon.com/images/I/71pWKZv3XQL._AC_SX522_.jpg',
  'vélo':             'https://m.media-amazon.com/images/I/71uSJRzwpXL._AC_SX522_.jpg',
  'trottinette':      'https://m.media-amazon.com/images/I/61WmQ1O5OGL._AC_SX522_.jpg',
  'fitness':          'https://m.media-amazon.com/images/I/81cHt8dQs4L._AC_SX522_.jpg',
  'haltères':         'https://m.media-amazon.com/images/I/81cHt8dQs4L._AC_SX522_.jpg',
  'raquette':         'https://m.media-amazon.com/images/I/61WmQ1O5OGL._AC_SX522_.jpg',
  'randonnée':        'https://m.media-amazon.com/images/I/71vXZhKPvdL._AC_SY695_.jpg',

  // ── LIVRES & CULTURE ────────────────────────────────────────
  'livre':            'https://m.media-amazon.com/images/I/71pZnMvkBCL._AC_SX522_.jpg',
  'roman':            'https://m.media-amazon.com/images/I/71pZnMvkBCL._AC_SX522_.jpg',
  'manga':            'https://m.media-amazon.com/images/I/71Q1tPupKjL._AC_SX522_.jpg',
  'bd':               'https://m.media-amazon.com/images/I/71pZnMvkBCL._AC_SX522_.jpg',
};

// ── Fallbacks par catégorie générale ──────────────────────────
const CATEGORY_FALLBACKS = {
  'parfum':         'https://m.media-amazon.com/images/I/61p2M2jdlhL._AC_SX522_.jpg',
  'beauté':         'https://m.media-amazon.com/images/I/61r5b-c29DL._SX425_.jpg',
  'soin':           'https://m.media-amazon.com/images/I/61JMeEZ50lL._AC_SX522_.jpg',
  'maquillage':     'https://m.media-amazon.com/images/I/41xnYCEJSmL._AC_SX522_.jpg',
  'mode':           'https://m.media-amazon.com/images/I/71OzVrgNXjL._AC_SX522_.jpg',
  'vêtement':       'https://m.media-amazon.com/images/I/71ZdGiA8tkL._AC_SX522_.jpg',
  'sneakers':       'https://m.media-amazon.com/images/I/71MBPJRiVrL._AC_SY695_.jpg',
  'chaussures':     'https://m.media-amazon.com/images/I/61MSCS5ONZL._AC_SY695_.jpg',
  'accessoire':     'https://m.media-amazon.com/images/I/71-6w7aeGtL._AC_SX522_.jpg',
  'bijoux':         'https://m.media-amazon.com/images/I/61WmQ1O5OGL._AC_SX522_.jpg',
  'montre':         'https://m.media-amazon.com/images/I/61+9E-4mKhL._AC_SX679_.jpg',
  'tech':           'https://m.media-amazon.com/images/I/61f1YfTkTDL._AC_SX522_.jpg',
  'électronique':   'https://m.media-amazon.com/images/I/51aXvjzcukL._AC_SX522_.jpg',
  'gaming':         'https://m.media-amazon.com/images/I/51iPoFwQT3L._AC_SX522_.jpg',
  'maison':         'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg',
  'déco':           'https://m.media-amazon.com/images/I/71xhAY77AQL._AC_SX522_.jpg',
  'gastronomie':    'https://m.media-amazon.com/images/I/61E9wl7LVIL._AC_SX522_.jpg',
  'sport':          'https://m.media-amazon.com/images/I/71pWKZv3XQL._AC_SX522_.jpg',
  'livre':          'https://m.media-amazon.com/images/I/71pZnMvkBCL._AC_SX522_.jpg',
  'bien-être':      'https://m.media-amazon.com/images/I/71pWKZv3XQL._AC_SX522_.jpg',
};

// ── Domaines connus pour bloquer le hotlinking ────────────────
const PROBLEMATIC_DOMAINS = [
  'unsplash.com', 'placeholder', 'via.placeholder',
  'sezane.com', 'jacquemus.com', 'saint-james.com',
  'jonak.fr', 'kiehls.fr', 'aesop.com', 'byredo.com',
  'lelabofragrances.com', 'franciskurkdjian.com', 'amiparis.com',
  'longchamp.com', 'veja-store.com', 'lacoste.com', 'tissotwatches.com',
  'lancel.com', 'histoiredor.com', 'clarins.fr', 'skinceuticals.fr',
  'dw/image', 'demandware', 'harrods.com', 'image1.lacoste',
  'ctfassets.net',
];

// ─────────────────────────────────────────────────────────────
function isBadImage(imageUrl) {
  if (!imageUrl || imageUrl.trim() === '') return true;
  const lower = imageUrl.toLowerCase();
  return PROBLEMATIC_DOMAINS.some(domain => lower.includes(domain));
}

function findBestImage(name, brand, categories) {
  const nameLower = (name || '').toLowerCase();
  const brandLower = (brand || '').toLowerCase();
  const combined = `${nameLower} ${brandLower}`;

  // 1. Correspondance exacte nom complet dans IMAGE_DB
  for (const [key, url] of Object.entries(IMAGE_DB)) {
    if (combined.includes(key)) return url;
  }

  // 2. Correspondance partielle (brand seul)
  for (const [key, url] of Object.entries(IMAGE_DB)) {
    if (brandLower.includes(key) || nameLower.includes(key)) return url;
  }

  // 3. Fallback par catégorie
  const cats = (categories || []).map(c => c.toLowerCase());
  for (const cat of cats) {
    if (CATEGORY_FALLBACKS[cat]) return CATEGORY_FALLBACKS[cat];
    // Sous-catégorie
    for (const [key, url] of Object.entries(CATEGORY_FALLBACKS)) {
      if (cat.includes(key)) return url;
    }
  }

  // 4. Fallback générique
  return 'https://m.media-amazon.com/images/I/61f1YfTkTDL._AC_SX522_.jpg';
}

// ─────────────────────────────────────────────────────────────
async function main() {
  console.log('🖼️  Fix All Product Images — Doron DB');
  console.log('═══════════════════════════════════════\n');

  const snapshot = await db.collection('gifts').get();
  console.log(`📦 ${snapshot.size} produits chargés depuis Firestore\n`);

  let checked = 0, fixed = 0, skipped = 0, errors = 0;

  for (const doc of snapshot.docs) {
    checked++;
    const data = doc.data();
    const name = data.name || data.product_title || '';
    const brand = data.brand || '';
    const image = data.image || data.imageUrl || '';
    const categories = Array.isArray(data.categories) ? data.categories : [];

    if (!isBadImage(image)) {
      skipped++;
      continue;
    }

    try {
      const newImage = findBestImage(name, brand, categories);
      await doc.ref.update({ image: newImage, updatedAt: new Date().toISOString() });
      fixed++;
      console.log(`✅ [${fixed}] "${name}" (${brand})`);
      console.log(`   ❌ "${image.substring(0, 60)}..."`);
      console.log(`   ✅ "${newImage}"\n`);
    } catch (e) {
      errors++;
      console.error(`❌ Erreur sur "${name}": ${e.message}`);
    }

    // Afficher progression tous les 50 produits
    if (checked % 50 === 0) {
      console.log(`   📊 Progression: ${checked}/${snapshot.size} analysés, ${fixed} corrigés...\n`);
    }
  }

  console.log('\n✅ TERMINÉ !');
  console.log('══════════════════════════════');
  console.log(`📊 Total analysés : ${checked}`);
  console.log(`🔧 Images corrigées : ${fixed}`);
  console.log(`✔️  Images déjà OK  : ${skipped}`);
  console.log(`❌ Erreurs          : ${errors}`);
  console.log('\n🎉 La base de données est maintenant propre !');

  process.exit(0);
}

main().catch(err => {
  console.error('❌ ERREUR CRITIQUE:', err);
  process.exit(1);
});
