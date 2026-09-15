import '/utils/app_logger.dart';

/// Model pour g�rer l'�tat de la page de r�sultats cadeaux post-onboarding
class OnboardingGiftsResultModel {
  List<Map<String, dynamic>> gifts = [];
  bool isLoading = false;
  Map<String, dynamic>? userProfile;
  String? errorMessage;
  String? errorDetails;
  String? personId; // ID de la personne pour laquelle on g�n�re les cadeaux
  Map<String, dynamic>? personTags; // Tags de la personne (recipient, budget, etc.)
  Map<String, dynamic>? voiceProfile; // ?? Profil g�n�r� par l'assistant vocal

  // Cadeaux ajout�s via l'onglet Recherche (fin de quiz)
  List<Map<String, dynamic>> searchGifts = [];

  // S�lection multiple de cadeaux
  Set<String> selectedGiftIds = {};

  /// Pool complet de cadeaux s�lectionnables : recommand�s + wishlists
  /// (dans `gifts`) + r�sultats de recherche.
  List<Map<String, dynamic>> get allGiftsPool => [...gifts, ...searchGifts];

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

  /// ?? D�fini le profil vocal (assistant vocal)
  void setVoiceProfile(Map<String, dynamic>? profile) {
    voiceProfile = profile;
    AppLogger.debug('?? Profil vocal d�fini dans model: ${profile?.keys.join(", ")}', 'Debug');
  }

  /// Toggle la s�lection d'un cadeau.
  /// Un id vide ne peut pas être sélectionné de façon fiable : plusieurs
  /// cartes différentes pourraient résoudre à un id vide (produit sans champ
  /// `id`), et les traiter comme un seul et même id ferait apparaître TOUTES
  /// ces cartes comme sélectionnées simultanément dès qu'une seule est
  /// cochée — d'où l'ignorer explicitement ici plutôt que de risquer ce bug.
  void toggleGiftSelection(String giftId) {
    if (giftId.isEmpty) return;
    if (selectedGiftIds.contains(giftId)) {
      selectedGiftIds.remove(giftId);
      AppLogger.debug('?? Cadeau d�s�lectionn�: $giftId', 'Debug');
    } else {
      selectedGiftIds.add(giftId);
      AppLogger.debug('? Cadeau s�lectionn�: $giftId', 'Debug');
    }
  }

  /// V�rifie si un cadeau est s�lectionn� (jamais vrai pour un id vide).
  bool isGiftSelected(String giftId) {
    return giftId.isNotEmpty && selectedGiftIds.contains(giftId);
  }

  /// Obtient la liste des cadeaux s�lectionn�s (tous onglets confondus,
  /// d�doublonn�s par id).
  List<Map<String, dynamic>> getSelectedGifts() {
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];
    for (final gift in allGiftsPool) {
      final giftId = gift['id']?.toString() ?? '';
      if (giftId.isEmpty) continue;
      if (selectedGiftIds.contains(giftId) && seen.add(giftId)) {
        result.add(gift);
      }
    }
    return result;
  }

  /// Nombre de cadeaux réellement sélectionnés — calculé à partir de
  /// [getSelectedGifts] (pas juste `selectedGiftIds.length`) pour rester
  /// garanti cohérent avec ce qui sera effectivement sauvegardé : un id vide
  /// ou dupliqué ne doit jamais faire apparaître/valider une sélection qui
  /// ne correspond à aucun cadeau réel (ou à plus de cadeaux que prévu).
  int get selectedCount => getSelectedGifts().length;

  void dispose() {
    // Cleanup si n�cessaire
  }
}
