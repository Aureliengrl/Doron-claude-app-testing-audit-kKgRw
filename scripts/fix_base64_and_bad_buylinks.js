/**
 * fix_base64_and_bad_buylinks.js
 * ─────────────────────────────────────────────────────────────
 * Corrige 2 problèmes dans la collection `gifts` :
 *
 *  1. Images stockées en base64 → remplacées par une URL Amazon CDN
 *     selon le nom/brand/catégorie du produit
 *
 *  2. buyLinks avec URL de domaine seulement (ex: "https://www.jomashop.com")
 *     → remplacées par une URL de recherche Amazon précise
 *     (car une URL de domaine redirige vers la homepage, pas le produit)
 *
 * USAGE : cd scripts && node fix_base64_and_bad_buylinks.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// ─── Catalogue d'images Amazon CDN par catégorie/nom ──────────────────────
const IMAGE_DB = {
  'yoga': 'https://m.media-amazon.com/images/I/71pWKZv3XQL._AC_SX522_.jpg',
  'sport': 'https://m.media-amazon.com/images/I/81cHt8dQs4L._AC_SX522_.jpg',
  'tshirt': 'https://m.media-amazon.com/images/I/71MF-i4-pTL._AC_SX522_.jpg',
  'short': 'https://m.media-amazon.com/images/I/71MF-i4-pTL._AC_SX522_.jpg',
  'legging': 'https://m.media-amazon.com/images/I/71pWKZv3XQL._AC_SX522_.jpg',
  'sneaker': 'https://m.media-amazon.com/images/I/71MBPJRiVrL._AC_SY695_.jpg',
  'chaussure': 'https://m.media-amazon.com/images/I/61MSCS5ONZL._AC_SY695_.jpg',
  'sac': 'https://m.media-amazon.com/images/I/71B5f3LYQKL._AC_SX522_.jpg',
  'montre': 'https://m.media-amazon.com/images/I/61+9E-4mKhL._AC_SX679_.jpg',
  'bijoux': 'https://m.media-amazon.com/images/I/61WmQ1O5OGL._AC_SX522_.jpg',
  'parfum': 'https://m.media-amazon.com/images/I/61p2M2jdlhL._AC_SX522_.jpg',
  'soin': 'https://m.media-amazon.com/images/I/61r5b-c29DL._SX425_.jpg',
  'tech': 'https://m.media-amazon.com/images/I/61f1YfTkTDL._AC_SX522_.jpg',
  'maison': 'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg',
  'livre': 'https://m.media-amazon.com/images/I/71pZnMvkBCL._AC_SX522_.jpg',
  'alo yoga': 'https://m.media-amazon.com/images/I/71pWKZv3XQL._AC_SX522_.jpg',
  'lululemon': 'https://m.media-amazon.com/images/I/71pWKZv3XQL._AC_SX522_.jpg',
  'stanley': 'https://m.media-amazon.com/images/I/81cHt8dQs4L._AC_SX522_.jpg',
  'jomashop': 'https://m.media-amazon.com/images/I/61z7gMXCjaL._AC_SX522_.jpg',
};

// Domaines "entiers" qui ne pointent pas vers une page produit
const DOMAIN_ONLY_PATTERNS = [
  /^https?:\/\/[^/]+\/?$/, // ex: https://www.jomashop.com ou https://www.jomashop.com/
  /^https?:\/\/[^/]+\/#?\/?$/, // avec fragment
];

function isBase64Image(url) {
  if (!url) return false;
  return url.startsWith('data:') || (url.length > 500 && !url.startsWith('http'));
}

function isDomainOnlyUrl(url) {
  if (!url || !url.startsWith('http')) return true;
  return DOMAIN_ONLY_PATTERNS.some(p => p.test(url));
}

function findBestImage(name = '', brand = '', categories = []) {
  const combined = `${name} ${brand}`.toLowerCase();
  for (const [key, url] of Object.entries(IMAGE_DB)) {
    if (combined.includes(key)) return url;
  }
  for (const cat of (categories || []).map(c => c.toLowerCase())) {
    if (IMAGE_DB[cat]) return IMAGE_DB[cat];
    for (const [key, url] of Object.entries(IMAGE_DB)) {
      if (cat.includes(key)) return url;
    }
  }
  return 'https://m.media-amazon.com/images/I/61f1YfTkTDL._AC_SX522_.jpg'; // generic
}

function generateAmazonSearchUrl(name, brand) {
  const query = encodeURIComponent(`${brand} ${name}`.trim());
  return `https://www.amazon.fr/s?k=${query}`;
}

async function main() {
  console.log('🔧 Fix Base64 Images & Bad BuyLinks — Doron DB');
  console.log('═════════════════════════════════════════════\n');

  const snapshot = await db.collection('gifts').get();
  console.log(`📦 ${snapshot.size} produits chargés\n`);

  let fixedImages = 0, fixedBuyLinks = 0, errors = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const name = data.name || data.product_title || '';
    const brand = data.brand || '';
    const image = data.image || data.imageUrl || '';
    const categories = Array.isArray(data.categories) ? data.categories : [];
    const buyLinks = Array.isArray(data.buyLinks) ? data.buyLinks : [];

    const updates = {};

    // ── 1. Fix image base64 ──────────────────────────────────────────────
    if (isBase64Image(image)) {
      updates.image = findBestImage(name, brand, categories);
      fixedImages++;
      console.log(`🖼️  Base64 image fixée: "${name}" (${brand})`);
      console.log(`   → ${updates.image}\n`);
    }

    // ── 2. Fix buyLinks avec domaine uniquement ──────────────────────────
    let buyLinksChanged = false;
    const fixedLinks = buyLinks.map(link => {
      // Format objet {site, url, price, ...}
      if (link && typeof link === 'object' && link.url !== undefined) {
        if (isDomainOnlyUrl(link.url)) {
          const newUrl = generateAmazonSearchUrl(name, brand);
          console.log(`🔗 BuyLink domaine fixé: "${name}" sur ${link.site || 'site'}`);
          console.log(`   ${link.url} → ${newUrl}\n`);
          buyLinksChanged = true;
          return { ...link, url: newUrl };
        }
        return link;
      }
      // Format string (tableau de strings)
      if (typeof link === 'string') {
        if (isDomainOnlyUrl(link)) {
          const newUrl = generateAmazonSearchUrl(name, brand);
          console.log(`🔗 BuyLink string domaine fixé: "${name}"`);
          console.log(`   ${link} → ${newUrl}\n`);
          buyLinksChanged = true;
          return newUrl;
        }
        return link;
      }
      return link;
    });

    if (buyLinksChanged) {
      updates.buyLinks = fixedLinks;
      fixedBuyLinks++;
    }

    // ── Appliquer les corrections ────────────────────────────────────────
    if (Object.keys(updates).length > 0) {
      try {
        updates.updatedAt = new Date().toISOString();
        await doc.ref.update(updates);
      } catch (e) {
        errors++;
        console.error(`❌ Erreur sur "${name}": ${e.message}`);
      }
    }
  }

  console.log('\n✅ TERMINÉ !');
  console.log('═══════════════════════════════════════');
  console.log(`🖼️  Images base64 corrigées : ${fixedImages}`);
  console.log(`🔗 BuyLinks domaine fixés   : ${fixedBuyLinks}`);
  console.log(`❌ Erreurs                  : ${errors}`);
  process.exit(0);
}

main().catch(err => {
  console.error('❌ ERREUR CRITIQUE:', err);
  process.exit(1);
});
