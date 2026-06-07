import 'abstract_market_api.dart';
import 'rakuten_api_service.dart';

class MultiMarketService {
  // Singleton pattern pour l'utiliser partout facilement
  static final MultiMarketService _instance = MultiMarketService._internal();
  factory MultiMarketService() => _instance;
  MultiMarketService._internal();

  // Liste des fournisseurs actifs
  final List<AbstractMarketApi> _providers = [
    RakutenApiService(),
    // On pourra ajouter EbayApiService() ici plus tard
  ];

  /// Recherche des produits sur TOUS les fournisseurs en parallèle
  Future<List<Map<String, dynamic>>> searchAcrossMarkets(String query, {int limitPerProvider = 10}) async {
    if (query.trim().isEmpty) return [];

    List<Map<String, dynamic>> allResults = [];

    // Lance toutes les requêtes en même temps (en parallèle)
    final futures = _providers.map((provider) => provider.searchProducts(query, limit: limitPerProvider));
    
    // Attend que tout le monde réponde
    final resultsSets = await Future.wait(futures);

    // Mélange les résultats
    for (var resultSet in resultsSets) {
      allResults.addAll(resultSet);
    }

    // Optionnel : trier les résultats (par prix, ou les mélanger aléatoirement)
    allResults.shuffle(); 

    return allResults;
  }

  /// Tente de rafraîchir le prix d'un produit (Background Sync)
  Future<Map<String, dynamic>?> refreshProductPrice(Map<String, dynamic> product) async {
    final source = product['source'] as String?;
    final productId = product['id'] as String?;

    if (source == null || productId == null) return null;

    // Trouve le bon fournisseur
    for (final provider in _providers) {
      if (provider.providerName == source) {
        return await provider.getProductDetails(productId);
      }
    }
    return null;
  }
}
