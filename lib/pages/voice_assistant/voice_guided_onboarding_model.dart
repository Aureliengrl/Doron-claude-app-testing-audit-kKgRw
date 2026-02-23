import '/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:doron/services/voice_assistant_service.dart';
import 'package:go_router/go_router.dart';

/// Model pour l'onboarding vocal guidé
/// Système de questions guidées avec transcription automatique
class VoiceGuidedOnboardingModel extends ChangeNotifier {
  final VoiceAssistantService _voiceService = VoiceAssistantService();

  // État du système de questions
  int _currentQuestionIndex = 0;
  final List<VoiceQuestion> _questions = [
    VoiceQuestion(
      id: 'recipient',
      text: 'Pour qui est le cadeau ?',
      hint: 'Ex: Pour ma mère, mon ami, ma copine...',
      tagKey: 'recipient',
    ),
    VoiceQuestion(
      id: 'age',
      text: 'Quel âge a cette personne ?',
      hint: 'Ex: 25 ans, environ 30 ans, la quarantaine...',
      tagKey: 'recipientAge',
    ),
    VoiceQuestion(
      id: 'gender',
      text: 'Est-ce un homme ou une femme ?',
      hint: 'Ex: C\'est une femme, un homme...',
      tagKey: 'recipientGender',
    ),
    VoiceQuestion(
      id: 'passions',
      text: 'Quelles sont ses passions ?',
      hint: 'Ex: Le sport, la lecture, la musique, les voyages...',
      tagKey: 'recipientHobbies',
    ),
    VoiceQuestion(
      id: 'style',
      text: 'Comment décrirais-tu son style ?',
      hint: 'Ex: Moderne, classique, sportif, élégant...',
      tagKey: 'style',
    ),
    VoiceQuestion(
      id: 'occasion',
      text: 'Quelle est l\'occasion ?',
      hint: 'Ex: Anniversaire, Noël, fête des mères...',
      tagKey: 'occasion',
    ),
    VoiceQuestion(
      id: 'budget',
      text: 'Quel est ton budget ?',
      hint: 'Ex: 50 euros, entre 20 et 100 euros...',
      tagKey: 'budget',
    ),
  ];

  // Réponses collectées
  final Map<String, String> _answers = {};

  // État de la transcription
  String _currentTranscript = '';
  bool _isListening = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isProcessing = false;

  // Getters
  int get currentQuestionIndex => _currentQuestionIndex;
  VoiceQuestion get currentQuestion => _questions[_currentQuestionIndex];
  List<VoiceQuestion> get questions => _questions;
  Map<String, String> get answers => _answers;
  String get currentTranscript => _currentTranscript;
  bool get isListening => _isListening;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  bool get isProcessing => _isProcessing;
  bool get isLastQuestion => _currentQuestionIndex == _questions.length - 1;
  int get progress => _currentQuestionIndex + 1;
  int get totalQuestions => _questions.length;

  /// Initialise le service vocal
  Future<void> initialize() async {
    AppLogger.debug('🎤 Initializing voice guided onboarding...', 'Debug');

    // Setup callbacks
    _voiceService.onTranscriptUpdate = (text) {
      _currentTranscript = text;
      notifyListeners();
    };

    _voiceService.onFinalTranscript = (text) {
      AppLogger.debug('✅ Final transcript received: $text', 'Debug');
      _currentTranscript = text;
      _isListening = false;
      notifyListeners();
    };

    _voiceService.onError = (error) {
      AppLogger.debug('❌ Voice error: $error', 'Debug');
      _hasError = true;
      _errorMessage = error;
      _isListening = false;
      notifyListeners();
    };

    // Initialize service
    final initialized = await _voiceService.initialize();
    if (!initialized) {
      _hasError = true;
      _errorMessage = 'Impossible d\'initialiser le microphone';
      notifyListeners();
    }

    // Auto-start listening pour la première question
    await Future.delayed(const Duration(milliseconds: 500));
    if (!_isListening) {
      startListening();
    }
  }

  /// Commence l'écoute pour la question actuelle
  Future<void> startListening() async {
    if (_isListening) return;

    AppLogger.debug('🎤 Starting listening for question ${_currentQuestionIndex + 1}...', 'Debug');
    _hasError = false;
    _errorMessage = '';
    _currentTranscript = '';
    _isListening = true;
    notifyListeners();

    await _voiceService.startListening();
  }

  /// Arrête l'écoute
  Future<void> stopListening() async {
    if (!_isListening) return;

    AppLogger.debug('🛑 Stopping listening...', 'Debug');
    await _voiceService.stopListening();
    _isListening = false;
    notifyListeners();
  }

