#!/usr/bin/env node
/**
 * Import massif de produits depuis une API RapidAPI de type "comparateur"
 * (par défaut : Real-Time Product Search — agrégateur Google Shopping, large
 * couverture marques) vers Firestore (`gifts` + `brands`).
 *
 * Conçu comme un import PAR LOT, PAS un appel en direct depuis l'app :
 * on paie/appelle une fois (ou de temps en temps pour rafraîchir), on écrit
 * tout dans Firestore, l'app ne rappelle plus jamais l'API au runtime.
 *
 * ⚠️ IMPORTANT AVANT UN VRAI IMPORT :
 * Les noms de champs de la réponse RapidAPI ci-dessous (PRODUCT_FIELD_MAP)
 * sont basés sur la structure documentée habituelle de ce type d'API, mais
 * n'ont PAS pu être vérifiés en conditions réelles (pas de clé disponible
 * au moment de l'écriture de ce script). Lance TOUJOURS d'abord :
 *   node import_products_rapidapi.js --inspect
 * pour voir la réponse brute d'une seule requête et ajuster
 * PRODUCT_FIELD_MAP si besoin, AVANT de lancer un import complet qui
 * consomme ton quota RapidAPI.
 *
 * USAGE :
 *   node import_products_rapidapi.js --inspect              → 1 requête, affiche le JSON brut, n'écrit rien
 *   node import_products_rapidapi.js --dry-run               → tourne tout mais n'écrit rien dans Firestore
 *   node import_products_rapidapi.js --dry-run --max-queries=5
 *   node import_products_rapidapi.js                          → import réel complet
 *   node import_products_rapidapi.js --max-queries=20         → import réel limité (contrôle du coût)
 *
 * Prérequis :
 *   - scripts/.env avec RAPIDAPI_KEY (voir .env.example)
 *   - scripts/serviceAccountKey.json (voir GUIDE_FIREBASE_UPLOAD.md)
 */

require('dotenv').config();
const admin = require('firebase-admin');
const fetch = require('node-fetch');

const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const RAPIDAPI_KEY = process.env.RAPIDAPI_KEY;
const RAPIDAPI_HOST = process.env.RAPIDAPI_HOST || 'real-time-product-search.p.rapidapi.com';

if (!RAPIDAPI_KEY) {
  console.error('❌ RAPIDAPI_KEY manquant dans scripts/.env (voir .env.example)');
  process.exit(1);
}

const INSPECT = process.argv.includes('--inspect');
const DRY_RUN = process.argv.includes('--dry-run') || INSPECT;
const maxQueriesArg = process.argv.find((a) => a.startsWith('--max-queries='));
const MAX_QUERIES = maxQueriesArg ? parseInt(maxQueriesArg.split('=')[1], 10) : Infinity;

// Délai entre deux appels API pour rester tranquille sur les plans RapidAPI
// à quota/minute limité (ajuste selon ton plan).
const DELAY_BETWEEN_CALLS_MS = 600;

// ============================================================================
// 1. LISTE DES REQUÊTES — marques × catégories pour une couverture large
// ============================================================================

// Grandes marques visées (mode, tech, beauté, maison, sport, jouets...).
// Complète cette liste librement — chaque entrée = potentiellement plusieurs
// appels API (une par mot-clé de BASE_KEYWORDS croisé).
const BRANDS = [
  'Zara', 'H&M', 'Nike', 'Adidas', 'Uniqlo', 'Levi\'s', 'Mango', 'Bershka',
  'Pull&Bear', 'Sephora', 'Yves Rocher', 'Apple', 'Samsung', 'Sony', 'Xiaomi',
  'JBL', 'Fnac', 'Decathlon', 'IKEA', 'Maisons du Monde', 'Lego', 'PlayStation',
  'Xbox', 'Nintendo', 'Nespresso', 'Le Creuset', 'Ray-Ban', 'Pandora', 'Swarovski',
  'Clarins', 'L\'Oréal', 'Dyson', 'Philips', 'Petit Bateau', 'Kiabi', 'Célio',
];

