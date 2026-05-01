/**
 * admin_image_fix.js — Doron Image Fix Admin
 * Usage: node scripts/admin_image_fix.js
 * Then open: http://localhost:3456
 */
const express = require('express');
const path    = require('path');
const fs      = require('fs');
const admin   = require('firebase-admin');
const sa      = require('./serviceAccountKey.json');

admin.initializeApp({ credential: admin.credential.cert(sa) });
const db = admin.firestore();

const app = express();
app.use(express.json());
app.use(express.static(path.join(__dirname, 'admin_fix_ui')));

// Champs image par ordre de priorité
const IMAGE_FIELDS = ['image', 'imageUrl', 'image_url', 'productPhoto', 'product_photo'];
function pickImage(d) {
  for (const f of IMAGE_FIELDS) if (d[f] && d[f].trim()) return d[f].trim();
  return '';
}

// Charger le rapport d'audit s'il existe
const REPORT_PATH = path.join(__dirname, 'image_audit_report.json');

// GET /api/products — tous les produits avec statut image
app.get('/api/products', async (req, res) => {
  try {
    const { filter = 'all', q = '' } = req.query;

    // Charger rapport audit pour les statuts
    let statusMap = {};
    if (fs.existsSync(REPORT_PATH)) {
      const report = JSON.parse(fs.readFileSync(REPORT_PATH, 'utf8'));
      report.problems.forEach(p => { statusMap[p.id] = p.status; });
    }

    const snap = await db.collection('gifts').get();
    let products = snap.docs.map(doc => {
      const d = doc.data();
      const imgUrl = pickImage(d);
      // FIX: imageFixed=true dans Firestore = l'utilisateur a déjà corrigé → toujours OK
      // Le rapport JSON est statique et ne doit pas écraser une correction manuelle
      let auditStatus;
      if (d.imageFixed && imgUrl) {
        auditStatus = 'OK';
      } else {
        auditStatus = statusMap[doc.id] || (imgUrl ? 'OK' : 'EMPTY');
      }
      return {
        id:         doc.id,
        name:       d.name || d.product_title || '(sans nom)',
        brand:      d.brand || d.source || '',
        image:      imgUrl,
        price:      d.price || d.prix || '',
        categories: Array.isArray(d.categories) ? d.categories : [],
        gender:     d.gender || '',
        buyLinksCount: Array.isArray(d.buyLinks) ? d.buyLinks.length : 0,
        status:     auditStatus,
        fixed:      d.imageFixed || false,
      };
    });

    // Filtre statut
    if (filter === 'broken')  products = products.filter(p => p.status !== 'OK');
    if (filter === 'ok')      products = products.filter(p => p.status === 'OK');
    if (filter === 'empty')   products = products.filter(p => p.status === 'EMPTY');
    if (filter === 'dead')    products = products.filter(p => p.status === 'DEAD');
    if (filter === 'blocked') products = products.filter(p => p.status === 'BLOCKED');

    // Recherche
    if (q.trim()) {
      const ql = q.toLowerCase();
      products = products.filter(p =>
        p.name.toLowerCase().includes(ql) ||
        p.brand.toLowerCase().includes(ql)
      );
    }

    // Tri: broken en premier
    products.sort((a, b) => {
      const order = { DEAD: 0, EMPTY: 1, BLOCKED: 2, BAD_URL: 3, TIMEOUT: 4, OK: 5 };
      return (order[a.status] ?? 6) - (order[b.status] ?? 6) || a.brand.localeCompare(b.brand);
    });

    res.json({ total: snap.size, shown: products.length, products });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// PUT /api/products/:id — mise à jour de l'image
app.put('/api/products/:id', async (req, res) => {
  try {
    const { image } = req.body;
    if (!image) return res.status(400).json({ error: 'image URL required' });
    await db.collection('gifts').doc(req.params.id).update({
      image,
      imageUrl:     image,
      image_url:    image,
      imageFixed:   true,
      imageFixedAt: new Date().toISOString(),
    });
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /api/stats
app.get('/api/stats', async (req, res) => {
  try {
    let statusMap = {};
    if (fs.existsSync(REPORT_PATH)) {
      const report = JSON.parse(fs.readFileSync(REPORT_PATH, 'utf8'));
      report.problems.forEach(p => { statusMap[p.id] = p.status; });
    }
    const snap = await db.collection('gifts').get();
    const stats = { total: snap.size, OK: 0, DEAD: 0, EMPTY: 0, BLOCKED: 0, BAD_URL: 0, fixed: 0 };
    snap.docs.forEach(doc => {
      const d = doc.data();
      const imgUrl = pickImage(d);
      // FIX: même logique — imageFixed prend la priorité sur le rapport JSON
      let s;
      if (d.imageFixed && imgUrl) {
        s = 'OK';
      } else {
        s = statusMap[doc.id] || (imgUrl ? 'OK' : 'EMPTY');
      }
      stats[s] = (stats[s] || 0) + 1;
      if (d.imageFixed) stats.fixed++;
    });
    res.json(stats);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /api/product/:id — détail complet (avec buyLinks)
app.get('/api/product/:id', async (req, res) => {
  try {
    const doc = await db.collection('gifts').doc(req.params.id).get();
    if (!doc.exists) return res.status(404).json({ error: 'not found' });
    const d = doc.data();
    res.json({
      id:        doc.id,
      name:      d.name || d.product_title || '',
      brand:     d.brand || '',
      image:     pickImage(d),
      price:     d.price || '',
      buyLinks:  d.buyLinks || [],
      categories: d.categories || [],
      gender:    d.gender || '',
      fixed:     d.imageFixed || false,
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

const PORT = 3456;
app.listen(PORT, () => {
  console.log('\n╔══════════════════════════════════════════════════════╗');
  console.log('║  🖼️   Doron Image Fix Admin — DÉMARRÉ               ║');
  console.log(`║  👉   http://localhost:${PORT}                          ║`);
  console.log('║  Ctrl+C pour arrêter                                ║');
  console.log('╚══════════════════════════════════════════════════════╝\n');
});