  /// Valide la réponse actuelle et passe à la question suivante
  Future<void> validateAnswer(BuildContext context) async {
    if (_currentTranscript.trim().isEmpty) {
      _hasError = true;
      _errorMessage = 'Veuillez donner une réponse avant de continuer';
      notifyListeners();
      return;
    }

    // Sauvegarder la réponse
    _answers[currentQuestion.tagKey] = _currentTranscript.trim();
    AppLogger.debug('✅ Answer saved: ${currentQuestion.tagKey} = ${_currentTranscript.trim()}', 'Debug');

    // Si c'était la dernière question, traiter et rediriger
    if (isLastQuestion) {
      await _processAnswersAndRedirect(context);
    } else {
      // Passer à la question suivante
      _currentQuestionIndex++;
      _currentTranscript = '';
      _hasError = false;
      _errorMessage = '';
      notifyListeners();

      // Auto-start listening pour la question suivante
      await Future.delayed(const Duration(milliseconds: 300));
      if (!_isListening) {
        startListening();
      }
    }
  }

  /// Revenir à la question précédente
  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      _currentTranscript = _answers[currentQuestion.tagKey] ?? '';
      _hasError = false;
      _errorMessage = '';
      notifyListeners();
    }
  }

  /// Passer la question actuelle
  Future<void> skipQuestion(BuildContext context) async {
    if (isLastQuestion) {
      await _processAnswersAndRedirect(context);
    } else {
      _currentQuestionIndex++;
      _currentTranscript = '';
      _hasError = false;
      _errorMessage = '';
      notifyListeners();

      // Auto-start listening
      await Future.delayed(const Duration(milliseconds: 300));
      if (!_isListening) {
        startListening();
      }
    }
  }

  /// Traite les réponses et convertit en tags, puis redirige
  Future<void> _processAnswersAndRedirect(BuildContext context) async {
    _isProcessing = true;
    notifyListeners();

    AppLogger.debug('🔄 Processing voice answers into tags...', 'Debug');

    // Conversion basique des réponses en tags
    // (L'IA OpenAI pourrait améliorer ça dans le futur)
    final tags = <String, dynamic>{
      ...answers,
    };

    // Extraction intelligente des informations
    // Genre
    final genderAnswer = answers['recipientGender']?.toLowerCase() ?? '';
    if (genderAnswer.contains('femme') || genderAnswer.contains('fille')) {
      tags['gender'] = 'Femme';
    } else if (genderAnswer.contains('homme') || genderAnswer.contains('garçon')) {
      tags['gender'] = 'Homme';
    } else {
      tags['gender'] = 'Non spécifié';
    }

    // Âge - extraire le nombre
    final ageAnswer = answers['recipientAge'] ?? '';
    final ageMatch = RegExp(r'(\d+)').firstMatch(ageAnswer);
    if (ageMatch != null) {
      tags['age'] = int.parse(ageMatch.group(1)!);
    }

    // Budget - extraire le nombre
    final budgetAnswer = answers['budget']?.toLowerCase() ?? '';
    final budgetMatch = RegExp(r'(\d+)').firstMatch(budgetAnswer);
    if (budgetMatch != null) {
      tags['budget'] = int.parse(budgetMatch.group(1)!);
    } else if (budgetAnswer.contains('50') || budgetAnswer.contains('cinquante')) {
      tags['budget'] = 50;
    } else if (budgetAnswer.contains('100') || budgetAnswer.contains('cent')) {
      tags['budget'] = 100;
    }

    AppLogger.debug('✅ Tags generated: $tags', 'Debug');

    _isProcessing = false;
    notifyListeners();

    // Rediriger vers la page de génération de cadeaux
    // (Similaire à l'onboarding classique)
    if (context.mounted) {
      // TODO: Sauvegarder les tags et rediriger vers la page de génération
      // Pour l'instant, on retourne juste en arrière
      context.pop();

      // Dans le futur, rediriger vers:
      // context.push('/gift-generation', extra: tags);
    }
  }

  /// Annule l'onboarding
  Future<void> cancel() async {
    AppLogger.debug('❌ Cancelling voice onboarding...', 'Debug');
    await _voiceService.cancel();
    _isListening = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _voiceService.reset();
    super.dispose();
  }
}

/// Classe pour représenter une question vocale
class VoiceQuestion {
  final String id;
  final String text;
  final String hint;
  final String tagKey;

  VoiceQuestion({
    required this.id,
    required this.text,
    required this.hint,
    required this.tagKey,
  });
}
