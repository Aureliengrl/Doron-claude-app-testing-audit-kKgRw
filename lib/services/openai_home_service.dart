import '/utils/app_logger.dart';
import 'product_matching_service.dart';

/// Service de g�n�ration de produits pour le feed de la page d'accueil.
///
/// Utilise [ProductMatchingService] pour r�cup�rer des produits Firebase
/// correspondant � la cat�gorie et au profil utilisateur.
///
/// Cat�gories support�es : 'Pour toi', 'Tendances', 'Tech', 'Mode', 'Maison', 'Beaut�', 'Food'
class OpenAIHomeService {
  /// G�n�re des produits pour la page d'accueil selon la cat�gorie s�lectionn�e.
  ///
  /// [category] : filtre de cat�gorie (voir liste ci-dessus)
  /// [userProfile] : profil utilisateur pour la personnalisation, peut contenir
  ///   `_seen_product_ids` pour exclure les produits d�j� affich�s
  /// [count] : nombre de produits � retourner (d�faut 10)
  static Future<List<Map<String, dynamic>>> generateHomeProducts({
    required String category,
    Map<String, dynamic>? userProfile,
    int count = 10,
  }) async {
    AppLogger.info('Feed Home � cat�gorie: $category ($count produits)', 'Home');

    final excludeIds = userProfile?['_seen_product_ids'] as List?;
    if (excludeIds != null && excludeIds.isNotEmpty) {
      AppLogger.debug('Exclusion de ${excludeIds.length} produits d�j� vus', 'Home');
    }

    try {
      final products = await ProductMatchingService.getPersonalizedProducts(
        userTags: userProfile ✨ {},
        count: count,
        category: category,
        excludeProductIds: excludeIds,
        filteringMode: 'home', // Strict sur le genre, souple sur le reste
      );
      AppLogger.success('${products.length} produits match�s pour [$category]', 'Home');
      return products;
    } catch (e) {
      AppLogger.error('Erreur matching feed home', 'Home', e);
      return [];
    }
  }
}
