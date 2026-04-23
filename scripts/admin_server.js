/**
 * admin_server.js — Doron Image Admin Tool
 * Usage: node admin_server.js
 * Then open: http://localhost:3456
 */
const express = require('express');
const path    = require('path');
const admin   = require('firebase-admin');
const sa      = require('./serviceAccountKey.json');

admin.initializeApp({ credential: admin.credential.cert(sa) });
const db = admin.firestore();

const app  = express();
app.use(express.json());
app.use(express.static(path.join(__dirname, 'admin_ui')));

// ── GET /api/products ───────────────────────────────────────────────
app.get('/api/products', async (req, res) => {
  try {
    const snap = await db.collection('gifts').get();
    const products = snap.docs.map(doc => {
      const d = doc.data();
      return {
        id:         doc.id,
        name:       d.name || d.product_title || d.title || '(sans nom)',
        brand:      d.brand || d.source || '',
        image:      d.image || d.imageUrl || d.productPhoto || '',
        categories: d.categories || d.tags || [],
        price:      d.price || d.prix || '',
        gender:     d.gender || '',
        fixed:      d.imageFixed || false,
      };
    }).sort((a, b) => a.brand.localeCompare(b.brand) || a.name.localeCompare(b.name));
    res.json({ total: products.length, products });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── PUT /api/products/:id ────────────────────────────────────────────
app.put('/api/products/:id', async (req, res) => {
  try {
    const { image } = req.body;
    if (!image) return res.status(400).json({ error: 'image URL required' });
    await db.collection('gifts').doc(req.params.id).update({
      image,
      imageUrl: image,
      imageFixed: true,
      imageFixedAt: new Date().toISOString(),
    });
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── GET /api/stats ───────────────────────────────────────────────────
app.get('/api/stats', async (req, res) => {
  try {
    const snap = await db.collection('gifts').get();
    let fixed = 0;
    snap.docs.forEach(d => { if (d.data().imageFixed) fixed++; });
    res.json({ total: snap.size, fixed, remaining: snap.size - fixed });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

const PORT = 3456;
app.listen(PORT, () => {
  console.log('\n╔══════════════════════════════════════════════╗');
  console.log('║   🖼️  Doron Image Admin — DÉMARRÉ           ║');
  console.log(`║   👉  http://localhost:${PORT}                 ║`);
  console.log('║   Ctrl+C pour arrêter                       ║');
  console.log('╚══════════════════════════════════════════════╝\n');
});
