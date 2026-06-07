import '/utils/app_logger.dart';
import 'dart:convert';
import 'package:doron/services/http_service.dart';
import '/environment_values.dart';

/// Service pour analyser les transcriptions vocales avec OpenAI (GPT-4o).
///
/// Ce service est actif — il effectue de vrais appels API OpenAI pour
/// transformer une transcription vocale en profil structuré (tags Doron).
/// La clé API est lue depuis les variables d'environnement (assets).
class OpenAIVoiceAnalysisService {
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  static String get _apiKey {
    final key = FFDevEnvironmentValues().openAiApiKey;
    if (key.isEmpty) {
      throw Exception('OpenAI API Key not configured in environment_values.');
    }
    return key;
  }

  /// Dernière erreur pour affichage diagnostique
  static String _lastErrorMessage = '';
  static String get lastErrorMessage => _lastErrorMessage;

  /// Analyse une transcription vocale et extrait un profil structuré (tags Doron).
  static Future<Map<String, dynamic>?> analyzeVoiceTranscript(
    String transcript,
  ) async {
    _lastErrorMessage = '';

    if (transcript.trim().isEmpty) {
      _lastErrorMessage = 'Transcript vide';
      AppLogger.warning('Voice transcript is empty', 'VoiceAnalysis');
      return null;
    }

    AppLogger.info('?? Analyzing voice transcript (${transcript.length} chars)', 'VoiceAnalysis');

    try {
      final prompt = _buildAnalysisPrompt(transcript);
      final rawResponse = await _callOpenAI(prompt);

      if (rawResponse == null) return null;

      final parsed = _parseOpenAIResponse(rawResponse);
      if (parsed == null) {
        _lastErrorMessage = 'Impossible de parser la réponse OpenAI';
        return null;
      }

      AppLogger.success('Voice analysis succeeded. Keys: ${parsed.keys.join(', ')}', 'VoiceAnalysis');
      return parsed;
    } catch (e) {
      _lastErrorMessage = 'Exception: ${e.toString().substring(0, e.toString().length.clamp(0, 100))}';
      AppLogger.error('Voice analysis failed', 'VoiceAnalysis', e);
      return null;
    }
  }

  /// Construit le prompt pour l'analyse vocale avec les TAGS OFFICIELS DORON
  static String _buildAnalysisPrompt(String transcript) {
    return '''Tu es un assistant spécialisé dans l\'analyse de descriptions de personnes pour des recommandations de cadeaux.
Tu dois extraire les informations et les convertir en TAGS OFFICIELS du système DORON.

TRANSCRIPTION VOCALE DE L\'UTILISATEUR:
"$transcript"

TÂCHE:
Analyse cette transcription et génère les TAGS OFFICIELS au format JSON STRICT.

FORMAT DE RÉPONSE REQUIS (JSON uniquement, sans texte supplémentaire):
{
  "recipientType": "Maman | Papa | Amie | Ami | Copine | Copain | Frère | Sœur | Grand-mère | Grand-père | Collègue | Patron | Autre",
  "recipientName": "Prénom si mentionné, sinon null",
  "budget": nombre (le maximum en euros),
  "age": nombre ou null,
  "gender": "Femme | Homme | Non spécifié",
  "genderTag": "gender_femme | gender_homme | gender_mixte",
  "categoryTags": ["cat_tendances", "cat_tech", "cat_mode", "cat_maison", "cat_beaute", "cat_food"],
  "budgetTag": "budget_0_50 | budget_50_100 | budget_100_200 | budget_200+",
  "styleTags": ["style_elegant", "style_tendance", "style_minimaliste", "style_classique", "style_decontracte", "style_sportif", "style_vintage", "style_moderne", "style_luxe"],
  "personalityTags": ["perso_creatif", "perso_actif", "perso_cool", "perso_bienveillant", "perso_ambitieux", "perso_romantique", "perso_aventurier", "perso_intellectuel", "perso_sociable", "perso_zen"],
  "passionTags": ["passion_sport", "passion_cuisine", "passion_voyages", "passion_photo", "passion_jeuxvideo", "passion_lecture", "passion_musique", "passion_mode", "passion_tech"],
  "giftTypeTags": ["type_mode_accessoires", "type_bien_etre", "type_sport_outdoor", "type_gastronomie", "type_culture", "type_high_tech"],
  "occasion": "Anniversaire | Noël | Fête des mères | Fête des pères | Mariage | Saint-Valentin | Autre | non spécifié",
  "specialNotes": "Notes additionnelles importantes"
}

RÈGLES STRICTES POUR LES TAGS:
1. genderTag: TOUJOURS 1 seul tag parmi gender_femme, gender_homme, gender_mixte
2. budgetTag: TOUJOURS 1 seul tag calculé selon le budget
3. categoryTags: LISTE de 1 à 3 catégories principales
4. styleTags, personalityTags, passionTags, giftTypeTags: LISTES (plusieurs possibles)

Réponds UNIQUEMENT avec le JSON, sans texte avant ou après.''';
  }

