import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'liquid_glass.dart';

/// Bouton canonique de la refonte premium.
///
/// Deux styles seulement :
///   - [GlassButton] (primaire) : dégradé violet→rose, texte blanc.
///   - [GlassButton.ghost]      : verre translucide + liseré.
///
/// Ressort au tap (scale 0.96) + haptique léger. À utiliser PARTOUT à la place
/// des `ElevatedButton`/`Container`+`InkWell` custom, pour un rendu homogène.
class GlassButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool ghost;
  final bool expand; // pleine largeur
  final bool loading;
  final double height;

  const GlassButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.expand = true,
    this.loading = false,
    this.height = 54,
  }) : ghost = false;

  const GlassButton.ghost({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.expand = true,
    this.loading = false,
    this.height = 54,
  }) : ghost = true;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _pressed = false;

  bool get _enabled => widget.onTap != null && !widget.loading;

  void _setPressed(bool v) {
    if (!_enabled) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.height / 2);

    final Widget inner = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        else ...[
          if (widget.icon != null) ...[
            Icon(widget.icon,
                size: 19,
                color: widget.ghost ? Colors.white : Colors.white),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
                color: widget.ghost
                    ? Colors.white.withOpacity(0.92)
                    : Colors.white,
              ),
            ),
          ),
        ],
      ],
    );

    Widget body = AnimatedContainer(
      duration: LiquidGlassTokens.durFast,
      curve: LiquidGlassTokens.easePremium,
      height: widget.height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: widget.ghost ? null : LiquidGlassTokens.signatureGradient,
        color: widget.ghost ? Colors.white.withOpacity(0.08) : null,
        border: Border.all(
          color: Colors.white.withOpacity(widget.ghost ? 0.22 : 0.28),
          width: 1,
        ),
        boxShadow: widget.ghost
            ? null
            : [
                BoxShadow(
                  color: LiquidGlassTokens.primary.withOpacity(0.42),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                  spreadRadius: -6,
                ),
              ],
      ),
      child: inner,
    );

    // Le verre (ghost) est flouté; le primaire n'en a pas besoin.
    if (widget.ghost) {
      body = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: body,
        ),
      );
    }

    return Opacity(
      opacity: _enabled ? 1 : 0.5,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: _enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onTap!();
              }
            : null,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: LiquidGlassTokens.durFast,
          curve: LiquidGlassTokens.easePremium,
          child: widget.expand ? SizedBox(width: double.infinity, child: body) : body,
        ),
      ),
    );
  }
}
