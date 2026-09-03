import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '/components/liquid_glass.dart';

// ══════════════════════════════════════════════════════════════════════════════
// FloatingModernNavBar — Liquid Glass iOS 26 + Apple Store style
//
//   Design :
//   • Barre FLOTTANTE arrondie, fond glass translucide (BackdropFilter blur)
//   • Bloc transparent (capsule) qui GLISSE entre les onglets (Apple Store)
//   • L'onglet actif a son icône blanche éclatante à l'intérieur de la capsule
//   • Les onglets inactifs ont des icônes semi-transparentes
//   • Animation spring physique naturelle pour le switch
//   • Haptic feedback à chaque onglet traversé
//
//   Interactions :
//   • Tap → spring snap avec la capsule qui glisse
//   • Horizontal drag → scrubbing en temps réel (la capsule suit le doigt)
//   • Double tap sur onglet actif → scroll to top (optionnel)
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
    this.margin = const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 2),
  });

  @override
  State<FloatingModernNavBar> createState() => _FloatingModernNavBarState();
}

class _FloatingModernNavBarState extends State<FloatingModernNavBar>
    with TickerProviderStateMixin {

  // ── Spring animation for indicator sliding ─────────────────────────────
  late AnimationController _springCtrl;
  late Animation<double> _springAnim;
  double _indicatorPos = 0.0; // current float tab index position

  // ── Scrub state ────────────────────────────────────────────────────────
  bool _isScrubbing = false;
  double _dragStartX = 0;
  double _scrubStart = 0;
  int _lastHapticTab = 0;


  @override
  void initState() {
    super.initState();
    _indicatorPos = widget.currentIndex.toDouble();

    _springCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );


  }

  @override
  void didUpdateWidget(FloatingModernNavBar old) {
    super.didUpdateWidget(old);
    if (!_isScrubbing && old.currentIndex != widget.currentIndex) {
      _animateTo(widget.currentIndex.toDouble());
    }
  }

  @override
  void dispose() {
    _springCtrl.dispose();
    super.dispose();
  }

  int get _count => widget.items.length;

  // ── Spring animation ──────────────────────────────────────────────────
  void _animateTo(double target) {
    final from = _indicatorPos;
    _springAnim = Tween<double>(begin: from, end: target).animate(
      CurvedAnimation(parent: _springCtrl, curve: _LiquidSpring()),
    );
    _springAnim.addListener(() {
      if (mounted) setState(() => _indicatorPos = _springAnim.value);
    });
    _springCtrl.forward(from: 0.0);
  }

  // ── Drag/scrub ────────────────────────────────────────────────────────
  void _onDragStart(DragStartDetails d) {
    _isScrubbing = true;
    _dragStartX = d.localPosition.dx;
    _scrubStart = _indicatorPos;
    _lastHapticTab = _indicatorPos.round();
    _springCtrl.stop();
    HapticFeedback.lightImpact();
  }

  void _onDragUpdate(DragUpdateDetails d, double barW) {
    if (!_isScrubbing) return;
    final tabW = barW / _count;
    final delta = (d.localPosition.dx - _dragStartX) / tabW;
    final p = (_scrubStart + delta).clamp(-0.12, _count - 0.88);
    setState(() => _indicatorPos = p);

    final nearest = p.round().clamp(0, _count - 1);
    if (nearest != _lastHapticTab) {
      HapticFeedback.selectionClick();
      _lastHapticTab = nearest;
      widget.onTabScrub?.call(nearest);
    }
  }

  void _onDragEnd(DragEndDetails d) {
    if (!_isScrubbing) return;
    _isScrubbing = false;
    final target = _indicatorPos.round().clamp(0, _count - 1).toDouble();
    _animateTo(target);
    HapticFeedback.mediumImpact();
    widget.onTap(target.toInt());
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primaryColor ?? LiquidGlassTokens.primary;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: widget.margin.left,
        right: widget.margin.right,
        bottom: bottomPad + widget.margin.bottom,
      ),
      child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              // Main shadow
              BoxShadow(
                color: Colors.black.withOpacity(0.32),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
              // Color glow
              BoxShadow(
                color: primary.withOpacity(0.10),
                blurRadius: 36,
                offset: const Offset(0, 12),
                spreadRadius: -8,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: CustomPaint(
                painter: _GlassBarPainter(
                  borderRadius: widget.borderRadius,
                  primary: primary,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.13),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.20),
                      width: 0.7,
                    ),
                  ),
                  child: LayoutBuilder(builder: (ctx, constraints) {
                    final barW = constraints.maxWidth;
                    return GestureDetector(
                      onHorizontalDragStart: _onDragStart,
                      onHorizontalDragUpdate: (d) => _onDragUpdate(d, barW),
                      onHorizontalDragEnd: _onDragEnd,
                      behavior: HitTestBehavior.opaque,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // ─── TRANSPARENT SLIDING BLOCK (Apple Store style) ───
                          _buildSlidingBlock(barW, primary),

                          // ─── TAB ITEMS ──────────────────────────────────────
                          Row(
                            children: List.generate(_count, (i) {
                              final dist = (_indicatorPos - i).abs();
                              final isActive = dist < 0.45;
                              return Expanded(
                                child: _TabItem(
                                  item: widget.items[i],
                                  isActive: isActive,
                                  primary: primary,
                                  height: widget.height,
                                  onTap: () {
                                    _animateTo(i.toDouble());
                                    HapticFeedback.mediumImpact();
                                    widget.onTap(i);
                                  },
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms, delay: 80.ms)
        .slideY(begin: 0.5, end: 0, duration: 480.ms, delay: 40.ms, curve: Curves.easeOutCubic);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SLIDING TRANSPARENT BLOCK — Apple Store style capsule
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildSlidingBlock(double barW, Color primary) {
    final tabW = barW / _count;
    final blockW = tabW - 10;

    // Calculate morphing stretch when between tabs
    final lower = _indicatorPos.floor().clamp(0, _count - 1);
    final frac = _indicatorPos - lower;
    final stretch = math.sin(frac * math.pi); // 0→1→0 between tabs
    final extraW = stretch * tabW * 0.22;
    final finalW = blockW + extraW;

    final centerX = (_indicatorPos * tabW) + tabW / 2;
    final left = (centerX - finalW / 2).clamp(5.0, barW - finalW - 5.0);

    final vertPad = 8.0;
    final blockH = widget.height - vertPad * 2;

    return AnimatedPositioned(
      duration: _isScrubbing ? Duration.zero : const Duration(milliseconds: 1),
      left: left,
      top: vertPad,
      child: Container(
        width: finalW.clamp(32.0, barW - 10),
        height: blockH,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(blockH / 2),
          // ── The transparent glass block ──
          color: Colors.white.withOpacity(0.13),
          border: Border.all(
            color: Colors.white.withOpacity(0.25),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 2),
              spreadRadius: -2,
            ),
          ],
        ),
        // Inner specular highlight
        child: ClipRRect(
          borderRadius: BorderRadius.circular(blockH / 2),
          child: CustomPaint(
            painter: _BlockSpecularPainter(borderRadius: blockH / 2),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _LiquidSpring — courbe spring iOS-like
// ══════════════════════════════════════════════════════════════════════════════
class _LiquidSpring extends Curve {
  @override
  double transformInternal(double t) {
    const c1 = 1.70158;
    const c3 = c1 + 1;
    return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _GlassBarPainter — specular highlights on the main bar
// ══════════════════════════════════════════════════════════════════════════════
class _GlassBarPainter extends CustomPainter {
  final double borderRadius;
  final Color primary;
  const _GlassBarPainter({required this.borderRadius, required this.primary});

  @override
  void paint(Canvas canvas, Size size) {
    final r = borderRadius;

    // Top specular shine
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.40),
        topLeft: Radius.circular(r),
        topRight: Radius.circular(r),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.16),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.40)),
    );

    // Top edge highlight
    final topEdge = Path()
      ..moveTo(r + 10, 0.5)
      ..lineTo(size.width - r - 10, 0.5);
    canvas.drawPath(
      topEdge,
      Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..strokeWidth = 0.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Bottom iridescent edge (liquid glass signature)
    final bottomEdge = Path()
      ..moveTo(r + 16, size.height - 0.5)
      ..lineTo(size.width - r - 16, size.height - 0.5);
    canvas.drawPath(
      bottomEdge,
      Paint()
        ..shader = LinearGradient(
          colors: [
            primary.withOpacity(0.0),
            primary.withOpacity(0.18),
            const Color(0xFFEC4899).withOpacity(0.14),
            const Color(0xFF00D4FF).withOpacity(0.10),
            primary.withOpacity(0.0),
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        ).createShader(Rect.fromLTWH(0, size.height - 2, size.width, 2))
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_GlassBarPainter old) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
// _BlockSpecularPainter — inner shine on the sliding block
// ══════════════════════════════════════════════════════════════════════════════
class _BlockSpecularPainter extends CustomPainter {
  final double borderRadius;
  const _BlockSpecularPainter({required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    // Top half specular
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.45),
        topLeft: Radius.circular(borderRadius),
        topRight: Radius.circular(borderRadius),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.45)),
    );
  }

  @override
  bool shouldRepaint(_BlockSpecularPainter old) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
// _TabItem — individual tab icon
// ══════════════════════════════════════════════════════════════════════════════
class _TabItem extends StatefulWidget {
  final NavBarItem item;
  final bool isActive;
  final Color primary;
  final double height;
  final VoidCallback onTap;

  const _TabItem({
    required this.item,
    required this.isActive,
    required this.primary,
    required this.height,
    required this.onTap,
  });

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive
        ? Colors.white
        : Colors.white.withOpacity(0.42);

    final shadows = widget.isActive
        ? [Shadow(color: widget.primary.withOpacity(0.65), blurRadius: 16)]
        : <Shadow>[];

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.translucent,
      child: AnimatedScale(
        scale: _pressed ? 0.85 : 1.0,
        duration: 80.ms,
        curve: Curves.easeInOut,
        child: SizedBox(
          height: widget.height,
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: 200.ms,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: widget.item.lottieAsset != null
                      ? Lottie.asset(
                          widget.item.lottieAsset!,
                          key: ValueKey('lottie_${widget.isActive}_${widget.item.label}'),
                          width: widget.item.iconSize + 6,
                          height: widget.item.iconSize + 6,
                          animate: widget.isActive,
                          repeat: false,
                        )
                      : Icon(
                          widget.isActive
                              ? widget.item.activeIcon
                              : widget.item.icon,
                          key: ValueKey('icon_${widget.isActive}_${widget.item.label}'),
                          color: color,
                          size: widget.item.iconSize,
                          shadows: shadows,
                        ),
                ),
                // Badge
                if (widget.item.badgeCount > 0)
                  Positioned(
                    right: -10,
                    top: -8,
                    child: _Badge(count: widget.item.badgeCount),
                  ),
              ],
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
          gradient: const LinearGradient(
            colors: [Color(0xFFFF4B4B), Color(0xFFFF2266)],
          ),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: const Color(0xFF0A0014).withOpacity(0.9),
            width: 1.5,
          ),
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
// NavBarItem
// ══════════════════════════════════════════════════════════════════════════════
class NavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String? tooltip;
  final double iconSize;
  final int badgeCount;
  final String? lottieAsset;

  const NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.tooltip,
    this.iconSize = 22.0,
    this.badgeCount = 0,
    this.lottieAsset,
  });

  NavBarItem copyWith({int? badgeCount}) => NavBarItem(
        icon: icon,
        activeIcon: activeIcon,
        label: label,
        tooltip: tooltip,
        iconSize: iconSize,
        badgeCount: badgeCount ?? this.badgeCount,
        lottieAsset: lottieAsset,
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
