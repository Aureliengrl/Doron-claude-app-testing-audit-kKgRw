import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/services/firebase_data_service.dart';
import '/utils/app_logger.dart';

/// Service centralisé pour les produits likés.
/// TOUTES les opérations like/unlike passent par ce service.
/// Collection cible : users/{uid}/favorites (subcollection)
class FavouriteService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _favCol(String uid) =>
      _db.collection('users').doc(uid).collection('favorites');

  /// Retourne true si le produit (par nom) est déjà liké.
  static Future<bool> isLiked(String productName) async {
    final uid = FirebaseDataService.currentUserId;
    if (uid == null) return false;
    try {
      final snap = await _favCol(uid)
          .where('name', isEqualTo: productName)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Like ou unlike un produit. Retourne true si succès.
  static Future<bool> toggle(Map<String, dynamic> product) async {
    final uid = FirebaseDataService.currentUserId;
    if (uid == null) return false;

    final name = product['name'] as String? ??
        product['product_title'] as String? ??
        product['title'] as String? ?? 'Produit';
    final image = product['image'] as String? ??
        product['product_photo'] as String? ??
        product['imageUrl'] as String? ?? '';
    final url = product['url'] as String? ??
        product['product_url'] as String? ?? '';
    final brand = product['brand'] as String? ??
        product['source'] as String? ??
        product['platform'] as String? ?? '';
    final price = (product['price'] ?? product['product_price'] ?? '')
        .toString()
        .replaceAll('€', '')
        .trim();

    try {
      final col = _favCol(uid);
      final existing = await col.where('name', isEqualTo: name).limit(1).get();

      if (existing.docs.isNotEmpty) {
        // Unlike — supprimer
        for (final doc in existing.docs) {
          await doc.reference.delete();
        }
        AppLogger.debug('💔 Unlike: $name', 'Fav');
        return true;
      } else {
        // Like — ajouter
        final docId = 'fav_${DateTime.now().millisecondsSinceEpoch}';
        await col.doc(docId).set({
          'id': docId,
          'name': name,
          'brand': brand,
          'price': price,
          'image': image,
          'url': url,
          'createdAt': FieldValue.serverTimestamp(),
        });
        AppLogger.debug('❤️ Like: $name', 'Fav');
        return true;
      }
    } catch (e) {
      AppLogger.error('Erreur toggle favori', 'Fav', e);
      return false;
    }
  }

  /// Like direct (pas de toggle — ajoute même si pas encore liké).
  static Future<bool> like(Map<String, dynamic> product) async {
    final uid = FirebaseDataService.currentUserId;
    if (uid == null) return false;

    final name = product['name'] as String? ??
        product['product_title'] as String? ??
        product['title'] as String? ?? 'Produit';
    
    // Vérifier si déjà liké
    final alreadyLiked = await isLiked(name);
    if (alreadyLiked) return true;

    return toggle(product);
  }

  /// Unlike direct (retire si présent, ne fait rien sinon).
  static Future<bool> unlike(Map<String, dynamic> product) async {
    final uid = FirebaseDataService.currentUserId;
    if (uid == null) return false;

    final name = product['name'] as String? ??
        product['product_title'] as String? ??
        product['title'] as String? ?? 'Produit';

    try {
      final col = _favCol(uid);
      final existing = await col.where('name', isEqualTo: name).limit(5).get();
      for (final doc in existing.docs) {
        await doc.reference.delete();
      }
      return true;
    } catch (e) {
      AppLogger.error('Erreur unlike', 'Fav', e);
      return false;
    }
  }

  /// Stream temps réel des produits likés.
  static Stream<List<Map<String, dynamic>>> favStream() {
    final uid = FirebaseDataService.currentUserId;
    if (uid == null) return Stream.value([]);
    return _favCol(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final d = doc.data();
              return <String, dynamic>{
                'id': doc.id,
                'name': d['name'] ?? '',
                'brand': d['brand'] ?? '',
                'price': (d['price'] ?? '').toString(),
                'image': d['image'] ?? '',
                'url': d['url'] ?? '',
              };
            }).toList());
  }
}
