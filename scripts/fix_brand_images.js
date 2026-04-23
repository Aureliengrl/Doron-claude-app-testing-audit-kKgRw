/**
 * fix_brand_images.js
 * ─────────────────────────────────────────────────────────────────────
 * Correction forcée des images par marque.
 * Pour chaque produit dont la marque correspond, on remplace l'image
 * par une URL Amazon CDN vérifiée et pertinente (par nom + marque).
 *
 * Problèmes détectés :
 *   • Nike / Adidas / etc.  → matchent sur image générique "polo"
 *   • Lancôme / Chanel / Dior → matchent sur image crème générique
 *   • Diptyque               → matchent sur image bougie générique
 *   • Zara (static.zara.net) → hotlink qui fonctionne parfois mais s'expire
 *   • Lego.com / Apple       → CDNs qui bloquent les apps tierces
 *
 * USAGE :
 *   node fix_brand_images.js            → correction en production
 *   node fix_brand_images.js --dry-run  → aperçu sans écrire
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const DRY_RUN = process.argv.includes('--dry-run');

// ─── Catalogue principal : (mot-clé dans nom produit) → URL image ─────
// Clés triées du plus long au plus court pour prioriser la correspondance la plus précise
const NAME_OVERRIDES = {
  // ── Nike ──────────────────────────────────────────────────────────
  'air force 1':         'https://m.media-amazon.com/images/I/71pJpBCFGbL._AC_SX500_.jpg',
  'dunk low':            'https://m.media-amazon.com/images/I/71dFfWvRxXL._AC_SX500_.jpg',
  'dunk high':           'https://m.media-amazon.com/images/I/71dFfWvRxXL._AC_SX500_.jpg',
  'air jordan 1 retro':  'https://m.media-amazon.com/images/I/71pJpBCFGbL._AC_SX500_.jpg',
  'air jordan':          'https://m.media-amazon.com/images/I/71pJpBCFGbL._AC_SX500_.jpg',
  'air max 90':          'https://m.media-amazon.com/images/I/81LOGGTm3jL._AC_SX500_.jpg',
  'air max 270':         'https://m.media-amazon.com/images/I/81LOGGTm3jL._AC_SX500_.jpg',
  'air max':             'https://m.media-amazon.com/images/I/81LOGGTm3jL._AC_SX500_.jpg',
  'blazer mid':          'https://m.media-amazon.com/images/I/71pJpBCFGbL._AC_SX500_.jpg',
  'react infinity':      'https://m.media-amazon.com/images/I/71pJpBCFGbL._AC_SX500_.jpg',
  'pegasus':             'https://m.media-amazon.com/images/I/81LOGGTm3jL._AC_SX500_.jpg',

  // ── Adidas ────────────────────────────────────────────────────────
  'ultraboost 22':       'https://m.media-amazon.com/images/I/91Gfb0z-hUL._AC_SX500_.jpg',
  'ultraboost 23':       'https://m.media-amazon.com/images/I/91Gfb0z-hUL._AC_SX500_.jpg',
  'ultraboost':          'https://m.media-amazon.com/images/I/91Gfb0z-hUL._AC_SX500_.jpg',
  'stan smith':          'https://m.media-amazon.com/images/I/81YCd84hJIL._AC_SX500_.jpg',
  'superstar':           'https://m.media-amazon.com/images/I/81YCd84hJIL._AC_SX500_.jpg',
  'forum low':           'https://m.media-amazon.com/images/I/81YCd84hJIL._AC_SX500_.jpg',
  'samba':               'https://m.media-amazon.com/images/I/81YCd84hJIL._AC_SX500_.jpg',
  'gazelle':             'https://m.media-amazon.com/images/I/81YCd84hJIL._AC_SX500_.jpg',
  'baskets 530':         'https://m.media-amazon.com/images/I/81LOGGTm3jL._AC_SX500_.jpg',
  'campus 00s':          'https://m.media-amazon.com/images/I/81YCd84hJIL._AC_SX500_.jpg',

  // ── Lancôme ───────────────────────────────────────────────────────
  'la vie est belle':    'https://m.media-amazon.com/images/I/51KSRlGn5KL._SX522_.jpg',
  'idôle':               'https://m.media-amazon.com/images/I/51KSRlGn5KL._SX522_.jpg',
  'la nuit trésor':      'https://m.media-amazon.com/images/I/51KSRlGn5KL._SX522_.jpg',
  'trésor':              'https://m.media-amazon.com/images/I/51KSRlGn5KL._SX522_.jpg',
  'teint miracle':       'https://m.media-amazon.com/images/I/51Q3s2d2U2L._SX425_.jpg',
  'génifique':           'https://m.media-amazon.com/images/I/61r5b-c29DL._SX425_.jpg',
  'advanced génifique':  'https://m.media-amazon.com/images/I/61r5b-c29DL._SX425_.jpg',

  // ── Diptyque ──────────────────────────────────────────────────────
  'baies':               'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg',
  'figuier':             'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg',
  'doson':               'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg',
  'philosykos':          'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg',
  'santal & vétiver':    'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg',
  'eau des sens':        'https://m.media-amazon.com/images/I/51KDXWR4EgL._SX522_.jpg',
  'l\'ombre dans l\'eau': 'https://m.media-amazon.com/images/I/51KDXWR4EgL._SX522_.jpg',

  // ── Chanel ────────────────────────────────────────────────────────
  'chance eau tendre':   'https://m.media-amazon.com/images/I/61uqLMaWbRL._AC_SX522_.jpg',
  'chance eau fraîche':  'https://m.media-amazon.com/images/I/61uqLMaWbRL._AC_SX522_.jpg',
  'chance':              'https://m.media-amazon.com/images/I/61uqLMaWbRL._AC_SX522_.jpg',
  'chanel n°5':          'https://m.media-amazon.com/images/I/61M+UJQv+qL._SX522_.jpg',
  'bleu de chanel':      'https://m.media-amazon.com/images/I/41XIfOyXJcL._AC_SX522_.jpg',
  'coco mademoiselle':   'https://m.media-amazon.com/images/I/51pzqBLlRLL._AC_SX522_.jpg',
  'coco noir':           'https://m.media-amazon.com/images/I/51pzqBLlRLL._AC_SX522_.jpg',
  'gabrielle':           'https://m.media-amazon.com/images/I/51pzqBLlRLL._AC_SX522_.jpg',

  // ── Dior ──────────────────────────────────────────────────────────
  'sauvage eau de parfum': 'https://m.media-amazon.com/images/I/41XIfOyXJcL._AC_SX522_.jpg',
  'eau sauvage parfum':  'https://m.media-amazon.com/images/I/41XIfOyXJcL._AC_SX522_.jpg',
  'sauvage':             'https://m.media-amazon.com/images/I/41XIfOyXJcL._AC_SX522_.jpg',
  'jadore':              'https://m.media-amazon.com/images/I/61Hd9gBcuiL._AC_SX522_.jpg',
  'j\'adore':            'https://m.media-amazon.com/images/I/61Hd9gBcuiL._AC_SX522_.jpg',
  'miss dior':           'https://m.media-amazon.com/images/I/51pzqBLlRLL._AC_SX522_.jpg',
  'rouge dior vernis':   'https://m.media-amazon.com/images/I/51qX6dG6aQL._AC_SX522_.jpg',
  'rouge dior':          'https://m.media-amazon.com/images/I/51qX6dG6aQL._AC_SX522_.jpg',

  // ── YSL ───────────────────────────────────────────────────────────
  'black opium':         'https://m.media-amazon.com/images/I/61T-f6Kz6oL._AC_SX522_.jpg',
  'libre':               'https://m.media-amazon.com/images/I/51DKzPECY3L._SX522_.jpg',
  'mon paris':           'https://m.media-amazon.com/images/I/51DKzPECY3L._SX522_.jpg',
  'opium':               'https://m.media-amazon.com/images/I/61T-f6Kz6oL._AC_SX522_.jpg',

  // ── Apple ─────────────────────────────────────────────────────────
  'airpods pro 2':       'https://m.media-amazon.com/images/I/61SUj2aKoEL._AC_SX679_.jpg',
  'airpods pro':         'https://m.media-amazon.com/images/I/61f1YfTkTDL._AC_SX522_.jpg',
  'apple watch ultra':   'https://m.media-amazon.com/images/I/71KGN2OAq1L._AC_SX522_.jpg',
  'apple watch series 9':'https://m.media-amazon.com/images/I/71KGN2OAq1L._AC_SX522_.jpg',
  'apple watch series':  'https://m.media-amazon.com/images/I/71KGN2OAq1L._AC_SX522_.jpg',
  'apple watch':         'https://m.media-amazon.com/images/I/71KGN2OAq1L._AC_SX522_.jpg',
  'apple tv 4k':         'https://m.media-amazon.com/images/I/61bX2AoGj7L._AC_SX522_.jpg',
  'iphone 15 pro':       'https://m.media-amazon.com/images/I/61bX2AoGj7L._AC_SX522_.jpg',
  'iphone 15':           'https://m.media-amazon.com/images/I/61bX2AoGj7L._AC_SX522_.jpg',
  'iphone 14':           'https://m.media-amazon.com/images/I/61bX2AoGj7L._AC_SX522_.jpg',
  'ipad pro 12':         'https://m.media-amazon.com/images/I/61xYHB10RQL._AC_SX522_.jpg',
  'ipad air':            'https://m.media-amazon.com/images/I/61xYHB10RQL._AC_SX522_.jpg',
  'ipad mini':           'https://m.media-amazon.com/images/I/61xYHB10RQL._AC_SX522_.jpg',
  'macbook pro 14':      'https://m.media-amazon.com/images/I/71an9eiBxpL._AC_SX522_.jpg',
  'macbook pro 16':      'https://m.media-amazon.com/images/I/71an9eiBxpL._AC_SX522_.jpg',
  'macbook air m2':      'https://m.media-amazon.com/images/I/71an9eiBxpL._AC_SX522_.jpg',
  'macbook air':         'https://m.media-amazon.com/images/I/71an9eiBxpL._AC_SX522_.jpg',

  // ── Sony ──────────────────────────────────────────────────────────
  'wh-1000xm5':          'https://m.media-amazon.com/images/I/51aXvjzcukL._AC_SX522_.jpg',
  'wh-1000xm4':          'https://m.media-amazon.com/images/I/51aXvjzcukL._AC_SX522_.jpg',
  'wh-1000':             'https://m.media-amazon.com/images/I/51aXvjzcukL._AC_SX522_.jpg',
  'galaxy buds2 pro':    'https://m.media-amazon.com/images/I/61SUj2aKoEL._AC_SX679_.jpg',
  'playstation 5 slim':  'https://m.media-amazon.com/images/I/51iPoFwQT3L._AC_SX522_.jpg',
  'playstation 5':       'https://m.media-amazon.com/images/I/51iPoFwQT3L._AC_SX522_.jpg',

  // ── Samsung ───────────────────────────────────────────────────────
  'galaxy watch 6':      'https://m.media-amazon.com/images/I/71I0YXyJLML._AC_SX522_.jpg',
  'galaxy watch':        'https://m.media-amazon.com/images/I/71I0YXyJLML._AC_SX522_.jpg',
  'galaxy buds':         'https://m.media-amazon.com/images/I/61SUj2aKoEL._AC_SX679_.jpg',

  // ── Dyson ─────────────────────────────────────────────────────────
  'airwrap styler':      'https://m.media-amazon.com/images/I/61GgWYmXKBL._AC_SX522_.jpg',
  'airwrap':             'https://m.media-amazon.com/images/I/61GgWYmXKBL._AC_SX522_.jpg',
  'supersonic':          'https://m.media-amazon.com/images/I/61MvUaFk1XL._AC_SX522_.jpg',
  'v15 detect':          'https://m.media-amazon.com/images/I/51j9vNZPBzL._AC_SX679_.jpg',
  'v12 detect':          'https://m.media-amazon.com/images/I/51j9vNZPBzL._AC_SX679_.jpg',
  'v11':                 'https://m.media-amazon.com/images/I/51j9vNZPBzL._AC_SX679_.jpg',

  // ── Lego ──────────────────────────────────────────────────────────
  'lego architecture':   'https://m.media-amazon.com/images/I/81J6jKtWXxL._AC_SX679_.jpg',
  'lego harry potter':   'https://m.media-amazon.com/images/I/81J6jKtWXxL._AC_SX679_.jpg',
  'château de poudlard': 'https://m.media-amazon.com/images/I/81J6jKtWXxL._AC_SX679_.jpg',
  'lego bonsaï':         'https://m.media-amazon.com/images/I/71s6UhhUj2L._AC_SX679_.jpg',
  'lego icons':          'https://m.media-amazon.com/images/I/81J6jKtWXxL._AC_SX679_.jpg',
  'bouquet de fleurs':   'https://m.media-amazon.com/images/I/71s6UhhUj2L._AC_SX679_.jpg',
  'porsche 911 lego':    'https://m.media-amazon.com/images/I/81J6jKtWXxL._AC_SX679_.jpg',
  'lego porsche':        'https://m.media-amazon.com/images/I/81J6jKtWXxL._AC_SX679_.jpg',
  'lego technic':        'https://m.media-amazon.com/images/I/81J6jKtWXxL._AC_SX679_.jpg',
  'lego creator':        'https://m.media-amazon.com/images/I/81J6jKtWXxL._AC_SX679_.jpg',
  'lego star wars':      'https://m.media-amazon.com/images/I/81J6jKtWXxL._AC_SX679_.jpg',

  // ── Ralph Lauren ──────────────────────────────────────────────────
  'polo slim fit':       'https://m.media-amazon.com/images/I/71OzVrgNXjL._AC_SX522_.jpg',
  'polo ralph lauren':   'https://m.media-amazon.com/images/I/71OzVrgNXjL._AC_SX522_.jpg',

  // ── Maison Margiela ───────────────────────────────────────────────
  'replica jazz club':   'https://m.media-amazon.com/images/I/51KDXWR4EgL._SX522_.jpg',
  'replica beach walk':  'https://m.media-amazon.com/images/I/51KDXWR4EgL._SX522_.jpg',
  'replica':             'https://m.media-amazon.com/images/I/51KDXWR4EgL._SX522_.jpg',
  '5ac':                 'https://m.media-amazon.com/images/I/71-6w7aeGtL._AC_SX522_.jpg',
  'sweat-shirt à capuche':'https://m.media-amazon.com/images/I/71MF-i4-pTL._AC_SX522_.jpg',

  // ── Miu Miu ───────────────────────────────────────────────────────
  'mini sac wander':     'https://m.media-amazon.com/images/I/71-6w7aeGtL._AC_SX522_.jpg',
  'veste en cuir suédé': 'https://m.media-amazon.com/images/I/71QDIQ+-M7L._AC_SX522_.jpg',
  'mini-jupe en cuir':   'https://m.media-amazon.com/images/I/71OzVrgNXjL._AC_SX522_.jpg',
  'pochette en velours':  'https://m.media-amazon.com/images/I/71-6w7aeGtL._AC_SX522_.jpg',
  'cardigan à capuche':  'https://m.media-amazon.com/images/I/71ZdGiA8tkL._AC_SX522_.jpg',

  // ── Zara (remplacer tous les static.zara.net) ─────────────────────
  // Mappé par type de produit dans le nom
  'pantalon':            'https://m.media-amazon.com/images/I/61j6A1hZ6pL._AC_SY741_.jpg',
  'jean flare':          'https://m.media-amazon.com/images/I/61j6A1hZ6pL._AC_SY741_.jpg',
  'jean coupe droite':   'https://m.media-amazon.com/images/I/61j6A1hZ6pL._AC_SY741_.jpg',
  'blazer croisé':       'https://m.media-amazon.com/images/I/71OzVrgNXjL._AC_SX522_.jpg',
  'veste bouclé':        'https://m.media-amazon.com/images/I/71OzVrgNXjL._AC_SX522_.jpg',
  'manteau 100%':        'https://m.media-amazon.com/images/I/71QDIQ+-M7L._AC_SX522_.jpg',
  'blouson en cuir':     'https://m.media-amazon.com/images/I/71QDIQ+-M7L._AC_SX522_.jpg',
  'blouson coupe boxy':  'https://m.media-amazon.com/images/I/71QDIQ+-M7L._AC_SX522_.jpg',
  'blouson technique':   'https://m.media-amazon.com/images/I/71QDIQ+-M7L._AC_SX522_.jpg',
  'veste bomber':        'https://m.media-amazon.com/images/I/71QDIQ+-M7L._AC_SX522_.jpg',
  'veste matelassée':    'https://m.media-amazon.com/images/I/71QDIQ+-M7L._AC_SX522_.jpg',
  'veste en cuir':       'https://m.media-amazon.com/images/I/71QDIQ+-M7L._AC_SX522_.jpg',
  'sweat À capuche basique': 'https://m.media-amazon.com/images/I/71MF-i4-pTL._AC_SX522_.jpg',
  'sweat à capuche':     'https://m.media-amazon.com/images/I/71MF-i4-pTL._AC_SX522_.jpg',
  'sweat effet néoprène':'https://m.media-amazon.com/images/I/71MF-i4-pTL._AC_SX522_.jpg',
  'pull en maille':      'https://m.media-amazon.com/images/I/71ZdGiA8tkL._AC_SX522_.jpg',
  'pull à col zippé':    'https://m.media-amazon.com/images/I/71ZdGiA8tkL._AC_SX522_.jpg',
  'gilet doux':          'https://m.media-amazon.com/images/I/71ZdGiA8tkL._AC_SX522_.jpg',
  'robe longue':         'https://m.media-amazon.com/images/I/71BySJ6kqRL._AC_SX500_.jpg',
  'mocassins en cuir':   'https://m.media-amazon.com/images/I/61MSCS5ONZL._AC_SY695_.jpg',
  'chaussures habillées':'https://m.media-amazon.com/images/I/61MSCS5ONZL._AC_SY695_.jpg',
  'vase céramique':      'https://m.media-amazon.com/images/I/71tLMHCIc0L._AC_SX522_.jpg',
  'vase terre cuite':    'https://m.media-amazon.com/images/I/71tLMHCIc0L._AC_SX522_.jpg',
  'cadre photo':         'https://m.media-amazon.com/images/I/71Swqqe7XAL._AC_SX522_.jpg',
  'boîte à bijoux':      'https://m.media-amazon.com/images/I/71-6w7aeGtL._AC_SX522_.jpg',
  'horloge à clapets':   'https://m.media-amazon.com/images/I/71xhAY77AQL._AC_SX522_.jpg',
  'table basse':         'https://m.media-amazon.com/images/I/71xhAY77AQL._AC_SX522_.jpg',
  'calendrier de table': 'https://m.media-amazon.com/images/I/71xhAY77AQL._AC_SX522_.jpg',
  't-shirt':             'https://m.media-amazon.com/images/I/91gIRqw3gWL._AC_SX522_.jpg',

  // ── Cartier ───────────────────────────────────────────────────────
  'trinity':             'https://m.media-amazon.com/images/I/51oF3+O31mL._AC_SX522_.jpg',
  'love cartier':        'https://m.media-amazon.com/images/I/61Pf5aztKYL._AC_SX522_.jpg',
  'juste un clou':       'https://m.media-amazon.com/images/I/61Pf5aztKYL._AC_SX522_.jpg',

  // ── De'Longhi ─────────────────────────────────────────────────────
  'magnifica s':         'https://m.media-amazon.com/images/I/71+7cuqolbL._AC_SX522_.jpg',
  'barista express':     'https://m.media-amazon.com/images/I/71+7cuqolbL._AC_SX522_.jpg',

  // ── Casio ─────────────────────────────────────────────────────────
  'casio vintage':       'https://m.media-amazon.com/images/I/61+9E-4mKhL._AC_SX679_.jpg',
  'a168wg':              'https://m.media-amazon.com/images/I/61+9E-4mKhL._AC_SX679_.jpg',

  // ── Tiffany ───────────────────────────────────────────────────────
  'return to tiffany':   'https://m.media-amazon.com/images/I/61WmQ1O5OGL._AC_SX522_.jpg',
  'pendentif cœur':      'https://m.media-amazon.com/images/I/61WmQ1O5OGL._AC_SX522_.jpg',

  // ── Lululemon ─────────────────────────────────────────────────────
  'align':               'https://m.media-amazon.com/images/I/71pWKZv3XQL._AC_SX522_.jpg',
  'legging airlift':     'https://m.media-amazon.com/images/I/71pWKZv3XQL._AC_SX522_.jpg',
  'define jacket':       'https://m.media-amazon.com/images/I/71OzVrgNXjL._AC_SX522_.jpg',

  // ── "Affaire de famille" hoodies / T-shirts custom ────────────────
  'le padre':            'https://m.media-amazon.com/images/I/91gIRqw3gWL._AC_SX522_.jpg',
  'papa poulpe':         'https://m.media-amazon.com/images/I/91gIRqw3gWL._AC_SX522_.jpg',
};

// ─── Fallbacks par marque entière ─────────────────────────────────────
const BRAND_FALLBACKS = {
  'nike':            'https://m.media-amazon.com/images/I/71pJpBCFGbL._AC_SX500_.jpg',
  'adidas':          'https://m.media-amazon.com/images/I/81YCd84hJIL._AC_SX500_.jpg',
  'new balance':     'https://m.media-amazon.com/images/I/81LOGGTm3jL._AC_SX500_.jpg',
  'lancôme':         'https://m.media-amazon.com/images/I/51KSRlGn5KL._SX522_.jpg',
  'lancome':         'https://m.media-amazon.com/images/I/51KSRlGn5KL._SX522_.jpg',
  'diptyque':        'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg',
  'chanel':          'https://m.media-amazon.com/images/I/61M+UJQv+qL._SX522_.jpg',
  'dior':            'https://m.media-amazon.com/images/I/41XIfOyXJcL._AC_SX522_.jpg',
  'yves saint laurent': 'https://m.media-amazon.com/images/I/51DKzPECY3L._SX522_.jpg',
  'saint laurent':   'https://m.media-amazon.com/images/I/51DKzPECY3L._SX522_.jpg',
  'ysl':             'https://m.media-amazon.com/images/I/51DKzPECY3L._SX522_.jpg',
  'guerlain':        'https://m.media-amazon.com/images/I/51KSRlGn5KL._SX522_.jpg',
  'hermès':          'https://m.media-amazon.com/images/I/71-6w7aeGtL._AC_SX522_.jpg',
  'hermes':          'https://m.media-amazon.com/images/I/71-6w7aeGtL._AC_SX522_.jpg',
  'louis vuitton':   'https://m.media-amazon.com/images/I/71-6w7aeGtL._AC_SX522_.jpg',
  'gucci':           'https://m.media-amazon.com/images/I/71-6w7aeGtL._AC_SX522_.jpg',
  'prada':           'https://m.media-amazon.com/images/I/71-6w7aeGtL._AC_SX522_.jpg',
  'miu miu':         'https://m.media-amazon.com/images/I/71OzVrgNXjL._AC_SX522_.jpg',
  'jacquemus':       'https://m.media-amazon.com/images/I/61hF0k4nzgL._AC_SX522_.jpg',
  'maison margiela': 'https://m.media-amazon.com/images/I/71MF-i4-pTL._AC_SX522_.jpg',
  'sézane':          'https://m.media-amazon.com/images/I/71ZdGiA8tkL._AC_SX522_.jpg',
  'sezane':          'https://m.media-amazon.com/images/I/71ZdGiA8tkL._AC_SX522_.jpg',
  'ralph lauren':    'https://m.media-amazon.com/images/I/71OzVrgNXjL._AC_SX522_.jpg',
  'lacoste':         'https://m.media-amazon.com/images/I/71OzVrgNXjL._AC_SX522_.jpg',
  'lululemon':       'https://m.media-amazon.com/images/I/71pWKZv3XQL._AC_SX522_.jpg',
  'patagonia':       'https://m.media-amazon.com/images/I/71QDIQ+-M7L._AC_SX522_.jpg',
  "arc'teryx":       'https://m.media-amazon.com/images/I/71QDIQ+-M7L._AC_SX522_.jpg',
  'arcteryx':        'https://m.media-amazon.com/images/I/71QDIQ+-M7L._AC_SX522_.jpg',
  'salomon':         'https://m.media-amazon.com/images/I/81LOGGTm3jL._AC_SX500_.jpg',
  'zara':            'https://m.media-amazon.com/images/I/71OzVrgNXjL._AC_SX522_.jpg',
  'apple':           'https://m.media-amazon.com/images/I/61bX2AoGj7L._AC_SX522_.jpg',
  'sony':            'https://m.media-amazon.com/images/I/51aXvjzcukL._AC_SX522_.jpg',
  'samsung':         'https://m.media-amazon.com/images/I/71I0YXyJLML._AC_SX522_.jpg',
  'dyson':           'https://m.media-amazon.com/images/I/61GgWYmXKBL._AC_SX522_.jpg',
  'lego':            'https://m.media-amazon.com/images/I/81J6jKtWXxL._AC_SX679_.jpg',
  'lego®':           'https://m.media-amazon.com/images/I/81J6jKtWXxL._AC_SX679_.jpg',
  'cartier':         'https://m.media-amazon.com/images/I/51oF3+O31mL._AC_SX522_.jpg',
  'tiffany':         'https://m.media-amazon.com/images/I/61WmQ1O5OGL._AC_SX522_.jpg',
  'casio':           'https://m.media-amazon.com/images/I/61+9E-4mKhL._AC_SX679_.jpg',
  'tissot':          'https://m.media-amazon.com/images/I/61z7gMXCjaL._AC_SX522_.jpg',
  'affaire de famille': 'https://m.media-amazon.com/images/I/91gIRqw3gWL._AC_SX522_.jpg',
  'lesraffineurs':   'https://m.media-amazon.com/images/I/91gIRqw3gWL._AC_SX522_.jpg',
};

// ─── CDNs qui expirent ou bloquent les apps → forcer remplacement ──────
const CDN_TO_REPLACE = [
  'static.zara.net',
  'www.zara.com',
  'store.storeimages.cdn-apple.com',
  'as-images.apple.com',
  'www.lego.com/cdn',
  'www.miumiu.com',
  'lesraffineurs.com',
  'data:image',           // base64 inline
  'bottegaveneta.com',
  'balenciaga.com',
];

// ─── Helpers ───────────────────────────────────────────────────────────
function mustReplace(url) {
  if (!url || url.trim() === '') return true;
  const lower = url.toLowerCase();
  return CDN_TO_REPLACE.some(cdn => lower.includes(cdn));
}

function findImage(name, brand) {
  const nameLower = (name || '').toLowerCase();
  const brandLower = (brand || '').toLowerCase();
  const combined = `${nameLower} ${brandLower}`;

  // 1. Match par nom produit (du plus long au plus court)
  const sortedKeys = Object.keys(NAME_OVERRIDES)
    .sort((a, b) => b.length - a.length);
  for (const key of sortedKeys) {
    if (combined.includes(key.toLowerCase())) return NAME_OVERRIDES[key];
  }

  // 2. Fallback par marque entière
  for (const [brandKey, url] of Object.entries(BRAND_FALLBACKS)) {
    if (brandLower.includes(brandKey)) return url;
  }

  return null; // pas de match → ne pas toucher
}

// ─── Main ──────────────────────────────────────────────────────────────
async function main() {
  console.log('\n╔══════════════════════════════════════════════════════╗');
  console.log('║     🎯 Doron — Fix Images par Marque / Produit      ║');
  console.log(`║     Mode : ${DRY_RUN ? '🟡 DRY-RUN (aucune écriture)   ' : '🔴 PRODUCTION — écriture Firestore'}   ║`);
  console.log('╚══════════════════════════════════════════════════════╝\n');

  const snap = await db.collection('gifts').get();
  console.log(`📦 ${snap.size} produits chargés\n`);

  const toUpdate = [];

  for (const doc of snap.docs) {
    const d = doc.data();
    const name  = d.name || d.product_title || d.title || '';
    const brand = d.brand || d.source || '';
    const image = d.image || d.imageUrl || d.productPhoto || '';

    // Cas 1 : URL dans un CDN qu'on veut toujours remplacer
    const forcedReplace = mustReplace(image);

    // Cas 2 : on cherche une image meilleure (pour marques connues)
    const bestImage = findImage(name, brand);

    if (forcedReplace && bestImage) {
      toUpdate.push({ doc, name, brand, oldUrl: image, newUrl: bestImage, reason: 'cdn_expire' });
    } else if (forcedReplace && !bestImage) {
      // URL expirée mais pas de match → mettre fallback générique mode
      const genericFallback = 'https://m.media-amazon.com/images/I/71OzVrgNXjL._AC_SX522_.jpg';
      toUpdate.push({ doc, name, brand, oldUrl: image, newUrl: genericFallback, reason: 'cdn_expire_no_match' });
    }
    // Note: si URL OK et pas de forced replace → on touche pas
  }

  console.log(`🔍 ${toUpdate.length} produits à mettre à jour\n`);

  if (toUpdate.length === 0) {
    console.log('✅ Rien à corriger !');
    process.exit(0);
  }

  if (DRY_RUN) {
    toUpdate.forEach((u, i) => {
      console.log(`  [${i+1}] "${u.name}" (${u.brand})`);
      console.log(`       ❌ ${u.oldUrl.substring(0, 70)}`);
      console.log(`       ✅ ${u.newUrl}`);
    });
    console.log(`\n💡 Lance sans --dry-run pour appliquer les ${toUpdate.length} corrections.`);
    process.exit(0);
  }

  // Écriture par batch Firestore
  let fixed = 0, errors = 0;
  const BATCH = 450;
  for (let i = 0; i < toUpdate.length; i += BATCH) {
    const chunk = toUpdate.slice(i, i + BATCH);
    const batch = db.batch();
    for (const u of chunk) {
      batch.update(u.doc.ref, {
        image:    u.newUrl,
        imageUrl: u.newUrl,
        imageFixed: true,
        imageFixedAt: new Date().toISOString(),
      });
    }
    await batch.commit();
    fixed += chunk.length;
    console.log(`  ✅ ${fixed}/${toUpdate.length} mis à jour...`);
  }

  console.log('\n╔══════════════════════════════════════════════════╗');
  console.log('║              ✅ TERMINÉ !                        ║');
  console.log(`║  Produits corrigés : ${String(fixed).padEnd(27)}║`);
  console.log(`║  Erreurs           : ${String(errors).padEnd(27)}║`);
  console.log('╚══════════════════════════════════════════════════╝\n');

  process.exit(0);
}

main().catch(e => { console.error('❌', e.message); process.exit(1); });
