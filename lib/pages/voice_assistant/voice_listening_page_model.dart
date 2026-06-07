import '/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:doron/services/voice_assistant_service.dart';

/// Model pour la page d'écoute vocale
class VoiceListeningPageModel extends ChangeNotifier {
  final VoiceAssistantService _voiceService = VoiceAssistantService();

  String _transcript = '';
  String _displayText = 'Appuyez sur le microphone pour commencer...';
  bool _isListening = false;
  bool _hasError = false;
  String _errorMessage = '';

  String get transcript => _transcript;
  String get displayText => _displayText;
  bool get isListening => _isListening;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;

  /// Initialise le service vocal
  Future<void> initialize() async {
    AppLogger.debug('?? Initializing voice listening page...', 'Debug');

    // ? FIX: Reset les anciens callbacks avant de configurer les nouveaux
    // (évite les callbacks stales si la page est recre)
    _voiceService.reset();

    // Setup callbacks
    _voiceService.onTranscriptUpdate = (text) {
      _transcript = text;
      if (text.isEmpty) {
        _displayText = 'Parlez maintenant...';
      } else {
        _displayText = text;
      }
      notifyListeners();
    };

    _voiceService.onFinalTranscript = (text) {
      AppLogger.debug('? Final transcript received: $text', 'Debug');
      _transcript = text;
      _displayText = text;
      _isListening = false;
      notifyListeners();
    };

    _voiceService.onError = (error) {
      AppLogger.debug('? Voice error: $error', 'Debug');
      _hasError = true;
      _errorMessage = error;
      _displayText = 'Erreur: $error';
      _isListening = false;
      notifyListeners();
    };

    // Initialize service
    final initialized = await _voiceService.initialize();
    if (!initialized) {
      _hasError = true;
      _errorMessage = 'Impossible d\'initialiser le microphone';
      _displayText = 'Microphone non disponible';
      notifyListeners();
    }
  }

  /// Commence l'écoute
  Future<void> startListening() async {
    if (_isListening) return;

    AppLogger.debug('?? Starting listening...', 'Debug');
    _hasError = false;
    _errorMessage = '';
    _transcript = '';
    _displayText = 'Parlez maintenant...';
    _isListening = true;
    notifyListeners();

    await _voiceService.startListening();
  }

  /// Arrête l'écoute
  Future<void> stopListening() async {
    if (!_isListening) return;

    AppLogger.debug('?? Stopping listening...', 'Debug');
    await _voiceService.stopListening();
    _isListening = false;
    notifyListeners();
  }

  /// Annule l'écoute
  Future<void> cancel() async {
    AppLogger.debug('? Cancelling listening...', 'Debug');
    await _voiceService.cancel();
    _isListening = false;
    _transcript = '';
    _displayText = 'Écoute annulée';
    notifyListeners();
  }

  /// Vérifie si le transcript est valide pour continuer
  bool canProceed() {
    return _transcript.trim().isNotEmpty && !_isListening;
  }

  @override
  void dispose() {
    _voiceService.reset();
    super.dispose();
  }
}
