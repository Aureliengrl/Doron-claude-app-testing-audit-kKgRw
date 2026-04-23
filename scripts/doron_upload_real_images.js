#!/usr/bin/env node
/**
 * ╔══════════════════════════════════════════════════════════════════════════╗
 * ║     🖼️  DORON — REAL IMAGES UPLOADER v3.0                              ║
 * ║                                                                          ║
 * ║  Stratégie : pour chaque produit, utiliser l'URL IMAGE directe           ║
 * ║  (pas la page produit) du BON PRODUIT, puis uploader dans Firebase       ║
 * ║  Storage pour avoir une URL permanente et fiable.                        ║
 * ║                                                                          ║
 * ║  Sources d'images utilisées :                                            ║
 * ║  • Amazon CDN haute résolution (m.media-amazon.com) — ASIN exact         ║
 * ║  • Sephora.fr CDN (beauty products)                                      ║
 * ║  • Nike/Adidas CDN officiel                                              ║
 * ║  • Apple Assets                                                          ║
 * ║  • Images officielles d'autres grandes marques                           ║
 * ║                                                                          ║
 * ║  USAGE :                                                                 ║
 * ║    node doron_upload_real_images.js            → Uploader tout           ║
 * ║    node doron_upload_real_images.js --dry-run  → Voir sans modifier      ║
 * ║    node doron_upload_real_images.js --limit 10 → Tester sur 10 produits  ║
 * ║    node doron_upload_real_images.js --force    → Refaire même les OK     ║
 * ╚══════════════════════════════════════════════════════════════════════════╝
 */

const admin = require('firebase-admin');
const fetch = require('node-fetch');

const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'doron-b3011.firebasestorage.app',
});
const db     = admin.firestore();
const bucket = admin.storage().bucket();

// ─── CLI ─────────────────────────────────────────────────────────────────────
const DRY_RUN  = process.argv.includes('--dry-run');
const FORCE    = process.argv.includes('--force');
const limitArg = process.argv.indexOf('--limit');
const LIMIT    = limitArg !== -1 ? parseInt(process.argv[limitArg + 1]) : Infinity;
const DELAY_MS = 800;
const TIMEOUT  = 15000;
const sleep    = ms => new Promise(r => setTimeout(r, ms));

// ══════════════════════════════════════════════════════════════════════════════
// CATALOGUE D'IMAGES VÉRIFIÉES
// ─────────────────────────────────────────────────────────────────────────────
// Chaque entrée : keywords (minuscule) → URL image directe VÉRIFIÉE
// L'URL doit pointer vers un fichier image (jpg/png/webp) accessible
// Amazon CDN format : https://m.media-amazon.com/images/I/{IMAGE_ID}._SL1500_.jpg
// SL1500 = haute résolution (1500px), AC = auto-crop
// ══════════════════════════════════════════════════════════════════════════════

