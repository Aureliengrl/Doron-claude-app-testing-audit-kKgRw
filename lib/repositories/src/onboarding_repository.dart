import '/services/firebase_data_service.dart';

/// Repository des réponses d'onboarding.
///
/// Gère la persistance hybride (local → Firebase) des réponses au questionnaire
/// d'onboarding qui servent à personnaliser les recommandations.
class OnboardingRepository {
  const OnboardingRepository();

  /// Sauvegarde les réponses d'onboarding (local + Firebase si connecté).
  Future<void> saveAnswers(Map<String, dynamic> answers) =>
      FirebaseDataService.saveOnboardingAnswers(answers);

  /// Charge les réponses d'onboarding (Firebase → fallback local).
  Future<Map<String, dynamic>?> loadAnswers() =>
      FirebaseDataService.loadOnboardingAnswers();

  /// Sauvegarde les tags du profil utilisateur (intérêts, style, âge…).
  Future<void> saveUserProfileTags(Map<String, dynamic> tags) =>
      FirebaseDataService.saveUserProfileTags(tags);

  /// Charge les tags du profil utilisateur.
  Future<Map<String, dynamic>?> loadUserProfileTags() =>
      FirebaseDataService.loadUserProfileTags();
}
