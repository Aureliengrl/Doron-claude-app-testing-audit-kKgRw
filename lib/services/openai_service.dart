import '/environment_values.dart';
import 'http_service.dart';

/// Façade OpenAI — fournit la clé API et les constantes partagées.
///
/// Les deux modes d'utilisation actifs sont :
///  - [OpenAIVoiceAnalysisService] : analyse vocale (appels GPT-4o réels)
///  - [ProductMatchingService] : matching Firebase (aucun appel OpenAI)
///
/// Note: toute la logique de génération de prompts, brands listes, et
/// fallback products a été supprimée — c'était du code mort.
class OpenAIService {
  /// Clé API OpenAI — lue depuis les variables d'environnement (assets).
  static String get apiKey {
    final key = FFDevEnvironmentValues().openAiApiKey;
    if (key.isEmpty) {
      throw Exception('OpenAI API Key not configured in environment_values.');
    }
    return key;
  }

  /// URL de base de l'API OpenAI
  static const String baseUrl = 'https://api.openai.com/v1';

  /// Service HTTP partagé (retry, timeout)
  static HttpService get httpService => HttpService();
}