  /// Appelle l'API OpenAI GPT-4o
  static Future<String?> _callOpenAI(String prompt) async {
    try {
      final body = json.encode({
        'model': 'gpt-4o',
        'messages': [
          {
            'role': 'system',
            'content': 'Tu es un expert en analyse de données pour recommandations de cadeaux. Tu réponds toujours en JSON valide.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.3,
        'max_tokens': 1000,
      });

      final response = await HttpService.postWithRetry(
        url: Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_apiKey}',
        },
        body: body,
        timeoutSeconds: 45,
        maxRetries: 3,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices']?[0]?['message']?['content']?.toString().trim();
      }

      switch (response.statusCode) {
        case 401:
          _lastErrorMessage = 'Clé API invalide ou expirée (401)';
        case 429:
          _lastErrorMessage = 'Limite de requêtes dépassée (429)';
        default:
          _lastErrorMessage = 'Erreur HTTP ${response.statusCode}';
      }
      AppLogger.error(_lastErrorMessage, 'VoiceAnalysis');
      return null;
    } catch (e) {
      _lastErrorMessage = 'Erreur réseau: ${e.runtimeType}';
      AppLogger.error('OpenAI call failed', 'VoiceAnalysis', e);
      return null;
    }
  }

  /// Parse la réponse JSON d'OpenAI (enlève le markdown si présent)
  static Map<String, dynamic>? _parseOpenAIResponse(String response) {
    try {
      String cleaned = response.trim();
      if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
      else if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
      if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
      return json.decode(cleaned.trim()) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Error parsing OpenAI response', 'VoiceAnalysis', e);
      return null;
    }
  }

  /// Convertit l'analyse OpenAI en format compatible avec [ProductMatchingService]
  static Map<String, dynamic> convertToGiftProfile(Map<String, dynamic> analysis) {
    final genderTag = analysis['genderTag'] as String? ?? '';
    final gender = genderTag.contains('femme')
        ? 'Femme'
        : genderTag.contains('homme')
            ? 'Homme'
            : 'Non spécifié';

    final categoryTags = (analysis['categoryTags'] as List?)?.cast<String>() ?? [];
    final preferredCategories = categoryTags.map((tag) {
      if (tag.contains('tendances')) return 'Tendances';
      if (tag.contains('tech')) return 'Tech';
      if (tag.contains('mode')) return 'Mode';
      if (tag.contains('maison')) return 'Maison';
      if (tag.contains('beaute')) return 'Beauté';
      if (tag.contains('food')) return 'Food';
      return tag;
    }).toList();

    final styleTags = (analysis['styleTags'] as List?)?.cast<String>() ?? [];
    final style = _styleFromTag(styleTags.isNotEmpty ? styleTags.first : '');

    final passionTags = (analysis['passionTags'] as List?)?.cast<String>() ?? [];
    final interests = passionTags.map((tag) => tag.replaceFirst('passion_', '')).toList();

    final personalityTags = (analysis['personalityTags'] as List?)?.cast<String>() ?? [];
    final personality = personalityTags.isNotEmpty
        ? personalityTags.first.replaceFirst('perso_', '')
        : null;

    return {
      'gender': gender,
      'recipientGender': gender,
      'budget': (analysis['budget'] ?? 100).toString(),
      'preferredCategories': preferredCategories,
      'style': style,
      'interests': interests,
      'personality': personality,
      'recipient': analysis['recipientType'] ?? 'Autre',
      'recipientAge': analysis['age']?.toString() ?? '',
      'occasion': analysis['occasion'] ?? 'non spécifié',
      'sourceType': 'voice',
      'rawTranscript': '',
    };
  }

  static String _styleFromTag(String tag) {
    if (tag.contains('elegant')) return 'Élégant';
    if (tag.contains('tendance')) return 'Tendance';
    if (tag.contains('minimaliste')) return 'Minimaliste';
    if (tag.contains('classique')) return 'Classique';
    if (tag.contains('decontracte')) return 'Décontracté';
    if (tag.contains('sportif')) return 'Sportif';
    if (tag.contains('vintage')) return 'Vintage';
    return 'Moderne';
  }

  /// Génère un résumé textuel de l'analyse
  static String generateSummary(Map<String, dynamic> analysis) {
    final recipient = analysis['recipientType'] ?? 'cette personne';
    final name = analysis['recipientName'];
    final age = analysis['age'];
    final budget = analysis['budget'];
    final occasion = analysis['occasion'];

    final buffer = StringBuffer();
    buffer.write(name != null && name.toString().isNotEmpty ? 'Pour $name' : 'Pour $recipient');
    if (age != null) buffer.write(', $age ans');
    if (occasion != null && occasion != 'non spécifié') buffer.write('\nOccasion: $occasion');
    if (budget != null) buffer.write('\nBudget: jusqu\'à ${budget}€');
    return buffer.toString();
  }
}
