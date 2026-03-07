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
    
    // Scinder les items en deux groupes (gauche = principaux, droite = profil)
    final leftItems = widget.items.length > 1 ? widget.items.sublist(0, widget.items.length - 1) : widget.items;
    final rightItem = widget.items.length > 1 ? widget.items.last : null;
    final rightIndex = widget.items.length - 1;

    // Calcul de la largeur des items à gauche
    final spacing = 16.0;
    final rightWidth = rightItem != null ? widget.height : 0.0;
    final leftNavWidth = screenWidth - widget.margin.horizontal - spacing - rightWidth;
    final leftItemWidth = leftNavWidth / leftItems.length;

    // Styles de base de Liquid Glass
    final glassGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.18),
        Colors.white.withOpacity(0.08),
        Colors.white.withOpacity(0.12),
      ],
    );
    final glassBorder = Border.all(
      color: Colors.white.withOpacity(0.25),
      width: 1.0,
    );
    final glassShadows = [
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
    ];

    return Padding(
      padding: widget.margin,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ==================== [ GAUCHE ] PILULE PRINCIPALE ====================
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: glassShadows,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
                  child: CustomPaint(
                    painter: _NavBarSpecularPainter(
                      borderRadius: widget.borderRadius,
                    ),
                    child: Container(
                      height: widget.height,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        gradient: glassGradient,
                        border: glassBorder,
                      ),
                      child: Stack(
                        children: [
                          // Pill indicateur animé (Masqué si index sélectionné est à droite)
                          AnimatedOpacity(
                            opacity: widget.currentIndex < leftItems.length ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: AnimatedBuilder(
                              animation: _pillController,
                              builder: (context, _) {
                                final curved = CurvedAnimation(
                                  parent: _pillController,
                                  curve: Curves.easeOutCubic,
                                );
                                
                                // Calculer la position seulement pour les index de gauche
                                final safePrevIndex = _previousIndex < leftItems.length ? _previousIndex : (leftItems.length - 1);
                                final safeCurrIndex = widget.currentIndex < leftItems.length ? widget.currentIndex : safePrevIndex;

                                final pos = Tween<double>(
                                  begin: safePrevIndex * leftItemWidth,
                                  end: safeCurrIndex * leftItemWidth,
                                ).animate(curved).value;

                                return Positioned(
                                  left: pos + (leftItemWidth - 56) / 2,
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
                          ),

                          // Items de gauche
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: List.generate(
                              leftItems.length,
                              (i) => _buildNavItem(leftItems[i], i, primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Espacement
          if (rightItem != null) SizedBox(width: spacing),

          // ==================== [ DROITE ] BOUTON CIRCULAIRE ====================
          if (rightItem != null)
            Container(
              width: widget.height,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.height / 2),
                boxShadow: glassShadows,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.height / 2),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
                  child: CustomPaint(
                    painter: _NavBarSpecularPainter(
                      borderRadius: widget.height / 2,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.height / 2),
                        gradient: glassGradient,
                        border: glassBorder,
                      ),
                      child: Stack(
                        children: [
                          // Fond lumineux actif
                          AnimatedOpacity(
                            opacity: widget.currentIndex == rightIndex ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(widget.height / 2),
                                gradient: RadialGradient(
                                  colors: [
                                    primary.withOpacity(0.6),
                                    Colors.transparent,
                                  ],
                                  radius: 0.8,
                                ),
                              ),
                            ),
                          ),
                          
                          // L'item cliquable (passe l'index global)
                          Row(
                            children: [
                              _buildNavItem(rightItem, rightIndex, primary),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ).animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.6, end: 0, duration: 550.ms, curve: Curves.easeOutCubic),
    );
  }

  Widget _buildNavItem(NavBarItem item, int index, Color primary) {
    final isSelected = widget.currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => HapticFeedback.lightImpact(),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap(index);
        },
        behavior: HitTestBehavior.translucent,
        child: SizedBox(
          height: widget.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 350),
                curve: Curves.elasticOut,
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.55),
                  size: item.iconSize,
                  shadows: [
                    if (!isSelected)
                      Shadow(
                        offset: const Offset(0, 1),
                        blurRadius: 2.0,
                        color: Colors.black.withOpacity(0.8),
                      )
                    else
                      Shadow(
                        offset: const Offset(0, 2),
                        blurRadius: 8.0,
                        color: const Color(0xFF8A2BE2).withOpacity(0.5),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  item.label,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
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
