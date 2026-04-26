/**
 * apply_affiliate_tag.js
 * Ajoute le tag affilié Amazon à tous les liens amazon.fr déjà en base
 * Tag: doron072004-21
 *
 * Usage: node scripts/apply_affiliate_tag.js --dry-run
 *        node scripts/apply_affiliate_tag.js
 */
const admin = require('firebase-admin');
require('dotenv').config();
const sa = require('./serviceAccountKey.json');
admin.initializeApp({ credential: admin.credential.cert(sa) });
const db = admin.firestore();

const ASSOCIATE_TAG = 'doron072004-21';
const DRY_RUN = process.argv.includes('--dry-run');

function addAffiliateTag(url) {
  if (!url) return url;
  try {
    const u = new URL(url);
    // Uniquement les domaines Amazon
    if (!u.hostname.includes('amazon.')) return url;
    // Supprimer un ancien tag s'il existe déjà
    u.searchParams.delete('tag');
    u.searchParams.set('tag', ASSOCIATE_TAG);
    return u.toString();
  } catch {
    return url;
  }
}

function isAmazonUrl(url) {
  try { return new URL(url).hostname.includes('amazon.'); }
  catch { return false; }
}

async function main() {
  console.log('\n╔══════════════════════════════════════════════════════╗');
  console.log('║   🏷️  Apply Amazon Affiliate Tag — doron072004-21    ║');
  if (DRY_RUN) console.log('║   ⚠️  DRY-RUN : rien ne sera écrit                  ║');
  console.log('╚══════════════════════════════════════════════════════╝\n');

  // Chercher tous les produits qui ont des buyLinks avec Amazon
  const snap = await db.collection('gifts').get();

  let updated = 0, alreadyTagged = 0, noAmazon = 0;
  const batch = db.batch();
  let batchCount = 0;

  for (const doc of snap.docs) {
    const d = doc.data();
    const buyLinks = d.buyLinks || [];
    const existingUrl = d.url || d.product_url || '';

    // Trouver les liens Amazon dans buyLinks
    const hasAmazonLink = buyLinks.some(l => isAmazonUrl(l.url));
    const hasAmazonExisting = isAmazonUrl(existingUrl);

    if (!hasAmazonLink && !hasAmazonExisting) { noAmazon++; continue; }

    // Vérifier si déjà tagué
    const alreadyHasTag = buyLinks.some(l =>
      isAmazonUrl(l.url) && l.url.includes(`tag=${ASSOCIATE_TAG}`)
    );
    const existingAlreadyTagged = existingUrl.includes(`tag=${ASSOCIATE_TAG}`);

    if (alreadyHasTag && existingAlreadyTagged) { alreadyTagged++; continue; }

    // Appliquer le tag
    const updatedLinks = buyLinks.map(l => {
      if (!isAmazonUrl(l.url)) return l;
      const newUrl = addAffiliateTag(l.url);
      if (newUrl !== l.url) {
        console.log(`  ✅ ${(d.name || '?').substring(0, 40)}`);
        console.log(`     ${l.url.substring(0, 60)}`);
        console.log(`     → ${newUrl.substring(0, 60)}`);
      }
      return { ...l, url: newUrl, affiliated: true, affiliateTag: ASSOCIATE_TAG };
    });

    const updateData = {};
    if (buyLinks.length > 0) updateData.buyLinks = updatedLinks;

    // Mettre à jour le lien existant aussi (champ url)
    if (hasAmazonExisting) {
      const newExisting = addAffiliateTag(existingUrl);
      if (newExisting !== existingUrl) {
        updateData.url = newExisting;
        if (!DRY_RUN) console.log(`  🔗 url: → ${newExisting.substring(0, 60)}`);
      }
    }

    if (Object.keys(updateData).length > 0) {
      if (!DRY_RUN) {
        batch.update(doc.ref, updateData);
        batchCount++;
        if (batchCount >= 490) {
          await batch.commit();
          batchCount = 0;
          console.log('  💾 Batch committé...');
        }
      }
      updated++;
    }
  }

  if (!DRY_RUN && batchCount > 0) await batch.commit();

  console.log('\n╔══════════════════════════════════════════════════════╗');
  console.log(`║  ✅ Liens Amazon taggés  : ${String(updated).padEnd(25)}║`);
  console.log(`║  ⏭  Déjà tagués          : ${String(alreadyTagged).padEnd(25)}║`);
  console.log(`║  —  Sans lien Amazon     : ${String(noAmazon).padEnd(25)}║`);
  console.log('╚══════════════════════════════════════════════════════╝\n');

  if (DRY_RUN) console.log('Lance sans --dry-run pour appliquer.\n');
  else console.log(`💰 Tous les achats Amazon via Doron génèrent maintenant des commissions (tag: ${ASSOCIATE_TAG})\n`);
}

main().catch(e => { console.error('ERREUR:', e.message); process.exit(1); });
