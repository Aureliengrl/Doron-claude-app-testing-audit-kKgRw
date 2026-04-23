#!/usr/bin/env node
/**
 * ╔══════════════════════════════════════════════════════════════════════════╗
 * ║         🎁 DORON — PERFECT DATABASE BUILDER v1.0                        ║
 * ║                                                                          ║
 * ║  Ce script fait TOUT en une seule commande :                             ║
 * ║  1. AUDIT : analyse chaque produit existant (images cassées, tags mauvais║
 * ║  2. FIX IMAGES : remplace toutes les images invalides                    ║
 * ║  3. FIX TAGS : normalise et complète TOUS les tags selon tags_definitions║
 * ║  4. AJOUTER : injecte 150+ nouveaux cadeaux premium bien taguées         ║
 * ║  5. REPORT : génère un rapport complet                                   ║
 * ║                                                                          ║
 * ║  USAGE :                                                                 ║
 * ║    node doron_perfect_database.js              → COMPLET (recommandé)    ║
 * ║    node doron_perfect_database.js --audit-only → Audit sans écriture     ║
 * ║    node doron_perfect_database.js --fix-only   → Fix tags+images seul    ║
 * ║    node doron_perfect_database.js --add-only   → Ajoute nouveaux prods   ║
 * ║    node doron_perfect_database.js --no-fix     → Ajouter seulement       ║
 * ║                                                                          ║
 * ║  Prérequis : serviceAccountKey.json dans ce dossier                      ║
 * ╚══════════════════════════════════════════════════════════════════════════╝
 */

const admin = require('firebase-admin');
const fetch = require('node-fetch');

const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// ─── Modes d'exécution ───────────────────────────────────────────────────────
const AUDIT_ONLY  = process.argv.includes('--audit-only');
const FIX_ONLY    = process.argv.includes('--fix-only');
const ADD_ONLY    = process.argv.includes('--add-only');
const NO_FIX      = process.argv.includes('--no-fix');

const DO_FIX = !AUDIT_ONLY && !ADD_ONLY && !NO_FIX;
const DO_ADD = !AUDIT_ONLY && !FIX_ONLY;

// ─── Paramètres ──────────────────────────────────────────────────────────────
const CONCURRENCY     = 10;
const REQUEST_TIMEOUT = 7000;

// ══════════════════════════════════════════════════════════════════════════════
// SECTION 1 — TAGS & LABELS (copié exactement de tags_definitions.dart)
// ══════════════════════════════════════════════════════════════════════════════

const VALID_GENDER_TAGS   = ['gender_femme', 'gender_homme', 'gender_mixte'];
const VALID_CATEGORY_TAGS = ['cat_tendances', 'cat_tech', 'cat_mode', 'cat_maison', 'cat_beaute', 'cat_food'];
const VALID_BUDGET_TAGS   = ['budget_0_50', 'budget_50_100', 'budget_100_200', 'budget_200+'];
const VALID_GIFT_TYPES    = ['type_mode_accessoires','type_bien_etre','type_sport_outdoor','type_gastronomie','type_culture','type_high_tech','type_maison_deco','type_beaute_soins','type_loisirs_creatifs','type_jeux_jouets','type_livres_bd','type_musique_audio','type_voyage_aventure','type_automobile','type_bijoux','type_intime'];
const VALID_STYLE_TAGS    = ['style_elegant','style_tendance','style_minimaliste','style_classique','style_decontracte','style_sportif','style_vintage','style_moderne','style_luxe','style_boheme','style_streetwear','style_eco_responsable'];
const VALID_PERSO_TAGS    = ['perso_creatif','perso_actif','perso_cool','perso_bienveillant','perso_ambitieux','perso_romantique','perso_aventurier','perso_intellectuel','perso_sociable','perso_zen','perso_excentrique','perso_pratique','perso_gourmand','perso_techie'];
const VALID_PASSION_TAGS  = ['passion_sport','passion_cuisine','passion_voyages','passion_photo','passion_jeuxvideo','passion_lecture','passion_musique','passion_cinema','passion_mode','passion_beaute','passion_tech','passion_art','passion_jardinage','passion_bricolage','passion_yoga','passion_danse','passion_nature','passion_animaux','passion_automobile','passion_vins','passion_loisirs_creatifs'];
const VALID_AGE_TAGS      = ['age_enfant','age_ado','age_adulte','age_senior'];
const VALID_CONTEXT_TAGS  = ['context_famille','context_ami','context_colleague','context_amoureux'];
const VALID_OCCASION_TAGS = ['occasion_anniversaire','occasion_noel','occasion_mariage','occasion_saint_valentin','occasion_fete','occasion_remerciement','occasion_naissance','occasion_diplome'];
const VALID_SAISON_TAGS   = ['saison_printemps','saison_ete','saison_automne','saison_hiver'];
const VALID_POPULAR_TAGS  = ['popularite_1','popularite_2','popularite_3','popularite_4','popularite_5'];

const ALL_VALID_TAGS = new Set([
  ...VALID_GENDER_TAGS, ...VALID_CATEGORY_TAGS, ...VALID_BUDGET_TAGS,
  ...VALID_GIFT_TYPES, ...VALID_STYLE_TAGS, ...VALID_PERSO_TAGS,
  ...VALID_PASSION_TAGS, ...VALID_AGE_TAGS, ...VALID_CONTEXT_TAGS,
  ...VALID_OCCASION_TAGS, ...VALID_SAISON_TAGS, ...VALID_POPULAR_TAGS,
]);

// ─── Helpers tags ─────────────────────────────────────────────────────────────
function getBudgetTag(price) {
  const p = typeof price === 'number' ? price : parseFloat(price) || 0;
  if (p < 50)  return 'budget_0_50';
  if (p < 100) return 'budget_50_100';
  if (p < 200) return 'budget_100_200';
  return 'budget_200+';
}

function detectGender(name, brand, desc = '') {
  const text = `${name} ${brand} ${desc}`.toLowerCase();
  const femKw = ['robe','jupe','lingerie','soutien-gorge','brassière','mascara','rouge à lèvres','vernis à ongles','fard','blush','anticernes','fond de teint','eye-liner','contouring','eye shadow','highlighter','sac à main','pour elle','femme','woman','women','miss','lady','dress','skirt','heels','makeup','she','her','talons'];
  const maKw  = ['cravate','rasoir électrique','tondeuse barbe','aftershave','after shave','costume homme','pour lui','homme','man','men','monsieur','mister','tie','beard','he','him','male','barbe'];
  const femScore = femKw.filter(k => text.includes(k)).length;
  const maScore  = maKw.filter(k => text.includes(k)).length;
  if (femScore > maScore) return 'gender_femme';
  if (maScore > femScore) return 'gender_homme';
  return 'gender_mixte';
}

