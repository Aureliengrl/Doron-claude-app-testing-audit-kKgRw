#!/usr/bin/env node

/**
 * Transforme les produits pour le format attendu par l'app Flutter
 */

const fs = require('fs');

// Charger les produits
const products = JSON.parse(
  fs.readFileSync('./scripts/affiliate/websearch_real_products.json', 'utf8')
);

console.log(`📦 Transformation de ${products.length} produits...`);

// Transformer pour le format Flutter
const flutterProducts = products.map(product => {
  return {
    id: product.id,
    name: product.name,
    brand: product.brand,
    price: product.price,
    url: product.url,
    image: product.image,  // Garder "image" pour compatibilité
    product_photo: product.image,  // AJOUTER product_photo pour Flutter
    product_title: product.name,  // AJOUTER product_title
    product_url: product.url,  // AJOUTER product_url
    product_price: String(product.price),  // AJOUTER product_price (en string)
    description: product.description,
    categories: product.categories,
    tags: product.tags,
    popularity: product.popularity,
    source: product.source
  };
});

// Sauvegarder
fs.writeFileSync(
  './assets/jsons/fallback_products.json',
  JSON.stringify(flutterProducts, null, 2)
);

console.log('✅ Produits transformés avec les bons champs Flutter!');
console.log('\nChamps ajoutés:');
console.log('  - product_photo (pour les images)');
console.log('  - product_title (pour les noms)');
console.log('  - product_url (pour les URLs)');
console.log('  - product_price (pour les prix en string)');

// Vérifier le premier produit
console.log('\n📋 Exemple du premier produit:');
console.log(JSON.stringify(flutterProducts[0], null, 2));
