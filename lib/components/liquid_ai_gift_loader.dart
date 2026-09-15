import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LiquidAIGiftLoader extends StatefulWidget {
  final double? progress; // If null, auto-animates from 0% to ~95%
  final String label;
  final String doneLabel;
  final String subtitle;
  final VoidCallback? onRestart;
  final bool isDone;
  final VoidCallback? onComplete;
  final double minSeconds;
  final double maxSeconds;

  const LiquidAIGiftLoader({
    super.key,
    this.progress,
    this.label = "L'IA prépare vos cadeaux...",
    this.doneLabel = "Tes cadeaux sont prêts",
    this.subtitle = "Matching intelligent par tags (sexe, âge, centres d'intérêt)",
    this.onRestart,
    this.isDone = false,
    this.onComplete,
    this.minSeconds = 3.0,
    this.maxSeconds = 7.0,
  });

  @override
  State<LiquidAIGiftLoader> createState() => _LiquidAIGiftLoaderState();
}

class _LiquidAIGiftLoaderState extends State<LiquidAIGiftLoader>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _progressController;
  late AnimationController _bobController;
  late AnimationController _glowController;
  late AnimationController _sheenController;

  double _simulatedProgress = 0.0;
  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();

    // 1. Continuous wave oscillation
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    // 2. Floating bobbing animation (4.2s ease-in-out)
    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);

    // 3. Glowing aura pulsation (3.4s)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat(reverse: true);

    // 4. Progress bar sheen reflection (1.7s linear)
    _sheenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat();

    // 5. Simulated progress animation (0.0 to 0.95 over ~4s)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );

    _progressController.addListener(() {
      if (mounted && widget.progress == null) {
        setState(() {
          // Non-linear ease-out progression
          final raw = _progressController.value;
          _simulatedProgress = (1.0 - math.pow(1.0 - raw, 2.1)).toDouble() * 0.95;
        });
      }
    });

    _progressController.forward();
  }

  @override
  void didUpdateWidget(LiquidAIGiftLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDone && !oldWidget.isDone && !_hasCompleted) {
      _hasCompleted = true;
      _progressController.stop();
      setState(() {
        _simulatedProgress = 1.0;
      });
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _progressController.dispose();
    _bobController.dispose();
    _glowController.dispose();
    _sheenController.dispose();
    super.dispose();
  }

  void _restart() {
    setState(() {
      _simulatedProgress = 0.0;
      _hasCompleted = false;
    });
    _progressController.reset();
    _progressController.forward();
    widget.onRestart?.call();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveProgress = (widget.isDone || _hasCompleted)
        ? 1.0
        : (widget.progress ?? _simulatedProgress).clamp(0.0, 1.0);
    final pct = (effectiveProgress * 100).round();
    final isDone = effectiveProgress >= 0.999 || widget.isDone;

    final currentLabel = isDone ? widget.doneLabel : widget.label;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFDF2F8),
            Color(0xFFFBEEF6),
            Color(0xFFF7EAF6),
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── En-tête : Titre & Sous-titre ────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 8),
              child: Column(
                children: [
                  Text(
                    'Tes cadeaux\npersonnalisés',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8A2BE2),
                      height: 1.12,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Basés sur tes réponses',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF7C7480),
                    ),
                  ),
                ],
              ),
            ),

            // ── Centre : Carte centrale avec Vague liquide & Bobbing ────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Visual avec bobbing et glow
                    AnimatedBuilder(
                      animation: Listenable.merge([_bobController, _glowController, _waveController]),
                      builder: (context, child) {
                        final bobOffset = math.sin(_bobController.value * math.pi * 2) * -6.0;
                        final glowOpacity = 0.30 + math.sin(_glowController.value * math.pi * 2) * 0.20;

                        return Transform.translate(
                          offset: Offset(0, bobOffset),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // 1. Halo lumineux violet radial
                              Container(
                                width: 268,
                                height: 268,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(0xFF8A2BE2).withOpacity(glowOpacity),
                                      const Color(0xFF8A2BE2).withOpacity(0.0),
                                    ],
                                    stops: const [0.0, 0.68],
                                  ),
                                ),
                              ),

                              // 2. Boîte arrondie 216x216
                              Container(
                                width: 216,
                                height: 216,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFE6F5),
                                  borderRadius: BorderRadius.circular(56),
                                  border: Border.all(
                                    color: const Color(0xFF8A2BE2).withOpacity(0.14),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF5A1E8C).withOpacity(0.25),
                                      blurRadius: 40,
                                      spreadRadius: -10,
                                      offset: const Offset(0, 18),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(55),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      // Image/Logo de fond en niveaux de gris atténué
                                      Opacity(
                                        opacity: 0.28,
                                        child: ColorFiltered(
                                          colorFilter: const ColorFilter.matrix(<double>[
                                            0.2126, 0.7152, 0.0722, 0, 50,
                                            0.2126, 0.7152, 0.0722, 0, 50,
                                            0.2126, 0.7152, 0.0722, 0, 50,
                                            0,      0,      0,      1, 0,
                                          ]),
                                          child: _buildLogoImage(),
                                        ),
                                      ),

                                      // Vague liquide montante avec logo coloré
                                      ClipPath(
                                        clipper: _LiquidWaveClipper(
                                          progress: effectiveProgress,
                                          wavePhase: _waveController.value * math.pi * 2,
                                        ),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFF8A2BE2),
                                                Color(0xFFEC4899),
                                              ],
                                            ),
                                          ),
                                          child: _buildLogoImage(tintWhite: true),
                                        ),
                                      ),

                                      // Ligne lumineuse de crête
                                      if (effectiveProgress > 0.01 && effectiveProgress < 0.99)
                                        CustomPaint(
                                          painter: _WaveCrestPainter(
                                            progress: effectiveProgress,
                                            wavePhase: _waveController.value * math.pi * 2,
                                          ),
                                        ),

                                      // Reflet de verre supérieur (spéculaire)
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.white.withOpacity(0.34),
                                              Colors.white.withOpacity(0.0),
                                            ],
                                            stops: const [0.0, 0.44],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 38),

                    // ── Barre de progression avec éclat Sheen ───────────────
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Column(
                        children: [
                          Container(
                            height: 12,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8A2BE2).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final fillWidth = constraints.maxWidth * effectiveProgress;

                                return Stack(
                                  children: [
                                    // Barre remplie avec dégradé
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      width: fillWidth,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFA95CF0),
                                            Color(0xFF8A2BE2),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                    ),

                                    // Reflet lumineux sheen en mouvement
                                    if (fillWidth > 10)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(999),
                                        child: SizedBox(
                                          width: fillWidth,
                                          height: 12,
                                          child: AnimatedBuilder(
                                            animation: _sheenController,
                                            builder: (context, child) {
                                              return Transform.translate(
                                                offset: Offset(
                                                  -fillWidth + (_sheenController.value * fillWidth * 2.2),
                                                  0,
                                                ),
                                                child: Container(
                                                  width: fillWidth * 0.45,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.white.withOpacity(0.0),
                                                        Colors.white.withOpacity(0.55),
                                                        Colors.white.withOpacity(0.0),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Libellé & Pourcentage
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Flexible(
                                child: Text(
                                  currentLabel,
                                  style: GoogleFonts.poppins(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2C2430),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$pct%',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF8A2BE2),
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // Sous-texte explicatif
                          Text(
                            widget.subtitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              color: const Color(0xFF9A929E),
                              fontWeight: FontWeight.w400,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bas de page : Bouton Relancer le chargement ──────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: _restart,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.70),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFF8A2BE2).withOpacity(0.55),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8A2BE2).withOpacity(0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.refresh_rounded,
                              color: Color(0xFF8A2BE2),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Relancer le chargement',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF8A2BE2),
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
        ),
      ),
    );
  }

  Widget _buildLogoImage({bool tintWhite = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Image.asset(
          'assets/images/doron_logo.png',
          fit: BoxFit.contain,
          color: tintWhite ? Colors.white : null,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.card_giftcard_rounded,
              size: 80,
              color: tintWhite ? Colors.white : const Color(0xFF8A2BE2),
            );
          },
        ),
      ),
    );
  }
}

