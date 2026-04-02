#!/usr/bin/env node

/**
 * Upload les produits DIRECTEMENT dans Firebase avec le bon format Flutter
 * SANS utiliser l'app TestFlight
 */

const admin = require('firebase-admin');
const fs = require('fs');

async function uploadProducts() {
  console.log('🔥 CONNEXION À FIREBASE...');

  try {
    // Vérifier si Firebase est déjà initialisé
    if (admin.apps.length === 0) {
      // Initialiser avec les credentials publiques (Web API)
      admin.initializeApp({
        projectId: 'doron-b3011'
      });
    }
    console.log('⚠️  Mode Firebase Web (sans credentials admin)');
    console.log('   Pour uploader, utilise la Firebase Console:\n');
  } catch (error) {
    console.error('❌ Erreur:', error.message);
  }

  // Charger et transformer les produits
  const products = JSON.parse(
    fs.readFileSync('./scripts/affiliate/websearch_real_products.json', 'utf8')
  );

  console.log(`📦 ${products.length} produits chargés\n`);

  // Transformer pour Firebase (format compatible Flutter)
  const firebaseData = {};

  products.forEach(product => {
    const id = String(product.id);

    firebaseData[id] = {
      name: product.name,
      brand: product.brand,
      price: product.price,
      url: product.url,
      image: product.image,
      product_photo: product.image,  // ← CRUCIAL pour Flutter
      product_title: product.name,
      product_url: product.url,
      product_price: String(product.price),
      description: product.description || '',
      categories: product.categories || [],
      tags: product.tags || [],
      popularity: product.popularity || 50,
      source: product.source || 'websearch_verified'
    };
  });

  // Sauvegarder le fichier pour import manuel
  const outputFile = './firebase-import-ready.json';
  fs.writeFileSync(outputFile, JSON.stringify(firebaseData, null, 2));

  console.log(`✅ Fichier créé: ${outputFile}`);
  console.log(`📦 ${Object.keys(firebaseData).length} produits prêts\n`);

  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('📋 INSTRUCTIONS POUR UPLOADER DANS FIREBASE:');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  console.log('OPTION 1 - Via Firebase Console (SIMPLE):');
  console.log('─────────────────────────────────────────────\n');
  console.log('1. Va sur: https://console.firebase.google.com/project/doron-b3011/firestore');
  console.log('2. Clique sur "Firestore Database"');
  console.log('3. Supprime la collection "products" (clique sur ... → Delete collection)');
  console.log('4. Installe Firebase CLI: npm install -g firebase-tools');
  console.log('5. Login: firebase login');
  console.log('6. Importe: firestore:import firebase-import-ready.json\n');

  console.log('OPTION 2 - Via TestFlight (RE-UPLOAD):');
  console.log('─────────────────────────────────────────────\n');
  console.log('1. Rebuild l\'app avec le nouveau fallback_products.json');
  console.log('2. Upload sur TestFlight');
  console.log('3. Dans l\'app, va dans Admin');
  console.log('4. Clique "Supprimer et Re-uploader"\n');

  console.log('OPTION 3 - Script Python avec Firebase Admin SDK:');
  console.log('─────────────────────────────────────────────\n');
  console.log('Si tu as des credentials admin valides, utilise:');
  console.log('python3 scripts/upload_with_correct_fields.py\n');

  // Afficher un exemple de produit
  const firstProduct = Object.values(firebaseData)[0];
  console.log('📋 EXEMPLE DE PRODUIT (avec tous les champs):');
  console.log('─────────────────────────────────────────────\n');
  console.log(JSON.stringify(firstProduct, null, 2));
  console.log('\n✅ Note: Le champ "product_photo" contient l\'URL de l\'image!');

  process.exit(0);
}

uploadProducts().catch(error => {
  console.error('❌ Erreur:', error);
  process.exit(1);
});
