import '/utils/app_logger.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/services/first_time_service.dart';
import '/auth/firebase_auth/auth_util.dart';

class SplashScreenWidget extends StatefulWidget {
  const SplashScreenWidget({super.key});

  static String routeName = 'SplashScreen';
  static String routePath = '/splash';

  @override
  State<SplashScreenWidget> createState() => _SplashScreenWidgetState();
}

class _SplashScreenWidgetState extends State<SplashScreenWidget>
    with TickerProviderStateMixin {
  late AnimationController _mainController;       // logo + texte
  late AnimationController _gradientController;   // fond gradient loop
  late AnimationController _particleController;   // particules loop
  late AnimationController _exitController;       // fade-out final

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<double> _taglineFade;
  late Animation<double> _exitFade;

  final List<_Particle> _particles = [];
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();

    // Générer les particules
    for (int i = 0; i < 12; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble() * 0.7 + 0.15,
        size: _rng.nextDouble() * 6 + 3,
        speed: _rng.nextDouble() * 0.3 + 0.1,
        phase: _rng.nextDouble() * math.pi * 2,
        opacity: _rng.nextDouble() * 0.5 + 0.3,
      ));
    }

    // Contrôleur principal (1600ms)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _logoScale = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.65, curve: Curves.easeIn),
      ),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
      ),
    );

    // Gradient animé fond (loop 4s)
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Particules (loop 3s)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Exit fade-out (400ms) — déclenché après _navigate
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    _mainController.forward();
    _navigate();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _gradientController.dispose();
    _particleController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    try {
      AppLogger.debug('🚀 Début navigation splash screen', 'Splash');
      await Future.delayed(const Duration(milliseconds: 2400));
      if (!mounted) return;

      final futures = await Future.wait([
        FirstTimeService.isFirstTime(),
        FirstTimeService.hasCompletedOnboarding(),
      ]).timeout(
        const Duration(seconds: 5),
        onTimeout: () => [true, false],
      );

      final isFirst = futures[0] as bool;
      final hasCompleted = futures[1] as bool;
      final isLoggedIn = loggedIn;

      // Fade-out élégant avant navigation
      if (mounted) await _exitController.forward();
      if (!mounted) return;

      AppLogger.debug(
        '📊 isFirst=$isFirst hasCompleted=$hasCompleted isLoggedIn=$isLoggedIn',
        'Splash',
      );

      if (isFirst && !hasCompleted) {
        Navigator.pushReplacementNamed(context, '/onboarding-advanced');
      } else if (!isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/authentification');
      } else {
        Navigator.pushReplacementNamed(context, '/homeAlgoace');
      }
    } catch (e) {
      AppLogger.debug('❌ Erreur navigation splash: $e', 'Splash');
      if (mounted) Navigator.pushReplacementNamed(context, '/onboarding-advanced');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _exitController,
      builder: (_, child) => Opacity(
        opacity: _exitFade.value,
        child: child,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        body: AnimatedBuilder(
          animation: Listenable.merge([
            _gradientController,
            _particleController,
            _mainController,
          ]),
          builder: (context, _) {
            final t = _gradientController.value;
            final c1 = Color.lerp(
              const Color(0xFF6B21C8),
              const Color(0xFF4A1090),
              t,
            )!;
            final c2 = Color.lerp(
              const Color(0xFFEC4899),
              const Color(0xFF8A2BE2),
              t,
            )!;
            final c3 = Color.lerp(
              const Color(0xFF1A0035),
              const Color(0xFF0D0D2A),
              t,
            )!;

            return Stack(
              fit: StackFit.expand,
              children: [
                // ── Fond gradient animé ──
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(
                        math.sin(t * math.pi * 2) * 0.3,
                        -0.3 + math.cos(t * math.pi * 2) * 0.2,
                      ),
                      radius: 1.4,
                      colors: [c1, c2, c3],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),

                // ── Particules flottantes ──
                CustomPaint(
                  painter: _ParticlePainter(
                    particles: _particles,
                    progress: _particleController.value,
                  ),
                ),

                // ── Contenu centré ──
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo avec scale élastique
                      Transform.scale(
                        scale: _logoScale.value,
                        child: Opacity(
                          opacity: _logoFade.value,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8A2BE2).withOpacity(0.6),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                                BoxShadow(
                                  color: const Color(0xFFEC4899).withOpacity(0.4),
                                  blurRadius: 60,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/doron_logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF8A2BE2), Color(0xFFEC4899)],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.card_giftcard_rounded,
                                    color: Colors.white,
                                    size: 60,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Titre "DORÕN" slide-up
                      SlideTransition(
                        position: _titleSlide,
                        child: FadeTransition(
                          opacity: _titleFade,
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Colors.white, Color(0xFFEC4899), Colors.white],
                              stops: [0.0, 0.5, 1.0],
                            ).createShader(bounds),
                            child: Text(
                              'DORÕN',
                              style: GoogleFonts.outfit(
                                fontSize: 52,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 8,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Tagline fade-in
                      FadeTransition(
                        opacity: _taglineFade,
                        child: Text(
                          'L\'art de choisir le cadeau parfait',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            color: Colors.white.withOpacity(0.7),
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Indicateur de chargement discret en bas ──
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _taglineFade,
                    child: Center(
                      child: SizedBox(
                        width: 40,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFEC4899),
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Particule data class ──
class _Particle {
  final double x;
  double y;
  final double size;
  final double speed;
  final double phase;
  final double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
    required this.opacity,
  });
}

// ── Custom painter pour les particules étoiles ──
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress + p.phase / (math.pi * 2)) % 1.0;
      final y = (p.y - t * p.speed) % 1.0;
      final fade = t < 0.15 ? t / 0.15 : (t > 0.85 ? (1.0 - t) / 0.15 : 1.0);

      final paint = Paint()
        ..color = Colors.white.withOpacity(p.opacity * fade)
        ..style = PaintingStyle.fill;

      final cx = p.x * size.width;
      final cy = y * size.height;
      final s = p.size;

      // Forme étoile 4 branches
      final path = Path();
      for (int i = 0; i < 8; i++) {
        final angle = i * math.pi / 4;
        final r = i.isEven ? s : s * 0.4;
        final px = cx + r * math.cos(angle);
        final py = cy + r * math.sin(angle);
        if (i == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}
