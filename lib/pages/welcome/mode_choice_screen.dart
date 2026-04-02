import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Écran de choix du mode (Saint-Valentin ou Classique)
class ModeChoiceScreen extends StatelessWidget {
  const ModeChoiceScreen({super.key});

  static const String routeName = 'ModeChoice';
  static const String routePath = '/mode-choice';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF8A2BE2), // Violet
              const Color(0xFFEC4899), // Rose
              const Color(0xFFFBBF24).withOpacity(0.3), // Or subtil
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              children: [
                // Bouton retour
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.pop();
                    },
                  ),
                ),

                const SizedBox(height: 40),

                // Titre
                Text(
                  'Choisis ton mode',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 16),

                Text(
                  'Sélectionne le type de recherche\nqui te correspond',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.5,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 600.ms),

                const Spacer(),

                // Carte Saint-Valentin
                _buildModeCard(
                  context: context,
                  title: '💝 Spécial Saint-Valentin',
                  subtitle: 'Cadeaux romantiques pour ton/ta partenaire',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF0844), Color(0xFFFFB199)],
                  ),
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('first_time', false);
                    await prefs.setString('onboarding_mode', 'valentine');
                    if (context.mounted) {
                      context.go('/onboarding-advanced');
                    }
                  },
                  delay: 400,
                ),

                const SizedBox(height: 24),

                // Carte Classique
                _buildModeCard(
                  context: context,
                  title: '🎁 Classique',
                  subtitle: 'Tous types de cadeaux pour toutes les occasions',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8A2BE2), Color(0xFF4F46E5)],
                  ),
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('first_time', false);
                    await prefs.setString('onboarding_mode', 'classic');
                    if (context.mounted) {
                      context.go('/onboarding-advanced');
                    }
                  },
                  delay: 500,
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required VoidCallback onTap,
    required int delay,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 600.ms)
        .slideX(begin: 0.3, end: 0)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }
}
