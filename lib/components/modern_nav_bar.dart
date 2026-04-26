import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/components/liquid_glass.dart';

// ══════════════════════════════════════════════════════════════════════════════
// FloatingModernNavBar — Liquid Glass iOS 26
//
//   Design :
//   • Onglet ACTIF   : mini-pilule glass (icon + label côte à côte)
//   • Onglet INACTIF : icône seule, parfaitement centrée
//   • Bouton PROFIL  : cercle glass séparé à droite
//
//   Interactions :
//   • Tap normal → spring snap vers l'onglet
//   • Long press + glisser → Tab Scrubbing en temps réel
//     - La pilule indicatrice suit le doigt et s'étire (morphing liquide)
//     - Les pages défilent en sync via onTabScrub callback
//     - Au relâchement : spring snap vers l'onglet le plus proche
//   • Haptic lightImpact par onglet traversé pendant le scrub
//   • Haptic mediumImpact au snap final
// ══════════════════════════════════════════════════════════════════════════════

class FloatingModernNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Function(int)? onTabScrub;
  final List<NavBarItem> items;
  final Color? primaryColor;
  final double height;
  final double borderRadius;
  final EdgeInsets margin;

  const FloatingModernNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onTabScrub,
    required this.items,
    this.primaryColor,
    this.height = 64,
    this.borderRadius = 32,
    this.margin = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  });

  @override
  State<FloatingModernNavBar> createState() => _FloatingModernNavBarState();
}

