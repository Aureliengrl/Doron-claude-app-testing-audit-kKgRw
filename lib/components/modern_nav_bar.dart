import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Apple Store-style iOS tab bar with frosted glass background.
class FloatingModernNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavBarItem> items;
  final Color? primaryColor;
  // Kept for API compat — ignored in the new design.
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
  Widget build(BuildContext context) {
    final primary = primaryColor ?? const Color(0xFF8A2BE2);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final unselectedColor = Colors.white.withOpacity(0.45);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.30),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.15),
                width: 0.33,
              ),
            ),
          ),
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 6),
            child: Row(
              children: List.generate(items.length, (i) {
                final item = items[i];
                final selected = currentIndex == i;
                return Expanded(
                  child: _IOSTabItem(
                    item: item,
                    isSelected: selected,
                    primaryColor: primary,
                    unselectedColor: unselectedColor,
                    onTap: () => onTap(i),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _IOSTabItem extends StatelessWidget {
  final NavBarItem item;
  final bool isSelected;
  final Color primaryColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  const _IOSTabItem({
    required this.item,
    required this.isSelected,
    required this.primaryColor,
    required this.unselectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? primaryColor : unselectedColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon with optional badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                isSelected ? item.activeIcon : item.icon,
                color: color,
                size: item.iconSize,
              ),
              if (item.badgeCount > 0)
                Positioned(
                  right: -8,
                  top: -4,
                  child: _AnimatedBadge(count: item.badgeCount),
                ),
            ],
          ),
          const SizedBox(height: 2),
          // Label — always visible
          Text(
            item.label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: color,
              height: 1.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Animated badge for notification indicators on nav items.
class _AnimatedBadge extends StatelessWidget {
  final int count;
  const _AnimatedBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : count.toString();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
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

/// Nav bar item model.
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

  /// Returns a copy with updated badge count.
  NavBarItem copyWith({int? badgeCount}) {
    return NavBarItem(
      icon: icon,
      activeIcon: activeIcon,
      label: label,
      iconSize: iconSize,
      badgeCount: badgeCount ?? this.badgeCount,
    );
  }
}

/// Alias kept for backward compatibility.
class BlobNavBar extends FloatingModernNavBar {
  const BlobNavBar({
    super.key,
    required super.currentIndex,
    required super.onTap,
    required super.items,
    super.primaryColor,
  });
}
