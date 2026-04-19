/**
 * scrape_and_upload_images.js
 * ─────────────────────────────────────────────────────────────
 * Pour chaque produit avec une image cassée/vide dans Firestore :
 *   1. Visite l'URL officielle du produit
 *   2. Extrait la vraie photo produit (og:image ou balise img principale)
 *   3. Télécharge les octets de l'image
 *   4. Upload dans Firebase Storage → products/gifts/{docId}.jpg
 *   5. Met à jour le champ `image` dans Firestore avec l'URL Firebase
 *
 * USAGE :
 *   cd scripts
 *   node scrape_and_upload_images.js
 *
 * Prérequis : serviceAccountKey.json dans ce dossier
 */

const admin = require('firebase-admin');
const fetch = require('node-fetch');
const cheerio = require('cheerio');
const path = require('path');

// ── Init Firebase Admin ──────────────────────────────────────
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'doron-b3011.firebasestorage.app',
});
const db = admin.firestore();
const bucket = admin.storage().bucket();

// ── Config ───────────────────────────────────────────────────
const DELAY_MS = 1500;          // délai entre requêtes (anti-blocage)
const TIMEOUT_MS = 12000;       // timeout par requête
const MAX_ERRORS = 5;           // arrêt si trop d'erreurs consécutives

// Headers réalistes pour éviter d'être bloqué
const HEADERS = {
  'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
  'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
  'Accept-Encoding': 'gzip, deflate, br',
  'Connection': 'keep-alive',
  'Cache-Control': 'no-cache',
};

// ── Domaines que LEURS propres CDN bloquent le hotlinking ─────
const HOTLINK_BLOCKED_DOMAINS = [
  'unsplash.com', 'placeholder',
  'sezane.com', 'jacquemus.com', 'saint-james.com',
  'jonak.fr', 'kiehls.fr', 'aesop.com', 'byredo.com',
  'lelabofragrances.com', 'franciskurkdjian.com', 'amiparis.com',
  'longchamp.com', 'veja-store.com', 'lacoste.com', 'tissotwatches.com',
  'lancel.com', 'histoiredor.com', 'clarins.fr', 'skinceuticals.fr',
  'rituals.com', 'loccitane.com', 'diptyqueparis.com',
  'maison-margiela.com', 'maje.com', 'sandro-paris.com',
  'dw/image', 'demandware', 'harrods.com', 'ctfassets.net',
];

// Produits dont l'URL appartient à une vraie marque mais l'image
// vient d'un autre CDN générique (Amazon, Nike...) → mismatch → corriger
const AMAZON_CDN = 'm.media-amazon.com';
const BRANDS_NOT_ON_AMAZON = [
  'sezane.com', 'jacquemus.com', 'saint-james.com', 'jonak.fr',
  'byredo.com', 'lelabofragrances.com', 'franciskurkdjian.com',
  'amiparis.com', 'longchamp.com', 'veja-store.com', 'lacoste.com',
  'aesop.com', 'kiehls.fr', 'clarins.fr', 'lancel.com',
  'rituals.com', 'loccitane.com', 'diptyqueparis.com',
  'maje.com', 'sandro-paris.com', 'maison-margiela.com',
];

function isBadImage(imageUrl, productUrl) {
  if (!imageUrl || imageUrl.trim() === '') return true;
  const imgLower = imageUrl.toLowerCase();

  // 1. Image déjà dans Firebase Storage → OK, on ne retouche pas
  if (imgLower.includes('firebasestorage.googleapis.com') ||
      imgLower.includes('storage.googleapis.com')) return false;

  // 2. Image d'un CDN connu pour bloquer le hotlinking
  if (HOTLINK_BLOCKED_DOMAINS.some(d => imgLower.includes(d))) return true;

  // 3. Image Amazon CDN générique pour un produit d'une marque non-Amazon
  if (imgLower.includes(AMAZON_CDN) && productUrl) {
    const urlLower = productUrl.toLowerCase();
    if (BRANDS_NOT_ON_AMAZON.some(brand => urlLower.includes(brand))) {
      return true; // mismatch → la vraie image est sur le site de la marque
    }
  }

  return false;
}

// ── Scraping : extraire l'image depuis og:image ───────────────
async function scrapeProductImage(productUrl) {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);

    const res = await fetch(productUrl, {
      headers: HEADERS,
      signal: controller.signal,
      redirect: 'follow',
    });
    clearTimeout(timeout);

    if (!res.ok) {
      return { error: `HTTP ${res.status}`, imageUrl: null };
    }

    const html = await res.text();
    const $ = cheerio.load(html);

    // Priorité 1 : og:image (standard universelle des e-commerce)
    let imageUrl = $('meta[property="og:image"]').attr('content')
      || $('meta[name="og:image"]').attr('content')
      || $('meta[property="og:image:secure_url"]').attr('content');

    // Priorité 2 : twitter:image
    if (!imageUrl) {
      imageUrl = $('meta[name="twitter:image"]').attr('content')
        || $('meta[property="twitter:image"]').attr('content');
    }

    // Priorité 3 : première grande image produit
    if (!imageUrl) {
      const imgCandidates = [
        'img[class*="product"][src]',
        'img[class*="main"][src]',
        'img[class*="hero"][src]',
        'img[itemprop="image"]',
        '.product-image img',
        '#product-image img',
        'img[data-main-image]',
      ];
      for (const sel of imgCandidates) {
        const src = $(sel).first().attr('src') || $(sel).first().attr('data-src');
        if (src && src.length > 10) { imageUrl = src; break; }
      }
    }

    // Nettoyer l'URL relative
    if (imageUrl) {
      if (imageUrl.startsWith('//')) imageUrl = 'https:' + imageUrl;
      else if (imageUrl.startsWith('/')) {
        const base = new URL(productUrl);
        imageUrl = `${base.protocol}//${base.host}${imageUrl}`;
      }
      // Supprimer les paramètres de resize qui pourraient poser pb
      imageUrl = imageUrl.split('?')[0].split('#')[0];
      // Ajouter la bonne extension si absente
      if (!imageUrl.match(/\.(jpg|jpeg|png|webp)$/i)) {
        imageUrl += '.jpg';
      }
    }

    return { imageUrl: imageUrl || null, error: null };
  } catch (err) {
    return { imageUrl: null, error: err.message };
  }
}

