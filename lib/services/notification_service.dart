import 'package:cloud_firestore/cloud_firestore.dart';
import '/utils/app_logger.dart';

/// Écrit une notification dans le flux in-app d'un utilisateur
/// (`notifications/{uid}/items`), affiché sur l'écran Notifications et
/// relayé en push (FCM) par les Cloud Functions correspondantes.
class NotificationService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> send({
    required String toUid,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic> extra = const {},
  }) async {
    try {
      await _db.collection('notifications').doc(toUid).collection('items').add({
        'type': type,
        'title': title,
        'body': body,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        ...extra,
      });
    } catch (e) {
      AppLogger.debug('NotificationService.send($type -> $toUid) failed: $e', 'Notif');
    }
  }
}
