import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '/utils/app_logger.dart';

/// Modèle léger pour un groupe Secret Santa.
class SecretSantaGroup {
  final String id;
  final String name;
  final String mode;
  final Map<String, int> budget;
  final String status;
  final String theme;
  final String createdBy;
  final String inviteToken;
  final List<String> participantUids;
  final DateTime? createdAt;

  const SecretSantaGroup({
    required this.id,
    required this.name,
    required this.mode,
    required this.budget,
    required this.status,
    required this.theme,
    required this.createdBy,
    required this.inviteToken,
    required this.participantUids,
    this.createdAt,
  });

  factory SecretSantaGroup.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SecretSantaGroup(
      id: doc.id,
      name: d['name'] as String? ?? '',
      mode: d['mode'] as String? ?? 'personal',
      budget: Map<String, int>.from(d['budget'] as Map? ?? {'min': 0, 'max': 50}),
      status: d['status'] as String? ?? 'open',
      theme: d['theme'] as String? ?? 'christmas',
      createdBy: d['createdBy'] as String? ?? '',
      inviteToken: d['inviteToken'] as String? ?? '',
      participantUids: List<String>.from(d['participantUids'] as List? ?? []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  bool get isOpen => status == 'open';
  bool get isDrawn => status == 'drawn';
  bool get isRevealed => status == 'revealed';

  String get themeEmoji {
    switch (theme) {
      case 'christmas': return '🎄';
      case 'winter': return '❄️';
      case 'birthday': return '🎂';
      case 'corporate': return '💼';
      default: return '🎁';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'open': return 'En attente';
      case 'drawn': return 'Tirage effectué';
      case 'revealed': return 'Révélé';
      default: return status;
    }
  }
}

/// Service Secret Santa — gestion des groupes, participants, tirage.
class SecretSantaService {
  static final _db = FirebaseFirestore.instance;
  static String? get _myUid => FirebaseAuth.instance.currentUser?.uid;

  // ── Créer un groupe ─────────────────────────────────────────────────────────

  static Future<String> createGroup({
    required String name,
    required String mode,
    required int budgetMin,
    required int budgetMax,
    required String theme,
    DateTime? deadline,
    DateTime? revealDate,
    List<List<String>> exclusions = const [],
  }) async {
    final myUid = _myUid;
    if (myUid == null) throw Exception('Non connecté');

    final inviteToken = const Uuid().v4().replaceAll('-', '').substring(0, 12);

    // Récupérer le profil de l'organisateur pour le pré-remplir
    final userDoc = await _db.collection('users').doc(myUid).get();
    final userData = userDoc.data() ?? {};
    final displayName = userData['display_name'] ?? userData['first_name'] ?? 'Organisateur';
    final photoUrl = userData['photo_url'] ?? userData['photoUrl'] ?? '';

    final groupRef = _db.collection('secret_santa_groups').doc();
    final now = FieldValue.serverTimestamp();

    final groupData = {
      'name': name,
      'mode': mode,
      'budget': {'min': budgetMin, 'max': budgetMax},
      'theme': theme,
      'status': 'open',
      'createdBy': myUid,
      'createdAt': now,
      'inviteToken': inviteToken,
      'participantUids': [myUid],
      'exclusions': exclusions,
      if (deadline != null) 'deadline': Timestamp.fromDate(deadline),
      if (revealDate != null) 'revealDate': Timestamp.fromDate(revealDate),
    };

    final batch = _db.batch();

    // Créer le groupe
    batch.set(groupRef, groupData);

    // Ajouter l'organisateur comme premier participant
    batch.set(groupRef.collection('participants').doc(myUid), {
      'displayName': displayName,
      'photoUrl': photoUrl,
      'joinedAt': now,
      'hasBought': false,
      'isOrganizer': true,
    });

    // Index token pour les deep links
    batch.set(_db.collection('ss_tokens').doc(inviteToken), {
      'groupId': groupRef.id,
      'groupName': name,
      'createdBy': myUid,
      'createdAt': now,
    });

    await batch.commit();

    AppLogger.debug('✅ SecretSanta: groupe créé ${groupRef.id}', 'SS');
    return groupRef.id;
  }

  // ── Rejoindre via token ─────────────────────────────────────────────────────

  static Future<String?> joinByToken(String token) async {
    final myUid = _myUid;
    if (myUid == null) return null;

    try {
      final tokenDoc = await _db.collection('ss_tokens').doc(token).get();
      if (!tokenDoc.exists) {
        AppLogger.debug('⚠️ SS joinByToken: token invalide $token', 'SS');
        return null;
      }

      final groupId = tokenDoc.data()!['groupId'] as String;
      final groupDoc = await _db.collection('secret_santa_groups').doc(groupId).get();
      if (!groupDoc.exists) return null;

      final group = groupDoc.data()!;
      final uids = List<String>.from(group['participantUids'] as List? ?? []);

      if (uids.contains(myUid)) return groupId; // Déjà membre

      // Récupérer le profil
      final userDoc = await _db.collection('users').doc(myUid).get();
      final userData = userDoc.data() ?? {};
      final displayName = userData['display_name'] ?? userData['first_name'] ?? 'Participant';
      final photoUrl = userData['photo_url'] ?? userData['photoUrl'] ?? '';

      final batch = _db.batch();
      batch.update(_db.collection('secret_santa_groups').doc(groupId), {
        'participantUids': FieldValue.arrayUnion([myUid]),
      });
      batch.set(
        _db.collection('secret_santa_groups').doc(groupId).collection('participants').doc(myUid),
        {
          'displayName': displayName,
          'photoUrl': photoUrl,
          'joinedAt': FieldValue.serverTimestamp(),
          'hasBought': false,
          'isOrganizer': false,
        },
      );
      await batch.commit();

      AppLogger.debug('✅ SS joinByToken: rejoint $groupId', 'SS');
      return groupId;
    } catch (e) {
      AppLogger.debug('❌ SS joinByToken: $e', 'SS');
      return null;
    }
  }

  // ── Tirage au sort (Fisher-Yates avec exclusions) ───────────────────────────
  // Inspiré d'Elfster : tirage côté client par l'organisateur.
  // Simple et efficace pour le MVP.

  static Future<bool> performDraw(String groupId) async {
    final myUid = _myUid;
    if (myUid == null) return false;

    try {
      final groupDoc = await _db.collection('secret_santa_groups').doc(groupId).get();
      final group = groupDoc.data()!;

      if (group['createdBy'] != myUid) throw Exception('Seul l\'organisateur peut lancer le tirage');
      if (group['status'] != 'open') throw Exception('Le tirage a déjà eu lieu');

      final uids = List<String>.from(group['participantUids'] as List);
      if (uids.length < 2) throw Exception('Il faut au moins 2 participants');

      final exclusions = (group['exclusions'] as List? ?? [])
          .map((e) => List<String>.from(e as List))
          .toList();

      // Algorithme de tirage avec retry pour respecter les exclusions
      List<String>? assignment;
      int attempts = 0;
      while (attempts < 100) {
        final shuffled = List<String>.from(uids)..shuffle();
        bool valid = true;

        for (int i = 0; i < uids.length; i++) {
          final giver = uids[i];
          final receiver = shuffled[i];

          // Un participant ne peut pas se tirer lui-même
          if (giver == receiver) { valid = false; break; }

          // Vérifier les règles d'exclusion
          for (final excl in exclusions) {
            if ((excl[0] == giver && excl[1] == receiver) ||
                (excl[1] == giver && excl[0] == receiver)) {
              valid = false;
              break;
            }
          }
          if (!valid) break;
        }

        if (valid) { assignment = shuffled; break; }
        attempts++;
      }

      if (assignment == null) throw Exception('Impossible de générer un tirage valide (contraintes trop strictes)');

      // Écrire les paires dans Firestore et créer un "rond" (personne) pour chaque giver
      final batch = _db.batch();
      for (int i = 0; i < uids.length; i++) {
        final giver = uids[i];
        final receiver = assignment[i];

        // Récupérer le nom du receiver
        final receiverParticipant = await _db
            .collection('secret_santa_groups')
            .doc(groupId)
            .collection('participants')
            .doc(receiver)
            .get();
        final receiverName = receiverParticipant.data()?['displayName'] ?? 'Quelqu\'un';

        batch.set(
          _db.collection('secret_santa_groups').doc(groupId).collection('pairs').doc(giver),
          {
            'assignedToUid': receiver,
            'assignedToName': receiverName,
            'assignedAt': FieldValue.serverTimestamp(),
          },
        );

        // Création automatique du "rond" (personne) pour l'IA Doron
        final personId = const Uuid().v4();
        final personData = {
          'id': personId,
          'meta': {
            'createdAt': FieldValue.serverTimestamp(),
            'isPendingFirstGen': false,
          },
          'tags': {
            'name': receiverName,
            'isSecretSanta': true,
            'secretSantaGroupId': groupId,
            'secretSantaTargetUid': receiver,
            'occasion': group['theme'],
            'budgetTier': 'Secret Santa (Max ${group['budget'] != null ? group['budget']['max'] : 50}€)',
          }
        };
        
        batch.set(
          _db.collection('users').doc(giver).collection('people').doc(personId),
          personData,
        );
      }

      // Mettre à jour le statut du groupe
      batch.update(_db.collection('secret_santa_groups').doc(groupId), {
        'status': 'drawn',
        'drawnAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      AppLogger.debug('✅ SS performDraw: tirage effectué pour $groupId', 'SS');
      return true;
    } catch (e) {
      AppLogger.debug('❌ SS performDraw: $e', 'SS');
      rethrow;
    }
  }

  // ── Lire ma paire ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getMyPair(String groupId) async {
    final myUid = _myUid;
    if (myUid == null) return null;

    try {
      final pairDoc = await _db
          .collection('secret_santa_groups')
          .doc(groupId)
          .collection('pairs')
          .doc(myUid)
          .get();

      if (!pairDoc.exists) return null;
      return {'id': pairDoc.id, ...pairDoc.data()!};
    } catch (e) {
      AppLogger.debug('❌ SS getMyPair: $e', 'SS');
      return null;
    }
  }

  // ── Marquer comme acheté ───────────────────────────────────────────────────

  static Future<void> markBought(String groupId) async {
    final myUid = _myUid;
    if (myUid == null) return;

    await _db
        .collection('secret_santa_groups')
        .doc(groupId)
        .collection('participants')
        .doc(myUid)
        .update({'hasBought': true, 'boughtAt': FieldValue.serverTimestamp()});
  }

  // ── Récupérer les participants ─────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getParticipants(String groupId) async {
    try {
      final snap = await _db
          .collection('secret_santa_groups')
          .doc(groupId)
          .collection('participants')
          .get();
      return snap.docs.map((d) => {'uid': d.id, ...d.data()}).toList();
    } catch (e) {
      AppLogger.debug('❌ SS getParticipants: $e', 'SS');
      return [];
    }
  }

  // ── Stream de mes groupes ──────────────────────────────────────────────────

  static Stream<List<SecretSantaGroup>> getMyGroupsStream() {
    final myUid = _myUid;
    if (myUid == null) return Stream.value([]);

    return _db
        .collection('secret_santa_groups')
        .where('participantUids', arrayContains: myUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(SecretSantaGroup.fromFirestore).toList());
  }

  // ── Stream d'un groupe ─────────────────────────────────────────────────────

  static Stream<SecretSantaGroup?> getGroupStream(String groupId) {
    return _db
        .collection('secret_santa_groups')
        .doc(groupId)
        .snapshots()
        .map((doc) => doc.exists ? SecretSantaGroup.fromFirestore(doc) : null);
  }

  // ── Lien d'invitation ──────────────────────────────────────────────────────

  static String getInviteLink(String token) => 'https://doron.app/ss/$token';

  // ── Récupérer la wishlist publique d'un user dans un budget ───────────────

  static Future<List<Map<String, dynamic>>> getWishlistItemsInBudget({
    required String targetUid,
    required int budgetMax,
  }) async {
    try {
      // Récupérer les wishlists publiques du target
      final wishlistsSnap = await _db
          .collection('users')
          .doc(targetUid)
          .collection('wishlists')
          .where('isPublic', isEqualTo: true)
          .get();

      final items = <Map<String, dynamic>>[];

      for (final wl in wishlistsSnap.docs) {
        final productsSnap = await wl.reference.collection('products').get();
        for (final p in productsSnap.docs) {
          final data = p.data();
          final price = (data['price'] ?? data['prix'] ?? 0);
          final priceNum = price is num ? price.toDouble() : double.tryParse(price.toString()) ?? 0;

          // Filtrer par budget (tolérance 10%)
          if (priceNum <= budgetMax * 1.1) {
            items.add({
              'id': p.id,
              'wishlistId': wl.id,
              ...data,
              'price': priceNum,
            });
          }
        }
      }

      // Trier par prix croissant
      items.sort((a, b) => (a['price'] as double).compareTo(b['price'] as double));
      return items;
    } catch (e) {
      AppLogger.debug('❌ SS getWishlistItemsInBudget: $e', 'SS');
      return [];
    }
  }

  // ── Récupérer les infos d'un participant ───────────────────────────────────

  static Future<Map<String, dynamic>?> getParticipantProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return {'uid': uid, ...doc.data()!};
    } catch (e) {
      return null;
    }
  }

  // ── Quitter un groupe ──────────────────────────────────────────────────────

  static Future<void> leaveGroup(String groupId) async {
    final myUid = _myUid;
    if (myUid == null) return;

    final batch = _db.batch();
    batch.update(_db.collection('secret_santa_groups').doc(groupId), {
      'participantUids': FieldValue.arrayRemove([myUid]),
    });
    batch.delete(
      _db.collection('secret_santa_groups').doc(groupId).collection('participants').doc(myUid),
    );
    await batch.commit();
  }
}
