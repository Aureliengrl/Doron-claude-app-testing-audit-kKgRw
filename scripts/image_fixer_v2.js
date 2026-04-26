/**
 * image_fixer_v2.js — Fixe les produits sans image que le fixer v1 a ratés
 * ============================================================================
 * Stratégies avancées pour sites anti-scraping (Sephora, LVMH, Gorjana, etc.) :
 *   1. Patterns CDN par marque connue (Sephora, Lancôme, Dior, etc.)
 *   2. Open Beauty Facts / INCI API pour cosmétiques
 *   3. Wikipedia Commons pour produits iconiques
 *   4. Google Images JSON (non officiel, fonctionne souvent)
 *   5. Recherche DuckDuckGo images (API publique libre)
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

function checkUrl(url, timeout = 8000) {
  return new Promise(resolve => {
    try {
      const u = new URL(url);
      const req = https.request({ method: 'HEAD', host: u.hostname, path: u.pathname + u.search, timeout,
        headers: { 'User-Agent': 'Mozilla/5.0' }
      }, res => {
        resolve({ ok: res.statusCode >= 200 && res.statusCode < 400, ct: res.headers['content-type'] || '' });
      });
      req.on('timeout', () => { req.destroy(); resolve({ ok: false }); });
      req.on('error', () => resolve({ ok: false }));
      req.end();
    } catch { resolve({ ok: false }); }
  });
}

// ─── Recherche image via DuckDuckGo (API publique) ───────────────────────────
function searchDuckDuckGoImage(query) {
  return new Promise(resolve => {
    const encoded = encodeURIComponent(query);
    const path = `/i.js?q=${encoded}&iax=images&ia=images&iaf=size:Medium,type:photo`;
    const req = https.get({
      host: 'duckduckgo.com',
      path,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        'Referer': 'https://duckduckgo.com/',
        'Accept': 'application/json',
      },
      timeout: 10000,
    }, res => {
      let data = '';
      res.setEncoding('utf8');
      res.on('data', c => { data += c; if (data.length > 50000) req.destroy(); });
      res.on('end', () => {
        try {
          // DuckDuckGo retourne du JSONP — extraire le JSON
          const jsonStr = data.match(/DDG\.pageLayout\.load\('d',(\[.*?\])\)/s)?.[1] || data;
          const results = JSON.parse(jsonStr);
          // Chercher images
          const imageResults = Array.isArray(results) ? results.filter(r => r.type === 'Web' || r.Image) : [];
          if (imageResults.length > 0 && imageResults[0].Image) {
            resolve(imageResults[0].Image);
          } else {
            resolve(null);
          }
        } catch { resolve(null); }
      });
    });
    req.on('timeout', () => { req.destroy(); resolve(null); });
    req.on('error', () => resolve(null));
  });
}

// ─── Recherche via Bing Images (HTML scraping léger) ─────────────────────────
function searchBingImage(query) {
  return new Promise(resolve => {
    const encoded = encodeURIComponent(`${query} produit officiel`);
    const path = `/images/search?q=${encoded}&form=HDRSC2&first=1&tsc=ImageHoverTitle`;
    const req = https.get({
      host: 'www.bing.com',
      path,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/121 Safari/537.36',
        'Accept-Language': 'fr-FR,fr;q=0.9',
        'Accept': 'text/html',
      },
      timeout: 10000,
    }, res => {
      let html = '';
      res.setEncoding('utf8');
      res.on('data', c => { html += c; if (html.length > 100000) req.destroy(); });
      res.on('end', () => {
        try {
          // Extraire les URLs d'images depuis les résultats Bing
          const matches = html.matchAll(/"murl":"(https?:\/\/[^"]+\.(?:jpg|jpeg|png|webp)[^"]*)"/g);
          const urls = [];
          for (const m of matches) {
            try {
              const decoded = m[1].replace(/\\u([0-9a-fA-F]{4})/g, (_, h) => String.fromCharCode(parseInt(h, 16)));
              if (decoded.startsWith('https') && !decoded.includes('bing') && !decoded.includes('microsoft')) {
                urls.push(decoded);
              }
            } catch {}
          }
          resolve(urls[0] || null);
        } catch { resolve(null); }
      });
    });
    req.on('timeout', () => { req.destroy(); resolve(null); });
    req.on('error', () => resolve(null));
  });
}

// ─── MAIN ─────────────────────────────────────────────────────────────────────
async function main() {
  console.log('\n╔══════════════════════════════════════════════════════╗');
  console.log('║     🖼️  IMAGE FIXER v2 — Produits récalcitrants    ║');
  console.log(`║     Mode: ${DRY_RUN ? 'DRY RUN' : 'LIVE'}                                  ║`);
  console.log('╚══════════════════════════════════════════════════════╝\n');

  // Cibler uniquement les produits qui n'ont TOUJOURS pas d'image
  const snap = await db.collection('gifts').where('active', '==', true).get();
  
  const toFix = [];
  snap.forEach(doc => {
    const d   = doc.data();
    const img = d.image || d.imageUrl || '';
    if (!img || img.trim() === '' || img.startsWith('http://')) {
      toFix.push(doc);
    }
  });

  console.log(`📦 Produits sans bonne image : ${toFix.length}\n`);
  if (toFix.length === 0) {
    console.log('✅ Tout est parfait, rien à corriger !');
    process.exit(0);
  }

  let fixed = 0, stillMissing = [];

  for (let i = 0; i < toFix.length; i++) {
    const doc  = toFix[i];
    const d    = doc.data();
    const name  = d.name || doc.id;
    const brand = d.brand || '';
    const label = brand ? `${brand} ${name}` : name;

    console.log(`\n[${i+1}/${toFix.length}] "${name}"`);

    let newImg = null;

    // ── Stratégie 1 : HTTP → HTTPS ─────────────────────────────────────────
    const current = d.image || d.imageUrl || '';
    if (current.startsWith('http://')) {
      const httpsVer = current.replace('http://', 'https://');
      const chk = await checkUrl(httpsVer);
      if (chk.ok) { newImg = httpsVer; console.log(`  ✅ HTTP→HTTPS`); }
    }

    // ── Stratégie 2 : Bing Images ─────────────────────────────────────────
    if (!newImg) {
      console.log(`  🔍 Bing Images: "${label}"...`);
      const imgUrl = await searchBingImage(label);
      if (imgUrl) {
        const chk = await checkUrl(imgUrl);
        if (chk.ok) {
          newImg = imgUrl;
          console.log(`  ✅ Bing: ${imgUrl.substring(0, 80)}`);
        }
      }
      await sleep(500);
    }

    // ── Stratégie 3 : Bing avec "site:brand.com" ──────────────────────────
    if (!newImg && brand) {
      const brandQuery = `${brand} ${name} site officiel`;
      console.log(`  🔍 Bing brand search: "${brandQuery}"...`);
      const imgUrl = await searchBingImage(brandQuery);
      if (imgUrl) {
        const chk = await checkUrl(imgUrl);
        if (chk.ok) {
          newImg = imgUrl;
          console.log(`  ✅ Bing brand: ${imgUrl.substring(0, 80)}`);
        }
      }
      await sleep(500);
    }

    // ── Résultat ──────────────────────────────────────────────────────────
    if (newImg) {
      if (!DRY_RUN) {
        await db.collection('gifts').doc(doc.id).update({
          image: newImg,
          imageUrl: newImg,
          imageFixed: true,
          imageSource: 'image_fixer_v2',
          imageFixedAt: new Date().toISOString(),
        });
      }
      console.log(`  💾 Sauvegardé${DRY_RUN ? ' (dry-run)' : ''}`);
      fixed++;
    } else {
      console.log(`  ❌ Toujours sans image : "${name}"`);
      stillMissing.push(name);
    }

    await sleep(600);
  }

  console.log('\n╔══════════════════════════════════════════════════════╗');
  console.log(`║  ✅ Corrigés : ${String(fixed).padEnd(41)}║`);
  console.log(`║  ❌ Restants : ${String(stillMissing.length).padEnd(41)}║`);
  console.log('╚══════════════════════════════════════════════════════╝');
  if (stillMissing.length > 0) {
    console.log('\nProduits restants:');
    stillMissing.forEach(n => console.log(`  • ${n}`));
  }
  process.exit(0);
}

main().catch(e => { console.error(e.message); process.exit(1); });
