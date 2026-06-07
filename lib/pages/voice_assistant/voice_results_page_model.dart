import '/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:doron/services/openai_voice_analysis_service.dart';
import 'package:doron/services/firebase_data_service.dart';
import 'package:doron/services/product_matching_service.dart';
import 'package:doron/services/product_url_service.dart';

/// Model pour la page de résultats vocaux
class VoiceResultsPageModel extends ChangeNotifier {
  Map<String, dynamic>? _analysis;
  String _transcript = '';
  List<Map<String, dynamic>> _products = [];
  bool _isGeneratingProducts = true;
  bool _hasError = false;
  String _errorMessage = '';
  String? _savedProfileId;

  List<Map<String, dynamic>> get products => _products;
  bool get isGeneratingProducts => _isGeneratingProducts;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  Map<String, dynamic>? get analysis => _analysis;
  String get summary => _generateSummary();

  /// Initialise et génère les produits
  Future<void> initialize({
    required Map<String, dynamic> analysis,
    required String transcript,
  }) async {
    _analysis = analysis;
    _transcript = transcript;

    AppLogger.debug('?? Initializing voice results with analysis: $analysis', 'Debug');

    // Générer les produits
    await generateProducts();
  }

  /// Génère les produits basés sur l'analyse
  /// FIX: Utiliser ProductMatchingService (Firebase) au lieu d'OpenAI pour avoir des images réelles
  Future<void> generateProducts() async {
    _isGeneratingProducts = true;
    _hasError = false;
    notifyListeners();

    try {
      AppLogger.debug('?? Generating products with ProductMatchingService (Firebase)...', 'Debug');

      // Convertir l'analyse vocale en format userTags pour ProductMatchingService
      final userTags = _convertToOnboardingFormat();

      // FIX: Utiliser ProductMatchingService pour avoir des produits avec images RÉELLES de Firebase
      final rawProducts = await ProductMatchingService.getPersonalizedProducts(
        userTags: userTags,
        count: 20, // Charger plus pour filtrer ceux sans images
        filteringMode: "person", // Mode personne pour cadeaux personnalisés
      );

      // FIX: Mapper les produits et filtrer ceux sans images valides
      final productsWithImages = rawProducts.map((product) {
        // Extraire l'image depuis plusieurs clés possibles
        String imageUrl = '';
        for (final key in ['image', 'imageUrl', 'photo', 'productPhoto', 'product_photo', 'img', 'thumbnail']) {
          if (product[key] != null && product[key].toString().isNotEmpty) {
            imageUrl = product[key].toString();
            break;
          }
        }

        // FIX CRASH: Conversion sécurisée du score (peut être int ou double)
        final matchScore = product['_matchScore'];
        final matchScoreInt = matchScore is int
            ? matchScore
            : (matchScore is double ? matchScore.toInt() : 0);

        return {
          'id': product['id'],
          'name': product['name'] ?? 'Produit',
          'brand': product['brand'] ?? 'Amazon',
          'price': product['price'] ?? 0,
          'image': imageUrl,
          'url': ProductUrlService.generateProductUrl(product),
          'match': matchScoreInt.clamp(0, 100),
        };
      })
      .where((product) {
        final hasImage = product['image'] != null &&
                         product['image'].toString().isNotEmpty &&
                         product['image'].toString().startsWith('http');
        if (!hasImage) {
          AppLogger.debug('?? Produit "${product['name']}" filtré: pas d\'image valide', 'Debug');
        }
        return hasImage;
      })
      .take(12) // Limiter à 12 produits
      .toList();

      if (productsWithImages.isNotEmpty) {
        AppLogger.debug('? Generated ${productsWithImages.length} products with valid images from Firebase', 'Debug');
        _products = productsWithImages;
        _isGeneratingProducts = false;
        _hasError = false;
      } else {
        AppLogger.debug('? No products with valid images found', 'Debug');
        _hasError = true;
        _errorMessage = 'Impossible de charger les suggestions. Veuillez réessayer.';
        _isGeneratingProducts = false;
      }

      notifyListeners();
    } catch (e) {
      AppLogger.debug('? Error generating products: $e', 'Debug');
      _hasError = true;
      _errorMessage = 'Une erreur est survenue lors du chargement des cadeaux.';
      _isGeneratingProducts = false;
      notifyListeners();
    }
  }

  /// Convertit l'analyse vocale en format compatible avec generateGiftSuggestions
  Map<String, dynamic> _convertToOnboardingFormat() {
    if (_analysis == null) return {};

    final budget = (_analysis!['budget']?['max'] ?? 50).toDouble();
    final hobbies = _analysis!['hobbies'] as List? ?? [];
    final interests = _analysis!['interests'] as List? ?? [];
    final personality = _analysis!['personality'] ?? '';

    return {
      // Informations sur le destinataire
      'recipient': _analysis!['recipientType'] ?? 'une personne',
      'budget': budget,
      'recipientAge': _analysis!['age']?.toString() ?? _analysis!['ageRange'] ?? 'adulte',
      'recipientHobbies': hobbies,
      'recipientPersonality': personality.isNotEmpty ? [personality] : [],
      'occasion': _analysis!['occasion'] ?? 'sans occasion',
      'recipientStyle': _analysis!['style'] ?? '',
      'recipientLifeSituation': '',
      'recipientAlreadyHas': _analysis!['avoidCategories'] ?? [],
      'recipientRelationDuration': '',

      // Informations sur l'utilisateur (valeurs par défaut car non capturées par vocal)
      'age': '',
      'gender': _analysis!['gender'] ?? '',
      'interests': interests,
      'style': '',
      'giftTypes': [],

      // Catégories préférées
      'preferredCategories': _analysis!['preferredCategories'] ?? [],
    };
  }

  /// Génère un résumé de l'analyse
  String _generateSummary() {
    if (_analysis == null) return '';
    return OpenAIVoiceAnalysisService.generateSummary(_analysis!);
  }

  /// Sauvegarde le profil dans Firebase
  Future<void> saveProfile() async {
    if (_analysis == null) return;

    try {
      AppLogger.debug('?? Saving voice profile to Firebase...', 'Debug');

      // Convertir l'analyse en profil de cadeau
      final profile = OpenAIVoiceAnalysisService.convertToGiftProfile(_analysis!);
      profile['rawTranscript'] = _transcript;

      // Sauvegarder dans Firebase
      final profileId = await FirebaseDataService.saveGiftProfile(profile);

      if (profileId != null) {
        _savedProfileId = profileId;
        AppLogger.debug('? Profile saved with ID: $profileId', 'Debug');
      }
    } catch (e) {
      AppLogger.debug('? Error saving profile: $e', 'Debug');
    }
  }

  /// Réessayer la génération de produits
  Future<void> retry() async {
    await generateProducts();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
