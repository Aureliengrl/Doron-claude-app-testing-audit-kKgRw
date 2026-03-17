import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/utils/app_logger.dart';

/// Service de gestion des amis et des chats directs dans Doron.
/// Utilise la sous-collection `users/{uid}/friends` pour stocker les amis.
/// Utilise la collection `chats` existante pour les messages directs.
class FriendService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get _currentUid => _auth.currentUser?.uid;

  // ─── Liste des amis en temps réel ────────────────────────────────────────

  /// Stream des amis de l'utilisateur connecté.
  static Stream<List<Map<String, dynamic>>> getFriendsStream() {
    final uid = _currentUid;
    if (uid == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(uid)
        .collection('friends')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  // ─── Ajouter un ami ───────────────────────────────────────────────────────

  /// Ajoute un utilisateur comme ami (bidirectionnel).
  static Future<void> addFriend(Map<String, dynamic> profile) async {
    final uid = _currentUid;
    if (uid == null) return;

    final friendUid = profile['uid'] as String?;
    if (friendUid == null || friendUid == uid) return;

    final friendData = {
      'uid': friendUid,
      'displayName': profile['displayName'] ?? 'Utilisateur',
      'handle': profile['handle'] ?? '',
      'photoUrl': profile['photoUrl'] ?? '',
      'addedAt': FieldValue.serverTimestamp(),
    };

    try {
      // On écrit dans les deux sens
      final batch = _db.batch();

      // Mon côté
      batch.set(
        _db.collection('users').doc(uid).collection('friends').doc(friendUid),
        friendData,
      );

      // Son côté — on récupère mon propre profil pour lui envoyer
      final myDoc = await _db.collection('users').doc(uid).get();
      final myData = myDoc.data() ?? {};
      batch.set(
        _db.collection('users').doc(friendUid).collection('friends').doc(uid),
        {
          'uid': uid,
          'displayName': myData['display_name'] ?? myData['name'] ?? 'Moi',
          'handle': myData['handle'] ?? '',
          'photoUrl': myData['photo_url'] ?? '',
          'addedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();
      AppLogger.debug('✅ Ami ajouté: $friendUid', 'Social');
    } catch (e) {
      AppLogger.debug('❌ FriendService.addFriend: $e', 'Social');
      rethrow;
    }
  }

  // ─── Supprimer un ami ─────────────────────────────────────────────────────

  /// Supprime un ami (bidirectionnel).
  static Future<void> removeFriend(String friendUid) async {
    final uid = _currentUid;
    if (uid == null) return;

    try {
      final batch = _db.batch();
      batch.delete(_db.collection('users').doc(uid).collection('friends').doc(friendUid));
      batch.delete(_db.collection('users').doc(friendUid).collection('friends').doc(uid));
      await batch.commit();
      AppLogger.debug('✅ Ami supprimé: $friendUid', 'Social');
    } catch (e) {
      AppLogger.debug('❌ FriendService.removeFriend: $e', 'Social');
    }
  }

  // ─── Vérifier si déjà ami ────────────────────────────────────────────────

  /// Vérifie si un utilisateur est déjà dans notre liste d'amis.
  static Future<bool> isFriend(String friendUid) async {
    final uid = _currentUid;
    if (uid == null) return false;

    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('friends')
          .doc(friendUid)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // ─── Obtenir ou créer un chat direct ─────────────────────────────────────

  /// Cherche un chat privé existant entre les deux utilisateurs.
  /// S'il n'existe pas, en crée un nouveau et retourne son ID.
  static Future<String> getOrCreateDirectChat(String friendUid) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('Non connecté');

    try {
      // Chercher un chat privé existant avec cet ami
      final existing = await _db
          .collection('chats')
          .where('isGroup', isEqualTo: false)
          .where('participants', arrayContains: uid)
          .get();

      for (final doc in existing.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        if (participants.contains(friendUid) && participants.length == 2) {
          return doc.id; // Chat existant trouvé
        }
      }

      // Créer un nouveau chat direct
      final chatRef = await _db.collection('chats').add({
        'participants': [uid, friendUid],
        'isGroup': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': {uid: 0, friendUid: 0},
      });

      AppLogger.debug('✅ Chat direct créé: ${chatRef.id}', 'Social');
      return chatRef.id;
    } catch (e) {
      AppLogger.debug('❌ FriendService.getOrCreateDirectChat: $e', 'Social');
      rethrow;
    }
  }
}
