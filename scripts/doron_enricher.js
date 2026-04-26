/**
 * doron_enricher.js — Enrichissement batch Doron v2
 * ====================================================
 * Sources (dans l'ordre de priorité) :
 *   1. Claude API (web_search) → image officielle HD + validation qualité
 *   2. Liens existants déjà dans Firebase (url, product_url)
 *   3. Google Custom Search API → liens d'achat supplémentaires
 *
 * Structure Firebase après enrichissement :
 *   {
 *     image: "https://image-HD.jpg",
 *     imageUrl: "https://...",
 *     buyLinks: [
 *       { site: "Amazon.fr",    price: 49, url: "https://...", priority: 1, affiliated: false },
 *       { site: "Fnac",         price: 52, url: "https://...", priority: 2, affiliated: false },
 *       { site: "Site officiel",price: 59, url: "https://...", priority: 3, affiliated: false },
 *     ],
 *     priceMin: 49,
 *     priceMax: 59,
 *     enriched: true,
 *     enrichedAt: "...",
 *   }
 *
 * Usage :
 *   node scripts/doron_enricher.js                → enrichit tout
 *   node scripts/doron_enricher.js --dry-run       → test sans écrire
 *   node scripts/doron_enricher.js --limit=20      → 20 produits max
 *   node scripts/doron_enricher.js --force         → ré-enrichit TOUT
 *   node scripts/doron_enricher.js --images-only   → seulement les images
 *   node scripts/doron_enricher.js --links-only    → seulement les liens
 *
 * Config .env requise :
 *   ANTHROPIC_API_KEY=sk-ant-...
 *   GOOGLE_CSE_KEY=AIza...        (optionnel — 100 requêtes/jour gratuites)
 *   GOOGLE_CSE_ID=...             (optionnel — ton moteur de recherche custom)
 */

const admin    = require('firebase-admin');
const Anthropic = require('@anthropic-ai/sdk');
const https    = require('https');
require('dotenv').config();

// ─── Affiliate Tags ──────────────────────────────────────────────────────────
const AMAZON_TAG = process.env.AMAZON_ASSOCIATE_TAG || 'doron072004-21';

// ─── Flags CLI ────────────────────────────────────────────────────────────────
const DRY_RUN     = process.argv.includes('--dry-run');
const FORCE       = process.argv.includes('--force');
const IMAGES_ONLY = process.argv.includes('--images-only');
const LINKS_ONLY  = process.argv.includes('--links-only');
const LIMIT_ARG   = process.argv.find(a => a.startsWith('--limit='));
const LIMIT       = LIMIT_ARG ? parseInt(LIMIT_ARG.split('=')[1]) : Infinity;

// Délai entre produits (ms) — évite les rate limits
const PAUSE_MS = 500;
// Nombre de produits traités en parallèle
const CONCURRENCY_ARG = process.argv.find(a => a.startsWith('--concurrency='));
const CONCURRENCY = CONCURRENCY_ARG ? parseInt(CONCURRENCY_ARG.split('=')[1]) : 1;

// Sites de confiance pour les liens d'achat (utilisés pour valider Google CSE)
const TRUSTED_SHOPS = [
  'amazon.fr', 'amazon.com', 'fnac.com', 'darty.com', 'cdiscount.com',
  'zalando.fr', 'laredoute.fr', 'galerieslafayette.com', 'leroymerlin.fr',
  'decathlon.fr', 'intersport.fr', 'sephora.fr', 'nocibe.fr', 'marionnaud.fr',
  'smallable.com', 'maisons-du-monde.com', 'alinea.com', 'leroy-merlin.fr',
  'boulanger.com', 'ldlc.com', 'cultura.com', 'librairie-gallimard.fr',
  'monoprix.fr', 'printemps.com', 'leboncoin.fr', 'vinted.fr',
];

