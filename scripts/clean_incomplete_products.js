#!/usr/bin/env node

/**
 * Script pour nettoyer Firebase en supprimant TOUS les produits incomplets
 * Garde seulement les produits 100% complets
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialiser Firebase Admin
const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || './serviceAccountKey.json';

if (!fs.existsSync(serviceAccountPath)) {
  console.error('❌ Fichier de clé de service non trouvé!');
  console.error('   Place serviceAccountKey.json à la racine du projet scripts/');
  console.error('   Télécharge-le depuis Firebase Console > Paramètres > Comptes de service');
  process.exit(1);
}

const serviceAccount = require(path.resolve(serviceAccountPath));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

/**
 * Vérifie si un produit est complet
 */
function isProductComplete(product) {
  const issues = [];

  // Nom (accepte soit 'name' soit 'product_title')
  const name = product.name || product.product_title || '';
  if (!name || name.trim() === '' || name === 'Juste une petite vérification' || name === 'Invalid URL') {
    issues.push('nom manquant/invalide');
  }

  // Marque
  const brand = product.brand || '';
  if (!brand || brand.trim() === '' || brand === 'Unknown') {
    issues.push('marque manquante');
  }

  // Prix (accepte soit 'price' soit 'product_price')
  const price = product.price || 0;
  const priceStr = product.product_price || '';
  if ((!price || price === 0) && (!priceStr || priceStr === '0' || priceStr === '')) {
    issues.push('prix manquant');
  }

  // Image (accepte soit 'image' soit 'product_photo')
  const image = product.image || product.product_photo || '';
  if (!image || image.trim() === '' || image === 'N/A' || image.includes('placeholder')) {
    issues.push('image manquante');
  }

  // URL
  const url = product.url || product.product_url || '';
  if (!url || url.trim() === '') {
    issues.push('URL manquante');
  }

  return {
    isComplete: issues.length === 0,
    issues: issues
  };
}

async function cleanIncompleteProducts() {
  console.log('\n🧹 NETTOYAGE DE LA BASE FIREBASE');
  console.log('═══════════════════════════════════════════════════════════════════\n');
  console.log('Suppression de tous les produits incomplets...\n');

  // Compter tous les produits
  const countSnapshot = await db.collection('gifts').count().get();
  const totalCount = countSnapshot.data().count;

  if (totalCount === 0) {
    console.log('✅ Aucun produit dans la base');
    process.exit(0);
  }

  console.log(`📊 Total de produits: ${totalCount}\n`);
  console.log('🔍 Analyse en cours...\n');

  // Récupérer tous les produits
  const allProductsSnapshot = await db.collection('gifts').get();

  let completeCount = 0;
  let incompleteCount = 0;
  const toDelete = [];

  // Analyser chaque produit
  allProductsSnapshot.docs.forEach(doc => {
    const product = doc.data();
    const analysis = isProductComplete(product);

    if (analysis.isComplete) {
      completeCount++;
      console.log(`✅ [${doc.id}] ${product.name || product.product_title || 'Sans nom'}`);
    } else {
      incompleteCount++;
      toDelete.push({
        id: doc.id,
        ref: doc.ref,
        name: product.name || product.product_title || 'Sans nom',
        issues: analysis.issues
      });
      console.log(`❌ [${doc.id}] ${product.name || product.product_title || 'Sans nom'}`);
      console.log(`   Problèmes: ${analysis.issues.join(', ')}`);
    }
  });

  console.log('\n' + '═══════════════════════════════════════════════════════════════════');
  console.log('📊 RÉSUMÉ DE L\'ANALYSE');
  console.log('═══════════════════════════════════════════════════════════════════\n');
  console.log(`Total:             ${totalCount}`);
  console.log(`✅ Complets:       ${completeCount} (${(completeCount/totalCount*100).toFixed(1)}%)`);
  console.log(`❌ Incomplets:     ${incompleteCount} (${(incompleteCount/totalCount*100).toFixed(1)}%)`);
  console.log('');

  if (incompleteCount === 0) {
    console.log('✨ Ta base est déjà propre! Tous les produits sont complets.\n');
    process.exit(0);
  }

  // Confirmation
  console.log('⚠️  ATTENTION: Je vais supprimer les ' + incompleteCount + ' produits incomplets\n');
  console.log('Appuie sur Ctrl+C dans les 5 secondes pour annuler...\n');

  await new Promise(resolve => setTimeout(resolve, 5000));

  console.log('🗑️  Suppression en cours...\n');

  // Supprimer par batch de 500 (limite Firestore)
  const batchSize = 500;
  let deletedCount = 0;

  for (let i = 0; i < toDelete.length; i += batchSize) {
    const batch = db.batch();
    const chunk = toDelete.slice(i, i + batchSize);

    chunk.forEach(item => {
      batch.delete(item.ref);
    });

    await batch.commit();
    deletedCount += chunk.length;

    console.log(`   ✅ ${deletedCount}/${incompleteCount} produits supprimés...`);

    // Petit délai
    if (deletedCount < incompleteCount) {
      await new Promise(resolve => setTimeout(resolve, 200));
    }
  }

  console.log('\n' + '═══════════════════════════════════════════════════════════════════');
  console.log('✅ NETTOYAGE TERMINÉ!');
  console.log('═══════════════════════════════════════════════════════════════════\n');
  console.log(`Produits supprimés:  ${deletedCount}`);
  console.log(`Produits restants:   ${completeCount}`);
  console.log('');
  console.log('✨ Ta base est maintenant propre avec seulement des produits complets!\n');

  process.exit(0);
}

// Lancer le nettoyage
cleanIncompleteProducts().catch(error => {
  console.error('❌ Erreur fatale:', error);
  process.exit(1);
});
