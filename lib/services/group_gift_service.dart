import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/utils/app_logger.dart';
import 'collaboration_service.dart';

/// Service du mode « Cadeau de groupe » (cagnotte).
///
/// S'appuie sur [CollaborationService] (collab + chat de groupe + invitations)
/// et ajoute la couche spécifique cagnotte :
///   - le cadeau retenu (retainedGift),
///   - la répartition du montant (égale ou personnalisée),
///   - le cycle de paiement par participant (due → declared → confirmed / refused),
///   - les notifications et messages de chat associés.
///
/// ⚠️ Doron ne manipule JAMAIS d'argent : on ne fait que coordonner. Les
/// paiements se font hors de l'app (Revolut / Wero / IBAN), et la confirmation
/// est manuelle (« j'ai envoyé » côté participant, « j'ai reçu » côté hôte).
class GroupGiftService {
  static final _db = FirebaseFirestore.instance;
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ─── Création ────────────────────────────────────────────────────────────

  /// Crée (ou récupère) une collaboration en mode cagnotte pour [profileId].
  static Future<Map<String, dynamic>> createOrGet({
    required String profileId,
    required String profileName,
  }) {
    return CollaborationService.createOrGetCollab(
      profileId: profileId,
      profileName: profileName,
      mode: 'group_gift',
    );
  }

  // ─── Cadeau retenu ───────────────────────────────────────────────────────

