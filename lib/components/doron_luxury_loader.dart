import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

/// Loader ultra-luxe unifié avec emblème Doron et halo Liquid Glass
class DoronLuxuryLoader extends StatefulWidget {
  final double size;
  final String? message;
  final bool showLogo;
  final Color primaryColor;

  const DoronLuxuryLoader({
    Key? key,
    this.size = 64.0,
    this.message,
    this.showLogo = true,
    this.primaryColor = const Color(0xFF9333EA),
  }) : super(key: key);

  @override
  State<DoronLuxuryLoader> createState() => _DoronLuxuryLoaderState();
}

class _DoronLuxuryLoaderState extends State<DoronLuxuryLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Rotating liquid glass gradient ring
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _controller.value * 2 * math.pi,
                      child: Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              widget.primaryColor.withOpacity(0.0),
                              const Color(0xFFC084FC),
                              const Color(0xFFF472B6),
                              const Color(0xFF38BDF8),
                              widget.primaryColor.withOpacity(0.0),
                            ],
                            stops: const [0.0, 0.45, 0.70, 0.88, 1.0],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Glass Core Layer
                Container(
                  width: widget.size - 6,
                  height: widget.size - 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0C051A),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.primaryColor.withOpacity(0.40),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: widget.showLogo
                          ? Padding(
                              padding: EdgeInsets.all(widget.size * 0.16),
                              child: Image.asset(
                                'assets/images/doron_wave_mark.png',
                                fit: BoxFit.contain,
                              ),
                            )
                          : Container(
                              color: Colors.transparent,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.message!,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.75),
                letterSpacing: 0.6,
              ),
            ).animate().fadeIn(duration: 400.ms),
          ],
        ],
      ),
    );
  }
}
