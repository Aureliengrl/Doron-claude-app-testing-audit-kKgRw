import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/physics.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import '/components/liquid_glass.dart';

// ══════════════════════════════════════════════════════════════════════════════
// FloatingModernNavBar — Liquid Glass iOS 26
// Caractéristiques :
//   • Blur profond (sigmaX/Y: 60)
//   • Fond très translucide (glass sur glass)
//   • Gradient specular 3 stops + border prismatique non-uniforme
//   • Pill active glass-over-glass avec spring physics
//   • Dispersion prismatique (reflets arc-en-ciel sur les bords)
//   • Spring bounce sur tap (SpringSimulation physique)
//   • Icons Iconly Pro (light → bold au tap)
//   • Haptic medium au changement d'onglet
// ══════════════════════════════════════════════════════════════════════════════

class FloatingModernNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavBarItem> items;
  final Color? primaryColor;
  final double height;
  final double borderRadius;
  final EdgeInsets margin;

  const FloatingModernNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.primaryColor,
    this.height = 72,
    this.borderRadius = 36,
    this.margin = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  });

  @override
  State<FloatingModernNavBar> createState() => _FloatingModernNavBarState();
}

class _FloatingModernNavBarState extends State<FloatingModernNavBar>
    with TickerProviderStateMixin {

  /// Contrôleur du pill (position animée via spring)
  late AnimationController _pillController;
  late Animation<double> _pillPosAnim;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _pillController = AnimationController(vsync: this);
    _pillPosAnim = AlwaysStoppedAnimation(0.0);
  }

  @override
  void didUpdateWidget(FloatingModernNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      final prevIdx = oldWidget.currentIndex;
      final currIdx = widget.currentIndex;
      _previousIndex = prevIdx;

      // Spring simulation — tension élevée, friction légère → rebond satisfaisant
      final spring = SpringDescription(mass: 1.0, stiffness: 320, damping: 26);
      final sim = SpringSimulation(spring, 0.0, 1.0, 0.0);
      _pillController.animateWith(sim);
      _pillPosAnim = Tween<double>(begin: prevIdx.toDouble(), end: currIdx.toDouble())
          .animate(_pillController);
    }
  }

  @override
  void dispose() {
    _pillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primaryColor ?? LiquidGlassTokens.primary;
    final leftItems = widget.items.length > 1
        ? widget.items.sublist(0, widget.items.length - 1)
        : widget.items;
    final rightItem = widget.items.length > 1 ? widget.items.last : null;
    final rightIndex = widget.items.length - 1;

    return Padding(
      padding: widget.margin,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Pilule principale (items de gauche) ──────────────────────────
          Expanded(
            child: _GlassPill(
              height: widget.height,
              borderRadius: widget.borderRadius,
              primary: primary,
              child: Stack(
                children: [
                  // ── Pill indicateur spring ──────────────────────────────
                  AnimatedBuilder(
                    animation: _pillController,
                    builder: (ctx, _) {
                      final itemCount = leftItems.length;
                      final pos = _pillController.isAnimating
                          ? _pillPosAnim.value
                          : widget.currentIndex < itemCount
                              ? widget.currentIndex.toDouble()
                              : (_previousIndex < itemCount ? _previousIndex.toDouble() : 0.0);

                      return LayoutBuilder(builder: (ctx2, constraints) {
                        final itemW = constraints.maxWidth / itemCount;
                        final pillW = 56.0;
                        final pillH = 46.0;
                        final left = pos * itemW + (itemW - pillW) / 2;

                        return AnimatedOpacity(
                          opacity: widget.currentIndex < itemCount ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Positioned(
                            left: left.clamp(0.0, constraints.maxWidth - pillW),
                            top: (widget.height - pillH) / 2,
                            child: _ActivePill(
                              width: pillW,
                              height: pillH,
                              primary: primary,
                            ),
                          ),
                        );
                      });
                    },
                  ),

                  // ── Items ──────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(
                      leftItems.length,
                      (i) => _NavItem(
                        item: leftItems[i],
                        isSelected: widget.currentIndex == i,
                        primary: primary,
                        height: widget.height,
                        onTap: () => widget.onTap(i),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bouton circulaire droite (profil) ────────────────────────────
          if (rightItem != null) ...[
            const SizedBox(width: 14),
            _GlassPill(
              height: widget.height,
              borderRadius: widget.height / 2,
              primary: primary,
              isCircle: true,
              child: Stack(
                children: [
                  // Fond lumineux actif
                  AnimatedOpacity(
                    opacity: widget.currentIndex == rightIndex ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [primary.withOpacity(0.55), Colors.transparent],
                          radius: 0.75,
                        ),
                      ),
                    ),
                  ),
                  // Item
                  _NavItem(
                    item: rightItem,
                    isSelected: widget.currentIndex == rightIndex,
                    primary: primary,
                    height: widget.height,
                    onTap: () => widget.onTap(rightIndex),
                  ),
                ],
              ),
            ),
          ],
        ],
      )
          .animate()
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.7, end: 0, duration: 600.ms, curve: Curves.easeOutCubic),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _GlassPill — conteneur glass avec dispersion prismatique
// ══════════════════════════════════════════════════════════════════════════════
class _GlassPill extends StatelessWidget {
  final Widget child;
  final double height;
  final double borderRadius;
  final Color primary;
  final bool isCircle;

  const _GlassPill({
    required this.child,
    required this.height,
    required this.borderRadius,
    required this.primary,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return Container(
      width: isCircle ? height : null,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.35),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: -6,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.38),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          // Lueur intérieure (depth)
          BoxShadow(
            color: Colors.white.withOpacity(0.06),
            blurRadius: 0,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: CustomPaint(
            painter: _LiquidGlassPainter(
              borderRadius: borderRadius,
              primary: primary,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                // Fond très translucide — le vrai glass
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.22),  // specular haut-gauche
                    Colors.white.withOpacity(0.06),  // transparent milieu
                    Colors.white.withOpacity(0.12),  // légère lueur bas-droite
                  ],
                  stops: const [0.0, 0.50, 1.0],
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _LiquidGlassPainter — specular + border prismatique non-uniforme
// ══════════════════════════════════════════════════════════════════════════════
class _LiquidGlassPainter extends CustomPainter {
  final double borderRadius;
  final Color primary;

  const _LiquidGlassPainter({required this.borderRadius, required this.primary});

  @override
  void paint(Canvas canvas, Size size) {
    final r = borderRadius;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(r));

    // ── 1. Specular gradient haut (reflet de lumière) ──────────────────────
    final specPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.32),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.38],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.45));
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.45),
        topLeft: Radius.circular(r),
        topRight: Radius.circular(r),
      ),
      specPaint,
    );

    // ── 2. Border prismatique non-uniforme (dispersion) ────────────────────
    // Top — très lumineux (blanc)
    final topPaint = Paint()
      ..color = Colors.white.withOpacity(0.65)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final topPath = Path()
      ..moveTo(r, 0)
      ..lineTo(size.width - r, 0)
      ..arcToPoint(Offset(size.width, r), radius: Radius.circular(r));
    canvas.drawPath(topPath, topPaint);

    // Bas — sombre (ombre)
    final bottomPaint = Paint()
      ..color = Colors.black.withOpacity(0.20)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    final bottomPath = Path()
      ..moveTo(r, size.height)
      ..lineTo(size.width - r, size.height)
      ..arcToPoint(Offset(size.width - r, size.height), radius: Radius.circular(r));
    canvas.drawPath(bottomPath, bottomPaint);

    // Côtés — reflets prismatiques (violet/bleu faint)
    final leftPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primary.withOpacity(0.30),
          Colors.transparent,
          primary.withOpacity(0.08),
        ],
      ).createShader(rect)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final leftPath = Path()
      ..moveTo(0, r)
      ..lineTo(0, size.height - r);
    canvas.drawPath(leftPath, leftPaint);

    final rightPath = Path()
      ..moveTo(size.width, r)
      ..lineTo(size.width, size.height - r);
    canvas.drawPath(rightPath, leftPaint);

    // ── 3. Reflet prismatique bas (arc-en-ciel très subtil) ────────────────
    const prismaColors = [
      Color(0x0CFF6B6B), // rouge
      Color(0x0CFFAA00), // orange
      Color(0x0C00C8FF), // bleu
      Color(0x0CB97EF8), // violet
    ];
    final prismPaint = Paint()
      ..shader = LinearGradient(colors: prismaColors)
          .createShader(Rect.fromLTWH(0, size.height * 0.7, size.width, size.height * 0.3))
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final prismPath = Path()
      ..moveTo(r, size.height)
      ..lineTo(size.width - r, size.height);
    canvas.drawPath(prismPath, prismPaint);
  }

  @override
  bool shouldRepaint(_LiquidGlassPainter old) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
