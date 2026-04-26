const admin = require('firebase-admin');
const sa = require('./serviceAccountKey.json');
admin.initializeApp({ credential: admin.credential.cert(sa) });
const db = admin.firestore();

db.collection('gifts').get().then(snap => {
  let withMulti = 0, withSingle = 0, amazonOnly = 0, noLinks = 0;

  snap.docs.forEach(d => {
    const data = d.data();
    const bl = data.buyLinks || [];
    const url = (data.url || data.product_url || '').toString();

    if (bl.length > 1)       withMulti++;
    else if (bl.length === 1) withSingle++;
    else if (url.includes('amazon')) amazonOnly++;
    else noLinks++;
  });

  console.log('');
  console.log('══ Audit des liens dans Firebase ══════════════');
  console.log('Total produits              :', snap.size);
  console.log('✅ Multi buyLinks (Claude)  :', withMulti);
  console.log('🔗 1 buyLink seulement      :', withSingle);
  console.log('🟠 URL Amazon sans buyLinks :', amazonOnly);
  console.log('❌ Aucun lien               :', noLinks);
  console.log('═══════════════════════════════════════════════');
  console.log('');
  console.log('→ Candidats Amazon PA API   :', snap.size - withMulti, 'produits');
  process.exit(0);
}).catch(e => { console.error(e.message); process.exit(1); });