// Mots-clés génériques (sans marque) pour élargir encore la variété — ce sont
// eux qui, croisés avec CATEGORY_TAG_MAP ci-dessous, injectent les tags
// gender_*/cat_*/type_* au moment de l'écriture.
const GENERIC_QUERIES = [
  { q: 'casquette', category: 'cat_mode', gender: null, type: ['type_mode_accessoires'] },
  { q: 'sac à main femme', category: 'cat_mode', gender: 'gender_femme', type: ['type_mode_accessoires'] },
  { q: 'montre homme', category: 'cat_mode', gender: 'gender_homme', type: ['type_mode_accessoires'] },
  { q: 'parfum femme', category: 'cat_beaute', gender: 'gender_femme', type: ['type_beaute_soins'] },
  { q: 'parfum homme', category: 'cat_beaute', gender: 'gender_homme', type: ['type_beaute_soins'] },
  { q: 'casque audio', category: 'cat_tech', gender: null, type: ['type_high_tech', 'type_musique_audio'] },
  { q: 'enceinte bluetooth', category: 'cat_tech', gender: null, type: ['type_high_tech', 'type_musique_audio'] },
  { q: 'jeux de société', category: 'cat_tendances', gender: null, type: ['type_jeux_jouets'] },
  { q: 'livre best seller', category: 'cat_tendances', gender: null, type: ['type_livres_bd'] },
  { q: 'bougie parfumée', category: 'cat_maison', gender: null, type: ['type_maison_deco'] },
  { q: 'coffret vin', category: 'cat_food', gender: null, type: ['type_gastronomie'] },
  { q: 'bijoux femme', category: 'cat_mode', gender: 'gender_femme', type: ['type_bijoux'] },
  { q: 'chaussures de sport', category: 'cat_tendances', gender: null, type: ['type_sport_outdoor'] },
  { q: 'idée cadeau noël', category: 'cat_tendances', gender: null, occasion: 'occasion_noel' },
  { q: 'idée cadeau anniversaire', category: 'cat_tendances', gender: null, occasion: 'occasion_anniversaire' },
  { q: 'idée cadeau saint valentin', category: 'cat_tendances', gender: null, occasion: 'occasion_saint_valentin' },
  { q: 'jouets enfant', category: 'cat_tendances', gender: 'gender_mixte', type: ['type_jeux_jouets'] },
  { q: 'déco maison', category: 'cat_maison', gender: null, type: ['type_maison_deco'] },
  { q: 'valise voyage', category: 'cat_tendances', gender: null, type: ['type_voyage_aventure'] },
  { q: 'appareil photo', category: 'cat_tech', gender: null, type: ['type_high_tech'] },
];

function buildQueryList() {
  const queries = [];
  for (const brand of BRANDS) {
    queries.push({ q: brand, brand, category: null });
  }
  for (const g of GENERIC_QUERIES) {
    queries.push(g);
  }
  return queries;
}

// ============================================================================
// 2. TAGGING — heuristiques (miroir simplifié de tags_definitions.dart)
// ============================================================================

const GENDER_KEYWORDS = {
  gender_femme: ['femme', 'women', 'girl', 'fille', 'robe', 'jupe', 'soutien-gorge'],
  gender_homme: ['homme', 'men', 'man', 'garçon', 'cravate', 'rasoir'],
};

const STYLE_KEYWORDS = {
  style_elegant: ['élégant', 'elegant', 'chic'],
  style_sportif: ['sport', 'running', 'fitness'],
  style_luxe: ['luxe', 'luxury', 'premium'],
  style_moderne: ['moderne', 'modern', 'design'],
  style_vintage: ['vintage', 'rétro', 'retro'],
  style_minimaliste: ['minimaliste', 'minimalist', 'épuré'],
};

const PASSION_KEYWORDS = {
  passion_tech: ['tech', 'gadget', 'électronique', 'connecté'],
  passion_mode: ['mode', 'fashion', 'vêtement'],
  passion_beaute: ['beauté', 'beauty', 'maquillage', 'parfum', 'soin'],
  passion_cuisine: ['cuisine', 'gastronomie', 'chef'],
  passion_sport: ['sport', 'fitness', 'running', 'outdoor'],
  passion_musique: ['musique', 'audio', 'son', 'enceinte', 'casque'],
  passion_lecture: ['livre', 'book', 'lecture'],
  passion_jeuxvideo: ['jeu vidéo', 'gaming', 'console', 'playstation', 'xbox', 'nintendo'],
  passion_voyages: ['voyage', 'valise', 'bagage'],
};

