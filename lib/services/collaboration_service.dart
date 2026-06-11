import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '/utils/app_logger.dart';

/// Service de collaboration sur les listes de cadeaux.
/// GÃ¨re : crÃ©ation, invitations, deep links, gestion du chat de groupe.
class CollaborationService {
  static final _db = FirebaseFirestore.instance;
  static String? get _myUid => FirebaseAuth.instance.currentUser?.uid;

  // â”€â”€â”€ CrÃ©er ou rÃ©cupÃ©rer une collaboration â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// CrÃ©e une collaboration pour [profileId] ou retourne l'existante.
  /// CrÃ©e aussi le chat de groupe si nÃ©cessaire.
  static Future<Map<String, dynamic>> createOrGetCollab({
    required String profileId,
    required String profileName,
  }) async {
    final myUid = _myUid;
    if (myUid == null) throw Exception('Non connectÃ©');

    try {
      // Chercher une collaboration existante pour ce profil et cet owner
      // IMPORTANT: inclure where('ownerId') pour satisfaire les security rules Firestore
      // (sans ce filtre, la query peut retourner des docs d'autres users â†’ permission-denied)
      final existing = await _db
          .collection('collaborations')
          .where('profileId', isEqualTo: profileId)
          .where('ownerId', isEqualTo: myUid)
          .get();

      if (existing.docs.isNotEmpty) {
        final doc = existing.docs.first;
        return {'collabId': doc.id, ...doc.data()};
      }

      // GÃ©nÃ©rer un token unique pour le lien d'invitation
      final inviteToken = const Uuid().v4().replaceAll('-', '').substring(0, 16);

      // CrÃ©er le chat de groupe
      final chatRef = _db.collection('chats').doc();
      await chatRef.set({
        'id': chatRef.id,
        'name': 'Cadeaux pour $profileName',
        'isGroup': true,
        'participants': [myUid],
        'lastMessage': 'ðŸŽ Groupe de collaboration crÃ©Ã© !',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': myUid,
        'linkedProfileId': profileId,
      });

      // Premier message dans le chat
      await chatRef.collection('messages').add({
        'senderId': 'system',
        'text': 'ðŸŽ Liste de cadeaux partagÃ©e pour $profileName. Invitez des amis pour collaborer !',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'system',
      });

      // CrÃ©er la collaboration
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

      // â”€â”€ FIX #5 : Ã©crire dans collab_tokens pour que joinByToken puisse lire
      // sans query sur collaborations (Ã©vite permission-denied sur la query)
      await _db.collection('collab_tokens').doc(inviteToken).set({
        'collabId': collabRef.id,
        'chatId': chatRef.id,
        'profileName': profileName,
        'ownerId': myUid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Mettre Ã  jour le profil avec chatId et collabId
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

      AppLogger.debug('âœ… CollaborationService: collab crÃ©Ã©e ${collabRef.id}', 'Collab');
      return {'collabId': collabRef.id, ...collabData, 'chatId': chatRef.id};
    } catch (e) {
      AppLogger.debug('âŒ CollaborationService.createOrGetCollab: $e', 'Collab');
      rethrow;
    }
  }

  // â”€â”€â”€ Inviter un utilisateur Doron â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Invite [toUid] Ã  rejoindre [collabId].
  /// Si [isAlreadyFriend] â†’ ajoute directement en membre.
  /// Sinon â†’ crÃ©e une invitation en attente.
  static Future<String> inviteUser({
    required String collabId,
    required String toUid,
    required String profileName,
    bool isAlreadyFriend = false,
  }) async {
    final myUid = _myUid;
    if (myUid == null) throw Exception('Non connectÃ©');

    try {
      if (isAlreadyFriend) {
        // Ajout direct
        await addMember(collabId: collabId, uid: toUid);
        return 'added';
      }

      // VÃ©rifier si une invitation existe dÃ©jÃ 
      // Utilise 2 filtres max pour Ã©viter l'index composite, filtre status cÃ´tÃ© client
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

      // CrÃ©er l'invitation
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

      // â”€â”€ Notification in-app : Ã©crite dans 'notifications/{toUid}/items' â”€â”€
      // DÃ©clenche aussi une Cloud Function FCM si configurÃ©e sur cette collection
      try {
        // RÃ©cupÃ©rer le nom de l'inviteur
        final senderDoc = await _db.collection('users').doc(myUid).get();
        final senderData = senderDoc.data() ?? {};
        final senderName = senderData['first_name'] as String? ??
            senderData['display_name'] as String? ??
            'Quelqu\'un';

        await _db
            .collection('notifications')
            .doc(toUid)
            .collection('items')
            .add({
          'type': 'collab_invite',
          'inviteId': inviteRef.id,
          'collabId': collabId,
          'fromUid': myUid,
          'fromName': senderName,
          'profileName': profileName,
          'title': 'ðŸŽ Invitation Ã  collaborer',
          'body': '$senderName t\'invite Ã  participer aux cadeaux pour $profileName',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        AppLogger.debug('âœ… Notification collab envoyÃ©e Ã  $toUid', 'Collab');
      } catch (e) {
        AppLogger.debug('âš ï¸ Notification collab failed (non-critical): $e', 'Collab');
      }

      AppLogger.debug('âœ… Invitation envoyÃ©e: ${inviteRef.id}', 'Collab');
      return inviteRef.id;
    } catch (e) {
      AppLogger.debug('âŒ CollaborationService.inviteUser: $e', 'Collab');
      rethrow;
    }
  }

  // â”€â”€â”€ Ajouter un membre directement â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// FIX #1 â€” addMember accepte chatId et profileName en paramÃ¨tre facultatif.
  /// Cela Ã©vite un get() sur la collab qui peut Ã©chouer si l'utilisateur
  /// n'est pas encore dans members/pendingInvites (permission-denied).
  static Future<void> addMember({
    required String collabId,
    required String uid,
    String? chatId,
    String? profileName,
  }) async {
    try {
      // â”€â”€ 1. Ajouter dans la collaboration â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      // On utilise set + merge : pas besoin de lire le doc d'abord.
      await _db.collection('collaborations').doc(collabId).set({
        'members': FieldValue.arrayUnion([uid]),
        'pendingInvites': FieldValue.arrayRemove([uid]),
      }, SetOptions(merge: true));

      // â”€â”€ 2. Si chatId non fourni, tenter de le rÃ©cupÃ©rer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      String? resolvedChatId = chatId;
      String resolvedName = profileName ?? 'la liste';

      if (resolvedChatId == null) {
        try {
          final collabDoc = await _db.collection('collaborations').doc(collabId).get();
          if (collabDoc.exists) {
            resolvedChatId = collabDoc.data()?['chatId'] as String?;
            resolvedName = collabDoc.data()?['profileName'] as String? ?? resolvedName;
          }
        } catch (e) {
          AppLogger.debug('âš ï¸ addMember: get chatId failed (non-critical): $e', 'Collab');
        }
      }

      // â”€â”€ 3. Ajouter dans le chat de groupe â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      if (resolvedChatId != null) {
        try {
          await _db.collection('chats').doc(resolvedChatId).set({
            'participants': FieldValue.arrayUnion([uid]),
          }, SetOptions(merge: true));

          // Message systÃ¨me
          await _db.collection('chats').doc(resolvedChatId).collection('messages').add({
            'senderId': 'system',
            'text': 'ðŸ‘¤ Un nouveau membre a rejoint la collaboration pour $resolvedName !',
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'system',
          });
        } catch (e) {
          AppLogger.debug('âš ï¸ addMember: chat update failed (non-critical): $e', 'Collab');
        }
      }

      AppLogger.debug('âœ… Membre $uid ajoutÃ© Ã  $collabId (chat: $resolvedChatId)', 'Collab');
    } catch (e) {
      AppLogger.debug('âŒ CollaborationService.addMember: $e', 'Collab');
      rethrow;
    }
  }

  // â”€â”€â”€ Accepter une invitation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static Future<Map<String, dynamic>> acceptInvite(String inviteId) async {
    final myUid = _myUid;
    if (myUid == null) throw Exception('Non connectÃ©');

    try {
      final inviteDoc = await _db.collection('collab_invites').doc(inviteId).get();
      final invite = inviteDoc.data();
      if (invite == null) throw Exception('Invitation introuvable');

      final collabId = invite['collabId'] as String;

      // Marquer comme acceptÃ©e
      await _db.collection('collab_invites').doc(inviteId).update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Ajouter le membre
      await addMember(collabId: collabId, uid: myUid);

      // RÃ©cupÃ©rer les infos de la collaboration
      final collabDoc = await _db.collection('collaborations').doc(collabId).get();
      final collab = collabDoc.data() ?? {};

      AppLogger.debug('âœ… Invitation acceptÃ©e: $inviteId', 'Collab');
      return {
        'collabId': collabId,
        'chatId': collab['chatId'],
        'profileName': collab['profileName'] ?? 'la liste',
      };
    } catch (e) {
      AppLogger.debug('âŒ CollaborationService.acceptInvite: $e', 'Collab');
      rethrow;
    }
  }

  // â”€â”€â”€ Refuser une invitation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
      AppLogger.debug('âŒ CollaborationService.declineInvite: $e', 'Collab');
    }
  }

