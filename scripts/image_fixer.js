/**
 * image_fixer.js — Fixe les images manquantes ou HTTP dans la base Doron
 * =========================================================================
 * Stratégies (sans Claude, sans API) :
 *   1. Produits Amazon (ont un ASIN) → image direct depuis CDN Amazon standard
 *   2. HTTP → forcer HTTPS (le plus simple, 95% des cas)
 *   3. Sans image → extraire l'image depuis la page de vente (scraping léger)
 *   4. Fallback → Open Graph image de la page produit
 */

const admin   = require('firebase-admin');
const https   = require('https');
const http    = require('http');
const { URL } = require('url');
require('dotenv').config();

const sa = require('./serviceAccountKey.json');
if (!admin.apps.length) admin.initializeApp({ credential: admin.credential.cert(sa) });
const db = admin.firestore();

const DRY_RUN = process.argv.includes('--dry-run');
const FORCE   = process.argv.includes('--force');

const sleep = ms => new Promise(r => setTimeout(r, ms));

// ─── Extraire ASIN depuis une URL Amazon ─────────────────────────────────────
function extractAsin(url) {
  if (!url) return null;
  const m = url.match(/\/(?:dp|gp\/product|ASIN)\/([A-Z0-9]{10})/i);
  return m ? m[1] : null;
}

// ─── URL image Amazon HD depuis ASIN ─────────────────────────────────────────
function amazonImageUrl(asin, size = 'SL600') {
  // Format CDN Amazon public standard
  return `https://m.media-amazon.com/images/I/${asin}._${size}_.jpg`;
}

// Fallback : pattern 2 (via images-na)
function amazonImageUrl2(asin) {
  return `https://images-na.ssl-images-amazon.com/images/P/${asin}.jpg`;
}

// ─── Vérifier qu'une URL image est valide (HEAD request) ─────────────────────
function checkUrl(url, timeout = 6000) {
  return new Promise(resolve => {
    try {
      const u = new URL(url);
      const mod = u.protocol === 'https:' ? https : http;
      const req = mod.request({ method: 'HEAD', host: u.hostname, path: u.pathname + u.search, timeout }, res => {
        const ok = res.statusCode >= 200 && res.statusCode < 400;
        resolve({ ok, status: res.statusCode, contentType: res.headers['content-type'] || '' });
      });
      req.on('timeout', () => { req.destroy(); resolve({ ok: false, status: 0 }); });
      req.on('error', () => resolve({ ok: false, status: 0 }));
      req.end();
    } catch { resolve({ ok: false, status: 0 }); }
  });
}

