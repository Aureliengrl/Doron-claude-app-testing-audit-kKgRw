import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Système de didacticiel pour le mode découverte
class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onComplete;
  final String tutorialKey;

  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
    required this.tutorialKey,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();

  /// Vérifie si le tutoriel a déjà été vu
  static Future<bool> hasSeenTutorial(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tutorial_$key') ?? false;
  }

  /// Marque le tutoriel comme vu
  static Future<void> markTutorialAsSeen(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_$key', true);
  }

  /// Affiche le tutoriel si non vu
  static Future<void> showIfNeeded(
    BuildContext context, {
    required String tutorialKey,
    required List<TutorialStep> steps,
    required VoidCallback onComplete,
  }) async {
    final seen = await hasSeenTutorial(tutorialKey);
    if (!seen && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.8),
        builder: (context) => TutorialOverlay(
          tutorialKey: tutorialKey,
          steps: steps,
          onComplete: onComplete,
        ),
      );
    }
  }
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _currentStep = 0;

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _complete();
    }
  }

  void _complete() async {
    await TutorialOverlay.markTutorialAsSeen(widget.tutorialKey);
    if (mounted) {
      Navigator.pop(context);
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    final isLastStep = _currentStep == widget.steps.length - 1;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône
            if (step.icon != null)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8A2BE2), Color(0xFFEC4899)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  step.icon,
                  color: Colors.white,
                  size: 40,
                ),
              ),

            if (step.icon != null) const SizedBox(height: 24),

            // Titre
            Text(
              step.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              step.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF6B7280),
                height: 1.6,
              ),
            ),

            const SizedBox(height: 28),

            // Progress indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.steps.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == _currentStep ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == _currentStep
                        ? const Color(0xFF8A2BE2)
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Bouton
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8A2BE2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 4,
                  shadowColor: const Color(0xFF8A2BE2).withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isLastStep ? step.buttonText ?? 'Terminer' : step.buttonText ?? 'OK',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Bouton skip (optionnel)
            if (!isLastStep) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _complete,
                child: Text(
                  'Passer le tutoriel',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Étape du tutoriel
class TutorialStep {
  final String title;
  final String description;
  final IconData? icon;
  final String? buttonText;

  const TutorialStep({
    required this.title,
    required this.description,
    this.icon,
    this.buttonText,
  });
}
