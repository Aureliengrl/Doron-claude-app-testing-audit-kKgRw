/**
 * image_fixer_sephora_fnac.js — Extraire les images depuis Sephora et Fnac
 * ============================================================================
 * Sephora : CDN images = https://www.sephora.fr/dw/image/v2/.../P{id}.jpg
 * Fnac    : OG image disponible via un User-Agent spécifique
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

// Fait une requête GET et retourne le HTML
function getPage(url, extraHeaders = {}) {
  return new Promise(resolve => {
    try {
      const u = new URL(url);
      const req = https.get({
        host: u.hostname,
        path: u.pathname + u.search,
        timeout: 12000,
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
          'Accept': 'text/html,application/xhtml+xml',
          'Accept-Language': 'fr-FR,fr;q=0.9',
          ...extraHeaders,
        },
      }, res => {
        // Suivre les redirections
        if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
          const newUrl = res.headers.location.startsWith('http') ? res.headers.location : `https://${u.hostname}${res.headers.location}`;
          resolve(getPage(newUrl, extraHeaders));
          return;
        }
        let html = '';
        res.setEncoding('utf8');
        res.on('data', c => { html += c; if (html.length > 120000) req.destroy(); });
        res.on('end', () => resolve(html));
        res.on('error', () => resolve(''));
      });
      req.on('timeout', () => { req.destroy(); resolve(''); });
      req.on('error', () => resolve(''));
    } catch { resolve(''); }
  });
}

function extractImageFromHtml(html) {
  // og:image
  let m = html.match(/property=["']og:image["'][^>]*content=["']([^"']+)["']/i)
           || html.match(/content=["']([^"']+)["'][^>]*property=["']og:image["']/i);
  if (m && m[1].startsWith('https')) return m[1];
  
  // twitter:image
  m = html.match(/name=["']twitter:image["'][^>]*content=["']([^"']+)["']/i)
      || html.match(/content=["']([^"']+)["'][^>]*name=["']twitter:image["']/i);
  if (m && m[1].startsWith('https')) return m[1];
  
  // JSON-LD
  m = html.match(/"image"\s*:\s*["']?(https?:\/\/[^"',\s\]]+\.(?:jpg|jpeg|png|webp))["']?/i);
  if (m) return m[1];

  // data-src ou src dans une image produit
  m = html.match(/data-(?:src|original|lazy)=["'](https:\/\/[^"']+\.(?:jpg|jpeg|png|webp)[^"']*)["']/i);
  if (m) return m[1];

  return null;
}

// Sephora a un CDN avec un ID produit dans l'URL → extraire le code P10xxxxxxx
function extractSephoraImage(pageUrl, html) {
  // Chercher l'image produit Sephora spécifiquement
  const patterns = [
    // CDN Sephora direct
    /(https:\/\/www\.sephora\.fr\/dw\/image\/v2\/BCWB_PRD\/[^"']+\.(?:jpg|png|webp))/i,
    // Images media3.sephora
    /(https:\/\/media3\.sephora\.fr\/[^"'\s]+\.(?:jpg|png|webp))/i,
    // Extracteur générique
  ];
  for (const p of patterns) {
    const m = html.match(p);
    if (m) return m[1].split('?')[0];
  }
  return extractImageFromHtml(html);
}

async function main() {
  console.log('\n╔══════════════════════════════════════════════════════╗');
  console.log('║  🖼️  IMAGE FIXER — Sephora + Fnac + Marques        ║');
  console.log(`║  Mode: ${DRY_RUN ? 'DRY RUN' : 'LIVE'}                                     ║`);
  console.log('╚══════════════════════════════════════════════════════╝\n');

  const snap = await db.collection('gifts').where('active', '==', true).get();
  
  const toFix = [];
  snap.forEach(doc => {
    const d   = doc.data();
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
      if (!link || !link.startsWith('https')) continue;
      
      let hostname = '';
      try { hostname = new URL(link).hostname; } catch { continue; }
      
      console.log(`  🌐 Scraping ${hostname}...`);
      const html = await getPage(link);
      
      if (!html) { await sleep(500); continue; }

      // Sephora : chercher l'image CDN spécifique
      if (hostname.includes('sephora')) {
        newImg = extractSephoraImage(link, html);
      } else {
        newImg = extractImageFromHtml(html);
      }

      if (newImg && newImg.startsWith('https')) {
        console.log(`  ✅ Image: ${newImg.substring(0, 90)}`);
        break;
      } else {
        newImg = null;
      }
      await sleep(800);
    }

    if (newImg) {
      if (!DRY_RUN) {
        await db.collection('gifts').doc(doc.id).update({
          image: newImg, imageUrl: newImg,
          imageFixed: true, imageSource: 'image_fixer_shops',
          imageFixedAt: new Date().toISOString(),
        });
      }
      console.log(`  💾 Sauvegardé${DRY_RUN ? ' (dry-run)' : ''}`);
      fixed++;
    } else {
      console.log(`  ❌ "${name}" → toujours sans image`);
      stillMissing.push({ name, brand: d.brand || '', url: allLinks[0] || '' });
    }

    await sleep(1000);
  }

  console.log('\n╔══════════════════════════════════════════════════════╗');
  console.log(`║  ✅ Corrigés  : ${String(fixed).padEnd(40)}║`);
  console.log(`║  ❌ Restants  : ${String(stillMissing.length).padEnd(40)}║`);
  console.log('╚══════════════════════════════════════════════════════╝');

  if (stillMissing.length > 0) {
    console.log('\n🚨 Produits à corriger manuellement :');
    stillMissing.forEach((p, idx) => console.log(`  ${idx+1}. ${p.brand ? p.brand+' — ' : ''}${p.name}`));
  }
  process.exit(0);
}
main().catch(e => { console.error(e.message); process.exit(1); });
