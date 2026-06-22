import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bouton avec effet bounce premium et haptic feedback
class BounceButton extends StatefulWidget {
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
  State<BounceButton> createState() => _BounceButtonState();
}

class _BounceButtonState extends State<BounceButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.enabled && widget.onPressed != null) {
      HapticFeedback.lightImpact();
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enabled && widget.onPressed != null) {
      setState(() => _isPressed = false);
      widget.onPressed!();
    }
  }

  void _handleTapCancel() {
    if (widget.enabled && widget.onPressed != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuart,
        child: Container(
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: widget.enabled
                ? (widget.backgroundColor ?? const Color(0xFF8A2BE2))
                : Colors.grey[300],
            borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
            border: widget.border,
            boxShadow: widget.enabled
                ? (widget.boxShadow ??
                    [
                      BoxShadow(
                        color: (widget.backgroundColor ?? const Color(0xFF8A2BE2))
                            .withOpacity(0.3),
                        blurRadius: widget.elevation ?? 12,
                        offset: const Offset(0, 6),
                      ),
                    ])
                : null,
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: widget.enabled
                  ? (widget.foregroundColor ?? Colors.white)
                  : Colors.grey[600],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Icon Button avec effet bounce
class BounceIconButton extends StatefulWidget {
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
  State<BounceIconButton> createState() => _BounceIconButtonState();
}

class _BounceIconButtonState extends State<BounceIconButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      HapticFeedback.lightImpact();
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = false);
      widget.onPressed!();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuart,
        child: Container(
          padding: EdgeInsets.all(widget.padding ?? 12),
          decoration: widget.backgroundColor != null
              ? BoxDecoration(
                  color: widget.backgroundColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.backgroundColor!.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                )
              : null,
          child: Icon(
            widget.icon,
            size: widget.size,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

/// Carte avec effet bounce au tap (Premium Scaling effect)
class BounceCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? color;
  final List<BoxShadow>? boxShadow;
  final Decoration? decoration;

  const BounceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.borderRadius,
    this.color,
    this.boxShadow,
    this.decoration,
  });

  @override
  State<BounceCard> createState() => _BounceCardState();
}

class _BounceCardState extends State<BounceCard> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      HapticFeedback.lightImpact();
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
      widget.onTap!();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutQuart,
        child: Container(
          padding: widget.padding,
          decoration: widget.decoration ?? BoxDecoration(
            color: widget.color ?? Colors.white,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
            boxShadow: widget.boxShadow ??
                [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

