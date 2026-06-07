import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';

import 'package:flutter_animate/flutter_animate.dart';

/// Widget Premium3DIcon
/// Utilisé pour afficher une icône 3D (SVG ou PNG) depuis les assets locaux.
class Premium3DIcon extends StatelessWidget {
  final String assetName; // ex: 'gift.svg' ou 'gift.png'
  final double size;
  final BoxFit fit;

  const Premium3DIcon({
    Key? key,
    required this.assetName,
    this.size = 120.0,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String path = 'assets/3d_icons/$assetName';
    
    Widget imageWidget;

    // Détection basique du type de fichier
    if (path.toLowerCase().endsWith('.svg')) {
      imageWidget = SvgPicture.asset(
        path,
        width: size,
        height: size,
        fit: fit,
        placeholderBuilder: (BuildContext context) => SizedBox(
          width: size,
          height: size,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    } else {
      imageWidget = Image.asset(
        path,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          // Fallback gracieux
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.image_not_supported_rounded,
                color: Colors.white24,
                size: 32,
              ),
            ),
          );
        },
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: imageWidget,
    )
    .animate(onPlay: (controller) => controller.repeat(reverse: true))
    .moveY(begin: -4, end: 4, duration: 2.seconds, curve: Curves.easeInOutSine);
  }
}
