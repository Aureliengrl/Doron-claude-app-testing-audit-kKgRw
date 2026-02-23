import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bouton avec effet bounce premium et haptic feedback
class BounceButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool enabled;
  final double? elevation;
  final List<BoxShadow>? boxShadow;
  final Border? border;

  const BounceButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
    this.enabled = true,
    this.elevation,
    this.boxShadow,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled && onPressed != null
          ? () {
              HapticFeedback.mediumImpact();
              onPressed!();
            }
          : null,
      child: Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: enabled
              ? (backgroundColor ?? const Color(0xFF8A2BE2))
              : Colors.grey[300],
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          border: border,
          boxShadow: enabled
              ? (boxShadow ??
                  [
                    BoxShadow(
                      color: (backgroundColor ?? const Color(0xFF8A2BE2))
                          .withOpacity(0.3),
                      blurRadius: elevation ?? 12,
                      offset: const Offset(0, 6),
                    ),
                  ])
              : null,
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            color: enabled
                ? (foregroundColor ?? Colors.white)
                : Colors.grey[600],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Icon Button avec effet bounce
class BounceIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final Color? backgroundColor;
  final double? padding;

  const BounceIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.size = 24,
    this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed != null
          ? () {
              HapticFeedback.lightImpact();
              onPressed!();
            }
          : null,
      child: Container(
        padding: EdgeInsets.all(padding ?? 12),
        decoration: backgroundColor != null
            ? BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: backgroundColor!.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              )
            : null,
        child: Icon(
          icon,
          size: size,
          color: color,
        ),
      ),
    );
  }
}

/// Carte avec effet bounce au tap
class BounceCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? color;
  final List<BoxShadow>? boxShadow;

  const BounceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.borderRadius,
    this.color,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap!();
            }
          : null,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          boxShadow: boxShadow ??
              [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
        ),
        child: child,
      ),
    );
  }
}
