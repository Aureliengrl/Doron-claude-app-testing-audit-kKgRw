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

// ── Nettoyage des noms (les APIs renvoient du HTML-encodé + titres à rallonge)
function decodeEntities(s) {
  return String(s || '')
    .replace(/&#x([0-9a-fA-F]+);/g, (_, h) => { try { return String.fromCodePoint(parseInt(h, 16)); } catch { return _; } })
    .replace(/&#(\d+);/g, (_, d) => { try { return String.fromCodePoint(parseInt(d, 10)); } catch { return _; } })
    .replace(/&quot;/g, '"').replace(/&apos;/g, "'")
    .replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&nbsp;/g, ' ')
    .replace(/&eacute;/g, 'é').replace(/&egrave;/g, 'è').replace(/&agrave;/g, 'à')
    .replace(/&ecirc;/g, 'ê').replace(/&ccedil;/g, 'ç').replace(/&ugrave;/g, 'ù')
    .replace(/&acirc;/g, 'â').replace(/&icirc;/g, 'î').replace(/&ocirc;/g, 'ô')
    .replace(/&euml;/g, 'ë').replace(/&iuml;/g, 'ï').replace(/&hellip;/g, '…')
    .replace(/&amp;/g, '&'); // en dernier
}
function shortName(name) {
  let n = decodeEntities(name).trim();
  n = n.split(/,| [–—-] |\s\|\s/)[0].replace(/\s+/g, ' ').trim();
  if (n.length > 50) n = n.slice(0, 50).replace(/\s+\S*$/, '').trim() + '…';
  return n || decodeEntities(name);
}

// ── Catégorie "app" (doit matcher les onglets de la home : trending/tech/
//    fashion/home/beauty/food). On stocke l'id ET le nom FR en alias car la
//    home requête par id, et son fallback par nom FR.
const BRAND_CAT = {
  apple: 'tech', samsung: 'tech', sony: 'tech', xiaomi: 'tech', jbl: 'tech', fnac: 'tech',
  playstation: 'tech', xbox: 'tech', nintendo: 'tech', dyson: 'tech', philips: 'tech',
  zara: 'fashion', 'h-m': 'fashion', nike: 'fashion', adidas: 'fashion', uniqlo: 'fashion',
  'levi-s': 'fashion', mango: 'fashion', bershka: 'fashion', 'pull-bear': 'fashion',
  'ray-ban': 'fashion', pandora: 'fashion', swarovski: 'fashion', 'petit-bateau': 'fashion',
  kiabi: 'fashion', celio: 'fashion',
  sephora: 'beauty', 'yves-rocher': 'beauty', clarins: 'beauty', 'l-oreal': 'beauty',
  ikea: 'home', 'maisons-du-monde': 'home', 'le-creuset': 'home', nespresso: 'home',
  lego: 'trending', decathlon: 'trending',
};
const CAT_FROM_TAG = {
  cat_tech: 'tech', cat_mode: 'fashion', cat_maison: 'home', cat_beaute: 'beauty', cat_food: 'food', cat_tendances: 'trending',
  passion_tech: 'tech', passion_musique: 'tech', passion_jeuxvideo: 'tech', passion_mode: 'fashion',
  passion_beaute: 'beauty', passion_cuisine: 'food', passion_sport: 'trending', passion_lecture: 'trending', passion_voyages: 'trending',
  type_high_tech: 'tech', type_musique_audio: 'tech', type_jeux_jouets: 'trending', type_livres_bd: 'trending',
  type_maison_deco: 'home', type_beaute_soins: 'beauty', type_gastronomie: 'food', type_mode_accessoires: 'fashion',
  type_bijoux: 'fashion', type_sport_outdoor: 'trending', type_voyage_aventure: 'trending',
};
const CAT_ALIASES = {
  tech: ['tech'], fashion: ['fashion', 'mode'], home: ['home', 'maison'],
  beauty: ['beauty', 'beaute', 'beauté'], food: ['food'], trending: ['trending', 'tendances'],
};
function appCategoryFor(brandId, tags) {
  if (BRAND_CAT[brandId]) return BRAND_CAT[brandId];
  for (const t of tags) if (CAT_FROM_TAG[t]) return CAT_FROM_TAG[t];
  return 'trending';
}
// catégorie app → tag cat_* utilisé par le feed home (getPersonalizedProducts
// filtre sur `tags` arrayContains cat_*, PAS sur `categories`).
const CAT_TAG = { tech: 'cat_tech', fashion: 'cat_mode', home: 'cat_maison', beauty: 'cat_beaute', food: 'cat_food', trending: 'cat_tendances' };
const KW_STOP = new Set(['pour', 'avec', 'des', 'les', 'une', 'set', 'the', 'and', 'sur', 'par', 'plus', 'sans', 'ml', 'cm', 'mm', 'de', 'la', 'le', 'du', 'en', 'au', 'aux', 'pcs', 'lot']);
// Mots-clés depuis le titre complet → alimentent les sous-filtres de la home
// (Sneakers, Audio, Parfums, Montres, Vin, Café…).
function keywordsFrom(fullName, brand) {
  const words = String(fullName || '').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z0-9 ]/g, ' ').split(/\s+/).filter((w) => w.length > 2 && !KW_STOP.has(w));
  return [...new Set([String(brand || '').toLowerCase(), ...words])].filter(Boolean).slice(0, 20);
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
  const description = decodeEntities(extractField(item, f.description, ''));

  const brandId = slugify(brand);
  const cleanName = decodeEntities(name);
  const tags = buildProductTags({ name: cleanName, description, price: priceNum, queryMeta });
  const category = appCategoryFor(brandId, tags);
  const catTag = CAT_TAG[category];
  if (catTag && !tags.includes(catTag)) tags.push(catTag); // pour le feed home

  return {
    name: shortName(name),        // nom court et décodé pour l'affichage
    fullName: cleanName,          // titre complet décodé (détail produit)
    brand,
    brandId,
    price: priceNum,
    image: imageRaw,
    imageUrl: imageRaw,
    url,
    source: 'RapidAPI',
    description,
    categories: CAT_ALIASES[category], // ids + noms FR → matche la home
    tags,
    keywords: keywordsFrom(cleanName, brand), // sous-filtres de la home
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

        product.searchTokens = buildSearchTokens([product.fullName || product.name, product.brand, ...product.categories]);
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
