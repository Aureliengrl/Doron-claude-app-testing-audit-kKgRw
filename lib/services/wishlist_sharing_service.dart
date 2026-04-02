import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '/utils/app_logger.dart';

/// Service de partage de wishlists via lien unique.
class WishlistSharingService {
  static final _db = FirebaseFirestore.instance;
  static String? get _myUid => FirebaseAuth.instance.currentUser?.uid;

  /// Génère ou récupère un lien de partage pour une wishlist.
  /// Retourne le token (court, 12 caractères).
  static Future<String> getOrCreateShareToken(String wishlistId) async {
    final myUid = _myUid;
    if (myUid == null) throw Exception('Non connecté');

    try {
      // Vérifier si un token existe déjà
      final wishlistDoc = await _db
          .collection('users')
          .doc(myUid)
          .collection('wishlists')
          .doc(wishlistId)
          .get();

      final existingToken = wishlistDoc.data()?['shareToken'] as String?;
      if (existingToken != null && existingToken.isNotEmpty) {
        return existingToken;
      }

      // Générer un nouveau token
      final token = const Uuid().v4().replaceAll('-', '').substring(0, 12);

      // Sauvegarder le token dans la wishlist
      await _db
          .collection('users')
          .doc(myUid)
          .collection('wishlists')
          .doc(wishlistId)
          .update({
        'shareToken': token,
        'isPublic': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Créer un document de référence pour la résolution du token
      await _db.collection('shared_wishlists').doc(token).set({
        'ownerUid': myUid,
        'wishlistId': wishlistId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      AppLogger.debug('Share token created: $token for $wishlistId', 'Wishlist');
      return token;
    } catch (e) {
      AppLogger.debug('WishlistSharingService.getOrCreateShareToken: $e', 'Wishlist');
      rethrow;
    }
  }

  /// Génère l'URL de partage complète.
  static Future<String> getShareUrl(String wishlistId) async {
    final token = await getOrCreateShareToken(wishlistId);
    return 'https://doron.app/wishlist/$token';
  }

  /// Résout un token de partage en wishlist data.
  static Future<Map<String, dynamic>?> resolveShareToken(String token) async {
    try {
      final doc = await _db.collection('shared_wishlists').doc(token).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      final ownerUid = data['ownerUid'] as String;
      final wishlistId = data['wishlistId'] as String;

      // Charger la wishlist
      final wishlistDoc = await _db
          .collection('users')
          .doc(ownerUid)
          .collection('wishlists')
          .doc(wishlistId)
          .get();

      if (!wishlistDoc.exists) return null;

      return {
        'ownerUid': ownerUid,
        'wishlistId': wishlistId,
        ...wishlistDoc.data()!,
      };
    } catch (e) {
      AppLogger.debug('WishlistSharingService.resolveShareToken: $e', 'Wishlist');
      return null;
    }
  }

  /// Révoque le lien de partage d'une wishlist.
  static Future<void> revokeShareToken(String wishlistId) async {
    final myUid = _myUid;
    if (myUid == null) return;

    try {
      final wishlistDoc = await _db
          .collection('users')
          .doc(myUid)
          .collection('wishlists')
          .doc(wishlistId)
          .get();

      final token = wishlistDoc.data()?['shareToken'] as String?;
      if (token != null) {
        await _db.collection('shared_wishlists').doc(token).delete();
      }

      await _db
          .collection('users')
          .doc(myUid)
          .collection('wishlists')
          .doc(wishlistId)
          .update({
        'shareToken': FieldValue.delete(),
      });
    } catch (e) {
      AppLogger.debug('WishlistSharingService.revokeShareToken: $e', 'Wishlist');
    }
  }
}
