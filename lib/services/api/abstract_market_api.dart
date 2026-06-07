abstract class AbstractMarketApi {
  /// Nom du fournisseur (ex: "Rakuten", "eBay")
  String get providerName;

  /// Recherche globale de produits selon un mot clé
  Future<List<Map<String, dynamic>>> searchProducts(String query, {int limit = 20});

  /// Récupération des détails d'un produit spécifique (incluant son prix mis à jour)
  Future<Map<String, dynamic>?> getProductDetails(String productId);
}