// ── Télécharger les bytes de l'image ─────────────────────────
async function downloadImage(imageUrl) {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);

    const res = await fetch(imageUrl, {
      headers: { ...HEADERS, 'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8' },
      signal: controller.signal,
    });
    clearTimeout(timeout);

    if (!res.ok) return { buffer: null, contentType: null, error: `HTTP ${res.status}` };

    const buffer = await res.buffer();
    const contentType = res.headers.get('content-type') || 'image/jpeg';
    return { buffer, contentType, error: null };
  } catch (err) {
    return { buffer: null, contentType: null, error: err.message };
  }
}

// ── Upload vers Firebase Storage ─────────────────────────────
async function uploadToStorage(buffer, contentType, docId) {
  const ext = contentType.includes('png') ? 'png'
    : contentType.includes('webp') ? 'webp'
    : 'jpg';
  const filePath = `products/gifts/${docId}.${ext}`;
  const file = bucket.file(filePath);

  await file.save(buffer, {
    metadata: { contentType, cacheControl: 'public, max-age=31536000' },
    public: true,   // lecture publique sans token
  });

  // URL publique stable
  const publicUrl = `https://storage.googleapis.com/${bucket.name}/${filePath}`;
  return publicUrl;
}

// ── Délai ────────────────────────────────────────────────────
const sleep = (ms) => new Promise(r => setTimeout(r, ms));

// ── MAIN ─────────────────────────────────────────────────────
async function main() {
  console.log('🖼️  Scrape & Upload — Vraies images produits → Firebase Storage');
  console.log('═════════════════════════════════════════════════════════════\n');

  const snapshot = await db.collection('gifts').get();
  console.log(`📦 ${snapshot.size} produits dans Firestore\n`);

  // Filtrer seulement les produits avec image cassée ET une URL produit valide
  const toFix = snapshot.docs.filter(doc => {
    const d = doc.data();
    const image = d.image || '';
    const url = d.url || d.product_url || '';
    return isBadImage(image, url) && url.startsWith('http');
  });

  console.log(`🔍 ${toFix.length} produits à corriger (image cassée + URL dispo)\n`);

  let fixed = 0, failed = 0, consecutiveErrors = 0;

  for (let i = 0; i < toFix.length; i++) {
    const doc = toFix[i];
    const data = doc.data();
    const name = data.name || data.product_title || 'Produit';
    const brand = data.brand || '';
    const productUrl = data.url || data.product_url;

    console.log(`\n[${i + 1}/${toFix.length}] "${name}" (${brand})`);
    console.log(`   🔗 ${productUrl.substring(0, 70)}...`);

    // Étape 1 : Scraper l'image depuis la page produit
    const { imageUrl, error: scrapeError } = await scrapeProductImage(productUrl);

    if (!imageUrl) {
      console.log(`   ❌ Scraping échoué: ${scrapeError || 'image introuvable'}`);
      failed++;
      consecutiveErrors++;
      if (consecutiveErrors >= MAX_ERRORS) {
        console.log(`\n⚠️  ${MAX_ERRORS} erreurs consécutives — pause 10s...`);
        await sleep(10000);
        consecutiveErrors = 0;
      } else {
        await sleep(DELAY_MS);
      }
      continue;
    }

    console.log(`   🖼️  Image trouvée: ${imageUrl.substring(0, 70)}`);

    // Étape 2 : Télécharger l'image
    const { buffer, contentType, error: dlError } = await downloadImage(imageUrl);

    if (!buffer || buffer.length < 1000) {
      console.log(`   ❌ Téléchargement échoué: ${dlError || `taille ${buffer?.length} trop petite`}`);
      failed++;
      await sleep(DELAY_MS);
      continue;
    }

    console.log(`   📥 Image téléchargée (${Math.round(buffer.length / 1024)} KB, ${contentType})`);

    // Étape 3 : Upload Firebase Storage
    try {
      const storageUrl = await uploadToStorage(buffer, contentType, doc.id);
      console.log(`   ☁️  Uploadée: ${storageUrl}`);

      // Étape 4 : Mettre à jour Firestore
      await doc.ref.update({
        image: storageUrl,
        imageStoragePath: `products/gifts/${doc.id}`,
        updatedAt: new Date().toISOString(),
      });

      console.log(`   ✅ Firestore mis à jour !`);
      fixed++;
      consecutiveErrors = 0;
    } catch (uploadErr) {
      console.log(`   ❌ Upload Storage échoué: ${uploadErr.message}`);
      failed++;
    }

    // Délai entre chaque produit
    await sleep(DELAY_MS);
  }

  // ── Rapport final ─────────────────────────────────────────
  console.log('\n\n✅ TERMINÉ !');
  console.log('══════════════════════════════════════');
  console.log(`📊 Produits à corriger  : ${toFix.length}`);
  console.log(`✅ Corrigés avec succès : ${fixed}`);
  console.log(`❌ Échecs               : ${failed}`);
  console.log(`\n🎉 ${fixed} produits ont maintenant de vraies images dans Firebase Storage !`);

  process.exit(0);
}

main().catch(err => {
  console.error('\n❌ ERREUR CRITIQUE:', err);
  process.exit(1);
});