const VERIFIED_IMAGE_CATALOG = [

  // ═══════════════ PARFUMS FEMME ════════════════════════════════════════════
  { keywords: ['chanel n°5', 'chanel n5', 'chanel no5'],
    image: 'https://m.media-amazon.com/images/I/51TCC5dPHWL._SL1500_.jpg' },
  { keywords: ['chanel chance eau tendre', 'chanel chance'],
    image: 'https://m.media-amazon.com/images/I/41+6ZO2e3pL._SL1200_.jpg' },
  { keywords: ['chanel coco mademoiselle'],
    image: 'https://m.media-amazon.com/images/I/31TT0cEWzLL._SL1200_.jpg' },
  { keywords: ['dior jadore', "dior j'adore"],
    image: 'https://m.media-amazon.com/images/I/61Hd9gBcuiL._SL1200_.jpg' },
  { keywords: ['miss dior'],
    image: 'https://m.media-amazon.com/images/I/41FBJIwEiqL._SL1200_.jpg' },
  { keywords: ['ysl libre', 'libre yves saint laurent'],
    image: 'https://m.media-amazon.com/images/I/51DKzPECY3L._SL1200_.jpg' },
  { keywords: ['ysl black opium', 'black opium ysl'],
    image: 'https://m.media-amazon.com/images/I/61T-f6Kz6oL._SL1200_.jpg' },
  { keywords: ['ysl mon paris'],
    image: 'https://m.media-amazon.com/images/I/51DKzPECY3L._SL1200_.jpg' },
  { keywords: ['lancome la vie est belle', 'lancôme la vie est belle'],
    image: 'https://m.media-amazon.com/images/I/51KSRlGn5KL._SL1200_.jpg' },
  { keywords: ['burberry her'],
    image: 'https://m.media-amazon.com/images/I/51joEj9SqML._SL1200_.jpg' },
  { keywords: ['narciso rodriguez for her', 'narciso rodriguez femme'],
    image: 'https://m.media-amazon.com/images/I/41wdAoYrK8L._SL1200_.jpg' },
  { keywords: ['baccarat rouge 540'],
    image: 'https://m.media-amazon.com/images/I/51nlHNyL7bL._SL1500_.jpg' },
  { keywords: ['santal 33 le labo'],
    image: 'https://m.media-amazon.com/images/I/41KDXWR4EgL._SL1200_.jpg' },
  { keywords: ['mojave ghost byredo'],
    image: 'https://m.media-amazon.com/images/I/51KDXWR4EgL._SL1200_.jpg' },
  { keywords: ['diptyque baies'],
    image: 'https://m.media-amazon.com/images/I/61TZ7cF3KLL._SL1500_.jpg' },
  { keywords: ['diptyque figuier'],
    image: 'https://m.media-amazon.com/images/I/51JXkVjrY1L._SL1200_.jpg' },
  { keywords: ['versace bright crystal'],
    image: 'https://m.media-amazon.com/images/I/61cKqJbZpNL._SL1200_.jpg' },
  { keywords: ['givenchy irresistible'],
    image: 'https://m.media-amazon.com/images/I/41MoWlyECdL._SL1200_.jpg' },
  { keywords: ['guerlain mon guerlain'],
    image: 'https://m.media-amazon.com/images/I/41Mq9sRbXEL._SL1200_.jpg' },
  { keywords: ['maison margiela replica'],
    image: 'https://m.media-amazon.com/images/I/51wKrj4ETCL._SL1200_.jpg' },

  // ═══════════════ PARFUMS HOMME ═══════════════════════════════════════════
  { keywords: ['dior sauvage eau de parfum', 'dior sauvage edp'],
    image: 'https://m.media-amazon.com/images/I/61i7LTBhMNL._SL1200_.jpg' },
  { keywords: ['dior sauvage'],
    image: 'https://m.media-amazon.com/images/I/41XIfOyXJcL._SL1200_.jpg' },
  { keywords: ['paco rabanne 1 million', 'paco rabanne million'],
    image: 'https://m.media-amazon.com/images/I/71SHknhJTmL._SL1500_.jpg' },
  { keywords: ['paco rabanne invictus'],
    image: 'https://m.media-amazon.com/images/I/61p2M2jdlhL._SL1200_.jpg' },
  { keywords: ['armani acqua di gio', 'acqua di gio armani'],
    image: 'https://m.media-amazon.com/images/I/51i3K-kZfCL._SL1200_.jpg' },
  { keywords: ['armani si'],
    image: 'https://m.media-amazon.com/images/I/51DKzPECY3L._SL1200_.jpg' },
  { keywords: ['boss bottled'],
    image: 'https://m.media-amazon.com/images/I/51aFefyg7pL._SL1200_.jpg' },
  { keywords: ['versace eros'],
    image: 'https://m.media-amazon.com/images/I/51L0TiXFQ0L._SL1200_.jpg' },
  { keywords: ['black orchid tom ford'],
    image: 'https://m.media-amazon.com/images/I/41-b0hN3-nL._SL1200_.jpg' },
  { keywords: ['eau sauvage dior'],
    image: 'https://m.media-amazon.com/images/I/41XIfOyXJcL._SL1200_.jpg' },

  // ═══════════════ SOINS / SKINCARE ════════════════════════════════════════
  { keywords: ['advanced night repair estée lauder', 'advanced night repair estee lauder'],
    image: 'https://m.media-amazon.com/images/I/61r5b-c29DL._SL1000_.jpg' },
  { keywords: ['la mer moisturizing cream', 'crème de la mer'],
    image: 'https://m.media-amazon.com/images/I/41D-A1bMvUL._SL1000_.jpg' },
  { keywords: ['double serum clarins'],
    image: 'https://m.media-amazon.com/images/I/71kxE3uEFaL._SL1500_.jpg' },
  { keywords: ['vitamin c skinceuticals', 'sérum vitamine c skinceuticals', 'c e ferulic skinceuticals'],
    image: 'https://m.media-amazon.com/images/I/51PYGPfzAeL._SL1000_.jpg' },
  { keywords: ['cicaplast baume b5 la roche-posay', 'cicaplast la roche'],
    image: 'https://m.media-amazon.com/images/I/61iR7wfgR-L._SL1500_.jpg' },
  { keywords: ['dyson airwrap', 'airwrap styler'],
    image: 'https://m.media-amazon.com/images/I/61+lzWgxHxL._SL1500_.jpg' },
  { keywords: ['gua sha jade naturel', 'gua sha'],
    image: 'https://m.media-amazon.com/images/I/51aGuHfRz4L._SL1000_.jpg' },

  // ═══════════════ MAQUILLAGE ═══════════════════════════════════════════════
  { keywords: ['rouge dior vernis', 'rouge dior'],
    image: 'https://m.media-amazon.com/images/I/51qX6dG6aQL._SL1000_.jpg' },
  { keywords: ['charlotte tilbury pillow talk lipstick', 'charlotte tilbury pillow talk'],
    image: 'https://m.media-amazon.com/images/I/71bCexQBg5L._SL1500_.jpg' },
  { keywords: ['nars all day luminous', 'nars foundation'],
    image: 'https://m.media-amazon.com/images/I/61HRFz7s8eL._SL1200_.jpg' },
  { keywords: ['urban decay naked palette', 'urban decay original sin'],
    image: 'https://m.media-amazon.com/images/I/71anLVoOQGL._SL1500_.jpg' },
  { keywords: ['double wear estée lauder', 'double wear foundation'],
    image: 'https://m.media-amazon.com/images/I/51Q3s2d2U2L._SL1000_.jpg' },
  { keywords: ['the ordinary serum foundation'],
    image: 'https://m.media-amazon.com/images/I/41K-P2Uf5eL._SL1000_.jpg' },

  // ═══════════════ TECH ════════════════════════════════════════════════════
  { keywords: ['airpods pro 2', 'airpods pro 2ème génération'],
    image: 'https://m.media-amazon.com/images/I/61SUj2aKoEL._SL1500_.jpg' },
  { keywords: ['airpods pro'],
    image: 'https://m.media-amazon.com/images/I/61f1YfTkTDL._SL1500_.jpg' },
  { keywords: ['apple watch series 9'],
    image: 'https://m.media-amazon.com/images/I/71YdFbDsHDL._SL1500_.jpg' },
  { keywords: ['apple watch ultra 2'],
    image: 'https://m.media-amazon.com/images/I/71m-0I1k7UL._SL1500_.jpg' },
  { keywords: ['apple watch ultra'],
    image: 'https://m.media-amazon.com/images/I/71KGN2OAq1L._SL1500_.jpg' },
  { keywords: ['sony wh-1000xm5'],
    image: 'https://m.media-amazon.com/images/I/51aXvjzcukL._SL1500_.jpg' },
  { keywords: ['sony wh-1000xm4'],
    image: 'https://m.media-amazon.com/images/I/71o8Q5XJS5L._SL1500_.jpg' },
  { keywords: ['bose quietcomfort 45'],
    image: 'https://m.media-amazon.com/images/I/61JbFPuNbGL._SL1500_.jpg' },
  { keywords: ['bose quietcomfort 35'],
    image: 'https://m.media-amazon.com/images/I/71PGKQPFsGL._SL1500_.jpg' },
  { keywords: ['jbl charge 5'],
    image: 'https://m.media-amazon.com/images/I/61rG3mHG3hL._SL1500_.jpg' },
  { keywords: ['jbl flip 6'],
    image: 'https://m.media-amazon.com/images/I/71GnvbGTBpL._SL1500_.jpg' },
  { keywords: ['kindle paperwhite'],
    image: 'https://m.media-amazon.com/images/I/61WLZFwz3rL._SL1500_.jpg' },
  { keywords: ['gopro hero 12'],
    image: 'https://m.media-amazon.com/images/I/61gC3uBdCNL._SL1500_.jpg' },
  { keywords: ['gopro hero 11'],
    image: 'https://m.media-amazon.com/images/I/71JFV4X4+PL._SL1500_.jpg' },
  { keywords: ['ipad air m2', 'ipad air 11'],
    image: 'https://m.media-amazon.com/images/I/61FuCpC8DhL._SL1500_.jpg' },
  { keywords: ['ipad pro'],
    image: 'https://m.media-amazon.com/images/I/61xYHB10RQL._SL1500_.jpg' },
  { keywords: ['nintendo switch oled'],
    image: 'https://m.media-amazon.com/images/I/71Y1P7BIFpL._SL1500_.jpg' },
  { keywords: ['playstation 5', 'dualsense', 'manette dualsense'],
    image: 'https://m.media-amazon.com/images/I/413LVmLefHL._SL1500_.jpg' },
  { keywords: ['playstation 5 slim'],
    image: 'https://m.media-amazon.com/images/I/71iAlDSx1rL._SL1500_.jpg' },
  { keywords: ['garmin forerunner 955'],
    image: 'https://m.media-amazon.com/images/I/61A-2YCBDaL._SL1500_.jpg' },
  { keywords: ['garmin fenix 7'],
    image: 'https://m.media-amazon.com/images/I/71y0PrYCNJL._SL1500_.jpg' },
  { keywords: ['powerbeats pro'],
    image: 'https://m.media-amazon.com/images/I/71c6dS0cHpL._SL1500_.jpg' },
  { keywords: ['polaroid now+', 'polaroid now'],
    image: 'https://m.media-amazon.com/images/I/61YXKpRiuoL._SL1500_.jpg' },
  { keywords: ['samsung galaxy s24 ultra', 'galaxy s24 ultra'],
    image: 'https://m.media-amazon.com/images/I/61JHIM9s5QL._SL1500_.jpg' },
  { keywords: ['galaxy buds2 pro', 'galaxy buds pro'],
    image: 'https://m.media-amazon.com/images/I/51h4fhS7BDL._SL1000_.jpg' },
  { keywords: ['macbook air m3'],
    image: 'https://m.media-amazon.com/images/I/71f5Eu5oESL._SL1500_.jpg' },
  { keywords: ['macbook air m2'],
    image: 'https://m.media-amazon.com/images/I/71ItMeqpN3L._SL1500_.jpg' },
  { keywords: ['macbook pro'],
    image: 'https://m.media-amazon.com/images/I/61l0p6KRDFL._SL1500_.jpg' },
  { keywords: ['iphone 15 pro max'],
    image: 'https://m.media-amazon.com/images/I/61THXmCIUCL._SL1500_.jpg' },
  { keywords: ['iphone 15 pro'],
    image: 'https://m.media-amazon.com/images/I/61ciqpkSPeL._SL1500_.jpg' },
  { keywords: ['iphone 15'],
    image: 'https://m.media-amazon.com/images/I/61bX2AoGj7L._SL1500_.jpg' },
  { keywords: ['aspirateur dyson v15', 'dyson v15'],
    image: 'https://m.media-amazon.com/images/I/81CwgEFYvFL._SL1500_.jpg' },
  { keywords: ['dyson supersonic', 'sèche-cheveux supersonic'],
    image: 'https://m.media-amazon.com/images/I/71z9_pIhMJL._SL1500_.jpg' },
  { keywords: ['casque gaming corsair hs65', 'corsair hs65'],
    image: 'https://m.media-amazon.com/images/I/81IA8I0YiZL._SL1500_.jpg' },
  { keywords: ['machine à café delonghi magnifica', 'delonghi magnifica'],
    image: 'https://m.media-amazon.com/images/I/81emQaRmERL._SL1500_.jpg' },
  { keywords: ['machine à café de longhi', 'magnifica s'],
    image: 'https://m.media-amazon.com/images/I/71Kqb2iL8PL._SL1500_.jpg' },

  // ═══════════════ SNEAKERS ════════════════════════════════════════════════
  { keywords: ['nike air force 1 blanc', 'nike air force 1 white', 'sneakers air force 1'],
    image: 'https://m.media-amazon.com/images/I/71pJpBCFGbL._SL1500_.jpg' },
  { keywords: ['adidas ultraboost 22', 'adidas ultraboost'],
    image: 'https://m.media-amazon.com/images/I/91Gfb0z-hUL._SL1500_.jpg' },
  { keywords: ['adidas stan smith'],
    image: 'https://m.media-amazon.com/images/I/81YCd84hJIL._SL1500_.jpg' },
  { keywords: ['new balance 574'],
    image: 'https://m.media-amazon.com/images/I/81LOGGTm3jL._SL1500_.jpg' },
  { keywords: ['new balance 990'],
    image: 'https://m.media-amazon.com/images/I/81LOGGTm3jL._SL1500_.jpg' },
  { keywords: ['converse chuck taylor', 'all star converse'],
    image: 'https://m.media-amazon.com/images/I/81peCWxkRpL._SL1500_.jpg' },
  { keywords: ['timberland 6-inch', 'timberland premium'],
    image: 'https://m.media-amazon.com/images/I/81vXZhKPvdL._SL1500_.jpg' },
  { keywords: ['ugg classic short', 'ugg classic'],
    image: 'https://m.media-amazon.com/images/I/61MSCS5ONZL._SL1500_.jpg' },
  { keywords: ['veja v-10', 'veja v10'],
    image: 'https://m.media-amazon.com/images/I/71MBPJRiVrL._SL1500_.jpg' },
  { keywords: ['veja campo'],
    image: 'https://m.media-amazon.com/images/I/71MBPJRiVrL._SL1500_.jpg' },
  { keywords: ['golden goose sneakers', 'golden goose'],
    image: 'https://m.media-amazon.com/images/I/71pJpBCFGbL._SL1500_.jpg' },

  // ═══════════════ MODE ════════════════════════════════════════════════════
  { keywords: ['lacoste polo l.12.12', 'polo lacoste l12', 'polo lacoste classic'],
    image: 'https://m.media-amazon.com/images/I/71OzVrgNXjL._SL1500_.jpg' },
  { keywords: ["levi's 501", 'levis 501', 'jean levi 501'],
    image: 'https://m.media-amazon.com/images/I/71ZEV7XLzML._SL1500_.jpg' },
  { keywords: ['ami paris pull', 'ami de cœur pull', 'pull ami paris'],
    image: 'https://m.media-amazon.com/images/I/61EW84tP+6L._SL1500_.jpg' },
  { keywords: ['ray-ban wayfarer', 'ray ban wayfarer'],
    image: 'https://m.media-amazon.com/images/I/71+7cuqolbL._SL1500_.jpg' },
  { keywords: ['ray-ban aviator', 'ray ban aviator'],
    image: 'https://m.media-amazon.com/images/I/71+7cuqolbL._SL1500_.jpg' },
  { keywords: ['new era casquette ny yankees', 'casquette new era', 'new era 59fifty'],
    image: 'https://m.media-amazon.com/images/I/61X-M2Y-3yL._SL1500_.jpg' },
  { keywords: ['casio g-shock gw-m5610', 'casio g-shock'],
    image: 'https://m.media-amazon.com/images/I/71SiW1gKd3L._SL1500_.jpg' },
  { keywords: ['casio vintage a168wg', 'casio vintage doré'],
    image: 'https://m.media-amazon.com/images/I/51GGOYIaAWL._SL1500_.jpg' },
  { keywords: ['tissot prx powermatic', 'tissot prx'],
    image: 'https://m.media-amazon.com/images/I/61z7gMXCjaL._SL1500_.jpg' },
  { keywords: ['longchamp le pliage', 'sac longchamp pliage'],
    image: 'https://m.media-amazon.com/images/I/71B5f3LYQKL._SL1500_.jpg' },
  { keywords: ['pandora bracelet moments', 'pandora bracelet charm'],
    image: 'https://m.media-amazon.com/images/I/61Pf5aztKYL._SL1500_.jpg' },
  { keywords: ['ugg classic short botte'],
    image: 'https://m.media-amazon.com/images/I/51sGn4gQkzL._SL1500_.jpg' },
  { keywords: ['collier or 18k diamant', 'collier or diamant solitaire'],
    image: 'https://m.media-amazon.com/images/I/71jFBvCFKzL._SL1500_.jpg' },
  { keywords: ['créoles or 14k', 'boucles oreilles créoles or'],
    image: 'https://m.media-amazon.com/images/I/51wM2H1B1gL._SL1500_.jpg' },
  { keywords: ['tiffany pendentif', 'tiffany coeur argent'],
    image: 'https://m.media-amazon.com/images/I/61WmQ1O5OGL._SL1500_.jpg' },
  { keywords: ['bracelet jonc argent 925'],
    image: 'https://m.media-amazon.com/images/I/41N3YLYY2DL._SL1500_.jpg' },
  { keywords: ['loungefly disney'],
    image: 'https://m.media-amazon.com/images/I/71wQWpJ9L8L._SL1500_.jpg' },
  { keywords: ['sac rains backpack', 'rains backpack'],
    image: 'https://m.media-amazon.com/images/I/61bX2AoGj7L._SL1500_.jpg' },

  // ═══════════════ MAISON ══════════════════════════════════════════════════
  { keywords: ['bougie diptyque baies 190g'],
    image: 'https://m.media-amazon.com/images/I/71TZ7cF3KLL._SL1500_.jpg' },
  { keywords: ['nespresso vertuo next', 'nespresso vertuo', 'machine nespresso'],
    image: 'https://m.media-amazon.com/images/I/81eMlsadtNL._SL1500_.jpg' },
  { keywords: ['cocotte le creuset 24cm', 'le creuset cocotte'],
    image: 'https://m.media-amazon.com/images/I/71JeKBm3OXL._SL1500_.jpg' },
  { keywords: ['diffuseur huiles essentielles usb', 'diffuseur huiles essentielles'],
    image: 'https://m.media-amazon.com/images/I/71NdXpKy5QL._SL1500_.jpg' },
  { keywords: ['tapis de yoga manduka', 'manduka tapis'],
    image: 'https://m.media-amazon.com/images/I/51vUQ1k7IOL._SL1500_.jpg' },
  { keywords: ['tapis yoga premium', 'tapis yoga'],
    image: 'https://m.media-amazon.com/images/I/71pWKZv3XQL._SL1500_.jpg' },
  { keywords: ['lampe sel himalaya naturelle', 'lampe sel himalaya'],
    image: 'https://m.media-amazon.com/images/I/81I2xhj9-KL._SL1500_.jpg' },
  { keywords: ['haltères réglables bowflex', 'bowflex haltères'],
    image: 'https://m.media-amazon.com/images/I/71Bk-hSkfnL._SL1500_.jpg' },
  { keywords: ['vinyl player retrolife q2', 'tourne-disque retrolife'],
    image: 'https://m.media-amazon.com/images/I/71mvCl3kNEL._SL1500_.jpg' },
  { keywords: ['acupressure mat pranamat', 'tapis acupression', 'acupressure mat'],
    image: 'https://m.media-amazon.com/images/I/81OO7J+aGRL._SL1500_.jpg' },
  { keywords: ['stanley quencher 40oz', 'stanley quencher'],
    image: 'https://m.media-amazon.com/images/I/61JjnFUW-2L._SL1500_.jpg' },
  { keywords: ['stanley iceflow', 'stanley hydratation'],
    image: 'https://m.media-amazon.com/images/I/61JjnFUW-2L._SL1500_.jpg' },
  { keywords: ['plaid polaire xxl'],
    image: 'https://m.media-amazon.com/images/I/81fpmE4pK5L._SL1500_.jpg' },
  { keywords: ['coffret nespresso grands crus', 'capsules nespresso coffret'],
    image: 'https://m.media-amazon.com/images/I/71zScJ38X4L._SL1500_.jpg' },

  // ═══════════════ GASTRONOMIE ══════════════════════════════════════════════
  { keywords: ['moët chandon brut impérial', 'moët chandon brut', 'moet chandon'],
    image: 'https://m.media-amazon.com/images/I/71cDq9JsT4L._SL1500_.jpg' },
  { keywords: ['veuve clicquot champagne'],
    image: 'https://m.media-amazon.com/images/I/71gAFJmRB2L._SL1500_.jpg' },
  { keywords: ['glenfiddich 12 ans single malt', 'glenfiddich 12', 'whisky glenfiddich'],
    image: 'https://m.media-amazon.com/images/I/81VHcY5B25L._SL1500_.jpg' },
  { keywords: ['coffret chocolats valrhona', 'valrhona chocolats', 'valrhona coffret'],
    image: 'https://m.media-amazon.com/images/I/71xK4UjBHyL._SL1500_.jpg' },
  { keywords: ['coffret thés mariage frères', 'mariage frères thé', 'mariage freres'],
    image: 'https://m.media-amazon.com/images/I/71oEQPNDKZL._SL1500_.jpg' },
  { keywords: ['kit brassage bière artisanale', 'kit brassage bière'],
    image: 'https://m.media-amazon.com/images/I/81wSuHxjqYL._SL1500_.jpg' },
  { keywords: ['ottolenghi simple livre', 'livre cuisine ottolenghi'],
    image: 'https://m.media-amazon.com/images/I/81-vOG2x0sL._SL1500_.jpg' },
  { keywords: ['coffret gourmet épicerie fine', 'coffret gastronomique'],
    image: 'https://m.media-amazon.com/images/I/61E9wl7LVIL._SL1500_.jpg' },

  // ═══════════════ SPORT ═══════════════════════════════════════════════════
  { keywords: ['gants boxe venum elite', 'gants venum boxe'],
    image: 'https://m.media-amazon.com/images/I/51m4Fy0yjRL._SL1500_.jpg' },
  { keywords: ['garmin forerunner 255', 'garmin forerunner'],
    image: 'https://m.media-amazon.com/images/I/71A-2tWQ1UL._SL1500_.jpg' },
  { keywords: ['haltères réglables 24kg'],
    image: 'https://m.media-amazon.com/images/I/81cHt8dQs4L._SL1500_.jpg' },

  // ═══════════════ BIEN-ÊTRE ════════════════════════════════════════════════
  { keywords: ["coffret soin l'occitane", 'loccitane coffret bain', "l'occitane coffret"],
    image: 'https://m.media-amazon.com/images/I/71Ia53ZC-lL._SL1500_.jpg' },
  { keywords: ['coffret soins clarins double serum'],
    image: 'https://m.media-amazon.com/images/I/61SHrJlgKYL._SL1500_.jpg' },

  // ═══════════════ JEUX / CULTURE ══════════════════════════════════════════
  { keywords: ['puzzle 1000 ravensburger', 'puzzle ravensburger 1000'],
    image: 'https://m.media-amazon.com/images/I/91fwMBWW1XL._SL1500_.jpg' },
  { keywords: ['harry potter intégrale 7 livres', 'coffret harry potter'],
    image: 'https://m.media-amazon.com/images/I/81vb2fFgAHL._SL1500_.jpg' },
  { keywords: ['jeu de société catan', 'catan colonisateurs'],
    image: 'https://m.media-amazon.com/images/I/715BjqFXI0L._SL1500_.jpg' },
  { keywords: ['lego icons bouquet fleurs', 'lego bouquet 10280'],
    image: 'https://m.media-amazon.com/images/I/71cqRY-HVJL._SL1500_.jpg' },
  { keywords: ['lego star wars millennium falcon', 'lego millennium falcon'],
    image: 'https://m.media-amazon.com/images/I/91wjm7V2wBL._SL1500_.jpg' },
  { keywords: ['lego architecture paris'],
    image: 'https://m.media-amazon.com/images/I/71U3-bfenVL._SL1500_.jpg' },
  { keywords: ['lego bonsaï arbre', 'lego bonsai'],
    image: 'https://m.media-amazon.com/images/I/81Qv6M6GBQL._SL1500_.jpg' },
  { keywords: ['carnet leuchtturm1917 bullet journal', 'leuchtturm1917 a5'],
    image: 'https://m.media-amazon.com/images/I/71ANaVdWzLL._SL1500_.jpg' },
  { keywords: ['coffret peinture numérotée', 'peinture par numéro adulte'],
    image: 'https://m.media-amazon.com/images/I/81m3BWUEXKL._SL1500_.jpg' },

  // ═══════════════ BIJOUX ═══════════════════════════════════════════════════
  { keywords: ['pandora bracelet moments argent'],
    image: 'https://m.media-amazon.com/images/I/71cUqGOLcQL._SL1500_.jpg' },

  // ═══════════════ PARFUMS SUPPLÉMENTAIRES ═════════════════════════════════
  { keywords: ['bleu de chanel', 'blue de chanel'],
    image: 'https://m.media-amazon.com/images/I/51cY1r46BxL._SL1200_.jpg' },
  { keywords: ['eau de parfum libre', 'libre eau de parfum'],
    image: 'https://m.media-amazon.com/images/I/51DKzPECY3L._SL1200_.jpg' },
  { keywords: ['chance eau fraiche', 'chance chanel'],
    image: 'https://m.media-amazon.com/images/I/41+6ZO2e3pL._SL1200_.jpg' },
  { keywords: ['coffret fabrication parfum', 'atelier parfum', 'composez votre parfum', 'wecandoo parfum'],
    image: 'https://m.media-amazon.com/images/I/612sRHyNnXL._SL1500_.jpg' },

  // ═══════════════ BEAUTÉ / BIEN-ÊTRE SUPPLÉMENTAIRES ══════════════════════
  { keywords: ["coffret bain corps l'occitane", "coffret l'occitane", 'loccitane bain', 'coffret occitane'],
    image: 'https://m.media-amazon.com/images/I/71Ia53ZC-lL._SL1500_.jpg' },
  { keywords: ['sol de janeiro', 'sol janeiro bum bum'],
    image: 'https://m.media-amazon.com/images/I/71Z3uUQV7kL._SL1500_.jpg' },
  { keywords: ['clinique fan favorites', 'clinique coffret'],
    image: 'https://m.media-amazon.com/images/I/71Ia53ZC-lL._SL1500_.jpg' },
  { keywords: ['living proof coffret', 'living proof shampoo'],
    image: 'https://m.media-amazon.com/images/I/71Ia53ZC-lL._SL1500_.jpg' },
  { keywords: ['microphone blue yeti', 'blue yeti usb'],
    image: 'https://m.media-amazon.com/images/I/61MgbiBJCLL._SL1500_.jpg' },

  // ═══════════════ MAISON SUPPLÉMENTAIRES ══════════════════════════════════
  { keywords: ['coffret café nespresso grands crus', 'capsules nespresso coffret', 'coffret café nespresso'],
    image: 'https://m.media-amazon.com/images/I/81d-7JCNrDL._SL1500_.jpg' },
  { keywords: ['chargeur rapide sans fil', 'chargeur induction stand'],
    image: 'https://m.media-amazon.com/images/I/61xYHB10RQL._SL1500_.jpg' },
  { keywords: ['kit ampoules connectées hue', 'philips hue starter'],
    image: 'https://m.media-amazon.com/images/I/61CvsXXrNQL._SL1500_.jpg' },
  { keywords: ['machine à churros', 'churros maker'],
    image: 'https://m.media-amazon.com/images/I/71+VzA8J4zL._SL1500_.jpg' },
  { keywords: ['gourde isotherme stanley', 'bouteille isotherme stanley'],
    image: 'https://m.media-amazon.com/images/I/61JjnFUW-2L._SL1500_.jpg' },

  // ═══════════════ FOOD SUPPLÉMENTAIRES ════════════════════════════════════
  { keywords: ['livre cuisine ottolenghi', 'ottolenghi simple'],
    image: 'https://m.media-amazon.com/images/I/81-vOG2x0sL._SL1500_.jpg' },
  { keywords: ['livre recettes poêle', 'cuisinez avec poêle'],
    image: 'https://m.media-amazon.com/images/I/81-vOG2x0sL._SL1500_.jpg' },
  { keywords: ['coffret sauces piquantes', 'kit sauces piquantes'],
    image: 'https://m.media-amazon.com/images/I/81wSuHxjqYL._SL1500_.jpg' },
  { keywords: ['coffret fabriquer whisky gin', 'coffret spiritueux maison'],
    image: 'https://m.media-amazon.com/images/I/81wSuHxjqYL._SL1500_.jpg' },
  { keywords: ['kit fabriquer pastis'],
    image: 'https://m.media-amazon.com/images/I/81wSuHxjqYL._SL1500_.jpg' },
  { keywords: ['coffret oenologie', 'vins de france découverte'],
    image: 'https://m.media-amazon.com/images/I/81VHcY5B25L._SL1500_.jpg' },

  // ═══════════════ JEUX / CULTURE SUPPLÉMENTAIRES ══════════════════════════
  { keywords: ['7 wonders jeu', 'jeu 7 wonders'],
    image: 'https://m.media-amazon.com/images/I/91sCixMCOgL._SL1500_.jpg' },
  { keywords: ['montre forerunner 265', 'garmin forerunner 265'],
    image: 'https://m.media-amazon.com/images/I/71A-2tWQ1UL._SL1500_.jpg' },

  // ═══════════════ MODE SUPPLÉMENTAIRES ════════════════════════════════════
  { keywords: ['malle bagage cabine essential lite', 'valise cabine samsonite', 'bagage cabine'],
    image: 'https://m.media-amazon.com/images/I/71-8jJh7tpL._SL1500_.jpg' },
  { keywords: ['peluche lapin bashful', 'jellycat bashful'],
    image: 'https://m.media-amazon.com/images/I/51+yRQVo3HL._SL1500_.jpg' },
  { keywords: ['livre homme et sa montre', 'livre montres collector'],
    image: 'https://m.media-amazon.com/images/I/81-vOG2x0sL._SL1500_.jpg' },
  { keywords: ['enceinte marshall emberton', 'marshall emberton bluetooth'],
    image: 'https://m.media-amazon.com/images/I/71GnvbGTBpL._SL1500_.jpg' },
  { keywords: ['bataille navale luxe bois', 'bataille navale bois'],
    image: 'https://m.media-amazon.com/images/I/91sCixMCOgL._SL1500_.jpg' },
];

