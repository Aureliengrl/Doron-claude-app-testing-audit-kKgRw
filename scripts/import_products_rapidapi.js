#!/usr/bin/env node
/**
 * Import massif de produits depuis une API RapidAPI de recherche produit
 * vers Firestore (`gifts` + `brands`).
 *
 * Système d'ADAPTATEURS : plusieurs APIs supportées (voir API_ADAPTERS).
 * Par défaut "amazon" (Real-Time Amazon Data — stable, très large couverture
 * marques). Pour changer d'API : mets RAPIDAPI_ADAPTER=<nom> dans scripts/.env.
 *
 * Conçu comme un import PAR LOT, PAS un appel en direct depuis l'app :
 * on appelle une fois (ou de temps en temps pour rafraîchir), on écrit tout
 * dans Firestore, l'app ne rappelle plus jamais l'API au runtime.
 *
 * ⚠️ AVANT UN VRAI IMPORT : le mapping des champs de chaque adaptateur est
 * basé sur le format documenté de l'API, mais peut varier. Lance TOUJOURS
 * d'abord `--inspect` (1 seule requête) pour voir la réponse brute et
 * ajuster l'adaptateur si besoin, AVANT de consommer ton quota.
 *
 * USAGE :
 *   node import_products_rapidapi.js --inspect              → 1 requête, affiche le JSON brut, n'écrit rien
 *   node import_products_rapidapi.js --dry-run               → tourne tout mais n'écrit rien dans Firestore
 *   node import_products_rapidapi.js --dry-run --max-queries=5
 *   node import_products_rapidapi.js                          → import réel complet
 *   node import_products_rapidapi.js --max-queries=20         → import réel limité (contrôle du coût)
 *
 * Prérequis :
 *   - scripts/.env avec RAPIDAPI_KEY (+ RAPIDAPI_ADAPTER optionnel — voir .env.example)
 *   - scripts/serviceAccountKey.json (voir GUIDE_FIREBASE_UPLOAD.md)
 */

require('dotenv').config();
const admin = require('firebase-admin');
const fetch = require('node-fetch');

// node-fetch v2 ne suit pas HTTPS_PROXY tout seul. En environnement proxifié
// (egress via CONNECT), on lui passe explicitement un agent, sinon la requête
// part hors tunnel et le proxy répond 405 Method Not Allowed.
const PROXY_URL = process.env.HTTPS_PROXY || process.env.https_proxy || null;
let proxyAgent = null;
if (PROXY_URL) {
  const { HttpsProxyAgent } = require('https-proxy-agent');
  proxyAgent = new HttpsProxyAgent(PROXY_URL);
}

const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const RAPIDAPI_KEY = process.env.RAPIDAPI_KEY;

// Quelle API RapidAPI utiliser. Chaque adaptateur (voir API_ADAPTERS plus bas)
// sait construire l'URL, extraire la liste de produits et mapper les champs
// pour une API donnée. Changer d'API = changer cette seule variable dans .env
// (RAPIDAPI_ADAPTER), sans toucher au reste du script.
//   - "amazon"        → Real-Time Amazon Data (recommandé : stable, très large)
//   - "google"        → Real-Time Product Search (Google Shopping — désactivée
//                        chez l'éditeur en 2026, gardée ici au cas où elle
//                        revienne ou pour un clone au même format)
const ADAPTER_NAME = process.env.RAPIDAPI_ADAPTER || 'amazon';

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
// 3. ADAPTATEURS D'API — un par API RapidAPI supportée
// ============================================================================
//
// Chaque adaptateur définit :
//   host       : le X-RapidAPI-Host (doit correspondre à celui de ton abonnement)
//   buildUrl   : construit l'URL de recherche pour un mot-clé
//   extractItems : extrait le tableau de produits de la réponse JSON
//   fields     : listes de chemins candidats pour chaque champ produit
//                (le 1er trouvé gagne — voir extractField)
//
// Pour ajouter une nouvelle API : copie un bloc, ajuste host/buildUrl/fields
// d'après la sortie de `--inspect`, et mets RAPIDAPI_ADAPTER=<ton_nom> dans .env.

