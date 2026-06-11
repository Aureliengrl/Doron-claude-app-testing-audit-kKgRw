import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

/// Configuration pour IconlyPro
/// Étape 1: Glissez le fichier 'IconlyPro.ttf' dans assets/fonts/
/// Étape 2: Remplissez ces codes hexadécimaux selon la documentation de la police.
/// Si vous avez téléchargé des SVG ou PNG à la place, utilisez le dossier assets/3d_icons/
class IconlyPro {
  IconlyPro._();

  // --- ICÔNES LIGHT ---
  static const IconData homeLight = CupertinoIcons.house;
  static const IconData searchLight = CupertinoIcons.search;
  static const IconData playLight = Icons.play_arrow_outlined;
  static const IconData profileLight = CupertinoIcons.person;
  static const IconData heartLight = CupertinoIcons.heart;
  static const IconData sendLight = CupertinoIcons.paperplane;
  static const IconData chatLight = CupertinoIcons.chat_bubble;

  // --- ICÔNES BOLD (Pour onglets actifs ou favoris) ---
  static const IconData homeBold = CupertinoIcons.house_fill;
  static const IconData searchBold = CupertinoIcons.search;
  static const IconData playBold = Icons.play_arrow_rounded;
  static const IconData profileBold = CupertinoIcons.person_fill;
  static const IconData heartBold = CupertinoIcons.heart_fill;
  static const IconData sendBold = CupertinoIcons.paperplane_fill;
  static const IconData chatBold = CupertinoIcons.chat_bubble_fill;
}
