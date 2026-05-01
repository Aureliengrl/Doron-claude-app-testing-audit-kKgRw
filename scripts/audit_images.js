/**
 * audit_images.js — Doron Gift Image Auditor
 * ============================================
 * Teste TOUTES les URLs images de la collection `gifts` et génère un rapport.
 *
 * Usage :
 *   node scripts/audit_images.js
 *   node scripts/audit_images.js --fix        (corrige les champs vides en priorité)
 *   node scripts/audit_images.js --json       (export rapport JSON brut)
 *
 * Rapport généré :
 *   ✅ OK         — image répond 200
 *   🚫 BLOCKED    — 403 Forbidden (hotlink bloqué)
 *   ❌ DEAD       — 404 / autre erreur HTTP
 *   ⚠️  EMPTY     — champ image vide ou absent
 *   🔗 BAD_URL    — URL invalide (pas http/https)
 *   ⏱️  TIMEOUT   — pas de réponse en 8s
 */

const admin  = require('firebase-admin');
const https  = require('https');
const http   = require('http');
const fs     = require('fs');
const path   = require('path');

// ── Init Firebase ────────────────────────────────────────────────────────────
const sa = require('./serviceAccountKey.json');
admin.initializeApp({ credential: admin.credential.cert(sa) });
const db = admin.firestore();

// ── Config ───────────────────────────────────────────────────────────────────
const TIMEOUT_MS      = 8000;
const CONCURRENCY     = 20;   // requêtes parallèles max
const COLLECTION      = 'gifts';
const REPORT_PATH     = path.join(__dirname, 'image_audit_report.json');

// Champs image par ordre de priorité
const IMAGE_FIELDS = ['image', 'imageUrl', 'image_url', 'productPhoto', 'product_photo'];

// ── Args ─────────────────────────────────────────────────────────────────────
const args    = process.argv.slice(2);
const EXPORT_JSON = args.includes('--json');

// ── Helpers ──────────────────────────────────────────────────────────────────
function pickImageUrl(data) {
  for (const f of IMAGE_FIELDS) {
    const v = data[f];
    if (v && typeof v === 'string' && v.trim() !== '') return v.trim();
  }
  return null;
}

function testUrl(url) {
  return new Promise((resolve) => {
    if (!url) return resolve({ status: 'EMPTY', code: null });
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return resolve({ status: 'BAD_URL', code: null });
    }

    let finished = false;
    const finish = (result) => {
      if (!finished) { finished = true; resolve(result); }
    };

    const timer = setTimeout(() => finish({ status: 'TIMEOUT', code: null }), TIMEOUT_MS);

    const lib = url.startsWith('https') ? https : http;
    try {
      const req = lib.request(url, { method: 'HEAD', timeout: TIMEOUT_MS,
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; DoronAudit/1.0)',
          'Referer': 'https://doron.app/',
        }
      }, (res) => {
        clearTimeout(timer);
        const code = res.statusCode;
        if (code === 200 || code === 206) finish({ status: 'OK',      code });
        else if (code === 403)           finish({ status: 'BLOCKED',  code });
        else if (code === 404)           finish({ status: 'DEAD',     code });
        else if (code >= 301 && code <= 308) {
          // Suivre une redirection
          const location = res.headers['location'];
          if (location) {
            testUrl(location.startsWith('http') ? location : new URL(location, url).href)
              .then(finish);
          } else {
            finish({ status: 'DEAD', code });
          }
        }
        else                             finish({ status: 'DEAD',     code });
      });
      req.on('error', () => { clearTimeout(timer); finish({ status: 'DEAD', code: null }); });
      req.on('timeout', () => { req.destroy(); finish({ status: 'TIMEOUT', code: null }); });
      req.end();
    } catch {
      clearTimeout(timer);
      finish({ status: 'BAD_URL', code: null });
    }
  });
}

// Exécution en pool de concurrence limitée
async function runConcurrent(tasks, concurrency) {
  const results = new Array(tasks.length);
  let idx = 0;
  async function worker() {
    while (idx < tasks.length) {
      const i = idx++;
      results[i] = await tasks[i]();
    }
  }
  await Promise.all(Array.from({ length: concurrency }, worker));
  return results;
}

// Barre de progression inline
let _total = 0, _done = 0;
function progress() {
  const pct = Math.round((_done / _total) * 100);
  const bar = '█'.repeat(Math.floor(pct / 2)).padEnd(50, '░');
  process.stdout.write(`\r  [${bar}] ${pct}% (${_done}/${_total})`);
}

