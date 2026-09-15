import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/services/firebase_data_service.dart';
import '/utils/app_logger.dart';

/// Service pour bloquer et signaler des utilisateurs.
class BlockService {
  static final _db = FirebaseFirestore.instance;
  static String? get _myUid => FirebaseDataService.currentUserId;

  /// Bloque un utilisateur. Ajoute à la liste blocked du user courant.
  static Future<bool> blockUser(String otherUid) async {
    final myUid = _myUid;
    if (myUid == null || myUid == otherUid) return false;
    try {
      await _db.collection('users').doc(myUid).update({
        'blockedUsers': FieldValue.arrayUnion([otherUid]),
      });
      // Also remove from friends if they were friends
      await _db.collection('users').doc(myUid).update({
        'friends': FieldValue.arrayRemove([otherUid]),
      });
      await _db.collection('users').doc(otherUid).update({
        'friends': FieldValue.arrayRemove([myUid]),
      });
      AppLogger.debug('Block user $otherUid', 'Social');
      return true;
    } catch (e) {
      AppLogger.debug('BlockService.blockUser error: $e', 'Social');
      return false;
    }
  }

  /// Débloque un utilisateur.
  static Future<bool> unblockUser(String otherUid) async {
    final myUid = _myUid;
    if (myUid == null) return false;
    try {
      await _db.collection('users').doc(myUid).update({
        'blockedUsers': FieldValue.arrayRemove([otherUid]),
      });
      return true;
    } catch (e) {
      AppLogger.debug('BlockService.unblockUser error: $e', 'Social');
      return false;
    }
  }

  /// Vérifie si un utilisateur est bloqué.
  static Future<bool> isBlocked(String otherUid) async {
    final myUid = _myUid;
    if (myUid == null) return false;
    try {
      final doc = await _db.collection('users').doc(myUid).get();
      final blocked = (doc.data()?['blockedUsers'] as List?)?.cast<String>() ?? [];
      return blocked.contains(otherUid);
    } catch (_) {
      return false;
    }
  }

  /// Récupère la liste des UIDs bloqués.
  static Future<List<String>> getBlockedUsers() async {
    final myUid = _myUid;
    if (myUid == null) return [];
    try {
      final doc = await _db.collection('users').doc(myUid).get();
      return (doc.data()?['blockedUsers'] as List?)?.cast<String>() ?? [];
    } catch (_) {
      return [];
    }
  }

  /// Signale un utilisateur avec une raison.
  static Future<bool> reportUser(String otherUid, String reason, {String? details}) async {
    final myUid = _myUid;
    if (myUid == null) return false;
    try {
      await _db.collection('reports').add({
        'reporterUid': myUid,
        'reportedUid': otherUid,
        'reason': reason,
        'details': details ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      AppLogger.debug('Report user $otherUid for $reason', 'Social');
      return true;
    } catch (e) {
      AppLogger.debug('BlockService.reportUser error: $e', 'Social');
      return false;
    }
  }
}
