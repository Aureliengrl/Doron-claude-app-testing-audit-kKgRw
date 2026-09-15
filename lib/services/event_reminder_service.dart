import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/services/firebase_data_service.dart';
import '/utils/app_logger.dart';

/// Service de rappels d'événements liés aux wishlists.
/// Permet d'associer une date à une wishlist et de déclencher
/// des rappels (7j avant, 1j avant).
class EventReminderService {
  static final _db = FirebaseFirestore.instance;
  static String? get _myUid => FirebaseDataService.currentUserId;

  /// Associe une date d'événement à une wishlist.
  static Future<void> setEventDate({
    required String wishlistId,
    required DateTime eventDate,
    String? eventLabel,
  }) async {
    final myUid = _myUid;
    if (myUid == null) return;

    try {
      await _db
          .collection('users')
          .doc(myUid)
          .collection('wishlists')
          .doc(wishlistId)
          .update({
        'eventDate': Timestamp.fromDate(eventDate),
        'eventLabel': eventLabel ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.debug(
          'Event date set for $wishlistId: $eventDate', 'Reminder');
    } catch (e) {
      AppLogger.debug('EventReminderService.setEventDate: $e', 'Reminder');
    }
  }

  /// Supprime la date d'événement d'une wishlist.
  static Future<void> clearEventDate(String wishlistId) async {
    final myUid = _myUid;
    if (myUid == null) return;

    try {
      await _db
          .collection('users')
          .doc(myUid)
          .collection('wishlists')
          .doc(wishlistId)
          .update({
        'eventDate': FieldValue.delete(),
        'eventLabel': FieldValue.delete(),
      });
    } catch (_) {}
  }

  /// Vérifie les wishlists avec des événements proches et retourne
  /// les rappels à afficher. À appeler au démarrage de l'app.
  static Future<List<Map<String, dynamic>>> checkUpcomingReminders() async {
    final myUid = _myUid;
    if (myUid == null) return [];

    try {
      final now = DateTime.now();
      final sevenDaysFromNow = now.add(const Duration(days: 7));

      final snap = await _db
          .collection('users')
          .doc(myUid)
          .collection('wishlists')
          .get();

      final reminders = <Map<String, dynamic>>[];
      final prefs = await SharedPreferences.getInstance();

      for (final doc in snap.docs) {
        final data = doc.data();
        final eventDate = (data['eventDate'] as Timestamp?)?.toDate();
        if (eventDate == null) continue;

        // Ignorer les événements passés
        if (eventDate.isBefore(now)) continue;

        final daysUntil = eventDate.difference(now).inDays;
        final wishlistName = data['name'] as String? ?? 'Wishlist';
        final eventLabel = data['eventLabel'] as String? ?? '';

        // Clé de rappel pour éviter de montrer le même rappel deux fois
        final reminderKey = '${doc.id}_$daysUntil';
        final alreadyShown = prefs.getBool('reminder_$reminderKey') ?? false;

        if (!alreadyShown && daysUntil <= 7) {
          String message;
          if (daysUntil == 0) {
            message = "C'est aujourd'hui !";
          } else if (daysUntil == 1) {
            message = 'Demain !';
          } else {
            message = 'Dans $daysUntil jours';
          }

          reminders.add({
            'wishlistId': doc.id,
            'wishlistName': wishlistName,
            'eventLabel': eventLabel,
            'eventDate': eventDate,
            'daysUntil': daysUntil,
            'message': message,
            'reminderKey': reminderKey,
          });
        }
      }

      // Trier par date la plus proche
      reminders.sort((a, b) =>
          (a['daysUntil'] as int).compareTo(b['daysUntil'] as int));

      return reminders;
    } catch (e) {
      AppLogger.debug(
          'EventReminderService.checkUpcomingReminders: $e', 'Reminder');
      return [];
    }
  }

  /// Marque un rappel comme affiché pour ne pas le montrer à nouveau.
  static Future<void> markReminderShown(String reminderKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('reminder_$reminderKey', true);
    } catch (_) {}
  }

  /// Récupère les wishlists avec des dates d'événement.
  static Future<List<Map<String, dynamic>>> getWishlistsWithDates() async {
    final myUid = _myUid;
    if (myUid == null) return [];

    try {
      final snap = await _db
          .collection('users')
          .doc(myUid)
          .collection('wishlists')
          .get();

      return snap.docs
          .where((doc) => doc.data()['eventDate'] != null)
          .map((doc) => {
                'id': doc.id,
                'name': doc.data()['name'] ?? 'Wishlist',
                'eventDate': (doc.data()['eventDate'] as Timestamp).toDate(),
                'eventLabel': doc.data()['eventLabel'] ?? '',
              })
          .toList()
        ..sort((a, b) => (a['eventDate'] as DateTime)
            .compareTo(b['eventDate'] as DateTime));
    } catch (_) {
      return [];
    }
  }
}
