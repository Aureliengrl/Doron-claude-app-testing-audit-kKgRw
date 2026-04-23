/**
 * diagnose_brands.js
 * Affiche les URLs images actuelles des produits pour une liste de marques.
 * Usage: node diagnose_brands.js
 */
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const TARGET_BRANDS = [
  'nike', 'lancôme', 'lancome', 'diptyque', 'adidas', 'dior', 'chanel',
  'louis vuitton', 'gucci', 'prada', 'hermes', 'hermès', 'zara', 'lego',
  'dyson', 'apple', 'samsung', 'sony', 'bose', 'ralph lauren',
  'sézane', 'sezane', 'miu miu', 'bottega', 'louboutin', 'cartier',
  'rolex', 'omega', 'ysl', 'saint laurent', 'balenciaga', 'off-white',
  'jacquemus', 'ami', 'maison margiela', 'acne studios', 'toteme',
  'lululemon', 'patagonia', 'arc teryx', "arc'teryx", 'salomon',
];

async function main() {
  const snap = await db.collection('gifts').get();
  console.log(`\n📦 ${snap.size} produits chargés\n`);
  console.log('MARQUE'.padEnd(20) + 'NOM'.padEnd(40) + 'URL IMAGE');
  console.log('─'.repeat(120));

  for (const doc of snap.docs) {
    const d = doc.data();
    const brand = (d.brand || d.source || '').toLowerCase();
    const name  = d.name || d.product_title || d.title || '';
    const image = d.image || d.imageUrl || d.productPhoto || '';

    const matches = TARGET_BRANDS.some(b => brand.includes(b) || (d.brand||'').toLowerCase().includes(b));
    if (!matches) continue;

    const imgShort = image.length > 60 ? image.substring(0, 57) + '...' : image;
    console.log(
      (d.brand || '').substring(0, 18).padEnd(20) +
      name.substring(0, 38).padEnd(40) +
      imgShort
    );
  }
  process.exit(0);
}
main().catch(e => { console.error(e); process.exit(1); });
