const fs = require('fs');

const path = 'functions/index.js';
let content = fs.readFileSync(path, 'utf8');

const newCode = `
const { onRequest } = require('firebase-functions/v2/https');

// Nouveau: httpCleanAmazonDB (HTTPS Trigger) pour nettoyer la base via simple URL
exports.httpCleanAmazonDB = onRequest(async (req, res) => {
  console.log('🔄 Démarrage du nettoyage de la base de données (Liens Amazon)...');
  
  const giftsRef = db.collection('gifts');
  const snapshot = await giftsRef.get();
  
  if (snapshot.empty) {
    res.send('Aucun cadeau trouvé');
    return;
  }
  
  let updatedCount = 0;
  let batch = db.batch();
  let batchCount = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    let url = data.url || data.product_url || '';
    
    if (url && url.toLowerCase().includes('amazon.')) {
      try {
        let newUrl = url;
        const amazonTag = 'doronapp130a-21';
        
        if (url.includes('?')) {
          const urlObj = new URL(url);
          urlObj.searchParams.set('tag', amazonTag);
          newUrl = urlObj.toString();
        } else {
          newUrl = \`\${url}?tag=\${amazonTag}\`;
        }
        
        if (newUrl !== url) {
          batch.update(doc.ref, { 
            url: newUrl, 
            updatedAt: require('firebase-admin').firestore.FieldValue.serverTimestamp() 
          });
          updatedCount++;
          batchCount++;
          
          if (batchCount === 450) {
            await batch.commit();
            batch = db.batch();
            batchCount = 0;
          }
        }
      } catch (e) {}
    }
  }
  
  if (batchCount > 0) {
    await batch.commit();
  }

  res.send(\`✨ Terminé ! \${updatedCount} liens Amazon ont été mis à jour avec doronapp130a-21.\`);
});
`;

if (!content.includes('httpCleanAmazonDB')) {
  fs.appendFileSync(path, newCode);
  console.log('Appended httpCleanAmazonDB to functions/index.js');
} else {
  console.log('Already exists');
}
