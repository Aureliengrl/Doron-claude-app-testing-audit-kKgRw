import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Logo « DORÕN » en faux-3D (relief + reflet + ombre colorée + léger flottement).
///
/// Pas de moteur 3D : une face dégradée + des ombres superposées (profondeur
/// sombre + halo coloré) donnent l'effet premium à faible coût. Utilisé sur
/// l'accueil, et réutilisable pour les en-têtes marques / événements.
class Logo3D extends StatelessWidget {
  final double fontSize;
  final bool animate;

  const Logo3D({super.key, this.fontSize = 34, this.animate = true});

  @override
  Widget build(BuildContext context) {
    final Widget wordmark = ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Color(0xFFE9D5FF)],
      ).createShader(rect),
      child: Text(
        'DORÕN',
        style: GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 3,
          color: Colors.white, // teinté par le ShaderMask
          height: 1.0,
          shadows: const [
            // profondeur (extrusion sombre)
            Shadow(color: Color(0x66000000), offset: Offset(0, 3), blurRadius: 6),
            // halo coloré (glow premium)
            Shadow(color: Color(0x66EC4899), offset: Offset(0, 7), blurRadius: 22),
            // reflet supérieur subtil
            Shadow(color: Color(0x55FFFFFF), offset: Offset(0, -1), blurRadius: 1),
          ],
        ),
      ),
    );

    if (!animate) return wordmark;

    return wordmark
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -3, end: 3, duration: 2500.ms, curve: Curves.easeInOutSine);
  }
}
