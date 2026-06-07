const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp({
  projectId: 'doron-b3011',
});

const db = admin.firestore();

async function deleteAmazonGifts() {
  console.log('🗑️ Démarrage de la suppression des cadeaux Amazon...');
  
  const giftsRef = db.collection('gifts');
  const snapshot = await giftsRef.get();
  
  if (snapshot.empty) {
    console.log('Aucun cadeau trouvé.');
    return;
  }
  
  let deletedCount = 0;
  let batch = db.batch();
  let batchCount = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    let url = data.url || data.product_url || '';
    
    // Si c'est un produit Amazon (ou si on veut vider toute la base pour recommencer à zéro avec Rakuten)
    // Ici, le but est de faire table rase des produits amazon.
    if (url && url.toLowerCase().includes('amazon.')) {
      batch.delete(doc.ref);
      deletedCount++;
      batchCount++;
      
      if (batchCount === 450) {
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
        console.log(`✅ Batch committé: 450 documents supprimés.`);
      }
    }
  }
  
  if (batchCount > 0) {
    await batch.commit();
    console.log(`✅ Dernier batch committé: ${batchCount} documents supprimés.`);
  }

  console.log(`✨ Terminé ! ${deletedCount} vieux cadeaux Amazon ont été supprimés.`);
}

deleteAmazonGifts().then(() => process.exit(0)).catch(e => {
  console.error(e);
  process.exit(1);
});
