import '/services/firebase_data_service.dart';

/// Repository des destinataires (personnes pour qui on cherche des cadeaux).
///
/// Gère la création, la lecture, la mise à jour et la suppression des
/// profils de destinataires avec synchronisation local/Firebase.
class PersonRepository {
  const PersonRepository();

  /// Crée un nouveau destinataire.
  /// Retourne l'ID du destinataire cr, ou null en cas d'erreur.
  Future<String?> create({
    required Map<String, dynamic> tags,
    bool isPendingFirstGen = false,
  }) =>
      FirebaseDataService.createPerson(
        tags: tags,
        isPendingFirstGen: isPendingFirstGen,
      );

  /// Charge tous les destinataires de l'utilisateur.
  Future<List<Map<String, dynamic>>> loadAll() =>
      FirebaseDataService.loadPeople();

  /// Charge un destinataire par son ID.
  Future<Map<String, dynamic>?> loadById(String personId) =>
      FirebaseDataService.loadPersonById(personId);

  /// Supprime un destinataire et ses listes de cadeaux associées.
  Future<void> delete(String personId) =>
      FirebaseDataService.deletePerson(personId);

  /// Marque un destinataire comme ayant reçu sa première génération.
  Future<void> clearPendingFlag(String personId) =>
      FirebaseDataService.updatePersonPendingFlag(personId, false);

  /// Retourne la première personne dont la génération est en attente.
  Future<Map<String, dynamic>?> getFirstPending() =>
      FirebaseDataService.getFirstPendingPerson();

  /// Sauvegarde une liste de cadeaux pour un destinataire.
  Future<String?> saveGiftList({
    required String personId,
    required List<Map<String, dynamic>> gifts,
    String? listName,
  }) =>
      FirebaseDataService.saveGiftListForPerson(
        personId: personId,
        gifts: gifts,
        listName: listName ?? 'Suggestions',
      );

  /// Charge toutes les listes de cadeaux d'un destinataire.
  Future<List<Map<String, dynamic>>> loadGiftLists(String personId) =>
      FirebaseDataService.loadGiftListsForPerson(personId);

  /// Charge la dernière liste de cadeaux d'un destinataire.
  Future<Map<String, dynamic>?> loadLatestGiftList(String personId) =>
      FirebaseDataService.loadLatestGiftListForPerson(personId);
}
