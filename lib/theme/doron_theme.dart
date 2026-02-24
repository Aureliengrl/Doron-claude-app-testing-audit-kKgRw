import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Thème officiel DORÕN — Material 3 Design System.
///
/// Utilisation dans main.dart :
/// ```dart
/// MaterialApp(
///   theme: DoronTheme.light,
///   darkTheme: DoronTheme.dark,
///   themeMode: ThemeMode.system,
/// )
/// ```
class DoronTheme {
  DoronTheme._();

  // ---------------------------------------------------------------------------
  // Palette de couleurs
  // ---------------------------------------------------------------------------

  /// Bleu marine profond — couleur principale des pages fondamentales
  static const Color navy = Color(0xFF062248);

  /// Rose vibrant — accent et call-to-action
  static const Color rose = Color(0xFFFF6B9D);

  /// Rose foncé — états actif/hover
  static const Color roseDark = Color(0xFFC74375);

  /// Violet — assistant vocal
  static const Color violet = Color(0xFF8A2BE2);

  /// Fond clair — pages de contenu
  static const Color surfaceLight = Color(0xFFF5F5F5);

  /// Fond carte — cartes produits
  static const Color cardWhite = Colors.white;

  // ---------------------------------------------------------------------------
  // ColorScheme — Material 3
  // ---------------------------------------------------------------------------

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: rose,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFFFD6E7),
    onPrimaryContainer: Color(0xFF8B0040),
    secondary: navy,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFD1E4FF),
    onSecondaryContainer: Color(0xFF001D36),
    tertiary: violet,
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFE8D5FF),
    onTertiaryContainer: Color(0xFF3D0080),
    error: Color(0xFFB3261E),
    onError: Colors.white,
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    background: surfaceLight,
    onBackground: Color(0xFF1C1B1F),
    surface: cardWhite,
    onSurface: Color(0xFF1C1B1F),
    surfaceVariant: Color(0xFFF3F3F3),
    onSurfaceVariant: Color(0xFF49454F),
    outline: Color(0xFF79747E),
    outlineVariant: Color(0xFFCAC4D0),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFF313033),
    onInverseSurface: Color(0xFFF4EFF4),
    inversePrimary: Color(0xFFFFB1CE),
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFFB1CE),
    onPrimary: Color(0xFF650040),
    primaryContainer: Color(0xFF8B0040),
    onPrimaryContainer: Color(0xFFFFD6E7),
    secondary: Color(0xFF9ECAFF),
    onSecondary: Color(0xFF003258),
    secondaryContainer: Color(0xFF00497D),
    onSecondaryContainer: Color(0xFFD1E4FF),
    tertiary: Color(0xFFD0B8FF),
    onTertiary: Color(0xFF3D0080),
    tertiaryContainer: Color(0xFF5800B4),
    onTertiaryContainer: Color(0xFFE8D5FF),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),
    background: Color(0xFF10131A),
    onBackground: Color(0xFFE6E1E5),
    surface: Color(0xFF1A1D26),
    onSurface: Color(0xFFE6E1E5),
    surfaceVariant: Color(0xFF1F2230),
    onSurfaceVariant: Color(0xFFCAC4D0),
    outline: Color(0xFF938F99),
    outlineVariant: Color(0xFF49454F),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFE6E1E5),
    onInverseSurface: Color(0xFF313033),
    inversePrimary: rose,
  );

  // ---------------------------------------------------------------------------
  // Typographie Outfit (famille utilisée dans l'app)
  // ---------------------------------------------------------------------------

  static TextTheme get _textTheme => GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400),
          displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400),
          displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400),
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      );

  // ---------------------------------------------------------------------------
  // Thèmes Material 3
  // ---------------------------------------------------------------------------

  /// Thème clair (mode par défaut)
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: _lightColorScheme,
        textTheme: _textTheme,
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: rose,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: const CardThemeData(
          color: cardWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF3F3F3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: rose, width: 2),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.selected) ? rose : null,
          ),
          trackColor: MaterialStateProperty.resolveWith(
            (states) => states.contains(MaterialState.selected)
                ? rose.withOpacity(0.5)
                : null,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: rose,
          foregroundColor: Colors.white,
        ),
        chipTheme: ChipThemeData(
          selectedColor: rose.withOpacity(0.15),
          labelStyle: const TextStyle(color: navy),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      );

  /// Thème sombre (dark mode)
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: _darkColorScheme,
        textTheme: _textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: _darkColorScheme.surface,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: rose,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: _darkColorScheme.surface,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: rose,
          foregroundColor: Colors.white,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      );
}
