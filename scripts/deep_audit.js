const admin = require('firebase-admin');
const sa = require('./serviceAccountKey.json');

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(sa) });
}
const db = admin.firestore();

async function deepAudit() {
  const snap = await db.collection('gifts').where('active', '==', true).get();
  const total = snap.size;

  let noImage = 0;
  let httpImage = 0;       // URL non-https (potentiellement brisée)
  let badImageUrl = 0;     // URL suspicieuse (placeholder, picsum, via.placeholder, etc.)
  let goodImage = 0;

  let noBuyLinks = 0;
  let oneBuyLink = 0;
  let multiBuyLinks = 0;

  let noPrice = 0;
  let zeroPrice = 0;

  const badImages = [];
  const noImageSamples = [];
  const noBuyLinkSamples = [];

  snap.forEach(doc => {
    const d = doc.data();

    // ── Image ──────────────────────────────────────
    const img = d.image || d.imageUrl || d.product_photo || '';
    if (!img || img.trim() === '') {
      noImage++;
      if (noImageSamples.length < 10) noImageSamples.push(d.name || doc.id);
    } else if (/placeholder|picsum|lorempixel|via\.placeholder|unsplash\.com\/random|dummyimage/i.test(img)) {
      badImageUrl++;
      if (badImages.length < 10) badImages.push({ name: d.name, url: img.substring(0, 80) });
    } else if (!img.startsWith('https')) {
      httpImage++;
    } else {
      goodImage++;
    }

    // ── buyLinks ───────────────────────────────────
    const links = d.buyLinks;
    if (!links || !Array.isArray(links) || links.length === 0) {
      noBuyLinks++;
      if (noBuyLinkSamples.length < 8) noBuyLinkSamples.push(d.name || doc.id);
    } else if (links.length === 1) {
      oneBuyLink++;
    } else {
      multiBuyLinks++;
    }

    // ── Prix ───────────────────────────────────────
    const price = d.price || d.product_price;
    const priceStr = (price || '').toString().replace(/[€$£]/g, '').trim();
    if (!priceStr || priceStr === '') noPrice++;
    else if (parseFloat(priceStr) === 0) zeroPrice++;
  });

  const pctGoodImage = ((goodImage / total) * 100).toFixed(1);
  const pctMultiLinks = ((multiBuyLinks / total) * 100).toFixed(1);
  const pctGoodLinks = (((multiBuyLinks + oneBuyLink) / total) * 100).toFixed(1);

  console.log('\n╔══════════════════════════════════════════════════════╗');
  console.log('║           AUDIT QUALITÉ BASE DORON                  ║');
  console.log(`╚══════════════════════════════════════════════════════╝`);
  console.log(`\n📦 Total produits actifs : ${total}\n`);

  console.log('━━━ 🖼️  IMAGES ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`  ✅ Bonne image HTTPS   : ${goodImage} (${pctGoodImage}%)`);
  console.log(`  ⚠️  Image HTTP (risque) : ${httpImage}`);
  console.log(`  🚫 Image placeholder   : ${badImageUrl}`);
  console.log(`  ❌ Aucune image        : ${noImage}`);
  if (noImageSamples.length > 0) {
    console.log(`\n  → Exemples sans image :`);
    noImageSamples.forEach(n => console.log(`    • ${n}`));
  }
  if (badImages.length > 0) {
    console.log(`\n  → Exemples images suspectes :`);
    badImages.forEach(b => console.log(`    • ${b.name} → ${b.url}`));
  }

  console.log('\n━━━ 🔗  LIENS D\'ACHAT (buyLinks) ━━━━━━━━━━━━━━━━━━━━━');
  console.log(`  ✅ Multi-liens (comparateur) : ${multiBuyLinks} (${pctMultiLinks}%)`);
  console.log(`  🔗 1 seul lien              : ${oneBuyLink}`);
  console.log(`  ❌ Aucun lien               : ${noBuyLinks}`);
  console.log(`  → Total avec au moins 1 lien : ${multiBuyLinks + oneBuyLink} (${pctGoodLinks}%)`);
  if (noBuyLinkSamples.length > 0) {
    console.log(`\n  → Produits sans aucun lien :`);
    noBuyLinkSamples.forEach(n => console.log(`    • ${n}`));
  }

  console.log('\n━━━ 💶  PRIX ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`  ✅ Prix renseigné : ${total - noPrice - zeroPrice}`);
  console.log(`  ⚠️  Prix = 0      : ${zeroPrice}`);
  console.log(`  ❌ Sans prix      : ${noPrice}`);

  console.log('\n━━━ 📊  VERDICT GLOBAL ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  const score = Math.round(
    ((goodImage / total) * 40) +
    ((multiBuyLinks / total) * 40) +
    (((total - noPrice - zeroPrice) / total) * 20)
  );
  console.log(`  Score qualité : ${score}/100`);
  if (score >= 80) console.log('  🟢 Base en très bon état');
  else if (score >= 60) console.log('  🟡 Base correcte — améliorations possibles');
  else console.log('  🔴 Base à améliorer');

  console.log('\n');
  process.exit(0);
}

deepAudit().catch(e => { console.error(e.message); process.exit(1); });
