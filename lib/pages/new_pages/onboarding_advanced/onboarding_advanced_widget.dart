import '/utils/app_logger.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/components/liquid_glass.dart';
import 'onboarding_advanced_model.dart';
export 'onboarding_advanced_model.dart';

class OnboardingAdvancedWidget extends StatefulWidget {
  const OnboardingAdvancedWidget({super.key});

  static String routeName = 'OnboardingAdvanced';
  static String routePath = '/onboarding-advanced';

  @override
  State<OnboardingAdvancedWidget> createState() =>
      _OnboardingAdvancedWidgetState();
}

class _OnboardingAdvancedWidgetState extends State<OnboardingAdvancedWidget>
    with TickerProviderStateMixin {
  late OnboardingAdvancedModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Couleur principale
  final Color violetColor = const Color(0xFF8A2BE2);

  // Mode d'onboarding (valentine ou classic)
  String? _onboardingMode;
  bool _isLoadingMode = true;

  @override
  void initState() {
    super.initState();
    _model = OnboardingAdvancedModel();
    _model.initAnimations(this);
    _loadOnboardingMode();
  }

  Future<void> _loadOnboardingMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mode = prefs.getString('onboarding_mode');
      setState(() {
        _onboardingMode = mode;
        _isLoadingMode = false;
      });
      AppLogger.debug('🎯 Mode onboarding chargé: $_onboardingMode', 'Debug');
    } catch (e) {
      AppLogger.debug('⚠️ Erreur chargement mode: $e', 'Debug');
      setState(() {
        _isLoadingMode = false;
      });
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Afficher un loader pendant le chargement du mode
    if (_isLoadingMode) {
      return Scaffold(
        backgroundColor: LiquidGlassTokens.pageDark,
        body: Center(
          child: CircularProgressIndicator(
            color: violetColor,
            strokeWidth: 3,
          ),
        ),
      );
    }

    // Lire les paramètres de query
    final skipUserQuestions = GoRouterState.of(context).uri.queryParameters['skipUserQuestions'] == 'true';
    final onlyUserQuestions = GoRouterState.of(context).uri.queryParameters['onlyUserQuestions'] == 'true';
    final returnTo = GoRouterState.of(context).uri.queryParameters['returnTo'];
    // Mode express activé par défaut (seulement 7 questions essentielles)
    // Pour revenir au mode complet, passer expressMode=false en paramètre
    final expressMode = GoRouterState.of(context).uri.queryParameters['expressMode'] != 'false';

    final steps = _model.getSteps(
      skipUserQuestions: skipUserQuestions,
      onlyUserQuestions: onlyUserQuestions,
      expressMode: expressMode,
      onboardingMode: _onboardingMode, // Passer le mode chargé
    );
    final currentStepData = steps[_model.currentStep];
    final progress = (_model.currentStep + 1) / steps.length;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: LiquidGlassTokens.pageDark,
      body: Stack(
        children: [
          // Fond sombre avec orbes ambiants
          Positioned(top: -80, left: -60, child: Container(width: 280, height: 280, decoration: BoxDecoration(shape: BoxShape.circle, color: LiquidGlassTokens.primary.withOpacity(0.18)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: const SizedBox()))),
          Positioned(bottom: -60, right: -40, child: Container(width: 220, height: 220, decoration: BoxDecoration(shape: BoxShape.circle, color: LiquidGlassTokens.secondary.withOpacity(0.14)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60), child: const SizedBox()))),
          // Contenu principal
          SafeArea(
            child: Column(
              children: [
                _buildHeader(progress, steps.length, returnTo: returnTo),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 32,
                      bottom: 120,
                    ),
                    child: _buildStepContent(currentStepData),
                  ),
                ),
              ],
            ),
          ),
          _buildContinueButton(steps),
          // Scan IA overlay during navigation of the final step
          if (_model.isNavigating && _model.currentStep == steps.length - 1)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.85),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated scanning icon
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1500),
                        builder: (context, value, child) {
                          return Transform.rotate(
                            angle: value * 2 * 3.14159,
                            child: Icon(
                              Icons.data_usage_outlined,
                              size: 80,
                              color: violetColor,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Recherche en cours...',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Analyse des millions de combinaisons\ngrace à notre ✨ Scan IA',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildAnimatedParticles() {
    return List.generate(20, (index) {
      return AnimatedBuilder(
        animation: _model.particleControllers[index],
        builder: (context, child) {
          return Positioned(
            left: MediaQuery.of(context).size.width *
                _model.particlePositions[index].dx,
            top: MediaQuery.of(context).size.height *
                _model.particlePositions[index].dy,
            child: Opacity(
              opacity: 0.2,
              child: Container(
                width: _model.particleSizes[index],
                height: _model.particleSizes[index],
                decoration: BoxDecoration(
                  color: violetColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildHeader(double progress, int totalSteps, {String? returnTo}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // Show back button if: we're not at step 0, OR we have a returnTo destination
              if (_model.currentStep > 0 || (returnTo != null && returnTo.isNotEmpty))
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      // If at step 0 and returnTo exists, go back to that page
                      if (_model.currentStep == 0 && returnTo != null && returnTo.isNotEmpty) {
                        if (mounted) {
                          context.go(returnTo);
                        }
                        return;
                      }

                      // Otherwise, go to previous step
                      if (mounted) {
                        setState(() {
                          _model.handleBack();
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: LiquidGlassTokens.secondary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${_model.currentStep + 1}/$totalSteps',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOut,
                    width: MediaQuery.of(context).size.width * progress,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          violetColor,
                          const Color(0xFFEC4899),
                          violetColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(Map<String, dynamic> stepData) {
    final type = stepData['type'] as String;

    if (type == 'welcome') {
      return _buildWelcomeScreen(stepData);
    } else if (type == 'transition') {
      return _buildTransitionScreen(stepData);
    } else if (type == 'text') {
      return _buildTextInputScreen(stepData);
    } else if (type == 'dual_text') {
      return _buildDualTextInputScreen(stepData);
    } else if (type == 'single' || type == 'multiple') {
      return _buildQuestionScreen(stepData);
    } else if (type == 'slider') {
      return _buildSliderScreen(stepData);
    }

    return const SizedBox.shrink();
  }

  Widget _buildWelcomeScreen(Map<String, dynamic> stepData) {
    final useLogo = stepData['useLogo'] as bool? ?? false;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 800),
          builder: (context, double value, child) {
            return Transform.scale(
              scale: value,
              child: useLogo
                  ? Image.asset(
                      'assets/images/doron_logo.png', // Logo DORÕN (vague)
                      width: 150,
                      height: 150,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback si l'image n'existe pas encore
                        return Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: violetColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.card_giftcard,
                            size: 80,
                            color: violetColor,
                          ),
                        );
                      },
                    )
                  : Text(
                      stepData['emoji'] as String,
                      style: const TextStyle(fontSize: 100),
                    ),
            );
          },
        ),
        const SizedBox(height: 24),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              violetColor,
              const Color(0xFFEC4899),
              violetColor,
            ],
          ).createShader(bounds),
          child: Text(
            stepData['title'] as String,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          stepData['subtitle'] as String,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 20,
            color: Colors.white.withOpacity(0.75),
          ),
        ),
      ],
    );
  }

  Widget _buildTransitionScreen(Map<String, dynamic> stepData) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1000),
          builder: (context, double value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Text(
                  stepData['emoji'] as String,
                  style: const TextStyle(fontSize: 80),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        Text(
          stepData['title'] as String,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: violetColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          stepData['subtitle'] as String,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 18,
            color: const Color(0xFFF5F5F7),
          ),
        ),
      ],
    );
  }

  Widget _buildTextInputScreen(Map<String, dynamic> stepData) {
    final field = stepData['field'] as String;
    final placeholder = stepData['placeholder'] as String? ?? '';
    final currentValue = _model.answers[field] as String? ?? '';

    // FIX Bug 1: Utiliser un ScrollController pour s'assurer que le champ soit visible
    // quand le clavier s'ouvre
    final scrollController = ScrollController();

    // Déclencher le scroll automatique après le build pour montrer le champ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Petit délai pour laisser le clavier s'ouvrir
      Future.delayed(const Duration(milliseconds: 300), () {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });

    return SingleChildScrollView(
      controller: scrollController,
      // Padding réduit en haut, plus de padding en bas pour le clavier
      padding: EdgeInsets.only(
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 60,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Espace réduit en haut (au lieu de 15% de l'écran)
          const SizedBox(height: 20),
          Text(
            stepData['icon'] as String,
            style: const TextStyle(fontSize: 60), // Taille réduite pour gagner de l'espace
          ),
          const SizedBox(height: 20),
          Text(
            stepData['question'] as String,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 24, // Taille réduite pour s'adapter au clavier
              fontWeight: FontWeight.bold,
              color: violetColor,
            ),
          ),
          if (stepData['subtitle'] != null) ...[
            const SizedBox(height: 8),
            Text(
              stepData['subtitle'] as String,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFFF5F5F7),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: TextFormField(
              key: ValueKey('${field}_${currentValue.hashCode}'),
              initialValue: currentValue,
              onChanged: (value) {
                _model.answers[field] = value;
              },
              autofocus: true,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: violetColor,
              ),
              decoration: InputDecoration(
              hintText: placeholder,
              labelText: 'optionnel',
              floatingLabelBehavior: FloatingLabelBehavior.always,
              labelStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
              ),
              hintStyle: GoogleFonts.poppins(
                fontSize: 20,
                color: Colors.grey[400],
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.20)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.20)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: violetColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
            ),
          ),
        ),
        // Espace supplémentaire en bas pour s'assurer que le champ reste visible
        const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildDualTextInputScreen(Map<String, dynamic> stepData) {
    final fields = stepData['fields'] as List;

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Text(
            stepData['question'] as String,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: violetColor,
            ),
          ),
          if (stepData['subtitle'] != null) ...[
            const SizedBox(height: 8),
            Text(
              stepData['subtitle'] as String,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFFF5F5F7),
              ),
            ),
          ],
          const SizedBox(height: 32),
          // Afficher les 2 champs
          ...fields.map((fieldData) {
            final field = fieldData['field'] as String;
            final label = fieldData['label'] as String;
            final placeholder = fieldData['placeholder'] as String;
            final required = fieldData['required'] as bool;
            final hint = fieldData['hint'] as String;
            final currentValue = _model.answers[field] as String? ?? '';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: required ? violetColor : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          hint,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: required ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: ValueKey('${field}_${currentValue.hashCode}'),
                    initialValue: currentValue,
                    onChanged: (value) {
                      _model.answers[field] = value;
                    },
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: violetColor,
                    ),
                    decoration: InputDecoration(
                      hintText: placeholder,
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: violetColor.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: violetColor.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: violetColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildQuestionScreen(Map<String, dynamic> stepData) {
    final type = stepData['type'] as String;
    final field = stepData['field'] as String;
    final options = stepData['options'] as List<String>;

    return Column(
      children: [
        if (stepData.containsKey('subtitle'))
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              stepData['subtitle'] as String,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: violetColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              stepData['icon'] as String,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                stepData['question'] as String,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        ...options.map((option) {
          final isSelected = _model.isSelected(field, option);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _model.handleSelect(
                        field,
                        option,
                        type == 'multiple',
                        maxSelections: stepData['maxSelections'] as int?,
                      );
                    });
                  },
                  borderRadius: BorderRadius.circular(32),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                violetColor,
                                violetColor.withOpacity(0.8),
                              ],
                            )
                          : LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.13),
                                Colors.white.withOpacity(0.07),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: isSelected ? Colors.white.withOpacity(0.35) : Colors.white.withOpacity(0.18),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: violetColor.withOpacity(0.40),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(isSelected ? 1.0 : 0.80),
                            ),
                          ),
                        ),
                        if (isSelected && type == 'multiple')
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
        if (type == 'multiple')
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              '✨ Tu peux sélectionner plusieurs réponses',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: violetColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSliderScreen(Map<String, dynamic> stepData) {
    final field = stepData['field'] as String;
    final min = (stepData['min'] as int).toDouble();
    final max = (stepData['max'] as int).toDouble();
    final value = _model.answers[field] as double? ?? min;

    return Column(
      children: [
        Text(
          stepData['icon'] as String,
          style: const TextStyle(fontSize: 40),
        ),
        const SizedBox(height: 16),
        Text(
          stepData['question'] as String,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        if (stepData.containsKey('subtitle'))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              stepData['subtitle'] as String,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: violetColor,
              ),
            ),
          ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        violetColor,
                        const Color(0xFFEC4899),
                      ],
                    ).createShader(bounds),
                    child: Text(
                      '${value.toInt()}€',
                      style: GoogleFonts.poppins(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 0,
                    right: -8,
                    child: Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFFBBF24),
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 16,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 14,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 24,
                  ),
                  activeTrackColor: violetColor,
                  inactiveTrackColor: const Color(0xFFE9D5FF),
                  thumbColor: violetColor,
                  overlayColor: violetColor.withOpacity(0.2),
                ),
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  onChanged: (newValue) {
                    setState(() {
                      _model.answers[field] = newValue;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${min.toInt()}€',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFFF5F5F7),
                    ),
                  ),
                  Text(
                    '${max.toInt()}€',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFFF5F5F7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Bouton "Raisonnable"
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      // Valeur raisonnable : 80€ (mix accessible + premium)
                      _model.answers[field] = 80.0;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          violetColor.withOpacity(0.1),
                          const Color(0xFFEC4899).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: violetColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: violetColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Budget raisonnable',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: violetColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton(List<Map<String, dynamic>> steps) {
    final canProceed = _model.canProceed(steps[_model.currentStep]);
    final isLastStep = _model.currentStep == steps.length - 1;
    final skipUserQuestions = GoRouterState.of(context).uri.queryParameters['skipUserQuestions'] == 'true';
    final returnTo = GoRouterState.of(context).uri.queryParameters['returnTo'];
    final onlyUserQuestions = GoRouterState.of(context).uri.queryParameters['onlyUserQuestions'] == 'true';

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0),
              Colors.white,
              Colors.white,
            ],
          ),
        ),
        child: ElevatedButton(
          // FIX Bug 2: Désactiver le bouton si navigation en cours
          onPressed: (canProceed && !_model.isNavigating)
              ? () async {
                  // Attendre correctement handleNext (async)
                  await _model.handleNext(steps, context, skipUserQuestions: skipUserQuestions, returnTo: returnTo, onlyUserQuestions: onlyUserQuestions);
                  // Rafraîchir l'UI après la navigation
                  if (mounted) {
                    setState(() {});
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canProceed ? violetColor : Colors.grey[300],
            disabledBackgroundColor: Colors.grey[300],
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            elevation: canProceed ? 8 : 0,
            shadowColor: violetColor.withOpacity(0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLastStep) ...[
                const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                isLastStep ? 'Découvrir mes cadeaux' : 'Continuer',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: canProceed ? Colors.white : Colors.grey[500],
                ),
              ),
              if (isLastStep) ...[
                const SizedBox(width: 8),
                const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ] else ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward,
                  color: canProceed ? Colors.white : Colors.grey[500],
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
