#!/usr/bin/env node
/**
 * Backfill du champ `searchTokens` sur les produits déjà présents dans
 * Firestore (collections `gifts` et `products`), pour que la recherche
 * plein-texte de la page d'accueil (ProductSearchService, côté Flutter)
 * fonctionne immédiatement sur la base existante — pas seulement sur les
 * futurs produits importés via le pipeline RapidAPI.
 *
 * Logique de tokenisation IDENTIQUE à lib/services/search_tokenizer.dart
 * (accents retirés, mots >= 2 caractères, tous les préfixes de chaque mot).
 *
 * USAGE :
 *   node backfill_search_tokens.js            → écrit pour de vrai
 *   node backfill_search_tokens.js --dry-run  → affiche seulement les stats
 *
 * Prérequis : serviceAccountKey.json dans ce dossier (voir GUIDE_FIREBASE_UPLOAD.md)
 */

const admin = require('firebase-admin');

const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const DRY_RUN = process.argv.includes('--dry-run');
const MIN_WORD_LENGTH = 2;
const MAX_WORD_LENGTH_INDEXED = 24;
const MAX_TOKENS_PER_PRODUCT = 200;

const ACCENT_MAP = {
  'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a',
  'ç': 'c',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'î': 'i', 'ï': 'i', 'í': 'i', 'ì': 'i',
  'ô': 'o', 'ö': 'o', 'ó': 'o', 'ò': 'o', 'õ': 'o',
  'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
  'ÿ': 'y', 'ñ': 'n',
  'œ': 'oe', 'æ': 'ae',
};

function normalize(input) {
  return String(input)
    .toLowerCase()
    .split('')
    .map((c) => ACCENT_MAP[c] || c)
    .join('');
}

function wordsFrom(text) {
  const normalized = normalize(text);
  return normalized
    .split(/[^a-z0-9]+/)
    .filter((w) => w.length >= MIN_WORD_LENGTH && w.length <= MAX_WORD_LENGTH_INDEXED);
}

// Préfixes retirés pour que les tags officiels ("cat_tech", "type_high_tech")
// contribuent des mots lisibles ("tech", "high") à la recherche plutôt que
// le tag brut.
const TAG_PREFIXES = ['cat_', 'type_', 'style_', 'perso_', 'passion_', 'gender_', 'age_', 'budget_', 'occasion_', 'saison_', 'popularite_'];

function readableTagWords(tags) {
  if (!Array.isArray(tags)) return [];
  return tags.map((t) => {
    let s = String(t);
    for (const prefix of TAG_PREFIXES) {
      if (s.startsWith(prefix)) { s = s.slice(prefix.length); break; }
    }
    return s.replace(/_/g, ' ');
  });
}

function tokensForIndexing(texts) {
  const tokens = new Set();
  for (const text of texts) {
    if (!text) continue;
    for (const word of wordsFrom(text)) {
      for (let end = MIN_WORD_LENGTH; end <= word.length; end++) {
        tokens.add(word.substring(0, end));
        if (tokens.size >= MAX_TOKENS_PER_PRODUCT) return tokens;
      }
    }
  }
  return tokens;
}

function buildSearchTokens(product) {
  const texts = [
    product.name,
    product.brand,
    ...(Array.isArray(product.categories) ? product.categories : []),
    ...readableTagWords(product.tags),
  ];
  return Array.from(tokensForIndexing(texts));
}

async function backfillCollection(collectionName) {
  const snap = await db.collection(collectionName).get();
  console.log(`\n📦 ${collectionName}: ${snap.size} documents`);

  let batch = db.batch();
  let batchCount = 0;
  let updated = 0;
  let skippedAlreadyTagged = 0;

  for (const doc of snap.docs) {
    const product = doc.data();

    // Ne pas re-générer si déjà présent (idempotent — permet de relancer le
    // script après chaque import sans tout recalculer).
    if (Array.isArray(product.searchTokens) && product.searchTokens.length > 0) {
      skippedAlreadyTagged++;
      continue;
    }

    const searchTokens = buildSearchTokens(product);
    if (searchTokens.length === 0) continue;

    updated++;
    if (!DRY_RUN) {
      batch.update(doc.ref, { searchTokens });
      batchCount++;
      if (batchCount >= 450) {
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
        console.log(`   … ${updated} mis à jour`);
      }
    }
  }

  if (!DRY_RUN && batchCount > 0) {
    await batch.commit();
  }

  console.log(`✅ ${collectionName}: ${updated} produits ${DRY_RUN ? 'à mettre à jour (dry-run)' : 'mis à jour'}, ${skippedAlreadyTagged} déjà tagués (ignorés)`);
}

(async () => {
  console.log(DRY_RUN ? '🔍 DRY RUN — aucune écriture' : '✍️  Écriture réelle sur Firestore');
  await backfillCollection('gifts');
  await backfillCollection('products');
  console.log('\n🏁 Terminé.');
  process.exit(0);
})().catch((e) => {
  console.error('❌ Erreur:', e);
  process.exit(1);
});
