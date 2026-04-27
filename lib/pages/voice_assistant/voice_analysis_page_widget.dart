import '/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:doron/services/openai_voice_analysis_service.dart';
import 'package:doron/services/firebase_data_service.dart';
import 'voice_analysis_page_model.dart';

class VoiceAnalysisPageWidget extends StatefulWidget {
  final String transcript;

  const VoiceAnalysisPageWidget({
    Key? key,
    required this.transcript,
  }) : super(key: key);

  @override
  State<VoiceAnalysisPageWidget> createState() =>
      _VoiceAnalysisPageWidgetState();
}

class _VoiceAnalysisPageWidgetState extends State<VoiceAnalysisPageWidget> {
  late VoiceAnalysisPageModel _model;
  bool _hasNavigated = false;
  bool _showSuccess = false; // ✅ État de succès avant navigation

  @override
  void initState() {
    super.initState();
    _model = VoiceAnalysisPageModel();

    // ✅ IMPORTANT: Ajouter le listener AVANT d'initialiser
    // pour ne pas manquer les notifications
    _model.addListener(_onModelChanged);

    // Initialiser après le premier frame pour garantir que le widget est monté
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _model.initialize(widget.transcript);
      }
    });
  }

  void _onModelChanged() async {
    AppLogger.debug('🔄 Voice Analysis: Listener déclenché - hasNavigated=$_hasNavigated, isAnalyzing=${_model.isAnalyzing}, hasError=${_model.hasError}, analysisResult=${_model.analysisResult != null ? "PRESENT" : "NULL"}', 'Debug');

    // ✅ Forcer le rebuild pour mettre à jour l'UI
    if (mounted) {
      setState(() {});
    }

    if (!_hasNavigated &&
        !_model.isAnalyzing &&
        !_model.hasError &&
        _model.analysisResult != null) {
      // Marquer comme ayant navigué pour éviter les navigations multiples
      _hasNavigated = true;
      AppLogger.debug('🎯 Voice Analysis: CONDITIONS VALIDÉES - Préparation navigation vers génération', 'Debug');

      // ✅ Afficher l'état de succès
      if (mounted) {
        setState(() {
          _showSuccess = true;
        });
      }

      // Convertir l'analyse en profil de cadeau
      final giftProfile = OpenAIVoiceAnalysisService.convertToGiftProfile(
        _model.analysisResult!,
      );
      giftProfile['rawTranscript'] = widget.transcript;

      AppLogger.debug('✅ Profil cadeau généré depuis l\'assistant vocal:', 'Debug');
      AppLogger.debug('   - Nom: ${giftProfile['name'] ?? giftProfile['recipientName'] ?? "Non défini"}', 'Debug');
      AppLogger.debug('   - Genre: ${giftProfile['gender'] ?? "Non défini"}', 'Debug');
      AppLogger.debug('   - Budget: ${giftProfile['budget'] ?? "Non défini"}', 'Debug');
      AppLogger.debug('   - Intérêts: ${(giftProfile['interests'] ?? giftProfile['recipientHobbies'] ?? []).length} items', 'Debug');

      // Sauvegarder le profil pour la génération (non bloquant)
      FirebaseDataService.saveGiftProfile(giftProfile).then((_) {
        AppLogger.debug('✅ Profil sauvegardé dans Firebase pour tracking', 'Debug');
      }).catchError((e) {
        AppLogger.debug('⚠️ Erreur sauvegarde profil (non bloquant): $e', 'Debug');
      });

      // Navigation automatique vers la génération de cadeaux après délai visuel
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          AppLogger.debug('🚀 NAVIGATION vers /onboarding-gifts-result avec profil vocal', 'Debug');
          AppLogger.debug('   Ceci va générer les cadeaux comme après l\'onboarding !', 'Debug');
          context.pushReplacement(
            '/onboarding-gifts-result',
            extra: giftProfile,
          );
        } else {
          AppLogger.debug('❌ Navigation annulée: widget non monté', 'Debug');
        }
      });
    } else {
      AppLogger.debug('⏸️ Voice Analysis: Conditions non remplies, attente...', 'Debug');
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
          automaticallyImplyLeading: false,
          title: const Text(
            'Analyse en cours...',
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
          child: Consumer<VoiceAnalysisPageModel>(
            builder: (context, model, _) {
              // 🔍 LOGS DÉTAILLÉS pour diagnostic
              AppLogger.debug('🤖 [VOICE ANALYSIS BUILD] État du modèle:', 'Debug');
              AppLogger.debug('   - isAnalyzing: ${model.isAnalyzing}', 'Debug');
              AppLogger.debug('   - hasError: ${model.hasError}', 'Debug');
              AppLogger.debug('   - showSuccess: $_showSuccess', 'Debug');
              AppLogger.debug('   - analysisResult: ${model.analysisResult != null ? "PRESENT" : "NULL"}', 'Debug');
              if (model.hasError) {
                AppLogger.debug('   - errorMessage: ${model.errorMessage}', 'Debug');
              }

              // ✅ État de succès avant navigation
              if (_showSuccess) {
                AppLogger.debug('   → Affichage SUCCESS STATE', 'Debug');
                return _buildSuccessState();
              }

              if (model.hasError) {
                AppLogger.debug('   → Affichage ERROR STATE', 'Debug');
                return _buildErrorState(model);
              }

              AppLogger.debug('   → Affichage LOADING STATE (analyse en cours)', 'Debug');
              return _buildLoadingState();
            },
          ),
        ),
      ),
    );
  }

  /// ✅ État de succès - affiché avant navigation
  Widget _buildSuccessState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Cercle de succès animé
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF10B981),
                  Color(0xFF059669),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.check,
              size: 60,
              color: Colors.white,
            ),
          )
              .animate()
              .scale(
                duration: const Duration(milliseconds: 400),
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.0, 1.0),
                curve: Curves.elasticOut,
              ),

          const SizedBox(height: 32),

          // Texte de succès
          Text(
            'Analyse terminée !',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: Colors.white.withOpacity(0.9),
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          )
              .animate()
              .fadeIn(duration: const Duration(milliseconds: 300)),

          const SizedBox(height: 16),

          Text(
            'Génération des cadeaux en cours...',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          )
              .animate()
              .fadeIn(
                duration: const Duration(milliseconds: 300),
                delay: const Duration(milliseconds: 200),
              ),

          const SizedBox(height: 32),

          // Indicateur de chargement pour la navigation
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            strokeWidth: 3,
          )
              .animate()
              .fadeIn(
                duration: const Duration(milliseconds: 300),
                delay: const Duration(milliseconds: 400),
              ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    // FIX: Animation simple sans repeat() pour éviter NaN/Infinity
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation simple - juste un cercle avec gradient et CircularProgressIndicator
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Cercle de fond avec gradient
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF6B9D),
                        Color(0xFFC74375),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B9D).withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 50,
                    color: Colors.white,
                  ),
                ),

                // CircularProgressIndicator autour
                const SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B9D)),
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Texte de chargement
          Text(
            'Analyse de votre description...',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: Colors.white.withOpacity(0.9),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          // Sous-texte
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Notre intelligence artificielle analyse vos critères pour trouver les meilleurs cadeaux',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Indicateur de progression simple
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B9D)),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(VoiceAnalysisPageModel model) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône d'erreur
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.2),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 32),

            // Message d'erreur
            Text(
              'Oups, une erreur est survenue',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: Colors.white.withOpacity(0.9),
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              model.errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 48),

            // Boutons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
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
                      'Retour',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      model.retry();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B9D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Réessayer',
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
          ],
        ),
      ),
    );
  }
}
