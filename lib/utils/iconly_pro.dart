import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

/// Configuration pour IconlyPro
/// Étape 1: Glissez le fichier 'IconlyPro.ttf' dans assets/fonts/
/// Étape 2: Remplissez ces codes hexadécimaux selon la documentation de la police.
/// Si vous avez téléchargé des SVG ou PNG à la place, utilisez le dossier assets/3d_icons/
class IconlyPro {
  IconlyPro._();

  // --- ICÔNES LIGHT ---
  static const IconData homeLight = Icons.home_outlined;
  static const IconData searchLight = Icons.search_outlined;
  static const IconData playLight = Icons.play_arrow_outlined;
  static const IconData profileLight = Icons.person_outline_rounded;
  static const IconData heartLight = Icons.favorite_border_rounded;
  static const IconData sendLight = Icons.send_outlined;
  static const IconData chatLight = Icons.chat_bubble_outline_rounded;

  // --- ICÔNES BOLD (Pour onglets actifs ou favoris) ---
  static const IconData homeBold = Icons.home_rounded;
  static const IconData searchBold = Icons.search_rounded;
  static const IconData playBold = Icons.play_arrow_rounded;
  static const IconData profileBold = Icons.person_rounded;
  static const IconData heartBold = Icons.favorite_rounded;
  static const IconData sendBold = Icons.send_rounded;
  static const IconData chatBold = Icons.chat_bubble_rounded;
}
