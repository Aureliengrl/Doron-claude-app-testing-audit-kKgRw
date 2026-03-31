import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/utils/app_logger.dart';

/// Statut de relation entre deux utilisateurs.
enum FriendshipStatus {
  none,             // Pas de relation
  pendingSent,      // Demande envoyée (en attente d'acceptation)
  pendingReceived,  // Demande reçue (à accepter/refuser)
  friends,          // Amis acceptés
}

/// Service gérant les demandes d'amis et la liste d'amis.
class FriendService {
  static final _db = FirebaseFirestore.instance;
  static String? get _myUid => FirebaseAuth.instance.currentUser?.uid;

  // ─── Vérifier si ami (simple) ──────────────────────────────────────────────

  static Future<bool> isFriend(String otherUid) async {
    final myUid = _myUid;
    if (myUid == null) return false;
    try {
      final doc = await _db.collection('users').doc(myUid).get();
      final friends = (doc.data()?['friends'] as List?)?.cast<String>() ?? [];
      return friends.contains(otherUid);
    } catch (_) {
      return false;
    }
  }

  // ─── Stream des amis (temps réel) ─────────────────────────────────────────

  static Stream<List<Map<String, dynamic>>> getFriendsStream() {
    final myUid = _myUid;
    if (myUid == null) return const Stream.empty();

    // Écoute le document user. À chaque modification, récupère les profils amis.
    return _db.collection('users').doc(myUid).snapshots().asyncMap((snap) async {
      final friendUids = (snap.data()?['friends'] as List?)?.cast<String>() ?? [];
      if (friendUids.isEmpty) return <Map<String, dynamic>>[];
      return await getFriends(myUid);
    });
  }

  // ─── Stream des demandes reçues (temps réel) ───────────────────────────────────────

  /// Stream des demandes d'amis reçues non traitées.
  /// N'utilise qu'un seul filtre (toUid) pour éviter la dépendance à un index
  /// composite Firestore qui peut ne pas encore être actif.
  /// Le filtre sur status='pending' est appliqué côté client.
  static Stream<List<Map<String, dynamic>>> getPendingRequestsStream() {
    final myUid = _myUid;
    if (myUid == null) return Stream.value([]);

    return _db
        .collection('friend_requests')
        .where('toUid', isEqualTo: myUid)
        .snapshots()
        .handleError((e) {
          AppLogger.debug('❌ getPendingRequestsStream error: $e', 'FriendService');
          return; // Important: allows stream to continue after error
        })
        .asyncMap((snap) async {
      if (snap == null) return <Map<String, dynamic>>[];
      final requests = <Map<String, dynamic>>[];
      // Filtre status côté client pour éviter l'index composite
      final pendingDocs = snap.docs.where((d) => d.data()['status'] == 'pending').toList();
      for (final doc in pendingDocs) {
        final data = doc.data();
        final fromUid = data['fromUid'] as String?;
        if (fromUid == null || fromUid.isEmpty) continue;

        String displayName = 'Utilisateur';
        String handle = '';
        String photoUrl = '';

        try {
          final senderDoc = await _db.collection('users').doc(fromUid).get();
          if (senderDoc.exists) {
            final sender = senderDoc.data() ?? {};
            displayName = (sender['first_name'] as String?) ??
                         (sender['display_name'] as String?) ??
                         (sender['name'] as String?) ??
                         ((sender['email'] as String? ?? '').split('@').first.isNotEmpty
                             ? (sender['email'] as String).split('@').first
                             : 'Utilisateur');
            handle = (sender['handle'] as String?) ?? (sender['username'] as String?) ?? '';
            photoUrl = (sender['photo_url'] as String?) ?? '';
          }
        } catch (e) {
          AppLogger.debug('getPendingRequestsStream: cannot load sender $fromUid: $e', 'FriendService');
          // Continue anyway — show the request even without full sender info
        }

        requests.add({
          'requestId': doc.id,
          'fromUid': fromUid,
          'displayName': displayName,
          'handle': handle,
          'photoUrl': photoUrl,
          'createdAt': data['createdAt'],
        });
      }
      return requests;
    });
  }

  // ─── Ajouter ami (legacy / direct sans demande) ────────────────────────────

  /// Ajoute directement [profile] comme ami (des deux côtés).
  /// Utilise sendRequest pour un flux propre avec état "pending".
  static Future<void> addFriend(Map<String, dynamic> profile) async {
    final uid = profile['uid'] as String?;
    if (uid == null || uid.isEmpty) return;
    await sendRequest(uid);
  }

  // ─── Envoyer une demande ───────────────────────────────────────────────────