function slugify(str) {
  return String(str)
    .toLowerCase()
    .normalize('NFD').replace(/[̀-ͯ]/g, '') // accents
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');
}

function detectFromKeywords(text, keywordMap) {
  const found = [];
  const lower = text.toLowerCase();
  for (const [tag, keywords] of Object.entries(keywordMap)) {
    if (keywords.some((kw) => lower.includes(kw))) found.push(tag);
  }
  return found;
}

function budgetTagFromPrice(price) {
  if (price == null) return null;
  if (price < 50) return 'budget_0_50';
  if (price < 100) return 'budget_50_100';
  if (price < 200) return 'budget_100_200';
  return 'budget_200+';
}

// --- Tokenizer (identique à lib/services/search_tokenizer.dart) -----------
const MIN_WORD_LENGTH = 2;
const MAX_WORD_LENGTH_INDEXED = 24;
const MAX_TOKENS_PER_PRODUCT = 200;
function normalizeText(input) {
  return String(input).toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '');
}
function wordsFrom(text) {
  return normalizeText(text)
    .split(/[^a-z0-9]+/)
    .filter((w) => w.length >= MIN_WORD_LENGTH && w.length <= MAX_WORD_LENGTH_INDEXED);
}
function buildSearchTokens(texts) {
  const tokens = new Set();
  for (const text of texts) {
    if (!text) continue;
    for (const word of wordsFrom(text)) {
      for (let end = MIN_WORD_LENGTH; end <= word.length; end++) {
        tokens.add(word.substring(0, end));
        if (tokens.size >= MAX_TOKENS_PER_PRODUCT) return Array.from(tokens);
      }
    }
  }
  return Array.from(tokens);
}

function buildProductTags({ name, description, price, queryMeta }) {
  const text = `${name} ${description || ''}`;
  const tags = new Set();

  // Genre : priorité au hint de la requête, sinon détection mots-clés
  if (queryMeta.gender) {
    tags.add(queryMeta.gender);
  } else {
    detectFromKeywords(text, GENDER_KEYWORDS).forEach((t) => tags.add(t));
  }

  if (queryMeta.category) tags.add(queryMeta.category);
  if (queryMeta.occasion) tags.add(queryMeta.occasion);
  (queryMeta.type || []).forEach((t) => tags.add(t));

  detectFromKeywords(text, STYLE_KEYWORDS).forEach((t) => tags.add(t));
  detectFromKeywords(text, PASSION_KEYWORDS).forEach((t) => tags.add(t));

  const budgetTag = budgetTagFromPrice(price);
  if (budgetTag) tags.add(budgetTag);

  return Array.from(tags);
}

// ============================================================================
// 3. APPEL API — défensif sur les noms de champs (voir avertissement en tête)
// ============================================================================

async function fetchProductsForQuery(query, country = 'fr', language = 'fr') {
  const url = `https://${RAPIDAPI_HOST}/search?q=${encodeURIComponent(query)}&country=${country}&language=${language}`;
  const res = await fetch(url, {
    headers: {
      'X-RapidAPI-Key': RAPIDAPI_KEY,
      'X-RapidAPI-Host': RAPIDAPI_HOST,
    },
  });
  if (!res.ok) {
    throw new Error(`RapidAPI ${res.status} ${res.statusText} pour "${query}"`);
  }
  const json = await res.json();

  if (INSPECT) {
    console.log(JSON.stringify(json, null, 2).slice(0, 4000));
    return [];
  }

  // Formats de réponse possibles selon l'API RapidAPI réellement utilisée —
  // À AJUSTER après vérification via --inspect.
  const items = json?.data?.products || json?.data || json?.products || json?.results || [];
  return Array.isArray(items) ? items : [];
}

function extractField(item, candidates, fallback = null) {
  for (const key of candidates) {
    const val = key.split('.').reduce((o, k) => (o == null ? undefined : o[k]), item);
    if (val !== undefined && val !== null && val !== '') return val;
  }
  return fallback;
}

