import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '/services/firebase_data_service.dart';
import '/utils/app_logger.dart';

/// Service de collaboration sur les listes de cadeaux.
/// Gère : création, invitations, deep links, gestion du chat de groupe.
class CollaborationService {
  static final _db = FirebaseFirestore.instance;
  static String? get _myUid => FirebaseDataService.currentUserId;

  // â”€â”€â”€ Créer ou récupérer une collaboration â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Crée une collaboration pour [profileId] ou retourne l'existante.
  /// Crée aussi le chat de groupe si nécessaire.
  static Future<Map<String, dynamic>> createOrGetCollab({
    required String profileId,
    required String profileName,
    String mode = 'simple', // 'simple' (collab classique) | 'group_gift' (cagnotte)
    Map<String, dynamic>? personData,
    List<Map<String, dynamic>>? gifts,
  }) async {
    final myUid = _myUid;
    if (myUid == null) throw Exception('Non connecté');

    try {
      // Récupérer le nom de l'hôte pour l'afficher aux invités
      String ownerName = 'Un ami';
      try {
        final uDoc = await _db.collection('users').doc(myUid).get();
        final uData = uDoc.data();
        if (uData != null) {
          ownerName = uData['first_name'] as String? ??
              uData['display_name'] as String? ??
              uData['name'] as String? ??
              FirebaseAuth.instance.currentUser?.displayName ??
              'Un ami';
        }
      } catch (_) {}

      // S'assurer que gifts contient bien les cadeaux du profil (fallback vers la liste existante de l'owner)
      List<Map<String, dynamic>> finalGifts = gifts != null ? List<Map<String, dynamic>>.from(gifts) : [];
      if (finalGifts.isEmpty) {
        try {
          final listData = await FirebaseDataService.loadLatestGiftListForPerson(profileId);
          final rawG = listData?['gifts'] as List?;
          if (rawG != null && rawG.isNotEmpty) {
            finalGifts = rawG.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}).where((m) => m.isNotEmpty).toList();
            AppLogger.debug('🎁 ${finalGifts.length} cadeaux récupérés pour la collab depuis le profil', 'Collab');
          }
        } catch (e) {
          AppLogger.debug('Fallback loadLatestGiftListForPerson error in createOrGetCollab: $e', 'Collab');
        }
      }

      // Chercher une collaboration existante pour ce profil dont je suis déjà
      // membre (peu importe qui est l'hôte). Sans ce filtre, un membre non
      // créateur ne retrouvait jamais la collab existante (la recherche ne
      // portait que sur ownerId == moi) et en recréait une en double.
      var existing = await _db
          .collection('collaborations')
          .where('profileId', isEqualTo: profileId)
          .where('members', arrayContains: myUid)
          .get();

      // Sinon, cas du créateur avant qu'il ne soit techniquement listé comme
      // membre (ou collab créée par un autre mécanisme) : chercher par ownerId.
      if (existing.docs.isEmpty) {
        existing = await _db
            .collection('collaborations')
            .where('profileId', isEqualTo: profileId)
            .where('ownerId', isEqualTo: myUid)
            .get();
      }

