import '/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:doron/services/openai_voice_analysis_service.dart';

/// Model pour la page d'analyse vocale
class VoiceAnalysisPageModel extends ChangeNotifier {
  String _transcript = '';
  bool _isAnalyzing = true;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic>? _analysisResult;

  bool get isAnalyzing => _isAnalyzing;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  Map<String, dynamic>? get analysisResult => _analysisResult;

  /// Initialise et lance l'analyse
  Future<void> initialize(String transcript) async {
    _transcript = transcript;
    AppLogger.debug('🤖 Initializing voice analysis with transcript: $transcript', 'Debug');

    // Lancer l'analyse
    await analyzeTranscript();
  }

  /// Analyse le transcript avec OpenAI
  Future<void> analyzeTranscript() async {
    AppLogger.debug('🤖 [MODEL] ===== DÉBUT ANALYSE TRANSCRIPT =====', 'Debug');
    AppLogger.debug('🤖 [MODEL] Transcript: "$_transcript"', 'Debug');

    _isAnalyzing = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      // Vérification 1: Transcript vide
      if (_transcript.trim().isEmpty) {
        AppLogger.debug('❌ [MODEL] ERREUR: Transcript vide', 'Debug');
        _hasError = true;
        _errorMessage = 'Aucune description détectée. Veuillez réessayer et parler clairement.';
        _isAnalyzing = false;
        notifyListeners();
        return;
      }

      // Vérification 2: Transcript trop court
      if (_transcript.trim().length < 10) {
        AppLogger.debug('❌ [MODEL] ERREUR: Transcript trop court (${_transcript.trim().length} chars)', 'Debug');
        _hasError = true;
        _errorMessage = 'Description trop courte. Veuillez donner plus de détails sur la personne.';
        _isAnalyzing = false;
        notifyListeners();
        return;
      }

      AppLogger.debug('🤖 [MODEL] Validations OK, lancement analyse OpenAI...', 'Debug');

      // Appel OpenAI avec timeout de 60 secondes
      final result = await OpenAIVoiceAnalysisService.analyzeVoiceTranscript(_transcript)
          .timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          AppLogger.debug('⏱️ [MODEL] TIMEOUT après 60 secondes', 'Debug');
          return null;
        },
      );

      AppLogger.debug('🤖 [MODEL] Résultat reçu: ${result != null ? "SUCCÈS" : "NULL"}', 'Debug');

      if (result != null) {
        AppLogger.debug('✅ [MODEL] ===== ANALYSE RÉUSSIE =====', 'Debug');
        AppLogger.debug('✅ [MODEL] Clés: ${result.keys.join(", ")}', 'Debug');
        _analysisResult = result;
        _isAnalyzing = false;
        _hasError = false;
      } else {
        AppLogger.debug('❌ [MODEL] ===== ANALYSE ÉCHOUÉE =====', 'Debug');
        _hasError = true;
        // Récupérer la dernière erreur du service pour l'afficher à l'utilisateur
        final lastError = OpenAIVoiceAnalysisService.lastErrorMessage;
        _errorMessage = lastError.isNotEmpty
            ? 'Erreur: $lastError'
            : 'L\'analyse a échoué. Vérifiez votre connexion internet.';
        _isAnalyzing = false;
      }

      notifyListeners();
    } catch (e, stack) {
      AppLogger.debug('❌ [MODEL] ===== EXCEPTION =====', 'Debug');
      AppLogger.debug('❌ [MODEL] Type: ${e.runtimeType}', 'Debug');
      AppLogger.debug('❌ [MODEL] Message: $e', 'Debug');
      AppLogger.debug('❌ [MODEL] Stack: ${stack.toString().split('\n').take(3).join('\n')}', 'Debug');
      _hasError = true;
      _errorMessage = 'Erreur: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e.toString()}';
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  /// Réessayer l'analyse
  Future<void> retry() async {
    await analyzeTranscript();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
