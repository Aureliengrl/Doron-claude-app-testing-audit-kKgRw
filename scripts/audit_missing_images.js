/**
 * audit_missing_images.js — Liste détaillée des produits sans image avec leurs URLs
 * Pour comprendre pourquoi les scripts ne trouvent pas leurs images
 */
const admin = require('firebase-admin');
require('dotenv').config();
const sa = require('./serviceAccountKey.json');
if (!admin.apps.length) admin.initializeApp({ credential: admin.credential.cert(sa) });
const db = admin.firestore();

async function main() {
  const snap = await db.collection('gifts').where('active', '==', true).get();
  const missing = [];
  
  snap.forEach(doc => {
    const d = doc.data();
    const img = (d.image || d.imageUrl || '').trim();
    if (!img || img.startsWith('http://')) {
      const links = (d.buyLinks || []).map(l => l.url || '').filter(Boolean);
      const mainUrl = d.url || d.product_url || '';
      missing.push({
        id: doc.id,
        name: d.name || '',
        brand: d.brand || '',
        url: mainUrl,
        buyLinks: links,
        hasAmazon: [...links, mainUrl].some(u => u.includes('amazon')),
        domains: [...links, mainUrl].map(u => { try { return new URL(u).hostname; } catch { return ''; }}).filter(Boolean),
      });
    }
  });

  console.log(`\n🔍 ${missing.length} produits sans image HTTPS valide:\n`);
  
  // Grouper par domaine principal
  const byDomain = {};
  missing.forEach(p => {
    const dom = p.domains[0] || 'aucun lien';
    if (!byDomain[dom]) byDomain[dom] = [];
    byDomain[dom].push(p);
  });

  Object.entries(byDomain).sort((a, b) => b[1].length - a[1].length).forEach(([dom, prods]) => {
    console.log(`\n📦 ${dom} (${prods.length} produits):`);
    prods.forEach(p => {
      console.log(`  • ${p.brand ? p.brand+' — ' : ''}${p.name}`);
      if (p.buyLinks[0]) console.log(`    ${p.buyLinks[0].substring(0, 100)}`);
    });
  });

  process.exit(0);
}
main().catch(e => { console.error(e.message); process.exit(1); });
