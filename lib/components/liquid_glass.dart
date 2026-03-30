import 'dart:ui';
import 'package:flutter/material.dart';

// ─── Design Tokens Liquid Glass Doron ────────────────────────────────────────

class LiquidGlassTokens {
  // Couleurs d'ambiance
  static const Color primary = Color(0xFF8A2BE2);
  static const Color secondary = Color(0xFFEC4899);

  // Fonds de page
  static const Color pageDark = Color(0xFF0A0014);
  static const Color pageDarkAlt = Color(0xFF0F0F1A);
  static const Color pageGradientTop = Color(0xFF0A0A1A);
  static const Color pageGradientBottom = Color(0xFF121225);

  // Surface glass — fond clair
  static const Color glassSurfaceLight = Color(0xAAFFFFFF); // rgba(255,255,255, 0.67)
  static const Color glassBorderLight = Color(0x44FFFFFF);
  static const Color glassSpecularLight = Color(0xBBFFFFFF);

  // Surface glass — fond sombre
  static const Color glassSurfaceDark = Color(0x0FFFFFFF);  // rgba(255,255,255, 0.06)
  static const Color glassBorderDark = Color(0x1FFFFFFF);    // rgba(255,255,255, 0.12)
  static const Color glassSpecularDark = Color(0x1FFFFFFF);  // rgba(255,255,255, 0.12)

  // Blur
  static const double blurLight = 25.0;
  static const double blurHeavy = 40.0;
  static const double navBarBlur = 40.0;
  static const double cardBlur = 25.0;

  // Ombres
  static List<BoxShadow> shadowPrimary = [
    BoxShadow(
      color: primary.withOpacity(0.25),
      blurRadius: 30,
      offset: const Offset(0, 12),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.20),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> shadowSubtle = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Gradient de page sombre — deep navy-black tones, no purple tint
  static const LinearGradient darkPageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A0A1A),
      Color(0xFF121225),
      Color(0xFF0D0D1A),
    ],
    stops: [0.0, 0.6, 1.0],
  );
}

// ─── LiquidGlassCard ─────────────────────────────────────────────────────────

/// Carte avec effet Liquid Glass style iOS 26.
/// Utilise BackdropFilter blur + surface translucide + specular highlight.
class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? tintColor;
  final bool darkMode;
  final double blur;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.tintColor,
    this.darkMode = true,
    this.blur = LiquidGlassTokens.cardBlur,
    this.boxShadow,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = darkMode
        ? const Color(0x0FFFFFFF) // rgba(255,255,255, 0.06)
        : LiquidGlassTokens.glassSurfaceLight;
    final border = darkMode
        ? const Color(0x1FFFFFFF) // rgba(255,255,255, 0.12)
        : LiquidGlassTokens.glassBorderLight;
    final specular = darkMode
        ? LiquidGlassTokens.glassSpecularDark
        : LiquidGlassTokens.glassSpecularLight;

    final tint = tintColor ?? (darkMode
        ? LiquidGlassTokens.primary.withOpacity(0.06)
        : Colors.transparent);

    final radius = BorderRadius.circular(borderRadius);

    Widget content = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: CustomPaint(
          painter: _SpecularPainter(
            borderRadius: radius,
            specularColor: specular,
          ),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: radius,
              color: surface,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tint.withOpacity((tint.opacity * 1.8).clamp(0.0, 1.0)),
                  tint,
                ],
              ),
              border: Border.all(
                color: border,
                width: 0.5,
              ),
            ),
            child: padding != null
                ? Padding(padding: padding!, child: child)
                : child,
          ),
        ),
      ),
    );

    if (boxShadow != null || !darkMode) {
      content = Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: boxShadow ?? LiquidGlassTokens.shadowSubtle,
        ),
        child: content,
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}

// ─── Custom Painter specular highlight ───────────────────────────────────────

/// Ajoute un reflet lumineux subtil en haut de la carte (effet verre Apple).
class _SpecularPainter extends CustomPainter {
  final BorderRadius borderRadius;
  final Color specularColor;

  const _SpecularPainter({
    required this.borderRadius,
    required this.specularColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle gradient covering only top 20% of the card
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          specularColor.withOpacity(0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.20));

    final path = Path()
      ..addRRect(RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.20),
        topLeft: borderRadius.topLeft,
        topRight: borderRadius.topRight,
      ));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SpecularPainter oldDelegate) => false;
}

// ─── LiquidGlassSurface ──────────────────────────────────────────────────────

/// Surface plein écran ou grande zone avec effet glass.
/// Idéal pour les headers, modaux, bottom sheets.
class LiquidGlassSurface extends StatelessWidget {
  final Widget child;
  final double blur;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool darkMode;

  const LiquidGlassSurface({
    super.key,
    required this.child,
    this.blur = 30,
    this.color,
    this.borderRadius,
    this.padding,
    this.darkMode = true,
  });

  @override
  Widget build(BuildContext context) {
    final surface = color ?? (darkMode
        ? const Color(0x0DFFFFFF) // rgba(255,255,255, 0.05)
        : const Color(0xCCFFFFFF));

    final Widget inner = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: borderRadius,
          border: Border.all(
            color: darkMode
                ? const Color(0x1FFFFFFF) // rgba(255,255,255, 0.12)
                : const Color(0x44FFFFFF),
            width: 0.5,
          ),
        ),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: inner);
    }
    return inner;
  }
}