// Noms des sites pour l'affichage (clé = domaine, valeur = nom propre)
const SITE_NAMES = {
  'amazon.fr': 'Amazon.fr', 'amazon.com': 'Amazon',
  'fnac.com': 'Fnac', 'darty.com': 'Darty', 'cdiscount.com': 'Cdiscount',
  'zalando.fr': 'Zalando', 'laredoute.fr': 'La Redoute',
  'galerieslafayette.com': 'Galeries Lafayette', 'smallable.com': 'Smallable',
  'sephora.fr': 'Sephora', 'nocibe.fr': 'Nocibé', 'marionnaud.fr': 'Marionnaud',
  'decathlon.fr': 'Decathlon', 'intersport.fr': 'Intersport',
  'boulanger.com': 'Boulanger', 'ldlc.com': 'LDLC', 'cultura.com': 'Cultura',
  'monoprix.fr': 'Monoprix', 'printemps.com': 'Printemps',
};

// ─── Init Firebase & Anthropic ────────────────────────────────────────────────
const sa = require('./serviceAccountKey.json');
admin.initializeApp({ credential: admin.credential.cert(sa) });
const db = admin.firestore();

const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

// ─── Helpers ──────────────────────────────────────────────────────────────────
const sleep = ms => new Promise(r => setTimeout(r, ms));

function applyAmazonTag(url) {
  if (!url) return url;
  try {
    const u = new URL(url);
    if (!u.hostname.includes('amazon.')) return url;
    u.searchParams.delete('tag');
    u.searchParams.set('tag', AMAZON_TAG);
    return u.toString();
  } catch { return url; }
}

function extractDomain(url) {
  try { return new URL(url).hostname.replace(/^www\./, ''); }
  catch { return ''; }
}

function getSiteName(url) {
  const domain = extractDomain(url);
  return SITE_NAMES[domain] || domain || 'Boutique';
}

function extractPrice(text) {
  if (!text) return null;
  const match = String(text).match(/(\d+(?:[.,]\d{1,2})?)/);
  if (!match) return null;
  return parseFloat(match[1].replace(',', '.'));
}

function isTrustedShop(url) {
  const domain = extractDomain(url);
  return TRUSTED_SHOPS.some(s => domain === s || domain.endsWith('.' + s));
}

function extractJsonFromText(text) {
  if (!text) return null;
  // Essayer plusieurs patterns
  const patterns = [
    /```json\s*([\s\S]*?)```/,
    /```\s*([\s\S]*?)```/,
    /(\{[\s\S]*?\})\s*$/,
    /(\{[\s\S]*\})/,
  ];
  for (const p of patterns) {
    const m = text.match(p);
    if (m) {
      try { return JSON.parse(m[1].trim()); }
      catch {}
    }
  }
  return null;
}

// ─── Google CSE : cherche des liens d'achat ───────────────────────────────────
async function searchGoogleCSE(productName, brand) {
  const key = process.env.GOOGLE_CSE_KEY;
  const cx  = process.env.GOOGLE_CSE_ID;
  if (!key || !cx) return [];

  const query = encodeURIComponent(`${brand ? brand + ' ' : ''}${productName} acheter prix`);
  const url   = `https://www.googleapis.com/customsearch/v1?key=${key}&cx=${cx}&q=${query}&num=10&gl=fr&hl=fr`;

  return new Promise(resolve => {
    https.get(url, res => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          if (json.error) { console.log(`  ⚠️  Google CSE erreur: ${json.error.message}`); resolve([]); return; }

          const links = (json.items || [])
            .filter(item => isTrustedShop(item.link))
            .map(item => ({
              site:      getSiteName(item.link),
              url:       item.link,
              price:     extractPrice(item.snippet || item.title),
              affiliated: false,
              priority:  2,
              source:    'google_cse',
            }))
            .filter((l, i, arr) => arr.findIndex(x => extractDomain(x.url) === extractDomain(l.url)) === i) // déduplique par domaine
            .slice(0, 6);

          resolve(links);
        } catch { resolve([]); }
      });
    }).on('error', () => resolve([]));
  });
}

