/**
 * image_fixer_v3.js — Stratégie ultra-rapide sans scraping anti-bot
 * ===================================================================
 * Pour les 81 produits récalcitrants, on utilise :
 *   1. Wikimedia/Wikipedia image search (API publique gratuite)
 *   2. Open Library covers (pour livres)
 *   3. Reconstruction URL depuis ASIN detecté dans les liens
 *   4. Itsdagram / Pinterest open data
 *   5. Fallback : URL construite à partir des métadonnées du produit
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

function get(url, opts = {}) {
  return new Promise(resolve => {
    try {
      const u = new URL(url);
      const req = https.get({
        host: u.hostname,
        path: u.pathname + u.search,
        timeout: opts.timeout || 10000,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/121 Safari/537.36',
          'Accept': opts.accept || '*/*',
          'Accept-Language': 'fr-FR,fr;q=0.9',
          ...opts.headers,
        },
      }, res => {
        let data = '';
        res.setEncoding('utf8');
        res.on('data', c => { data += c; if (data.length > (opts.maxLen || 200000)) req.destroy(); });
        res.on('end', () => resolve({ status: res.statusCode, body: data, headers: res.headers }));
        res.on('error', () => resolve(null));
      });
      req.on('timeout', () => { req.destroy(); resolve(null); });
      req.on('error', () => resolve(null));
    } catch { resolve(null); }
  });
}

function checkImageUrl(url) {
  return new Promise(resolve => {
    try {
      const u = new URL(url);
      const req = https.request({ method: 'HEAD', host: u.hostname, path: u.pathname + u.search, timeout: 6000,
        headers: { 'User-Agent': 'Mozilla/5.0' }
      }, res => {
        const ok = res.statusCode >= 200 && res.statusCode < 400;
        const ct = res.headers['content-type'] || '';
        resolve(ok && (ct.includes('image') || url.match(/\.(jpg|jpeg|png|webp|gif)/i)) ? url : null);
      });
      req.on('timeout', () => { req.destroy(); resolve(null); });
      req.on('error', () => resolve(null));
      req.end();
    } catch { resolve(null); }
  });
}

// ─── Wikipedia Image Search ───────────────────────────────────────────────────
async function searchWikipediaImage(query) {
  const encoded = encodeURIComponent(query);
  const res = await get(`https://en.wikipedia.org/w/api.php?action=query&titles=${encoded}&prop=pageimages&format=json&pithumbsize=500&pilimit=1&redirects=1`, { maxLen: 10000 });
  if (!res) return null;
  try {
    const data = JSON.parse(res.body);
    const pages = data.query?.pages || {};
    for (const page of Object.values(pages)) {
      if (page.thumbnail?.source) return page.thumbnail.source;
    }
  } catch {}
  return null;
}

// ─── Amazon ASIN → image CDN (essai multi-format) ────────────────────────────
async function tryAmazonAsin(asin) {
  const patterns = [
    `https://m.media-amazon.com/images/P/${asin}.jpg`,
    `https://images-eu.ssl-images-amazon.com/images/P/${asin}.jpg`,
    `https://images-na.ssl-images-amazon.com/images/P/${asin}.jpg`,
  ];
  for (const url of patterns) {
    const ok = await checkImageUrl(url);
    if (ok) return url;
    await sleep(100);
  }
  return null;
}

function extractAsin(url) {
  if (!url) return null;
  const m = url.match(/\/(?:dp|gp\/product|ASIN|product)\/([A-Z0-9]{10})/i);
  return m ? m[1] : null;
}

// ─── Cherche image via Open Graph sur différentes URLs ───────────────────────
async function tryDirectBrandUrls(name, brand) {
  // Construire des URLs possibles basées sur le nom
  const nameLower = name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/-+/g, '-').trim();
  const brandLower = (brand || '').toLowerCase();
  
  // Patterns spéciaux pour marques connues
  const brandPatterns = {
    'sephora': `https://www.sephora.fr/dw/image/v2/BCWB_PRD/on/demandware.static/-/Sites-sephora-fr-master/default/images/large/${nameLower}.jpg`,
    'gorjana': `https://gorjana.com/cdn/shop/products/${nameLower}.jpg`,
    'isabel marant': `https://www.isabelmarant.com/on/demandware.static/-/Sites/default/images/large/${nameLower}.jpg`,
    'lululemon': null, // handled by ASIN
    'new balance': null, // handled by ASIN
  };
  
  for (const [brand_key, pattern] of Object.entries(brandPatterns)) {
    if (brandLower.includes(brand_key) && pattern) {
      const ok = await checkImageUrl(pattern);
      if (ok) return ok;
    }
  }
  return null;
}

