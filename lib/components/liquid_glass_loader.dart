import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/components/liquid_glass.dart';

class LiquidGlassLoader extends StatelessWidget {
  final double size;
  final bool isDark;

  const LiquidGlassLoader({
    Key? key,
    this.size = 40.0,
    this.isDark = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFF8A2BE2),
              const Color(0xFFEC4899).withOpacity(0.5),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8A2BE2).withOpacity(0.5),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(3.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? LiquidGlassTokens.pageDark : Colors.white,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Center(
                  child: Container(
                    width: size * 0.4,
                    height: size * 0.4,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF8A2BE2),
                    ),
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                   .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.5, 1.5), duration: 800.ms)
                   .fade(begin: 0.5, end: 1.0, duration: 800.ms),
                ),
              ),
            ),
          ),
        ),
      ).animate(onPlay: (controller) => controller.repeat())
       .rotate(duration: 2.seconds),
    );
  }
}
