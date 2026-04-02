/**
 * SCRIPT SIMPLE : Compte les produits par genre dans Firebase
 *
 * Exécuter sur Replit : node count_genders.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function countGenders() {
  console.log('🔍 Comptage des genres dans Firebase\n');

  const snapshot = await db.collection('gifts').get();

  let stats = {
    total: snapshot.size,
    gender_homme: 0,
    gender_femme: 0,
    gender_mixte: 0,
    sans_genre: 0
  };

  snapshot.docs.forEach(doc => {
    const data = doc.data();
    const tags = data.tags || [];

    if (tags.includes('gender_homme')) {
      stats.gender_homme++;
    } else if (tags.includes('gender_femme')) {
      stats.gender_femme++;
    } else if (tags.includes('gender_mixte')) {
      stats.gender_mixte++;
    } else {
      stats.sans_genre++;
    }
  });

  console.log('📊 RÉSULTATS:');
  console.log('═════════════════════════════════════');
  console.log(`Total produits: ${stats.total}`);
  console.log(`gender_homme: ${stats.gender_homme} (${Math.round(stats.gender_homme/stats.total*100)}%)`);
  console.log(`gender_femme: ${stats.gender_femme} (${Math.round(stats.gender_femme/stats.total*100)}%)`);
  console.log(`gender_mixte: ${stats.gender_mixte} (${Math.round(stats.gender_mixte/stats.total*100)}%)`);
  console.log(`sans genre: ${stats.sans_genre}`);
  console.log('═════════════════════════════════════\n');

  if (stats.gender_homme === 0) {
    console.log('❌ PROBLÈME: AUCUN produit gender_homme !');
    console.log('   → Recherche "Homme" donnera 0 résultats\n');
  }

  if (stats.gender_femme === 0) {
    console.log('❌ PROBLÈME: AUCUN produit gender_femme !');
    console.log('   → Recherche "Femme" donnera 0 résultats\n');
  }

  if (stats.gender_homme > 0 && stats.gender_femme > 0) {
    console.log('✅ Les deux genres sont présents');
    console.log('   → Recherche Homme ET Femme devraient fonctionner\n');
  }

  if (stats.gender_mixte > 0) {
    console.log(`⚠️  ${stats.gender_mixte} produits ont encore gender_mixte`);
    console.log('   → Le script devrait les convertir en homme/femme\n');
  }

  process.exit(0);
}

countGenders();