/// Custom Clipper qui génère la forme d'une vague fluide sinusoïdale
class _LiquidWaveClipper extends CustomClipper<Path> {
  final double progress;
  final double wavePhase;

  _LiquidWaveClipper({
    required this.progress,
    required this.wavePhase,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final surfaceY = size.height * (1.0 - progress);
    final amplitude = (size.height * 0.036) * (1.0 - progress) + 1.2;

    const steps = 30;
    final points = <Offset>[];

    for (int i = 0; i <= steps; i++) {
      final x = (i / steps) * size.width;
      final wave1 = math.sin((i / steps) * math.pi * 2.4 + wavePhase);
      final wave2 = 0.5 * math.sin((i / steps) * math.pi * 4.1 - (wavePhase * 1.4));
      final y = surfaceY + amplitude * (wave1 + wave2);
      points.add(Offset(x, y.clamp(0.0, size.height)));
    }

    path.moveTo(0, size.height);
    path.lineTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_LiquidWaveClipper oldClipper) {
    return oldClipper.progress != progress || oldClipper.wavePhase != wavePhase;
  }
}

/// Painter pour dessiner la crête lumineuse de la vague
class _WaveCrestPainter extends CustomPainter {
  final double progress;
  final double wavePhase;

  _WaveCrestPainter({
    required this.progress,
    required this.wavePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final surfaceY = size.height * (1.0 - progress);
    final amplitude = (size.height * 0.036) * (1.0 - progress) + 1.2;

    const steps = 30;
    final path = Path();

    for (int i = 0; i <= steps; i++) {
      final x = (i / steps) * size.width;
      final wave1 = math.sin((i / steps) * math.pi * 2.4 + wavePhase);
      final wave2 = 0.5 * math.sin((i / steps) * math.pi * 4.1 - (wavePhase * 1.4));
      final y = surfaceY + amplitude * (wave1 + wave2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.20),
          Colors.white.withOpacity(0.95),
          Colors.white.withOpacity(0.20),
        ],
      ).createShader(Rect.fromLTWH(0, surfaceY - 5, size.width, 10));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WaveCrestPainter oldPainter) {
    return oldPainter.progress != progress || oldPainter.wavePhase != wavePhase;
  }
}
