import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

/// Configuration pour IconlyPro
/// Étape 1: Glissez le fichier 'IconlyPro.ttf' dans assets/fonts/
/// Étape 2: Remplissez ces codes hexadécimaux selon la documentation de la police.
/// Si vous avez téléchargé des SVG ou PNG à la place, utilisez le dossier assets/3d_icons/
class IconlyPro {
  IconlyPro._();

  static const String _fontFamily = 'IconlyPro';

  // --- ICÔNES LIGHT ---
  static const IconData homeLight = IconData(0xe900, fontFamily: _fontFamily, fallback: Icons.home_outlined);
  static const IconData searchLight = IconData(0xe901, fontFamily: _fontFamily, fallback: Icons.search_outlined);
  static const IconData playLight = IconData(0xe902, fontFamily: _fontFamily, fallback: Icons.play_arrow_outlined);
  static const IconData profileLight = IconData(0xe903, fontFamily: _fontFamily, fallback: Icons.person_outline_rounded);
  static const IconData heartLight = IconData(0xe904, fontFamily: _fontFamily, fallback: Icons.favorite_border_rounded);
  static const IconData sendLight = IconData(0xe905, fontFamily: _fontFamily, fallback: Icons.send_outlined);

  // --- ICÔNES BOLD (Pour onglets actifs ou favoris) ---
  static const IconData homeBold = IconData(0xe906, fontFamily: _fontFamily, fallback: Icons.home_rounded);
  static const IconData searchBold = IconData(0xe907, fontFamily: _fontFamily, fallback: Icons.search_rounded);
  static const IconData playBold = IconData(0xe908, fontFamily: _fontFamily, fallback: Icons.play_arrow_rounded);
  static const IconData profileBold = IconData(0xe909, fontFamily: _fontFamily, fallback: Icons.person_rounded);
  static const IconData heartBold = IconData(0xe90a, fontFamily: _fontFamily, fallback: Icons.favorite_rounded);
  static const IconData sendBold = IconData(0xe90b, fontFamily: _fontFamily, fallback: Icons.send_rounded);
}
