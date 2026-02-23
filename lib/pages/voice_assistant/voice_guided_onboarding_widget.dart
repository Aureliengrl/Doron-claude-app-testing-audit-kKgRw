import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'voice_guided_onboarding_model.dart';
export 'voice_guided_onboarding_model.dart';

/// Page d'onboarding vocal guidé
/// Système de questions guidées avec transcription automatique
class VoiceGuidedOnboardingWidget extends StatefulWidget {
  const VoiceGuidedOnboardingWidget({super.key});

  static String routeName = 'VoiceGuidedOnboarding';
  static String routePath = '/voice-guided-onboarding';

  @override
  State<VoiceGuidedOnboardingWidget> createState() =>
      _VoiceGuidedOnboardingWidgetState();
}

class _VoiceGuidedOnboardingWidgetState
    extends State<VoiceGuidedOnboardingWidget> {
  late VoiceGuidedOnboardingModel _model;

  final Color violetColor = const Color(0xFF8A2BE2);
  final Color pinkColor = const Color(0xFFEC4899);

  @override
  void initState() {
    super.initState();
    _model = VoiceGuidedOnboardingModel();
    _model.initialize();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _model,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Consumer<VoiceGuidedOnboardingModel>(
          builder: (context, model, _) {
            if (model.isProcessing) {
              return _buildProcessingState();
            }

            return SafeArea(
              child: Column(
                children: [
                  // Header avec progression
                  _buildHeader(model),

                  // Question actuelle
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Numéro de la question
                          Text(
                            'Question ${model.progress}/${model.totalQuestions}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: violetColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Texte de la question
                          Text(
                            model.currentQuestion.text,
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF111827),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Hint
                          Text(
                            model.currentQuestion.hint,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: const Color(0xFF6B7280),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Microphone animé - FIX: Animation simple sans repeat
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                if (model.isListening) {
                                  _model.stopListening();
                                } else {
                                  _model.startListening();
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: model.isListening ? 160 : 140,
                                height: model.isListening ? 160 : 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: model.isListening
                                        ? [pinkColor, violetColor]
                                        : [
                                            violetColor.withOpacity(0.2),
                                            violetColor.withOpacity(0.1),
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: model.isListening
                                      ? [
                                          BoxShadow(
                                            color: pinkColor.withOpacity(0.4),
                                            blurRadius: 30,
                                            spreadRadius: 5,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Icon(
                                  model.isListening ? Icons.mic : Icons.mic_none,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Status
                          Center(
                            child: Text(
                              model.isListening
                                  ? 'En écoute...'
                                  : 'Appuyez pour parler',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Transcription
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 100),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: model.currentTranscript.isNotEmpty
                                    ? violetColor.withOpacity(0.3)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              model.currentTranscript.isEmpty
                                  ? 'Votre réponse apparaîtra ici...'
                                  : model.currentTranscript,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: model.currentTranscript.isEmpty
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF111827),
                                height: 1.5,
                              ),
                            ),
                          ),

                          // Erreur
                          if (model.hasError) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: Colors.red[700], size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      model.errorMessage,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.red[900],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Boutons de navigation
                  _buildNavigationButtons(model),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(VoiceGuidedOnboardingModel model) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row avec bouton retour et titre
          Row(
            children: [
              // Bouton retour
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _model.cancel();
                    context.pop();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF6B7280),
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Titre
              Expanded(
                child: Text(
                  'Assistant Vocal',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: model.progress / model.totalQuestions,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(violetColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(VoiceGuidedOnboardingModel model) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Bouton principal (Valider / Terminer)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: model.currentTranscript.trim().isEmpty
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      _model.validateAnswer(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: violetColor,
                disabledBackgroundColor: const Color(0xFFE5E7EB),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    model.isLastQuestion ? 'Terminer' : 'Continuer',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    model.isLastQuestion ? Icons.check : Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Boutons secondaires
          Row(
            children: [
              // Bouton Précédent (si pas première question)
              if (model.currentQuestionIndex > 0)
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _model.previousQuestion();
                    },
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: Text(
                      'Précédent',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                    ),
                  ),
                ),

              // Spacer si précédent existe
              if (model.currentQuestionIndex > 0) const SizedBox(width: 12),

              // Bouton Passer
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _model.skipQuestion(context);
                  },
                  icon: const Icon(Icons.skip_next, size: 18),
                  label: Text(
                    'Passer',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: violetColor,
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'Analyse de vos réponses...',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Génération des suggestions en cours',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