const API_ADAPTERS = {
  // ── Real-Time Amazon Data (recommandé) ─────────────────────────────────
  // https://rapidapi.com/letscrape-6bRBa3QguO5/api/real-time-amazon-data
  amazon: {
    host: 'real-time-amazon-data.p.rapidapi.com',
    buildUrl: (host, q) =>
      `https://${host}/search?query=${encodeURIComponent(q)}&country=FR&page=1`,
    extractItems: (json) => json?.data?.products || json?.data || [],
    fields: {
      name: ['product_title', 'title'],
      image: ['product_photo', 'product_main_image_url', 'thumbnail'],
      price: ['product_price', 'price'],
      brand: ['product_byline', 'brand'],
      url: ['product_url', 'url'],
      description: ['product_description', 'description'],
      id: ['asin', 'product_id'],
    },
  },

  // ── Real-Time Product Search (Google Shopping — format d'origine) ────────
  google: {
    host: 'real-time-product-search.p.rapidapi.com',
    buildUrl: (host, q) =>
      `https://${host}/search?q=${encodeURIComponent(q)}&country=fr&language=fr`,
    extractItems: (json) => json?.data?.products || json?.data || json?.products || [],
    fields: {
      name: ['product_title', 'title', 'name'],
      image: ['product_photos.0', 'product_photo', 'image', 'thumbnail'],
      price: ['offer.price', 'product_price', 'price', 'typical_price_range.0'],
      brand: ['product_attributes.Brand', 'brand', 'source'],
      url: ['product_page_url', 'offer.offer_page_url', 'url', 'link'],
      description: ['product_description', 'description'],
      id: ['product_id', 'id'],
    },
  },
};

const ADAPTER = API_ADAPTERS[ADAPTER_NAME];
if (!ADAPTER) {
  console.error(`❌ RAPIDAPI_ADAPTER inconnu: "${ADAPTER_NAME}". Options: ${Object.keys(API_ADAPTERS).join(', ')}`);
  process.exit(1);
}
// L'utilisateur peut forcer un host custom (clone d'API au même format).
const RAPIDAPI_HOST = process.env.RAPIDAPI_HOST || ADAPTER.host;

async function fetchProductsForQuery(query) {
  const url = ADAPTER.buildUrl(RAPIDAPI_HOST, query);
  const res = await fetch(url, {
    headers: {
      'X-RapidAPI-Key': RAPIDAPI_KEY,
      'X-RapidAPI-Host': RAPIDAPI_HOST,
    },
    agent: proxyAgent,
  });
  if (!res.ok) {
    throw new Error(`RapidAPI ${res.status} ${res.statusText} pour "${query}"`);
  }
  const json = await res.json();

  if (INSPECT) {
    console.log(JSON.stringify(json, null, 2).slice(0, 4000));
    return [];
  }

  const items = ADAPTER.extractItems(json);
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
  const f = ADAPTER.fields;
  const name = extractField(item, f.name);
  if (!name) return null;

  const imageRaw = extractField(item, f.image);
  const priceRaw = extractField(item, f.price);
  const priceNum = typeof priceRaw === 'number'
    ? priceRaw
    : parseFloat(String(priceRaw || '').replace(/[^0-9.,]/g, '').replace(',', '.')) || null;

  // Marque : hint de la requête en priorité (fiable, ex. requête "Nike"),
  // sinon champ de l'API, sinon "Autre".
  const brand = queryMeta.brand || extractField(item, f.brand) || 'Autre';
  const url = extractField(item, f.url);
  const description = extractField(item, f.description, '');

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
  console.log(`🔌 Adaptateur: ${ADAPTER_NAME} (host: ${RAPIDAPI_HOST})`);
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
