const fs = require('fs');

const path = 'functions/index.js';
let content = fs.readFileSync(path, 'utf8');

const newCode = `
// Nouveau: httpDeleteAmazonGifts pour supprimer les vieux produits
exports.httpDeleteAmazonGifts = onRequest(async (req, res) => {
  console.log('🗑️ Démarrage de la suppression...');
  
  const giftsRef = db.collection('gifts');
  const snapshot = await giftsRef.get();
  
  if (snapshot.empty) {
    res.send('Aucun cadeau');
    return;
  }
  
  let deletedCount = 0;
  let batch = db.batch();
  let batchCount = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    let url = data.url || data.product_url || '';
    
    if (url && url.toLowerCase().includes('amazon.')) {
      batch.delete(doc.ref);
      deletedCount++;
      batchCount++;
      
      if (batchCount === 450) {
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
      }
    }
  }
  
  if (batchCount > 0) {
    await batch.commit();
  }

  res.send(\`✨ Terminé ! \${deletedCount} vieux cadeaux Amazon supprimés.\`);
});
`;

if (!content.includes('httpDeleteAmazonGifts')) {
  fs.appendFileSync(path, newCode);
  console.log('Appended httpDeleteAmazonGifts to functions/index.js');
} else {
  console.log('Already exists');
}
