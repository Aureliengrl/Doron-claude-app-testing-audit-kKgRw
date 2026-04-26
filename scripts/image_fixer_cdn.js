/**
 * image_fixer_cdn.js — Injecte les images directement depuis les CDN
 * ====================================================================
 * Sephora : https://www.sephora.fr/dw/image/v2/BCWB_PRD/on/demandware.static/
 *           /-/Sites-sephora-fr-master/default/images/large/{productId}.jpg
 *           L'ID est dans l'URL : /p/nom-produit-P10029107.html → P10029107
 *
 * Fnac :    https://media.fnac.com/Images/{id}/{id}_h300.jpg
 *           L'ID est dans l'URL : /a18000030 → 18000030
 *
 * Autres : construire depuis l'URL de chaque marque connue
 */

const admin   = require('firebase-admin');
const https   = require('https');
const { URL } = require('url');
require('dotenv').config();

const sa = require('./serviceAccountKey.json');
if (!admin.apps.length) admin.initializeApp({ credential: admin.credential.cert(sa) });
const db = admin.firestore();

const DRY_RUN = process.argv.includes('--dry-run');
const sleep   = ms => new Promise(r => setTimeout(r, ms));

function checkImageUrl(url) {
  return new Promise(resolve => {
    try {
      const u = new URL(url);
      const req = https.request({ method: 'HEAD', host: u.hostname, path: u.pathname + u.search, timeout: 8000,
        headers: { 'User-Agent': 'Mozilla/5.0' }
      }, res => {
        resolve(res.statusCode >= 200 && res.statusCode < 400 ? url : null);
      });
      req.on('timeout', () => { req.destroy(); resolve(null); });
      req.on('error', () => resolve(null));
      req.end();
    } catch { resolve(null); }
  });
}

// ─── Sephora: extraire le productId de l'URL ─────────────────────────────────
function getSephoraImageUrl(pageUrl) {
  // URL pattern: /p/nom-produit-P10029107.html
  const m = pageUrl.match(/[_-](P\d{7,9})(?:\.html|$)/i);
  if (!m) return null;
  const pid = m[1]; // ex: P10029107
  
  // Sephora CDN patterns (à tester dans l'ordre)
  return [
    `https://www.sephora.fr/dw/image/v2/BCWB_PRD/on/demandware.static/-/Sites-sephora-fr-master/default/images/large/${pid}.jpg`,
    `https://www.sephora.fr/dw/image/v2/BCWB_PRD/on/demandware.static/-/Sites-sephora-fr-master/default/images/medium15/${pid}.jpg`,
    `https://media3.sephora.fr/imgs/products/${pid}.jpg`,
  ];
}

// ─── Fnac: extraire le productId de l'URL ────────────────────────────────────
function getFnacImageUrls(pageUrl) {
  // URL pattern: /a18000030 ou /a2488008
  const m = pageUrl.match(/\/a(\d{5,9})(?:\/|$|-)/);
  if (!m) return null;
  const id = m[1];
  return [
    `https://media.fnac.com/Images/${id}/${id}_h300.jpg`,
    `https://media.fnac.com/Images/${id}/${id}_h500.jpg`,
    `https://media.fnac.com/Images/${id}/${id}.jpg`,
  ];
}

// ─── Patterns CDN par marque ──────────────────────────────────────────────────
function getBrandCdnUrls(pageUrl, name) {
  const slug = name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/-+/g, '-').replace(/^-|-$/g, '');
  
  try {
    const u = new URL(pageUrl);
    const host = u.hostname;
    const path = u.pathname;
    
    // Veja : /fr/produit/campo-chromefree-CF0301719A.html
    if (host.includes('veja-store')) {
      const ref = path.split('/').pop().split('.')[0]; // CF0301719A
      return [
        `https://www.veja-store.com/media/catalog/product/${ref[0]}/${ref[1]}/${ref}.jpg`,
        `https://www.veja-store.com/media/catalog/product/cache/1/${ref}.jpg`,
      ];
    }
    
    // HAY
    if (host.includes('hay.com')) {
      return [`https://dam.hay.com/is/image/hay/${slug}?wid=540`];
    }
    
    // Jacquemus - CDN Shopify
    if (host.includes('jacquemus')) {
      return [
        `https://cdn.shopify.com/s/files/1/0266/0738/products/${slug}.jpg`,
        `https://www.jacquemus.com/dw/image/v2/BBPH_PRD/on/demandware.static/-/Sites/default/images/${slug}.jpg`,
      ];
    }
    
    // On Running
    if (host.includes('on-running')) {
      const productPath = path.split('/products/').pop();
      return [`https://www.on-running.com/on/pictures/womens/${productPath}.jpg`];
    }
    
    // Muuto
    if (host.includes('muuto')) {
      const productSlug = path.split('/').pop();
      return [`https://www.muuto.com/media/img/products/${productSlug}.jpg`];
    }
    
    // ferm LIVING
    if (host.includes('fermliving')) {
      const productSlug = path.split('/products/').pop();
      return [`https://www.fermliving.com/media/catalog/product/${productSlug}.jpg`];
    }
    
    // Isabel Marant
    if (host.includes('isabelmarant')) {
      return [`https://www.isabelmarant.com/dw/image/v2/BGRY_PRD/on/demandware.static/-/Sites-isabelmarant-master/default/images/large/${slug}.jpg`];
    }
    
    // Gorjana
    if (host.includes('gorjana')) {
      const handle = path.split('/products/').pop().split('?')[0];
      return [
        `https://cdn.shopify.com/s/files/1/0279/7076/products/${handle}.jpg`,
        `https://gorjana.com/cdn/shop/products/${handle}.jpg`,
        `https://cdn.shopify.com/s/files/1/0279/7076/products/gorjana-${handle}.jpg`,
      ];
    }
    
    // Maisons du Monde
    if (host.includes('maisonsdumonde')) {
      const ref = path.split('/').find(p => /^\d+/.test(p)) || slug;
      return [`https://www.maisonsdumonde.com/cdn/images/product_500x500/${ref}.jpg`];
    }
    
  } catch {}
  
  return null;
}

