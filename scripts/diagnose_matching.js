#!/usr/bin/env node

/**
 * Script de diagnostic : Simule EXACTEMENT la recherche de l'app
 * pour comprendre pourquoi 0 produits apparaissent
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialiser Firebase Admin
const serviceAccount = require(path.join(__dirname, '../serviceAccountKey.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// SIMULATION DES TAGS DE L'APP
const genderConversion = {
  'Femme': 'gender_femme',
  'Homme': 'gender_homme',
  'Mixte': 'gender_mixte',
  'Non spécifié': 'gender_mixte',
};

/**
 * Simule la conversion de l'app (product_matching_service.dart ligne 518-527)
 */
function convertGenderTag(userGender) {
  console.log('\n🔍 SIMULATION CONVERSION APP:');
  console.log(`   Input: "${userGender}"`);

  // Ligne 521-522: Chercher dans la map de conversion
  let convertedGender = genderConversion[userGender];

  if (!convertedGender) {
    // Ligne 522: Fallback vers "Non spécifié"
    console.log(`   ⚠️ Pas trouvé dans map → Fallback "Non spécifié"`);
    convertedGender = genderConversion['Non spécifié'];
  }

  console.log(`   Output: ${convertedGender}`);
  return convertedGender;
}

/**
 * Calcule le score comme l'app (simplifié)
 */
function calculateScore(product, userGenderTag, isPersonMode) {
  let score = 150.0; // Base score

  const productTags = product.tags || [];
  const productGenderTags = productTags.filter(t => t.startsWith('gender_'));

  console.log(`\n   📦 Produit: "${product.name}"`);
  console.log(`      Tags genre produit: ${productGenderTags.join(', ')}`);
  console.log(`      User cherche: ${userGenderTag}`);

  // Ligne 697-757: Logique de scoring genre
  if (productGenderTags.length === 0) {
    console.log(`      ℹ️ Pas de tag genre → +50 (universel)`);
    score += 50.0;
  } else if (productGenderTags.includes(userGenderTag)) {
    console.log(`      ✅ MATCH EXACT genre → +100`);
    score += 100.0;
  } else if (productGenderTags.includes('gender_mixte')) {
    console.log(`      ✅ Produit mixte → +70`);
    score += 70.0;
  } else {
    // Genre ne correspond pas
    if (isPersonMode) {
      console.log(`      ❌ EXCLUSION STRICTE (mode person) → -10000`);
      return -10000.0;
    } else {
      console.log(`      ⚠️ Pénalité → -80`);
      score -= 80.0;
    }
  }

  console.log(`      Score final: ${score}`);
  return score;
}

