/**
 * SCRIPT DE DEBUG FIREBASE
 *
 * Copier ce code dans la console de Replit pour voir l'état actuel de Firebase
 * et comprendre pourquoi aucun produit n'apparaît.
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function debugFirebase() {
  console.log('🔍 DEBUG FIREBASE - Analyse des produits\n');
  console.log('═══════════════════════════════════════\n');

  try {
    const snapshot = await db.collection('gifts').limit(10).get();

    if (snapshot.empty) {
      console.log('❌ AUCUN PRODUIT dans Firebase !');
      process.exit(1);
    }

    console.log(`✅ ${snapshot.size} produits trouvés (affichage des 10 premiers)\n`);

    let stats = {
      totalGenderHomme: 0,
      totalGenderFemme: 0,
      totalGenderMixte: 0,
      totalGenderManquant: 0,
      budgetAvecTiret: 0,
      budgetSansTag: 0,
      budgetFormatIncorrect: 0,
    };

    snapshot.docs.forEach((doc, index) => {
      const data = doc.data();
      const tags = data.tags || [];

      console.log(`\n📦 PRODUIT ${index + 1}: "${data.name || data.product_title}"`);
      console.log(`   Prix: ${data.price}€`);
      console.log(`   Gender field: "${data.gender}"`);
      console.log(`   Tags: ${JSON.stringify(tags)}`);

      // Analyser le genre
      const genderTags = tags.filter(t => t.startsWith('gender_'));
      if (genderTags.length === 0) {
        console.log(`   ⚠️  PROBLÈME: Aucun tag gender_*`);
        stats.totalGenderManquant++;
      } else {
        if (genderTags.includes('gender_homme')) {
          console.log(`   ✓ Genre: HOMME`);
          stats.totalGenderHomme++;
        } else if (genderTags.includes('gender_femme')) {
          console.log(`   ✓ Genre: FEMME`);
          stats.totalGenderFemme++;
        } else if (genderTags.includes('gender_mixte')) {
          console.log(`   ⚠️  Genre: MIXTE (ne devrait pas exister)`);
          stats.totalGenderMixte++;
        }
      }

      // Analyser le budget
      const budgetTags = tags.filter(t => t.startsWith('budget_'));
      if (budgetTags.length === 0) {
        console.log(`   ⚠️  PROBLÈME: Aucun tag budget_*`);
        stats.budgetSansTag++;
      } else {
        const budgetTag = budgetTags[0];
        if (budgetTag.includes('-')) {
          console.log(`   ⚠️  PROBLÈME: Budget avec tiret "${budgetTag}" (devrait être underscore)`);
          stats.budgetAvecTiret++;
        }
        if (budgetTag === 'budget_200_500' || budgetTag === 'budget_500_plus') {
          console.log(`   ⚠️  PROBLÈME: Format budget incorrect "${budgetTag}" (devrait être budget_200+)`);
          stats.budgetFormatIncorrect++;
        }
      }
    });

    console.log('\n\n═══════════════════════════════════════');
    console.log('📊 STATISTIQUES (sur les 10 premiers produits)');
    console.log('═══════════════════════════════════════');
    console.log(`Genre Homme: ${stats.totalGenderHomme}`);
    console.log(`Genre Femme: ${stats.totalGenderFemme}`);
    console.log(`Genre Mixte: ${stats.totalGenderMixte} ${stats.totalGenderMixte > 0 ? '⚠️' : '✓'}`);
    console.log(`Genre manquant: ${stats.totalGenderManquant} ${stats.totalGenderManquant > 0 ? '⚠️' : '✓'}`);
    console.log(`Budget avec tirets: ${stats.budgetAvecTiret} ${stats.budgetAvecTiret > 0 ? '⚠️' : '✓'}`);
    console.log(`Budget format incorrect: ${stats.budgetFormatIncorrect} ${stats.budgetFormatIncorrect > 0 ? '⚠️' : '✓'}`);
    console.log(`Budget manquant: ${stats.budgetSansTag} ${stats.budgetSansTag > 0 ? '⚠️' : '✓'}`);

    console.log('\n═══════════════════════════════════════');
    console.log('🎯 DIAGNOSTIC');
    console.log('═══════════════════════════════════════');

    if (stats.totalGenderManquant > 0) {
      console.log('❌ Certains produits n\'ont PAS de tag gender_*');
      console.log('   → Exécutez le script fix_firebase_tags.js');
    }

    if (stats.totalGenderMixte > 0) {
      console.log('⚠️  Certains produits ont gender_mixte');
      console.log('   → Relancez le script fix_firebase_tags.js (version corrigée)');
    }

    if (stats.budgetAvecTiret > 0) {
      console.log('⚠️  Certains budgets ont des tirets au lieu d\'underscores');
      console.log('   → L\'app devrait normaliser automatiquement, mais c\'est mieux de corriger');
    }

    if (stats.budgetFormatIncorrect > 0) {
      console.log('❌ Certains budgets ont un format incorrect (budget_200_500 au lieu de budget_200+)');
      console.log('   → Exécutez le script fix_firebase_tags.js (version corrigée)');
    }

    if (stats.totalGenderHomme === 0 && stats.totalGenderFemme === 0) {
      console.log('❌ AUCUN produit avec genre valide !');
      console.log('   → C\'est pour ça qu\'aucun produit n\'apparaît dans l\'app');
    } else {
      console.log(`✓ ${stats.totalGenderHomme + stats.totalGenderFemme} produits ont un genre valide`);
    }

  } catch (error) {
    console.error('❌ ERREUR:', error);
  }

  process.exit(0);
}

debugFirebase();