async function main() {
  console.log('\n╔══════════════════════════════════════════════════════╗');
  console.log('║  🖼️  IMAGE FIXER CDN — Sephora/Fnac/Marques        ║');
  console.log(`║  Mode: ${DRY_RUN ? 'DRY RUN' : 'LIVE'}                                     ║`);
  console.log('╚══════════════════════════════════════════════════════╝\n');

  const snap = await db.collection('gifts').where('active', '==', true).get();
  const toFix = [];
  snap.forEach(doc => {
    const d = doc.data();
    const img = (d.image || d.imageUrl || '').trim();
    if (!img || img.startsWith('http://')) {
      const allLinks = [(d.url || d.product_url || ''), ...(d.buyLinks||[]).map(l => l.url||'')].filter(Boolean);
      toFix.push({ doc, d, allLinks });
    }
  });

  console.log(`📦 Produits à corriger : ${toFix.length}\n`);
  let fixed = 0; const stillMissing = [];

  for (let i = 0; i < toFix.length; i++) {
    const { doc, d, allLinks } = toFix[i];
    const name = d.name || doc.id;
    console.log(`\n[${i+1}/${toFix.length}] "${name}"`);

    let newImg = null;

    for (const link of allLinks) {
      if (!link) continue;
      
      let candidateUrls = [];
      
      // Sephora
      if (link.includes('sephora')) {
        const urls = getSephoraImageUrl(link);
        if (urls) candidateUrls = urls;
      }
      // Fnac
      else if (link.includes('fnac.com')) {
        const urls = getFnacImageUrls(link);
        if (urls) candidateUrls = urls;
      }
      // Autres marques
      else {
        const urls = getBrandCdnUrls(link, name);
        if (urls) candidateUrls = urls;
      }

      for (const candidate of candidateUrls) {
        console.log(`  🔍 Test: ${candidate.substring(0, 80)}`);
        const ok = await checkImageUrl(candidate);
        if (ok) {
          newImg = ok;
          console.log(`  ✅ Found!`);
          break;
        }
        await sleep(200);
      }
      
      if (newImg) break;
    }

    if (newImg) {
      if (!DRY_RUN) {
        await db.collection('gifts').doc(doc.id).update({
          image: newImg, imageUrl: newImg,
          imageFixed: true, imageSource: 'image_fixer_cdn',
          imageFixedAt: new Date().toISOString(),
        });
      }
      console.log(`  💾 Sauvegardé${DRY_RUN ? ' (dry-run)' : ''}`);
      fixed++;
    } else {
      console.log(`  ❌ "${name}"`);
      stillMissing.push({ name, brand: d.brand || '' });
    }

    await sleep(300);
  }

  console.log('\n╔══════════════════════════════════════════════════════╗');
  console.log(`║  ✅ Corrigés  : ${String(fixed).padEnd(40)}║`);
  console.log(`║  ❌ Restants  : ${String(stillMissing.length).padEnd(40)}║`);
  console.log('╚══════════════════════════════════════════════════════╝');
  if (stillMissing.length > 0) {
    console.log('\n🔧 Produits à corriger via Admin UI :');
    stillMissing.forEach((p, i) => console.log(`  ${i+1}. ${p.brand ? p.brand+' — ' : ''}${p.name}`));
  }
  process.exit(0);
}
main().catch(e => { console.error(e.message); process.exit(1); });
