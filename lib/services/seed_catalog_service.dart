import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/utils/app_logger.dart';

class SeedCatalogService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Injecte l'intégralité du catalogue (400+ produits) dans la collection 'gifts' de Firestore.
  static Future<int> seedFirestoreGifts({
    Function(int current, int total)? onProgress,
    bool forceOverwrite = false,
  }) async {
    try {
      AppLogger.debug('🚀 [SeedCatalog] Début du chargement de fallback_products.json...', 'Catalog');
      final jsonStr = await rootBundle.loadString('assets/jsons/fallback_products.json');
      final List<dynamic> rawList = jsonDecode(jsonStr);

      final total = rawList.length;
      AppLogger.debug('📦 [SeedCatalog] $total produits trouvés dans le JSON.', 'Catalog');

      int processed = 0;
      const int batchSize = 400;

      for (int i = 0; i < total; i += batchSize) {
        final batch = _db.batch();
        final end = (i + batchSize < total) ? i + batchSize : total;
        final chunk = rawList.sublist(i, end);

        for (final item in chunk) {
          final map = Map<String, dynamic>.from(item as Map);
          final rawId = map['id']?.toString() ?? 'prod_${processed}';
          final cleanDocId = rawId.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');

          final docRef = _db.collection('gifts').doc(cleanDocId);

          final brandStr = (map['brand'] ?? '').toString().trim();
          final rawCats = (map['categories'] as List?)?.cast<String>() ?? ['trending'];
          final brandClean = brandStr.toLowerCase();
          final brandNorm = brandClean.replaceAll('&', '').replaceAll(' ', '').replaceAll('-', '');
          final enrichedCategories = {...rawCats, brandClean, brandNorm}.where((c) => c.isNotEmpty).toList();

          // Normalisation des champs pour compatibilité totale avec MatchingEngine & HomePinterest
          final docData = <String, dynamic>{
            'name': map['name'] ?? map['product_title'] ?? 'Produit',
            'product_title': map['name'] ?? map['product_title'] ?? 'Produit',
            'brand': brandStr,
            'brandId': brandStr.toLowerCase(),
            'price': _parsePrice(map['price'] ?? map['product_price']),
            'product_price': (map['price'] ?? map['product_price'])?.toString() ?? '0.0',
            'image': map['image'] ?? map['product_photo'] ?? '',
            'product_photo': map['image'] ?? map['product_photo'] ?? '',
            'url': map['url'] ?? map['product_url'] ?? '',
            'product_url': map['url'] ?? map['product_url'] ?? '',
            'description': map['description'] ?? '',
            'categories': enrichedCategories,
            'keywords': (map['keywords'] as List?)?.cast<String>() ?? [],
            'tags': (map['tags'] as List?)?.cast<String>() ?? ['gender_mixte'],
            'popularity': map['popularity'] is num ? (map['popularity'] as num).toInt() : 90,
            'active': true,
            'isNew': map['isNew'] == true,
            'source': map['source'] ?? 'Doron Catalog',
            'updatedAt': FieldValue.serverTimestamp(),
          };

          batch.set(docRef, docData, SetOptions(merge: true));
          processed++;
        }

        await batch.commit();
        AppLogger.debug('✅ [SeedCatalog] Batch commité : $processed/$total produits enregistrés dans Firebase.', 'Catalog');
        if (onProgress != null) {
          onProgress(processed, total);
        }
      }

      AppLogger.debug('🎉 [SeedCatalog] Injection Firebase terminée avec succès ($processed produits) !', 'Catalog');
      return processed;
    } catch (e, stack) {
      AppLogger.debug('❌ [SeedCatalog] Erreur injection: $e\n$stack', 'Catalog');
      rethrow;
    }
  }

  /// Déclenche l'injection automatique au démarrage de l'app si la base Firestore est vide
  static Future<void> autoSeedIfEmpty() async {
    try {
      final snap = await _db.collection('gifts').limit(15).get();
      if (snap.docs.length < 10) {
        AppLogger.debug('⚠️ [SeedCatalog] Moins de 10 produits dans Firebase, lancement auto-seed...', 'Catalog');
        await seedFirestoreGifts();
      }
    } catch (e) {
      AppLogger.debug('⚠️ [SeedCatalog] AutoSeed skipped: $e', 'Catalog');
    }
  }

  static double _parsePrice(dynamic val) {
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) {
      final clean = val.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(clean) ?? 0.0;
    }
    return 0.0;
  }
}
