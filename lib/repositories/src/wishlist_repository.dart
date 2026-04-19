import '/services/firebase_data_service.dart';

/// Repository des wishlists (listes de souhaits).
///
/// Gère les wishlists de l'utilisateur avec support de taille illimitée.
///
/// BUG 2 FIX: addProduct() appelle maintenant addProductToWishlist()
///   (nouvelle architecture sous-collection products) au lieu de la méthode
///   legacy addToWishlist() qui écrivait dans l'ancien champ productIds.
///
/// BUG 3 FIX: loadProducts() retourne List<Map<String,dynamic>> pour
///   correspondre au type exact retourné par FirebaseDataService.loadWishlistProducts().
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

  /// Ajoute un produit (Map complet) à une wishlist.
  /// BUG 2 FIX: utilise addProductToWishlist() — écrit dans la sous-collection
  /// products (nouvelle architecture) et non plus dans productIds (legacy).
  Future<bool> addProduct(String wishlistId, Map<String, dynamic> product) =>
      FirebaseDataService.addProductToWishlist(wishlistId, product);

  /// Retire un produit d'une wishlist.
  Future<bool> removeProduct(String wishlistId, String productId) =>
      FirebaseDataService.removeProductFromWishlist(wishlistId, productId);

  /// Charge tous les produits d'une wishlist.
  /// BUG 3 FIX: type de retour corrigé — Map<String,dynamic> au lieu de FavouritesRecord.
  Future<List<Map<String, dynamic>>> loadProducts(String wishlistId) =>
      FirebaseDataService.loadWishlistProducts(wishlistId);

  /// Supprime une wishlist et son contenu.
  Future<bool> delete(String wishlistId) =>
      FirebaseDataService.deleteWishlist(wishlistId);
}