// _ActivePill — indicateur de l'onglet actif (glass sur glass)
// ══════════════════════════════════════════════════════════════════════════════
class _ActivePill extends StatelessWidget {
  final double width;
  final double height;
  final Color primary;

  const _ActivePill({
    required this.width,
    required this.height,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            // glass-over-glass : plus blanc que le fond de la pilule
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.38),
                Colors.white.withOpacity(0.14),
                primary.withOpacity(0.30),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.55),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.45),
                blurRadius: 18,
                offset: const Offset(0, 6),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.14),
                blurRadius: 4,
                offset: const Offset(0, -1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _NavItem — item de navbar avec spring bounce + Iconly icons
// ══════════════════════════════════════════════════════════════════════════════
class _NavItem extends StatefulWidget {
  final NavBarItem item;
  final bool isSelected;
  final Color primary;
  final double height;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.primary,
    required this.height,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _scaleAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(vsync: this);
    _scaleAnim = AlwaysStoppedAnimation(1.0);
  }

  @override
  void didUpdateWidget(_NavItem old) {
    super.didUpdateWidget(old);
    if (!old.isSelected && widget.isSelected) {
      // Spring bounce quand l'item devient actif
      final spring = SpringDescription(mass: 1.0, stiffness: 500, damping: 18);
      final sim = SpringSimulation(spring, 0.0, 1.0, 8.0); // vitesse initiale
      _bounceController.animateWith(sim);
      _scaleAnim = Tween<double>(begin: 1.25, end: 1.0)
          .animate(_bounceController);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) {
          HapticFeedback.lightImpact();
          setState(() => _isPressed = true);
        },
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onTap();
        },
        behavior: HitTestBehavior.translucent,
        child: SizedBox(
          height: widget.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _bounceController,
                builder: (ctx, child) {
                  final springScale = _bounceController.isAnimating
                      ? _scaleAnim.value
                      : widget.isSelected ? 1.18 : 1.0;
                  final pressScale = _isPressed ? 0.88 : 1.0;
                  return Transform.scale(
                    scale: springScale * pressScale,
                    child: child,
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ── Icon Iconly ──────────────────────────────────────
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: anim,
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: Icon(
                        widget.isSelected
                            ? widget.item.activeIcon
                            : widget.item.icon,
                        key: ValueKey(widget.isSelected),
                        color: widget.isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.55),
                        size: widget.item.iconSize,
                        shadows: widget.isSelected
                            ? [
                                Shadow(
                                  color: widget.primary.withOpacity(0.8),
                                  blurRadius: 14,
                                ),
                                Shadow(
                                  color: Colors.white.withOpacity(0.6),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : [
                                Shadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                      ),
                    ),
                    // Badge
                    if (widget.item.badgeCount > 0)
                      Positioned(
                        right: -9,
                        top: -7,
                        child: _AnimatedBadge(count: widget.item.badgeCount),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              // Label (visible seulement si actif)
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.poppins(
                  fontSize: widget.isSelected ? 10.0 : 9.0,
                  fontWeight: widget.isSelected
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: widget.isSelected
                      ? Colors.white
                      : Colors.transparent,
                  letterSpacing: 0.3,
                  shadows: widget.isSelected
                      ? [
                          Shadow(
                            color: widget.primary.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ]
                      : [],
                ),
                child: Text(widget.item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _AnimatedBadge — badge notification avec spring pop
// ══════════════════════════════════════════════════════════════════════════════
class _AnimatedBadge extends StatelessWidget {
  final int count;
  const _AnimatedBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : count.toString();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (ctx, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF4B4B), Color(0xFFFF2266)],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4B4B).withOpacity(0.55),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// NavBarItem — données d'un item de navbar
// ══════════════════════════════════════════════════════════════════════════════
class NavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final double iconSize;
  final int badgeCount;

  const NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.iconSize = 24.0,
    this.badgeCount = 0,
  });

  NavBarItem copyWith({int? badgeCount}) => NavBarItem(
        icon: icon,
        activeIcon: activeIcon,
        label: label,
        iconSize: iconSize,
        badgeCount: badgeCount ?? this.badgeCount,
      );
}

/// Alias pour compatibilité ascendante.
class BlobNavBar extends FloatingModernNavBar {
  const BlobNavBar({
    super.key,
    required super.currentIndex,
    required super.onTap,
    required super.items,
    super.primaryColor,
  });
}
