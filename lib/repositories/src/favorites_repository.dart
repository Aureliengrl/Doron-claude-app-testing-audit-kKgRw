import '/services/firebase_data_service.dart';

/// Repository des produits favoris.
///
/// Gère les produits likés par l'utilisateur (ajout, suppression, lecture)
/// avec persistance dans la sous-collection Firestore `favorites`.
class FavoritesRepository {
  const FavoritesRepository();

  /// Ajoute un produit aux favoris.
  Future<void> add(Map<String, dynamic> product) =>
      FirebaseDataService.addToFavorites(product);

  /// Retire un produit des favoris.
  Future<void> remove(String productId) =>
      FirebaseDataService.removeFromFavorites(productId);

  /// Charge tous les favoris de l'utilisateur.
  Future<List<Map<String, dynamic>>> loadAll() =>
      FirebaseDataService.loadFavorites();

  /// Vérifie si un produit est dans les favoris.
  Future<bool> isFavorite(String productId) =>
      FirebaseDataService.isFavorite(productId);
}
