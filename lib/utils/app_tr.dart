import 'package:flutter/material.dart';
import '/flutter_flow/internationalization.dart';

/// Extension de traduction instantanée sur BuildContext.
/// Usage : context.tr('Français', 'English')
///
/// Réactif : se met à jour automatiquement quand setAppLanguage() est appelé
/// car MaterialApp rebuild via MyApp.setLocale().
///
/// Les données produit (noms, prix, marques) venant de Firestore
/// ne doivent JAMAIS passer par cette extension — elles restent en français.
extension AppTr on BuildContext {
  /// Retourne [en] si la langue courante est l'anglais, sinon [fr].
  String tr(String fr, String en) {
    try {
      final lang = FFLocalizations.of(this).languageCode;
      return lang == 'en' ? en : fr;
    } catch (_) {
      return fr; // Fallback sûr si les localisations ne sont pas encore disponibles
    }
  }

  /// Raccourci pour savoir si l'app est en anglais.
  bool get isEn {
    try {
      return FFLocalizations.of(this).languageCode == 'en';
    } catch (_) {
      return false;
    }
  }
}
