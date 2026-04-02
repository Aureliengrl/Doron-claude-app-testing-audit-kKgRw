import '/utils/app_logger.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';

/// Service pour gérer la reconnaissance vocale
class VoiceAssistantService {
  static final VoiceAssistantService _instance = VoiceAssistantService._internal();
  factory VoiceAssistantService() => _instance;
  VoiceAssistantService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastTranscript = '';

  /// Callbacks
  Function(String)? onTranscriptUpdate;
  Function(String)? onFinalTranscript;
  Function(String)? onError;

  bool get isListening => _isListening;
  String get lastTranscript => _lastTranscript;

  /// Initialise le service de reconnaissance vocale
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onStatus: (status) {
          AppLogger.debug('🎤 Speech status: $status', 'Debug');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
        onError: (error) {
          AppLogger.debug('❌ Speech error: $error', 'Debug');
          _isListening = false;
          onError?.call(error.errorMsg);
        },
      );

      if (_isInitialized) {
        AppLogger.debug('✅ Speech recognition initialized', 'Debug');
      } else {
        AppLogger.debug('❌ Speech recognition not available', 'Debug');
      }

      return _isInitialized;
    } catch (e) {
      AppLogger.debug('❌ Error initializing speech: $e', 'Debug');
      return false;
    }
  }

  /// Commence l'écoute
  Future<void> startListening() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError?.call('Impossible d\'initialiser le microphone');
        return;
      }
    }

    if (_isListening) {
      AppLogger.debug('⚠️ Already listening', 'Debug');
      return;
    }

    try {
      _lastTranscript = '';
      _isListening = true;

      await _speech.listen(
        onResult: (result) {
          _lastTranscript = result.recognizedWords;
          AppLogger.debug('📝 Transcript: $_lastTranscript', 'Debug');

          // Callback temps réel
          onTranscriptUpdate?.call(_lastTranscript);

          // Si final
          if (result.finalResult) {
            AppLogger.debug('✅ Final transcript: $_lastTranscript', 'Debug');
            onFinalTranscript?.call(_lastTranscript);
            _isListening = false;
          }
        },
        listenFor: const Duration(seconds: 60), // Max 60 secondes
        pauseFor: const Duration(seconds: 3), // Pause de 3s = fin
        partialResults: true,
        localeId: 'fr_FR', // Français
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );

      AppLogger.debug('🎤 Started listening...', 'Debug');
    } catch (e) {
      AppLogger.debug('❌ Error starting listening: $e', 'Debug');
      _isListening = false;
      onError?.call('Erreur lors de l\'écoute');
    }
  }

  /// Arrête l'écoute
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      _isListening = false;
      AppLogger.debug('🛑 Stopped listening', 'Debug');

      // Callback final avec dernier transcript
      if (_lastTranscript.isNotEmpty) {
        onFinalTranscript?.call(_lastTranscript);
      }
    } catch (e) {
      AppLogger.debug('❌ Error stopping listening: $e', 'Debug');
    }
  }

  /// Annule l'écoute
  Future<void> cancel() async {
    if (!_isListening) return;

    try {
      await _speech.cancel();
      _isListening = false;
      _lastTranscript = '';
      AppLogger.debug('❌ Cancelled listening', 'Debug');
    } catch (e) {
      AppLogger.debug('❌ Error cancelling listening: $e', 'Debug');
    }
  }

  /// Reset le service
  void reset() {
    _lastTranscript = '';
    onTranscriptUpdate = null;
    onFinalTranscript = null;
    onError = null;
  }

  /// Dispose le service
  void dispose() {
    if (_isListening) {
      _speech.stop();
    }
    reset();
  }
}