function normalizeProduct(item, queryMeta) {
  const name = extractField(item, ['product_title', 'title', 'name']);
  if (!name) return null;

  const imageRaw = extractField(item, ['product_photos.0', 'product_photo', 'image', 'thumbnail']);
  const priceRaw = extractField(item, ['offer.price', 'product_price', 'price', 'typical_price_range.0']);
  const priceNum = typeof priceRaw === 'number'
    ? priceRaw
    : parseFloat(String(priceRaw || '').replace(/[^0-9.,]/g, '').replace(',', '.')) || null;

  const brand = queryMeta.brand || extractField(item, ['product_attributes.Brand', 'brand', 'source']) || 'Autre';
  const url = extractField(item, ['product_page_url', 'offer.offer_page_url', 'url', 'link']);
  const description = extractField(item, ['product_description', 'description'], '');

  return {
    name,
    brand,
    brandId: slugify(brand),
    price: priceNum,
    image: imageRaw,
    imageUrl: imageRaw,
    url,
    source: 'RapidAPI',
    description,
    categories: queryMeta.category ? [queryMeta.category.replace('cat_', '')] : [],
    tags: buildProductTags({ name, description, price: priceNum, queryMeta }),
    active: true,
    popularity: 50,
    createdAt: new Date().toISOString(),
    addedBy: 'import_products_rapidapi_v1',
  };
}

// ============================================================================
// 4. IMPORT PRINCIPAL
// ============================================================================

async function run() {
  const queries = buildQueryList().slice(0, MAX_QUERIES === Infinity ? undefined : MAX_QUERIES);
  console.log(`🚀 ${INSPECT ? 'INSPECT' : DRY_RUN ? 'DRY RUN' : 'IMPORT RÉEL'} — ${queries.length} requêtes prévues\n`);

  const seenKeys = new Set(); // dédoublonnage brand+name
  const allProducts = [];
  const brandsSeen = new Map(); // id -> {name, order}
  let order = 0;

  for (const query of queries) {
    const q = query.q;
    process.stdout.write(`🔎 "${q}"… `);
    try {
      const items = await fetchProductsForQuery(q);
      let added = 0;
      for (const item of items) {
        const product = normalizeProduct(item, query);
        if (!product) continue;
        const key = `${product.brandId}::${slugify(product.name)}`;
        if (seenKeys.has(key)) continue;
        seenKeys.add(key);

        product.searchTokens = buildSearchTokens([product.name, product.brand, ...product.categories]);
        allProducts.push(product);
        added++;

        if (!brandsSeen.has(product.brandId)) {
          brandsSeen.set(product.brandId, { name: product.brand, order: order++ });
        }
      }
      console.log(`+${added} produits (${items.length} reçus)`);
    } catch (e) {
      console.log(`❌ ${e.message}`);
    }

    if (INSPECT) break; // une seule requête suffit pour inspecter le format
    await new Promise((r) => setTimeout(r, DELAY_BETWEEN_CALLS_MS));
  }

  console.log(`\n📊 Total: ${allProducts.length} produits uniques, ${brandsSeen.size} marques`);

  if (DRY_RUN) {
    console.log('🔍 DRY RUN — aucune écriture Firestore. Exemple de produit :');
    console.log(JSON.stringify(allProducts[0], null, 2));
    return;
  }

  // --- Écriture Firestore : gifts (batches de 450) -------------------------
  let batch = db.batch();
  let count = 0;
  for (const product of allProducts) {
    const ref = db.collection('gifts').doc();
    batch.set(ref, product);
    count++;
    if (count % 450 === 0) {
      await batch.commit();
      batch = db.batch();
      console.log(`   … ${count} produits écrits`);
    }
  }
  if (count % 450 !== 0) await batch.commit();
  console.log(`✅ ${count} produits écrits dans 'gifts'`);

  // --- Écriture Firestore : brands (pour le filtre marque de la home) ------
  let brandBatch = db.batch();
  let brandCount = 0;
  for (const [id, info] of brandsSeen.entries()) {
    const ref = db.collection('brands').doc(id);
    brandBatch.set(ref, { name: info.name, order: info.order }, { merge: true });
    brandCount++;
  }
  await brandBatch.commit();
  console.log(`✅ ${brandCount} marques écrites dans 'brands'`);
}

run()
  .then(() => { console.log('\n🏁 Terminé.'); process.exit(0); })
  .catch((e) => { console.error('❌ Erreur fatale:', e); process.exit(1); });
