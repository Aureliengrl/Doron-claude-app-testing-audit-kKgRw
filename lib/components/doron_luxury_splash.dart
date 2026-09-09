import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

/// Un écran de chargement / démarrage ultra-luxe cinématique pour la marque Doron
class DoronLuxurySplashIntro extends StatefulWidget {
  final Future<void> Function()? onInitialize;
  final VoidCallback? onFinished;
  final String statusText;
  final bool isFullScreen;

  const DoronLuxurySplashIntro({
    Key? key,
    this.onInitialize,
    this.onFinished,
    this.statusText = "Préparation de votre univers...",
    this.isFullScreen = true,
  }) : super(key: key);

  @override
  State<DoronLuxurySplashIntro> createState() => _DoronLuxurySplashIntroState();
}

class _DoronLuxurySplashIntroState extends State<DoronLuxurySplashIntro>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _shimmerController;
  late AnimationController _exitController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startFlow();
      }
    });
  }

  Future<void> _startFlow() async {
    // Minimum visual display duration for smooth luxury animation
    final minTimer = Future.delayed(const Duration(milliseconds: 2600));

    if (widget.onInitialize != null) {
      await Future.wait([widget.onInitialize!(), minTimer]);
    } else {
      await minTimer;
    }

    if (!mounted) return;

    // Smooth exit animation
    await _exitController.forward();

    if (mounted && widget.onFinished != null) {
      widget.onFinished!();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _shimmerController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _exitController,
      builder: (context, child) {
        final exitProgress = _exitController.value;
        final exitOpacity = (1.0 - exitProgress).clamp(0.0, 1.0);
        final exitScale = 1.0 + (exitProgress * 0.08);

        return Opacity(
          opacity: exitOpacity,
          child: Transform.scale(
            scale: exitScale,
            child: Scaffold(
              backgroundColor: const Color(0xFF070311),
              body: Stack(
                children: [
                  // ─── 1. DYNAMIC COSMIC AURORA BACKGROUND ───
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0.0, -0.2),
                          radius: 1.2,
                          colors: [
                            Color(0xFF1E0A3C), // Luminous luxury purple core
                            Color(0xFF100522),
                            Color(0xFF06020E), // Pure luxury dark void
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ─── 2. FLOATING AMBIENT GLOW ORBS ───
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      final p = _pulseController.value;
                      return Stack(
                        children: [
                          // Top-right Magenta Orb
                          Positioned(
                            top: size.height * 0.15 + (p * 20),
                            right: -40 + (p * 15),
                            child: ImageFiltered(
                              imageFilter: ui.ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                              child: Container(
                                width: 240,
                                height: 240,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFC026D3).withOpacity(0.18 + p * 0.08),
                                ),
                              ),
                            ),
                          ),
                          // Bottom-left Violet/Cyan Orb
                          Positioned(
                            bottom: size.height * 0.20 - (p * 20),
                            left: -50 - (p * 15),
                            child: ImageFiltered(
                              imageFilter: ui.ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                              child: Container(
                                width: 260,
                                height: 260,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF7C3AED).withOpacity(0.22 + p * 0.10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // ─── 3. SUBTLE AMBIENT MESH GRID & PARTICLES ───
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CosmicStarsPainter(pulse: _pulseController),
                    ),
                  ),

                  // ─── 4. HERO BRAND REVEAL CENTER ───
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animated Glowing Emblem with Specular Orbit Ring
                          _buildEmblemStage(),

                          const SizedBox(height: 38),

                          // DORÕN Brand Typography with Shimmer
                          _buildBrandTypography(),

                          const SizedBox(height: 12),

                          // Brand Tagline
                          Text(
                            "L'art d'offrir, réinventé",
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 3.5,
                              color: Colors.white.withOpacity(0.70),
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 900.ms, delay: 600.ms)
                              .slideY(begin: 0.3, end: 0, duration: 800.ms, curve: Curves.easeOutCubic),

                          const SizedBox(height: 48),

                          // Liquid Glass Luxury Progress Loader
                          _buildProgressLoader(),

                          const SizedBox(height: 18),

                          // Dynamic Status Text
                          Text(
                            widget.statusText,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              color: Colors.white.withOpacity(0.45),
                              letterSpacing: 0.8,
                            ),
                          ).animate().fadeIn(duration: 600.ms, delay: 800.ms),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3D EMBLEM & ORBITING GLOW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildEmblemStage() {
    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating Glass Energy Ring
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, _) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: Container(
                  width: 165,
                  height: 165,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        const Color(0xFF9333EA).withOpacity(0.0),
                        const Color(0xFFC084FC).withOpacity(0.85),
                        const Color(0xFFF472B6).withOpacity(0.60),
                        const Color(0xFF38BDF8).withOpacity(0.40),
                        const Color(0xFF9333EA).withOpacity(0.0),
                      ],
                      stops: const [0.0, 0.4, 0.7, 0.85, 1.0],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF070311),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Breathing Backlight Halo
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final p = _pulseController.value;
              return Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9333EA).withOpacity(0.45 + (p * 0.35)),
                      blurRadius: 45 + (p * 20),
                      spreadRadius: 4 + (p * 8),
                    ),
                    BoxShadow(
                      color: const Color(0xFFEC4899).withOpacity(0.25 + (p * 0.20)),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              );
            },
          ),

          // Glass Bubble Container for the Official Doron Logo
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xF03B1E6D),
                  Color(0xF5180A30),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.40),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.60),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Official Doron Logo
                    Image.asset(
                      'assets/images/doron_logo.png',
                      width: 118,
                      height: 118,
                      fit: BoxFit.contain,
                    ),

                    // Specular Highlight Over Logo
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.28),
                              Colors.white.withOpacity(0.0),
                            ],
                            stops: const [0.0, 0.45],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
              .animate()
              .scale(begin: const Offset(0.75, 0.75), end: const Offset(1.0, 1.0), duration: 1100.ms, curve: Curves.easeOutBack)
              .fadeIn(duration: 700.ms),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BRAND TYPOGRAPHY & LIGHT SWEEP
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBrandTypography() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        final shimmerValue = _shimmerController.value;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFFEDE9FE), // Soft luxury white
                Color(0xFFFFFFFF),
                Color(0xFFFDE047), // Gold spark
                Color(0xFFFFFFFF),
                Color(0xFFDDD6FE),
              ],
              stops: [
                (shimmerValue - 0.35).clamp(0.0, 1.0),
                (shimmerValue - 0.15).clamp(0.0, 1.0),
                shimmerValue.clamp(0.0, 1.0),
                (shimmerValue + 0.15).clamp(0.0, 1.0),
                (shimmerValue + 0.35).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: Text(
            'DORÕN',
            style: GoogleFonts.cinzel(
              fontSize: 38,
              fontWeight: FontWeight.w700,
              letterSpacing: 14.0,
            ),
          ),
        );
      },
    )
        .animate()
        .fadeIn(duration: 900.ms, delay: 350.ms)
        .slideY(begin: 0.25, end: 0, duration: 800.ms, curve: Curves.easeOutCubic);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LIQUID GLASS MICRO PROGRESS BAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildProgressLoader() {
    return Container(
      width: 180,
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, _) {
            final val = _shimmerController.value;
            return Align(
              alignment: Alignment(-1.0 + (val * 2.0), 0.0),
              child: Container(
                width: 70,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0x00A855F7),
                      Color(0xFFC084FC),
                      Color(0xFFFFFFFF),
                      Color(0xFFF472B6),
                      Color(0x00EC4899),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC084FC).withOpacity(0.8),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 700.ms);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// COSMIC PARTICLES PAINTER
// ═══════════════════════════════════════════════════════════════════════════════
class _CosmicStarsPainter extends CustomPainter {
  final Animation<double> pulse;

  _CosmicStarsPainter({required this.pulse}) : super(repaint: pulse);

  static final List<math.Point<double>> _stars = [
    const math.Point(0.15, 0.18),
    const math.Point(0.82, 0.12),
    const math.Point(0.28, 0.35),
    const math.Point(0.75, 0.42),
    const math.Point(0.12, 0.65),
    const math.Point(0.88, 0.72),
    const math.Point(0.35, 0.85),
    const math.Point(0.68, 0.88),
    const math.Point(0.50, 0.10),
    const math.Point(0.20, 0.50),
    const math.Point(0.80, 0.55),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final p = pulse.value;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < _stars.length; i++) {
      final star = _stars[i];
      final x = star.x * size.width;
      final y = star.y * size.height;
      final phase = ((p + (i * 0.15)) % 1.0);
      final opacity = 0.25 + (math.sin(phase * math.pi) * 0.45);
      final radius = 1.0 + (math.sin(phase * math.pi) * 0.8);

      paint.color = Colors.white.withOpacity(opacity.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicStarsPainter oldDelegate) => true;
}
