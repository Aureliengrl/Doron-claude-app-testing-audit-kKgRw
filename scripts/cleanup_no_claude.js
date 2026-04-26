/**
 * cleanup_no_claude.js
 * Supprime le flag "enriched: true" des produits qui ont été marqués
 * enrichis SANS que Claude ait pu faire ses recherches (credit balance too low)
 * = produits avec 1 seul buyLink de source "existing" et pas d'imageUrl Claude
 */
const admin = require('firebase-admin');
const sa    = require('./serviceAccountKey.json');
admin.initializeApp({ credential: admin.credential.cert(sa) });
const db = admin.firestore();

const DRY_RUN = process.argv.includes('--dry-run');

async function main() {
  console.log('\n🔍 Recherche des produits mal enrichis (sans Claude)...\n');

  const snap = await db.collection('gifts').where('enriched', '==', true).get();
  let toReset = 0, kept = 0;

  const batch = db.batch();
  let batchCount = 0;

  for (const doc of snap.docs) {
    const d = doc.data();
    const buyLinks = d.buyLinks || [];

    // Un produit vraiment enrichi par Claude a soit:
    // - plusieurs links
    // - OU au moins 1 link de source "claude"
    const hasClaudeLink = buyLinks.some(l => l.source === 'claude');
    const hasMultipleLinks = buyLinks.length > 1;
    const hasQualityScore = d.qualityScore !== undefined;

    const wasProperlyEnriched = hasClaudeLink || hasMultipleLinks || hasQualityScore;

    if (!wasProperlyEnriched) {
      // Réinitialiser pour ré-enrichissement futur
      if (!DRY_RUN) {
        batch.update(doc.ref, {
          enriched: false,
          enrichedAt: admin.firestore.FieldValue.delete(),
          enrichedVersion: admin.firestore.FieldValue.delete(),
          buyLinks: admin.firestore.FieldValue.delete(),
          priceMin: admin.firestore.FieldValue.delete(),
          priceMax: admin.firestore.FieldValue.delete(),
        });
        batchCount++;

        // Firestore batch max 500
        if (batchCount >= 490) {
          await batch.commit();
          batchCount = 0;
          console.log('  💾 Batch écrit...');
        }
      }
      toReset++;
      const name = d.name || '(sans nom)';
      if (toReset <= 20) console.log(`  ❌ À réinitialiser: "${d.brand || ''} — ${name.substring(0, 50)}"`);
    } else {
      kept++;
    }
  }

  if (!DRY_RUN && batchCount > 0) await batch.commit();

  console.log(`\n📊 Résultat:`);
  console.log(`  ✅ Correctement enrichis (gardés): ${kept}`);
  console.log(`  🔄 Mal enrichis (réinitialisés):  ${toReset}`);
  if (DRY_RUN) console.log('\n  [DRY-RUN] Rien n\'a été écrit. Lance sans --dry-run pour appliquer.');
  else console.log('\n  ✅ Base nettoyée. Recharge les crédits puis relance: node doron_enricher.js');
}

main().catch(e => { console.error('ERREUR:', e.message); process.exit(1); });
