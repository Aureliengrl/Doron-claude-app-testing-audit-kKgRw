import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '/utils/app_logger.dart';

/// Service qui calcule les suggestions d'amis :
/// 1. Amis d'amis (priorité haute)
/// 2. Utilisateurs Doron présents dans les contacts téléphone
class SuggestionService {
  static final _db = FirebaseFirestore.instance;

  // ─── API Publique ────────────────────────────────────────────────────────

  /// Retourne une liste de suggestions (max [limit]).
  /// Chaque map contient : uid, displayName, handle, photoUrl, source ('friend_of_friend' | 'contact')
  static Future<List<Map<String, dynamic>>> getSuggestions({int limit = 20}) async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null) return [];

    try {
      // 1. Charger mes données (friends list)
      final myDoc = await _db.collection('users').doc(me.uid).get();
      final myFriends = List<String>.from(myDoc.data()?['friends'] ?? []);
      final excluded = <String>{me.uid, ...myFriends};

      final suggestions = <String, Map<String, dynamic>>{};

      // 2. Amis d'amis
      await _addFriendsOfFriends(myFriends, excluded, suggestions);

      // 3. Contacts téléphone (si permission)
      await _addFromContacts(excluded, suggestions);

      // Filtrer ceux qui ont une demande en attente
      final filteredKeys = suggestions.keys.toList();
      // Note: on garde toutes les sources, le filtre final dans l'UI s'occupe des pending

      final result = filteredKeys.map((uid) => suggestions[uid]!).toList();
      result.sort((a, b) {
        // Priorité : amis d'amis > contacts
        final aScore = a['mutualCount'] as int? ?? 0;
        final bScore = b['mutualCount'] as int? ?? 0;
        return bScore.compareTo(aScore);
      });

      return result.take(limit).toList();
    } catch (e) {
      AppLogger.debug('❌ SuggestionService: $e', 'Social');
      return [];
    }
  }

  // ─── Amis d'amis ────────────────────────────────────────────────────────

  static Future<void> _addFriendsOfFriends(
    List<String> myFriends,
    Set<String> excluded,
    Map<String, Map<String, dynamic>> suggestions,
  ) async {
    if (myFriends.isEmpty) return;

    // On charge les friends de chacun de mes amis (par batch de 10 max Firestore)
    final batches = <List<String>>[];
    for (int i = 0; i < myFriends.length; i += 10) {
      batches.add(myFriends.sublist(i, i + 10 > myFriends.length ? myFriends.length : i + 10));
    }

    for (final batch in batches) {
      final snap = await _db.collection('users')
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      for (final friendDoc in snap.docs) {
        final theirFriends = List<String>.from(friendDoc.data()['friends'] ?? []);
        for (final candidateUid in theirFriends) {
          if (excluded.contains(candidateUid)) continue;

          if (suggestions.containsKey(candidateUid)) {
            // Incrémenter le compteur d'amis communs
            suggestions[candidateUid]!['mutualCount'] =
                (suggestions[candidateUid]!['mutualCount'] as int) + 1;
          } else {
            suggestions[candidateUid] = {
              'uid': candidateUid,
              'source': 'friend_of_friend',
              'mutualCount': 1,
            };
          }
        }
      }
    }

    // Charger les profils des candidats trouvés
    final toFetch = suggestions.keys
        .where((uid) => suggestions[uid]!['displayName'] == null)
        .toList();

    if (toFetch.isEmpty) return;

    for (int i = 0; i < toFetch.length; i += 10) {
      final batch = toFetch.sublist(i, i + 10 > toFetch.length ? toFetch.length : i + 10);
      final profileSnap = await _db.collection('users')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      for (final doc in profileSnap.docs) {
        final d = doc.data();
        if (suggestions.containsKey(doc.id)) {
          suggestions[doc.id]!['displayName'] = d['display_name'] ?? d['displayName'] ?? 'Utilisateur';
          suggestions[doc.id]!['handle'] = d['handle'] ?? '';
          suggestions[doc.id]!['photoUrl'] = d['photo_url'] ?? d['photoUrl'] ?? '';
        }
      }
    }
  }

  // ─── Contacts téléphone ─────────────────────────────────────────────────

  static Future<void> _addFromContacts(
    Set<String> excluded,
    Map<String, Map<String, dynamic>> suggestions,
  ) async {
    try {
      // Demande la permission contacts
      if (!await FlutterContacts.requestPermission(readonly: true)) return;

      final contacts = await FlutterContacts.getContacts(withProperties: true);
      // Extraire tous les numéros de téléphone normalisés
      final phones = <String>{};
      for (final contact in contacts) {
        for (final phone in contact.phones) {
          final normalized = phone.number.replaceAll(RegExp(r'[\s\-\(\)]'), '');
          if (normalized.isNotEmpty) phones.add(normalized);
        }
      }

      if (phones.isEmpty) return;

      // Chercher dans Firestore les utilisateurs avec ces numéros
      // (le champ phoneNumber doit être stocké dans le document user)
      final batches = phones.toList();
      for (int i = 0; i < batches.length; i += 10) {
        final batch = batches.sublist(i, i + 10 > batches.length ? batches.length : i + 10);
        final snap = await _db.collection('users')
            .where('phoneNumber', whereIn: batch)
            .limit(10)
            .get();

        for (final doc in snap.docs) {
          final uid = doc.id;
          if (excluded.contains(uid)) continue;
          if (suggestions.containsKey(uid)) {
            // Déjà en suggestion (ami d'ami), marquer aussi comme contact
            suggestions[uid]!['source'] = 'friend_of_friend_and_contact';
          } else {
            final d = doc.data();
            suggestions[uid] = {
              'uid': uid,
              'source': 'contact',
              'mutualCount': 0,
              'displayName': d['display_name'] ?? d['displayName'] ?? 'Utilisateur',
              'handle': d['handle'] ?? '',
              'photoUrl': d['photo_url'] ?? d['photoUrl'] ?? '',
            };
          }
        }
      }
    } catch (e) {
      AppLogger.debug('⚠️ Contacts suggestions: $e', 'Social');
    }
  }
}