      if (existing.docs.isNotEmpty) {
        final doc = existing.docs.first;
        final updates = <String, dynamic>{
          'ownerName': ownerName,
        };
        if (personData != null && personData.isNotEmpty) {
          updates['personData'] = personData;
        }
        if (finalGifts.isNotEmpty) {
          updates['gifts'] = finalGifts;
        }
        await doc.reference.set(updates, SetOptions(merge: true));
        return {'collabId': doc.id, ...doc.data(), ...updates};
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
      try {
        await chatRef.collection('messages').add({
          'senderId': myUid,
          'text': '🎁 Liste de cadeaux partagée pour $profileName. Invitez des amis pour collaborer !',
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'system',
        });
      } catch (e) {
        AppLogger.debug('Premier message chat: $e', 'Collab');
      }

      // Créer la collaboration
      final collabRef = _db.collection('collaborations').doc();
      final collabData = {
        'profileId': profileId,
        'profileName': profileName,
        'ownerId': myUid,
        'ownerName': ownerName,
        'mode': mode,
        'members': [myUid],
        'pendingInvites': <String>[],
        'chatId': chatRef.id,
        'inviteToken': inviteToken,
        if (personData != null) 'personData': personData,
        if (finalGifts.isNotEmpty) 'gifts': finalGifts,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await collabRef.set(collabData);

      // Écrire dans collab_tokens pour que joinByToken puisse lire
      try {
        await _db.collection('collab_tokens').doc(inviteToken).set({
          'collabId': collabRef.id,
          'chatId': chatRef.id,
          'profileName': profileName,
          'ownerId': myUid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        AppLogger.debug('collab_tokens error: $e', 'Collab');
      }

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
          'giftMode': mode,
        }, SetOptions(merge: true));
      } catch (e) { AppLogger.debug('CollaborationService error: $e', 'Collab'); }

      AppLogger.debug('✅ CollaborationService: collab créée ${collabRef.id}', 'Collab');
      return {'collabId': collabRef.id, ...collabData, 'chatId': chatRef.id};
    } catch (e) {
      AppLogger.debug('âŒ CollaborationService.createOrGetCollab: $e', 'Collab');
      rethrow;
    }
  }

  // â”€â”€â”€ Inviter un utilisateur Doron â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

      // ——— Notification in-app : écrite dans 'notifications/{toUid}/items' ———
      // Déclenche aussi une Cloud Function FCM si configurée sur cette collection
      try {
        // Récupérer le nom de l'inviteur
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
          'title': '🎁 Invitation à collaborer',
          'body': '$senderName t\'invite à participer aux cadeaux pour $profileName',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        AppLogger.debug('✅ Notification collab envoyée à $toUid', 'Collab');
      } catch (e) {
        AppLogger.debug('⚠️ Notification collab failed (non-critical): $e', 'Collab');
      }

      AppLogger.debug('✅ Invitation envoyée: ${inviteRef.id}', 'Collab');
      return inviteRef.id;
    } catch (e) {
      AppLogger.debug('❌ CollaborationService.inviteUser: $e', 'Collab');
      rethrow;
    }
  }

  // ——— Ajouter un membre directement ——————————————————————————————————————————

  /// FIX #1 — addMember accepte chatId et profileName en paramètre facultatif.
  /// Cela évite un get() sur la collab qui peut échouer si l'utilisateur
  /// n'est pas encore dans members/pendingInvites (permission-denied).
  static Future<void> addMember({
    required String collabId,
    required String uid,
    String? chatId,
    String? profileName,
  }) async {
    try {
      // ——— 1. Ajouter dans la collaboration ——————————————————————————————————
      // On utilise set + merge : pas besoin de lire le doc d'abord.
      await _db.collection('collaborations').doc(collabId).set({
        'members': FieldValue.arrayUnion([uid]),
        'pendingInvites': FieldValue.arrayRemove([uid]),
      }, SetOptions(merge: true));

      // ——— 2. Si chatId non fourni, tenter de le récupérer ———————————————————
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
          AppLogger.debug('⚠️ addMember: get chatId failed (non-critical): $e', 'Collab');
        }
      }

      // ——— 3. Ajouter dans le chat de groupe —————————————————————————————————
      if (resolvedChatId != null) {
        try {
          await _db.collection('chats').doc(resolvedChatId).set({
            'participants': FieldValue.arrayUnion([uid]),
          }, SetOptions(merge: true));

          // Message système
          await _db.collection('chats').doc(resolvedChatId).collection('messages').add({
            'senderId': 'system',
            'text': 'ðŸ‘¤ Un nouveau membre a rejoint la collaboration pour $resolvedName !',
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'system',
          });
        } catch (e) {
          AppLogger.debug('âš ï¸ addMember: chat update failed (non-critical): $e', 'Collab');
          AppLogger.debug('âš ï¸  addMember: chat update failed (non-critical): $e', 'Collab');
        }
      }

      AppLogger.debug('✅ Membre $uid ajouté à $collabId (chat: $resolvedChatId)', 'Collab');
    } catch (e) {
      AppLogger.debug('â Œ CollaborationService.addMember: $e', 'Collab');
      rethrow;
    }
  }

  /// Synchronise les cadeaux d'une collaboration avec tous les membres
  static Future<void> syncGiftsToCollab({
    required String collabId,
    required List<Map<String, dynamic>> gifts,
  }) async {
    try {
      await _db.collection('collaborations').doc(collabId).set({
        'gifts': gifts,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      AppLogger.debug('✅ Cadeaux synchronisés avec la collab $collabId (${gifts.length} cadeaux)', 'Collab');
    } catch (e) {
      AppLogger.debug('⚠️ syncGiftsToCollab error: $e', 'Collab');
    }
  }

  /// Permet à un utilisateur de quitter une collaboration
  static Future<void> leaveCollaboration({
    required String collabId,
    String? chatId,
    String? profileId,
  }) async {
    final myUid = _myUid;
    if (myUid == null) return;
    try {
      // 1. Retirer de collaborations.members
      await _db.collection('collaborations').doc(collabId).update({
        'members': FieldValue.arrayRemove([myUid]),
      });

      // 2. Retirer de chats.participants si chatId fourni ou résolu
      String? resolvedChatId = chatId;
      if (resolvedChatId == null) {
        final doc = await _db.collection('collaborations').doc(collabId).get();
        resolvedChatId = doc.data()?['chatId'] as String?;
      }
      if (resolvedChatId != null && resolvedChatId.isNotEmpty) {
        await _db.collection('chats').doc(resolvedChatId).update({
          'participants': FieldValue.arrayRemove([myUid]),
        });
      }

      // 3. Supprimer la copie locale du profil si existante
      if (profileId != null && profileId.isNotEmpty) {
        await FirebaseDataService.deletePerson(profileId);
      }
      AppLogger.info('Membre $myUid a quitté la collaboration $collabId', 'Collab');
    } catch (e) {
      AppLogger.error('Erreur leaveCollaboration: $e', 'Collab');
      rethrow;
    }
  }

  /// Retire un membre de la collaboration et du chat associé
  static Future<void> removeMember({
    required String collabId,
    required String uid,
  }) async {
    try {
      final doc = await _db.collection('collaborations').doc(collabId).get();
      final chatId = doc.data()?['chatId'] as String?;

      await _db.collection('collaborations').doc(collabId).update({
        'members': FieldValue.arrayRemove([uid]),
      });

      if (chatId != null && chatId.isNotEmpty) {
        await _db.collection('chats').doc(chatId).update({
          'participants': FieldValue.arrayRemove([uid]),
        });
      }
      AppLogger.debug('✅ Membre $uid retiré de $collabId', 'Collab');
    } catch (e) {
      AppLogger.debug('⚠️ removeMember error: $e', 'Collab');
    }
  }

  // â”€â”€â”€ Accepter une invitation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  /// Lit les informations d'un lien d'invitation SANS rejoindre la
  /// collaboration — utilisé pour afficher l'écran de confirmation
  /// « veux-tu rejoindre la liste de X ? » avant tout engagement.
  /// Le rejoint effectif se fait ensuite via [joinByToken], après acceptation.
  static Future<Map<String, dynamic>?> previewInviteToken(String token) async {
    final myUid = _myUid;
    if (myUid == null) return null;

    try {
      String? collabId;
      String? chatId;
      String? profileName;

      final tokenDoc = await _db.collection('collab_tokens').doc(token).get();
      if (tokenDoc.exists) {
        final data = tokenDoc.data()!;
        collabId = data['collabId'] as String?;
        chatId = data['chatId'] as String?;
        profileName = data['profileName'] as String?;
      } else {
        // Fallback pour les anciens tokens non indexés dans collab_tokens.
        final snap = await _db
            .collection('collaborations')
            .where('inviteToken', isEqualTo: token)
            .limit(1)
            .get();
        if (snap.docs.isEmpty) return null;
        collabId = snap.docs.first.id;
        final data = snap.docs.first.data();
        chatId = data['chatId'] as String?;
        profileName = data['profileName'] as String?;
      }
      if (collabId == null) return null;

      bool alreadyMember = false;
      String ownerName = 'Un ami';
      try {
        final collabDoc = await _db.collection('collaborations').doc(collabId).get();
        if (collabDoc.exists) {
          final data = collabDoc.data()!;
          final members = (data['members'] as List?)?.cast<String>() ?? [];
          alreadyMember = members.contains(myUid);
          ownerName = data['ownerName'] as String? ?? ownerName;
          profileName ??= data['profileName'] as String?;
          chatId ??= data['chatId'] as String?;
        }
      } catch (_) {} // non-critique : on garde les infos du token

      return {
        'collabId': collabId,
        'chatId': chatId,
        'profileName': profileName ?? 'la liste',
        'ownerName': ownerName,
        'alreadyMember': alreadyMember,
      };
    } catch (e) {
      AppLogger.debug('❌ CollaborationService.previewInviteToken: $e', 'Collab');
      return null;
    }
  }

  /// FIX #2 "” joinByToken utilise la collection `collab_tokens` comme index.
  /// La query directe sur `collaborations` échouait car la règle Firestore
  /// ne permet pas la lecture sans être owner/member/pendingInvite.
  /// `collab_tokens` a une règle allow read: if isAuth() → pas de problème.
  static Future<Map<String, dynamic>?> joinByToken(String token) async {
    final myUid = _myUid;
    if (myUid == null) return null;

    try {
      // â”€â”€ 1. Lire le token depuis la collection dédiée â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

      // â”€â”€ 2. Vérifier si déjà membre â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

      // â”€â”€ 3. Ajouter comme membre (chatId fourni → pas de get() interne) â”€â”€â”€â”€â”€
      await addMember(collabId: collabId, uid: myUid, chatId: chatId, profileName: profileName);

      AppLogger.debug('✅ Rejoint par token: $collabId', 'Collab');
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

  /// Fallback pour les collaborations créées avant l'index collab_tokens.
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

  // â”€â”€â”€ Générer le lien d'invitation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  // â”€â”€â”€ Streams â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Stream des invitations collab reçues et en attente.
  /// FIX #6: Filtre sur toUid uniquement pour éviter l'index composite (toUid+status).
  /// Le filtre status='pending' est appliqué côté client.
  static Stream<List<Map<String, dynamic>>> getMyPendingCollabInvitesStream() {
    // Réagit aux changements d'état d'authentification plutôt que de figer
    // définitivement le flux sur l'uid disponible au moment de l'appel.
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
      final myUid = user?.uid ?? _myUid;
      if (myUid == null) return Stream.value(<Map<String, dynamic>>[]);

      return _db
          .collection('collab_invites')
          .where('toUid', isEqualTo: myUid)
          .snapshots()
          .asyncMap((snap) async {
        // Filtre status côté client pour éviter l'index composite
        final pendingDocs = snap.docs
            .where((d) => d.data()['status'] == 'pending')
            .toList();
        // Lectures des profils expéditeurs en parallèle avec timeout, pour
        // qu'une lecture lente ne bloque pas l'affichage des autres invitations.
        final result = await Future.wait(pendingDocs.map((doc) async {
          final data = doc.data();
          try {
            final senderDoc = await _db
                .collection('users')
                .doc(data['fromUid'])
                .get()
                .timeout(const Duration(seconds: 6));
            final sender = senderDoc.data() ?? {};
            return {
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
            };
          } catch (e) {
            AppLogger.debug('CollaborationService error: $e', 'Collab');
            return {
              'inviteId': doc.id,
              'collabId': data['collabId'],
              'fromUid': data['fromUid'],
              'profileName': data['profileName'] ?? 'une liste',
              'fromName': 'Quelqu\'un',
              'fromPhotoUrl': '',
              'createdAt': data['createdAt'],
            };
          }
        }));
        return result;
      });
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

