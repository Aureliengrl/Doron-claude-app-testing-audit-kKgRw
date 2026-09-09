import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/components/doron_luxury_loader.dart';

class LiquidGlassLoader extends StatelessWidget {
  final double size;
  final bool isDark;
  final String? message;

  const LiquidGlassLoader({
    Key? key,
    this.size = 48.0,
    this.isDark = true,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DoronLuxuryLoader(
      size: size,
      message: message,
      showLogo: true,
    );
  }
}
