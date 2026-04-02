const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
  let firestore = admin.firestore();
  let userRef = firestore.doc("Users/" + user.uid);
  await firestore.collection("Users").doc(user.uid).delete();
});

/**
 * Fonction pour supprimer TOUS les utilisateurs (Auth + Firestore)
 * ⚠️ ATTENTION: Cette fonction est DANGEREUSE et supprime TOUS les utilisateurs!
 * ⚠️ À n'utiliser que pendant le développement!
 *
 * Pour l'appeler:
 * curl -X POST https://us-central1-<PROJECT_ID>.cloudfunctions.net/deleteAllUsers \
 *   -H "Content-Type: application/json" \
 *   -d '{"confirmationKey": "DELETE_ALL_USERS_CONFIRMED"}'
 */
exports.deleteAllUsers = functions.https.onRequest(async (req, res) => {
  // CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  // Vérification de sécurité - nécessite une clé de confirmation
  const confirmationKey = req.body.confirmationKey;
  if (confirmationKey !== 'DELETE_ALL_USERS_CONFIRMED') {
    console.log('❌ Tentative de suppression sans clé de confirmation valide');
    res.status(403).json({
      error: 'Forbidden',
      message: 'Clé de confirmation manquante ou invalide'
    });
    return;
  }

  try {
    console.log('🗑️ DÉBUT SUPPRESSION DE TOUS LES UTILISATEURS');

    const firestore = admin.firestore();
    let totalAuthUsersDeleted = 0;
    let totalFirestoreDocsDeleted = 0;
    let errors = [];

    // 1. Supprimer tous les utilisateurs de Firebase Authentication
    console.log('🔄 Récupération de tous les utilisateurs Auth...');
    const listAllUsers = async (nextPageToken) => {
      try {
        const listUsersResult = await admin.auth().listUsers(1000, nextPageToken);

        for (const userRecord of listUsersResult.users) {
          try {
            await admin.auth().deleteUser(userRecord.uid);
            totalAuthUsersDeleted++;
            console.log(`✅ Auth user supprimé: ${userRecord.email || userRecord.uid}`);
          } catch (error) {
            errors.push(`Erreur suppression Auth user ${userRecord.uid}: ${error.message}`);
            console.error(`❌ Erreur suppression ${userRecord.uid}:`, error);
          }
        }

        if (listUsersResult.pageToken) {
          await listAllUsers(listUsersResult.pageToken);
        }
      } catch (error) {
        errors.push(`Erreur lors de la récupération des utilisateurs: ${error.message}`);
        console.error('❌ Erreur récupération utilisateurs:', error);
      }
    };

    await listAllUsers();

    // 2. Supprimer tous les documents de la collection Users dans Firestore
    console.log('🔄 Suppression des documents Firestore Users...');
    const usersSnapshot = await firestore.collection('Users').get();

    const batch = firestore.batch();
    let batchCount = 0;

    for (const doc of usersSnapshot.docs) {
      batch.delete(doc.ref);
      batchCount++;

      // Firestore batch a une limite de 500 opérations
      if (batchCount === 500) {
        await batch.commit();
        totalFirestoreDocsDeleted += batchCount;
        console.log(`✅ Batch de ${batchCount} documents Firestore supprimés`);
        batchCount = 0;
      }
    }

    // Commit du dernier batch s'il reste des opérations
    if (batchCount > 0) {
      await batch.commit();
      totalFirestoreDocsDeleted += batchCount;
      console.log(`✅ Batch final de ${batchCount} documents Firestore supprimés`);
    }

    console.log('✅ SUPPRESSION TERMINÉE');
    console.log(`   - Utilisateurs Auth supprimés: ${totalAuthUsersDeleted}`);
    console.log(`   - Documents Firestore supprimés: ${totalFirestoreDocsDeleted}`);

    res.status(200).json({
      success: true,
      message: 'Tous les utilisateurs ont été supprimés',
      details: {
        authUsersDeleted: totalAuthUsersDeleted,
        firestoreDocsDeleted: totalFirestoreDocsDeleted,
        errors: errors.length > 0 ? errors : null
      }
    });

  } catch (error) {
    console.error('❌ ERREUR CRITIQUE lors de la suppression:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: error.message
    });
  }
});

