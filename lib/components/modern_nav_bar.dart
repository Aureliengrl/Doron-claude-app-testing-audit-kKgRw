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
//   • Onglet ACTIF   : pilule intérieure + icon + label côte à côte
//   • Onglet INACTIF : icône seule, parfaitement centrée verticalement
//   • Spring physics (SpringSimulation) sur tap
//   • AnimatedSize pour l'expansion du label
//   • Haptic mediumImpact sur changement d'onglet
//   • Blur 60 + specular gradient + border prismatique
// ══════════════════════════════════════════════════════════════════════════════

class FloatingModernNavBar extends StatelessWidget {
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
    this.height = 64,
    this.borderRadius = 32,
    this.margin = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? LiquidGlassTokens.primary;
    final leftItems = items.length > 1 ? items.sublist(0, items.length - 1) : items;
    final rightItem = items.length > 1 ? items.last : null;
    final rightIndex = items.length - 1;

    return Padding(
      padding: margin,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Pilule principale ──────────────────────────────────────────
          Expanded(
            child: _GlassPill(
              height: height,
              borderRadius: borderRadius,
              primary: primary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(
                  leftItems.length,
                  (i) => _NavItem(
                    item: leftItems[i],
                    isSelected: currentIndex == i,
                    primary: primary,
                    onTap: () => onTap(i),
                  ),
                ),
              ),
            ),
          ),

          // ── Bouton circulaire profil ───────────────────────────────────
          if (rightItem != null) ...[
            const SizedBox(width: 12),
            _CircleNavItem(
              item: rightItem,
              isSelected: currentIndex == rightIndex,
              primary: primary,
              size: height,
              onTap: () => onTap(rightIndex),
            ),
          ],
        ],
      )
          .animate()
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.6, end: 0, duration: 550.ms, curve: Curves.easeOutCubic),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _GlassPill — conteneur verre avec specular + border prismatique
// ══════════════════════════════════════════════════════════════════════════════
class _GlassPill extends StatelessWidget {
  final Widget child;
  final double height;
  final double borderRadius;
  final Color primary;

  const _GlassPill({
    required this.child,
    required this.height,
    required this.borderRadius,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.30),
            blurRadius: 40,
            offset: const Offset(0, 14),
            spreadRadius: -6,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.36),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: CustomPaint(
            painter: _GlassPainter(borderRadius: borderRadius, primary: primary),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.20),
                    Colors.white.withOpacity(0.05),
                    Colors.white.withOpacity(0.10),
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
// _GlassPainter — specular top + border prismatique + bords latéraux
// ══════════════════════════════════════════════════════════════════════════════
class _GlassPainter extends CustomPainter {
  final double borderRadius;
  final Color primary;
  const _GlassPainter({required this.borderRadius, required this.primary});

