import '/backend/backend.dart';
import '/services/firebase_data_service.dart';

/// Repository des wishlists (listes de souhaits).
///
/// Gère les wishlists de l'utilisateur avec support de taille illimitée
/// (batches de 30 pour contourner la limite Firestore whereIn).
class WishlistRepository {
  const WishlistRepository();

  /// Crée une nouvelle wishlist.
  /// [personId] est optionnel : permet d'associer la wishlist à un destinataire.
  Future<String?> create({
    required String name,
    String? personId,
    String? emoji,
  }) =>
      FirebaseDataService.createWishlist(
        name: name,
        personId: personId,
        emoji: emoji,
      );

  /// Charge toutes les wishlists, optionnellement filtrées par destinataire.
  Future<List<Map<String, dynamic>>> loadAll({String? personId}) =>
      FirebaseDataService.loadWishlists(personId: personId);

  /// Ajoute un produit à une wishlist.
  Future<bool> addProduct(String wishlistId, String favoriteId) =>
      FirebaseDataService.addToWishlist(wishlistId, favoriteId);

  /// Retire un produit d'une wishlist.
  Future<bool> removeProduct(String wishlistId, String favoriteId) =>
      FirebaseDataService.removeProductFromWishlist(wishlistId, favoriteId);

  /// Charge tous les produits d'une wishlist (taille illimitée, batches de 30).
  Future<List<FavouritesRecord>> loadProducts(String wishlistId) =>
      FirebaseDataService.loadWishlistProducts(wishlistId);

  /// Supprime une wishlist et son contenu.
  Future<bool> delete(String wishlistId) =>
      FirebaseDataService.deleteWishlist(wishlistId);
}
