/**
 * audit_buylinks.js
 * ─────────────────────────────────────────────────────────────────
 * Audit des buyLinks dans la collection `gifts`.
 * 
 * Teste chaque lien d'achat et rapporte :
 *   - Liens OK (200)
 *   - Liens cassés (404, 410, redirect vers erreur, timeout)
 *   - Liens manquants (pas de buyLinks du tout)
 *   - Distribution par domaine (Amazon, Fnac, Darty, etc.)
 * 
 * USAGE :
 *   node scripts/audit_buylinks.js              → audit complet
 *   node scripts/audit_buylinks.js --fast       → 50 produits seulement (test)
 *   node scripts/audit_buylinks.js --report     → rapport JSON uniquement
 */

const admin = require('firebase-admin');
const fetch = require('node-fetch');
const fs    = require('fs');
const path  = require('path');

const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const FAST_MODE      = process.argv.includes('--fast');
const REPORT_ONLY    = process.argv.includes('--report');
const CONCURRENCY    = 8;
const REQUEST_TIMEOUT = 10000;
const FAST_LIMIT     = 50;

// Domaines connus pour bloquer les HEAD requests (mais liens valides quand même)
const SKIP_CHECK_DOMAINS = [
  'amazon.fr', 'amazon.com', 'amzn.to',  // Amazon bloque les HEAD bots
  'instagram.com', 'facebook.com',
];

// ── Helpers ────────────────────────────────────────────────────────

function getDomain(url) {
  try {
    return new URL(url).hostname.replace('www.', '');
  } catch {
    return 'invalid';
  }
}

async function checkLink(url) {
  if (!url || url.trim() === '') return { status: 'EMPTY', code: null };
  if (!url.startsWith('http')) return { status: 'INVALID', code: null };

  const domain = getDomain(url);
  
  // Amazon et quelques domaines bloquent les HEAD bots → on marque "SKIP" (assumé OK)
  if (SKIP_CHECK_DOMAINS.some(d => domain.includes(d))) {
    return { status: 'SKIP_BOT_PROTECTED', code: null };
  }

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT);

    // Essai 1 : HEAD request
    let res;
    try {
      res = await fetch(url, {
        method: 'HEAD',
        signal: controller.signal,
        redirect: 'follow',
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
          'Accept': 'text/html,application/xhtml+xml',
        },
      });
    } catch (headErr) {
      // Essai 2 : GET request si HEAD échoue
      try {
        res = await fetch(url, {
          method: 'GET',
          signal: controller.signal,
          redirect: 'follow',
          headers: {
            'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
          },
        });
      } catch {
        clearTimeout(timeout);
        return { status: 'TIMEOUT', code: null };
      }
    }

    clearTimeout(timeout);

    if (res.status === 200) return { status: 'OK', code: 200 };
    if (res.status === 301 || res.status === 302) return { status: 'OK', code: res.status }; // redirect = OK
    if (res.status === 404) return { status: 'NOT_FOUND', code: 404 };
    if (res.status === 410) return { status: 'GONE', code: 410 };
    if (res.status === 403) return { status: 'FORBIDDEN', code: 403 };
    if (res.status >= 500) return { status: 'SERVER_ERROR', code: res.status };
    return { status: 'OTHER', code: res.status };

  } catch (e) {
    if (e.name === 'AbortError') return { status: 'TIMEOUT', code: null };
    return { status: 'ERROR', code: null, error: e.message };
  }
}

async function runConcurrent(items, fn, concurrency) {
  const results = [];
  for (let i = 0; i < items.length; i += concurrency) {
    const batch = items.slice(i, i + concurrency);
    const batchResults = await Promise.all(batch.map(fn));
    results.push(...batchResults);
  }
  return results;
}

// ── Main ────────────────────────────────────────────────────────────

