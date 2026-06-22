import 'package:shared_preferences/shared_preferences.dart';

/// Service pour détecter la première utilisation de l'app
class FirstTimeService {
  static const String _keyFirstTime = 'isFirstTime';
  static const String _keyCompletedOnboarding = 'completedOnboarding';

  /// Vérifie si c'est la première fois que l'utilisateur lance l'app
  static Future<bool> isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFirstTime) ?? true;
  }

  /// Marque l'app comme "déjà utilisée"
  static Future<void> setNotFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstTime, false);
  }

  /// Vérifie si l'onboarding a été complété
  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyCompletedOnboarding) ?? false;
  }

  /// Marque l'onboarding comme complété
  static Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCompletedOnboarding, true);
    await setNotFirstTime();
  }

  /// Réinitialise (pour tests)
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFirstTime);
    await prefs.remove(_keyCompletedOnboarding);
  }
}
