import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/components/liquid_glass.dart';

/// Navbar flottante Liquid Glass style iOS 26.
/// Fond blur profond + specular highlight + pill indicateur lumineux.
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
    with SingleTickerProviderStateMixin {
  late AnimationController _pillController;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _pillController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _previousIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(FloatingModernNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _pillController.forward(from: 0);
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
    final screenWidth = MediaQuery.of(context).size.width;
    final navWidth = screenWidth - widget.margin.horizontal;
    final itemWidth = navWidth / widget.items.length;

    return Padding(
      padding: widget.margin,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.30),
              blurRadius: 40,
              offset: const Offset(0, 16),
              spreadRadius: -8,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.30),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
            child: CustomPaint(
              painter: _NavBarSpecularPainter(
                borderRadius: widget.borderRadius,
              ),
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  // Liquid Glass surface — très légèrement blanc
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.07),
                      Colors.white.withOpacity(0.12),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.22),
                    width: 1.0,
                  ),
                ),
                child: Stack(
                  children: [
                    // Pill indicateur animé
                    AnimatedBuilder(
                      animation: _pillController,
                      builder: (context, _) {
                        final curved = CurvedAnimation(
                          parent: _pillController,
                          curve: Curves.easeOutCubic,
                        );
                        final pos = Tween<double>(
                          begin: _previousIndex * itemWidth,
                          end: widget.currentIndex * itemWidth,
                        ).animate(curved).value;

                        return Positioned(
                          left: pos + (itemWidth - 56) / 2,
                          top: (widget.height - 48) / 2,
                          child: Container(
                            width: 56,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  primary.withOpacity(0.75),
                                  primary.withOpacity(0.50),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.35),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withOpacity(0.50),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Items
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(
                        widget.items.length,
                        (i) => _buildNavItem(widget.items[i], i, primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ).animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.6, end: 0, duration: 550.ms, curve: Curves.easeOutCubic),
    );
  }

  Widget _buildNavItem(NavBarItem item, int index, Color primary) {
    final isSelected = widget.currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap(index);
        },
        behavior: HitTestBehavior.translucent,
        child: SizedBox(
          height: widget.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.45),
                  size: item.iconSize,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  item.label,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// CustomPainter pour le specular highlight sur le bord supérieur de la navbar.
class _NavBarSpecularPainter extends CustomPainter {
  final double borderRadius;
  const _NavBarSpecularPainter({required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    // Specular gradient en haut
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.35),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.5));

    final path = Path()
      ..addRRect(RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.5),
        topLeft: Radius.circular(borderRadius),
        topRight: Radius.circular(borderRadius),
      ));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_NavBarSpecularPainter oldDelegate) => false;
}

/// Item de navbar
class NavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final double iconSize;

  const NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.iconSize = 22.0,
  });
}

/// Alias pour compatibilité — conservé pour ne pas casser le code existant.
class BlobNavBar extends FloatingModernNavBar {
  const BlobNavBar({
    super.key,
    required super.currentIndex,
    required super.onTap,
    required super.items,
    super.primaryColor,
  });
}