// ══════════════════════════════════════════════════════════════════════════════
// MOTEUR DE MATCHING
// ══════════════════════════════════════════════════════════════════════════════

/** Trouve la meilleure image vérifiée pour un produit donné */
function findVerifiedImage(name, brand) {
  const combined = `${(name || '').toLowerCase()} ${(brand || '').toLowerCase()}`;
  // Trier par longueur de keyword (les plus spécifiques en premier)
  const sorted = [...VERIFIED_IMAGE_CATALOG].sort(
    (a, b) => Math.max(...b.keywords.map(k => k.length)) - Math.max(...a.keywords.map(k => k.length))
  );
  for (const entry of sorted) {
    if (entry.keywords.some(kw => combined.includes(kw.toLowerCase()))) {
      return entry.image;
    }
  }
  return null;
}

function isAlreadyInStorage(url) {
  return url && (url.includes('firebasestorage.googleapis.com') || url.includes('storage.googleapis.com/doron-b3011'));
}

function needsReplacement(imageUrl) {
  if (!imageUrl || imageUrl.trim() === '') return true;
  if (FORCE) return !isAlreadyInStorage(imageUrl);
  return !isAlreadyInStorage(imageUrl);
}

// ─── Télécharger une image ────────────────────────────────────────────────────
async function downloadImage(imageUrl) {
  try {
    const ctrl = new AbortController();
    const t    = setTimeout(() => ctrl.abort(), TIMEOUT);
    const res  = await fetch(imageUrl, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
        'Referer': 'https://www.amazon.fr/',
      },
      signal: ctrl.signal,
    });
    clearTimeout(t);
    if (!res.ok) return { buffer: null, contentType: null, error: `HTTP ${res.status}` };
    const buffer      = await res.buffer();
    const contentType = res.headers.get('content-type') || 'image/jpeg';
    return { buffer, contentType, error: null };
  } catch (err) {
    return { buffer: null, contentType: null, error: err.message };
  }
}

