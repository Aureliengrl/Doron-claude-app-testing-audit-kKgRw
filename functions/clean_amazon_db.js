const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp({
  projectId: 'doron-b3011',
});

const db = admin.firestore();

async function cleanAmazonLinks() {
  console.log('🔄 Démarrage du nettoyage de la base de données (Liens Amazon)...');
  
  const giftsRef = db.collection('gifts');
  const snapshot = await giftsRef.get();
  
  if (snapshot.empty) {
    console.log('Aucun cadeau trouvé dans la base.');
    return;
  }
  
  let updatedCount = 0;
  
  // Create a batch
  let batch = db.batch();
  let batchCount = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    let url = data.url || data.product_url || '';
    
    if (url && url.toLowerCase().includes('amazon.')) {
      try {
        // Parse the URL
        let newUrl = url;
        const amazonTag = 'doronapp130a-21';
        
        if (url.includes('?')) {
          const urlObj = new URL(url);
          urlObj.searchParams.set('tag', amazonTag);
          newUrl = urlObj.toString();
        } else {
          newUrl = `${url}?tag=${amazonTag}`;
        }
        
        if (newUrl !== url) {
          batch.update(doc.ref, { 
            url: newUrl, 
            updatedAt: admin.firestore.FieldValue.serverTimestamp() 
          });
          updatedCount++;
          batchCount++;
          
          if (batchCount === 450) {
            await batch.commit();
            console.log(`✅ Batch committé: 450 documents mis à jour.`);
            batch = db.batch();
            batchCount = 0;
          }
        }
      } catch (e) {
        console.error(`Erreur avec l'URL: ${url}`, e);
      }
    }
  }
  
  if (batchCount > 0) {
    await batch.commit();
    console.log(`✅ Dernier batch committé: ${batchCount} documents mis à jour.`);
  }

  console.log(`✨ Terminé ! ${updatedCount} liens Amazon ont été nettoyés avec le nouveau tag doronapp130a-21.`);
}

cleanAmazonLinks().then(() => {
  process.exit(0);
}).catch((error) => {
  console.error('❌ Erreur:', error);
  process.exit(1);
});