// ── Main ─────────────────────────────────────────────────────────────────────
async function main() {
  console.log('\n╔══════════════════════════════════════════════════╗');
  console.log('║  🔍  Doron — Audit Images Base de Cadeaux       ║');
  console.log('╚══════════════════════════════════════════════════╝\n');

  // 1. Charger tous les produits
  console.log(`📦 Chargement de la collection "${COLLECTION}"...`);
  const snap = await db.collection(COLLECTION).get();
  const docs = snap.docs;
  _total = docs.length;
  console.log(`   → ${_total} produits trouvés\n`);

  // 2. Construire les tâches
  const products = docs.map(doc => {
    const d = doc.data();
    return {
      id:    doc.id,
      name:  d.name || d.product_title || d.title || '(sans nom)',
      brand: d.brand || d.source || '',
      url:   pickImageUrl(d),
      categories: Array.isArray(d.categories) ? d.categories.join(', ') : '',
    };
  });

  const tasks = products.map(p => async () => {
    const result = await testUrl(p.url);
    _done++;
    progress();
    return { ...p, ...result };
  });

  // 3. Exécuter
  console.log(`🌐 Test des URLs (${CONCURRENCY} en parallèle, timeout ${TIMEOUT_MS/1000}s)...\n`);
  const results = await runConcurrent(tasks, CONCURRENCY);
  console.log('\n');

  // 4. Grouper par statut
  const groups = {
    OK:      results.filter(r => r.status === 'OK'),
    BLOCKED: results.filter(r => r.status === 'BLOCKED'),
    DEAD:    results.filter(r => r.status === 'DEAD'),
    EMPTY:   results.filter(r => r.status === 'EMPTY'),
    BAD_URL: results.filter(r => r.status === 'BAD_URL'),
    TIMEOUT: results.filter(r => r.status === 'TIMEOUT'),
  };

  // 5. Rapport console
  const emojis = { OK:'✅', BLOCKED:'🚫', DEAD:'❌', EMPTY:'⚠️ ', BAD_URL:'🔗', TIMEOUT:'⏱️ ' };
  const labels = { OK:'OK (image valide)', BLOCKED:'BLOCKED (hotlink bloqué)', DEAD:'DEAD (404/erreur)', EMPTY:'EMPTY (champ vide)', BAD_URL:'BAD URL (format invalide)', TIMEOUT:'TIMEOUT (pas de réponse)' };

  console.log('═'.repeat(60));
  console.log('  RÉSUMÉ\n');
  let totalProblems = 0;
  for (const [status, list] of Object.entries(groups)) {
    const e = emojis[status];
    const l = labels[status];
    const n = list.length;
    console.log(`  ${e} ${l.padEnd(32)} : ${String(n).padStart(4)} produits`);
    if (status !== 'OK') totalProblems += n;
  }
  console.log('─'.repeat(60));
  console.log(`  Total produits : ${_total}`);
  console.log(`  ✅ OK          : ${groups.OK.length} (${Math.round(groups.OK.length/_total*100)}%)`);
  console.log(`  🔴 Problèmes   : ${totalProblems} (${Math.round(totalProblems/_total*100)}%)`);
  console.log('═'.repeat(60) + '\n');

  // 6. Détail des problèmes
  for (const status of ['BLOCKED', 'DEAD', 'EMPTY', 'BAD_URL', 'TIMEOUT']) {
    const list = groups[status];
    if (list.length === 0) continue;
    console.log(`\n${emojis[status]} ${labels[status].toUpperCase()} — ${list.length} produit(s)\n`);
    console.log('  ' + 'BRAND'.padEnd(20) + 'NOM'.padEnd(40) + 'URL');
    console.log('  ' + '─'.repeat(100));
    for (const r of list) {
      const urlShort = r.url ? (r.url.length > 55 ? r.url.substring(0, 52) + '...' : r.url) : '(vide)';
      const code = r.code ? ` [${r.code}]` : '';
      console.log(`  ${r.brand.substring(0,18).padEnd(20)}${r.name.substring(0,38).padEnd(40)}${urlShort}${code}`);
      console.log(`  ${''.padEnd(20)}${'ID: ' + r.id}`);
    }
  }

  // 7. Export JSON
  const report = {
    generatedAt:    new Date().toISOString(),
    totalProducts:  _total,
    summary: Object.fromEntries(
      Object.entries(groups).map(([k, v]) => [k, v.length])
    ),
    problems: results.filter(r => r.status !== 'OK').map(r => ({
      id:       r.id,
      status:   r.status,
      code:     r.code,
      name:     r.name,
      brand:    r.brand,
      url:      r.url,
      categories: r.categories,
    })),
    okCount: groups.OK.length,
  };

  fs.writeFileSync(REPORT_PATH, JSON.stringify(report, null, 2), 'utf8');
  console.log(`\n📄 Rapport JSON sauvegardé : ${REPORT_PATH}`);

  if (EXPORT_JSON) {
    console.log('\n' + JSON.stringify(report, null, 2));
  }

  // 8. Conseil de correction
  if (totalProblems > 0) {
    console.log('\n💡 CONSEIL :');
    console.log('   • BLOCKED (403) → utiliser Firebase Storage (uploader l\'image)');
    console.log('   • DEAD (404)    → retrouver l\'URL officielle du produit');
    console.log('   • EMPTY         → ajouter un champ `image` dans Firestore');
    console.log('   • TIMEOUT       → réessayer ou remplacer l\'URL');
    console.log('\n   Ouvre scripts/admin_server.js pour corriger visuellement.\n');
  } else {
    console.log('\n🎉 Toutes les images sont OK !\n');
  }

  process.exit(0);
}

main().catch(e => {
  console.error('\n❌ Erreur fatale :', e.message);
  process.exit(1);
});
