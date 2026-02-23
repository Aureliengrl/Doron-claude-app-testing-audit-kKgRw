import '/utils/app_logger.dart';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Script Flutter pour gérer les produits Firebase
/// Utilise les credentials Firebase déjà configurés dans l'app
class FirebaseProductsManager {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Supprime tous les produits de Firebase
  static Future<void> deleteAllProducts() async {
    AppLogger.debug('🗑️  Suppression de tous les produits...\n', 'Debug');

    try {
      // Compter les produits
      final countQuery = await _firestore.collection('products').count().get();
      final totalCount = countQuery.count ?? 0;

      if (totalCount == 0) {
        AppLogger.debug('✅ Aucun produit à supprimer', 'Debug');
        return;
      }

      AppLogger.debug('   Produits à supprimer: $totalCount\n', 'Debug');

      int deletedCount = 0;
      const batchSize = 500;

      while (true) {
        // Récupérer un batch
        final snapshot = await _firestore
            .collection('products')
            .limit(batchSize)
            .get();

        if (snapshot.docs.isEmpty) break;

        // Créer un batch de suppression
        final batch = _firestore.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        // Commit
        await batch.commit();
        deletedCount += snapshot.docs.length;

        AppLogger.debug('   ✅ $deletedCount/$totalCount produits supprimés...', 'Debug');

        // Petit délai
        await Future.delayed(const Duration(milliseconds: 200));
      }

      AppLogger.debug('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', 'Debug');
      AppLogger.debug('✅ SUPPRESSION TERMINÉE!', 'Debug');
      AppLogger.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', 'Debug');
      AppLogger.debug('   Total supprimé: $deletedCount produits\n', 'Debug');
    } catch (e) {
      AppLogger.debug('❌ Erreur: $e', 'Debug');
      rethrow;
    }
  }

  /// Upload tous les produits depuis fallback_products.json
  static Future<void> uploadAllProducts() async {
    AppLogger.debug('🚀 Démarrage de l\'upload des produits...\n', 'Debug');

    try {
      // Lire le fichier JSON
      AppLogger.debug('📖 Lecture du fichier...', 'Debug');
      final jsonString = await rootBundle.loadString('assets/jsons/fallback_products.json');
      final List<dynamic> products = json.decode(jsonString);

      AppLogger.debug('✅ ${products.length} produits chargés\n', 'Debug');

      // Vérifier si la collection existe
      final snapshot = await _firestore.collection('products').limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        AppLogger.debug('⚠️  La collection "products" existe déjà', 'Debug');
        AppLogger.debug('   Les nouveaux produits seront ajoutés/mis à jour\n', 'Debug');
      }

      // Upload par batch
      const batchSize = 500;
      int uploadedCount = 0;
      int errorCount = 0;

      AppLogger.debug('📤 Upload des produits...', 'Debug');
      AppLogger.debug('   Batch size: $batchSize produits\n', 'Debug');

      for (int i = 0; i < products.length; i += batchSize) {
        final batch = _firestore.batch();
        final endIndex = (i + batchSize < products.length) ? i + batchSize : products.length;
        final currentBatch = products.sublist(i, endIndex);

        AppLogger.debug('📦 Batch ${(i ~/ batchSize) + 1}: Produits ${i + 1} à $endIndex...', 'Debug');

        for (var product in currentBatch) {
          try {
            final productMap = product as Map<String, dynamic>;
            final docRef = _firestore.collection('products').doc(productMap['id'].toString());

            // Retirer l'ID du map (il sera dans le document ID)
            final data = Map<String, dynamic>.from(productMap);
            data.remove('id');

            // Assurer que les arrays sont corrects
            if (!data.containsKey('tags')) data['tags'] = [];
            if (!data.containsKey('categories')) data['categories'] = [];

            batch.set(docRef, data);
            uploadedCount++;
          } catch (e) {
            AppLogger.debug('   ⚠️  Erreur produit ${product['id']}: $e', 'Debug');
            errorCount++;
          }
        }

        // Commit le batch
        try {
          await batch.commit();
          AppLogger.debug('   ✅ Batch ${(i ~/ batchSize) + 1} uploadé (${currentBatch.length} produits)', 'Debug');

          // Délai pour éviter de surcharger Firebase
          if (endIndex < products.length) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } catch (e) {
          AppLogger.debug('   ❌ Erreur upload batch ${(i ~/ batchSize) + 1}: $e', 'Debug');
          errorCount += currentBatch.length;
        }
      }

      AppLogger.debug('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', 'Debug');
      AppLogger.debug('✅ UPLOAD TERMINÉ!', 'Debug');
      AppLogger.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', 'Debug');
      AppLogger.debug('📊 Statistiques:', 'Debug');
      AppLogger.debug('   - Produits uploadés: $uploadedCount', 'Debug');
      AppLogger.debug('   - Erreurs: $errorCount', 'Debug');
      AppLogger.debug('   - Total: ${products.length} produits', 'Debug');

      // Vérification finale
      AppLogger.debug('\n🔍 Vérification finale...', 'Debug');
      final finalCount = await _firestore.collection('products').count().get();
      AppLogger.debug('   Collection "products" contient: ${finalCount.count} documents', 'Debug');

      // Test avec filtre
      AppLogger.debug('\n🧪 Test de requête avec filtre sexe...', 'Debug');
      final maleQuery = await _firestore
          .collection('products')
          .where('tags', arrayContains: 'homme')
          .limit(10)
          .get();
      AppLogger.debug('   - Produits avec tag "homme": ${maleQuery.docs.length} trouvés', 'Debug');

      final femaleQuery = await _firestore
          .collection('products')
          .where('tags', arrayContains: 'femme')
          .limit(10)
          .get();
      AppLogger.debug('   - Produits avec tag "femme": ${femaleQuery.docs.length} trouvés', 'Debug');

      AppLogger.debug('\n✨ Firebase est maintenant peuplé!', 'Debug');
      AppLogger.debug('   L\'app devrait afficher des produits variés.\n', 'Debug');
    } catch (e) {
      AppLogger.debug('❌ Erreur fatale: $e', 'Debug');
      rethrow;
    }
  }

  /// Menu interactif pour choisir l'opération
  static Future<void> runInteractive() async {
    AppLogger.debug('\n═══════════════════════════════════════════════════════', 'Debug');
    AppLogger.debug('     GESTION DES PRODUITS FIREBASE', 'Debug');
    AppLogger.debug('═══════════════════════════════════════════════════════\n', 'Debug');
    AppLogger.debug('Que veux-tu faire ?\n', 'Debug');
    AppLogger.debug('1. Supprimer tous les produits', 'Debug');
    AppLogger.debug('2. Uploader les nouveaux produits', 'Debug');
    AppLogger.debug('3. Supprimer ET re-uploader (recommandé)', 'Debug');
    AppLogger.debug('4. Quitter\n', 'Debug');

    stdout.write('Choix (1-4): ');
    final choice = stdin.readLineSync();

    switch (choice) {
      case '1':
        await deleteAllProducts();
        break;
      case '2':
        await uploadAllProducts();
        break;
      case '3':
        await deleteAllProducts();
        AppLogger.debug('\n⏸️  Pause de 2 secondes...\n', 'Debug');
        await Future.delayed(const Duration(seconds: 2));
        await uploadAllProducts();
        break;
      case '4':
        AppLogger.debug('👋 À bientôt!', 'Debug');
        break;
      default:
        AppLogger.debug('❌ Choix invalide', 'Debug');
    }
  }
}
