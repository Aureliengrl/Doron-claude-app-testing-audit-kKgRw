import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '/utils/app_logger.dart';

/// Service de collaboration sur les listes de cadeaux.
/// Gère : création, invitations, deep links, gestion du chat de groupe.
class CollaborationService {
  static final _db = FirebaseFirestore.instance;
  static String? get _myUid => FirebaseAuth.instance.currentUser?.uid;

  // ─── Créer ou récupérer une collaboration ─────────────────────────────────

  /// Crée une collaboration pour [profileId] ou retourne l'existante.
  /// Crée aussi le chat de groupe si nécessaire.
  static Future<Map<String, dynamic>> createOrGetCollab({
    required String profileId,
    required String profileName,
  }) async {
    final myUid = _myUid;
    if (myUid == null) throw Exception('Non connecté');

    try {
      // Chercher une collaboration existante pour ce profil et cet owner
      // IMPORTANT: inclure where('ownerId') pour satisfaire les security rules Firestore
      // (sans ce filtre, la query peut retourner des docs d'autres users → permission-denied)
      final existing = await _db
          .collection('collaborations')
          .where('profileId', isEqualTo: profileId)
          .where('ownerId', isEqualTo: myUid)
          .get();

      if (existing.docs.isNotEmpty) {
        final doc = existing.docs.first;
        return {'collabId': doc.id, ...doc.data()};
      }

      // Générer un token unique pour le lien d'invitation
      final inviteToken = const Uuid().v4().replaceAll('-', '').substring(0, 16);

      // Créer le chat de groupe
      final chatRef = _db.collection('chats').doc();
      await chatRef.set({
        'id': chatRef.id,
        'name': 'Cadeaux pour $profileName',
        'isGroup': true,
        'participants': [myUid],
        'lastMessage': '🎁 Groupe de collaboration créé !',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': myUid,
        'linkedProfileId': profileId,
      });

      // Premier message dans le chat
      await chatRef.collection('messages').add({
        'senderId': 'system',
        'text': '🎁 Liste de cadeaux partagée pour $profileName. Invitez des amis pour collaborer !',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'system',
      });

      // Créer la collaboration
      final collabRef = _db.collection('collaborations').doc();
      final collabData = {
        'profileId': profileId,
        'profileName': profileName,
        'ownerId': myUid,
        'members': [myUid],
        'pendingInvites': <String>[],
        'chatId': chatRef.id,
        'inviteToken': inviteToken,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await collabRef.set(collabData);

      // Mettre à jour le profil avec chatId et collabId
      try {
        await _db
            .collection('users')
            .doc(myUid)
            .collection('people')
            .doc(profileId)
            .set({
          'isShared': true,
          'chatId': chatRef.id,
          'collabId': collabRef.id,
        }, SetOptions(merge: true));
      } catch (e) { AppLogger.debug('CollaborationService error: $e', 'Collab'); }

      AppLogger.debug('✅ CollaborationService: collab créée ${collabRef.id}', 'Collab');
      return {'collabId': collabRef.id, ...collabData, 'chatId': chatRef.id};
    } catch (e) {
      AppLogger.debug('❌ CollaborationService.createOrGetCollab: $e', 'Collab');
      rethrow;
    }
  }

  // ─── Inviter un utilisateur Doron ─────────────────────────────────────────

  /// Invite [toUid] à rejoindre [collabId].
  /// Si [isAlreadyFriend] → ajoute directement en membre.
  /// Sinon → crée une invitation en attente.
  static Future<String> inviteUser({
    required String collabId,
    required String toUid,
    required String profileName,
    bool isAlreadyFriend = false,
  }) async {
    final myUid = _myUid;
    if (myUid == null) throw Exception('Non connecté');

    try {
      if (isAlreadyFriend) {
        // Ajout direct
        await addMember(collabId: collabId, uid: toUid);
        return 'added';
      }

      // Vérifier si une invitation existe déjà
      // Utilise 2 filtres max pour éviter l'index composite, filtre status côté client
      final existingInvite = await _db
          .collection('collab_invites')
          .where('collabId', isEqualTo: collabId)
          .where('toUid', isEqualTo: toUid)
          .limit(5)
          .get();

      final pendingInvite = existingInvite.docs
          .where((d) => d.data()['status'] == 'pending')
          .toList();

      if (pendingInvite.isNotEmpty) {
        return pendingInvite.first.id;
      }

      // Créer l'invitation
      final inviteRef = await _db.collection('collab_invites').add({
        'collabId': collabId,
        'fromUid': myUid,
        'toUid': toUid,
        'profileName': profileName,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Ajouter dans pendingInvites de la collaboration
      await _db.collection('collaborations').doc(collabId).update({
        'pendingInvites': FieldValue.arrayUnion([toUid]),
      });

      AppLogger.debug('✅ Invitation envoyée: ${inviteRef.id}', 'Collab');
      return inviteRef.id;
    } catch (e) {
      AppLogger.debug('❌ CollaborationService.inviteUser: $e', 'Collab');
      rethrow;
    }
  }

  // ─── Ajouter un membre directement ────────────────────────────────────────

  static Future<void> addMember({
    required String collabId,
    required String uid,
  }) async {
    try {
      // Récupérer le chatId
      final collabDoc = await _db.collection('collaborations').doc(collabId).get();
      final data = collabDoc.data();
      if (data == null) {
        AppLogger.debug('❌ addMember: collab $collabId not found', 'Collab');
        throw Exception('Collaboration introuvable');
      }

      final chatId = data['chatId'] as String?;
      final profileName = data['profileName'] as String? ?? 'la liste';

      // 1. Ajouter dans la collaboration (opération séparée)
      await _db.collection('collaborations').doc(collabId).set({
        'members': FieldValue.arrayUnion([uid]),
        'pendingInvites': FieldValue.arrayRemove([uid]),
      }, SetOptions(merge: true));

      // 2. Ajouter dans le chat de groupe
      if (chatId != null) {
        try {
          await _db.collection('chats').doc(chatId).set({
            'participants': FieldValue.arrayUnion([uid]),
          }, SetOptions(merge: true));

          // Message système dans le chat
          await _db.collection('chats').doc(chatId).collection('messages').add({
            'senderId': 'system',
            'text': '👤 Un nouveau membre a rejoint la collaboration pour $profileName !',
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'system',
          });
        } catch (e) {
          AppLogger.debug('⚠️ addMember: chat update failed (non-critical): $e', 'Collab');
        }
      }

      AppLogger.debug('✅ Membre $uid ajouté à $collabId', 'Collab');
    } catch (e) {
      AppLogger.debug('❌ CollaborationService.addMember: $e', 'Collab');
      rethrow;
    }
  }

  // ─── Accepter une invitation ───────────────────────────────────────────────

  static Future<Map<String, dynamic>> acceptInvite(String inviteId) async {
    final myUid = _myUid;
    if (myUid == null) throw Exception('Non connecté');

    try {
      final inviteDoc = await _db.collection('collab_invites').doc(inviteId).get();
      final invite = inviteDoc.data();
      if (invite == null) throw Exception('Invitation introuvable');

      final collabId = invite['collabId'] as String;

      // Marquer comme acceptée
      await _db.collection('collab_invites').doc(inviteId).update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Ajouter le membre
      await addMember(collabId: collabId, uid: myUid);

      // Récupérer les infos de la collaboration
      final collabDoc = await _db.collection('collaborations').doc(collabId).get();
      final collab = collabDoc.data() ?? {};

      AppLogger.debug('✅ Invitation acceptée: $inviteId', 'Collab');
      return {
        'collabId': collabId,
        'chatId': collab['chatId'],
        'profileName': collab['profileName'] ?? 'la liste',
      };
    } catch (e) {
      AppLogger.debug('❌ CollaborationService.acceptInvite: $e', 'Collab');
      rethrow;
    }
  }

  // ─── Refuser une invitation ────────────────────────────────────────────────

  static Future<void> declineInvite(String inviteId) async {
    try {
      final inviteDoc = await _db.collection('collab_invites').doc(inviteId).get();
      final invite = inviteDoc.data();

      await _db.collection('collab_invites').doc(inviteId).update({
        'status': 'declined',
      });

      if (invite != null) {
        final myUid = _myUid;
        if (myUid != null) {
          await _db.collection('collaborations').doc(invite['collabId']).update({
            'pendingInvites': FieldValue.arrayRemove([myUid]),
          });
        }
      }
    } catch (e) {
      AppLogger.debug('❌ CollaborationService.declineInvite: $e', 'Collab');
    }
  }

  // ─── Rejoindre via token (deep link) ──────────────────────────────────────

  static Future<Map<String, dynamic>?> joinByToken(String token) async {
    final myUid = _myUid;
    if (myUid == null) return null;

    try {
      final snap = await _db
          .collection('collaborations')
          .where('inviteToken', isEqualTo: token)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;

      final collabDoc = snap.docs.first;
      final collab = collabDoc.data();
      final collabId = collabDoc.id;
      final members = (collab['members'] as List?)?.cast<String>() ?? [];

      // Déjà membre ?
      if (members.contains(myUid)) {
        return {
          'collabId': collabId,
          'chatId': collab['chatId'],
          'profileName': collab['profileName'] ?? 'la liste',
          'alreadyMember': true,
        };
      }

      // Ajouter comme membre
      await addMember(collabId: collabId, uid: myUid);

      AppLogger.debug('✅ Rejoint par token: $collabId', 'Collab');
      return {
        'collabId': collabId,
        'chatId': collab['chatId'],
        'profileName': collab['profileName'] ?? 'la liste',
        'alreadyMember': false,
      };
    } catch (e) {
      AppLogger.debug('❌ CollaborationService.joinByToken: $e', 'Collab');
      return null;
    }
  }

  // ─── Générer le lien d'invitation ─────────────────────────────────────────

  /// Génère un lien d'invitation qui :
  /// 1. Ouvre l'app directement si installée (deep link)
  /// 2. Redirige vers l'App Store / Play Store sinon
  static String generateInviteLink(String inviteToken) {
    // Utilise un lien universel Apple (app_links) qui redirige vers l'app
    // ou vers l'App Store si non installée.
    // Le domaine doron.app doit être configuré avec apple-app-site-association.
    // Fallback: lien App Store direct avec le token en paramètre.
    return 'https://doron.app/join/$inviteToken';
  }

  // ─── Streams ──────────────────────────────────────────────────────────────

  /// Stream des invitations collab reçues et en attente.
  /// FIX #6: Filtre sur toUid uniquement pour éviter l'index composite (toUid+status).
  /// Le filtre status='pending' est appliqué côté client.
  static Stream<List<Map<String, dynamic>>> getMyPendingCollabInvitesStream() {
    final myUid = _myUid;
    if (myUid == null) return Stream.value([]);

    return _db
        .collection('collab_invites')
        .where('toUid', isEqualTo: myUid)
        .snapshots()
        .asyncMap((snap) async {
      final result = <Map<String, dynamic>>[];
      // Filtre status côté client pour éviter l'index composite
      final pendingDocs = snap.docs
          .where((d) => d.data()['status'] == 'pending')
          .toList();
      for (final doc in pendingDocs) {
        final data = doc.data();
        try {
          final senderDoc = await _db.collection('users').doc(data['fromUid']).get();
          final sender = senderDoc.data() ?? {};
          result.add({
            'inviteId': doc.id,
            'collabId': data['collabId'],
            'fromUid': data['fromUid'],
            'profileName': data['profileName'] ?? 'une liste',
            'fromName': sender['first_name'] ?? sender['display_name'] ?? 'Quelqu\'un',
            'fromPhotoUrl': (sender['photo_url'] as String?)?.isNotEmpty == true
                ? sender['photo_url'] as String
                : (sender['photoUrl'] as String?)?.isNotEmpty == true
                    ? sender['photoUrl'] as String
                    : (sender['photoURL'] as String?) ?? '',
            'createdAt': data['createdAt'],
          });
        } catch (e) {
          AppLogger.debug('CollaborationService error: $e', 'Collab');
          result.add({
            'inviteId': doc.id,
            'collabId': data['collabId'],
            'fromUid': data['fromUid'],
            'profileName': data['profileName'] ?? 'une liste',
            'fromName': 'Quelqu\'un',
            'fromPhotoUrl': '',
            'createdAt': data['createdAt'],
          });
        }
      }
      return result;
    });
  }


  /// Stream temps réel d'une collaboration.
  static Stream<Map<String, dynamic>?> getCollabStream(String collabId) {
    return _db.collection('collaborations').doc(collabId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return {'collabId': snap.id, ...snap.data()!};
    });
  }

  /// Récupère le nombre de membres d'une collab liée à un profil.
  static Future<int> getMembersCount(String profileId, String ownerUid) async {
    try {
      final snap = await _db
          .collection('collaborations')
          .where('profileId', isEqualTo: profileId)
          .where('ownerId', isEqualTo: ownerUid)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return 0;
      final members = (snap.docs.first.data()['members'] as List?) ?? [];
      return members.length;
    } catch (e) {
      AppLogger.debug('CollaborationService error: $e', 'Collab');
      return 0;
    }
  }
}
