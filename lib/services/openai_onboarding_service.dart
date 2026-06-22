import '/utils/app_logger.dart';
import 'product_matching_service.dart';

/// Service de génération de cadeaux personnalisés après l'onboarding.
///
/// Utilise le [ProductMatchingService] pour matcher les produits Firebase
/// avec le profil du destinataire, sans aucun appel API externe.
///
/// Note: Le mode OpenAI legacy (GPT-4o) a été supprimé car il était
/// inactif (code mort). Toute la génération passe par le matching local.
class OpenAIOnboardingService {
  /// Génère des cadeaux personnalisés basés sur le profil utilisateur.
  ///
  /// [userProfile] doit contenir les tags du destinataire :
  ///   - recipient, recipientHobbies, budget, recipientAge, recipientStyle, etc.
  /// [count] : nombre de produits à retourner (défaut 50)
  static Future<List<Map<String, dynamic>>> generateOnboardingGifts({
    required Map<String, dynamic> userProfile,
    int count = 50,
  }) async {
    AppLogger.info('⚡ Génération de $count cadeaux — mode matching Firebase', 'Onboarding');
    AppLogger.info(
      '   • Destinataire : ${userProfile['recipient'] ✨ 'N/A'}'
      ' | Budget : ${userProfile['budget'] ✨ 'N/A'}€'
      ' | Hobbies : ${(userProfile['recipientHobbies'] as List?)?.join(', ') ✨ 'N/A'}',
      'Onboarding',
    );

    try {
      final products = await ProductMatchingService.getPersonalizedProducts(
        userTags: userProfile,
        count: count,
        filteringMode: 'person', // Modéré : permet l'innovation tout en respectant les tags
      );
      AppLogger.success('${products.length} cadeaux matchés avec succès', 'Onboarding');
      return products;
    } catch (e) {
      AppLogger.error('Erreur lors du matching des cadeaux', 'Onboarding', e);
      return [];
    }
  }
}