async function diagnoseMatching() {
  console.log('═══════════════════════════════════════════════════════════');
  console.log('🔍 DIAGNOSTIC: Pourquoi 0 produits après ajout personne?');
  console.log('═══════════════════════════════════════════════════════════\n');

  // TEST 1: Vérifier les produits Firebase
  console.log('📊 ÉTAPE 1: Vérifier les produits dans Firebase\n');

  const giftsSnapshot = await db.collection('gifts').limit(100).get();
  console.log(`✅ ${giftsSnapshot.size} produits chargés depuis Firebase\n`);

  if (giftsSnapshot.empty) {
    console.log('❌ ERREUR CRITIQUE: Firebase collection "gifts" est VIDE !');
    process.exit(1);
  }

  // Compter les produits par genre
  const genderCounts = {
    'gender_femme': 0,
    'gender_homme': 0,
    'gender_mixte': 0,
    'aucun': 0
  };

  giftsSnapshot.forEach(doc => {
    const product = doc.data();
    const tags = product.tags || [];
    const genderTag = tags.find(t => t.startsWith('gender_'));

    if (genderTag) {
      genderCounts[genderTag] = (genderCounts[genderTag] || 0) + 1;
    } else {
      genderCounts['aucun']++;
    }
  });

  console.log('📊 Répartition des genres dans Firebase:');
  console.log(`   gender_femme: ${genderCounts['gender_femme']} produits`);
  console.log(`   gender_homme: ${genderCounts['gender_homme']} produits`);
  console.log(`   gender_mixte: ${genderCounts['gender_mixte']} produits`);
  console.log(`   Aucun tag: ${genderCounts['aucun']} produits`);

  if (genderCounts['gender_mixte'] === 0) {
    console.log('\n⚠️ PROBLÈME TROUVÉ: Aucun produit gender_mixte !');
    console.log('   → L\'app utilise gender_mixte comme fallback');
    console.log('   → Solution: Exécuter le script fix_firebase_tags.js');
  }

  // TEST 2: Simuler la recherche de l'app
  console.log('\n═══════════════════════════════════════════════════════════');
  console.log('🎯 ÉTAPE 2: Simuler la recherche de l\'app\n');

  // Cas de test: utilisateur sélectionne "🙋‍♀️ Femme" dans l'onboarding
  const testCases = [
    { input: '🙋‍♀️ Femme', description: 'Onboarding avec emoji (cas réel)' },
    { input: 'Femme', description: 'Sans emoji (ancien format)' },
    { input: '🙋‍♂️ Homme', description: 'Homme avec emoji' },
    { input: 'Homme', description: 'Homme sans emoji' },
  ];

  for (const testCase of testCases) {
    console.log(`\n🧪 TEST: ${testCase.description}`);
    console.log(`   User sélectionne: "${testCase.input}"`);

    const convertedGender = convertGenderTag(testCase.input);

    if (!convertedGender) {
      console.log('   ❌ CONVERSION ÉCHOUE → Aucun tag genre → 0 produits');
      continue;
    }

    // Tester avec quelques produits
    console.log('\n   🔍 Test avec 5 produits aléatoires:');
    let validProducts = 0;
    let excludedProducts = 0;

    const products = [];
    giftsSnapshot.forEach(doc => products.push({ id: doc.id, ...doc.data() }));

    const sampleProducts = products.slice(0, 5);

    for (const product of sampleProducts) {
      const score = calculateScore(product, convertedGender, true); // mode person

      if (score > 0) {
        validProducts++;
      } else {
        excludedProducts++;
      }
    }

    console.log(`\n   📊 Résumé: ${validProducts} produits valides, ${excludedProducts} exclus`);

    if (validProducts === 0) {
      console.log('   ❌ PROBLÈME: Tous les produits exclus !');
    }
  }

  // TEST 3: Vérifier les tags budget
  console.log('\n═══════════════════════════════════════════════════════════');
  console.log('🏷️ ÉTAPE 3: Vérifier les tags budget\n');

  const budgetCounts = {};
  giftsSnapshot.forEach(doc => {
    const product = doc.data();
    const tags = product.tags || [];
    const budgetTag = tags.find(t => t.startsWith('budget_'));

    if (budgetTag) {
      budgetCounts[budgetTag] = (budgetCounts[budgetTag] || 0) + 1;
    }
  });

  console.log('📊 Répartition des budgets:');
  Object.entries(budgetCounts).sort().forEach(([tag, count]) => {
    console.log(`   ${tag}: ${count} produits`);
  });

  const expectedBudgets = ['budget_0_50', 'budget_50_100', 'budget_100_200', 'budget_200+'];
  const unexpectedBudgets = Object.keys(budgetCounts).filter(b => !expectedBudgets.includes(b));

  if (unexpectedBudgets.length > 0) {
    console.log('\n⚠️ PROBLÈME: Tags budget incorrects trouvés:');
    unexpectedBudgets.forEach(tag => {
      console.log(`   - ${tag} (${budgetCounts[tag]} produits)`);
    });
    console.log('   → L\'app attend: budget_0_50, budget_50_100, budget_100_200, budget_200+');
  }

  // TEST 4: Vérifier un produit complet
  console.log('\n═══════════════════════════════════════════════════════════');
  console.log('🔍 ÉTAPE 4: Exemple de produit complet\n');

  const sampleProduct = giftsSnapshot.docs[0].data();
  console.log('Produit exemple:');
  console.log(JSON.stringify({
    name: sampleProduct.name,
    price: sampleProduct.price,
    tags: sampleProduct.tags,
    categories: sampleProduct.categories,
  }, null, 2));

  console.log('\n═══════════════════════════════════════════════════════════');
  console.log('✅ DIAGNOSTIC TERMINÉ');
  console.log('═══════════════════════════════════════════════════════════\n');

  process.exit(0);
}

diagnoseMatching().catch(error => {
  console.error('❌ Erreur:', error);
  process.exit(1);
});
