import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/utils/app_logger.dart';

/// Service pour rafraîchir les données produits (prix, images, URLs).
/// Communique avec les Cloud Functions pour le scraping automatique.
class ProductRefreshService {
  static final _db = FirebaseFirestore.instance;

  // URL de base des Cloud Functions (à configurer)
  static const _functionsBaseUrl = 'https://us-central1-doron-b3011.cloudfunctions.net';

  /// Déclenche un rafraîchissement manuel des produits.
  /// Nécessite un token d'authentification.
  static Future<Map<String, dynamic>> triggerRefresh({int? limit}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Non connecté');

    final token = await user.getIdToken();

    try {
      final response = await http.post(
        Uri.parse('$_functionsBaseUrl/refreshProductsManual'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'limit': limit ?? 9999}),
      ).timeout(const Duration(minutes: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      AppLogger.debug('ProductRefreshService.triggerRefresh: $e', 'ProductRefresh');
      rethrow;
    }
  }

  /// Récupère la liste des produits avec des problèmes.
  static Future<List<Map<String, dynamic>>> getProductIssues() async {
    try {
      final snapshot = await _db
          .collection('gifts')
          .where('hasIssues', isEqualTo: true)
          .where('active', isEqualTo: true)
          .limit(100)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? data['product_title'] ?? 'Inconnu',
          'brand': data['brand'] ?? '',
          'price': data['price']?.toString() ?? '',
          'image': data['image'] ?? '',
          'url': data['url'] ?? '',
          'imageStatus': data['imageStatus'] ?? 'unknown',
          'urlStatus': data['urlStatus'] ?? 'unknown',
          'lastChecked': data['lastChecked'],
        };
      }).toList();
    } catch (e) {
      AppLogger.debug('ProductRefreshService.getProductIssues: $e', 'ProductRefresh');
      return [];
    }
  }

  /// Récupère le dernier log de rafraîchissement.
  static Future<Map<String, dynamic>?> getLastRefreshLog() async {
    try {
      final doc = await _db.collection('system').doc('product_refresh_log').get();
      return doc.exists ? doc.data() : null;
    } catch (_) {
      return null;
    }
  }

  /// Met à jour manuellement un produit spécifique.
  static Future<void> updateProduct(String productId, Map<String, dynamic> updates) async {
    try {
      await _db.collection('gifts').doc(productId).update({
        ...updates,
        'hasIssues': false,
        'lastChecked': FieldValue.serverTimestamp(),
        'manuallyFixed': true,
      });
      AppLogger.debug('Product $productId updated manually', 'ProductRefresh');
    } catch (e) {
      AppLogger.debug('ProductRefreshService.updateProduct: $e', 'ProductRefresh');
      rethrow;
    }
  }

  /// Désactive un produit (le retire du catalogue).
  static Future<void> deactivateProduct(String productId) async {
    try {
      await _db.collection('gifts').doc(productId).update({
        'active': false,
        'deactivatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.debug('ProductRefreshService.deactivateProduct: $e', 'ProductRefresh');
    }
  }

  /// Valide une URL d'image (retourne true si accessible).
  static Future<bool> validateImageUrl(String url) async {
    if (url.isEmpty || !url.startsWith('http')) return false;
    try {
      final response = await http.head(Uri.parse(url)).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (_) {
      return false;
    }
  }
}