// ─── Claude : enrichit un produit ─────────────────────────────────────────────
async function claudeEnrich(productName, brand, existingImage, existingUrl) {
  const label = brand ? `${brand} — ${productName}` : productName;

  const prompt = `Produit e-commerce à enrichir: "${label}"

Fais 2-3 recherches web maintenant:
1. "${label} amazon.fr" → ASIN + prix + image officielle
2. "${label} fnac darty prix" → prix comparatif
3. "${label} image officielle site marque" → image HD

Retourne UNIQUEMENT ce JSON (sans markdown):
{"imageUrl":"URL_IMAGE_HD_DIRECTE","imageSource":"amazon|brand|other","imageKept":false,"buyLinks":[{"site":"Amazon.fr","url":"https://amazon.fr/dp/ASIN","price":49.99},{"site":"Fnac","url":"https://fnac.com/...","price":52}],"qualityScore":8,"isLowQuality":false,"notes":"description 1 ligne"}

RÈGLES: URLs réelles uniquement | imageUrl = URL directe image (.jpg/.png/.webp) | Si rien: {"imageUrl":null,"buyLinks":[],"qualityScore":5,"isLowQuality":false,"notes":""}`;

  try {
    const response = await anthropic.messages.create({
      model:      'claude-opus-4-5',  // seul modèle accessible sur cette clé, avec web_search
      max_tokens: 800,
      tools: [{ type: 'web_search_20250305', name: 'web_search', max_uses: 3 }],
      tool_choice: { type: 'auto' },
      messages: [{ role: 'user', content: prompt }],
    });

    let resultText = '';
    for (const block of response.content) {
      if (block.type === 'text') resultText += block.text;
    }

    return extractJsonFromText(resultText);

  } catch (e) {
    if (e.status === 529 || e.status === 429) {
      console.log('  ⏳ Rate limit Claude — attente 30s...');
      await sleep(30000);
      return claudeEnrich(productName, brand, existingImage, existingUrl);
    }
    console.error(`  ❌ Claude erreur: ${e.message}`);
    return null;
  }
}

