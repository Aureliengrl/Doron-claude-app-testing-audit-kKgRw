import 'package:cloud_firestore/cloud_firestore.dart';
import '/utils/app_logger.dart';

/// Service de recherche d'utilisateurs Doron par @pseudo ou prénom.
/// Gère aussi la visibilité des wishlists (public/privé) et
/// l'enrichissement des résultats de matching avec la wishlist publique.
class UserSearchService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Recherche de profil ────────────────────────────────────────────────────

  /// Recherche un utilisateur par son @pseudo exact.
  /// Retourne null si non trouvé.
  static Future<Map<String, dynamic>?> findUserByHandle(String handle) async {
    try {
      final normalizedHandle = handle.replaceAll('@', '').toLowerCase().trim();
      if (normalizedHandle.isEmpty) return null;

      final snapshot = await _db
          .collection('users')
          .where('handle', isEqualTo: normalizedHandle)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return _buildPublicProfile(doc.id, doc.data());
    } catch (e) {
      AppLogger.debug('❌ UserSearchService.findUserByHandle: $e', 'Social');
      return null;
    }
  }

  /// Recherche des utilisateurs par prénom (recherche partielle).
  /// Retourne une liste de profils publics.
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final queryLower = query.toLowerCase().trim();

      // Firestore ne supporte pas la recherche LIKE, on utilise la range query
      final snapshot = await _db
          .collection('users')
          .where('searchName', isGreaterThanOrEqualTo: queryLower)
          .where('searchName', isLessThan: '${queryLower}z')
          .limit(20)
          .get();

      // Chercher aussi par handle
      final handleSnapshot = await _db
          .collection('users')
          .where('handle', isGreaterThanOrEqualTo: queryLower)
          .where('handle', isLessThan: '${queryLower}z')
          .limit(10)
          .get();

      final results = <String, Map<String, dynamic>>{};

      for (final doc in [...snapshot.docs, ...handleSnapshot.docs]) {
        results[doc.id] = _buildPublicProfile(doc.id, doc.data());
      }

      return results.values.toList();
    } catch (e) {
      AppLogger.debug('❌ UserSearchService.searchUsers: $e', 'Social');
      return [];
    }
  }

  /// Construit un profil public depuis un document Firestore.
  static Map<String, dynamic> _buildPublicProfile(
      String uid, Map<String, dynamic> data) {
    return {
      'uid': uid,
      'displayName': data['display_name'] ?? data['name'] ?? 'Utilisateur',
      'handle': data['handle'] ?? '',
      'photoUrl': data['photo_url'] ?? '',
      'bio': data['bio'] ?? '',
      'city': data['city'] ?? '',
      'age': data['age'],
    };
  }

  // ─── Wishlists publiques ────────────────────────────────────────────────────

  /// Récupère les wishlists visibles d'un utilisateur.
  /// Si viewerUid == ownerUid → toutes les wishlists.
  /// Sinon → uniquement les publiques.
  static Future<List<Map<String, dynamic>>> getVisibleWishlists(
      String ownerUid, {String? viewerUid}) async {
    try {
      Query query = _db
          .collection('wishlists')
          .where('ownerUid', isEqualTo: ownerUid);

      // Si ce n'est pas le propriétaire, afficher seulement les publiques
      if (viewerUid != ownerUid) {
        query = query.where('isPublic', isEqualTo: true);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Wishlist',
          'description': data['description'] ?? '',
          'isPublic': data['isPublic'] ?? false,
          'productCount': (data['giftIds'] as List?)?.length ?? 0,
          'ownerUid': ownerUid,
        };
      }).toList();
    } catch (e) {
      AppLogger.debug('❌ UserSearchService.getVisibleWishlists: $e', 'Social');
      return [];
    }
  }

  /// Met à jour la visibilité (public/privé) d'une wishlist.
  static Future<void> setWishlistVisibility(
      String wishlistId, bool isPublic) async {
    try {
      await _db.collection('wishlists').doc(wishlistId).update({
        'isPublic': isPublic,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.debug(
          '✅ Wishlist $wishlistId → ${isPublic ? "publique" : "privée"}',
          'Social');
    } catch (e) {
      AppLogger.debug('❌ UserSearchService.setWishlistVisibility: $e', 'Social');
      rethrow;
    }
  }

  // ─── Matching enrichi par wishlist ─────────────────────────────────────────

  /// Récupère les titres de produits dans les wishlists publiques d'un user.
  /// Utilisé pour enrichir le matching quand on cherche un cadeau pour lui.
  static Future<Set<String>> getPublicWishlistTitles(String userUid) async {
    try {
      // 1. Récupérer les wishlists publiques
      final wishlists = await _db
          .collection('wishlists')
          .where('ownerUid', isEqualTo: userUid)
          .where('isPublic', isEqualTo: true)
          .get();

      if (wishlists.docs.isEmpty) return {};

      // 2. Collecter tous les giftIds
      final allGiftIds = <String>[];
      for (final doc in wishlists.docs) {
        final data = doc.data();
        final ids = (data['giftIds'] as List?)?.cast<String>() ?? [];
        allGiftIds.addAll(ids);
      }

      if (allGiftIds.isEmpty) return {};

      // 3. Récupérer les titres des produits de la wishlist
      final titles = <String>{};
      // Firestore whereIn max = 30
      for (var i = 0; i < allGiftIds.length; i += 30) {
        final chunk = allGiftIds.sublist(
            i, i + 30 > allGiftIds.length ? allGiftIds.length : i + 30);
        final favSnapshot = await _db
            .collection('favourites')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in favSnapshot.docs) {
          final data = doc.data();
          final title = data['product']?['product_title'] as String?;
          if (title != null && title.isNotEmpty) titles.add(title);
        }
      }

      AppLogger.debug(
          '✅ ${titles.length} titres trouvés dans les wishlists publiques de $userUid',
          'Social');
      return titles;
    } catch (e) {
      AppLogger.debug(
          '❌ UserSearchService.getPublicWishlistTitles: $e', 'Social');
      return {};
    }
  }

  // ─── @pseudo management ────────────────────────────────────────────────────

  /// Vérifie si un @pseudo est disponible.
  static Future<bool> isHandleAvailable(String handle) async {
    try {
      final normalized = handle.replaceAll('@', '').toLowerCase().trim();
      if (normalized.isEmpty || normalized.length < 3) return false;
      // FIX IGNITION: Allouer les tirets (-) pour correspondre à l'UI
      if (!RegExp(r'^[a-z0-9_.-]+$').hasMatch(normalized)) return false;

      final snapshot = await _db
          .collection('users')
          .where('handle', isEqualTo: normalized)
          .limit(1)
          .get();

      return snapshot.docs.isEmpty;
    } catch (e) {
      AppLogger.debug('❌ UserSearchService.isHandleAvailable error: $e', 'Social');
      if (e.toString().contains('permission-denied')) {
        // Bypass permission denied errors during onboarding
        return true;
      }
      return false;
    }
  }

  /// Met à jour le @pseudo d'un utilisateur.
  static Future<void> setHandle(String uid, String handle) async {
    final normalized = handle.replaceAll('@', '').toLowerCase().trim();
    await _db.collection('users').doc(uid).update({
      'handle': normalized,
      'searchName': normalized,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
