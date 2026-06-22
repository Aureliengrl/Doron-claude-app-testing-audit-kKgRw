import '/utils/app_logger.dart';
import 'product_matching_service.dart';

/// Service de génération de produits pour le feed de la page d'accueil.
///
/// Utilise [ProductMatchingService] pour récupérer des produits Firebase
/// correspondant à la catégorie et au profil utilisateur.
///
/// Catégories supportées : 'Pour toi', 'Tendances', 'Tech', 'Mode', 'Maison', 'Beauté', 'Food'
class OpenAIHomeService {
  /// Génère des produits pour la page d'accueil selon la catégorie sélectionnée.
  ///
  /// [category] : filtre de catégorie (voir liste ci-dessus)
  /// [userProfile] : profil utilisateur pour la personnalisation, peut contenir
  ///   `_seen_product_ids` pour exclure les produits déjà affichés
  /// [count] : nombre de produits à retourner (défaut 10)
  static Future<List<Map<String, dynamic>>> generateHomeProducts({
    required String category,
    Map<String, dynamic>? userProfile,
    int count = 10,
  }) async {
    AppLogger.info('? Feed Home — catégorie: $category ($count produits)', 'Home');

    final excludeIds = userProfile?['_seen_product_ids'] as List?;
    if (excludeIds != null && excludeIds.isNotEmpty) {
      AppLogger.debug('?? Exclusion de ${excludeIds.length} produits déjà vus', 'Home');
    }

    try {
      final products = await ProductMatchingService.getPersonalizedProducts(
        userTags: userProfile ?? {},
        count: count,
        category: category,
        excludeProductIds: excludeIds,
        filteringMode: 'home', // Strict sur le genre, souple sur le reste
      );
      AppLogger.success('${products.length} produits matchés pour [$category]', 'Home');
      return products;
    } catch (e) {
      AppLogger.error('Erreur matching feed home', 'Home', e);
      return [];
    }
  }
}
