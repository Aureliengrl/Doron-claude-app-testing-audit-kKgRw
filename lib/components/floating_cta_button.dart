import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FloatingCtaButton extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback onTap;
  final Widget? child; // Optionnel : remplace le contenu interne
  final int badgeCount;

  const FloatingCtaButton({
    Key? key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.onTap,
    this.child,
    this.badgeCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget buttonContent = child ?? Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, color: Colors.white, size: subtitle != null ? 28 : 22),
          const SizedBox(width: 8),
        ],
        if (subtitle != null)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          )
        else
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
      ],
    );

    Widget pill = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8A2BE2), Color(0xFFEC4899)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8A2BE2).withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: buttonContent,
        ),
      ),
    );

    if (badgeCount > 0) {
      pill = Badge(
        label: Text(badgeCount.toString()),
        offset: const Offset(-5, -5),
        child: pill,
      );
    }

    return Positioned(
      bottom: 90,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A0030).withOpacity(0),
              const Color(0xFF1A0030).withOpacity(0.92),
              const Color(0xFF1A0030),
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: pill,
      ),
    );
  }
}