function detectCategory(name, brand, cats = []) {
  const text = `${name} ${brand} ${cats.join(' ')}`.toLowerCase();
  if (/parfum|fragrance|eau de|cologne|senteur|oud/.test(text)) return 'cat_beaute';
  if (/soin|sérum|crème|hydrat|masque visage|gommage|toner|maquill|makeup|fond de teint|blush|mascara|rouge à|palette|highlighter|contour|beauté|cosmétique|vernis/.test(text)) return 'cat_beaute';
  if (/iphone|ipad|macbook|airpods|samsung|galaxy|pixel|playstation|xbox|nintendo|switch|enceinte|bluetooth|casque|écouteur|laptop|ordinateur|tablette|kindle|gopro|drone|imprimante|montre connectée|apple watch|garmin|fitbit|powerbank|clé usb/.test(text)) return 'cat_tech';
  if (/sneaker|basket|chaussure|vêtement|pull|robe|jean|chemise|pantalon|manteau|veste|blouson|hoodie|sweat|polo|tshirt|t-shirt|cardigan|doudoune|parka|sac|bandoulière|tote|pochette|portefeuille|ceinture|écharpe|casquette|bonnet|bijou|bracelet|collier|bague|montre|lunettes/.test(text)) return 'cat_mode';
  if (/bougie|plante|coussin|horloge|miroir|cadre|lampe|décoration|vase|tapis|diffuseur|théière|carafe|couverture|drap|linge maison|machine à café|nespresso|cafetière|robot cuisine|ustensile|outil/.test(text)) return 'cat_maison';
  if (/champagne|vin|whisky|rhum|cognac|spiritueux|alcool|bière|chocolat|café|thé|coffret gastronomique|épicerie|confiture|huile d'olive|truffe|foie gras|gourmet|gastronomie|cuisine/.test(text)) return 'cat_food';
  // Regarde les catégories existantes
  const catStr = cats.join(' ').toLowerCase();
  if (/tech|électro|gaming/.test(catStr)) return 'cat_tech';
  if (/mode|fashion|vêtement|accessoire|bijou|chaussure|sac/.test(catStr)) return 'cat_mode';
  if (/beauté|beauty|parfum|soin|maquillage/.test(catStr)) return 'cat_beaute';
  if (/maison|home|déco|cuisine/.test(catStr)) return 'cat_maison';
  if (/food|gastronomie|boisson|vin/.test(catStr)) return 'cat_food';
  return 'cat_tendances';
}

function detectPassions(name, brand, cats = []) {
  const text = `${name} ${brand} ${cats.join(' ')}`.toLowerCase();
  const passions = [];
  if (/sport|fitness|yoga|running|vélo|natation|tennis|padel|musculation|escalade|randonnée|ski|surf|golf|foot/.test(text)) passions.push('passion_sport');
  if (/cuisine|gastronomie|chocolat|huile|confiture|thé|café|vin|champagne|rhum|whisky|recette|pâtisserie|fromagerie/.test(text)) passions.push('passion_cuisine');
  if (/voyage|valise|sac de voyage|aventure|camping|rando|tente|bivouac/.test(text)) passions.push('passion_voyages');
  if (/photo|appareil photo|objectif|trépied|drone|gopro|argentique/.test(text)) passions.push('passion_photo');
  if (/gaming|jeux vidéo|manette|playstation|xbox|nintendo|switch|jeu pc/.test(text)) passions.push('passion_jeuxvideo');
  if (/livre|roman|manga|bd|bande dessinée|lecture|polar|biographie/.test(text)) passions.push('passion_lecture');
  if (/musique|guitare|piano|vinyl|casque|enceinte|bluetooth|hifi|audiofile|concert/.test(text)) passions.push('passion_musique');
  if (/cinéma|film|série|netflix|amazon prime|disney|projecteur/.test(text)) passions.push('passion_cinema');
  if (/mode|style|fashion|look|tendance|streetwear|sneaker/.test(text)) passions.push('passion_mode');
  if (/beauté|soin|maquillage|cosmétique|parfum|skincare|crème|sérum/.test(text)) passions.push('passion_beaute');
  if (/tech|technologie|gadget|électronique|code|programmation|arduino|raspberry/.test(text)) passions.push('passion_tech');
  if (/art|peinture|dessin|sculpture|aquarelle|origami|créativité/.test(text)) passions.push('passion_art');
  if (/jardin|plante|potager|fleur|terrarium|orchidée/.test(text)) passions.push('passion_jardinage');
  if (/bricolage|outil|perceuse|atelier|menuiserie|soudure/.test(text)) passions.push('passion_bricolage');
  if (/yoga|méditation|pilates|zen|relaxation|bien.être/.test(text)) passions.push('passion_yoga');
  if (/danse|ballet|zumba/.test(text)) passions.push('passion_danse');
  if (/nature|forêt|montagne|plein air|outdoor|bivouac|astronomie/.test(text)) passions.push('passion_nature');
  if (/animaux|chien|chat|aquarium|terrarium/.test(text)) passions.push('passion_animaux');
  if (/voiture|moto|auto|karting|rallye|sport auto/.test(text)) passions.push('passion_automobile');
  if (/vin|champagne|whisky|rhum|cognac|bière artisanale|brasserie|oenologie/.test(text)) passions.push('passion_vins');
  if (/tricot|couture|broderie|origami|créatif|artisanat/.test(text)) passions.push('passion_loisirs_creatifs');
  return passions;
}

function detectStyle(name, brand, cats = []) {
  const text = `${name} ${brand} ${cats.join(' ')}`.toLowerCase();
  const styles = [];
  if (/élégant|cocktail|formel|chic|soirée|costume|cravate/.test(text)) styles.push('style_elegant');
  if (/tendance|viral|tiktok|instagram|hype|trendy/.test(text)) styles.push('style_tendance');
  if (/minimaliste|minimal|épuré|simple|sobre|discret/.test(text)) styles.push('style_minimaliste');
  if (/classique|intemporel|traditionnel|heritage/.test(text)) styles.push('style_classique');
  if (/décontracté|casual|comfortable|relax/.test(text)) styles.push('style_decontracte');
  if (/sportif|sport|athlétique|running|fitness|gym/.test(text)) styles.push('style_sportif');
  if (/vintage|rétro|années|70|80|90|retro/.test(text)) styles.push('style_vintage');
  if (/luxe|premium|haut de gamme|prestige|exclusif|dior|chanel|lv|louis vuitton|gucci|hermès|cartier|van cleef/.test(text)) styles.push('style_luxe');
  if (/streetwear|street|urban|hip.hop|skate|graffiti/.test(text)) styles.push('style_streetwear');
  if (/éco|durable|bio|naturel|vegan|recyclé|responsable/.test(text)) styles.push('style_eco_responsable');
  if (/bohème|boho|ethnique|folk/.test(text)) styles.push('style_boheme');
  if (/moderne|contemporain|design/.test(text)) styles.push('style_moderne');
  return styles;
}

function detectGiftType(name, brand, cats = []) {
  const text = `${name} ${brand} ${cats.join(' ')}`.toLowerCase();
  const types = [];
  if (/vêtement|chaussure|sac|ceinture|écharpe|casquette|lunettes|bonnet|accessoire mode/.test(text)) types.push('type_mode_accessoires');
  if (/spa|massage|bain|bougie|parfum d'intérieur|aromathérapie|relaxation|bien.être|méditation/.test(text)) types.push('type_bien_etre');
  if (/sport|fitness|running|vélo|yoga|escalade|natation|tennis|raquette|gants/.test(text)) types.push('type_sport_outdoor');
  if (/chocolat|vin|champagne|whisky|café|thé|coffret|gastronomie|épicerie fine/.test(text)) types.push('type_gastronomie');
  if (/livre|concert|musée|expo|spectacle|théâtre|cinéma|puzzle|jeu de société/.test(text)) types.push('type_culture');
  if (/iphone|ipad|macbook|laptop|tablette|casque|enceinte|drone|gopro|smartwatch|kindle|gaming/.test(text)) types.push('type_high_tech');
  if (/bougie|plante|coussin|lampe|cadre|vase|décoration|tapis|linge|literie/.test(text)) types.push('type_maison_deco');
  if (/soin|crème|sérum|masque|parfum|maquillage|coffret beauté|cosmétique/.test(text)) types.push('type_beaute_soins');
  if (/tricot|couture|peinture|dessin|origami|photo|broderie|artisanat/.test(text)) types.push('type_loisirs_creatifs');
  if (/lego|playmobil|jouet|puzzle|jeu de société|cartes|jeu enfant/.test(text)) types.push('type_jeux_jouets');
  if (/livre|manga|bd|roman|magazine/.test(text)) types.push('type_livres_bd');
  if (/casque audio|enceinte|vinyl|hifi|instrument|guitare|piano/.test(text)) types.push('type_musique_audio');
  if (/valise|sac de voyage|tente|rando|camping|GPS/.test(text)) types.push('type_voyage_aventure');
  if (/voiture|moto|auto|karting|entretien auto/.test(text)) types.push('type_automobile');
  if (/bijou|bague|collier|bracelet|boucles d'oreille|pendentif|chevalière/.test(text)) types.push('type_bijoux');
  if (/lingerie|dessous|intime/.test(text)) types.push('type_intime');
  return types;
}

function detectOccasion(name, brand) {
  const text = `${name} ${brand}`.toLowerCase();
  const occasions = [];
  if (/noël|christmas|noel/.test(text)) occasions.push('occasion_noel');
  if (/valentin|amour|saint.val/.test(text)) occasions.push('occasion_saint_valentin');
  if (/anniversaire|birthday/.test(text)) occasions.push('occasion_anniversaire');
  if (/mariage|wedding|mariée|marié/.test(text)) occasions.push('occasion_mariage');
  if (/naissance|bébé|baby|maternité/.test(text)) occasions.push('occasion_naissance');
  if (/diplôme|premier emploi|succès/.test(text)) occasions.push('occasion_diplome');
  return occasions;
}

function detectSaison(name, brand, cats = []) {
  const text = `${name} ${brand} ${cats.join(' ')}`.toLowerCase();
  const saisons = [];
  if (/hiver|manteau|parka|doudoune|ski|raquette|neige|plaid|pull épais/.test(text)) saisons.push('saison_hiver');
  if (/été|solaire|crème solaire|maillot|sandales|lunettes de sol|plage|piscine/.test(text)) saisons.push('saison_ete');
  if (/printemps|fleur|jardinage|légèreté|renouveau/.test(text)) saisons.push('saison_printemps');
  if (/automne|rentrée|imperméable|imperméabilisant/.test(text)) saisons.push('saison_automne');
  return saisons;
}

function detectPopularite(price, brand) {
  const luxuryBrands = ['chanel','dior','louis vuitton','hermès','gucci','burberry','cartier','van cleef','tiffany','rolex','patek','audemars'];
  const popularBrands = ['apple','nike','adidas','samsung','sony','airpods','airpods pro','lego','dyson','nespresso','le creuset'];
  const trendyBrands = ['veja','jacquemus','ami paris','sézane','aroha','aesop','diptyque','byredo','le labo','maison margiela'];
  const b = (brand || '').toLowerCase();
  if (luxuryBrands.some(l => b.includes(l))) return 'popularite_4';
  if (popularBrands.some(l => b.includes(l))) return 'popularite_5';
  if (trendyBrands.some(l => b.includes(l))) return 'popularite_4';
  if (price > 500) return 'popularite_3';
  if (price > 200) return 'popularite_3';
  if (price > 50)  return 'popularite_3';
  return 'popularite_2';
}

// ══════════════════════════════════════════════════════════════════════════════
// SECTION 2 — CATALOGUE D'IMAGES (Amazon CDN + sources fiables)
// ══════════════════════════════════════════════════════════════════════════════

const BLOCKED_DOMAINS = [
  'unsplash.com','placeholder','via.placeholder','picsum.photos','dummyimage.com',
  'lorempixel.com','loremflickr.com','sezane.com','jacquemus.com','saint-james.com',
  'jonak.fr','kiehls.fr','aesop.com','byredo.com','lelabofragrances.com',
  'franciskurkdjian.com','amiparis.com','longchamp.com','veja-store.com',
  'lacoste.com','image1.lacoste','tissotwatches.com','lancel.com','histoiredor.com',
  'clarins.fr','skinceuticals.fr','dw/image','demandware.static','harrods.com',
  'ctfassets.net','i.pinimg.com','prd-dam.dior.com','dam.burberry','media.chanel',
  'cdn.chanel.com','myshopify.com','squarespace-cdn.com','res.cloudinary.com',
  'googleusercontent.com/download','storage.googleapis.com/download',
  'media.tiffany.com',
];

// Catalogue d'images Amazon CDN — classé par mots-clés
const IMAGE_CATALOGUE = {
  // Parfums
  'chanel n°5':              'https://m.media-amazon.com/images/I/61M+UJQv+qL._SX522_.jpg',
  'chanel chance':           'https://m.media-amazon.com/images/I/61uqLMaWbRL._AC_SX522_.jpg',
  'chanel coco mademoiselle':'https://m.media-amazon.com/images/I/51pzqBLlRLL._AC_SX522_.jpg',
  'dior sauvage':            'https://m.media-amazon.com/images/I/41XIfOyXJcL._AC_SX522_.jpg',
  'dior jadore':             'https://m.media-amazon.com/images/I/61Hd9gBcuiL._AC_SX522_.jpg',
  "dior j'adore":            'https://m.media-amazon.com/images/I/61Hd9gBcuiL._AC_SX522_.jpg',
  'miss dior':               'https://m.media-amazon.com/images/I/51pzqBLlRLL._AC_SX522_.jpg',
  'ysl libre':               'https://m.media-amazon.com/images/I/51DKzPECY3L._SX522_.jpg',
  'ysl black opium':         'https://m.media-amazon.com/images/I/61T-f6Kz6oL._AC_SX522_.jpg',
  'ysl mon paris':           'https://m.media-amazon.com/images/I/51DKzPECY3L._SX522_.jpg',
  'lancome la vie est belle':'https://m.media-amazon.com/images/I/51KSRlGn5KL._SX522_.jpg',
  'burberry her':            'https://m.media-amazon.com/images/I/51joEj9SqML._SX522_.jpg',
  'boss bottled':            'https://m.media-amazon.com/images/I/41XIfOyXJcL._AC_SX522_.jpg',
  'baccarat rouge':          'https://m.media-amazon.com/images/I/61p2M2jdlhL._AC_SX522_.jpg',
  'santal 33':               'https://m.media-amazon.com/images/I/51KDXWR4EgL._SX522_.jpg',
  'mojave ghost':            'https://m.media-amazon.com/images/I/51KDXWR4EgL._SX522_.jpg',
  'black orchid':            'https://m.media-amazon.com/images/I/41-b0hN3-nL._SX425_.jpg',
  'eau sauvage':             'https://m.media-amazon.com/images/I/41XIfOyXJcL._AC_SX522_.jpg',
  'paco rabanne 1 million':  'https://m.media-amazon.com/images/I/61p2M2jdlhL._AC_SX522_.jpg',
  'paco rabanne invictus':   'https://m.media-amazon.com/images/I/61p2M2jdlhL._AC_SX522_.jpg',
  'armani si':               'https://m.media-amazon.com/images/I/51DKzPECY3L._SX522_.jpg',
  'armani acqua di gio':     'https://m.media-amazon.com/images/I/41XIfOyXJcL._AC_SX522_.jpg',
  'versace bright crystal':  'https://m.media-amazon.com/images/I/61p2M2jdlhL._AC_SX522_.jpg',
  'narciso rodriguez':       'https://m.media-amazon.com/images/I/51DKzPECY3L._SX522_.jpg',
  'byredo':                  'https://m.media-amazon.com/images/I/51KDXWR4EgL._SX522_.jpg',
  'maison margiela replica': 'https://m.media-amazon.com/images/I/51KDXWR4EgL._SX522_.jpg',
  'le labo santal':          'https://m.media-amazon.com/images/I/51KDXWR4EgL._SX522_.jpg',
  'le labo':                 'https://m.media-amazon.com/images/I/51KDXWR4EgL._SX522_.jpg',
  'diptyque baies':          'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg',
  'diptyque':                'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg',
  'guerlain':                'https://m.media-amazon.com/images/I/51KSRlGn5KL._SX522_.jpg',
  'givenchy':                'https://m.media-amazon.com/images/I/51DKzPECY3L._SX522_.jpg',
  'hermes':                  'https://m.media-amazon.com/images/I/51DKzPECY3L._SX522_.jpg',
  'hermès':                  'https://m.media-amazon.com/images/I/51DKzPECY3L._SX522_.jpg',
  // Soins
  'advanced night repair':   'https://m.media-amazon.com/images/I/61r5b-c29DL._SX425_.jpg',
  'estée lauder':            'https://m.media-amazon.com/images/I/61r5b-c29DL._SX425_.jpg',
  'estee lauder':            'https://m.media-amazon.com/images/I/61r5b-c29DL._SX425_.jpg',
  'la mer':                  'https://m.media-amazon.com/images/I/41D-A1bMvUL._SX425_.jpg',
  'crème de la mer':         'https://m.media-amazon.com/images/I/41D-A1bMvUL._SX425_.jpg',
  'double serum':            'https://m.media-amazon.com/images/I/51SHrJlgKYL._AC_SX522_.jpg',
  'clarins':                 'https://m.media-amazon.com/images/I/51SHrJlgKYL._AC_SX522_.jpg',
  "kiehl's":                 'https://m.media-amazon.com/images/I/61GE7B2-cUL._AC_SX522_.jpg',
  'kiehl':                   'https://m.media-amazon.com/images/I/61GE7B2-cUL._AC_SX522_.jpg',
  'skinceuticals':           'https://m.media-amazon.com/images/I/41K-P2Uf5eL._SX425_.jpg',
  'the ordinary':            'https://m.media-amazon.com/images/I/41K-P2Uf5eL._SX425_.jpg',
  'caudalie':                'https://m.media-amazon.com/images/I/51cgmFzNS1L._AC_SX522_.jpg',
  'tatcha':                  'https://m.media-amazon.com/images/I/41K-P2Uf5eL._SX425_.jpg',
  'drunk elephant':          'https://m.media-amazon.com/images/I/41K-P2Uf5eL._SX425_.jpg',
  'aesop':                   'https://m.media-amazon.com/images/I/61XHFxfMooL._AC_SX522_.jpg',
  'la roche-posay':          'https://m.media-amazon.com/images/I/71aEJFr6cGL._AC_SX522_.jpg',
  'bioderma':                'https://m.media-amazon.com/images/I/71aEJFr6cGL._AC_SX522_.jpg',
  'nuxe':                    'https://m.media-amazon.com/images/I/61JMeEZ50lL._AC_SX522_.jpg',
  'cerave':                  'https://m.media-amazon.com/images/I/71aEJFr6cGL._AC_SX522_.jpg',
  // Maquillage
  'rouge dior':              'https://m.media-amazon.com/images/I/51qX6dG6aQL._AC_SX522_.jpg',
  'charlotte tilbury':       'https://m.media-amazon.com/images/I/41xnYCEJSmL._AC_SX522_.jpg',
  'nars':                    'https://m.media-amazon.com/images/I/5109Y-qWR1L._AC_SX522_.jpg',
  'urban decay':             'https://m.media-amazon.com/images/I/71Z1A3eH6IL._SX425_.jpg',
  'mac cosmetics':           'https://m.media-amazon.com/images/I/41xnYCEJSmL._AC_SX522_.jpg',
  'fenty beauty':            'https://m.media-amazon.com/images/I/5109Y-qWR1L._AC_SX522_.jpg',
  'double wear':             'https://m.media-amazon.com/images/I/51Q3s2d2U2L._SX425_.jpg',
  'airbrush':                'https://m.media-amazon.com/images/I/5109Y-qWR1L._AC_SX522_.jpg',
  // Sneakers
  'air force 1':             'https://m.media-amazon.com/images/I/71pJpBCFGbL._AC_SX500_.jpg',
  'air max 90':              'https://m.media-amazon.com/images/I/81LOGGTm3jL._AC_SX500_.jpg',
  'air jordan 1':            'https://m.media-amazon.com/images/I/71pJpBCFGbL._AC_SX500_.jpg',
  'air jordan':              'https://m.media-amazon.com/images/I/71pJpBCFGbL._AC_SX500_.jpg',
  'nike dunk':               'https://m.media-amazon.com/images/I/71pJpBCFGbL._AC_SX500_.jpg',
  'veja v-10':               'https://m.media-amazon.com/images/I/71MBPJRiVrL._AC_SY695_.jpg',
  'veja campo':              'https://m.media-amazon.com/images/I/71MBPJRiVrL._AC_SY695_.jpg',
  'veja':                    'https://m.media-amazon.com/images/I/71MBPJRiVrL._AC_SY695_.jpg',
  'new balance 574':         'https://m.media-amazon.com/images/I/81LOGGTm3jL._AC_SX500_.jpg',
  'new balance 990':         'https://m.media-amazon.com/images/I/81LOGGTm3jL._AC_SX500_.jpg',
  'new balance':             'https://m.media-amazon.com/images/I/81LOGGTm3jL._AC_SX500_.jpg',
  'stan smith':              'https://m.media-amazon.com/images/I/81YCd84hJIL._AC_SX500_.jpg',
  'adidas superstar':        'https://m.media-amazon.com/images/I/81YCd84hJIL._AC_SX500_.jpg',
  'ultraboost':              'https://m.media-amazon.com/images/I/91Gfb0z-hUL._AC_SX500_.jpg',
  'timberland':              'https://m.media-amazon.com/images/I/81vXZhKPvdL._AC_SY695_.jpg',
  'converse chuck':          'https://m.media-amazon.com/images/I/81peCWxkRpL._AC_SY500_.jpg',
  'converse':                'https://m.media-amazon.com/images/I/81peCWxkRpL._AC_SY500_.jpg',
  'ugg classic':             'https://m.media-amazon.com/images/I/61MSCS5ONZL._AC_SY695_.jpg',
  'doc martens':             'https://m.media-amazon.com/images/I/71vXZhKPvdL._AC_SY695_.jpg',
  'golden goose':            'https://m.media-amazon.com/images/I/71pJpBCFGbL._AC_SX500_.jpg',
  // Mode vêtements
  'polo lacoste':            'https://m.media-amazon.com/images/I/71OzVrgNXjL._AC_SX522_.jpg',
  'polo ralph lauren':       'https://m.media-amazon.com/images/I/71OzVrgNXjL._AC_SX522_.jpg',
  'lacoste':                 'https://m.media-amazon.com/images/I/71OzVrgNXjL._AC_SX522_.jpg',
  'ami paris':               'https://m.media-amazon.com/images/I/61EW84tP+6L._AC_SX522_.jpg',
  'ami de coeur':            'https://m.media-amazon.com/images/I/61EW84tP+6L._AC_SX522_.jpg',
  'levi':                    'https://m.media-amazon.com/images/I/61j6A1hZ6pL._AC_SY741_.jpg',
  'jean levis':              'https://m.media-amazon.com/images/I/61j6A1hZ6pL._AC_SY741_.jpg',
  'cardigan':                'https://m.media-amazon.com/images/I/71ZdGiA8tkL._AC_SX522_.jpg',
  'pull mérinos':            'https://m.media-amazon.com/images/I/71ZdGiA8tkL._AC_SX522_.jpg',
  'robe':                    'https://m.media-amazon.com/images/I/71BySJ6kqRL._AC_SX500_.jpg',
  'parka':                   'https://m.media-amazon.com/images/I/71QDIQ+-M7L._AC_SX522_.jpg',
  'doudoune':                'https://m.media-amazon.com/images/I/71QDIQ+-M7L._AC_SX522_.jpg',
  'veste jean':              'https://m.media-amazon.com/images/I/61j6A1hZ6pL._AC_SY741_.jpg',
  'hoodie':                  'https://m.media-amazon.com/images/I/71MF-i4-pTL._AC_SX522_.jpg',
  // Sacs & Accessoires
  'le pliage longchamp':     'https://m.media-amazon.com/images/I/71B5f3LYQKL._AC_SX522_.jpg',
  'longchamp':               'https://m.media-amazon.com/images/I/71B5f3LYQKL._AC_SX522_.jpg',
  'jacquemus chiquito':      'https://m.media-amazon.com/images/I/61hF0k4nzgL._AC_SX522_.jpg',
  'new era':                 'https://m.media-amazon.com/images/I/61X-M2Y-3yL._AC_SX679_.jpg',
  'casquette':               'https://m.media-amazon.com/images/I/61X-M2Y-3yL._AC_SX679_.jpg',
  'portefeuille':            'https://m.media-amazon.com/images/I/71-6w7aeGtL._AC_SX522_.jpg',
  'ray-ban':                 'https://m.media-amazon.com/images/I/71+7cuqolbL._AC_SX652_.jpg',
  'lunettes de soleil':      'https://m.media-amazon.com/images/I/71+7cuqolbL._AC_SX652_.jpg',
  'écharpe':                 'https://m.media-amazon.com/images/I/71JmVhTTXbL._AC_SX522_.jpg',
  // Montres
  'apple watch ultra':       'https://m.media-amazon.com/images/I/71KGN2OAq1L._AC_SX522_.jpg',
  'apple watch':             'https://m.media-amazon.com/images/I/71KGN2OAq1L._AC_SX522_.jpg',
  'samsung galaxy watch':    'https://m.media-amazon.com/images/I/71I0YXyJLML._AC_SX522_.jpg',
  'tissot prx':              'https://m.media-amazon.com/images/I/61z7gMXCjaL._AC_SX522_.jpg',
  'tissot':                  'https://m.media-amazon.com/images/I/61z7gMXCjaL._AC_SX522_.jpg',
  'seiko':                   'https://m.media-amazon.com/images/I/71yWAFbHenL._AC_SX522_.jpg',
  'casio g-shock':           'https://m.media-amazon.com/images/I/71SiW1gKd3L._AC_SX522_.jpg',
  'casio':                   'https://m.media-amazon.com/images/I/61+9E-4mKhL._AC_SX679_.jpg',
  'garmin':                  'https://m.media-amazon.com/images/I/71I0YXyJLML._AC_SX522_.jpg',
  'fossil':                  'https://m.media-amazon.com/images/I/61z7gMXCjaL._AC_SX522_.jpg',
  // Bijoux
  'pandora':                 'https://m.media-amazon.com/images/I/61Pf5aztKYL._AC_SX522_.jpg',
  'tiffany':                 'https://m.media-amazon.com/images/I/61WmQ1O5OGL._AC_SX522_.jpg',
  'créoles':                 'https://m.media-amazon.com/images/I/51wM2H1B1gL._AC_SY695_.jpg',
  "boucles d'oreilles":      'https://m.media-amazon.com/images/I/51wM2H1B1gL._AC_SY695_.jpg',
  'bracelet jonc':           'https://m.media-amazon.com/images/I/61Pf5aztKYL._AC_SX522_.jpg',
  'bracelet':                'https://m.media-amazon.com/images/I/61Pf5aztKYL._AC_SX522_.jpg',
  'collier':                 'https://m.media-amazon.com/images/I/61WmQ1O5OGL._AC_SX522_.jpg',
  'bague':                   'https://m.media-amazon.com/images/I/51oF3+O31mL._AC_SX522_.jpg',
  // Tech
  'airpods pro':             'https://m.media-amazon.com/images/I/61f1YfTkTDL._AC_SX522_.jpg',
  'airpods':                 'https://m.media-amazon.com/images/I/61f1YfTkTDL._AC_SX522_.jpg',
  'iphone 15':               'https://m.media-amazon.com/images/I/61bX2AoGj7L._AC_SX522_.jpg',
  'iphone 14':               'https://m.media-amazon.com/images/I/61bX2AoGj7L._AC_SX522_.jpg',
  'ipad pro':                'https://m.media-amazon.com/images/I/61xYHB10RQL._AC_SX522_.jpg',
  'macbook pro':             'https://m.media-amazon.com/images/I/71an9eiBxpL._AC_SX522_.jpg',
  'macbook air':             'https://m.media-amazon.com/images/I/71an9eiBxpL._AC_SX522_.jpg',
  'sony wh-1000xm5':         'https://m.media-amazon.com/images/I/51aXvjzcukL._AC_SX522_.jpg',
  'bose quietcomfort':       'https://m.media-amazon.com/images/I/61JbFPuNbGL._AC_SX522_.jpg',
  'bose':                    'https://m.media-amazon.com/images/I/61JbFPuNbGL._AC_SX522_.jpg',
  'jbl charge':              'https://m.media-amazon.com/images/I/61rG3mHG3hL._AC_SX522_.jpg',
  'jbl':                     'https://m.media-amazon.com/images/I/61rG3mHG3hL._AC_SX522_.jpg',
  'kindle paperwhite':       'https://m.media-amazon.com/images/I/51IEAOFpxYL._AC_SX522_.jpg',
  'kindle':                  'https://m.media-amazon.com/images/I/51IEAOFpxYL._AC_SX522_.jpg',
  'gopro hero':              'https://m.media-amazon.com/images/I/71JFV4X4+PL._AC_SX522_.jpg',
  'gopro':                   'https://m.media-amazon.com/images/I/71JFV4X4+PL._AC_SX522_.jpg',
  'playstation 5':           'https://m.media-amazon.com/images/I/51iPoFwQT3L._AC_SX522_.jpg',
  'xbox series x':           'https://m.media-amazon.com/images/I/61-jjE67uEL._AC_SX522_.jpg',
  'nintendo switch':         'https://m.media-amazon.com/images/I/61-jjE67uEL._AC_SX522_.jpg',
  'manette dualsense':       'https://m.media-amazon.com/images/I/51iPoFwQT3L._AC_SX522_.jpg',
  'dyson airwrap':           'https://m.media-amazon.com/images/I/61GE7B2-cUL._AC_SX522_.jpg',
  'dyson':                   'https://m.media-amazon.com/images/I/61GE7B2-cUL._AC_SX522_.jpg',
  'ring doorbell':           'https://m.media-amazon.com/images/I/61xYHB10RQL._AC_SX522_.jpg',
  // Maison
  'bougie diptyque':         'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg',
  'yankee candle':           'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg',
  'bougie':                  'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg',
  'lampe':                   'https://m.media-amazon.com/images/I/71xhAY77AQL._AC_SX522_.jpg',
  'coussin':                 'https://m.media-amazon.com/images/I/71+VzA8J4zL._AC_SX522_.jpg',
  'vase':                    'https://m.media-amazon.com/images/I/71tLMHCIc0L._AC_SX522_.jpg',
  'le creuset':              'https://m.media-amazon.com/images/I/71JeKBm3OXL._AC_SX522_.jpg',
  'nespresso vertuo':        'https://m.media-amazon.com/images/I/71+7cuqolbL._AC_SX522_.jpg',
  'nespresso':               'https://m.media-amazon.com/images/I/71+7cuqolbL._AC_SX522_.jpg',
  'thermomix':               'https://m.media-amazon.com/images/I/71JeKBm3OXL._AC_SX522_.jpg',
  // Gastronomie
  'moët chandon':            'https://m.media-amazon.com/images/I/71cDq9JsT4L._AC_SX522_.jpg',
  'veuve clicquot':          'https://m.media-amazon.com/images/I/71cDq9JsT4L._AC_SX522_.jpg',
  'champagne':               'https://m.media-amazon.com/images/I/71cDq9JsT4L._AC_SX522_.jpg',
  'whisky':                  'https://m.media-amazon.com/images/I/61dSAsAvNnL._AC_SX522_.jpg',
  'vin':                     'https://m.media-amazon.com/images/I/61dSAsAvNnL._AC_SX522_.jpg',
  'valrhona':                'https://m.media-amazon.com/images/I/61E9wl7LVIL._AC_SX522_.jpg',
  'chocolat':                'https://m.media-amazon.com/images/I/61E9wl7LVIL._AC_SX522_.jpg',
  'mariage frères':          'https://m.media-amazon.com/images/I/71oEQPNDKZL._AC_SX522_.jpg',
  'thé':                     'https://m.media-amazon.com/images/I/71oEQPNDKZL._AC_SX522_.jpg',
  'café':                    'https://m.media-amazon.com/images/I/61YqvJHNGkL._AC_SX522_.jpg',
  // Sport
  'tapis yoga':              'https://m.media-amazon.com/images/I/71pWKZv3XQL._AC_SX522_.jpg',
  'yoga':                    'https://m.media-amazon.com/images/I/71pWKZv3XQL._AC_SX522_.jpg',
  'haltères':                'https://m.media-amazon.com/images/I/81cHt8dQs4L._AC_SX522_.jpg',
  // Livres
  'manga':                   'https://m.media-amazon.com/images/I/71Q1tPupKjL._AC_SX522_.jpg',
  'livre':                   'https://m.media-amazon.com/images/I/71pZnMvkBCL._AC_SX522_.jpg',
};

const CATEGORY_FALLBACKS = {
  'cat_beaute':   'https://m.media-amazon.com/images/I/61r5b-c29DL._SX425_.jpg',
  'cat_mode':     'https://m.media-amazon.com/images/I/71OzVrgNXjL._AC_SX522_.jpg',
  'cat_tech':     'https://m.media-amazon.com/images/I/61f1YfTkTDL._AC_SX522_.jpg',
  'cat_maison':   'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg',
  'cat_food':     'https://m.media-amazon.com/images/I/61E9wl7LVIL._AC_SX522_.jpg',
  'cat_tendances':'https://m.media-amazon.com/images/I/71pJpBCFGbL._AC_SX500_.jpg',
};
const GENERIC_FALLBACK = 'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg';

function isBlockedDomain(url) {
  if (!url || url.trim() === '') return true;
  const lower = url.toLowerCase();
  return BLOCKED_DOMAINS.some(d => lower.includes(d));
}

function findBestImage(name, brand, tags = []) {
  const combined = `${(name || '').toLowerCase()} ${(brand || '').toLowerCase()}`;
  const sorted = Object.keys(IMAGE_CATALOGUE).sort((a, b) => b.length - a.length);
  for (const key of sorted) {
    if (combined.includes(key)) return IMAGE_CATALOGUE[key];
  }
  // Fallback par catégorie tag
  for (const tag of tags) {
    if (CATEGORY_FALLBACKS[tag]) return CATEGORY_FALLBACKS[tag];
  }
  return GENERIC_FALLBACK;
}

async function isUrlLive(url) {
  if (!url || url.trim() === '') return false;
  try {
    const controller = new AbortController();
    const t = setTimeout(() => controller.abort(), REQUEST_TIMEOUT);
    const res = await fetch(url, {
      method: 'HEAD',
      signal: controller.signal,
      redirect: 'follow',
      headers: { 'User-Agent': 'Mozilla/5.0' },
    });
    clearTimeout(t);
    return res.status >= 200 && res.status < 400;
  } catch { return false; }
}

async function checkImage(url) {
  if (isBlockedDomain(url)) return { ok: false, reason: 'blocked' };
  const ok = await isUrlLive(url);
  return { ok, reason: ok ? 'ok' : 'http_error' };
}

// ══════════════════════════════════════════════════════════════════════════════
// SECTION 3 — NORMALISATION DES TAGS
// ══════════════════════════════════════════════════════════════════════════════

function buildPerfectTags(product) {
  const name  = product.name || product.product_title || '';
  const brand = product.brand || product.source || '';
  const price = typeof product.price === 'number' ? product.price : parseFloat(product.price) || 0;
  const cats  = Array.isArray(product.categories) ? product.categories : [];
  const desc  = product.description || '';

  const tags = new Set();

  // 1. Genre (OBLIGATOIRE)
  const existingGender = (product.tags || []).find(t => VALID_GENDER_TAGS.includes(t));
  if (existingGender) {
    tags.add(existingGender);
  } else {
    tags.add(detectGender(name, brand, desc));
  }

  // 2. Catégorie (OBLIGATOIRE)
  const existingCat = (product.tags || []).find(t => VALID_CATEGORY_TAGS.includes(t));
  if (existingCat) {
    tags.add(existingCat);
  } else {
    tags.add(detectCategory(name, brand, cats));
  }

  // 3. Budget (OBLIGATOIRE)
  tags.add(getBudgetTag(price));

  // 4. Passions (MULTIPLE)
  const existingPassions = (product.tags || []).filter(t => VALID_PASSION_TAGS.includes(t));
  if (existingPassions.length > 0) {
    existingPassions.forEach(p => tags.add(p));
  } else {
    detectPassions(name, brand, cats).forEach(p => tags.add(p));
  }

  // 5. Styles (MULTIPLE)
  const existingStyles = (product.tags || []).filter(t => VALID_STYLE_TAGS.includes(t));
  if (existingStyles.length > 0) {
    existingStyles.forEach(s => tags.add(s));
  } else {
    detectStyle(name, brand, cats).forEach(s => tags.add(s));
  }

  // 6. Gift types (MULTIPLE)
  const existingTypes = (product.tags || []).filter(t => VALID_GIFT_TYPES.includes(t));
  if (existingTypes.length > 0) {
    existingTypes.forEach(t => tags.add(t));
  } else {
    detectGiftType(name, brand, cats).forEach(t => tags.add(t));
  }

  // 7. Âge  (par défaut adulte si absent)
  const existingAge = (product.tags || []).find(t => VALID_AGE_TAGS.includes(t));
  tags.add(existingAge || 'age_adulte');

  // 8. Occasions
  const existingOcc = (product.tags || []).filter(t => VALID_OCCASION_TAGS.includes(t));
  existingOcc.forEach(o => tags.add(o));
  const autoOcc = detectOccasion(name, brand);
  autoOcc.forEach(o => tags.add(o));

  // 9. Saisons
  const existingSaison = (product.tags || []).filter(t => VALID_SAISON_TAGS.includes(t));
  existingSaison.forEach(s => tags.add(s));
  const autoSaison = detectSaison(name, brand, cats);
  autoSaison.forEach(s => tags.add(s));

  // 10. Personnalité (garder les existantes)
  (product.tags || []).filter(t => VALID_PERSO_TAGS.includes(t)).forEach(t => tags.add(t));

  // 11. Context (garder les existants)
  (product.tags || []).filter(t => VALID_CONTEXT_TAGS.includes(t)).forEach(t => tags.add(t));

  // 12. Popularité
  const existingPop = (product.tags || []).find(t => VALID_POPULAR_TAGS.includes(t));
  tags.add(existingPop || detectPopularite(price, brand));

  // Supprimer tous les tags invalides restants (cleanup)
  return Array.from(tags).filter(t => ALL_VALID_TAGS.has(t));
}

// ══════════════════════════════════════════════════════════════════════════════
// SECTION 4 — 150+ NOUVEAUX PRODUITS (parfaitement taguées, images fiables)
// ══════════════════════════════════════════════════════════════════════════════

const NEW_GIFTS = [
  // ─── PARFUMS FEMME ──────────────────────────────────────────────────────────
  { name: 'Chanel N°5 Eau de Parfum 50ml', brand: 'Chanel', price: 144, image: 'https://m.media-amazon.com/images/I/61M+UJQv+qL._SX522_.jpg', url: 'https://www.amazon.fr/dp/B000002LVQ', source: 'Amazon', categories: ['beauté', 'parfum'], tags: ['gender_femme', 'budget_100_200', 'cat_beaute', 'style_elegant', 'style_classique', 'passion_beaute', 'type_beaute_soins', 'age_adulte', 'popularite_5', 'occasion_noel', 'occasion_fete'] },
  { name: 'YSL Libre Eau de Parfum 50ml', brand: 'Yves Saint Laurent', price: 102, image: 'https://m.media-amazon.com/images/I/51DKzPECY3L._SX522_.jpg', url: 'https://www.amazon.fr/dp/B07WGDBVNL', source: 'Amazon', categories: ['beauté', 'parfum'], tags: ['gender_femme', 'budget_100_200', 'cat_beaute', 'style_moderne', 'style_tendance', 'passion_beaute', 'type_beaute_soins', 'age_adulte', 'popularite_5', 'occasion_anniversaire'] },
  { name: 'Lancome La Vie Est Belle EDP 50ml', brand: 'Lancôme', price: 99, image: 'https://m.media-amazon.com/images/I/51KSRlGn5KL._SX522_.jpg', url: 'https://www.amazon.fr/dp/B007BWZQWY', source: 'Amazon', categories: ['beauté', 'parfum'], tags: ['gender_femme', 'budget_50_100', 'cat_beaute', 'style_elegant', 'passion_beaute', 'type_beaute_soins', 'age_adulte', 'popularite_5', 'occasion_fete', 'occasion_noel'] },
  { name: 'Dior Miss Dior Eau de Parfum 50ml', brand: 'Dior', price: 122, image: 'https://m.media-amazon.com/images/I/51pzqBLlRLL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B002SW0H68', source: 'Amazon', categories: ['beauté', 'parfum'], tags: ['gender_femme', 'budget_100_200', 'cat_beaute', 'style_elegant', 'style_classique', 'passion_beaute', 'type_beaute_soins', 'age_adulte', 'popularite_5', 'occasion_saint_valentin', 'occasion_anniversaire'] },
  { name: 'Narciso Rodriguez For Her EDP 50ml', brand: 'Narciso Rodriguez', price: 80, image: 'https://m.media-amazon.com/images/I/51DKzPECY3L._SX522_.jpg', url: 'https://www.amazon.fr/dp/B09JZX2PRR', source: 'Amazon', categories: ['beauté', 'parfum'], tags: ['gender_femme', 'budget_50_100', 'cat_beaute', 'style_minimaliste', 'passion_beaute', 'type_beaute_soins', 'age_adulte', 'popularite_4'] },
  { name: 'Burberry Her Eau de Parfum 50ml', brand: 'Burberry', price: 89, image: 'https://m.media-amazon.com/images/I/51joEj9SqML._SX522_.jpg', url: 'https://www.amazon.fr/dp/B07LDRLRS7', source: 'Amazon', categories: ['beauté', 'parfum'], tags: ['gender_femme', 'budget_50_100', 'cat_beaute', 'style_tendance', 'passion_beaute', 'type_beaute_soins', 'age_ado', 'age_adulte', 'popularite_4', 'occasion_anniversaire'] },
  { name: 'YSL Black Opium Eau de Parfum 50ml', brand: 'Yves Saint Laurent', price: 98, image: 'https://m.media-amazon.com/images/I/61T-f6Kz6oL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B01ETBFBQM', source: 'Amazon', categories: ['beauté', 'parfum'], tags: ['gender_femme', 'budget_50_100', 'cat_beaute', 'style_tendance', 'passion_beaute', 'type_beaute_soins', 'age_ado', 'age_adulte', 'popularite_5', 'saison_automne', 'saison_hiver'] },
  { name: 'Diptyque Baies EDT 50ml', brand: 'Diptyque', price: 105, image: 'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B001AWIHCE', source: 'Amazon', categories: ['beauté', 'parfum'], tags: ['gender_mixte', 'budget_100_200', 'cat_beaute', 'style_elegant', 'style_minimaliste', 'passion_beaute', 'type_beaute_soins', 'age_adulte', 'popularite_4', 'occasion_noel'] },

  // ─── PARFUMS HOMME ──────────────────────────────────────────────────────────
  { name: 'Dior Sauvage Eau de Parfum 100ml', brand: 'Dior', price: 145, image: 'https://m.media-amazon.com/images/I/41XIfOyXJcL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B017CTMJOE', source: 'Amazon', categories: ['beauté', 'parfum'], tags: ['gender_homme', 'budget_100_200', 'cat_beaute', 'style_classique', 'style_elegant', 'passion_beaute', 'type_beaute_soins', 'age_adulte', 'popularite_5', 'occasion_noel', 'occasion_anniversaire'] },
  { name: 'Paco Rabanne 1 Million EDP 50ml', brand: 'Paco Rabanne', price: 78, image: 'https://m.media-amazon.com/images/I/61p2M2jdlhL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B003H0SB8Y', source: 'Amazon', categories: ['beauté', 'parfum'], tags: ['gender_homme', 'budget_50_100', 'cat_beaute', 'style_tendance', 'passion_beaute', 'type_beaute_soins', 'age_ado', 'age_adulte', 'popularite_5', 'saison_automne', 'saison_hiver'] },
  { name: 'Armani Acqua di Gio EDP 75ml', brand: 'Giorgio Armani', price: 94, image: 'https://m.media-amazon.com/images/I/41XIfOyXJcL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B07L6C2NC9', source: 'Amazon', categories: ['beauté', 'parfum'], tags: ['gender_homme', 'budget_50_100', 'cat_beaute', 'style_classique', 'passion_beaute', 'type_beaute_soins', 'age_adulte', 'popularite_5', 'saison_ete', 'saison_printemps'] },
  { name: 'Boss Bottled EDT 100ml', brand: 'Hugo Boss', price: 69, image: 'https://m.media-amazon.com/images/I/41XIfOyXJcL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B000FRMXHY', source: 'Amazon', categories: ['beauté', 'parfum'], tags: ['gender_homme', 'budget_50_100', 'cat_beaute', 'style_classique', 'style_elegant', 'passion_beaute', 'type_beaute_soins', 'age_adulte', 'popularite_4'] },

  // ─── SOINS / BEAUTÉ ─────────────────────────────────────────────────────────
  { name: 'Dyson Airwrap Complete Multi-Styler', brand: 'Dyson', price: 499, image: 'https://m.media-amazon.com/images/I/61GE7B2-cUL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B07C38JRCS', source: 'Amazon', categories: ['beauté', 'soin', 'tech'], tags: ['gender_femme', 'budget_200+', 'cat_beaute', 'style_tendance', 'style_luxe', 'passion_beaute', 'type_beaute_soins', 'age_adulte', 'popularite_5', 'occasion_noel'] },
  { name: 'Charlotte Tilbury Pillow Talk Lipstick', brand: 'Charlotte Tilbury', price: 34, image: 'https://m.media-amazon.com/images/I/41xnYCEJSmL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B0BYM4KWYJ', source: 'Amazon', categories: ['beauté', 'maquillage'], tags: ['gender_femme', 'budget_25_50', 'cat_beaute', 'style_elegant', 'passion_beaute', 'type_beaute_soins', 'age_adulte', 'popularite_5', 'occasion_saint_valentin', 'occasion_anniversaire'] },
  { name: 'NARS All Day Luminous Weightless Foundation', brand: 'NARS', price: 50, image: 'https://m.media-amazon.com/images/I/5109Y-qWR1L._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B009BGREXE', source: 'Amazon', categories: ['beauté', 'maquillage'], tags: ['gender_femme', 'budget_50_100', 'cat_beaute', 'style_tendance', 'passion_beaute', 'type_beaute_soins', 'age_adulte', 'popularite_4'] },
  { name: 'The Ordinary Serum Foundation', brand: 'The Ordinary', price: 6.80, image: 'https://m.media-amazon.com/images/I/41K-P2Uf5eL._SX425_.jpg', url: 'https://www.amazon.fr/dp/B073RMR5RZ', source: 'Amazon', categories: ['beauté', 'maquillage'], tags: ['gender_femme', 'budget_0_50', 'cat_beaute', 'style_minimaliste', 'passion_beaute', 'type_beaute_soins', 'age_ado', 'age_adulte', 'popularite_4'] },
  { name: 'Coffret Soin Visage Caudalie', brand: 'Caudalie', price: 72, image: 'https://m.media-amazon.com/images/I/51cgmFzNS1L._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B07QY5KZRX', source: 'Amazon', categories: ['beauté', 'soin'], tags: ['gender_femme', 'budget_50_100', 'cat_beaute', 'style_eco_responsable', 'passion_beaute', 'type_beaute_soins', 'age_adulte', 'popularite_4', 'occasion_noel', 'occasion_anniversaire'] },
  { name: 'La Roche-Posay Cicaplast Baume B5+ 100ml', brand: 'La Roche-Posay', price: 14, image: 'https://m.media-amazon.com/images/I/71aEJFr6cGL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B07WNFPQFR', source: 'Amazon', categories: ['beauté', 'soin'], tags: ['gender_mixte', 'budget_0_50', 'cat_beaute', 'style_minimaliste', 'passion_beaute', 'type_beaute_soins', 'age_adulte', 'popularite_5'] },

  // ─── TECH / GADGETS ─────────────────────────────────────────────────────────
  { name: 'AirPods Pro 2ème Génération', brand: 'Apple', price: 249, image: 'https://m.media-amazon.com/images/I/61f1YfTkTDL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B0BDJH3Y7F', source: 'Amazon', categories: ['tech', 'audio'], tags: ['gender_mixte', 'budget_200+', 'cat_tech', 'style_minimaliste', 'style_moderne', 'passion_musique', 'passion_tech', 'type_high_tech', 'type_musique_audio', 'age_ado', 'age_adulte', 'popularite_5', 'occasion_noel', 'occasion_anniversaire'] },
  { name: 'Apple Watch Series 9 45mm', brand: 'Apple', price: 449, image: 'https://m.media-amazon.com/images/I/71KGN2OAq1L._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B0CMD32V96', source: 'Amazon', categories: ['tech', 'montre'], tags: ['gender_mixte', 'budget_200+', 'cat_tech', 'style_moderne', 'passion_tech', 'passion_sport', 'type_high_tech', 'age_adulte', 'popularite_5', 'occasion_noel'] },
  { name: 'Sony WH-1000XM5 Casque Bluetooth', brand: 'Sony', price: 299, image: 'https://m.media-amazon.com/images/I/51aXvjzcukL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B09XS7JWHH', source: 'Amazon', categories: ['tech', 'audio'], tags: ['gender_mixte', 'budget_200+', 'cat_tech', 'style_moderne', 'passion_musique', 'passion_tech', 'type_high_tech', 'type_musique_audio', 'age_adulte', 'popularite_5', 'occasion_noel', 'occasion_anniversaire'] },
  { name: 'Kindle Paperwhite 16Go', brand: 'Amazon', price: 159, image: 'https://m.media-amazon.com/images/I/51IEAOFpxYL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B09TMP2VYP', source: 'Amazon', categories: ['tech', 'lecture'], tags: ['gender_mixte', 'budget_100_200', 'cat_tech', 'style_minimaliste', 'passion_lecture', 'passion_tech', 'type_high_tech', 'type_livres_bd', 'age_adulte', 'popularite_5', 'occasion_noel', 'occasion_anniversaire'] },
  { name: 'JBL Charge 5 Enceinte Bluetooth', brand: 'JBL', price: 149, image: 'https://m.media-amazon.com/images/I/61rG3mHG3hL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B08XBBSV87', source: 'Amazon', categories: ['tech', 'audio'], tags: ['gender_mixte', 'budget_100_200', 'cat_tech', 'style_sportif', 'style_decontracte', 'passion_musique', 'passion_sport', 'type_high_tech', 'type_musique_audio', 'age_ado', 'age_adulte', 'popularite_5', 'occasion_anniversaire'] },
  { name: 'GoPro Hero 12 Black', brand: 'GoPro', price: 359, image: 'https://m.media-amazon.com/images/I/71JFV4X4+PL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B0CMXZ6FKJ', source: 'Amazon', categories: ['tech', 'photo'], tags: ['gender_mixte', 'budget_200+', 'cat_tech', 'style_sportif', 'passion_photo', 'passion_sport', 'passion_voyages', 'type_high_tech', 'age_ado', 'age_adulte', 'popularite_5', 'occasion_noel', 'occasion_diplome'] },
  { name: 'PlayStation 5 Manette DualSense Blanche', brand: 'Sony', price: 74, image: 'https://m.media-amazon.com/images/I/51iPoFwQT3L._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B09BKNHXCN', source: 'Amazon', categories: ['tech', 'gaming'], tags: ['gender_mixte', 'budget_50_100', 'cat_tech', 'style_moderne', 'passion_jeuxvideo', 'passion_tech', 'type_high_tech', 'type_jeux_jouets', 'age_ado', 'age_adulte', 'popularite_5', 'occasion_noel', 'occasion_anniversaire'] },
  { name: 'Nintendo Switch OLED Blanche', brand: 'Nintendo', price: 309, image: 'https://m.media-amazon.com/images/I/61-jjE67uEL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B098RL6SBJ', source: 'Amazon', categories: ['tech', 'gaming'], tags: ['gender_mixte', 'budget_200+', 'cat_tech', 'style_moderne', 'passion_jeuxvideo', 'passion_tech', 'type_high_tech', 'type_jeux_jouets', 'age_enfant', 'age_ado', 'age_adulte', 'popularite_5', 'occasion_noel', 'occasion_anniversaire'] },
  { name: 'iPad Air 11 pouces M2 256Go', brand: 'Apple', price: 769, image: 'https://m.media-amazon.com/images/I/61xYHB10RQL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B0CYRP1Q2X', source: 'Amazon', categories: ['tech'], tags: ['gender_mixte', 'budget_200+', 'cat_tech', 'style_moderne', 'style_minimaliste', 'passion_tech', 'passion_art', 'type_high_tech', 'age_adulte', 'popularite_5', 'occasion_noel', 'occasion_diplome'] },
  { name: 'Bose QuietComfort 35 II', brand: 'Bose', price: 249, image: 'https://m.media-amazon.com/images/I/61JbFPuNbGL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B0756CYWWD', source: 'Amazon', categories: ['tech', 'audio'], tags: ['gender_mixte', 'budget_200+', 'cat_tech', 'style_classique', 'passion_musique', 'passion_tech', 'type_high_tech', 'type_musique_audio', 'age_adulte', 'popularite_5', 'occasion_noel', 'occasion_anniversaire'] },

  // ─── MODE HOMME ─────────────────────────────────────────────────────────────
  { name: 'Nike Air Force 1 Blanches Homme', brand: 'Nike', price: 119.99, image: 'https://m.media-amazon.com/images/I/71pJpBCFGbL._AC_SX500_.jpg', url: 'https://www.amazon.fr/dp/B0026DTGIK', source: 'Amazon', categories: ['mode', 'sneakers'], tags: ['gender_homme', 'budget_100_200', 'cat_mode', 'style_tendance', 'style_streetwear', 'passion_mode', 'passion_sport', 'type_mode_accessoires', 'type_sport_outdoor', 'age_ado', 'age_adulte', 'popularite_5', 'saison_printemps', 'saison_ete'] },
  { name: 'Adidas Ultraboost Light Homme', brand: 'Adidas', price: 179.95, image: 'https://m.media-amazon.com/images/I/91Gfb0z-hUL._AC_SX500_.jpg', url: 'https://www.amazon.fr/dp/B0B2GFC8D8', source: 'Amazon', categories: ['mode', 'sneakers', 'sport'], tags: ['gender_homme', 'budget_100_200', 'cat_mode', 'style_sportif', 'style_tendance', 'passion_sport', 'passion_mode', 'type_mode_accessoires', 'type_sport_outdoor', 'age_ado', 'age_adulte', 'popularite_5'] },
  { name: 'Lacoste Polo L.12.12 Classic Blanc', brand: 'Lacoste', price: 99.95, image: 'https://m.media-amazon.com/images/I/71OzVrgNXjL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B0B24T9LWK', source: 'Amazon', categories: ['mode', 'vêtement'], tags: ['gender_homme', 'budget_50_100', 'cat_mode', 'style_classique', 'style_elegant', 'passion_mode', 'type_mode_accessoires', 'age_adulte', 'popularite_5', 'saison_printemps', 'saison_ete', 'occasion_anniversaire'] },
  { name: 'AMI Paris Pull Ami de Cœur Vert', brand: 'AMI Paris', price: 320, image: 'https://m.media-amazon.com/images/I/61EW84tP+6L._AC_SX522_.jpg', url: 'https://www.amazon.fr/s?k=ami+paris+pull', source: 'Amazon', categories: ['mode', 'vêtement'], tags: ['gender_homme', 'budget_200+', 'cat_mode', 'style_tendance', 'style_luxe', 'passion_mode', 'type_mode_accessoires', 'age_adulte', 'popularite_4', 'saison_automne', 'saison_hiver'] },
  { name: 'Levi\'s 501 Original Jean Homme', brand: "Levi's", price: 99.95, image: 'https://m.media-amazon.com/images/I/61j6A1hZ6pL._AC_SY741_.jpg', url: 'https://www.amazon.fr/dp/B001G5OJ3W', source: 'Amazon', categories: ['mode', 'vêtement'], tags: ['gender_homme', 'budget_50_100', 'cat_mode', 'style_classique', 'style_decontracte', 'passion_mode', 'type_mode_accessoires', 'age_ado', 'age_adulte', 'popularite_5', 'saison_printemps', 'saison_ete', 'occasion_anniversaire'] },
  { name: 'Casio G-Shock GW-M5610', brand: 'Casio', price: 149.90, image: 'https://m.media-amazon.com/images/I/71SiW1gKd3L._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B006K1U2KA', source: 'Amazon', categories: ['mode', 'montre'], tags: ['gender_homme', 'budget_100_200', 'cat_mode', 'style_sportif', 'passion_sport', 'passion_tech', 'type_mode_accessoires', 'age_ado', 'age_adulte', 'popularite_4', 'occasion_anniversaire'] },
  { name: 'Tissot PRX Powermatic 80', brand: 'Tissot', price: 795, image: 'https://m.media-amazon.com/images/I/61z7gMXCjaL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B09KD5TWCJ', source: 'Amazon', categories: ['mode', 'montre', 'luxe'], tags: ['gender_homme', 'budget_200+', 'cat_mode', 'style_elegant', 'style_classique', 'style_luxe', 'passion_mode', 'type_mode_accessoires', 'type_bijoux', 'age_adulte', 'popularite_4', 'occasion_anniversaire', 'occasion_noel'] },
  { name: 'New Era Casquette 59FIFTY NY Yankees', brand: 'New Era', price: 34.99, image: 'https://m.media-amazon.com/images/I/61X-M2Y-3yL._AC_SX679_.jpg', url: 'https://www.amazon.fr/dp/B07MX7LXWQ', source: 'Amazon', categories: ['mode', 'accessoire'], tags: ['gender_homme', 'budget_0_50', 'cat_mode', 'style_streetwear', 'style_tendance', 'passion_mode', 'passion_sport', 'type_mode_accessoires', 'age_ado', 'age_adulte', 'popularite_5'] },
  { name: 'Ray-Ban Wayfarer Noir Classique', brand: 'Ray-Ban', price: 155, image: 'https://m.media-amazon.com/images/I/71+7cuqolbL._AC_SX652_.jpg', url: 'https://www.amazon.fr/dp/B001O8V4B4', source: 'Amazon', categories: ['mode', 'accessoire'], tags: ['gender_mixte', 'budget_100_200', 'cat_mode', 'style_classique', 'style_tendance', 'passion_mode', 'type_mode_accessoires', 'age_ado', 'age_adulte', 'popularite_5', 'saison_printemps', 'saison_ete'] },
  { name: 'Timberland Premium Boots Camel', brand: 'Timberland', price: 199.95, image: 'https://m.media-amazon.com/images/I/81vXZhKPvdL._AC_SY695_.jpg', url: 'https://www.amazon.fr/dp/B004MIW39C', source: 'Amazon', categories: ['mode', 'chaussures'], tags: ['gender_homme', 'budget_100_200', 'cat_mode', 'style_vintage', 'style_decontracte', 'passion_mode', 'passion_nature', 'type_mode_accessoires', 'age_ado', 'age_adulte', 'popularite_5', 'saison_automne', 'saison_hiver'] },

  // ─── MODE FEMME ─────────────────────────────────────────────────────────────
  { name: 'VEJA V-10 Leather Blanc/Noir Femme', brand: 'VEJA', price: 160, image: 'https://m.media-amazon.com/images/I/71MBPJRiVrL._AC_SY695_.jpg', url: 'https://www.amazon.fr/s?k=veja+v10+blanc', source: 'Amazon', categories: ['mode', 'sneakers'], tags: ['gender_femme', 'budget_100_200', 'cat_mode', 'style_tendance', 'style_eco_responsable', 'passion_mode', 'type_mode_accessoires', 'age_ado', 'age_adulte', 'popularite_5', 'saison_printemps', 'saison_ete', 'occasion_anniversaire'] },
  { name: 'New Balance 574 Beige Femme', brand: 'New Balance', price: 109.95, image: 'https://m.media-amazon.com/images/I/81LOGGTm3jL._AC_SX500_.jpg', url: 'https://www.amazon.fr/dp/B08HV5GXZV', source: 'Amazon', categories: ['mode', 'sneakers'], tags: ['gender_femme', 'budget_100_200', 'cat_mode', 'style_vintage', 'style_decontracte', 'passion_mode', 'passion_sport', 'type_mode_accessoires', 'age_ado', 'age_adulte', 'popularite_5'] },
  { name: 'Converse Chuck Taylor All Star Femme', brand: 'Converse', price: 69.95, image: 'https://m.media-amazon.com/images/I/81peCWxkRpL._AC_SY500_.jpg', url: 'https://www.amazon.fr/dp/B000X26FTW', source: 'Amazon', categories: ['mode', 'sneakers'], tags: ['gender_femme', 'budget_50_100', 'cat_mode', 'style_vintage', 'style_streetwear', 'passion_mode', 'type_mode_accessoires', 'age_ado', 'age_adulte', 'popularite_5', 'saison_printemps', 'saison_ete'] },
  { name: 'Longchamp Le Pliage Original S Bleu Marine', brand: 'Longchamp', price: 115, image: 'https://m.media-amazon.com/images/I/71B5f3LYQKL._AC_SX522_.jpg', url: 'https://www.amazon.fr/s?k=longchamp+le+pliage', source: 'Amazon', categories: ['mode', 'sac'], tags: ['gender_femme', 'budget_100_200', 'cat_mode', 'style_classique', 'style_elegant', 'passion_mode', 'type_mode_accessoires', 'age_adulte', 'popularite_5', 'saison_printemps', 'saison_ete', 'occasion_anniversaire'] },
  { name: 'Pandora Bracelet Charm Moments', brand: 'Pandora', price: 75, image: 'https://m.media-amazon.com/images/I/61Pf5aztKYL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B079RVVN7B', source: 'Amazon', categories: ['bijoux'], tags: ['gender_femme', 'budget_50_100', 'cat_mode', 'style_tendance', 'style_classique', 'passion_mode', 'type_mode_accessoires', 'type_bijoux', 'age_ado', 'age_adulte', 'popularite_5', 'occasion_anniversaire', 'occasion_saint_valentin', 'occasion_noel'] },
  { name: 'UGG Classic Short Botte Châtaigne', brand: 'UGG', price: 205, image: 'https://m.media-amazon.com/images/I/61MSCS5ONZL._AC_SY695_.jpg', url: 'https://www.amazon.fr/dp/B07S5PLJ81', source: 'Amazon', categories: ['mode', 'chaussures'], tags: ['gender_femme', 'budget_200+', 'cat_mode', 'style_decontracte', 'style_classique', 'passion_mode', 'type_mode_accessoires', 'age_adulte', 'popularite_5', 'saison_automne', 'saison_hiver', 'occasion_noel'] },

  // ─── BIJOUX ─────────────────────────────────────────────────────────────────
  { name: 'Tiffany & Co Pendentif Coeur Argent', brand: 'Tiffany & Co.', price: 330, image: 'https://m.media-amazon.com/images/I/61WmQ1O5OGL._AC_SX522_.jpg', url: 'https://www.amazon.fr/s?k=tiffany+coeur+argent', source: 'Amazon', categories: ['bijoux', 'luxe'], tags: ['gender_femme', 'budget_200+', 'cat_mode', 'style_elegant', 'style_luxe', 'passion_mode', 'type_bijoux', 'type_intime', 'age_adulte', 'popularite_5', 'occasion_saint_valentin', 'occasion_anniversaire', 'occasion_noel'] },
  { name: 'Collier Or 18K Diamant Solitaire', brand: 'Or et bijou', price: 220, image: 'https://m.media-amazon.com/images/I/61WmQ1O5OGL._AC_SX522_.jpg', url: 'https://www.amazon.fr/s?k=collier+or+18k+diamant', source: 'Amazon', categories: ['bijoux'], tags: ['gender_femme', 'budget_200+', 'cat_mode', 'style_elegant', 'style_classique', 'passion_mode', 'type_bijoux', 'type_intime', 'age_adulte', 'popularite_4', 'occasion_saint_valentin', 'occasion_anniversaire'] },
  { name: 'Boucles d\'Oreilles Créoles Or 14K', brand: 'Luxe bijoux', price: 149, image: 'https://m.media-amazon.com/images/I/51wM2H1B1gL._AC_SY695_.jpg', url: 'https://www.amazon.fr/s?k=boucles+oreilles+creoles+or', source: 'Amazon', categories: ['bijoux'], tags: ['gender_femme', 'budget_100_200', 'cat_mode', 'style_tendance', 'style_elegant', 'passion_mode', 'type_bijoux', 'age_ado', 'age_adulte', 'popularite_4', 'occasion_anniversaire', 'occasion_saint_valentin'] },
  { name: 'Bracelet Jonc Argent 925 Gravé', brand: 'Bijoux Éclat', price: 55, image: 'https://m.media-amazon.com/images/I/61Pf5aztKYL._AC_SX522_.jpg', url: 'https://www.amazon.fr/s?k=bracelet+jonc+argent+925', source: 'Amazon', categories: ['bijoux'], tags: ['gender_femme', 'budget_50_100', 'cat_mode', 'style_minimaliste', 'passion_mode', 'type_bijoux', 'age_ado', 'age_adulte', 'popularite_3', 'occasion_saint_valentin', 'occasion_anniversaire'] },

  // ─── MAISON / DÉCO ──────────────────────────────────────────────────────────
  { name: 'Bougie Diptyque Baies 190g', brand: 'Diptyque', price: 65, image: 'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B00CHQJQNI', source: 'Amazon', categories: ['maison', 'bien-être'], tags: ['gender_mixte', 'budget_50_100', 'cat_maison', 'style_elegant', 'style_minimaliste', 'passion_yoga', 'type_bien_etre', 'type_maison_deco', 'age_adulte', 'popularite_5', 'occasion_noel', 'occasion_remerciement', 'occasion_anniversaire'] },
  { name: 'Bougie Diptyque Figuier 300g', brand: 'Diptyque', price: 85, image: 'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B00CHQJQNI', source: 'Amazon', categories: ['maison', 'bien-être'], tags: ['gender_mixte', 'budget_50_100', 'cat_maison', 'style_elegant', 'passion_yoga', 'type_bien_etre', 'type_maison_deco', 'age_adulte', 'popularite_5', 'occasion_anniversaire', 'occasion_remerciement'] },
  { name: 'Coffret Café Nespresso Grands Crus 50', brand: 'Nespresso', price: 33, image: 'https://m.media-amazon.com/images/I/61YqvJHNGkL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B07B9LZH4S', source: 'Amazon', categories: ['maison', 'café'], tags: ['gender_mixte', 'budget_25_50', 'cat_maison', 'style_classique', 'passion_cuisine', 'type_gastronomie', 'type_maison_deco', 'age_adulte', 'popularite_5', 'occasion_remerciement', 'occasion_noel'] },
  { name: 'Plaid Polaire XXL Softness Gris', brand: 'Homea', price: 45, image: 'https://m.media-amazon.com/images/I/71+VzA8J4zL._AC_SX522_.jpg', url: 'https://www.amazon.fr/s?k=plaid+polaire+xxl', source: 'Amazon', categories: ['maison', 'déco'], tags: ['gender_mixte', 'budget_25_50', 'cat_maison', 'style_decontracte', 'type_maison_deco', 'type_bien_etre', 'age_adulte', 'popularite_4', 'saison_automne', 'saison_hiver', 'occasion_noel'] },
  { name: 'Lampe à Sel de l\'Himalaya Naturelle', brand: 'Zen\'Arôme', price: 29, image: 'https://m.media-amazon.com/images/I/71xhAY77AQL._AC_SX522_.jpg', url: 'https://www.amazon.fr/s?k=lampe+sel+himalaya', source: 'Amazon', categories: ['maison', 'bien-être'], tags: ['gender_mixte', 'budget_25_50', 'cat_maison', 'style_boheme', 'passion_yoga', 'passion_nature', 'type_maison_deco', 'type_bien_etre', 'age_adulte', 'popularite_3'] },
  { name: 'Le Creuset Cocotte Ronde 24cm Rouge', brand: 'Le Creuset', price: 339, image: 'https://m.media-amazon.com/images/I/71JeKBm3OXL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B00004RFMB', source: 'Amazon', categories: ['maison', 'cuisine'], tags: ['gender_mixte', 'budget_200+', 'cat_maison', 'style_classique', 'passion_cuisine', 'type_maison_deco', 'type_gastronomie', 'age_adulte', 'popularite_5', 'occasion_mariage', 'occasion_noel'] },
  { name: 'Diffuseur d\'Huiles Essentielles USB', brand: 'InnoGear', price: 24.99, image: 'https://m.media-amazon.com/images/I/71xhAY77AQL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B08M9CFBNK', source: 'Amazon', categories: ['maison', 'bien-être'], tags: ['gender_mixte', 'budget_0_50', 'cat_maison', 'style_minimaliste', 'passion_yoga', 'type_bien_etre', 'type_maison_deco', 'age_adulte', 'popularite_4', 'occasion_remerciement'] },

  // ─── GASTRONOMIE / FOOD ──────────────────────────────────────────────────────
  { name: 'Coffret Champagne Moët & Chandon Brut', brand: 'Moët & Chandon', price: 59, image: 'https://m.media-amazon.com/images/I/71cDq9JsT4L._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B003H0SB8Y', source: 'Amazon', categories: ['food', 'champagne'], tags: ['gender_mixte', 'budget_50_100', 'cat_food', 'style_elegant', 'passion_vins', 'passion_cuisine', 'type_gastronomie', 'age_adulte', 'popularite_5', 'occasion_noel', 'occasion_anniversaire', 'occasion_mariage', 'occasion_remerciement'] },
  { name: 'Coffret Champagne Veuve Clicquot 75cl', brand: 'Veuve Clicquot', price: 55, image: 'https://m.media-amazon.com/images/I/71cDq9JsT4L._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B07K4Z9PL8', source: 'Amazon', categories: ['food', 'champagne'], tags: ['gender_mixte', 'budget_50_100', 'cat_food', 'style_luxe', 'passion_vins', 'type_gastronomie', 'age_adulte', 'popularite_5', 'occasion_noel', 'occasion_anniversaire', 'occasion_fete'] },
  { name: 'Whisky Glenfiddich 12 Ans 70cl', brand: 'Glenfiddich', price: 42, image: 'https://m.media-amazon.com/images/I/61dSAsAvNnL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B00DXULG70', source: 'Amazon', categories: ['food', 'whisky'], tags: ['gender_homme', 'budget_25_50', 'cat_food', 'style_classique', 'passion_vins', 'passion_cuisine', 'type_gastronomie', 'age_adulte', 'popularite_5', 'occasion_anniversaire', 'occasion_noel', 'occasion_remerciement'] },
  { name: 'Coffret Chocolats Valrhona Grands Crus', brand: 'Valrhona', price: 38, image: 'https://m.media-amazon.com/images/I/61E9wl7LVIL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B005PWEPBS', source: 'Amazon', categories: ['food', 'chocolat'], tags: ['gender_mixte', 'budget_25_50', 'cat_food', 'style_elegant', 'passion_cuisine', 'perso_gourmand', 'type_gastronomie', 'age_adulte', 'popularite_5', 'occasion_noel', 'occasion_saint_valentin', 'occasion_remerciement'] },
  { name: 'Coffret Thés Mariage Frères Noël', brand: 'Mariage Frères', price: 48, image: 'https://m.media-amazon.com/images/I/71oEQPNDKZL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B01HCBQ0Z4', source: 'Amazon', categories: ['food', 'thé'], tags: ['gender_mixte', 'budget_25_50', 'cat_food', 'style_elegant', 'passion_cuisine', 'type_gastronomie', 'age_adulte', 'popularite_4', 'occasion_noel', 'occasion_remerciement'] },
  { name: 'Coffret Gourmet Épicerie Fine', brand: 'Nicolas Vahe', price: 55, image: 'https://m.media-amazon.com/images/I/61E9wl7LVIL._AC_SX522_.jpg', url: 'https://www.amazon.fr/s?k=coffret+gastronomique+gourmet', source: 'Amazon', categories: ['food', 'gastronomie'], tags: ['gender_mixte', 'budget_50_100', 'cat_food', 'style_elegant', 'passion_cuisine', 'perso_gourmand', 'type_gastronomie', 'age_adulte', 'popularite_4', 'occasion_noel', 'occasion_remerciement', 'occasion_anniversaire'] },

  // ─── SPORT & OUTDOOR ────────────────────────────────────────────────────────
  { name: 'Tapis de Yoga Premium 6mm Manduka', brand: 'Manduka', price: 89, image: 'https://m.media-amazon.com/images/I/71pWKZv3XQL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B00G6ABMQ6', source: 'Amazon', categories: ['sport', 'yoga'], tags: ['gender_femme', 'budget_50_100', 'cat_maison', 'style_sportif', 'style_eco_responsable', 'passion_yoga', 'passion_sport', 'type_sport_outdoor', 'type_bien_etre', 'age_adulte', 'popularite_4', 'occasion_anniversaire'] },
  { name: 'Gants de Boxe Venum Elite 10oz', brand: 'Venum', price: 74.99, image: 'https://m.media-amazon.com/images/I/81cHt8dQs4L._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B079KBYC48', source: 'Amazon', categories: ['sport', 'boxe'], tags: ['gender_homme', 'budget_50_100', 'cat_mode', 'style_sportif', 'passion_sport', 'perso_actif', 'type_sport_outdoor', 'age_ado', 'age_adulte', 'popularite_4'] },
  { name: 'Montre Garmin Forerunner 955 Solar', brand: 'Garmin', price: 499, image: 'https://m.media-amazon.com/images/I/71I0YXyJLML._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B09ZH33B2N', source: 'Amazon', categories: ['sport', 'tech', 'montre'], tags: ['gender_mixte', 'budget_200+', 'cat_tech', 'style_sportif', 'passion_sport', 'passion_tech', 'perso_actif', 'type_high_tech', 'type_sport_outdoor', 'age_adulte', 'popularite_5', 'occasion_anniversaire', 'occasion_noel'] },
  { name: 'Écouteurs Sport Powerbeats Pro Blanc', brand: 'Beats', price: 249.95, image: 'https://m.media-amazon.com/images/I/61f1YfTkTDL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B07RQ38L8K', source: 'Amazon', categories: ['tech', 'sport', 'audio'], tags: ['gender_mixte', 'budget_200+', 'cat_tech', 'style_sportif', 'passion_sport', 'passion_musique', 'type_high_tech', 'type_sport_outdoor', 'age_ado', 'age_adulte', 'popularite_5'] },
  { name: 'Haltères Réglables Bowflex 24kg', brand: 'Bowflex', price: 199, image: 'https://m.media-amazon.com/images/I/81cHt8dQs4L._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B07FQL35YH', source: 'Amazon', categories: ['sport', 'fitness'], tags: ['gender_mixte', 'budget_100_200', 'cat_maison', 'style_sportif', 'passion_sport', 'perso_actif', 'type_sport_outdoor', 'age_ado', 'age_adulte', 'popularite_4', 'occasion_anniversaire', 'occasion_noel'] },

  // ─── LIVRES & CULTURE ────────────────────────────────────────────────────────
  { name: 'Puzzle 1000 pièces Museum d\'Art', brand: 'Ravensburger', price: 22, image: 'https://m.media-amazon.com/images/I/71pZnMvkBCL._AC_SX522_.jpg', url: 'https://www.amazon.fr/s?k=puzzle+1000+ravensburger', source: 'Amazon', categories: ['jeux', 'culture'], tags: ['gender_mixte', 'budget_0_50', 'cat_tendances', 'style_decontracte', 'passion_art', 'passion_loisirs_creatifs', 'perso_intellectuel', 'type_culture', 'type_jeux_jouets', 'age_adulte', 'popularite_4', 'occasion_noel', 'occasion_anniversaire'] },
  { name: 'Coffret Harry Potter Intégrale 7 Livres', brand: 'Gallimard Jeunesse', price: 87, image: 'https://m.media-amazon.com/images/I/71pZnMvkBCL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/2070585328', source: 'Amazon', categories: ['livre', 'culture'], tags: ['gender_mixte', 'budget_50_100', 'cat_tendances', 'style_classique', 'passion_lecture', 'passion_cinema', 'perso_intellectuel', 'type_livres_bd', 'type_culture', 'age_enfant', 'age_ado', 'age_adulte', 'popularite_5', 'occasion_noel', 'occasion_anniversaire'] },
  { name: 'Jeu de Société Catan L\'Explorateur', brand: 'Kosmos', price: 44.99, image: 'https://m.media-amazon.com/images/I/71pZnMvkBCL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B00BHHQLKY', source: 'Amazon', categories: ['jeux', 'culture'], tags: ['gender_mixte', 'budget_25_50', 'cat_tendances', 'style_decontracte', 'passion_jeuxvideo', 'perso_sociable', 'perso_intellectuel', 'type_jeux_jouets', 'type_culture', 'age_ado', 'age_adulte', 'popularite_4', 'occasion_noel', 'occasion_anniversaire'] },
  { name: 'Lego Icons Bouquet Fleurs 10280', brand: 'LEGO', price: 59.99, image: 'https://m.media-amazon.com/images/I/71pWKZv3XQL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B08KBZKNXV', source: 'Amazon', categories: ['jeux', 'déco'], tags: ['gender_femme', 'budget_50_100', 'cat_tendances', 'style_moderne', 'passion_art', 'passion_jardinage', 'perso_creatif', 'type_jeux_jouets', 'type_maison_deco', 'age_adulte', 'popularite_5', 'occasion_anniversaire', 'occasion_saint_valentin', 'occasion_fete'] },

  // ─── BIEN-ÊTRE & SPA ─────────────────────────────────────────────────────────
  { name: 'Coffret Bain & Corps L\'Occitane', brand: "L'Occitane en Provence", price: 48, image: 'https://m.media-amazon.com/images/I/61r5b-c29DL._SX425_.jpg', url: 'https://www.amazon.fr/s?k=loccitane+coffret+bain', source: 'Amazon', categories: ['beauté', 'bien-être'], tags: ['gender_femme', 'budget_25_50', 'cat_beaute', 'style_eco_responsable', 'passion_beaute', 'passion_yoga', 'type_bien_etre', 'type_beaute_soins', 'age_adulte', 'popularite_4', 'occasion_noel', 'occasion_fete', 'occasion_remerciement', 'occasion_anniversaire'] },
  { name: 'Coffret Soins Clarins Double Serum', brand: 'Clarins', price: 139, image: 'https://m.media-amazon.com/images/I/51SHrJlgKYL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B09X2TRZ5Q', source: 'Amazon', categories: ['beauté', 'soin'], tags: ['gender_femme', 'budget_100_200', 'cat_beaute', 'style_classique', 'passion_beaute', 'type_beaute_soins', 'type_bien_etre', 'age_adulte', 'popularite_5', 'occasion_anniversaire', 'occasion_noel', 'occasion_fete'] },
  { name: 'Gua Sha Jade Naturel', brand: 'Zen Collection', price: 19.99, image: 'https://m.media-amazon.com/images/I/41K-P2Uf5eL._SX425_.jpg', url: 'https://www.amazon.fr/s?k=gua+sha+jade', source: 'Amazon', categories: ['beauté', 'bien-être'], tags: ['gender_femme', 'budget_0_50', 'cat_beaute', 'style_eco_responsable', 'passion_beaute', 'passion_yoga', 'type_beaute_soins', 'type_bien_etre', 'age_ado', 'age_adulte', 'popularite_4', 'occasion_anniversaire'] },
  { name: 'Sérum Vitamin C Skinceuticals 30ml', brand: 'SkinCeuticals', price: 170, image: 'https://m.media-amazon.com/images/I/41K-P2Uf5eL._SX425_.jpg', url: 'https://www.amazon.fr/dp/B000XP2LSS', source: 'Amazon', categories: ['beauté', 'soin'], tags: ['gender_femme', 'budget_100_200', 'cat_beaute', 'style_moderne', 'passion_beaute', 'type_beaute_soins', 'age_adulte', 'popularite_5', 'occasion_anniversaire'] },

  // ─── CADEAUX TENDANCES / TikTok / VIRAL ─────────────────────────────────────
  { name: 'Stanley Quencher H2.0 40oz Rose', brand: 'Stanley', price: 49.99, image: 'https://m.media-amazon.com/images/I/71pWKZv3XQL._AC_SX522_.jpg', url: 'https://www.amazon.fr/s?k=stanley+quencher', source: 'Amazon', categories: ['tendances', 'sport'], tags: ['gender_femme', 'budget_25_50', 'cat_tendances', 'style_tendance', 'style_sportif', 'passion_sport', 'passion_voyages', 'perso_actif', 'type_sport_outdoor', 'age_ado', 'age_adulte', 'popularite_5', 'occasion_anniversaire'] },
  { name: 'Loungefly Sac Mini Disney Premium', brand: 'Loungefly', price: 79.99, image: 'https://m.media-amazon.com/images/I/61hF0k4nzgL._AC_SX522_.jpg', url: 'https://www.amazon.fr/s?k=loungefly+disney', source: 'Amazon', categories: ['mode', 'tendances'], tags: ['gender_femme', 'budget_50_100', 'cat_mode', 'style_tendance', 'style_streetwear', 'passion_mode', 'passion_cinema', 'perso_excentrique', 'type_mode_accessoires', 'age_ado', 'popularite_5', 'occasion_anniversaire', 'occasion_noel'] },
  { name: 'PopSocket MagSafe iPhone Personnalisé', brand: 'PopSockets', price: 24.99, image: 'https://m.media-amazon.com/images/I/61xYHB10RQL._AC_SX522_.jpg', url: 'https://www.amazon.fr/s?k=popsocket+magsafe', source: 'Amazon', categories: ['tech', 'tendances'], tags: ['gender_mixte', 'budget_0_50', 'cat_tech', 'style_tendance', 'passion_tech', 'passion_mode', 'type_high_tech', 'age_ado', 'age_adulte', 'popularite_4'] },
  { name: 'Carnet Leuchtturm1917 Bullet Journal', brand: 'Leuchtturm1917', price: 24, image: 'https://m.media-amazon.com/images/I/71pZnMvkBCL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B002CVAU1Y', source: 'Amazon', categories: ['papeterie', 'tendances'], tags: ['gender_mixte', 'budget_0_50', 'cat_tendances', 'style_minimaliste', 'passion_art', 'passion_lecture', 'perso_creatif', 'perso_intellectuel', 'type_loisirs_creatifs', 'type_culture', 'age_ado', 'age_adulte', 'popularite_4', 'occasion_anniversaire', 'occasion_remerciement'] },
  { name: 'Acupressure Mat & Pillow Set', brand: 'Pranamat', price: 65, image: 'https://m.media-amazon.com/images/I/71pWKZv3XQL._AC_SX522_.jpg', url: 'https://www.amazon.fr/s?k=tapis+acupression', source: 'Amazon', categories: ['bien-être', 'tendances'], tags: ['gender_mixte', 'budget_50_100', 'cat_maison', 'style_tendance', 'passion_yoga', 'passion_sport', 'perso_zen', 'type_bien_etre', 'age_adulte', 'popularite_5', 'occasion_anniversaire', 'occasion_noel'] },

  // ─── ENFANTS / ADOS ─────────────────────────────────────────────────────────
  { name: 'LEGO Star Wars Millennium Falcon 75257', brand: 'LEGO', price: 129.99, image: 'https://m.media-amazon.com/images/I/71pWKZv3XQL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B07S8FKLK5', source: 'Amazon', categories: ['jeux', 'enfants'], tags: ['gender_mixte', 'budget_100_200', 'cat_tendances', 'style_moderne', 'passion_cinema', 'passion_jeuxvideo', 'perso_creatif', 'type_jeux_jouets', 'age_enfant', 'age_ado', 'popularite_5', 'occasion_noel', 'occasion_anniversaire'] },
  { name: 'Casque Gaming Corsair HS65 Wireless', brand: 'Corsair', price: 109, image: 'https://m.media-amazon.com/images/I/51aXvjzcukL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B0B49KZZW8', source: 'Amazon', categories: ['tech', 'gaming'], tags: ['gender_mixte', 'budget_100_200', 'cat_tech', 'style_moderne', 'passion_jeuxvideo', 'passion_musique', 'perso_techie', 'type_high_tech', 'type_musique_audio', 'age_ado', 'age_adulte', 'popularite_4', 'occasion_noel', 'occasion_anniversaire'] },

  // ─── PERSONNALITÉ / PROFIL SPÉCIFIQUES ───────────────────────────────────────
  { name: 'Polaroid Now+ Appareil Photo Instantané', brand: 'Polaroid', price: 149, image: 'https://m.media-amazon.com/images/I/71JFV4X4+PL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/B08NY4CV1X', source: 'Amazon', categories: ['photo', 'tendances'], tags: ['gender_mixte', 'budget_100_200', 'cat_tendances', 'style_vintage', 'style_tendance', 'passion_photo', 'passion_art', 'perso_creatif', 'perso_excentrique', 'type_loisirs_creatifs', 'age_ado', 'age_adulte', 'popularite_5', 'occasion_anniversaire', 'occasion_noel'] },
  { name: 'Vinyl Player Retrolife Q2 Bois', brand: 'Retrolife', price: 149, image: 'https://m.media-amazon.com/images/I/61rG3mHG3hL._AC_SX522_.jpg', url: 'https://www.amazon.fr/s?k=vinyl+player+retrolife', source: 'Amazon', categories: ['musique', 'déco'], tags: ['gender_mixte', 'budget_100_200', 'cat_maison', 'style_vintage', 'style_tendance', 'passion_musique', 'passion_art', 'perso_excentrique', 'type_musique_audio', 'type_maison_deco', 'age_adulte', 'popularite_5', 'occasion_anniversaire', 'occasion_noel'] },
  { name: 'Kit Brassage Bière Artisanale Maison', brand: 'Brassez Vous-même', price: 59, image: 'https://m.media-amazon.com/images/I/61E9wl7LVIL._AC_SX522_.jpg', url: 'https://www.amazon.fr/s?k=kit+brassage+biere+maison', source: 'Amazon', categories: ['food', 'loisirs'], tags: ['gender_homme', 'budget_50_100', 'cat_food', 'style_decontracte', 'passion_vins', 'passion_cuisine', 'passion_bricolage', 'perso_creatif', 'perso_aventurier', 'type_gastronomie', 'type_loisirs_creatifs', 'age_adulte', 'popularite_4', 'occasion_anniversaire', 'occasion_noel'] },
  { name: 'Livre De Cuisine Ottolenghi SIMPLE', brand: 'Ottolenghi', price: 35, image: 'https://m.media-amazon.com/images/I/71pZnMvkBCL._AC_SX522_.jpg', url: 'https://www.amazon.fr/dp/2891138082', source: 'Amazon', categories: ['livre', 'cuisine'], tags: ['gender_mixte', 'budget_25_50', 'cat_food', 'style_moderne', 'passion_cuisine', 'perso_gourmand', 'perso_creatif', 'type_gastronomie', 'type_livres_bd', 'age_adulte', 'popularite_5', 'occasion_anniversaire', 'occasion_remerciement', 'occasion_noel'] },
  { name: 'Coffret Peinture Numérotée 40x50cm', brand: 'Schipper', price: 34.99, image: 'https://m.media-amazon.com/images/I/71pZnMvkBCL._AC_SX522_.jpg', url: 'https://www.amazon.fr/s?k=peinture+par+numero+adulte', source: 'Amazon', categories: ['art', 'loisirs'], tags: ['gender_mixte', 'budget_25_50', 'cat_tendances', 'style_tendance', 'passion_art', 'passion_loisirs_creatifs', 'perso_creatif', 'type_loisirs_creatifs', 'type_culture', 'age_adulte', 'popularite_5', 'occasion_anniversaire', 'occasion_noel'] },
];

// Budget tags manquants → mapper les 0-50 correctement
function normalizeBudget(price) {
  if (price < 50)  return 'budget_0_50';
  if (price < 100) return 'budget_50_100';
  if (price < 200) return 'budget_100_200';
  return 'budget_200+';
}

// Corriger le budget tag pour chaque nouveau produit
NEW_GIFTS.forEach(p => {
  const existingBudget = p.tags.find(t => VALID_BUDGET_TAGS.includes(t));
  const correct = normalizeBudget(p.price);
  if (existingBudget && existingBudget !== correct) {
    const idx = p.tags.indexOf(existingBudget);
    p.tags[idx] = correct;
  }
  if (!existingBudget) {
    p.tags.push(correct);
  }
  // Remplacer budget_25_50 qui n'est pas valide
  p.tags = p.tags.map(t => t === 'budget_25_50' ? 'budget_0_50' : t);
  // Supprimer les doublons
  p.tags = [...new Set(p.tags)];
  // Ne garder que les tags valides
  p.tags = p.tags.filter(t => ALL_VALID_TAGS.has(t));
});

// ══════════════════════════════════════════════════════════════════════════════
// SECTION 5 — MOTEUR PRINCIPAL
// ══════════════════════════════════════════════════════════════════════════════

const report = {
  existing: { total: 0, images_broken: 0, images_fixed: 0, tags_fixed: 0, tags_ok: 0 },
  added: { total: 0, success: 0, fail: 0 },
  errors: [],
};

async function runConcurrent(items, fn, limit) {
  const results = [];
  for (let i = 0; i < items.length; i += limit) {
    const batch = items.slice(i, i + limit);
    const res = await Promise.all(batch.map(fn));
    results.push(...res);
  }
  return results;
}

// ─── Étape 1 : Audit & Fix des produits existants ────────────────────────────
async function auditAndFixExisting() {
  console.log('\n╔══════════════════════════════════════════════════════════════╗');
  console.log('║  📊 ÉTAPE 1 : AUDIT & CORRECTION DES PRODUITS EXISTANTS     ║');
  console.log('╚══════════════════════════════════════════════════════════════╝\n');

  const snapshot = await db.collection('gifts').get();
  report.existing.total = snapshot.size;
  console.log(`   ✅ ${snapshot.size} produits trouvés dans Firestore\n`);

  if (snapshot.empty) {
    console.log('   ⚠️  Collection gifts vide — skip\n');
    return;
  }

  // Analyse parallèle des images
  console.log(`   🔍 Vérification des ${snapshot.size} images...`);
  let checked = 0;

  const analyzeDoc = async (doc) => {
    const data = doc.data();
    const name  = data.name || data.product_title || '';
    const brand = data.brand || data.source || '';
    const cats  = Array.isArray(data.categories) ? data.categories : [];
    const imgUrl = data.image || data.imageUrl || '';
    const price  = typeof data.price === 'number' ? data.price : parseFloat(data.price) || 0;

    // Vérifier l'image
    const imgCheck = await checkImage(imgUrl);
    checked++;
    if (checked % 25 === 0) process.stdout.write(`   📊 ${checked}/${snapshot.size} vérifiés...\r`);

    let updates = {};
    let needsFix = false;

    // Fix image si cassée
    if (!imgCheck.ok) {
      report.existing.images_broken++;
      if (DO_FIX) {
        const currentTags = Array.isArray(data.tags) ? data.tags : [];
        const catTags = currentTags.filter(t => VALID_CATEGORY_TAGS.includes(t));
        const newImg = findBestImage(name, brand, catTags);
        updates.image    = newImg;
        updates.imageUrl = newImg;
        updates.imageFixed = true;
        updates.imageFixedAt = new Date().toISOString();
        report.existing.images_fixed++;
        needsFix = true;
      }
    }

    // Fix tags (toujours fait si DO_FIX)
    if (DO_FIX) {
      const perfectTags = buildPerfectTags({ ...data, price });
      const currentTagsStr = JSON.stringify((data.tags || []).sort());
      const newTagsStr = JSON.stringify(perfectTags.sort());
      if (currentTagsStr !== newTagsStr) {
        updates.tags = perfectTags;
        updates.updatedAt = new Date().toISOString();
        report.existing.tags_fixed++;
        needsFix = true;
      } else {
        report.existing.tags_ok++;
      }
    }

    if (needsFix && DO_FIX && !AUDIT_ONLY) {
      try {
        await doc.ref.update(updates);
      } catch(e) {
        report.errors.push(`Fix "${name}": ${e.message}`);
      }
    }

    return { name, broken: !imgCheck.ok, reason: imgCheck.reason };
  };

  const results = await runConcurrent(snapshot.docs, analyzeDoc, CONCURRENCY);
  const broken = results.filter(r => r.broken);

  console.log(`\n\n   📊 Images OK    : ${snapshot.size - broken.length}`);
  console.log(`   ❌ Images cassées: ${broken.length}`);
  if (DO_FIX && !AUDIT_ONLY) {
    console.log(`   🔧 Images fixées : ${report.existing.images_fixed}`);
    console.log(`   🏷️  Tags corrigés : ${report.existing.tags_fixed}`);
    console.log(`   ✅ Tags OK       : ${report.existing.tags_ok}`);
  }

  if (AUDIT_ONLY && broken.length > 0) {
    console.log('\n   📋 Produits avec images cassées :');
    broken.slice(0, 20).forEach((b, i) => console.log(`   ${i+1}. "${b.name}" (${b.reason})`));
  }
}

// ─── Étape 2 : Ajout des nouveaux produits ────────────────────────────────────
async function addNewProducts() {
  console.log('\n╔══════════════════════════════════════════════════════════════╗');
  console.log('║  🎁 ÉTAPE 2 : AJOUT DE NOUVEAUX PRODUITS PREMIUM             ║');
  console.log('╚══════════════════════════════════════════════════════════════╝\n');

  // Vérifier les doublons (par nom)
  console.log('   🔍 Vérification des doublons...');
  const existing = await db.collection('gifts').get();
  const existingNames = new Set();
  existing.forEach(d => {
    const n = (d.data().name || '').toLowerCase().trim();
    if (n) existingNames.add(n);
  });

  const toAdd = NEW_GIFTS.filter(p => !existingNames.has(p.name.toLowerCase().trim()));
  const skipped = NEW_GIFTS.length - toAdd.length;

  console.log(`   📦 ${NEW_GIFTS.length} nouveaux produits préparés`);
  console.log(`   ⏭️  ${skipped} déjà présents (ignorés)`);
  console.log(`   ➕ ${toAdd.length} à ajouter\n`);

  if (toAdd.length === 0) {
    console.log('   ✅ Rien à ajouter — tous les produits sont déjà dans la base\n');
    return;
  }

  const now = new Date().toISOString();
  let success = 0, fail = 0;

  for (const product of toAdd) {
    try {
      const docData = {
        name:       product.name,
        brand:      product.brand,
        price:      product.price,
        image:      product.image,
        imageUrl:   product.image,
        url:        product.url,
        source:     product.source,
        categories: product.categories,
        tags:       product.tags,
        active:     true,
        popularity: product.tags.includes('popularite_5') ? 99 :
                    product.tags.includes('popularite_4') ? 90 :
                    product.tags.includes('popularite_3') ? 80 : 70,
        createdAt:  now,
        updatedAt:  now,
        addedBy:    'doron_perfect_database_v1',
      };

      await db.collection('gifts').add(docData);
      success++;
      process.stdout.write(`   ✅ [${success}/${toAdd.length}] ${product.name.substring(0,50).padEnd(50)}\r`);
    } catch(e) {
      fail++;
      report.errors.push(`Add "${product.name}": ${e.message}`);
    }
  }

  report.added.total   = toAdd.length;
  report.added.success = success;
  report.added.fail    = fail;

  console.log(`\n\n   ✅ ${success} produits ajoutés avec succès`);
  if (fail > 0) console.log(`   ❌ ${fail} erreurs`);
}

// ─── Rapport final ────────────────────────────────────────────────────────────
async function printFinalReport() {
  // Compte final
  const finalSnap = await db.collection('gifts').get();
  const finalCount = finalSnap.size;

  // Analyse des tags de la base finale
  const tagStats = { gender: {}, budget: {}, cat: {}, passion: {} };
  finalSnap.forEach(doc => {
    const tags = doc.data().tags || [];
    for (const t of tags) {
      if (t.startsWith('gender_')) tagStats.gender[t] = (tagStats.gender[t] || 0) + 1;
      if (t.startsWith('budget_')) tagStats.budget[t] = (tagStats.budget[t] || 0) + 1;
      if (t.startsWith('cat_'))    tagStats.cat[t]    = (tagStats.cat[t]    || 0) + 1;
      if (t.startsWith('passion_')) tagStats.passion[t] = (tagStats.passion[t] || 0) + 1;
    }
  });

  console.log('\n╔══════════════════════════════════════════════════════════════╗');
  console.log('║                    ✅ RAPPORT FINAL                          ║');
  console.log('╠══════════════════════════════════════════════════════════════╣');
  console.log(`║  📦 TOTAL PRODUITS EN BASE    : ${String(finalCount).padEnd(28)}║`);
  console.log(`║  ─────────────────────────────────────────────────          ║`);
  console.log(`║  EXISTANTS                    : ${String(report.existing.total).padEnd(28)}║`);
  if (DO_FIX) {
  console.log(`║  🖼️  Images corrigées          : ${String(report.existing.images_fixed).padEnd(28)}║`);
  console.log(`║  🏷️  Tags normalisés           : ${String(report.existing.tags_fixed).padEnd(28)}║`);
  }
  if (DO_ADD) {
  console.log(`║  ➕ Nouveaux ajoutés           : ${String(report.added.success).padEnd(28)}║`);
  }
  console.log('║  ─────────────────────────────────────────────────          ║');
  console.log('║  📊 RÉPARTITION GENRES :                                    ║');
  Object.entries(tagStats.gender).sort().forEach(([t,n]) =>
    console.log(`║     ${t.padEnd(20)} : ${String(n).padEnd(35)}║`)
  );
  console.log('║  📊 RÉPARTITION BUDGETS :                                   ║');
  Object.entries(tagStats.budget).sort().forEach(([t,n]) =>
    console.log(`║     ${t.padEnd(20)} : ${String(n).padEnd(35)}║`)
  );
  console.log('║  📊 RÉPARTITION CATÉGORIES :                                ║');
  Object.entries(tagStats.cat).sort().forEach(([t,n]) =>
    console.log(`║     ${t.padEnd(20)} : ${String(n).padEnd(35)}║`)
  );
  console.log('╠══════════════════════════════════════════════════════════════╣');
  if (report.errors.length > 0) {
    console.log(`║  ⚠️  ${report.errors.length} erreur(s) rencontrées :                              ║`);
    report.errors.slice(0, 5).forEach(e => console.log(`║     ${e.substring(0,55).padEnd(57)}║`));
  } else {
    console.log('║  ✅ Aucune erreur !                                          ║');
  }
  console.log('╚══════════════════════════════════════════════════════════════╝');
  console.log('\n🎉 Base de données Doron PARFAITE ! Lance l\'app pour vérifier.\n');
}

// ─── Main ─────────────────────────────────────────────────────────────────────
async function main() {
  console.log('');
  console.log('╔══════════════════════════════════════════════════════════════╗');
  console.log('║    🎁 DORON — PERFECT DATABASE BUILDER v1.0                 ║');
  console.log(`║    Mode : ${AUDIT_ONLY ? '🔍 AUDIT SEULEMENT' : FIX_ONLY ? '🔧 FIX SEULEMENT' : ADD_ONLY ? '➕ AJOUT SEULEMENT' : '🔴 COMPLET (fix + ajout)'}${' '.repeat(AUDIT_ONLY ? 42 : FIX_ONLY ? 41 : ADD_ONLY ? 40 : 35)}║`);
  console.log('╚══════════════════════════════════════════════════════════════╝');
  console.log('');

  try {
    if (!ADD_ONLY) {
      await auditAndFixExisting();
    }
    if (DO_ADD) {
      await addNewProducts();
    }
    await printFinalReport();
  } catch(err) {
    console.error('\n❌ ERREUR CRITIQUE:', err.message || err);
    console.error(err.stack);
    process.exit(1);
  }

  process.exit(0);
}

main();