class _FloatingModernNavBarState extends State<FloatingModernNavBar>
    with TickerProviderStateMixin {

  // ── Scrubbing state ──────────────────────────────────────────────────────
  double _scrubProgress = 0.0; // 0.0 … leftItems.length (float tab index)
  bool _isScrubbing = false;
  double _dragStartX = 0;
  double _scrubStartProgress = 0;
  int _lastHapticTab = 0;

  // ── Spring animation ─────────────────────────────────────────────────────
  late AnimationController _springCtrl;
  late Animation<double> _springAnim;

  @override
  void initState() {
    super.initState();
    _scrubProgress = widget.currentIndex.toDouble().clamp(0.0, _leftCount - 1.0);
    _springCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _springCtrl.addListener(() {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(FloatingModernNavBar old) {
    super.didUpdateWidget(old);
    if (!_isScrubbing && old.currentIndex != widget.currentIndex) {
      final target = widget.currentIndex.clamp(0, _leftCount - 1).toDouble();
      _animateSpringTo(target);
    }
  }

  @override
  void dispose() {
    _springCtrl.dispose();
    super.dispose();
  }

  int get _leftCount => widget.items.length > 1 ? widget.items.length - 1 : widget.items.length;

  void _animateSpringTo(double target) {
    final start = _scrubProgress;
    _springAnim = Tween<double>(begin: start, end: target).animate(
      CurvedAnimation(parent: _springCtrl, curve: _SpringOutCurve()),
    );
    _springCtrl.forward(from: 0.0);
    _springCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _scrubProgress = target);
      }
    });
    _springAnim.addListener(() {
      setState(() => _scrubProgress = _springAnim.value);
    });
  }

  // ── Drag handlers ─────────────────────────────────────────────────────────
  void _onDragStart(DragStartDetails d) {
    _isScrubbing = true;
    _dragStartX = d.localPosition.dx;
    _scrubStartProgress = _scrubProgress;
    _lastHapticTab = _scrubProgress.round();
    _springCtrl.stop();
    HapticFeedback.lightImpact();
  }

  void _onDragUpdate(DragUpdateDetails d, double pillWidth) {
    if (!_isScrubbing) return;
    final tabW = pillWidth / _leftCount;
    final delta = (d.localPosition.dx - _dragStartX) / tabW;
    final newProgress = (_scrubStartProgress + delta).clamp(-0.15, _leftCount - 0.85);
    setState(() => _scrubProgress = newProgress);

    // Haptic par onglet traversé
    final nearestTab = newProgress.round().clamp(0, _leftCount - 1);
    if (nearestTab != _lastHapticTab) {
      HapticFeedback.lightImpact();
      _lastHapticTab = nearestTab;
      widget.onTabScrub?.call(nearestTab);
    }
  }

  void _onDragEnd(DragEndDetails d) {
    if (!_isScrubbing) return;
    _isScrubbing = false;
    final target = _scrubProgress.round().clamp(0, _leftCount - 1).toDouble();
    _animateSpringTo(target);
    HapticFeedback.mediumImpact();
    widget.onTap(target.round());
  }

  // ── Indicateur : position + largeur selon le scrub progress ──────────────
  _PillGeometry _computeIndicator(double pillWidth) {
    final tabW = pillWidth / _leftCount;
    final lower = _scrubProgress.floor().clamp(0, _leftCount - 1);
    final upper = (_scrubProgress.ceil()).clamp(0, _leftCount - 1);
    final frac = _scrubProgress - lower;

    // Centre de chaque slot
    final cL = lower * tabW + tabW / 2;
    final cU = upper * tabW + tabW / 2;

    const baseW = 90.0;
    if (lower == upper || frac.abs() < 0.005) {
      return _PillGeometry(left: cL - baseW / 2, width: baseW);
    }

    // Morphing liquide : étirement entre deux onglets
    final stretch = math.sin(frac * math.pi); // 0 → 1 → 0
    final leftEdge  = cL - baseW / 2;
    final rightEdge = cU + baseW / 2;
    final stretchW  = (rightEdge - leftEdge) * stretch + baseW * (1 - stretch);
    final center    = cL + (cU - cL) * frac;
    return _PillGeometry(left: center - stretchW / 2, width: stretchW);
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Pilule principale avec gesture scrubbing ───────────────────
          Expanded(
            child: _GlassPill(
              height: widget.height,
              borderRadius: widget.borderRadius,
              primary: primary,
              child: LayoutBuilder(builder: (ctx, constraints) {
                final pillW = constraints.maxWidth;
                final geo = _computeIndicator(pillW);

                return GestureDetector(
                  onHorizontalDragStart: _onDragStart,
                  onHorizontalDragUpdate: (d) => _onDragUpdate(d, pillW),
                  onHorizontalDragEnd: _onDragEnd,
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    children: [
                      // ── Indicateur glissant / morphing ─────────────
                      AnimatedPositioned(
                        duration: _isScrubbing ? Duration.zero : const Duration(milliseconds: 1),
                        left: geo.left.clamp(6.0, pillW - geo.width - 6.0),
                        top: (widget.height - 44) / 2,
                        child: _ActivePillIndicator(
                          width: geo.width.clamp(44.0, pillW - 12.0),
                          height: 44,
                          primary: primary,
                        ),
                      ),

                      // ── Items ────────────────────────────────────────
                      Row(
                        children: List.generate(
                          leftItems.length,
                          (i) {
                            final dist = (_scrubProgress - i).abs();
                            final isActive = dist < 0.45;
                            return _NavItem(
                              item: leftItems[i],
                              isSelected: isActive,
                              primary: primary,
                              height: widget.height,
                              onTap: () {
                                _animateSpringTo(i.toDouble());
                                HapticFeedback.mediumImpact();
                                widget.onTap(i);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),

          // ── Bouton circulaire profil ──────────────────────────────────
          if (rightItem != null) ...[
            const SizedBox(width: 12),
            _CircleNavItem(
              item: rightItem,
              isSelected: widget.currentIndex == rightIndex,
              primary: primary,
              size: widget.height,
              onTap: () => widget.onTap(rightIndex),
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

// Courbe spring custom
class _SpringOutCurve extends Curve {
  @override
  double transformInternal(double t) {
    // easeOutBack springy
    const c1 = 1.70158, c3 = c1 + 1;
    return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2);
  }
}

class _PillGeometry {
  final double left;
  final double width;
  const _PillGeometry({required this.left, required this.width});
}

// ══════════════════════════════════════════════════════════════════════════════
// _GlassPill
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
          BoxShadow(color: primary.withOpacity(0.28), blurRadius: 40, offset: const Offset(0, 14), spreadRadius: -6),
          BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 6)),
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

class _GlassPainter extends CustomPainter {
  final double borderRadius;
  final Color primary;
  const _GlassPainter({required this.borderRadius, required this.primary});

  @override
  void paint(Canvas canvas, Size size) {
    final r = borderRadius;
    canvas.drawRRect(
      RRect.fromRectAndCorners(Rect.fromLTWH(0, 0, size.width, size.height * 0.44),
          topLeft: Radius.circular(r), topRight: Radius.circular(r)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.white.withOpacity(0.26), Colors.white.withOpacity(0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.44)),
    );
    canvas.drawPath(
      Path()..moveTo(r, 0)..lineTo(size.width - r, 0),
      Paint()..color = Colors.white.withOpacity(0.58)..strokeWidth = 1.0..style = PaintingStyle.stroke..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      Path()..moveTo(r, size.height)..lineTo(size.width - r, size.height),
      Paint()
        ..shader = const LinearGradient(colors: [Color(0x0CFF6B6B), Color(0x1200C8FF), Color(0x14B97EF8), Color(0x1200C8FF), Color(0x0CFF6B6B)])
            .createShader(Rect.fromLTWH(0, size.height - 2, size.width, 2))
        ..strokeWidth = 1.5..style = PaintingStyle.stroke,
    );
    final sidePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [primary.withOpacity(0.26), Colors.transparent, primary.withOpacity(0.08)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 0.8..style = PaintingStyle.stroke;
    canvas.drawPath(Path()..moveTo(0, r)..lineTo(0, size.height - r), sidePaint);
    canvas.drawPath(Path()..moveTo(size.width, r)..lineTo(size.width, size.height - r), sidePaint);
  }

  @override
  bool shouldRepaint(_GlassPainter old) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
// _ActivePillIndicator — pilule interne qui glisse et morphe
// ══════════════════════════════════════════════════════════════════════════════
class _ActivePillIndicator extends StatelessWidget {
  final double width;
  final double height;
  final Color primary;

  const _ActivePillIndicator({required this.width, required this.height, required this.primary});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.28),
                Colors.white.withOpacity(0.10),
                primary.withOpacity(0.24),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
            boxShadow: [
              BoxShadow(color: primary.withOpacity(0.42), blurRadius: 14, offset: const Offset(0, 5), spreadRadius: -3),
              BoxShadow(color: Colors.white.withOpacity(0.12), blurRadius: 0, offset: const Offset(0, -1)),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.42), width: 0.8),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _NavItem
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

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        behavior: HitTestBehavior.translucent,
        child: AnimatedScale(
          scale: _pressed ? 0.90 : 1.0,
          duration: 100.ms,
          child: SizedBox(
            height: widget.height,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedSwitcher(
                        duration: 160.ms,
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: Icon(
                          widget.isSelected ? widget.item.activeIcon : widget.item.icon,
                          key: ValueKey(widget.isSelected),
                          color: widget.isSelected ? Colors.white : Colors.white.withOpacity(0.52),
                          size: widget.item.iconSize,
                          shadows: widget.isSelected
                              ? [Shadow(color: widget.primary.withOpacity(0.75), blurRadius: 12)]
                              : [Shadow(color: Colors.black.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 1))],
                        ),
                      ),
                      if (widget.item.badgeCount > 0)
                        Positioned(
                          right: -9, top: -7,
                          child: _Badge(count: widget.item.badgeCount),
                        ),
                    ],
                  ),
                  // Label animé
                  AnimatedSize(
                    duration: 300.ms,
                    curve: const Cubic(0.34, 1.2, 0.64, 1),
                    child: widget.isSelected
                        ? Row(mainAxisSize: MainAxisSize.min, children: [
                            const SizedBox(width: 7),
                            AnimatedOpacity(
                              opacity: 1.0,
                              duration: 200.ms,
                              child: Text(
                                widget.item.label,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.15,
                                  shadows: [Shadow(color: widget.primary.withOpacity(0.45), blurRadius: 8)],
                                ),
                              ),
                            ),
                          ])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _CircleNavItem — bouton circulaire profil
// ══════════════════════════════════════════════════════════════════════════════
class _CircleNavItem extends StatefulWidget {
  final NavBarItem item;
  final bool isSelected;
  final Color primary;
  final double size;
  final VoidCallback onTap;

  const _CircleNavItem({
    required this.item, required this.isSelected,
    required this.primary, required this.size, required this.onTap,
  });

  @override
  State<_CircleNavItem> createState() => _CircleNavItemState();
}

class _CircleNavItemState extends State<_CircleNavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { HapticFeedback.lightImpact(); setState(() => _pressed = true); },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () { HapticFeedback.mediumImpact(); widget.onTap(); },
      child: AnimatedScale(
        scale: _pressed ? 0.90 : 1.0,
        duration: 100.ms,
        child: Container(
          width: widget.size, height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: widget.primary.withOpacity(0.28), blurRadius: 40, offset: const Offset(0, 14), spreadRadius: -6),
              BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 6)),
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
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: widget.isSelected
                        ? [widget.primary.withOpacity(0.60), widget.primary.withOpacity(0.35), const Color(0xFFEC4899).withOpacity(0.28)]
                        : [Colors.white.withOpacity(0.20), Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.10)],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                  border: Border.all(
                    color: widget.isSelected ? Colors.white.withOpacity(0.45) : Colors.white.withOpacity(0.52),
                    width: widget.isSelected ? 0.8 : 1.0,
                  ),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Stack(clipBehavior: Clip.none, children: [
                    AnimatedSwitcher(
                      duration: 160.ms,
                      child: Icon(
                        widget.isSelected ? widget.item.activeIcon : widget.item.icon,
                        key: ValueKey(widget.isSelected),
                        color: widget.isSelected ? Colors.white : Colors.white.withOpacity(0.52),
                        size: widget.item.iconSize,
                        shadows: widget.isSelected
                            ? [Shadow(color: widget.primary.withOpacity(0.8), blurRadius: 12)]
                            : [],
                      ),
                    ),
                    if (widget.item.badgeCount > 0)
                      Positioned(right: -9, top: -7, child: _Badge(count: widget.item.badgeCount)),
                  ]),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: 200.ms,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: widget.isSelected ? Colors.white : Colors.white.withOpacity(0.50),
                    ),
                    child: Text(widget.item.label),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _Badge
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
          gradient: const LinearGradient(colors: [Color(0xFFFF4B4B), Color(0xFFFF2266)]),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.black.withOpacity(0.85), width: 1.5),
          boxShadow: [BoxShadow(color: const Color(0xFFFF4B4B).withOpacity(0.55), blurRadius: 7, offset: const Offset(0, 2))],
        ),
        child: Text(label,
          style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
          textAlign: TextAlign.center),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// NavBarItem
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
        icon: icon, activeIcon: activeIcon, label: label,
        iconSize: iconSize, badgeCount: badgeCount ?? this.badgeCount,
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
