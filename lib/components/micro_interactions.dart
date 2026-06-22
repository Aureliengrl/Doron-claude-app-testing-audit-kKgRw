import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Wrapper qui ajoute un effet de tap avec scale et haptic feedback
class TapScaleEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleValue;
  final Duration duration;
  final bool enableHaptic;

  const TapScaleEffect({
    super.key,
    required this.child,
    this.onTap,
    this.scaleValue = 0.95,
    this.duration = const Duration(milliseconds: 100),
    this.enableHaptic = true,
  });

  @override
  State<TapScaleEffect> createState() => _TapScaleEffectState();
}

class _TapScaleEffectState extends State<TapScaleEffect> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null) {
          setState(() => _isPressed = true);
          if (widget.enableHaptic) {
            HapticFeedback.lightImpact();
          }
        }
      },
      onTapUp: (_) {
        if (widget.onTap != null) {
          setState(() => _isPressed = false);
          widget.onTap!();
        }
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleValue : 1.0,
        duration: widget.duration,
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}

/// Animation d'apparition avec fade + slide from bottom
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int delay;
  final Duration duration;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = 0,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: delay),
          duration: duration,
          curve: Curves.easeOut,
        )
        .slideY(
          begin: 0.3,
          end: 0,
          delay: Duration(milliseconds: delay),
          duration: duration,
          curve: Curves.easeOutCubic,
        );
  }
}

/// Effet de bounce lors de l'apparition
class BounceIn extends StatelessWidget {
  final Widget child;
  final int delay;

  const BounceIn({
    super.key,
    required this.child,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay))
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          delay: Duration(milliseconds: delay),
          duration: 500.ms,
          curve: Curves.elasticOut,
        );
  }
}

/// Effet shimmer/brillance continu
class ShimmerEffect extends StatelessWidget {
  final Widget child;
  final Color shimmerColor;
  final Duration duration;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.shimmerColor = Colors.white,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  Widget build(BuildContext context) {
    return child.animate(onPlay: (controller) => controller.repeat())
      .shimmer(
        duration: duration,
        color: shimmerColor.withOpacity(0.3),
      );
  }
}

/// Pulse effect - Parfait pour attirer l'attention
class PulseEffect extends StatelessWidget {
  final Widget child;
  final double maxScale;
  final Duration duration;

  const PulseEffect({
    super.key,
    required this.child,
    this.maxScale = 1.05,
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  Widget build(BuildContext context) {
    return child.animate(onPlay: (controller) => controller.repeat(reverse: true))
      .scale(
        begin: const Offset(1.0, 1.0),
        end: Offset(maxScale, maxScale),
        duration: duration,
        curve: Curves.easeInOut,
      );
  }
}

/// Rotation subtle pour effet dynamique
class FloatingRotation extends StatelessWidget {
  final Widget child;
  final double angle;
  final Duration duration;

  const FloatingRotation({
    super.key,
    required this.child,
    this.angle = 0.02, // 2 degrés
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  Widget build(BuildContext context) {
    return child.animate(onPlay: (controller) => controller.repeat(reverse: true))
      .rotate(
        begin: -angle,
        end: angle,
        duration: duration,
        curve: Curves.easeInOut,
      );
  }
}

/// Effet de glow/lueur autour d'un widget
class GlowEffect extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double blurRadius;
  final double spreadRadius;

  const GlowEffect({
    super.key,
    required this.child,
    required this.glowColor,
    this.blurRadius = 20,
    this.spreadRadius = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.6),
            blurRadius: blurRadius,
            spreadRadius: spreadRadius,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Card avec effet de levitation au hover/press
class LevitatingCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const LevitatingCard({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<LevitatingCard> createState() => _LevitatingCardState();
}

class _LevitatingCardState extends State<LevitatingCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(
            0,
            _isHovered ? -8 : 0,
            0,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isHovered ? 0.15 : 0.08),
                  blurRadius: _isHovered ? 24 : 16,
                  offset: Offset(0, _isHovered ? 12 : 4),
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Badge de notification animé
class AnimatedNotificationBadge extends StatelessWidget {
  final int count;
  final Color backgroundColor;
  final double size;

  const AnimatedNotificationBadge({
    super.key,
    required this.count,
    this.backgroundColor = Colors.red,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat())
      .scale(
        begin: const Offset(1.0, 1.0),
        end: const Offset(1.1, 1.1),
        duration: 1000.ms,
        curve: Curves.easeInOut,
      )
      .then()
      .scale(
        begin: const Offset(1.1, 1.1),
        end: const Offset(1.0, 1.0),
        duration: 1000.ms,
        curve: Curves.easeInOut,
      );
  }
}

/// Stagger children animations - Anime les enfants séquentiellement
class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final int staggerDelay; // Délai entre chaque enfant en ms

  const StaggeredList({
    super.key,
    required this.children,
    this.staggerDelay = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;

        return FadeSlideIn(
          delay: index * staggerDelay,
          child: child,
        );
      }).toList(),
    );
  }
}

/// Loading shimmer effect pour skeleton screens
class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    ).animate(onPlay: (controller) => controller.repeat())
      .shimmer(
        duration: 1500.ms,
        color: Colors.white.withOpacity(0.5),
      );
  }
}

/// Success checkmark animation
class SuccessCheckmark extends StatelessWidget {
  final double size;
  final Color color;

  const SuccessCheckmark({
    super.key,
    this.size = 60,
    this.color = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Icon(
        Icons.check,
        color: Colors.white,
        size: size * 0.6,
      ),
    ).animate()
      .scale(
        begin: const Offset(0, 0),
        end: const Offset(1, 1),
        duration: 400.ms,
        curve: Curves.elasticOut,
      )
      .then()
      .shimmer(duration: 500.ms, color: Colors.white.withOpacity(0.5));
  }
}
