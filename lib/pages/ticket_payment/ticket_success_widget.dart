import '/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Écran de confirmation après paiement réussi
class TicketSuccessWidget extends StatefulWidget {
  const TicketSuccessWidget({super.key});

  static String routeName = 'TicketSuccess';
  static String routePath = '/ticket-success';

  @override
  State<TicketSuccessWidget> createState() => _TicketSuccessWidgetState();
}

class _TicketSuccessWidgetState extends State<TicketSuccessWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late ConfettiController _confettiController;

  final Color violetColor = const Color(0xFF8A2BE2);
  final Color goldColor = const Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();

    // Animation du check
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    // Confetti
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Démarrer les animations
    Future.delayed(const Duration(milliseconds: 500), () {
      _animationController.forward();
      _confettiController.play();
    });

    // Désactiver le mode découverte après achat du billet
    _disableDiscoveryMode();
  }

  Future<void> _disableDiscoveryMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('anonymous_mode', false);
    } catch (e) {
      AppLogger.debug('Erreur désactivation mode découverte: $e', 'Debug');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFF7ED),
              const Color(0xFFFEE2E2),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Confetti
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  particleDrag: 0.05,
                  emissionFrequency: 0.05,
                  numberOfParticles: 50,
                  gravity: 0.1,
                  colors: [
                    violetColor,
                    goldColor,
                    const Color(0xFFEC4899),
                    const Color(0xFFF43F5E),
                  ],
                ),
              ),

              // Contenu principal
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icône de succès animée
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [violetColor, goldColor],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: violetColor.withOpacity(0.4),
                                blurRadius: 40,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Titre
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [violetColor, goldColor],
                          ).createShader(bounds),
                          child: Text(
                            'Paiement réussi !',
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Message
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'Ton billet pour le gala DORÕN est confirmé !',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Informations
                      _buildInfoCard(),

                      const SizedBox(height: 48),

                      // Boutons d'action
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            IconlyLight.message,
            color: violetColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Confirmation envoyée',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tu vas recevoir un email de confirmation avec tous les détails de ton billet.',
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: const Color(0xFF6B7280),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: goldColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: goldColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  IconlyLight.ticket,
                  color: goldColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Vérifie ton Apple Wallet pour accéder à ton billet',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF92400E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Bouton principal : Découvrir l'app
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              context.go('/HomePinterest');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: violetColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 8,
              shadowColor: violetColor.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(IconlyLight.discovery, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Découvrir l\'app',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Bouton secondaire : Retour à l'accueil
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              context.go('/initial-choice');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: violetColor,
              padding: const EdgeInsets.symmetric(vertical: 18),
              side: BorderSide(color: violetColor, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Retour à l\'accueil',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
