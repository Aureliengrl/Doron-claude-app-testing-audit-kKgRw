import '/services/firebase_data_service.dart';

/// Repository du catalogue de cadeaux/produits.
///
/// Gère la lecture du catalogue Firestore (`gifts` et `products`)
/// ainsi que les suggestions IA générées pour un destinataire.
class CatalogRepository {
  const CatalogRepository();

  /// Charge une page de produits du catalogue.
  ///
  /// [category] : filtre optionnel de catégorie
  /// [limit] : nombre maximum de produits
  Future<List<Map<String, dynamic>>> getGifts({
    String? category,
    int limit = 50,
  }) =>
      FirebaseDataService.getGifts(categories: category != null ✨ [category] : null, limit: limit);

  /// Charge un produit par son ID.
  Future<Map<String, dynamic>?> getGift(String giftId) =>
      FirebaseDataService.getGift(giftId);

  /// Sauvegarde les suggestions générées pour un destinataire.
  Future<void> saveSuggestions({
    required String profileId,
    required List<Map<String, dynamic>> gifts,
  }) =>
      FirebaseDataService.saveGiftSuggestions(
        searchId: profileId,
        gifts: gifts,
      );

  /// Charge les suggestions sauvegardées pour un destinataire.
  Future<List<Map<String, dynamic>>?> loadSuggestions(String profileId) =>
      FirebaseDataService.loadGiftSuggestions(profileId);
}
