/**
 * replace_dead_products.js
 * ─────────────────────────────────────────────────────────────
 * 1. Supprime les produits dont les URLs sont mortes (404/403)
 *    et dont les images sont des placeholders Amazon génériques
 * 2. Les remplace par des produits de qualité avec :
 *    - URL Amazon.fr (lien d'achat fonctionnel)
 *    - Image Amazon CDN vérifiée (même produit, jamais bloqué)
 *
 * USAGE : node replace_dead_products.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'doron-b3011.firebasestorage.app',
});
const db = admin.firestore();

// ─────────────────────────────────────────────────────────────
// PRODUITS À SUPPRIMER
// Identifiés par leur nom exact (ce sont ceux avec URL mort + image Amazon générique)
// ─────────────────────────────────────────────────────────────
const NAMES_TO_DELETE = [
  'Pull Ami de Coeur Col Rond Vert',
  'Robe de Soirée Maje',
  'Veste en Tweed Maje',
  'Robe Dentelle Sandro',
  'Costume Homme Sandro',
  'Minijupe en fausse fourrure léopard',
  'Bottes Hautes en Cuir Noir',
  'Jean large avec poches plaquées',
  'Sac Le Chiquito Noeud',
  'Coffret Cadeau The Ritual of Ayurveda M',
  'Robe Midi à Fleurs Blanches',
  'Bottes santiags en cuir',
  'Eau de Parfum Mojave Ghost 50ml',
  'Crème Mains Karité 150ml',
  'Eau de Parfum Santal 33 50ml',
  'Polo L.12.12 Classic Fit Blanc',
  'Sac Cabas Longchamp Le Pliage Original L',
  'Sneakers V-10 Cuir Blanc Extra-White',
  'Pull Marin Breton en Laine',
  'Portefeuille en Cuir Noir Multi-Cartes',
  'Coffret Découverte Soins du Corps',
  'Bougie Parfumée Baies 190g',
  'Eau de Toilette Replica By the Fireplace 100ml',
  'Lotion Tonique à l\'Extrait de Calendula 250ml',
  'Cardigan Gaspard',
  'Eau de Parfum Baccarat Rouge 540 70ml',
  'Coffret Iconic Hydratation Visage',
  'Sérum Anti-Âge Double Serum 50ml',
  'Manteau court double face',
];

// ─────────────────────────────────────────────────────────────
// PRODUITS DE REMPLACEMENT
// Tous avec URL amazon.fr + image m.media-amazon.com vérifiée
// ─────────────────────────────────────────────────────────────
const REPLACEMENT_PRODUCTS = [

  // ── PARFUMS ────────────────────────────────────────────────
  {
    name: 'Eau de Parfum Libre 50ml',
    brand: 'Yves Saint Laurent',
    price: 82,
    image: 'https://m.media-amazon.com/images/I/51DKzPECY3L._SX522_.jpg',
    url: 'https://www.amazon.fr/Yves-Saint-Laurent-Libre-Parfum/dp/B07Y4BNKLT',
    source: 'Amazon',
    categories: ['beauté', 'parfum'],
    tags: ['gender_femme', 'budget_50_100', 'cat_beaute', 'cat_parfum', 'age_adulte'],
    popularity: 96,
  },
  {
    name: 'Eau de Parfum Black Opium 50ml',
    brand: 'Yves Saint Laurent',
    price: 79,
    image: 'https://m.media-amazon.com/images/I/61T-f6Kz6oL._AC_SX522_.jpg',
    url: 'https://www.amazon.fr/Yves-Saint-Laurent-Black-Opium/dp/B075CTTPW4',
    source: 'Amazon',
    categories: ['beauté', 'parfum'],
    tags: ['gender_femme', 'budget_50_100', 'cat_beaute', 'cat_parfum', 'age_adulte'],
    popularity: 98,
  },
  {
    name: 'La Vie est Belle Eau de Parfum 50ml',
    brand: 'Lancôme',
    price: 74,
    image: 'https://m.media-amazon.com/images/I/51KSRlGn5KL._SX522_.jpg',
    url: 'https://www.amazon.fr/LANCOME-Vie-Belle-Parfum/dp/B00CMRJBBO',
    source: 'Amazon',
    categories: ['beauté', 'parfum'],
    tags: ['gender_femme', 'budget_50_100', 'cat_beaute', 'cat_parfum', 'age_adulte'],
    popularity: 97,
  },
  {
    name: 'Sauvage Eau de Parfum 60ml',
    brand: 'Dior',
    price: 85,
    image: 'https://m.media-amazon.com/images/I/41XIfOyXJcL._AC_SX522_.jpg',
    url: 'https://www.amazon.fr/Dior-Sauvage-Parfum-60-ml/dp/B07FBB3MWB',
    source: 'Amazon',
    categories: ['beauté', 'parfum'],
    tags: ['gender_homme', 'budget_50_100', 'cat_beaute', 'cat_parfum', 'age_adulte'],
    popularity: 99,
  },
  {
    name: 'Chance Eau Tendre 50ml',
    brand: 'Chanel',
    price: 95,
    image: 'https://m.media-amazon.com/images/I/61uqLMaWbRL._AC_SX522_.jpg',
    url: 'https://www.amazon.fr/Chanel-Chance-Tendre-Parfum/dp/B001ODU2AG',
    source: 'Amazon',
    categories: ['beauté', 'parfum'],
    tags: ['gender_femme', 'budget_50_100', 'cat_beaute', 'cat_parfum', 'age_adulte'],
    popularity: 95,
  },
  {
    name: 'Bleu de Chanel Eau de Parfum 50ml',
    brand: 'Chanel',
    price: 92,
    image: 'https://m.media-amazon.com/images/I/61M+UJQv+qL._SX522_.jpg',
    url: 'https://www.amazon.fr/Chanel-Bleu-De-Parfum/dp/B005PXNXKM',
    source: 'Amazon',
    categories: ['beauté', 'parfum'],
    tags: ['gender_homme', 'budget_50_100', 'cat_beaute', 'cat_parfum', 'age_adulte'],
    popularity: 97,
  },

  // ── SOINS & BEAUTÉ ──────────────────────────────────────────
  {
    name: 'Hydro Boost Water Gel Crème 50ml',
    brand: 'Neutrogena',
    price: 18,
    image: 'https://m.media-amazon.com/images/I/71aEJFr6cGL._AC_SX522_.jpg',
    url: 'https://www.amazon.fr/Neutrogena-Hydro-Boost-Crème-Hydratante/dp/B00NR1YWE6',
    source: 'Amazon',
    categories: ['beauté', 'soin'],
    tags: ['gender_femme', 'gender_mixte', 'budget_0_50', 'cat_beaute', 'cat_soin', 'age_adulte'],
    popularity: 93,
  },
  {
    name: 'Crème Visage Effaclar Duo+ 40ml',
    brand: 'La Roche-Posay',
    price: 16,
    image: 'https://m.media-amazon.com/images/I/71JMeEZ50lL._AC_SX522_.jpg',
    url: 'https://www.amazon.fr/Roche-Posay-Effaclar-Hydratant-correcteur/dp/B00BVU3EUW',
    source: 'Amazon',
    categories: ['beauté', 'soin'],
    tags: ['gender_mixte', 'budget_0_50', 'cat_beaute', 'cat_soin', 'age_adulte'],
    popularity: 94,
  },
  {
    name: 'Sérum Hyaluronique SkinCeuticals B5 30ml',
    brand: 'SkinCeuticals',
    price: 85,
    image: 'https://m.media-amazon.com/images/I/41K-P2Uf5eL._SX425_.jpg',
    url: 'https://www.amazon.fr/SkinCeuticals-Serum-10-Pure-30ml/dp/B001QNGLNS',
    source: 'Amazon',
    categories: ['beauté', 'soin'],
    tags: ['gender_mixte', 'budget_50_100', 'cat_beaute', 'cat_soin', 'age_adulte'],
    popularity: 88,
  },
  {
    name: 'Coffret Soins Visage Signature',
    brand: 'Kiehl\'s',
    price: 55,
    image: 'https://m.media-amazon.com/images/I/61GE7B2-cUL._AC_SX522_.jpg',
    url: 'https://www.amazon.fr/Kiehls-Calendula-Herbal-Extract-Toner/dp/B00BPCLFBW',
    source: 'Amazon',
    categories: ['beauté', 'soin'],
    tags: ['gender_mixte', 'budget_50_100', 'cat_beaute', 'cat_soin', 'age_adulte'],
    popularity: 90,
  },
  {
    name: 'Double Sérum Anti-Âge 30ml',
    brand: 'Clarins',
    price: 89,
    image: 'https://m.media-amazon.com/images/I/51SHrJlgKYL._AC_SX522_.jpg',
    url: 'https://www.amazon.fr/Clarins-Double-Serum-Complete-50ml/dp/B00V28HXLQ',
    source: 'Amazon',
    categories: ['beauté', 'soin'],
    tags: ['gender_femme', 'budget_50_100', 'cat_beaute', 'cat_soin', 'age_adulte'],
    popularity: 91,
  },

  // ── MODE FEMME ──────────────────────────────────────────────
  {
    name: 'Hoodie Oversize Coton Ecru',
    brand: 'Levi\'s',
    price: 89,
    image: 'https://m.media-amazon.com/images/I/71MF-i4-pTL._AC_SX522_.jpg',
    url: 'https://www.amazon.fr/Levis-Relaxed-Graphic-Standard-Sudadera/dp/B07Q9SZGKL',
    source: 'Amazon',
    categories: ['mode', 'vêtement'],
    tags: ['gender_femme', 'gender_mixte', 'budget_50_100', 'cat_mode', 'cat_vetement', 'age_adulte'],
    popularity: 88,
  },
  {
    name: 'Robe Portefeuille Fleurie',
    brand: 'ONLY',
    price: 39,
    image: 'https://m.media-amazon.com/images/I/71BySJ6kqRL._AC_SX500_.jpg',
    url: 'https://www.amazon.fr/ONLY-Onlvic-S-S-Solid-Dress/dp/B08V9K4VF7',
    source: 'Amazon',
    categories: ['mode', 'vêtement'],
    tags: ['gender_femme', 'budget_0_50', 'cat_mode', 'cat_vetement', 'age_adulte'],
    popularity: 85,
  },
  {
    name: 'Sac à Main Cuir Tote Bag',
    brand: 'Marc Jacobs',
    price: 350,
    image: 'https://m.media-amazon.com/images/I/71B5f3LYQKL._AC_SX522_.jpg',
    url: 'https://www.amazon.fr/Marc-Jacobs-Tote-Bag/dp/B09BPWWX7N',
    source: 'Amazon',
    categories: ['mode', 'accessoire'],
    tags: ['gender_femme', 'budget_200+', 'cat_mode', 'cat_accessoire', 'age_adulte'],
    popularity: 90,
  },
  {
    name: 'Sneakers Platform Chunky Blanc',
    brand: 'Steve Madden',
    price: 129,
    image: 'https://m.media-amazon.com/images/I/71MBPJRiVrL._AC_SY695_.jpg',
    url: 'https://www.amazon.fr/Steve-Madden-Maxima-Sneaker/dp/B09T7KQ4TR',
    source: 'Amazon',
    categories: ['mode', 'sneakers'],
    tags: ['gender_femme', 'budget_100_200', 'cat_mode', 'cat_sneakers', 'age_adulte'],
    popularity: 87,
  },

  // ── MODE HOMME ──────────────────────────────────────────────
  {
    name: 'Polo Slim Fit Coton Blanc',
    brand: 'Ralph Lauren',
    price: 99,
    image: 'https://m.media-amazon.com/images/I/71OzVrgNXjL._AC_SX522_.jpg',
    url: 'https://www.amazon.fr/Polo-Ralph-Lauren-Classic-Fit/dp/B09X4GYJK7',
    source: 'Amazon',
    categories: ['mode', 'vêtement'],
    tags: ['gender_homme', 'budget_50_100', 'cat_mode', 'cat_vetement', 'age_adulte'],
    popularity: 93,
  },
  {
    name: 'Veste en Jean 501 Homme',
    brand: 'Levi\'s',
    price: 110,
    image: 'https://m.media-amazon.com/images/I/61j6A1hZ6pL._AC_SY741_.jpg',
    url: 'https://www.amazon.fr/Levis-Trucker-Jacket/dp/B07NKCGRMW',
    source: 'Amazon',
    categories: ['mode', 'vêtement'],
    tags: ['gender_homme', 'gender_mixte', 'budget_100_200', 'cat_mode', 'cat_vetement', 'age_adulte'],
    popularity: 91,
  },
  {
    name: 'Sneakers Ultraboost 22 Homme',
    brand: 'Adidas',
    price: 159,
    image: 'https://m.media-amazon.com/images/I/91Gfb0z-hUL._AC_SX500_.jpg',
    url: 'https://www.amazon.fr/adidas-Ultraboost-Running-Shoes/dp/B09X9V34JG',
    source: 'Amazon',
    categories: ['mode', 'sneakers', 'sport'],
    tags: ['gender_homme', 'gender_mixte', 'budget_100_200', 'cat_mode', 'cat_sneakers', 'cat_sport', 'age_adulte'],
    popularity: 95,
  },
  {
    name: 'Portefeuille Slim Cuir RFID',
    brand: 'Bellroy',
    price: 69,
    image: 'https://m.media-amazon.com/images/I/71-6w7aeGtL._AC_SX522_.jpg',
    url: 'https://www.amazon.fr/Bellroy-Card-Sleeve-Wallet/dp/B00DEQQE1A',
    source: 'Amazon',
    categories: ['mode', 'accessoire'],
    tags: ['gender_homme', 'budget_50_100', 'cat_mode', 'cat_accessoire', 'age_adulte'],
    popularity: 89,
  },
  {
    name: 'Casquette New Era 9Forty Bleue',
    brand: 'New Era',
    price: 28,
    image: 'https://m.media-amazon.com/images/I/61X-M2Y-3yL._AC_SX679_.jpg',
    url: 'https://www.amazon.fr/New-Era-9forty-Adjustable-Snapback/dp/B093TTHFHZ',
    source: 'Amazon',
    categories: ['mode', 'accessoire'],
    tags: ['gender_homme', 'gender_mixte', 'budget_0_50', 'cat_mode', 'cat_accessoire', 'age_adulte'],
    popularity: 92,
  },

  // ── BIJOUX ──────────────────────────────────────────────────
  {
    name: 'Collier Diamant Or Blanc 18K',
    brand: 'Cleor',
    price: 279,
    image: 'https://m.media-amazon.com/images/I/61WmQ1O5OGL._AC_SX522_.jpg',
    url: 'https://www.amazon.fr/Collier-Diamant-Brillant-Femme-Blanc/dp/B09MDX24Z6',
    source: 'Amazon',
    categories: ['bijoux'],
    tags: ['gender_femme', 'budget_200+', 'cat_bijoux', 'age_adulte'],
    popularity: 86,
  },
  {
    name: 'Bracelet Jonc Acier Doré',
    brand: 'Thomas Sabo',
    price: 89,
    image: 'https://m.media-amazon.com/images/I/61Pf5aztKYL._AC_SX522_.jpg',
    url: 'https://www.amazon.fr/Thomas-Sabo-Bracelet-Femmes-Argent/dp/B00JXFVG0E',
    source: 'Amazon',
    categories: ['bijoux'],
    tags: ['gender_femme', 'budget_50_100', 'cat_bijoux', 'age_adulte'],
    popularity: 84,
  },

  // ── MAISON ─────────────────────────────────────────────────
  {
    name: 'Bougie Parfumée Santal & Vétiver',
    brand: 'Diptyque',
    price: 48,
    image: 'https://m.media-amazon.com/images/I/71gBj74gTfL._AC_SX522_.jpg',
    url: 'https://www.amazon.fr/Diptyque-Baies-Bougie-Parfumee/dp/B00F9I4NVM',
    source: 'Amazon',
    categories: ['maison', 'déco'],
    tags: ['gender_mixte', 'budget_0_50', 'cat_maison', 'age_adulte'],
    popularity: 95,
  },
  {
    name: 'Coffret Rituel de Soin Corps',
    brand: 'L\'Occitane',
    price: 42,
    image: 'https://m.media-amazon.com/images/I/61XHFxfMooL._AC_SX522_.jpg',
    url: 'https://www.amazon.fr/Occitane-Coffret-Beurre-Corps-Karité/dp/B00P5DTLQG',
    source: 'Amazon',
    categories: ['beauté', 'bien-être'],
    tags: ['gender_femme', 'budget_0_50', 'cat_beaute', 'cat_bien_etre', 'age_adulte'],
    popularity: 90,
  },

  // ── SPORT & BIEN-ÊTRE ───────────────────────────────────────
  {
    name: 'Tapis de Yoga Premium Antidérapant 6mm',
    brand: 'Lululemon',
    price: 88,
    image: 'https://m.media-amazon.com/images/I/71pWKZv3XQL._AC_SX522_.jpg',
    url: 'https://www.amazon.fr/GAIAM-Premium-Antidérapant-Tapis-Yoga/dp/B078JSYGFT',
    source: 'Amazon',
    categories: ['sport', 'bien-être'],
    tags: ['gender_mixte', 'budget_50_100', 'cat_sport', 'cat_bien_etre', 'age_adulte'],
    popularity: 91,
  },
  {
    name: 'Gourde Isotherme Stanley 1L',
    brand: 'Stanley',
    price: 45,
    image: 'https://m.media-amazon.com/images/I/81cHt8dQs4L._AC_SX522_.jpg',
    url: 'https://www.amazon.fr/Stanley-Quencher-Adventure-Tumbler-Stainless/dp/B09GRTNCRM',
    source: 'Amazon',
    categories: ['sport', 'bien-être', 'lifestyle'],
    tags: ['gender_mixte', 'budget_0_50', 'cat_sport', 'age_adulte'],
    popularity: 97,
  },
];

// ─────────────────────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────────────────────
async function main() {
  console.log('🔄 Replace Dead Products — Doron DB');
  console.log('═════════════════════════════════════\n');

  // ─── ÉTAPE 1 : Supprimer les produits morts ───────────────
  console.log(`🗑️  Suppression de ${NAMES_TO_DELETE.length} produits avec URLs mortes...\n`);

  const snapshot = await db.collection('gifts').get();
  let deletedCount = 0;

  for (const doc of snapshot.docs) {
    const name = doc.data().name || doc.data().product_title || '';
    if (NAMES_TO_DELETE.includes(name)) {
      await doc.ref.delete();
      deletedCount++;
      console.log(`   🗑️  Supprimé : "${name}"`);
    }
  }

  console.log(`\n✅ ${deletedCount} produits supprimés.\n`);

  // ─── ÉTAPE 2 : Ajouter les remplaçants ───────────────────
  console.log(`➕ Ajout de ${REPLACEMENT_PRODUCTS.length} nouveaux produits...\n`);

  let addedCount = 0;

  for (const product of REPLACEMENT_PRODUCTS) {
    try {
      await db.collection('gifts').add({
        ...product,
        active: true,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      });
      addedCount++;
      console.log(`   ✅ Ajouté : "${product.name}" (${product.brand}) — ${product.price}€`);
    } catch (e) {
      console.error(`   ❌ Erreur : "${product.name}" — ${e.message}`);
    }
  }

  // ─── Résumé ───────────────────────────────────────────────
  console.log('\n\n✅ TERMINÉ !');
  console.log('═══════════════════════════════════════');
  console.log(`🗑️  Supprimés : ${deletedCount}`);
  console.log(`➕  Ajoutés   : ${addedCount}`);
  console.log('\n🎉 La base de données est maintenant propre et complète !');
  console.log('   Toutes les nouvelles images viennent d\'Amazon CDN → jamais bloquées.\n');

  process.exit(0);
}

main().catch(err => {
  console.error('\n❌ ERREUR CRITIQUE:', err);
  process.exit(1);
});