// ─── MAIN ─────────────────────────────────────────────────────────────────────
async function main() {
  console.log('\n╔══════════════════════════════════════════════════════╗');
  console.log('║  🖼️  IMAGE FIXER v3 — Wikipedia + ASIN + Smart     ║');
  console.log(`║  Mode: ${DRY_RUN ? 'DRY RUN' : 'LIVE'}                                     ║`);
  console.log('╚══════════════════════════════════════════════════════╝\n');

  const snap = await db.collection('gifts').where('active', '==', true).get();
  
  const toFix = [];
  snap.forEach(doc => {
    const d = doc.data();
    const img = (d.image || d.imageUrl || '').trim();
    if (!img || img.startsWith('http://')) toFix.push(doc);
  });

  console.log(`📦 Produits à traiter : ${toFix.length}\n`);
  if (toFix.length === 0) { console.log('✅ Tout est parfait !'); process.exit(0); }

  let fixed = 0;
  const stillMissing = [];

  for (let i = 0; i < toFix.length; i++) {
    const doc   = toFix[i];
    const d     = doc.data();
    const name  = d.name || doc.id;
    const brand = d.brand || d.source || '';
    const label = brand ? `${brand} ${name}` : name;

    const currentImg = d.image || d.imageUrl || '';
    const allUrls = [d.url, d.product_url, ...(d.buyLinks||[]).map(l => l.url||'')].filter(Boolean);

    console.log(`\n[${i+1}/${toFix.length}] "${name}"`);
    let newImg = null;

    // Strat 1 : HTTP→HTTPS
    if (!newImg && currentImg.startsWith('http://')) {
      newImg = await checkImageUrl(currentImg.replace('http://', 'https://'));
      if (newImg) console.log('  ✅ HTTP→HTTPS');
    }

    // Strat 2 : ASIN → Amazon CDN
    if (!newImg) {
      for (const u of allUrls) {
        const asin = extractAsin(u);
        if (asin) {
          console.log(`  🔍 ASIN: ${asin}`);
          newImg = await tryAmazonAsin(asin);
          if (newImg) { console.log(`  ✅ Amazon CDN: ${newImg}`); break; }
        }
      }
    }

    // Strat 3 : Wikipedia
    if (!newImg) {
      console.log(`  🌐 Wikipedia: "${label}"...`);
      newImg = await searchWikipediaImage(label) || await searchWikipediaImage(name);
      if (newImg) console.log(`  ✅ Wikipedia: ${newImg.substring(0, 80)}`);
      await sleep(300);
    }

    // Strat 4 : Brand patterns
    if (!newImg) {
      newImg = await tryDirectBrandUrls(name, brand);
      if (newImg) console.log(`  ✅ Brand CDN: ${newImg.substring(0, 80)}`);
    }

    // Strat 5 : Wikipedia EN + FR
    if (!newImg && brand) {
      console.log(`  🌐 Wikipedia FR: "${brand} ${name}"...`);
      const frRes = await get(`https://fr.wikipedia.org/w/api.php?action=query&titles=${encodeURIComponent(name)}&prop=pageimages&format=json&pithumbsize=500&pilimit=1&redirects=1`, { maxLen: 10000 });
      if (frRes) {
        try {
          const data = JSON.parse(frRes.body);
          for (const page of Object.values(data.query?.pages || {})) {
            if (page.thumbnail?.source) { newImg = page.thumbnail.source; break; }
          }
        } catch {}
      }
      if (newImg) console.log(`  ✅ Wikipedia FR: ${newImg.substring(0, 80)}`);
      await sleep(300);
    }

    if (newImg) {
      if (!DRY_RUN) {
        await db.collection('gifts').doc(doc.id).update({
          image: newImg, imageUrl: newImg,
          imageFixed: true, imageSource: 'image_fixer_v3',
          imageFixedAt: new Date().toISOString(),
        });
      }
      console.log(`  💾 Sauvegardé${DRY_RUN ? ' (dry-run)' : ''}`);
      fixed++;
    } else {
      console.log(`  ❌ "${name}" → toujours sans image`);
      stillMissing.push({ name, brand, url: allUrls[0] || '' });
    }

    await sleep(400);
  }

  console.log('\n╔══════════════════════════════════════════════════════╗');
  console.log(`║  ✅ Corrigés  : ${String(fixed).padEnd(40)}║`);
  console.log(`║  ❌ Restants  : ${String(stillMissing.length).padEnd(40)}║`);
  console.log('╚══════════════════════════════════════════════════════╝');

  if (stillMissing.length > 0) {
    console.log('\n🚨 Ces produits nécessitent une image manuelle :');
    stillMissing.forEach((p, idx) => console.log(`  ${idx+1}. ${p.brand ? p.brand+' — ' : ''}${p.name}${p.url ? ' | '+p.url : ''}`));
  }

  process.exit(0);
}

main().catch(e => { console.error(e.message); process.exit(1); });
