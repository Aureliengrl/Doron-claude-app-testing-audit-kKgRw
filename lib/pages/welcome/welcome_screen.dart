import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/components/liquid_glass.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const String routeName = 'Welcome';
  static const String routePath = '/welcome';

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: DarkPageBackground(
        addOrbs: true,
        child: SafeArea(
          child: Stack(
            children: [
              // ── Contenu principal ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(flex: 1),

                    // ── Logo glass ──────────────────────────────────────────
                    _GlassLogo()
                        .animate()
                        .scale(duration: 700.ms, curve: Curves.easeOutBack)
                        .fadeIn(duration: 500.ms),

                    const SizedBox(height: 32),

                    // ── Titre ───────────────────────────────────────────────
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.white, Color(0xFFE8D5FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'DORON',
                        style: GoogleFonts.poppins(
                          fontSize: 54,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 6,
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 150.ms, duration: 600.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 14),

                    // ── Accroche ─────────────────────────────────────────────
                    Text(
                      'Le cadeau parfait existe.\nDoron le trouve pour toi.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.80),
                        height: 1.6,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 600.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 36),

                    // ── 3 badges Liquid Glass ─────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _GlassBadge(icon: '🎯', label: 'Matching IA'),
                        const SizedBox(width: 10),
                        _GlassBadge(icon: '🛍️', label: '+375 idées'),
                        const SizedBox(width: 10),
                        _GlassBadge(icon: '⚡', label: '2 minutes'),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 450.ms, duration: 600.ms)
                        .slideY(begin: 0.2, end: 0),

                    const Spacer(flex: 2),

                    // ── Panneau glass bas ─────────────────────────────────
                    _BottomGlassPanel(size: size),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Logo Glass ──────────────────────────────────────────────────────────────

class _GlassLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      height: 116,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: LiquidGlassTokens.primary.withOpacity(0.50),
            blurRadius: 50,
            spreadRadius: 8,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: LiquidGlassTokens.secondary.withOpacity(0.25),
            blurRadius: 30,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.22),
                  LiquidGlassTokens.primary.withOpacity(0.15),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.40),
                width: 1.5,
              ),
            ),
            child: const Center(
              child: Text('🎁', style: TextStyle(fontSize: 54)),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Badge Liquid Glass ──────────────────────────────────────────────────────

class _GlassBadge extends StatelessWidget {
  final String icon;
  final String label;
  const _GlassBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.18),
                Colors.white.withOpacity(0.07),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 5),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.90),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Panneau Glass Bas ───────────────────────────────────────────────────────

class _BottomGlassPanel extends StatelessWidget {
  final Size size;
  const _BottomGlassPanel({required this.size});

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      darkMode: true,
      blur: 30,
      borderRadius: 28,
      tintColor: LiquidGlassTokens.primary,
      padding: const EdgeInsets.all(24),
      boxShadow: [
        BoxShadow(
          color: LiquidGlassTokens.primary.withOpacity(0.30),
          blurRadius: 40,
          offset: const Offset(0, 16),
          spreadRadius: -4,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
      child: Column(
        children: [
          // ── CTA principal ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () async {
                HapticFeedback.mediumImpact();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('first_time', false);
                if (context.mounted) context.go('/authentification');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF9B4DE8),
                      Color(0xFFEC4899),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: LiquidGlassTokens.primary.withOpacity(0.55),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🚀', style: TextStyle(fontSize: 20)),
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
                            color: Colors.white.withOpacity(0.80),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 600.ms, duration: 500.ms)
              .slideY(begin: 0.3, end: 0),

          const SizedBox(height: 16),

          // ── Lien connexion ───────────────────────────────────────────────
          GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('first_time', false);
              if (context.mounted) context.go('/authentification');
            },
            child: Text(
              'Déjà un compte ? Se connecter',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withOpacity(0.60),
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white.withOpacity(0.35),
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 750.ms, duration: 500.ms),

          const SizedBox(height: 12),

          Text(
            'Gratuit · Sans carte bancaire · Aucun engagement',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.white.withOpacity(0.35),
            ),
          )
              .animate()
              .fadeIn(delay: 900.ms, duration: 500.ms),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 550.ms, duration: 600.ms)
        .slideY(begin: 0.4, end: 0);
  }
}
