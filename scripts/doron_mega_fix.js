/**
 * doron_mega_fix.js
 * Fixes all critical data issues found in the Doron Firebase audit:
 * 1. Base64 images → replace with category-based fallback URL
 * 2. Normalize image field: imageUrl = best of (imageUrl, image_url, image)
 * 3. Fix domain-only buyLinks
 * 4. Normalize buyLinks to Array of Maps format
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// Category fallback images (clean, official-looking CDN URLs)
const FALLBACK_IMAGES = {
  sport: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&q=80',
  fitness: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&q=80',
  mode: 'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?w=400&q=80',
  vetements: 'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?w=400&q=80',
  tech: 'https://images.unsplash.com/photo-1498049794561-7780e7231661?w=400&q=80',
  electronique: 'https://images.unsplash.com/photo-1498049794561-7780e7231661?w=400&q=80',
  maison: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&q=80',
  cuisine: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&q=80',
  beaute: 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=400&q=80',
  soin: 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=400&q=80',
  parfum: 'https://images.unsplash.com/photo-1541643600914-78b084683702?w=400&q=80',
  livre: 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400&q=80',
  bijoux: 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=400&q=80',
  montre: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&q=80',
  default: 'https://images.unsplash.com/photo-1513201099705-a9746072228c?w=400&q=80',
};

function isBase64OrInvalidImage(url) {
  if (!url || typeof url !== 'string') return true;
  if (url.startsWith('data:')) return true;
  if (!url.startsWith('http')) return true;
  if (url.length > 2000) return true; // suspiciously long = base64 encoded
  return false;
}

function isDomainOnly(url) {
  if (!url || !url.startsWith('http')) return true;
  try {
    const u = new URL(url);
    return u.pathname === '/' || u.pathname === '';
  } catch { return true; }
}

function getFallbackImage(data) {
  const text = `${data.name || ''} ${data.brand || ''} ${(data.tags || []).join(' ')}`.toLowerCase();
  for (const [key, url] of Object.entries(FALLBACK_IMAGES)) {
    if (key !== 'default' && text.includes(key)) return url;
  }
  return FALLBACK_IMAGES.default;
}

function getBestImageUrl(data) {
  // Priority: imageUrl > image_url > image (pick first valid http URL)
  const candidates = [data.imageUrl, data.image_url, data.image, data.photo, data.productPhoto];
  for (const c of candidates) {
    if (c && typeof c === 'string' && c.startsWith('http') && c.length < 2000) {
      return c;
    }
  }
  return null;
}

function normalizeBuyLink(link) {
  if (typeof link === 'string') {
    return { url: link, site: new URL(link).hostname.replace('www.',''), price: null, affiliated: false };
  }
  if (typeof link === 'object' && link !== null) {
    return {
      url: link.url || link.link || link.href || '',
      site: link.site || link.store || link.name || '',
      price: link.price || null,
      affiliated: link.affiliated || false,
    };
  }
  return null;
}

async function fixAll() {
  console.log('🔧 Doron Mega Fix — Starting...\n');
  
  let stats = { base64Fixed: 0, imageNormalized: 0, buyLinksFixed: 0, errors: 0, total: 0 };
  
  // Process in batches of 100
  let lastDoc = null;
  const BATCH_SIZE = 100;
  
  while (true) {
    let query = db.collection('gifts').limit(BATCH_SIZE);
    if (lastDoc) query = query.startAfter(lastDoc);
    
    const snapshot = await query.get();
    if (snapshot.empty) break;
    
    lastDoc = snapshot.docs[snapshot.docs.length - 1];
    stats.total += snapshot.docs.length;
    
    const batch = db.batch();
    let batchChanges = 0;
    
    for (const doc of snapshot.docs) {
      const data = doc.data();
      const updates = {};
      
      // 1. Fix / Normalize imageUrl
      const bestUrl = getBestImageUrl(data);
      const currentImageUrl = data.imageUrl;
      
      if (isBase64OrInvalidImage(currentImageUrl)) {
        if (bestUrl) {
          // Found a valid URL in another field
          updates.imageUrl = bestUrl;
          stats.imageNormalized++;
        } else {
          // No valid URL anywhere → use category fallback
          updates.imageUrl = getFallbackImage(data);
          stats.base64Fixed++;
        }
      } else if (!currentImageUrl && bestUrl) {
        // imageUrl is empty but another field has a valid URL
        updates.imageUrl = bestUrl;
        stats.imageNormalized++;
      }
      
      // 2. Remove redundant image fields (keep only imageUrl)
      if (data.image_url !== undefined) updates.image_url = admin.firestore.FieldValue.delete();
      if (data.photo !== undefined) updates.photo = admin.firestore.FieldValue.delete();
      if (data.productPhoto !== undefined) updates.productPhoto = admin.firestore.FieldValue.delete();
      // Keep 'image' as fallback for old code compatibility
      
      // 3. Fix buyLinks
      if (data.buyLinks && Array.isArray(data.buyLinks)) {
        const needsNormalization = data.buyLinks.some(l => typeof l === 'string' || isDomainOnly(l?.url || l));
        if (needsNormalization) {
          const normalized = data.buyLinks
            .map(l => normalizeBuyLink(l))
            .filter(l => l && l.url && !isDomainOnly(l.url));
          
          if (normalized.length > 0) {
            updates.buyLinks = normalized;
            stats.buyLinksFixed++;
          } else if (data.url && !isDomainOnly(data.url)) {
            // Fallback: use the top-level url field
            updates.buyLinks = [{ url: data.url, site: '', price: null, affiliated: false }];
            stats.buyLinksFixed++;
          }
        }
      } else if (!data.buyLinks && data.url && !isDomainOnly(data.url)) {
        // No buyLinks at all but has url → create it
        updates.buyLinks = [{ url: data.url, site: '', price: null, affiliated: false }];
        stats.buyLinksFixed++;
      }
      
      if (Object.keys(updates).length > 0) {
        batch.update(doc.ref, updates);
        batchChanges++;
      }
    }
    
    if (batchChanges > 0) {
      await batch.commit();
      process.stdout.write(`✅ Batch committed: ${batchChanges} docs | Total: ${stats.total}\r`);
    }
  }
  
  console.log('\n\n════════════════════════════════════');
  console.log('✅ TERMINÉ !');
  console.log(`📦 Total produits traités : ${stats.total}`);
  console.log(`🖼️  Images base64 → fallback : ${stats.base64Fixed}`);
  console.log(`🔄 Images normalisées (imageUrl) : ${stats.imageNormalized}`);
  console.log(`🔗 BuyLinks normalisés : ${stats.buyLinksFixed}`);
  console.log(`❌ Erreurs : ${stats.errors}`);
  
  process.exit(0);
}

fixAll().catch(e => {
  console.error('FATAL:', e);
  process.exit(1);
});