// ─── Traitement d'un produit ───────────────────────────────────────────────────
async function processProduct(doc) {
  const data = doc.data();
  const name  = data.name || data.product_title || data.title || '';
  const brand = data.brand || '';

  // Images existantes
  const existingImage = data.image || data.imageUrl || data.productPhoto || '';
  // Lien existant
  const existingUrl   = data.url || data.product_url || data.link || '';

  const label = brand ? `${brand} — ${name}` : name;

  if (!name) { console.log(`  ⏭  Pas de nom — ignoré`); return null; }

  const update = {};
  let claudeResult = null;

  // ── Étape 1 : Claude (image + liens Claude) ────────────────────────────────
  if (!LINKS_ONLY) {
    console.log(`  🤖 Claude web_search...`);
    claudeResult = await claudeEnrich(name, brand, existingImage, existingUrl);

    if (claudeResult) {
      if (claudeResult.imageUrl && !claudeResult.imageKept) {
        update.image    = claudeResult.imageUrl;
        update.imageUrl = claudeResult.imageUrl;
        update.imageSource = claudeResult.imageSource || 'claude';
        update.imageFixed = true;
        console.log(`  🖼  Image: ${claudeResult.imageUrl.substring(0, 70)}...`);
      } else if (!existingImage) {
        console.log(`  ⚠️  Pas d'image trouvée`);
      }

      if (claudeResult.qualityScore !== undefined) {
        update.qualityScore  = claudeResult.qualityScore;
        update.isLowQuality  = claudeResult.isLowQuality || false;
      }

      if (claudeResult.notes) update.productNotes = claudeResult.notes;
    }
  }

  // ── Étape 2 : Construire les buyLinks ─────────────────────────────────────
  if (!IMAGES_ONLY) {
    const allLinks = [];

    // 2a. Liens Claude (priorité 1)
    if (claudeResult?.buyLinks?.length > 0) {
      claudeResult.buyLinks.forEach(l => {
        const finalUrl = applyAmazonTag(l.url);
        const isAffiliated = finalUrl.includes('tag=' + AMAZON_TAG);
        const linkObj = {
          site:       l.site || getSiteName(l.url),
          url:        finalUrl,
          price:      l.price || null,
          affiliated: isAffiliated,
          priority:   1,
          source:     'claude',
        };
        if (isAffiliated) linkObj.affiliateTag = AMAZON_TAG;
        allLinks.push(linkObj);
      });
      console.log(`  🛒 Claude links: ${claudeResult.buyLinks.length}`);
    }

    // 2b. Lien existant dans Firebase (priorité 3 — s'il n'est pas déjà dedans)
    if (existingUrl) {
      const alreadyIn = allLinks.some(l => l.url === existingUrl);
      if (!alreadyIn) {
        allLinks.push({
          site:       getSiteName(existingUrl) || brand || 'Boutique',
          url:        existingUrl,
          price:      extractPrice(data.price) || null,
          affiliated: false,
          priority:   3,
          source:     'existing',
        });
        console.log(`  🔗 Lien existant ajouté`);
      }
    }

    // 2c. Google CSE (priorité 2)
    console.log(`  🔍 Google CSE...`);
    const cseLinks = await searchGoogleCSE(name, brand);
    cseLinks.forEach(l => {
      const alreadyIn = allLinks.some(x => extractDomain(x.url) === extractDomain(l.url));
      if (!alreadyIn) allLinks.push(l);
    });
    if (cseLinks.length > 0) console.log(`  📡 Google CSE: ${cseLinks.length} liens`);
    else console.log(`  📡 Google CSE: aucun résultat (vérifier GOOGLE_CSE_KEY)`);

    // Trier : d'abord par priorité, puis par prix croissant
    allLinks.sort((a, b) => {
      if (a.priority !== b.priority) return a.priority - b.priority;
      if (a.price && b.price) return a.price - b.price;
      return 0;
    });

    if (allLinks.length > 0) {
      update.buyLinks = allLinks.slice(0, 8); // max 8 liens par produit

      const prices = allLinks.map(l => l.price).filter(Boolean);
      if (prices.length) {
        update.priceMin = Math.min(...prices);
        update.priceMax = Math.max(...prices);
        // Mettre à jour le prix principal si manquant
        if (!data.price && update.priceMin) update.price = update.priceMin;
      }

      console.log(`  ✅ ${allLinks.length} liens au total | Prix: ${update.priceMin || '?'}€ → ${update.priceMax || '?'}€`);
    } else {
      console.log(`  ⚠️  Aucun lien d'achat trouvé`);
    }
  }

  // ── Étape 3 : Metadata enrichissement ─────────────────────────────────────
  update.enriched        = true;
  update.enrichedAt      = new Date().toISOString();
  update.enrichedVersion = '2.0';

  return update;
}

// ─── Main ─────────────────────────────────────────────────────────────────────
async function main() {
  console.log('\n╔════════════════════════════════════════════════════════╗');
  console.log('║   🚀  Doron Enricher v2 — Claude + Google CSE         ║');
  console.log(`║   📦  Sources: Claude web_search + DB existant + CSE  ║`);
  if (DRY_RUN)     console.log('║   ⚠️   MODE DRY-RUN : aucune écriture Firebase        ║');
  if (FORCE)       console.log('║   🔁   MODE FORCE : tout ré-enrichir                  ║');
  if (IMAGES_ONLY) console.log('║   🖼️   MODE IMAGES ONLY                               ║');
  if (LINKS_ONLY)  console.log('║   🛒   MODE LINKS ONLY                                ║');
  console.log('╚════════════════════════════════════════════════════════╝\n');

  if (!process.env.ANTHROPIC_API_KEY) {
    console.error('❌ ANTHROPIC_API_KEY manquante dans .env');
    process.exit(1);
  }

  if (!process.env.GOOGLE_CSE_KEY || !process.env.GOOGLE_CSE_ID) {
    console.log('⚠️  Google CSE non configuré (GOOGLE_CSE_KEY + GOOGLE_CSE_ID dans .env)');
    console.log('   → Les liens Google ne seront pas récupérés\n');
  }

  // Requête Firestore
  let query = db.collection('gifts');
  if (!FORCE) {
    // Seulement les produits pas encore enrichis (ou tentés)
    // Note: Firestore ne supporte pas != sur un champ inexistant → double requête
    const snap1 = await db.collection('gifts').where('enriched', '==', false).get();
    const snap2 = await db.collection('gifts').where('enriched', '==', null).get();

    // On charge tout et on filtre côté client
    const allSnap = await db.collection('gifts').get();
    const toProcess = allSnap.docs.filter(d => !d.data().enriched);

    await runBatch(toProcess);
    return;
  }

  const snap = await query.get();
  await runBatch(snap.docs);
}

