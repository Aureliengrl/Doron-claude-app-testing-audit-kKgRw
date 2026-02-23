import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '/utils/app_logger.dart';

/// Service pour gérer les sessions de billetterie LYF PAY
/// Sessions temporaires et non partageables
class TicketSessionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _uuid = Uuid();

  /// Durée de vie d'une session (15 minutes)
  static const _sessionDuration = Duration(minutes: 15);

  /// Collection Firestore pour les sessions
  static const _sessionsCollection = 'ticket_sessions';

  /// Crée une nouvelle session de billetterie
  /// Returns: Session ID unique
  static Future<String?> createSession({
    required String deviceId,
    required String appVersion,
  }) async {
    try {
      final sessionId = _uuid.v4();
      final now = DateTime.now();
      final expiresAt = now.add(_sessionDuration);

      await _firestore.collection(_sessionsCollection).doc(sessionId).set({
        'sessionId': sessionId,
        'deviceId': deviceId,
        'appVersion': appVersion,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'status': 'pending', // pending, active, completed, expired
        'paymentCompleted': false,
        'lastAccessedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.success('Session billetterie créée: $sessionId', 'TicketSession');
      return sessionId;
    } catch (e) {
      AppLogger.error('Erreur création session billetterie', 'TicketSession', e);
      return null;
    }
  }

  /// Vérifie si une session est valide
  static Future<bool> isSessionValid(String sessionId) async {
    try {
      final doc = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .get();

      if (!doc.exists) {
        AppLogger.warning('Session non trouvée: $sessionId', 'TicketSession');
        return false;
      }

      final data = doc.data()!;
      final status = data['status'] as String;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final now = DateTime.now();

      // Vérifier expiration
      if (now.isAfter(expiresAt)) {
        AppLogger.warning('Session expirée: $sessionId', 'TicketSession');
        await _expireSession(sessionId);
        return false;
      }

      // Vérifier statut
      if (status == 'expired' || status == 'completed') {
        AppLogger.warning('Session déjà terminée: $sessionId', 'TicketSession');
        return false;
      }

      // Mettre à jour le dernier accès
      await _firestore.collection(_sessionsCollection).doc(sessionId).update({
        'lastAccessedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      return true;
    } catch (e) {
      AppLogger.error('Erreur validation session', 'TicketSession', e);
      return false;
    }
  }

  /// Marque une session comme complétée (après paiement réussi)
  static Future<void> completeSession(String sessionId) async {
    try {
      await _firestore.collection(_sessionsCollection).doc(sessionId).update({
        'status': 'completed',
        'paymentCompleted': true,
        'completedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.success('Session complétée: $sessionId', 'TicketSession');
    } catch (e) {
      AppLogger.error('Erreur complétion session', 'TicketSession', e);
    }
  }

  /// Marque une session comme expirée
  static Future<void> _expireSession(String sessionId) async {
    try {
      await _firestore.collection(_sessionsCollection).doc(sessionId).update({
        'status': 'expired',
        'expiredAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error('Erreur expiration session', 'TicketSession', e);
    }
  }

  /// Annule une session (si l'utilisateur quitte)
  static Future<void> cancelSession(String sessionId) async {
    try {
      final doc = await _firestore
          .collection(_sessionsCollection)
          .doc(sessionId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final status = data['status'] as String;

        // Ne pas annuler si déjà complétée
        if (status != 'completed') {
          await _firestore.collection(_sessionsCollection).doc(sessionId).update({
            'status': 'cancelled',
            'cancelledAt': FieldValue.serverTimestamp(),
          });

          AppLogger.info('Session annulée: $sessionId', 'TicketSession');
        }
      }
    } catch (e) {
      AppLogger.error('Erreur annulation session', 'TicketSession', e);
    }
  }

  /// Nettoie les sessions expirées (à appeler périodiquement)
  static Future<void> cleanupExpiredSessions() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection(_sessionsCollection)
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .where('status', whereIn: ['pending', 'active'])
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'status': 'expired',
          'expiredAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      AppLogger.info('${snapshot.docs.length} sessions expirées nettoyées', 'TicketSession');
    } catch (e) {
      AppLogger.error('Erreur nettoyage sessions', 'TicketSession', e);
    }
  }

  /// Génère l'URL LYF PAY avec session ID
  static String generateLyfPayUrl(String sessionId) {
    // URL de base LYF PAY (à remplacer par l'URL réelle fournie par LYF PAY)
    const lyfPayBaseUrl = 'https://pay.lyf.eu/doron-gala';

    // Ajouter le session ID comme paramètre sécurisé
    return '$lyfPayBaseUrl?session=$sessionId&app=doron';
  }

  /// Vérifie si une URL est une URL de callback valide
  static bool isValidCallbackUrl(String url) {
    // URL de callback attendue de LYF PAY
    return url.contains('doron://ticket-success') ||
           url.contains('doron://ticket-cancelled');
  }

  /// Extrait le session ID d'une URL de callback
  static String? extractSessionIdFromCallback(String url) {
    final uri = Uri.parse(url);
    return uri.queryParameters['session'];
  }
}