  // â”€â”€â”€ Rejoindre via token (deep link) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// FIX #2 â€” joinByToken utilise la collection `collab_tokens` comme index.
  /// La query directe sur `collaborations` Ã©chouait car la rÃ¨gle Firestore
  /// ne permet pas la lecture sans Ãªtre owner/member/pendingInvite.
  /// `collab_tokens` a une rÃ¨gle allow read: if isAuth() â†’ pas de problÃ¨me.
  static Future<Map<String, dynamic>?> joinByToken(String token) async {
    final myUid = _myUid;
    if (myUid == null) return null;

    try {
      // â”€â”€ 1. Lire le token depuis la collection dÃ©diÃ©e â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      final tokenDoc = await _db.collection('collab_tokens').doc(token).get();

      if (!tokenDoc.exists) {
        // Fallback : tenter la query directe sur collaborations (anciens tokens)
        AppLogger.debug('âš ï¸ joinByToken: token absent de collab_tokens, fallback query', 'Collab');
        return await _joinByTokenFallback(token, myUid);
      }

      final tokenData = tokenDoc.data()!;
      final collabId = tokenData['collabId'] as String;
      final chatId = tokenData['chatId'] as String?;
      final profileName = tokenData['profileName'] as String? ?? 'la liste';

      // â”€â”€ 2. VÃ©rifier si dÃ©jÃ  membre â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      try {
        final collabDoc = await _db.collection('collaborations').doc(collabId).get();
        if (collabDoc.exists) {
          final members = (collabDoc.data()?['members'] as List?)?.cast<String>() ?? [];
          if (members.contains(myUid)) {
            return {
              'collabId': collabId,
              'chatId': chatId,
              'profileName': profileName,
              'alreadyMember': true,
            };
          }
        }
      } catch (_) {} // Non-critique, continuer l'ajout

      // â”€â”€ 3. Ajouter comme membre (chatId fourni â†’ pas de get() interne) â”€â”€â”€â”€â”€
      await addMember(collabId: collabId, uid: myUid, chatId: chatId, profileName: profileName);

      AppLogger.debug('âœ… Rejoint par token: $collabId', 'Collab');
      return {
        'collabId': collabId,
        'chatId': chatId,
        'profileName': profileName,
        'alreadyMember': false,
      };
    } catch (e) {
      AppLogger.debug('âŒ CollaborationService.joinByToken: $e', 'Collab');
      return null;
    }
  }

  /// Fallback pour les collaborations crÃ©Ã©es avant l'index collab_tokens.
  static Future<Map<String, dynamic>?> _joinByTokenFallback(String token, String myUid) async {
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
      final chatId = collab['chatId'] as String?;
      final profileName = collab['profileName'] as String? ?? 'la liste';
      final members = (collab['members'] as List?)?.cast<String>() ?? [];
      if (members.contains(myUid)) {
        return {'collabId': collabId, 'chatId': chatId, 'profileName': profileName, 'alreadyMember': true};
      }
      await addMember(collabId: collabId, uid: myUid, chatId: chatId, profileName: profileName);
      return {'collabId': collabId, 'chatId': chatId, 'profileName': profileName, 'alreadyMember': false};
    } catch (e) {
      AppLogger.debug('âŒ joinByToken fallback: $e', 'Collab');
      return null;
    }
  }

  // â”€â”€â”€ GÃ©nÃ©rer le lien d'invitation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// GÃ©nÃ¨re un lien d'invitation qui :
  /// 1. Ouvre l'app directement si installÃ©e (deep link)
  /// 2. Redirige vers l'App Store / Play Store sinon
  static String generateInviteLink(String inviteToken) {
    // Utilise un lien universel Apple (app_links) qui redirige vers l'app
    // ou vers l'App Store si non installÃ©e.
    // Le domaine doron.app doit Ãªtre configurÃ© avec apple-app-site-association.
    // Fallback: lien App Store direct avec le token en paramÃ¨tre.
    return 'https://doron.app/join/$inviteToken';
  }

  // â”€â”€â”€ Streams â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Stream des invitations collab reÃ§ues et en attente.
  /// FIX #6: Filtre sur toUid uniquement pour Ã©viter l'index composite (toUid+status).
  /// Le filtre status='pending' est appliquÃ© cÃ´tÃ© client.
  static Stream<List<Map<String, dynamic>>> getMyPendingCollabInvitesStream() {
    final myUid = _myUid;
    if (myUid == null) return Stream.value([]);

    return _db
        .collection('collab_invites')
        .where('toUid', isEqualTo: myUid)
        .snapshots()
        .asyncMap((snap) async {
      final result = <Map<String, dynamic>>[];
      // Filtre status cÃ´tÃ© client pour Ã©viter l'index composite
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


  /// Stream temps rÃ©el d'une collaboration.
  static Stream<Map<String, dynamic>?> getCollabStream(String collabId) {
    return _db.collection('collaborations').doc(collabId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return {'collabId': snap.id, ...snap.data()!};
    });
  }

  /// RÃ©cupÃ¨re le nombre de membres d'une collab liÃ©e Ã  un profil.
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

