import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/services/firebase_data_service.dart';
import '/utils/app_logger.dart';

/// Service de réservation de cadeaux dans les wishlists partagées.
/// Permet à un ami de "réserver" un produit pour éviter les doublons,
/// tout en le gardant invisible pour le propriétaire de la wishlist.
class GiftReservationService {
  static final _db = FirebaseFirestore.instance;
  static String? get _myUid => FirebaseDataService.currentUserId;

  /// Réserve un produit dans une wishlist partagée.
  /// [ownerUid] = propriétaire de la wishlist.
  /// [wishlistId] = ID de la wishlist.
  /// [productId] = ID du produit dans la wishlist.
  static Future<bool> reserveGift({
    required String ownerUid,
    required String wishlistId,
    required String productId,
  }) async {
    final myUid = _myUid;
    if (myUid == null || myUid == ownerUid) return false;

    try {
      final ref = _db
          .collection('gift_reservations')
          .doc('${wishlistId}_$productId');

      final existing = await ref.get();
      if (existing.exists) {
        // Déjà réservé par quelqu'un
        return false;
      }

      await ref.set({
        'reservedBy': myUid,
        'ownerUid': ownerUid,
        'wishlistId': wishlistId,
        'productId': productId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      AppLogger.debug(
          'Gift reserved: $productId in $wishlistId', 'Reservation');
      return true;
    } catch (e) {
      AppLogger.debug(
          'GiftReservationService.reserveGift: $e', 'Reservation');
      return false;
    }
  }

  /// Annule la réservation d'un produit.
  static Future<bool> cancelReservation({
    required String wishlistId,
    required String productId,
  }) async {
    final myUid = _myUid;
    if (myUid == null) return false;

    try {
      final ref = _db
          .collection('gift_reservations')
          .doc('${wishlistId}_$productId');

      final doc = await ref.get();
      if (!doc.exists) return false;
      if (doc.data()?['reservedBy'] != myUid) return false;

      await ref.delete();
      return true;
    } catch (e) {
      AppLogger.debug(
          'GiftReservationService.cancelReservation: $e', 'Reservation');
      return false;
    }
  }

  /// Vérifie si un produit est réservé.
  /// Retourne null si non réservé, sinon le UID du réserveur.
  /// Note: le propriétaire de la wishlist ne devrait PAS voir les réservations.
  static Future<String?> getReservedBy({
    required String wishlistId,
    required String productId,
  }) async {
    try {
      final doc = await _db
          .collection('gift_reservations')
          .doc('${wishlistId}_$productId')
          .get();
      if (!doc.exists) return null;
      return doc.data()?['reservedBy'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Charge toutes les réservations pour une wishlist.
  /// Retourne une Map productId → reservedByUid.
  /// IMPORTANT: Ne pas montrer au propriétaire de la wishlist!
  static Future<Map<String, String>> getReservationsForWishlist(
      String wishlistId) async {
    try {
      final snap = await _db
          .collection('gift_reservations')
          .where('wishlistId', isEqualTo: wishlistId)
          .get();

      final reservations = <String, String>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final productId = data['productId'] as String?;
        final reservedBy = data['reservedBy'] as String?;
        if (productId != null && reservedBy != null) {
          reservations[productId] = reservedBy;
        }
      }
      return reservations;
    } catch (e) {
      AppLogger.debug(
          'GiftReservationService.getReservationsForWishlist: $e',
          'Reservation');
      return {};
    }
  }

  /// Stream temps réel des réservations pour une wishlist.
  static Stream<Map<String, String>> reservationsStream(String wishlistId) {
    return _db
        .collection('gift_reservations')
        .where('wishlistId', isEqualTo: wishlistId)
        .snapshots()
        .map((snap) {
      final reservations = <String, String>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final productId = data['productId'] as String?;
        final reservedBy = data['reservedBy'] as String?;
        if (productId != null && reservedBy != null) {
          reservations[productId] = reservedBy;
        }
      }
      return reservations;
    });
  }
}
