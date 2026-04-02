/// Script pour peupler Firebase avec des produits pré-générés
/// Usage: dart run scripts/populate_products.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  print('🚀 Démarrage du script de population de produits...');

  // Initialiser Firebase (vous devrez adapter avec vos credentials)
  await Firebase.initializeApp();

  final firestore = FirebaseFirestore.instance;
  final products = generateProducts();

  print('📦 ${products.length} produits générés');
  print('💾 Upload vers Firebase...');

  int uploaded = 0;
  for (var product in products) {
    try {
      await firestore.collection('products').add(product);
      uploaded++;
      if (uploaded % 50 == 0) {
        print('   ✓ $uploaded/${ products.length} produits uploadés');
      }
    } catch (e) {
      print('   ❌ Erreur upload produit: $e');
    }
  }

  print('✅ Upload terminé: $uploaded produits dans Firebase');
  exit(0);
}

List<Map<String, dynamic>> generateProducts() {
  final products = <Map<String, dynamic>>[];

  // Tech - Homme
  products.addAll([
    {
      'name': 'AirPods Pro 2ème génération',
      'brand': 'Apple',
      'price': 279,
      'description': 'Écouteurs sans fil avec réduction de bruit active et audio spatial',
      'image': 'https://images.unsplash.com/photo-1606841837239-c5a1a4a07af7?w=400',
      'url': 'https://www.apple.com/fr/airpods-pro/',
      'source': 'Apple',
      'tags': ['tech', 'audio', 'homme', 'femme', 'premium', '20-30ans', '30-50ans', 'moderne'],
      'categories': ['tech'],
      'popularity': 95,
    },
    {
      'name': 'PlayStation 5 Console',
      'brand': 'Sony',
      'price': 549,
      'description': 'Console de jeux nouvelle génération 4K',
      'image': 'https://images.unsplash.com/photo-1606813907291-d86efa9b94db?w=400',
      'url': 'https://www.playstation.com/fr-fr/ps5/',
      'source': 'Sony',
      'tags': ['gaming', 'tech', 'homme', '20-30ans', 'jeux-vidéo', 'premium'],
      'categories': ['tech'],
      'popularity': 98,
    },
    {
      'name': 'iPad Air M2',
      'brand': 'Apple',
      'price': 699,
      'description': 'Tablette puissante pour créativité et productivité',
      'image': 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=400',
      'url': 'https://www.apple.com/fr/ipad-air/',
      'source': 'Apple',
      'tags': ['tech', 'tablette', 'homme', 'femme', 'travail', 'créatif', 'premium'],
      'categories': ['tech'],
      'popularity': 90,
    },
    {
      'name': 'Montre connectée Apple Watch Series 9',
      'brand': 'Apple',
      'price': 449,
      'description': 'Montre intelligente avec suivi santé et fitness',
      'image': 'https://images.unsplash.com/photo-1434494878577-86c23bcb06b9?w=400',
      'url': 'https://www.apple.com/fr/apple-watch-series-9/',
      'source': 'Apple',
      'tags': ['tech', 'sport', 'homme', 'femme', 'fitness', '20-30ans', '30-50ans'],
      'categories': ['tech'],
      'popularity': 92,
    },
    {
      'name': 'Casque Gaming HyperX Cloud III',
      'brand': 'HyperX',
      'price': 99,
      'description': 'Casque gaming avec son surround 7.1',
      'image': 'https://images.unsplash.com/photo-1612287230202-1ff1d85d1bdf?w=400',
      'url': 'https://www.amazon.fr/s?k=hyperx+cloud+3',
      'source': 'Amazon',
      'tags': ['gaming', 'tech', 'homme', '20-30ans', 'jeux-vidéo', 'audio'],
      'categories': ['tech'],
      'popularity': 85,
    },
  ]);

  // Mode - Femme
  products.addAll([
    {
      'name': 'Sac à main Michael Kors Jet Set',
      'brand': 'Michael Kors',
      'price': 195,
      'description': 'Sac en cuir élégant et spacieux',
      'image': 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=400',
      'url': 'https://www.michaelkors.fr/',
      'source': 'Michael Kors',
      'tags': ['mode', 'femme', 'luxe', 'élégant', '30-50ans', 'accessoire'],
      'categories': ['fashion'],
      'popularity': 88,
    },
    {
      'name': 'Bottines Chelsea en cuir',
      'brand': 'Dr. Martens',
      'price': 169,
      'description': 'Bottines emblématiques en cuir véritable',
      'image': 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=400',
      'url': 'https://www.drmartens.com/fr/fr/',
      'source': 'Dr. Martens',
      'tags': ['mode', 'femme', 'homme', 'chaussures', 'rock', '20-30ans', 'moderne'],
      'categories': ['fashion'],
      'popularity': 82,
    },
    {
      'name': 'Écharpe en cachemire',
      'brand': 'Burberry',
      'price': 450,
      'description': 'Écharpe classique en cachemire à motif emblématique',
      'image': 'https://images.unsplash.com/photo-1601924994987-69e26d50dc26?w=400',
      'url': 'https://fr.burberry.com/',
      'source': 'Burberry',
      'tags': ['mode', 'femme', 'homme', 'luxe', 'hiver', 'élégant', 'premium'],
      'categories': ['fashion'],
      'popularity': 90,
    },
  ]);

  // Beauté - Femme
  products.addAll([
    {
      'name': 'Palette Naked Urban Decay',
      'brand': 'Urban Decay',
      'price': 54,
      'description': 'Palette de fards à paupières nude iconique',
      'image': 'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?w=400',
      'url': 'https://www.sephora.fr/p/naked-palette-P416005.html',
      'source': 'Sephora',
      'tags': ['beauté', 'femme', 'maquillage', '20-30ans', '30-50ans', 'makeup'],
      'categories': ['beauty'],
      'popularity': 87,
    },
    {
      'name': 'Coffret Dior Sauvage',
      'brand': 'Dior',
      'price': 89,
      'description': 'Coffret parfum homme avec eau de toilette et déodorant',
      'image': 'https://images.unsplash.com/photo-1541643600914-78b084683601?w=400',
      'url': 'https://www.sephora.fr/marques/dior/sauvage/',
      'source': 'Sephora',
      'tags': ['beauté', 'homme', 'parfum', '20-30ans', '30-50ans', 'luxe'],
      'categories': ['beauty'],
      'popularity': 93,
    },
    {
      'name': 'Crème La Mer',
      'brand': 'La Mer',
      'price': 350,
      'description': 'Crème hydratante de luxe anti-âge',
      'image': 'https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=400',
      'url': 'https://www.sephora.fr/marques/la-mer/',
      'source': 'Sephora',
      'tags': ['beauté', 'femme', 'soin', 'luxe', '30-50ans', '50+', 'premium'],
      'categories': ['beauty'],
      'popularity': 85,
    },
  ]);

  // Maison & Déco
  products.addAll([
    {
      'name': 'Bougie parfumée Diptyque Baies',
      'brand': 'Diptyque',
      'price': 68,
      'description': 'Bougie luxueuse aux notes de baies et roses',
      'image': 'https://images.unsplash.com/photo-1602874801006-ae7cdaa06ea4?w=400',
      'url': 'https://www.diptyqueparis.com/',
      'source': 'Diptyque',
      'tags': ['maison', 'déco', 'femme', 'luxe', 'cocooning', '30-50ans'],
      'categories': ['home'],
      'popularity': 88,
    },
    {
      'name': 'Machine à café Nespresso Vertuo',
      'brand': 'Nespresso',
      'price': 179,
      'description': 'Machine à café à capsules avec technologie Centrifusion',
      'image': 'https://images.unsplash.com/photo-1517668808822-9ebb02f2a0e6?w=400',
      'url': 'https://www.nespresso.com/fr/fr/',
      'source': 'Nespresso',
      'tags': ['maison', 'cuisine', 'homme', 'femme', 'café', 'pratique'],
      'categories': ['home'],
      'popularity': 90,
    },
    {
      'name': 'Lampe Philips Hue',
      'brand': 'Philips',
      'price': 59,
      'description': 'Ampoule connectée RGB avec contrôle via app',
      'image': 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?w=400',
      'url': 'https://www.philips-hue.com/fr-fr',
      'source': 'Philips',
      'tags': ['maison', 'tech', 'déco', 'moderne', 'connecté'],
      'categories': ['home', 'tech'],
      'popularity': 83,
    },
  ]);

  // Sport & Fitness
  products.addAll([
    {
      'name': 'Tapis de yoga Lululemon',
      'brand': 'Lululemon',
      'price': 88,
      'description': 'Tapis de yoga antidérapant haute qualité',
      'image': 'https://images.unsplash.com/photo-1601925260368-ae2f83cf8b7f?w=400',
      'url': 'https://www.lululemon.fr/',
      'source': 'Lululemon',
      'tags': ['sport', 'yoga', 'femme', 'fitness', 'wellness', '20-30ans'],
      'categories': ['sport'],
      'popularity': 80,
    },
    {
      'name': 'Gourde Stanley 1L',
      'brand': 'Stanley',
      'price': 45,
      'description': 'Bouteille isotherme gardant boissons chaudes/froides 24h',
      'image': 'https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=400',
      'url': 'https://www.stanley1913.com/',
      'source': 'Stanley',
      'tags': ['sport', 'pratique', 'homme', 'femme', 'outdoor', 'écolo'],
      'categories': ['sport'],
      'popularity': 92,
    },
  ]);

  // Food & Boissons
  products.addAll([
    {
      'name': 'Coffret dégustation whisky',
      'brand': 'Glenfiddich',
      'price': 89,
      'description': 'Coffret de 3 whiskies single malt pour découverte',
      'image': 'https://images.unsplash.com/photo-1527281400683-1aae777175f8?w=400',
      'url': 'https://www.whisky.fr/',
      'source': 'La Maison du Whisky',
      'tags': ['food', 'alcool', 'homme', '30-50ans', '50+', 'luxe', 'gourmet'],
      'categories': ['food'],
      'popularity': 85,
    },
    {
      'name': 'Coffret chocolats Pierre Hermé',
      'brand': 'Pierre Hermé',
      'price': 65,
      'description': 'Assortiment de chocolats fins et macarons',
      'image': 'https://images.unsplash.com/photo-1549007994-cb92caebd54b?w=400',
      'url': 'https://www.pierreherme.com/',
      'source': 'Pierre Hermé',
      'tags': ['food', 'chocolat', 'femme', 'homme', 'gourmet', 'luxe', 'cadeau'],
      'categories': ['food'],
      'popularity': 90,
    },
  ]);

  // Dupliquer et varier pour atteindre ~500 produits
  final baseProducts = List<Map<String, dynamic>>.from(products);
  final variations = [
    'Version 2023',
    'Édition limitée',
    'Pack duo',
    'Format voyage',
    'Nouvelle collection',
  ];

  for (int i = 0; i < 20; i++) {
    for (var baseProduct in baseProducts) {
      final variation = variations[i % variations.length];
      final variedProduct = Map<String, dynamic>.from(baseProduct);
      variedProduct['name'] = '${baseProduct['name']} - $variation';
      variedProduct['price'] = (baseProduct['price'] as int) + (i * 5 - 50);
      products.add(variedProduct);

      if (products.length >= 500) break;
    }
    if (products.length >= 500) break;
  }

  return products.take(500).toList();
}
