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

    return _db.collection('users').doc(myUid).snapshots().asyncMap((snap) async {
      final friendUids = (snap.data()?['friends'] as List?)?.cast<String>() ?? [];
      if (friendUids.isEmpty) return <Map<String, dynamic>>[];
      return await getFriends(myUid);
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
      final existing = await _db
          .collection('friend_requests')
          .where('fromUid', isEqualTo: myUid)
          .where('toUid', isEqualTo: toUid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) return existing.docs.first.id;

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

    try {
      final batch = _db.batch();
      batch.update(_db.collection('friend_requests').doc(requestId), {
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.update(_db.collection('users').doc(myUid), {
        'friends': FieldValue.arrayUnion([fromUid]),
      });
      batch.update(_db.collection('users').doc(fromUid), {
        'friends': FieldValue.arrayUnion([myUid]),
      });
      await batch.commit();
      AppLogger.debug('✅ FriendService.acceptRequest: $requestId', 'Social');
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

      final sentSnap = await _db
          .collection('friend_requests')
          .where('fromUid', isEqualTo: myUid)
          .where('toUid', isEqualTo: otherUid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (sentSnap.docs.isNotEmpty) {
        return (status: FriendshipStatus.pendingSent, requestId: sentSnap.docs.first.id);
      }

      final receivedSnap = await _db
          .collection('friend_requests')
          .where('fromUid', isEqualTo: otherUid)
          .where('toUid', isEqualTo: myUid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (receivedSnap.docs.isNotEmpty) {
        return (status: FriendshipStatus.pendingReceived, requestId: receivedSnap.docs.first.id);
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
      final snap = await _db
          .collection('friend_requests')
          .where('toUid', isEqualTo: myUid)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      final requests = <Map<String, dynamic>>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final senderDoc = await _db.collection('users').doc(data['fromUid']).get();
        final sender = senderDoc.data() ?? {};
        requests.add({
          'requestId': doc.id,
          'fromUid': data['fromUid'],
          'displayName': sender['display_name'] ?? sender['name'] ?? 'Utilisateur',
          'handle': sender['handle'] ?? '',
          'photoUrl': sender['photo_url'] ?? '',
          'createdAt': data['createdAt'],
        });
      }
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
            'displayName': data['display_name'] ?? data['name'] ?? 'Utilisateur',
            'handle': data['handle'] ?? '',
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
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } catch (e) {
      AppLogger.debug('❌ FriendService.getOrCreateDirectChat: $e', 'Social');
      rethrow;
    }
  }
}
