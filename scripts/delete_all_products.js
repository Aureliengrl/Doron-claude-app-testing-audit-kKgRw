#!/usr/bin/env node

/**
 * Script pour supprimer tous les produits de Firebase
 * Utilise avant de re-uploader les produits avec les nouvelles URLs
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialiser Firebase Admin
const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || './serviceAccountKey.json';

if (!fs.existsSync(serviceAccountPath)) {
  console.error('❌ Fichier de clé de service non trouvé!');
  console.error('   Place serviceAccountKey.json à la racine du projet');
  process.exit(1);
}

const serviceAccount = require(path.resolve(serviceAccountPath));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function deleteAllProducts() {
  console.log('🗑️  Suppression de tous les produits...\n');

  // Compter les produits existants
  const countSnapshot = await db.collection('products').count().get();
  const totalCount = countSnapshot.data().count;

  if (totalCount === 0) {
    console.log('✅ Aucun produit à supprimer');
    process.exit(0);
  }

  console.log(`   Produits à supprimer: ${totalCount}\n`);

  // Supprimer par batch de 500 (limite Firestore)
  const batchSize = 500;
  let deletedCount = 0;

  while (true) {
    // Récupérer un batch de documents
    const snapshot = await db.collection('products').limit(batchSize).get();

    if (snapshot.empty) {
      break;
    }

    // Créer un batch de suppression
    const batch = db.batch();
    snapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    // Commit le batch
    await batch.commit();
    deletedCount += snapshot.size;

    console.log(`   ✅ ${deletedCount}/${totalCount} produits supprimés...`);

    // Petit délai pour éviter de surcharger Firebase
    await new Promise(resolve => setTimeout(resolve, 200));
  }

  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('✅ SUPPRESSION TERMINÉE!');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`   Total supprimé: ${deletedCount} produits\n`);

  process.exit(0);
}

// Lancer la suppression
deleteAllProducts().catch(error => {
  console.error('❌ Erreur fatale:', error);
  process.exit(1);
});
