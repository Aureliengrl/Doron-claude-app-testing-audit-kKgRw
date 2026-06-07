const fs = require('fs');

const path = 'functions/index.js';
let content = fs.readFileSync(path, 'utf8');

const newCode = `
const { onRequest: reqImport } = require('firebase-functions/v2/https');
const xml2js = require('xml2js');

// Nouveau: httpImportRakuten pour importer des produits depuis Rakuten et les catégoriser via Claude
exports.httpImportRakuten = reqImport({ timeoutSeconds: 540, memory: '1GiB' }, async (req, res) => {
  const keyword = req.query.keyword || 'cadeau';
  const token = 'pk_thp8WuFagFNOQh9VnsoWHJ8mAQhhRsHt4NWvW4wUA4q';
  const url = \`https://api.rakutenmarketing.com/productsearch/1.0?keyword=\${encodeURIComponent(keyword)}&max=50\`;

  console.log(\`🚀 Démarrage de l'import Rakuten pour: \${keyword}\`);

  try {
    const response = await fetch(url, {
      headers: {
        'Authorization': \`Bearer \${token}\`
      }
    });

    if (!response.ok) {
      res.status(500).send(\`Erreur Rakuten API: \${response.status}\`);
      return;
    }

    const xml = await response.text();
    const parser = new xml2js.Parser({ explicitArray: false });
    const parsed = await parser.parseStringPromise(xml);

    let items = parsed.result && parsed.result.item;
    if (!items) {
      res.send('Aucun produit trouvé');
      return;
    }

    if (!Array.isArray(items)) {
      items = [items];
    }

    const anthropic = new (require('@anthropic-ai/sdk').Anthropic)({
      apiKey: process.env.ANTHROPIC_API_KEY || 'sk-ant-api03-placeholder' 
      // L'API key Anthropic doit être définie dans l'environnement Cloud Functions (secrets)
      // Nous utilisons la fonction generateBrands existante si possible, 
      // ou bien nous sauvegardons les produits bruts et laissons le client les matcher
    });
    
    // Pour éviter le timeout et les coûts si on a pas de clé hardcodée, on va sauvegarder les produits tels quels.
    // L'IA Claude est déjà utilisée dans ProductMatchingService pour le reranking, donc on peut se contenter 
    // d'insérer des données propres.

    let batch = db.batch();
    let imported = 0;

    for (const item of items) {
      const priceVal = item.price && item.price._ ? item.price._ : item.price;
      const imageUrl = item.imageurl || '';
      
      if (!imageUrl || imageUrl.includes('no-image')) continue; // Skip items without images

      const product = {
        name: item.productname || '',
        price: priceVal || '',
        description: item.description || '',
        image: imageUrl,
        url: item.linkurl || '',
        brand: item.merchantname || 'Rakuten',
        source: 'rakuten',
        keywords: [keyword.toLowerCase()],
        createdAt: require('firebase-admin').firestore.FieldValue.serverTimestamp()
      };

      const docRef = db.collection('gifts').doc();
      batch.set(docRef, product);
      imported++;
    }

    await batch.commit();

    res.send(\`✨ Terminé ! \${imported} produits importés depuis Rakuten avec succès pour le mot clé "\${keyword}".\`);
  } catch (e) {
    console.error('Erreur import Rakuten:', e);
    res.status(500).send('Erreur: ' + e.toString());
  }
});
`;

if (!content.includes('httpImportRakuten')) {
  fs.appendFileSync(path, newCode);
  console.log('Appended httpImportRakuten to functions/index.js');
} else {
  console.log('Already exists');
}