// ============================================================
// Product refresh helpers and functions
// ============================================================

/**
 * Shared logic for checking and refreshing a single product document.
 * Returns an updates object to apply to the document.
 */
async function checkProduct(data, axios, admin) {
  const updates = {};
  let hasIssue = false;

  // 1. Check image URL
  const imageUrl = data.image || data.product_photo || '';
  if (imageUrl) {
    try {
      await axios.head(imageUrl, {
        timeout: 5000,
        validateStatus: (s) => s < 400,
        headers: { 'User-Agent': 'Mozilla/5.0 (compatible; DoronBot/1.0)' }
      });
    } catch (e) {
      // Image is broken
      updates.imageStatus = 'broken';
      hasIssue = true;

      const name = data.name || data.product_title || '';
      if (name) {
        updates.image = '';
        updates.imageStatus = 'missing';
      }
    }
  } else {
    updates.imageStatus = 'missing';
    hasIssue = true;
  }

  // 2. Check product URL
  const productUrl = data.url || data.product_url || '';
  if (productUrl && productUrl !== '#' && productUrl.startsWith('http')) {
    try {
      await axios.head(productUrl, {
        timeout: 5000,
        maxRedirects: 3,
        validateStatus: (s) => s < 400,
        headers: { 'User-Agent': 'Mozilla/5.0 (compatible; DoronBot/1.0)' }
      });
      updates.urlStatus = 'valid';
    } catch (e) {
      updates.urlStatus = 'broken';
      hasIssue = true;

      const name = data.name || '';
      const brand = data.brand || '';
      const source = (data.source || 'amazon').toLowerCase();
      const query = encodeURIComponent(`${brand} ${name}`.trim());

      if (source.includes('amazon')) {
        updates.url = `https://www.amazon.fr/s?k=${query}`;
      } else if (source.includes('sephora')) {
        updates.url = `https://www.sephora.fr/search/?q=${query}`;
      } else if (source.includes('fnac')) {
        updates.url = `https://www.fnac.com/SearchResult/ResultList.aspx?Search=${query}`;
      } else {
        updates.url = `https://www.amazon.fr/s?k=${query}`;
      }
      updates.urlStatus = 'fallback_search';
    }
  } else {
    // No URL at all, generate one
    const name = data.name || '';
    const brand = data.brand || '';
    const query = encodeURIComponent(`${brand} ${name}`.trim());
    updates.url = `https://www.amazon.fr/s?k=${query}`;
    updates.urlStatus = 'generated';
    hasIssue = true;
  }

  // 3. Flag the product
  updates.lastChecked = admin.firestore.FieldValue.serverTimestamp();
  updates.hasIssues = hasIssue;

  return { updates, hasIssue };
}

/**
 * Process a list of product documents: check each one and apply updates.
 * Returns { fixed, flagged, errors }.
 */
async function processProductDocs(docs, axios, admin) {
  let fixed = 0, flagged = 0, errors = 0;

  for (let i = 0; i < docs.length; i += 20) {
    const batch = docs.slice(i, i + 20);

    await Promise.all(batch.map(async (doc) => {
      const data = doc.data();
      try {
        const result = await checkProduct(data, axios, admin);
        if (result.hasIssue) flagged++;
        else fixed++;

        await doc.ref.update(result.updates);
      } catch (e) {
        errors++;
        console.error(`Error updating ${doc.id}: ${e.message}`);
      }
    }));

    // Small delay between batches to avoid rate limits
    if (i + 20 < docs.length) {
      await new Promise(r => setTimeout(r, 1000));
    }
  }

  return { fixed, flagged, errors };
}

/**
 * Scheduled function that refreshes product data daily.
 * For each product, attempts to verify and update:
 * - Image URL (checks if accessible via HEAD request)
 * - Product URL (checks if accessible)
 * - Flags products with issues
 *
 * Runs every day at 3am Paris time.
 */