// ─── Scraper l'OG:image d'une page produit ───────────────────────────────────
function scrapeOgImage(pageUrl, timeout = 8000) {
  return new Promise(resolve => {
    try {
      const u = new URL(pageUrl);
      const mod = u.protocol === 'https:' ? https : http;
      const req = mod.get({ host: u.hostname, path: u.pathname + u.search, timeout,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/120 Safari/537.36',
          'Accept': 'text/html',
        }
      }, res => {
        let html = '';
        res.setEncoding('utf8');
        res.on('data', chunk => {
          html += chunk;
          // On arrête après 60kb pour économiser
          if (html.length > 60000) req.destroy();
        });
        res.on('end', () => {
          // Chercher og:image
          let m = html.match(/property=["']og:image["'][^>]*content=["']([^"']+)["']/i)
                || html.match(/content=["']([^"']+)["'][^>]*property=["']og:image["']/i);
          if (m) { resolve(m[1]); return; }
          // Chercher twitter:image
          m = html.match(/name=["']twitter:image["'][^>]*content=["']([^"']+)["']/i)
            || html.match(/content=["']([^"']+)["'][^>]*name=["']twitter:image["']/i);
          if (m) { resolve(m[1]); return; }
          // Chercher la première image grande dans le HTML
          m = html.match(/https:\/\/[^"'\s]+\.(?:jpg|jpeg|png|webp)(?:\?[^"'\s]*)?/gi);
          const imgs = (m || []).filter(u => !u.includes('logo') && !u.includes('icon') && !u.includes('sprite'));
          resolve(imgs[0] || null);
        });
        res.on('error', () => resolve(null));
      });
      req.on('timeout', () => { req.destroy(); resolve(null); });
      req.on('error', () => resolve(null));
    } catch { resolve(null); }
  });
}

// ─── MAIN ─────────────────────────────────────────────────────────────────────
async function main() {
  console.log('\n╔══════════════════════════════════════════════════════╗');
  console.log('║     🖼️  IMAGE FIXER — Doron Database               ║');
  console.log(`║     Mode: ${DRY_RUN ? 'DRY RUN (aucun write)' : 'LIVE (écriture Firebase)'}               ║`);
  console.log('╚══════════════════════════════════════════════════════╝\n');

  const snap = await db.collection('gifts').where('active', '==', true).get();
  
  const toFix = [];
  snap.forEach(doc => {
    const d = doc.data();
    const img = d.image || d.imageUrl || '';
    const needsFix = !img || img.startsWith('http://') || (FORCE && img);
    if (needsFix) toFix.push(doc);
  });

  console.log(`📦 Produits à corriger : ${toFix.length}\n`);

  let fixed = 0, failed = 0, httpsOnly = 0;

  for (let i = 0; i < toFix.length; i++) {
    const doc = toFix[i];
    const d   = doc.data();
    const name  = d.name || d.product_title || doc.id;
    const brand = d.brand || '';
    const currentImg = d.image || d.imageUrl || '';
    const existingUrl = d.url || d.product_url || (d.buyLinks?.[0]?.url) || '';

    console.log(`\n[${i+1}/${toFix.length}] "${name}"`);

    let newImageUrl = null;

    // ── Stratégie 1 : HTTP → HTTPS (trivial, prioritaire) ──────────────────
    if (currentImg && currentImg.startsWith('http://')) {
      const httpsVersion = currentImg.replace('http://', 'https://');
      const check = await checkUrl(httpsVersion);
      if (check.ok && check.contentType.includes('image')) {
        newImageUrl = httpsVersion;
        console.log(`  ✅ HTTP→HTTPS: ${httpsVersion.substring(0, 70)}`);
        httpsOnly++;
      }
    }

    // ── Stratégie 2 : ASIN Amazon → image CDN direct ───────────────────────
    if (!newImageUrl) {
      // Chercher un ASIN dans tous les liens disponibles
      const allUrls = [existingUrl, ...(d.buyLinks||[]).map(l => l.url||'')].filter(Boolean);
      let asin = null;
      for (const u of allUrls) {
        asin = extractAsin(u);
        if (asin) break;
      }

      if (asin) {
        console.log(`  🔍 ASIN trouvé: ${asin}`);
        // Essayer plusieurs formats CDN Amazon
        const candidates = [
          `https://m.media-amazon.com/images/P/${asin}.jpg`,
          `https://images-eu.ssl-images-amazon.com/images/P/${asin}.jpg`,
          `https://images-na.ssl-images-amazon.com/images/P/${asin}.jpg`,
          `https://m.media-amazon.com/images/I/${asin}._SL500_.jpg`,
        ];
        for (const candidate of candidates) {
          const check = await checkUrl(candidate);
          if (check.ok) {
            newImageUrl = candidate;
            console.log(`  ✅ Image Amazon CDN: ${candidate}`);
            break;
          }
        }
      }
    }

    // ── Stratégie 3 : OG:image depuis la page de vente ─────────────────────
    if (!newImageUrl && existingUrl && existingUrl.startsWith('https')) {
      console.log(`  🌐 Scraping OG:image depuis ${new URL(existingUrl).hostname}...`);
      const ogImg = await scrapeOgImage(existingUrl);
      if (ogImg && ogImg.startsWith('https')) {
        const check = await checkUrl(ogImg);
        if (check.ok && (check.contentType.includes('image') || ogImg.match(/\.(jpg|jpeg|png|webp)/i))) {
          newImageUrl = ogImg;
          console.log(`  ✅ OG:image trouvée: ${ogImg.substring(0, 80)}`);
        }
      }
    }

    // ── Stratégie 4 : essayer les buyLinks un par un ────────────────────────
    if (!newImageUrl && d.buyLinks && d.buyLinks.length > 0) {
      for (const link of d.buyLinks) {
        if (!link.url || !link.url.startsWith('https')) continue;
        console.log(`  🌐 Scraping ${new URL(link.url).hostname}...`);
        const ogImg = await scrapeOgImage(link.url);
        if (ogImg && ogImg.startsWith('https')) {
          newImageUrl = ogImg;
          console.log(`  ✅ Image depuis buyLink: ${ogImg.substring(0, 80)}`);
          break;
        }
        await sleep(300);
      }
    }

    // ── Résultat ──────────────────────────────────────────────────────────────
    if (newImageUrl) {
      if (!DRY_RUN) {
        await db.collection('gifts').doc(doc.id).update({
          image:       newImageUrl,
          imageUrl:    newImageUrl,
          imageFixed:  true,
          imageSource: 'image_fixer',
          imageFixedAt: new Date().toISOString(),
        });
      }
      console.log(`  💾 Sauvegardé${DRY_RUN ? ' (dry-run)' : ''}`);
      fixed++;
    } else {
      console.log(`  ❌ Aucune image trouvée pour "${name}"`);
      failed++;
    }

    await sleep(400);
  }

  console.log('\n╔══════════════════════════════════════════════════════╗');
  console.log(`║  ✅ Corrigés  : ${String(fixed).padEnd(4)} (dont ${httpsOnly} HTTP→HTTPS) ║`);
  console.log(`║  ❌ Échecs    : ${String(failed).padEnd(35)}║`);
  console.log('╚══════════════════════════════════════════════════════╝\n');

  process.exit(0);
}

main().catch(e => { console.error(e.message); process.exit(1); });
