import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const String routeName = 'Welcome';
  static const String routePath = '/welcome';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF062248), // Navy profond
              Color(0xFF1A1040), // Violet sombre
              Color(0xFF3D0080), // Violet foncé
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 1),

                // ── Logo animé ──────────────────────────────────────────────
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B9D).withOpacity(0.4),
                        blurRadius: 40,
                        spreadRadius: 8,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🎁', style: TextStyle(fontSize: 52)),
                  ),
                )
                    .animate()
                    .scale(duration: 700.ms, curve: Curves.easeOutBack)
                    .fadeIn(duration: 500.ms),

                const SizedBox(height: 28),

                // ── Titre ───────────────────────────────────────────────────
                Text(
                  'DORON',
                  style: GoogleFonts.poppins(
                    fontSize: 46,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 600.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 12),

                // ── Accroche ─────────────────────────────────────────────────
                Text(
                  'Le cadeau parfait existe.\nDoron le trouve pour toi.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.85),
                    height: 1.5,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 600.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 40),

                // ── 3 badges de valeur ─────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ValueBadge(icon: '🎯', label: 'Matching IA'),
                    const SizedBox(width: 12),
                    _ValueBadge(icon: '🛍️', label: '+375 idées'),
                    const SizedBox(width: 12),
                    _ValueBadge(icon: '⚡', label: '2 minutes'),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 450.ms, duration: 600.ms)
                    .slideY(begin: 0.2, end: 0),

                const Spacer(flex: 2),

                // ── CTA principal ──────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('first_time', false);
                      if (context.mounted) {
                        context.go('/authentification');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B9D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      elevation: 12,
                      shadowColor: const Color(0xFFFF6B9D).withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🚀', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Commencer gratuitement',
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Prêt en 2 minutes',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0)
                    .scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1)),

                const SizedBox(height: 16),

                // ── Lien connexion existant ────────────────────────────────
                TextButton(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('first_time', false);
                    if (context.mounted) {
                      context.go('/authentification');
                    }
                  },
                  child: Text(
                    'Déjà un compte ? Se connecter',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.65),
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white.withOpacity(0.4),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 750.ms, duration: 600.ms),

                const SizedBox(height: 16),

                // ── Mention légale ─────────────────────────────────────────
                Text(
                  'Gratuit · Sans carte bancaire · Aucun engagement',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.4),
                    height: 1.5,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 850.ms, duration: 600.ms),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge de valeur produit (icône + label)
class _ValueBadge extends StatelessWidget {
  const _ValueBadge({required this.icon, required this.label});
  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