// ─── LiquidGlassPill ─────────────────────────────────────────────────────────

/// Bouton / tag / chip en style Liquid Glass.
/// Utilisé pour les filtres, CTA secondaires, badges.
class LiquidGlassPill extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isActive;
  final Color? activeColor;
  final double height;
  final EdgeInsetsGeometry padding;
  final bool darkMode;

  const LiquidGlassPill({
    super.key,
    required this.child,
    this.onTap,
    this.isActive = false,
    this.activeColor,
    this.height = 36,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.darkMode = true,
  });

  @override
  Widget build(BuildContext context) {
    final primary = activeColor ?? LiquidGlassTokens.primary;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height / 2),
              color: isActive ? primary : null,
              gradient: isActive
                  ? null
                  : LinearGradient(
                      colors: darkMode
                          ? [
                              Colors.white.withOpacity(0.08),
                              Colors.white.withOpacity(0.04),
                            ]
                          : [
                              Colors.white.withOpacity(0.70),
                              Colors.white.withOpacity(0.45),
                            ],
                    ),
              border: Border.all(
                color: isActive
                    ? Colors.white.withOpacity(0.20)
                    : Colors.white.withOpacity(darkMode ? 0.10 : 0.5),
                width: 0.5,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: primary.withOpacity(0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

// ─── DarkPageBackground ───────────────────────────────────────────────────────

/// Fond de page sombre ambiant Liquid Glass.
/// À placer en Stack derrière tout le contenu.
class DarkPageBackground extends StatelessWidget {
  final Widget child;
  final bool addOrbs; // Ajouter des orbes lumineux pour l'effet depth

  const DarkPageBackground({
    super.key,
    required this.child,
    this.addOrbs = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LiquidGlassTokens.darkPageGradient,
      ),
      child: addOrbs
          ? Stack(
              children: [
                // Orbe violet haut-gauche — large and diffuse
                Positioned(
                  top: -120,
                  left: -100,
                  child: _ColorOrb(
                    color: LiquidGlassTokens.primary,
                    size: 400,
                    opacity: 0.12,
                  ),
                ),
                // Orbe rose haut-droite — large and diffuse
                Positioned(
                  top: 60,
                  right: -100,
                  child: _ColorOrb(
                    color: LiquidGlassTokens.secondary,
                    size: 320,
                    opacity: 0.10,
                  ),
                ),
                // Orbe violet bas-centre — large and diffuse
                Positioned(
                  bottom: 80,
                  left: MediaQuery.of(context).size.width * 0.15,
                  child: _ColorOrb(
                    color: LiquidGlassTokens.primary,
                    size: 280,
                    opacity: 0.10,
                  ),
                ),
                // Orbe bleu bas-droite — subtle blue for color variety
                Positioned(
                  bottom: -60,
                  right: -80,
                  child: _ColorOrb(
                    color: const Color(0xFF2563EB),
                    size: 340,
                    opacity: 0.15,
                  ),
                ),
                child,
              ],
            )
          : child,
    );
  }
}

class _ColorOrb extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _ColorOrb({required this.color, required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(0),
          ],
        ),
      ),
    );
  }
}

// ─── LiquidGlassInput ─────────────────────────────────────────────────────────

/// Champ de texte style Liquid Glass — iOS-native rounded rect look.
class LiquidGlassInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final ValueChanged<String>? onChanged;
  final bool darkMode;
  final TextInputType keyboardType;
  final bool obscureText;

  const LiquidGlassInput({
    super.key,
    this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.onChanged,
    this.darkMode = true,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: darkMode
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.60),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(darkMode ? 0.12 : 0.50),
              width: 0.5,
            ),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboardType,
            obscureText: obscureText,
            style: TextStyle(
              color: darkMode ? Colors.white : const Color(0xFF111827),
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: darkMode
                    ? Colors.white.withOpacity(0.40)
                    : Colors.black.withOpacity(0.35),
                fontSize: 15,
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon,
                      color: darkMode
                          ? Colors.white.withOpacity(0.50)
                          : Colors.black.withOpacity(0.40),
                      size: 20)
                  : null,
              suffixIcon: suffixIcon != null
                  ? GestureDetector(
                      onTap: onSuffixTap,
                      child: Icon(suffixIcon,
                          color: darkMode
                              ? Colors.white.withOpacity(0.50)
                              : Colors.black.withOpacity(0.40),
                          size: 20))
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: LiquidGlassTokens.primary.withOpacity(0.60),
                  width: 1.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── LiquidGlassHeader ───────────────────────────────────────────────────────

/// Standardized page header with consistent height and glass treatment.
/// Used on Home, Search, Inspiration, Profile pages for identical "notch" look.
class LiquidGlassHeader extends StatelessWidget {
  final Widget child;
  final double height;
  final double bottomRadius;

  const LiquidGlassHeader({
    super.key,
    required this.child,
    this.height = 120,
    this.bottomRadius = 28,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(bottomRadius),
        bottomRight: Radius.circular(bottomRadius),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                LiquidGlassTokens.primary.withOpacity(0.15),
                LiquidGlassTokens.secondary.withOpacity(0.08),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.12),
                width: 0.5,
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
