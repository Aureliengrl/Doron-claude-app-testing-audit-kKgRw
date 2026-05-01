const admin = require('firebase-admin');
const sa = require('./serviceAccountKey.json');
admin.initializeApp({ credential: admin.credential.cert(sa) });
const db = admin.firestore();

db.collection('gifts').get().then(snap => {
  let hasBuyLinks = 0, noBuyLinks = 0, totalLinks = 0, maxLinks = 0;
  let sampleMax = null;
  let sampleWith = null;
  snap.docs.forEach(doc => {
    const d = doc.data();
    const bl = d.buyLinks || d.buy_links || d.links || [];
    if (Array.isArray(bl) && bl.length > 0) {
      hasBuyLinks++;
      totalLinks += bl.length;
      if (bl.length > maxLinks) {
        maxLinks = bl.length;
        sampleMax = { id: doc.id, name: d.name, links: bl };
      }
      if (!sampleWith) sampleWith = { id: doc.id, name: d.name, links: bl.slice(0,2) };
    } else {
      noBuyLinks++;
    }
  });
  console.log('\n=== buyLinks STATS ===');
  console.log('  Produits AVEC buyLinks :', hasBuyLinks);
  console.log('  Produits SANS buyLinks :', noBuyLinks);
  console.log('  Total liens achat      :', totalLinks);
  console.log('  Max liens / produit    :', maxLinks);
  console.log('\n=== EXEMPLE (premier avec buyLinks) ===');
  console.log(JSON.stringify(sampleWith, null, 2));
  console.log('\n=== EXEMPLE (produit avec le plus de liens) ===');
  console.log(JSON.stringify(sampleMax, null, 2));
  process.exit(0);
}).catch(e => { console.error(e); process.exit(1); });