exports.refreshProducts = functions.pubsub
  .schedule('0 3 * * *')
  .timeZone('Europe/Paris')
  .onRun(async (context) => {
    const db = admin.firestore();
    const axios = require('axios');

    // Get all active products
    const snapshot = await db.collection('gifts').where('active', '==', true).get();
    console.log(`Found ${snapshot.size} active products to check`);

    const docs = snapshot.docs;
    const { fixed, flagged, errors } = await processProductDocs(docs, axios, admin);

    console.log(`Refresh complete: ${fixed} OK, ${flagged} flagged, ${errors} errors`);

    // Save summary
    await db.collection('system').doc('product_refresh_log').set({
      lastRun: admin.firestore.FieldValue.serverTimestamp(),
      totalChecked: docs.length,
      fixed,
      flagged,
      errors,
    });

    return null;
  });

/**
 * Manual trigger to refresh product data.
 * POST /refreshProductsManual
 * Body: { "limit": 50 } (optional, default processes all)
 *
 * Requires a valid Firebase Auth Bearer token.
 */
exports.refreshProductsManual = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') { res.status(204).send(''); return; }
  if (req.method !== 'POST') { res.status(405).send('Method not allowed'); return; }

  // Verify Firebase Auth token
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }

  try {
    const token = authHeader.split('Bearer ')[1];
    await admin.auth().verifyIdToken(token);
  } catch (e) {
    res.status(401).json({ error: 'Invalid token' });
    return;
  }

  try {
    const limit = (req.body && req.body.limit) ? parseInt(req.body.limit, 10) : 0;
    const db = admin.firestore();
    const axios = require('axios');

    let query = db.collection('gifts').where('active', '==', true);
    if (limit > 0) {
      query = query.limit(limit);
    }

    const snapshot = await query.get();
    console.log(`Manual refresh: checking ${snapshot.size} products (limit=${limit || 'all'})`);

    const docs = snapshot.docs;
    const { fixed, flagged, errors } = await processProductDocs(docs, axios, admin);

    // Save summary
    await db.collection('system').doc('product_refresh_log').set({
      lastRun: admin.firestore.FieldValue.serverTimestamp(),
      totalChecked: docs.length,
      fixed,
      flagged,
      errors,
      triggeredBy: 'manual',
    });

    res.status(200).json({
      success: true,
      checked: docs.length,
      fixed,
      flagged,
      errors,
    });
  } catch (error) {
    console.error('Error in refreshProductsManual:', error);
    res.status(500).json({ error: 'Internal server error', message: error.message });
  }
});

/**
 * Returns a list of products that have issues (broken images, broken URLs, etc.)
 * for the admin dashboard.
 *
 * GET /getProductIssues
 * Requires a valid Firebase Auth Bearer token.
 *
 * Returns JSON array of { id, name, brand, imageStatus, urlStatus, price, lastChecked }
 */
exports.getProductIssues = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') { res.status(204).send(''); return; }
  if (req.method !== 'GET') { res.status(405).send('Method not allowed'); return; }

  // Verify Firebase Auth token
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }

  try {
    const token = authHeader.split('Bearer ')[1];
    await admin.auth().verifyIdToken(token);
  } catch (e) {
    res.status(401).json({ error: 'Invalid token' });
    return;
  }

  try {
    const db = admin.firestore();
    const snapshot = await db.collection('gifts').where('hasIssues', '==', true).get();

    const issues = snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        name: data.name || data.product_title || '',
        brand: data.brand || '',
        imageStatus: data.imageStatus || 'unknown',
        urlStatus: data.urlStatus || 'unknown',
        price: data.price || data.product_price || null,
        lastChecked: data.lastChecked || null,
      };
    });

    res.status(200).json({ success: true, count: issues.length, issues });
  } catch (error) {
    console.error('Error in getProductIssues:', error);
    res.status(500).json({ error: 'Internal server error', message: error.message });
  }
});
