import '/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'voice_listening_page_model.dart';

class VoiceListeningPageWidget extends StatefulWidget {
  const VoiceListeningPageWidget({Key? key}) : super(key: key);

  @override
  State<VoiceListeningPageWidget> createState() =>
      _VoiceListeningPageWidgetState();
}

class _VoiceListeningPageWidgetState extends State<VoiceListeningPageWidget> {
  late VoiceListeningPageModel _model;

  @override
  void initState() {
    super.initState();
    _model = VoiceListeningPageModel();

    // ✅ IMPORTANT: Ajouter un listener pour forcer le rebuild quand le modèle change
    _model.addListener(_onModelChanged);

    // Initialiser après le premier frame pour garantir que le widget est monté
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _model.initialize();
      }
    });
  }

  /// Callback appelé quand le modèle change - force le rebuild
  void _onModelChanged() {
    if (mounted) {
      setState(() {
        // Force rebuild avec les nouvelles données du modèle
      });
    }
  }

  @override
  void dispose() {
    _model.removeListener(_onModelChanged);
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _model,
      child: Scaffold(
        backgroundColor: const Color(0xFF062248),
        appBar: AppBar(
          backgroundColor: const Color(0xFF062248),
          automaticallyImplyLeading: true,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              _model.cancel();
              context.pop();
            },
          ),
          title: const Text(
            'Assistant Vocal (Bêta)',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          child: Consumer<VoiceListeningPageModel>(
            builder: (context, model, _) {
              // 🔍 LOGS DÉTAILLÉS pour diagnostic
              AppLogger.debug('🎤 [VOICE LISTENING BUILD] État du modèle:', 'Debug');
              AppLogger.debug('   - isListening: ${model.isListening}', 'Debug');
              AppLogger.debug('   - hasError: ${model.hasError}', 'Debug');
              AppLogger.debug('   - transcript.length: ${model.transcript.length}', 'Debug');
              AppLogger.debug('   - canProceed: ${model.canProceed()}', 'Debug');
              if (model.hasError) {
                AppLogger.debug('   - errorMessage: ${model.errorMessage}', 'Debug');
              }

              return Column(
                children: [
                  // Instructions
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Décrivez la personne pour qui vous cherchez un cadeau',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Suggestions de ce qu'il faut dire - TOUJOURS VISIBLE
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vous pouvez mentionner:',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildSuggestionItem('• Qui est cette personne (maman, ami, etc.)'),
                          _buildSuggestionItem('• Son âge ou tranche d\'âge'),
                          _buildSuggestionItem('• Votre budget'),
                          _buildSuggestionItem('• Ses hobbies et centres d\'intérêt'),
                          _buildSuggestionItem('• L\'occasion (anniversaire, Noël, etc.)'),
                          _buildSuggestionItem('• Son style (moderne, classique, etc.)'),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Microphone animé - FIX: Animation simple sans repeat
                  GestureDetector(
                    onTap: () {
                      if (model.isListening) {
                        _model.stopListening();
                      } else {
                        _model.startListening();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: model.isListening ? 180 : 160,
                      height: model.isListening ? 180 : 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: model.isListening
                              ? [
                                  const Color(0xFFFF6B9D),
                                  const Color(0xFFC74375),
                                ]
                              : [
                                  Colors.white.withOpacity(0.2),
                                  Colors.white.withOpacity(0.1),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: model.isListening
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFF6B9D).withOpacity(0.5),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        model.isListening ? IconlyBold.voice : IconlyLight.voice,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Status text
                  Text(
                    model.isListening ? 'En écoute...' : 'Appuyez pour parler',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const Spacer(),

                  // Transcription
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 120),
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        model.displayText,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: model.hasError
                              ? Colors.red[300]
                              : Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),

                  // Boutons d'action
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        // Bouton Annuler
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _model.cancel();
                              context.pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Annuler',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Bouton Continuer
                        Expanded(
                          child: ElevatedButton(
                            onPressed: model.canProceed()
                                ? () async {
                                    // Arrêter l'écoute si en cours
                                    if (model.isListening) {
                                      await _model.stopListening();
                                    }

                                    // Naviguer vers la page d'analyse
                                    if (mounted) {
                                      context.push(
                                        '/voiceAnalysis',
                                        extra: {
                                          'transcript': model.transcript,
                                        },
                                      );
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B9D),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBackgroundColor:
                                  Colors.white.withOpacity(0.1),
                            ),
                            child: const Text(
                              'Continuer',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Outfit',
          color: Colors.white.withOpacity(0.6),
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