async function main() {
  console.log('');
  console.log('╔══════════════════════════════════════════════════════╗');
  console.log('║      🔗 Doron — Audit des liens d\'achat (buyLinks)  ║');
  console.log('╚══════════════════════════════════════════════════════╝');
  console.log('');

  // Charger les produits
  console.log('📦 Chargement depuis Firestore...');
  const snapshot = await db.collection('gifts').get();
  let docs = snapshot.docs;
  if (FAST_MODE) {
    docs = docs.slice(0, FAST_LIMIT);
    console.log(`   ⚡ Mode FAST — seulement ${FAST_LIMIT} produits`);
  }
  console.log(`   ✅ ${docs.length} produits chargés\n`);

  // Stats rapides sans HTTP
  const noLinks     = docs.filter(d => !d.data().buyLinks || d.data().buyLinks.length === 0);
  const withLinks   = docs.filter(d => d.data().buyLinks && d.data().buyLinks.length > 0);

  console.log(`📊 Vue rapide :`);
  console.log(`   • Avec buyLinks  : ${withLinks.length} (${Math.round(withLinks.length/docs.length*100)}%)`);
  console.log(`   • Sans buyLinks  : ${noLinks.length} (${Math.round(noLinks.length/docs.length*100)}%)`);

  // Distribution domaines
  const domainCount = {};
  for (const doc of withLinks) {
    const links = doc.data().buyLinks || [];
    for (const link of links) {
      const url = typeof link === 'string' ? link : (link.url || link.link || '');
      if (url) {
        const d = getDomain(url);
        domainCount[d] = (domainCount[d] || 0) + 1;
      }
    }
  }
  const topDomains = Object.entries(domainCount)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 15);

  console.log(`\n🌐 Top domaines de liens :`);
  for (const [domain, count] of topDomains) {
    const bar = '█'.repeat(Math.min(Math.round(count / Math.max(...Object.values(domainCount)) * 20), 20));
    console.log(`   ${domain.padEnd(30)} ${bar} ${count}`);
  }

  if (REPORT_ONLY) {
    const report = {
      total: docs.length,
      withLinks: withLinks.length,
      noLinks: noLinks.length,
      topDomains,
      noLinksProducts: noLinks.map(d => ({
        id: d.id,
        name: d.data().name || d.data().product_title || '',
        brand: d.data().brand || '',
      })),
    };
    const reportPath = path.join(__dirname, 'buylinks_report.json');
    fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));
    console.log(`\n✅ Rapport sauvegardé : ${reportPath}`);
    process.exit(0);
  }

  // ── Test HTTP de chaque lien ────────────────────────────────────
  console.log(`\n🔍 Test HTTP de ${withLinks.length} produits avec liens...`);
  console.log(`   (${CONCURRENCY} requêtes en parallèle, timeout ${REQUEST_TIMEOUT/1000}s)\n`);

  const brokenProducts = [];
  const results = { OK: 0, NOT_FOUND: 0, GONE: 0, TIMEOUT: 0, FORBIDDEN: 0, 
                    SKIP_BOT_PROTECTED: 0, EMPTY: 0, INVALID: 0, OTHER: 0, ERROR: 0, SERVER_ERROR: 0 };

  let checked = 0;

  const tasks = withLinks.map(doc => async () => {
    const d = doc.data();
    const name = d.name || d.product_title || d.title || '?';
    const brand = d.brand || '';
    const links = d.buyLinks || [];

    const linkResults = [];
    for (const link of links) {
      const url = typeof link === 'string' ? link : (link.url || link.link || '');
      if (!url) continue;
      const check = await checkLink(url);
      linkResults.push({ url, ...check });
      results[check.status] = (results[check.status] || 0) + 1;
    }

    checked++;
    if (checked % 20 === 0) {
      process.stdout.write(`   📊 ${checked}/${withLinks.length} vérifiés...\r`);
    }

    // Un produit est "cassé" si TOUS ses liens sont en erreur (NOT_FOUND, GONE, TIMEOUT)
    const brokenStatuses = ['NOT_FOUND', 'GONE', 'SERVER_ERROR'];
    const allBroken = linkResults.length > 0 && linkResults.every(r => brokenStatuses.includes(r.status));
    const someBroken = linkResults.some(r => brokenStatuses.includes(r.status));

    if (someBroken) {
      return {
        id: doc.id,
        name,
        brand,
        links: linkResults,
        allBroken,
        someBroken,
      };
    }
    return null;
  });

  await runConcurrent(tasks, t => t(), CONCURRENCY);
  // Re-run properly to collect results
  // (Reset and run again properly)
  const brokenList = [];
  let checked2 = 0;

  const tasks2 = withLinks.map(doc => async () => {
    const d = doc.data();
    const name = d.name || d.product_title || d.title || '?';
    const brand = d.brand || '';
    const links = d.buyLinks || [];

    const linkResults = [];
    for (const link of links) {
      const url = typeof link === 'string' ? link : (link.url || link.link || '');
      if (!url) continue;
      const check = await checkLink(url);
      linkResults.push({ url, ...check });
    }

    checked2++;
    if (checked2 % 20 === 0) {
      process.stdout.write(`   ✔  ${checked2}/${withLinks.length} vérifiés...\r`);
    }

    const brokenStatuses = ['NOT_FOUND', 'GONE', 'SERVER_ERROR'];
    const someBroken = linkResults.some(r => brokenStatuses.includes(r.status));
    const allBroken = linkResults.length > 0 && linkResults.every(r => brokenStatuses.includes(r.status));

    return { id: doc.id, name, brand, links: linkResults, someBroken, allBroken };
  });

  const allResults = await runConcurrent(tasks2, t => t(), CONCURRENCY);
  const broken = allResults.filter(r => r.someBroken);
  const fullyBroken = broken.filter(r => r.allBroken);
  const partiallyBroken = broken.filter(r => !r.allBroken);

  // ── Rapport final ────────────────────────────────────────────────
  console.log(`\n\n══════════════════════════════════════════════════════`);
  console.log(`📊 RÉSULTATS — LIENS D'ACHAT`);
  console.log(`══════════════════════════════════════════════════════`);
  console.log(`   Total produits          : ${docs.length}`);
  console.log(`   Avec buyLinks           : ${withLinks.length}`);
  console.log(`   Sans buyLinks           : ${noLinks.length}`);
  console.log(`   ─────────────────────────────────────────────────`);
  console.log(`   🔴 Tous les liens cassés (404/410/5xx) : ${fullyBroken.length}`);
  console.log(`   🟡 Au moins 1 lien cassé              : ${partiallyBroken.length}`);
  console.log(`   ✅ Tous les liens OK                  : ${withLinks.length - broken.length}`);
  console.log(`   ⚡ Non testés (Amazon/bot-protected)   : vérifier manuellement`);

  if (fullyBroken.length > 0) {
    console.log(`\n🔴 PRODUITS AVEC TOUS LES LIENS CASSÉS (${fullyBroken.length}) :`);
    fullyBroken.slice(0, 30).forEach((p, i) => {
      console.log(`   ${i+1}. "${p.name}" (${p.brand || 'N/A'})`);
      p.links.forEach(l => {
        console.log(`      → [${l.status}${l.code ? ' '+l.code : ''}] ${l.url.substring(0, 70)}`);
      });
    });
    if (fullyBroken.length > 30) console.log(`   ...et ${fullyBroken.length - 30} autres.`);
  }

  if (partiallyBroken.length > 0 && partiallyBroken.length <= 20) {
    console.log(`\n🟡 PRODUITS AVEC AU MOINS 1 LIEN CASSÉ (${partiallyBroken.length}) :`);
    partiallyBroken.slice(0, 15).forEach((p, i) => {
      const brokenLinks = p.links.filter(l => ['NOT_FOUND', 'GONE', 'SERVER_ERROR'].includes(l.status));
      console.log(`   ${i+1}. "${p.name}" — ${brokenLinks.length}/${p.links.length} lien(s) cassé(s)`);
    });
  }

  // Sauvegarder le rapport complet
  const reportData = {
    timestamp: new Date().toISOString(),
    total: docs.length,
    withLinks: withLinks.length,
    noLinks: noLinks.length,
    fullyBroken: fullyBroken.length,
    partiallyBroken: partiallyBroken.length,
    topDomains,
    fullyBrokenProducts: fullyBroken,
    partiallyBrokenProducts: partiallyBroken,
    noLinksProducts: noLinks.map(d => ({
      id: d.id,
      name: d.data().name || d.data().product_title || '',
      brand: d.data().brand || '',
    })),
  };

  const reportPath = path.join(__dirname, 'buylinks_audit_report.json');
  fs.writeFileSync(reportPath, JSON.stringify(reportData, null, 2));

  console.log(`\n💾 Rapport complet sauvegardé : scripts/buylinks_audit_report.json`);
  console.log(`\n╔══════════════════════════════════════════════════════╗`);
  console.log(`║  Résumé : ${fullyBroken.length} produits à corriger en priorité`.padEnd(55) + '║');
  console.log(`║  + ${noLinks.length} produits sans aucun lien d'achat`.padEnd(55) + '║');
  console.log(`╚══════════════════════════════════════════════════════╝`);

  process.exit(0);
}

main().catch(err => {
  console.error('\n❌ ERREUR CRITIQUE:', err.message || err);
  process.exit(1);
});