async function runBatch(docs) {
  const limited = docs.slice(0, LIMIT === Infinity ? docs.length : LIMIT);

  console.log(`📦 ${limited.length} produits à traiter (${CONCURRENCY} en parallèle)\n`);
  if (DRY_RUN) console.log('🔍 DRY RUN — rien ne sera écrit dans Firebase\n');

  let success = 0, errors = 0, skipped = 0;
  const startTime = Date.now();
  let processed = 0;

  // Traitement par chunks de CONCURRENCY produits en parallèle
  for (let i = 0; i < limited.length; i += CONCURRENCY) {
    const chunk = limited.slice(i, i + CONCURRENCY);
    const elapsed = Math.round((Date.now() - startTime) / 1000);
    const eta = processed > 0 ? Math.round((elapsed / processed) * (limited.length - processed)) : '?';

    console.log(`\n═══════════════════════════════════════════════`);
    console.log(`[${i + 1}-${Math.min(i + CONCURRENCY, limited.length)}/${limited.length}] ⏱ ${elapsed}s | ETA ~${eta}s`);

    const results = await Promise.all(chunk.map(async (doc) => {
      const data  = doc.data();
      const name  = data.name || data.product_title || '(sans nom)';
      const brand = data.brand || '';
      console.log(`  🔄 "${brand ? brand + ' — ' : ''}${name}"`);
      try {
        const update = await processProduct(doc);
        return { doc, update, ok: true };
      } catch (e) {
        console.error(`  ❌ Erreur sur "${name}": ${e.message}`);
        return { doc, update: null, ok: false };
      }
    }));

    // Écrire les résultats dans Firebase
    for (const { doc, update, ok } of results) {
      processed++;
      if (!ok || !update) {
        errors++;
      } else if (!DRY_RUN) {
        await doc.ref.update(update);
        console.log(`  💾 "${doc.data().name || '?'}" → mis à jour (${Object.keys(update).length} champs)`);
        success++;
      } else {
        console.log(`  [DRY-RUN]:`, JSON.stringify(update, null, 2).substring(0, 200));
        success++;
      }
    }

    // Pause entre les chunks
    if (i + CONCURRENCY < limited.length) {
      process.stdout.write(`  ⏱  Pause ${PAUSE_MS / 1000}s...`);
      await sleep(PAUSE_MS);
      process.stdout.write(' OK\n');
    }
  }

  const total = Math.round((Date.now() - startTime) / 1000);
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log(`║  ✅ Enrichis  : ${String(success).padEnd(4)} produits              ║`);
  console.log(`║  ⏭  Ignorés  : ${String(skipped).padEnd(4)} produits              ║`);
  console.log(`║  ❌ Erreurs   : ${String(errors).padEnd(4)} produits              ║`);
  console.log(`║  ⏱  Durée    : ${String(total).padEnd(4)}s                      ║`);
  console.log('╚══════════════════════════════════════════════╝\n');

  console.log('💡 Prochaines étapes pour la monétisation :');
  console.log('   • Amazon Associates → remplace les liens Amazon par des liens affiliés');
  console.log('   • Awin → ajoute les liens Fnac/Zalando/etc. affiliés');
  console.log('   • Dans l\'app Flutter → afficher le mini comparateur buyLinks[]');
}

main().catch(e => {
  console.error('\n❌ ERREUR FATALE:', e.message);
  process.exit(1);
});
