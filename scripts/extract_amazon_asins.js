/**
 * extract_amazon_asins.js
 * Pour les 147 produits qui ont une URL Amazon dans le champ url/product_url
 * mais PAS de buyLinks[] :
 *   1. Extrait le ASIN depuis l'URL
 *   2. Crée un buyLinks[] avec le lien affilié doron072004-21
 *   3. Met à jour Firebase
 *
 * Usage : node scripts/extract_amazon_asins.js --dry-run
 *         node scripts/extract_amazon_asins.js
 */

const admin = require('firebase-admin');
require('dotenv').config();
const sa = require('./serviceAccountKey.json');
admin.initializeApp({ credential: admin.credential.cert(sa) });
const db = admin.firestore();

const ASSOCIATE_TAG = 'doron072004-21';
const DRY_RUN = process.argv.includes('--dry-run');

// Extraire l'ASIN depuis une URL Amazon
function extractAsin(url) {
  if (!url) return null;
  // Patterns : /dp/ASIN, /gp/product/ASIN, /exec/obidos/ASIN/ASIN
  const patterns = [
    /\/dp\/([A-Z0-9]{10})/i,
    /\/gp\/product\/([A-Z0-9]{10})/i,
    /\/product\/([A-Z0-9]{10})/i,
    /\/([A-Z0-9]{10})(?:\/|\?|$)/,
  ];
  for (const p of patterns) {
    const m = url.match(p);
    if (m && m[1] && m[1].length === 10) return m[1].toUpperCase();
  }
  return null;
}

function buildAffiliateUrl(asin) {
  return `https://www.amazon.fr/dp/${asin}?tag=${ASSOCIATE_TAG}`;
}

function extractPrice(val) {
  if (!val) return null;
  const n = parseFloat(String(val).replace(',', '.').replace(/[^0-9.]/g, ''));
  return isNaN(n) ? null : n;
}

async function main() {
  console.log('\n╔═════════════════════════════════════════════════════╗');
  console.log('║   🛒  Amazon ASIN Extractor — doron072004-21        ║');
  if (DRY_RUN) console.log('║   ⚠️   DRY-RUN : aucune écriture Firebase          ║');
  console.log('╚═════════════════════════════════════════════════════╝\n');

  const snap = await db.collection('gifts').get();

  let processed = 0, skipped = 0, noAsin = 0;
  const toUpdate = [];

  // 1ère passe : identifier les produits à traiter
  for (const doc of snap.docs) {
    const d = doc.data();
    const bl = d.buyLinks || [];

    // Cibler les produits avec URL Amazon mais PAS encore de multi-liens
    const url = (d.url || d.product_url || '').toString();
    const hasAmazon = url.includes('amazon.');
    const alreadyEnriched = bl.length > 1;

    if (!hasAmazon || alreadyEnriched) { skipped++; continue; }

    const asin = extractAsin(url);

    if (!asin) {
      console.log(`  ⚠️  Pas d'ASIN dans: ${url.substring(0, 80)}`);
      noAsin++;
      continue;
    }

    const affiliateUrl = buildAffiliateUrl(asin);
    const price = extractPrice(d.price || d.prix || '');

    // Récupérer les buyLinks existants (s'il y en a 1)
    const existingLinks = bl.map(l => ({
      ...l,
      affiliated: (l.url || '').includes('amazon.') ? true : l.affiliated,
    }));

    // Ajouter le lien Amazon affilié si pas déjà présent
    const amazonAlreadyIn = existingLinks.some(l => (l.url || '').includes('amazon.'));

    const newBuyLinks = [
      // Amazon affilié en priorité 1
      ...(!amazonAlreadyIn ? [{
        site: 'Amazon.fr',
        siteShort: 'amazon',
        url: affiliateUrl,
        price: price,
        affiliated: true,
        affiliateTag: ASSOCIATE_TAG,
        priority: 1,
        source: 'asin_extract',
      }] : []),
      // Liens existants (mis à jour avec tag si Amazon)
      ...existingLinks.map(l => ({
        ...l,
        url: (l.url || '').includes('amazon.')
            ? (l.url.includes('tag=') ? l.url : l.url + (l.url.includes('?') ? '&' : '?') + `tag=${ASSOCIATE_TAG}`)
            : l.url,
      })),
    ];

    const name = d.name || d.product_title || '(sans nom)';
    const brand = d.brand || '';
    console.log(`  ✅ ${brand ? brand + ' — ' : ''}${name.substring(0, 50)}`);
    console.log(`     ASIN: ${asin} → ${affiliateUrl}`);

    toUpdate.push({
      ref: doc.ref,
      name,
      data: {
        buyLinks: newBuyLinks,
        priceMin: price || null,
        priceMax: price || null,
        // Mettre à jour l'URL principale avec le tag affilié aussi
        url: affiliateUrl,
      },
    });
  }

  console.log(`\n📊 ${toUpdate.length} produits à mettre à jour, ${noAsin} sans ASIN, ${skipped} ignorés\n`);

  if (DRY_RUN) {
    console.log('[DRY-RUN] Lance sans --dry-run pour appliquer.\n');
    return;
  }

  // 2ème passe : écrire en batches
  const BATCH_SIZE = 400;
  for (let i = 0; i < toUpdate.length; i += BATCH_SIZE) {
    const batch = db.batch();
    const chunk = toUpdate.slice(i, i + BATCH_SIZE);
    for (const { ref, data } of chunk) {
      // Nettoyer les valeurs null pour Firestore
      const clean = {};
      for (const [k, v] of Object.entries(data)) {
        if (v !== null && v !== undefined) clean[k] = v;
      }
      batch.update(ref, clean);
    }
    await batch.commit();
    console.log(`  💾 Batch ${Math.floor(i / BATCH_SIZE) + 1} écrit (${chunk.length} produits)`);
  }

  processed = toUpdate.length;

  console.log('\n╔═════════════════════════════════════════════════════╗');
  console.log(`║  ✅ Liens affiliés créés  : ${String(processed).padEnd(24)}║`);
  console.log(`║  ⚠️  Sans ASIN extractible: ${String(noAsin).padEnd(24)}║`);
  console.log(`║  ⏭  Déjà enrichis/ignorés: ${String(skipped).padEnd(24)}║`);
  console.log('╚═════════════════════════════════════════════════════╝\n');
  console.log(`💰 ${processed} produits Amazon ont maintenant un lien affilié doron072004-21\n`);
  console.log('Prochaine étape : recharger les crédits Anthropic → node scripts/doron_enricher.js');
  console.log('  → Claude trouvera les images officielles + autres liens (Fnac, Darty, etc.)\n');
}

main().catch(e => { console.error('ERREUR:', e.message); process.exit(1); });