  /// Marque [gift] comme cadeau retenu du groupe. Réservé à l'hôte (verrouillé
  /// aussi par les règles Firestore). Poste un message spécial dans le chat.
  static Future<void> setRetainedGift({
    required String collabId,
    required String chatId,
    required Map<String, dynamic> gift,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Non connecté');

    final retained = <String, dynamic>{
      'giftId': (gift['id'] ?? gift['giftId'] ?? '').toString(),
      'name': (gift['name'] ?? gift['title'] ?? gift['product_title'] ?? 'Cadeau').toString(),
      'price': _toNum(gift['price']),
      'image': (gift['image'] ?? gift['imageUrl'] ?? gift['image_url'] ?? '').toString(),
      'url': (gift['url'] ?? gift['product_url'] ?? '').toString(),
      'chosenBy': uid,
      'chosenAt': FieldValue.serverTimestamp(),
    };

    try {
      await _db.collection('collaborations').doc(collabId).set(
        {'retainedGift': retained},
        SetOptions(merge: true),
      );

      final label = '🎁 Cadeau retenu : ${retained['name']}';
      await _db.collection('chats').doc(chatId).collection('messages').add({
        'senderId': uid,
        'type': 'retained_gift',
        'text': label,
        'gift': retained,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await _db.collection('chats').doc(chatId).set({
        'lastMessage': label,
        'lastMessageTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      AppLogger.debug('✅ GroupGift: cadeau retenu sur $collabId', 'GroupGift');
    } catch (e) {
      AppLogger.debug('❌ GroupGift.setRetainedGift: $e', 'GroupGift');
      rethrow;
    }
  }

  /// Retire le cadeau retenu (l'hôte change d'avis avant la collecte).
  static Future<void> clearRetainedGift({required String collabId}) async {
    await _db.collection('collaborations').doc(collabId).set(
      {'retainedGift': FieldValue.delete()},
      SetOptions(merge: true),
    );
  }

  // ─── Répartition du montant ──────────────────────────────────────────────

  /// Répartit [total] en parts égales entre [uids]. Le reste des centimes
  /// (arrondi) est absorbé par le premier de la liste (place l'hôte en tête
  /// si tu veux qu'il l'absorbe). Retourne uid → montant.
  static Map<String, double> computeEqualSplit(double total, List<String> uids) {
    final n = uids.length;
    if (n == 0) return {};
    final cents = (total * 100).round();
    final baseCents = cents ~/ n;
    final remainder = cents - baseCents * n;
    final result = <String, double>{};
    for (var i = 0; i < n; i++) {
      final c = baseCents + (i == 0 ? remainder : 0);
      result[uids[i]] = c / 100.0;
    }
    return result;
  }

  // ─── Lancer la collecte ──────────────────────────────────────────────────

  /// Ouvre la collecte : écrit l'état sur la collab, crée un doc participant
  /// par personne concernée (statut `due`), notifie chacun et poste un message.
  ///
  /// [shares] : uid → montant dû. Les uids présents deviennent redevables.
  /// [payment] : moyen de l'hôte, ex.
  ///   { 'method':'revolut', 'handle':'@aurel', 'iban':'', 'holderName':'Aurélien', 'url':'https://revolut.me/aurel' }
  static Future<void> startCollection({
    required String collabId,
    required String chatId,
    required String profileName,
    required double total,
    required String splitType, // 'equal' | 'custom'
    required Map<String, double> shares,
    required Map<String, dynamic> payment,
    String currency = 'EUR',
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Non connecté');

    try {
      await _db.collection('collaborations').doc(collabId).set({
        'collection': {
          'status': 'open',
          'total': total,
          'currency': currency,
          'splitType': splitType,
          'startedAt': FieldValue.serverTimestamp(),
          'startedBy': uid,
        },
        'payment': payment,
      }, SetOptions(merge: true));

      final batch = _db.batch();
      shares.forEach((puid, amount) {
        final pRef = _db
            .collection('collaborations')
            .doc(collabId)
            .collection('participants')
            .doc(puid);
        batch.set(pRef, {
          'uid': puid,
          'share': amount,
          'status': 'due',
          'includedInSplit': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Notifier chaque participant (sauf l'hôte lui-même)
        if (puid != uid) {
          final nRef = _db
              .collection('notifications')
              .doc(puid)
              .collection('items')
              .doc();
          batch.set(nRef, {
            'type': 'group_payment_due',
            'collabId': collabId,
            'chatId': chatId,
            'profileName': profileName,
            'amount': amount,
            'title': '🎁 Cagnotte : ta part',
            'body':
                'Ta part pour $profileName : ${amount.toStringAsFixed(2)} $currency',
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });
      await batch.commit();

      await _db.collection('chats').doc(chatId).collection('messages').add({
        // Posté par l'hôte (participant du chat) — 'system' ne passerait pas
        // la règle Firestore pour un type non-'system'.
        'senderId': uid,
        'type': 'payment_request',
        'text': '💰 La collecte est ouverte pour $profileName '
            '(${total.toStringAsFixed(2)} $currency).',
        'total': total,
        'currency': currency,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await _db.collection('chats').doc(chatId).set({
        'lastMessage': '💰 Collecte ouverte',
        'lastMessageTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      AppLogger.debug('✅ GroupGift: collecte lancée sur $collabId', 'GroupGift');
    } catch (e) {
      AppLogger.debug('❌ GroupGift.startCollection: $e', 'GroupGift');
      rethrow;
    }
  }

  /// Ferme la collecte (tout le monde a payé, ou l'hôte clôt manuellement).
  static Future<void> closeCollection({required String collabId}) async {
    await _db.collection('collaborations').doc(collabId).set({
      'collection': {'status': 'closed', 'closedAt': FieldValue.serverTimestamp()},
    }, SetOptions(merge: true));
  }

  // ─── Cycle de paiement ───────────────────────────────────────────────────

  /// Le participant déclare avoir envoyé sa part. Notifie l'hôte.
  static Future<void> declarePayment({
    required String collabId,
    required String chatId,
    required String profileName,
    required String myName,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Non connecté');

    try {
      await _db
          .collection('collaborations')
          .doc(collabId)
          .collection('participants')
          .doc(uid)
          .set({
        'status': 'declared',
        'declaredAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Récupérer l'hôte pour le notifier
      String? ownerId;
      try {
        final collab = await _db.collection('collaborations').doc(collabId).get();
        ownerId = collab.data()?['ownerId'] as String?;
      } catch (_) {}

      await _db.collection('chats').doc(chatId).collection('messages').add({
        'senderId': uid,
        'type': 'payment_declared',
        'text': '💸 $myName a indiqué avoir envoyé sa part.',
        'targetUid': ownerId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (ownerId != null && ownerId != uid) {
        await _db
            .collection('notifications')
            .doc(ownerId)
            .collection('items')
            .add({
          'type': 'group_payment_declared',
          'collabId': collabId,
          'chatId': chatId,
          'fromUid': uid,
          'fromName': myName,
          'profileName': profileName,
          'title': '💸 Paiement déclaré',
          'body': '$myName a envoyé sa part pour $profileName. À confirmer.',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      AppLogger.debug('✅ GroupGift: paiement déclaré par $uid', 'GroupGift');
    } catch (e) {
      AppLogger.debug('❌ GroupGift.declarePayment: $e', 'GroupGift');
      rethrow;
    }
  }

  /// L'hôte confirme avoir reçu le paiement de [participantUid]. Le passe en vert.
  static Future<void> confirmPayment({
    required String collabId,
    required String chatId,
    required String participantUid,
    required String participantName,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Non connecté');

    try {
      await _db
          .collection('collaborations')
          .doc(collabId)
          .collection('participants')
          .doc(participantUid)
          .set({
        'status': 'confirmed',
        'confirmedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _db.collection('chats').doc(chatId).collection('messages').add({
        'senderId': uid,
        'type': 'payment_confirmed',
        'text': '✅ Paiement de $participantName confirmé.',
        'targetUid': participantUid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (participantUid != uid) {
        await _db
            .collection('notifications')
            .doc(participantUid)
            .collection('items')
            .add({
          'type': 'group_payment_confirmed',
          'collabId': collabId,
          'chatId': chatId,
          'title': '✅ Paiement confirmé',
          'body': 'Ton paiement a bien été reçu. Merci !',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      AppLogger.debug('✅ GroupGift: paiement confirmé pour $participantUid', 'GroupGift');
    } catch (e) {
      AppLogger.debug('❌ GroupGift.confirmPayment: $e', 'GroupGift');
      rethrow;
    }
  }

  /// L'hôte indique n'avoir pas reçu le paiement de [participantUid].
  /// Le remet en « due » avec une note facultative, et re-notifie le participant.
  static Future<void> refusePayment({
    required String collabId,
    required String chatId,
    required String participantUid,
    String? note,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Non connecté');

    try {
      await _db
          .collection('collaborations')
          .doc(collabId)
          .collection('participants')
          .doc(participantUid)
          .set({
        'status': 'refused',
        'refusedAt': FieldValue.serverTimestamp(),
        if (note != null && note.isNotEmpty) 'note': note,
      }, SetOptions(merge: true));

      if (participantUid != uid) {
        await _db
            .collection('notifications')
            .doc(participantUid)
            .collection('items')
            .add({
          'type': 'group_payment_due',
          'collabId': collabId,
          'chatId': chatId,
          'title': '⚠️ Paiement non reçu',
          'body': note != null && note.isNotEmpty
              ? 'L\'hôte n\'a pas reçu ton paiement : $note'
              : 'L\'hôte n\'a pas encore reçu ton paiement.',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      AppLogger.debug('✅ GroupGift: paiement refusé pour $participantUid', 'GroupGift');
    } catch (e) {
      AppLogger.debug('❌ GroupGift.refusePayment: $e', 'GroupGift');
      rethrow;
    }
  }

  // ─── Streams ─────────────────────────────────────────────────────────────

  /// Stream temps réel de la collab (mode, retainedGift, collection, payment…).
  static Stream<Map<String, dynamic>?> groupStream(String collabId) =>
      CollaborationService.getCollabStream(collabId);

  /// Stream de la liste des participants (avec leur statut de paiement).
  static Stream<List<Map<String, dynamic>>> participantsStream(String collabId) {
    return _db
        .collection('collaborations')
        .doc(collabId)
        .collection('participants')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {'uid': d.id, ...d.data()}).toList());
  }

  /// Nombre d'actions requises pour l'utilisateur courant sur cette collab :
  ///   - hôte  → nombre de paiements « déclarés » à confirmer,
  ///   - participant → 1 s'il doit (encore) payer, 0 sinon.
  /// Alimente le badge « 1 » sur le rond de la personne (page Recherche).
  static Stream<int> myActionCountStream({
    required String collabId,
    required String ownerId,
  }) {
    final uid = _uid;
    if (uid == null) return Stream.value(0);
    return participantsStream(collabId).map((parts) {
      if (ownerId == uid) {
        return parts.where((p) => p['status'] == 'declared').length;
      }
      final mine = parts.where((p) => p['uid'] == uid).toList();
      if (mine.isEmpty) return 0;
      final st = mine.first['status'];
      return (st == 'due' || st == 'refused') ? 1 : 0;
    });
  }

  // ─── Utils ───────────────────────────────────────────────────────────────

  static double _toNum(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) {
      final cleaned = v.replaceAll(RegExp(r'[^0-9.,]'), '').replaceAll(',', '.');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }
}
