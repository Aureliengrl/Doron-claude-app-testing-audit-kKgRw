import '/utils/app_logger.dart';

/// Model pour gérer l'état de la page de résultats cadeaux post-onboarding
class OnboardingGiftsResultModel {
  List<Map<String, dynamic>> gifts = [];
  bool isLoading = false;
  Map<String, dynamic>? userProfile;
  String? errorMessage;
  String? errorDetails;
  String? personId; // ID de la personne pour laquelle on génère les cadeaux
  Map<String, dynamic>? personTags; // Tags de la personne (recipient, budget, etc.)
  Map<String, dynamic>? voiceProfile; // ?? Profil généré par l'assistant vocal

  // Sélection multiple de cadeaux
  Set<String> selectedGiftIds = {};

  void setGifts(List<Map<String, dynamic>> newGifts) {
    gifts = newGifts;
  }

  void setLoading(bool loading) {
    isLoading = loading;
  }

  void setUserProfile(Map<String, dynamic>? profile) {
    userProfile = profile;
  }

  void setError(String? message, String? details) {
    errorMessage = message;
    errorDetails = details;
  }

  void clearError() {
    errorMessage = null;
    errorDetails = null;
  }

  void setPersonId(String? id) {
    personId = id;
  }

  void setPersonTags(Map<String, dynamic>? tags) {
    personTags = tags;
  }

  /// ?? Défini le profil vocal (assistant vocal)
  void setVoiceProfile(Map<String, dynamic>? profile) {
    voiceProfile = profile;
    AppLogger.debug('?? Profil vocal défini dans model: ${profile?.keys.join(", ")}', 'Debug');
  }

  /// Toggle la sélection d'un cadeau
  void toggleGiftSelection(String giftId) {
    if (selectedGiftIds.contains(giftId)) {
      selectedGiftIds.remove(giftId);
      AppLogger.debug('?? Cadeau désélectionné: $giftId', 'Debug');
    } else {
      selectedGiftIds.add(giftId);
      AppLogger.debug('? Cadeau sélectionné: $giftId', 'Debug');
    }
  }

  /// Vérifie si un cadeau est sélectionné
  bool isGiftSelected(String giftId) {
    return selectedGiftIds.contains(giftId);
  }

  /// Obtient la liste des cadeaux sélectionnés
  List<Map<String, dynamic>> getSelectedGifts() {
    return gifts.where((gift) {
      final giftId = gift['id']?.toString() ?? '';
      return selectedGiftIds.contains(giftId);
    }).toList();
  }

  /// Nombre de cadeaux sélectionnés
  int get selectedCount => selectedGiftIds.length;

  void dispose() {
    // Cleanup si nécessaire
  }
}
