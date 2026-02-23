import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui' as ui;

/// Navbar flottante moderne style App Store avec glassmorphism et animations liquid
class FloatingModernNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavBarItem> items;
  final Color? primaryColor;
  final Color? backgroundColor;
  final double height;
  final double borderRadius;
  final EdgeInsets margin;

  const FloatingModernNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.primaryColor,
    this.backgroundColor,
    this.height = 70,
    this.borderRadius = 35,
    this.margin = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  });

  @override
  State<FloatingModernNavBar> createState() => _FloatingModernNavBarState();
}

class _FloatingModernNavBarState extends State<FloatingModernNavBar> with SingleTickerProviderStateMixin {
  late AnimationController _liquidController;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _liquidController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _previousIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(FloatingModernNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _liquidController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _liquidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? const Color(0xFF8A2BE2);
    final bgColor = widget.backgroundColor ?? Colors.white;

    return Padding(
      padding: widget.margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: bgColor.withOpacity(0.85),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Liquid background indicator
                AnimatedBuilder(
                  animation: _liquidController,
                  builder: (context, child) {
                    return _buildLiquidIndicator(primaryColor);
                  },
                ),

                // Nav items
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    widget.items.length,
                    (index) => _buildNavItem(
                      widget.items[index],
                      index,
                      primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.5, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),
    );
  }

  Widget _buildLiquidIndicator(Color primaryColor) {
    final itemWidth = MediaQuery.of(context).size.width / widget.items.length;
    final targetPosition = widget.currentIndex * itemWidth;
    final startPosition = _previousIndex * itemWidth;

    final curvedAnimation = CurvedAnimation(
      parent: _liquidController,
      curve: Curves.easeInOutCubic,
    );

    final currentPosition = Tween<double>(
      begin: startPosition,
      end: targetPosition,
    ).animate(curvedAnimation).value;

    return Positioned(
      left: currentPosition - widget.margin.left + (itemWidth / 2) - 30,
      top: (widget.height - 60) / 2,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              primaryColor.withOpacity(0.3),
              primaryColor.withOpacity(0.15),
              primaryColor.withOpacity(0.05),
            ],
          ),
          shape: BoxShape.circle,
        ),
      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.1, 1.1),
          duration: 1500.ms,
          curve: Curves.easeInOut,
        ),
    );
  }

  Widget _buildNavItem(NavBarItem item, int index, Color primaryColor) {
    final isSelected = widget.currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onTap(index);
        },
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.all(isSelected ? 12 : 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            primaryColor.withOpacity(0.2),
                            primaryColor.withOpacity(0.1),
                          ],
                        )
                      : null,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: primaryColor.withOpacity(0.3),
                          width: 2,
                        )
                      : null,
                ),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected ? primaryColor : const Color(0xFF9E9E9E),
                  size: item.iconSize,
                ),
              ).animate(target: isSelected ? 1 : 0)
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.15, 1.15),
                  duration: 300.ms,
                  curve: Curves.easeOutBack,
                ),

              const SizedBox(height: 4),

              // Label avec animation
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.label,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ).animate(target: isSelected ? 1 : 0)
                  .fadeIn(duration: 200.ms)
                  .slideY(begin: 0.3, end: 0, duration: 300.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Item de la navbar
class NavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final double iconSize;

  const NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.iconSize = 24.0,
  });
}

/// Version alternative avec effet "blob" morphing
class BlobNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavBarItem> items;
  final Color? primaryColor;

  const BlobNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.primaryColor,
  });

  @override
  State<BlobNavBar> createState() => _BlobNavBarState();
}

class _BlobNavBarState extends State<BlobNavBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(BlobNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? const Color(0xFF8A2BE2);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, 15),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          widget.items.length,
          (index) {
            final isSelected = widget.currentIndex == index;
            final item = widget.items[index];

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  widget.onTap(index);
                },
                behavior: HitTestBehavior.translucent,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [primaryColor, primaryColor.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    isSelected ? item.activeIcon : item.icon,
                    color: isSelected ? Colors.white : const Color(0xFF9E9E9E),
                    size: item.iconSize,
                  ),
                ).animate(target: isSelected ? 1 : 0)
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.1, 1.1),
                    duration: 300.ms,
                    curve: Curves.elasticOut,
                  )
                  .shimmer(
                    duration: 1000.ms,
                    color: Colors.white.withOpacity(0.3),
                  ),
              ),
            );
          },
        ),
      ),
    ).animate()
      .fadeIn(duration: 400.ms)
      .slideY(begin: 0.5, end: 0, duration: 600.ms, curve: Curves.easeOutCubic);
  }
}