  @override
  void paint(Canvas canvas, Size size) {
    final r = borderRadius;

    // Specular top strip
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.44),
        topLeft: Radius.circular(r),
        topRight: Radius.circular(r),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withOpacity(0.28), Colors.white.withOpacity(0)],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.44)),
    );

    // Top border — blanc
    canvas.drawPath(
      Path()
        ..moveTo(r, 0)
        ..lineTo(size.width - r, 0),
      Paint()
        ..color = Colors.white.withOpacity(0.60)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Bottom border — prismatique
    canvas.drawPath(
      Path()
        ..moveTo(r, size.height)
        ..lineTo(size.width - r, size.height),
      Paint()
        ..shader = LinearGradient(colors: const [
          Color(0x0CFF6B6B),
          Color(0x1200C8FF),
          Color(0x14B97EF8),
          Color(0x1200C8FF),
          Color(0x0CFF6B6B),
        ]).createShader(Rect.fromLTWH(0, size.height - 2, size.width, 2))
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    // Bords latéraux
    final sidePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primary.withOpacity(0.28),
          Colors.transparent,
          primary.withOpacity(0.08),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    canvas.drawPath(Path()..moveTo(0, r)..lineTo(0, size.height - r), sidePaint);
    canvas.drawPath(Path()..moveTo(size.width, r)..lineTo(size.width, size.height - r), sidePaint);
  }

  @override
  bool shouldRepaint(_GlassPainter old) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
// _NavItem — item gauche : active = pilule (icon + label), inactif = icon seule
// ══════════════════════════════════════════════════════════════════════════════
class _NavItem extends StatefulWidget {
  final NavBarItem item;
  final bool isSelected;
  final Color primary;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.primary,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _bounceCtrl;
  late Animation<double> _scaleAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(vsync: this, duration: 600.ms);
  }

  @override
  void didUpdateWidget(_NavItem old) {
    super.didUpdateWidget(old);
    if (!old.isSelected && widget.isSelected) {
      _bounceCtrl.forward(from: 0.0);
      _scaleAnim = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.28), weight: 15),
        TweenSequenceItem(tween: Tween(begin: 1.28, end: 0.95), weight: 25),
        TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.12), weight: 30),
        TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 30),
      ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOut));
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _pressed = true);
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      behavior: HitTestBehavior.translucent,
      child: AnimatedScale(
        scale: _pressed ? 0.90 : 1.0,
        duration: 100.ms,
        child: AnimatedContainer(
          duration: 320.ms,
          curve: const Cubic(0.34, 1.56, 0.64, 1),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isSelected ? 14.0 : 10.0,
            vertical: 10.0,
          ),
          decoration: widget.isSelected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.26),
                      Colors.white.withOpacity(0.10),
                      widget.primary.withOpacity(0.22),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.primary.withOpacity(0.40),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                      spreadRadius: -3,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.12),
                      blurRadius: 0,
                      offset: const Offset(0, -1),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.42),
                    width: 0.8,
                  ),
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Icône ────────────────────────────────────────────────
              AnimatedBuilder(
                animation: _bounceCtrl,
                builder: (ctx, child) {
                  final s = _bounceCtrl.isAnimating ? _scaleAnim.value : 1.0;
                  return Transform.scale(scale: s, child: child);
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedSwitcher(
                      duration: 160.ms,
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
                            : Colors.white.withOpacity(0.52),
                        size: widget.item.iconSize,
                        shadows: widget.isSelected
                            ? [
                                Shadow(
                                  color: widget.primary.withOpacity(0.75),
                                  blurRadius: 12,
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
                    if (widget.item.badgeCount > 0)
                      Positioned(
                        right: -9,
                        top: -7,
                        child: _Badge(count: widget.item.badgeCount),
                      ),
                  ],
                ),
              ),

              // ── Label animé (apparaît quand actif) ───────────────────
              AnimatedSize(
                duration: 320.ms,
                curve: const Cubic(0.34, 1.2, 0.64, 1),
                child: widget.isSelected
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 7),
                          AnimatedOpacity(
                            opacity: widget.isSelected ? 1.0 : 0.0,
                            duration: 220.ms,
                            child: Text(
                              widget.item.label,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.15,
                                shadows: [
                                  Shadow(
                                    color: widget.primary.withOpacity(0.45),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _CircleNavItem — bouton circulaire (profil)
// ══════════════════════════════════════════════════════════════════════════════
class _CircleNavItem extends StatefulWidget {
  final NavBarItem item;
  final bool isSelected;
  final Color primary;
  final double size;
  final VoidCallback onTap;

  const _CircleNavItem({
    required this.item,
    required this.isSelected,
    required this.primary,
    required this.size,
    required this.onTap,
  });

  @override
  State<_CircleNavItem> createState() => _CircleNavItemState();
}

class _CircleNavItemState extends State<_CircleNavItem>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.size / 2;
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _pressed = true);
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.90 : 1.0,
        duration: 100.ms,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.primary.withOpacity(0.30),
                blurRadius: 40,
                offset: const Offset(0, 14),
                spreadRadius: -6,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.36),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: AnimatedContainer(
                duration: 300.ms,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.isSelected
                        ? [
                            widget.primary.withOpacity(0.60),
                            widget.primary.withOpacity(0.35),
                            const Color(0xFFEC4899).withOpacity(0.28),
                          ]
                        : [
                            Colors.white.withOpacity(0.20),
                            Colors.white.withOpacity(0.05),
                            Colors.white.withOpacity(0.10),
                          ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                  boxShadow: widget.isSelected
                      ? [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.25),
                            blurRadius: 0,
                            offset: const Offset(0, -1),
                          ),
                        ]
                      : null,
                  border: Border.all(
                    color: widget.isSelected
                        ? Colors.white.withOpacity(0.45)
                        : Colors.white.withOpacity(0.52),
                    width: widget.isSelected ? 0.8 : 1.0,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedSwitcher(
                          duration: 160.ms,
                          child: Icon(
                            widget.isSelected
                                ? widget.item.activeIcon
                                : widget.item.icon,
                            key: ValueKey(widget.isSelected),
                            color: widget.isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.52),
                            size: widget.item.iconSize,
                            shadows: widget.isSelected
                                ? [
                                    Shadow(
                                      color: widget.primary.withOpacity(0.8),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : [],
                          ),
                        ),
                        if (widget.item.badgeCount > 0)
                          Positioned(
                            right: -9,
                            top: -7,
                            child: _Badge(count: widget.item.badgeCount),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    AnimatedDefaultTextStyle(
                      duration: 200.ms,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: widget.isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: widget.isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.50),
                      ),
                      child: Text(widget.item.label),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _Badge — indicateur de notification
// ══════════════════════════════════════════════════════════════════════════════
class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : count.toString();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: 400.ms,
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF4B4B), Color(0xFFFF2266)],
          ),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.black.withOpacity(0.85), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4B4B).withOpacity(0.55),
              blurRadius: 7,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// NavBarItem — données d'un onglet
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
    this.iconSize = 22.0,
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