  static Future<String?> sendRequest(String toUid) async {
    final myUid = _myUid;
    if (myUid == null || myUid == toUid) return null;

    try {
      // FIX #4: Éviter le filtre à 3 champs (fromUid+toUid+status) qui nécessite
      // un index composite Firestore potentiellement manquant.
      // On filtre sur 2 champs (fromUid+toUid) et on vérifie status côté client.
      final existing = await _db
          .collection('friend_requests')
          .where('fromUid', isEqualTo: myUid)
          .where('toUid', isEqualTo: toUid)
          .limit(5)
          .get();

      final pendingDoc = existing.docs
          .where((d) => d.data()['status'] == 'pending')
          .firstOrNull;
      if (pendingDoc != null) return pendingDoc.id;

      final ref = await _db.collection('friend_requests').add({
        'fromUid': myUid,
        'toUid': toUid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.debug('✅ FriendService.sendRequest → ${ref.id}', 'Social');
      return ref.id;
    } catch (e) {
      AppLogger.debug('❌ FriendService.sendRequest: $e', 'Social');
      return null;
    }
  }

  // ─── Annuler ───────────────────────────────────────────────────────────────

  static Future<bool> cancelRequest(String requestId) async {
    try {
      await _db.collection('friend_requests').doc(requestId).delete();
      return true;
    } catch (e) {
      AppLogger.debug('❌ FriendService.cancelRequest: $e', 'Social');
      return false;
    }
  }

  // ─── Refuser ───────────────────────────────────────────────────────────────

  static Future<bool> declineRequest(String requestId) async {
    try {
      await _db.collection('friend_requests').doc(requestId).update({
        'status': 'declined',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      AppLogger.debug('❌ FriendService.declineRequest: $e', 'Social');
      return false;
    }
  }

  // ─── Accepter ──────────────────────────────────────────────────────────────

  static Future<bool> acceptRequest(String requestId, String fromUid) async {
    final myUid = _myUid;
    if (myUid == null) return false;
    if (requestId.isEmpty || fromUid.isEmpty) {
      AppLogger.debug('❌ acceptRequest: requestId or fromUid is empty', 'Social');
      return false;
    }

    try {
      // Vérifier que la demande existe avant de l'accepter
      final requestDoc = await _db.collection('friend_requests').doc(requestId).get();
      if (!requestDoc.exists) {
        AppLogger.debug('❌ acceptRequest: request $requestId does not exist', 'Social');
        return false;
      }

      final batch = _db.batch();

      // 1. Mettre à jour le statut de la demande
      batch.update(_db.collection('friend_requests').doc(requestId), {
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Ajouter aux listes d'amis (set merge pour créer le champ si absent)
      batch.set(_db.collection('users').doc(myUid), {
        'friends': FieldValue.arrayUnion([fromUid]),
      }, SetOptions(merge: true));

      batch.set(_db.collection('users').doc(fromUid), {
        'friends': FieldValue.arrayUnion([myUid]),
      }, SetOptions(merge: true));

      await batch.commit();
      AppLogger.debug('✅ FriendService.acceptRequest: $requestId from $fromUid', 'Social');
      return true;
    } catch (e) {
      AppLogger.debug('❌ FriendService.acceptRequest: $e', 'Social');
      return false;
    }
  }

  // ─── Retirer ami ──────────────────────────────────────────────────────────

  static Future<bool> removeFriend(String otherUid) async {
    final myUid = _myUid;
    if (myUid == null) return false;

    try {
      final batch = _db.batch();
      batch.update(_db.collection('users').doc(myUid), {
        'friends': FieldValue.arrayRemove([otherUid]),
      });
      batch.update(_db.collection('users').doc(otherUid), {
        'friends': FieldValue.arrayRemove([myUid]),
      });
      await batch.commit();
      return true;
    } catch (e) {
      AppLogger.debug('❌ FriendService.removeFriend: $e', 'Social');
      return false;
    }
  }

  // ─── Statut de relation ────────────────────────────────────────────────────

  static Future<({FriendshipStatus status, String? requestId})> getFriendshipStatus(
      String otherUid) async {
    final myUid = _myUid;
    if (myUid == null) return (status: FriendshipStatus.none, requestId: null);

    try {
      final myDoc = await _db.collection('users').doc(myUid).get();
      final friends = (myDoc.data()?['friends'] as List?)?.cast<String>() ?? [];
      if (friends.contains(otherUid)) {
        return (status: FriendshipStatus.friends, requestId: null);
      }

      // FIX #4: Utiliser 2 champs max pour éviter l'index composite manquant.
      // On filtre status côté client.
      final sentSnap = await _db
          .collection('friend_requests')
          .where('fromUid', isEqualTo: myUid)
          .where('toUid', isEqualTo: otherUid)
          .limit(5)
          .get();
      final sentPending = sentSnap.docs
          .where((d) => d.data()['status'] == 'pending')
          .firstOrNull;
      if (sentPending != null) {
        return (status: FriendshipStatus.pendingSent, requestId: sentPending.id);
      }

      final receivedSnap = await _db
          .collection('friend_requests')
          .where('fromUid', isEqualTo: otherUid)
          .where('toUid', isEqualTo: myUid)
          .limit(5)
          .get();
      final receivedPending = receivedSnap.docs
          .where((d) => d.data()['status'] == 'pending')
          .firstOrNull;
      if (receivedPending != null) {
        return (status: FriendshipStatus.pendingReceived, requestId: receivedPending.id);
      }

      return (status: FriendshipStatus.none, requestId: null);
    } catch (e) {
      AppLogger.debug('❌ FriendService.getFriendshipStatus: $e', 'Social');
      return (status: FriendshipStatus.none, requestId: null);
    }
  }

  // ─── Demandes en attente ───────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final myUid = _myUid;
    if (myUid == null) return [];

    try {
      // Ne pas utiliser orderBy ici — requiert un index composite qui peut ne pas être actif.
      // Tri effectué côté client après récupération.
      final snap = await _db
          .collection('friend_requests')
          .where('toUid', isEqualTo: myUid)
          .where('status', isEqualTo: 'pending')
          .get();

      final requests = <Map<String, dynamic>>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final senderDoc = await _db.collection('users').doc(data['fromUid']).get();
        final sender = senderDoc.data() ?? {};
        requests.add({
          'requestId': doc.id,
          'fromUid': data['fromUid'],
          'displayName': sender['first_name'] as String? ??
                         sender['display_name'] as String? ??
                         sender['name'] as String? ?? 'Utilisateur',
          'handle': sender['handle'] ?? sender['username'] ?? '',
          'photoUrl': sender['photo_url'] ?? '',
          'createdAt': data['createdAt'],
        });
      }
      // Tri côté client : plus récent en premier
      requests.sort((a, b) {
        final aTs = a['createdAt'];
        final bTs = b['createdAt'];
        if (aTs == null && bTs == null) return 0;
        if (aTs == null) return 1;
        if (bTs == null) return -1;
        return bTs.compareTo(aTs);
      });
      return requests;
    } catch (e) {
      AppLogger.debug('❌ FriendService.getPendingRequests: $e', 'Social');
      return [];
    }
  }


  // ─── Liste d'amis ──────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getFriends(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final friendUids = (doc.data()?['friends'] as List?)?.cast<String>() ?? [];
      if (friendUids.isEmpty) return [];

      final profiles = <Map<String, dynamic>>[];
      for (var i = 0; i < friendUids.length; i += 10) {
        final chunk = friendUids.sublist(
            i, i + 10 > friendUids.length ? friendUids.length : i + 10);
        final snap = await _db
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final d in snap.docs) {
          final data = d.data();
          profiles.add({
            'uid': d.id,
            'displayName': data['first_name'] as String? ??
                           data['display_name'] as String? ??
                           data['name'] as String? ?? 'Utilisateur',
            'handle': data['handle'] ?? data['username'] ?? '',
            'photoUrl': data['photo_url'] ?? '',
          });
        }
      }
      return profiles;
    } catch (e) {
      AppLogger.debug('❌ FriendService.getFriends: $e', 'Social');
      return [];
    }
  }

  // ─── Chat direct ──────────────────────────────────────────────────────────

  /// Récupère ou crée un chat direct avec [friendUid]. Retourne le chatId.
  static Future<String> getOrCreateDirectChat(String friendUid) async {
    final myUid = _myUid;
    if (myUid == null) throw Exception('Non connecté');

    try {
      // Chercher un chat existant entre les deux utilisateurs
      final snap = await _db
          .collection('chats')
          .where('participants', arrayContains: myUid)
          .where('isGroup', isEqualTo: false)
          .get();

      for (final doc in snap.docs) {
        final participants = (doc.data()['participants'] as List).cast<String>();
        if (participants.contains(friendUid) && participants.length == 2) {
          return doc.id;
        }
      }

      // Créer un nouveau chat direct
      final ref = await _db.collection('chats').add({
        'participants': [myUid, friendUid],
        'isGroup': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } catch (e) {
      AppLogger.debug('❌ FriendService.getOrCreateDirectChat: $e', 'Social');
      rethrow;
    }
  }
}
