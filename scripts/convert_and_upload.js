#!/usr/bin/env node

/**
 * Script Node.js pour uploader les produits dans Firebase Firestore
 *
 * UTILISATION:
 * 1. npm install firebase-admin
 * 2. Télécharge la clé de service Firebase (voir README)
 * 3. node scripts/convert_and_upload.js
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialiser Firebase Admin
// IMPORTANT: Remplace ce chemin par celui de ta clé de service Firebase
const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || './serviceAccountKey.json';

if (!fs.existsSync(serviceAccountPath)) {
  console.error('❌ Fichier de clé de service non trouvé!');
  console.error('   Télécharge ta clé depuis:');
  console.error('   Firebase Console → Paramètres du projet → Comptes de service');
  console.error('   → Générer une nouvelle clé privée');
  console.error('   Et place le fichier à la racine du projet avec le nom "serviceAccountKey.json"');
  process.exit(1);
}

const serviceAccount = require(path.resolve(serviceAccountPath));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function uploadProducts() {
  console.log('🚀 Démarrage de l\'upload des produits...\n');

  // Lire le fichier JSON
  const jsonPath = path.join(__dirname, '../assets/jsons/fallback_products.json');

  if (!fs.existsSync(jsonPath)) {
    console.error('❌ Fichier fallback_products.json non trouvé!');
    console.error('   Chemin attendu:', jsonPath);
    process.exit(1);
  }

  console.log('📖 Lecture du fichier...');
  const jsonData = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));

  console.log(`✅ ${jsonData.length} produits chargés\n`);

  // Vérifier si la collection existe
  const snapshot = await db.collection('products').limit(1).get();
  if (!snapshot.empty) {
    console.log('⚠️  La collection "products" existe déjà');
    console.log('   Les nouveaux produits seront ajoutés/mis à jour\n');
  }

  // Upload par batch de 500 (limite Firestore)
  const batchSize = 500;
  let uploadedCount = 0;
  let errorCount = 0;

  console.log('📤 Upload des produits...');
  console.log(`   Batch size: ${batchSize} produits\n`);

  for (let i = 0; i < jsonData.length; i += batchSize) {
    const batch = db.batch();
    const endIndex = Math.min(i + batchSize, jsonData.length);
    const currentBatch = jsonData.slice(i, endIndex);

    console.log(`📦 Batch ${Math.floor(i / batchSize) + 1}: Produits ${i + 1} à ${endIndex}...`);

    for (const product of currentBatch) {
      try {
        // Utiliser l'ID du produit comme document ID
        const docRef = db.collection('products').doc(product.id.toString());

        // Préparer les données (retirer l'ID car il sera dans le document ID)
        const data = { ...product };
        delete data.id;

        // Assurer que les arrays sont bien des arrays
        if (!data.tags) data.tags = [];
        if (!data.categories) data.categories = [];

        batch.set(docRef, data);
        uploadedCount++;
      } catch (e) {
        console.error(`   ⚠️  Erreur produit ${product.id}:`, e.message);
        errorCount++;
      }
    }

    // Commit le batch
    try {
      await batch.commit();
      console.log(`   ✅ Batch ${Math.floor(i / batchSize) + 1} uploadé (${currentBatch.length} produits)`);

      // Petit délai pour éviter de surcharger Firebase
      if (endIndex < jsonData.length) {
        await new Promise(resolve => setTimeout(resolve, 500));
      }
    } catch (e) {
      console.error(`   ❌ Erreur upload batch ${Math.floor(i / batchSize) + 1}:`, e.message);
      errorCount += currentBatch.length;
    }
  }

  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('✅ UPLOAD TERMINÉ!');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('📊 Statistiques:');
  console.log(`   - Produits uploadés: ${uploadedCount}`);
  console.log(`   - Erreurs: ${errorCount}`);
  console.log(`   - Total: ${jsonData.length} produits`);

  // Vérification finale
  console.log('\n🔍 Vérification finale...');
  const finalSnapshot = await db.collection('products').count().get();
  console.log(`   Collection "products" contient: ${finalSnapshot.data().count} documents`);

  // Tester une query avec filtre sexe
  console.log('\n🧪 Test de requête avec filtre sexe...');
  const maleQuery = await db.collection('products')
    .where('tags', 'array-contains', 'homme')
    .limit(10)
    .get();
  console.log(`   - Produits avec tag "homme": ${maleQuery.size} trouvés`);

  const femaleQuery = await db.collection('products')
    .where('tags', 'array-contains', 'femme')
    .limit(10)
    .get();
  console.log(`   - Produits avec tag "femme": ${femaleQuery.size} trouvés`);

  if (maleQuery.empty && femaleQuery.empty) {
    console.log('\n⚠️  ATTENTION: Aucun produit trouvé avec tags "homme" ou "femme"!');
    console.log('   Les tags dans le JSON sont peut-être différents.');
  }

  console.log('\n✨ Firebase est maintenant peuplé!');
  console.log('   L\'app devrait afficher des produits variés.\n');

  process.exit(0);
}

// Lancer l'upload
uploadProducts().catch(error => {
  console.error('❌ Erreur fatale:', error);
  process.exit(1);
});