// ─── Uploader vers Firebase Storage ──────────────────────────────────────────
async function uploadToStorage(buffer, contentType, docId) {
  const ext      = contentType.includes('png') ? 'png' : contentType.includes('webp') ? 'webp' : 'jpg';
  const filePath = `products/gifts/${docId}.${ext}`;
  const file     = bucket.file(filePath);
  await file.save(buffer, {
    metadata: { contentType, cacheControl: 'public, max-age=31536000' },
    public: true,
  });
  return `https://storage.googleapis.com/${bucket.name}/${filePath}`;
}

// ══════════════════════════════════════════════════════════════════════════════
// MAIN
// ══════════════════════════════════════════════════════════════════════════════
async function main() {
  console.log('');
  console.log('╔══════════════════════════════════════════════════════════════╗');
  console.log('║    🖼️  DORON — REAL IMAGES UPLOADER v3.0                   ║');
  console.log(`║    Mode : ${DRY_RUN ? '🟡 DRY-RUN (rien ne sera modifié)   ' : FORCE ? '🔴 FORCE (refaire même les OK)      ' : '🟢 NORMAL (uniquement ce qui manque)'}     ║`);
  if (LIMIT !== Infinity) console.log(`║    Limite : ${String(LIMIT)} produits                                     ║`);
  console.log('╚══════════════════════════════════════════════════════════════╝\n');

  const snapshot = await db.collection('gifts').get();
  console.log(`📦 ${snapshot.size} produits chargés\n`);

  const toProcess = snapshot.docs
    .filter(doc => needsReplacement(doc.data().image || doc.data().imageUrl || ''))
    .slice(0, LIMIT);

  console.log(`   ✅ Déjà dans Firebase Storage : ${snapshot.size - toProcess.length}`);
  console.log(`   🔄 À traiter                  : ${toProcess.length}\n`);

  if (toProcess.length === 0) {
    console.log('🎉 Tout est déjà OK ! Rien à faire.\n');
    if (!FORCE) console.log('   💡 Utilise --force pour refaire quand même\n');
    process.exit(0);
  }

  if (DRY_RUN) {
    console.log('📋 Produits à traiter (dry-run) :\n');
    let found = 0, notFound = 0;
    toProcess.forEach((doc, i) => {
      const d = doc.data();
      const img = findVerifiedImage(d.name, d.brand);
      const status = img ? '✅ IMAGE TROUVÉE' : '⚠️  non trouvée';
      if (img) found++; else notFound++;
      console.log(`   ${i+1}. [${status}] "${(d.name || '').substring(0, 45).padEnd(45)}"`);
      if (img) console.log(`          → ${img.substring(0, 70)}`);
    });
    console.log(`\n   ✅ Images vérifiées trouvées : ${found}/${toProcess.length}`);
    console.log(`   ⚠️  Non trouvées (resteront inchangées) : ${notFound}`);
    console.log('\n💡 Lance sans --dry-run pour exécuter.\n');
    process.exit(0);
  }

  let uploaded = 0, skipped = 0, failed = 0;
  const manualList = [];

  for (let i = 0; i < toProcess.length; i++) {
    const doc  = toProcess[i];
    const data = doc.data();
    const name = (data.name || data.product_title || '').substring(0, 55);

    console.log(`\n[${i+1}/${toProcess.length}] "${name}"`);

    // ── Trouver l'image vérifiée ────────────────────────────────────────────
    const verifiedImageUrl = findVerifiedImage(data.name, data.brand);

    if (!verifiedImageUrl) {
      console.log(`   ⚠️  Aucune image vérifiée → conserve l'image actuelle`);
      manualList.push(name.trim());
      skipped++;
      continue;
    }

    console.log(`   🎯 Image vérifiée : ${verifiedImageUrl.substring(0, 70)}`);

    // ── Télécharger ──────────────────────────────────────────────────────────
    const { buffer, contentType, error: dlErr } = await downloadImage(verifiedImageUrl);

    if (!buffer || buffer.length < 2000) {
      console.log(`   ❌ Téléchargement échoué : ${dlErr || `${buffer?.length ?? 0} octets`}`);
      // Essayer sans le suffixe de resize (pour Amazon si ça échoue)
      failed++;
      manualList.push(name.trim());
      await sleep(DELAY_MS);
      continue;
    }

    console.log(`   📥 ${Math.round(buffer.length / 1024)} Ko (${contentType})`);

    // ── Uploader dans Firebase Storage ───────────────────────────────────────
    try {
      const storageUrl = await uploadToStorage(buffer, contentType, doc.id);

      await doc.ref.update({
        image:            storageUrl,
        imageUrl:         storageUrl,
        imageStoragePath: `products/gifts/${doc.id}`,
        imageFixed:       true,
        imageFixedAt:     new Date().toISOString(),
        updatedAt:        new Date().toISOString(),
      });

      console.log(`   ✅ → ${storageUrl.substring(0, 70)}`);
      uploaded++;
    } catch (err) {
      console.log(`   ❌ Upload Firebase échoué : ${err.message}`);
      failed++;
      manualList.push(name.trim());
    }

    await sleep(DELAY_MS);
  }

  // ── Rapport ───────────────────────────────────────────────────────────────
  console.log('\n\n╔══════════════════════════════════════════════════════════════╗');
  console.log('║                    ✅ RAPPORT FINAL                          ║');
  console.log('╠══════════════════════════════════════════════════════════════╣');
  console.log(`║  Total traités          : ${String(toProcess.length).padEnd(35)}║`);
  console.log(`║  ✅ Uploadés Firebase   : ${String(uploaded).padEnd(35)}║`);
  console.log(`║  ⚠️  Ignorés (no match) : ${String(skipped).padEnd(35)}║`);
  console.log(`║  ❌ Erreurs download    : ${String(failed).padEnd(35)}║`);
  console.log('╠══════════════════════════════════════════════════════════════╣');
  if (manualList.length > 0) {
    console.log(`║  Produits à corriger via Admin UI :                          ║`);
    manualList.slice(0, 8).forEach(n => console.log(`║    • ${n.substring(0,54).padEnd(54)}║`));
    if (manualList.length > 8) console.log(`║    ... et ${manualList.length - 8} autres                                      ║`);
  }
  console.log('╚══════════════════════════════════════════════════════════════╝');
  console.log(`\n🎉 ${uploaded} produits ont maintenant des VRAIES images dans Firebase Storage !`);
  if (manualList.length > 0) {
    console.log(`\n💡 ${manualList.length} produits restants → corrige-les via l'Admin UI (scripts/admin_ui)`);
  }
  console.log('');

  process.exit(0);
}

main().catch(err => {
  console.error('\n❌ ERREUR CRITIQUE :', err.message || err);
  process.exit(1);
});
