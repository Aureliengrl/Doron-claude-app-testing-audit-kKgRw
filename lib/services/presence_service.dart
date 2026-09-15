import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import '/utils/app_logger.dart';
import '/services/firebase_data_service.dart';

/// Service de présence en ligne — met à jour `lastSeen` et `isOnline`
/// dans le document utilisateur Firestore.
class PresenceService with WidgetsBindingObserver {
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  static final _db = FirebaseFirestore.instance;
  Timer? _heartbeatTimer;
  bool _initialized = false;

  /// Initialise le service. À appeler une fois après le login.
  void initialize() {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    _goOnline();
    // Heartbeat toutes les 60 secondes
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _goOnline(),
    );
  }

  /// Nettoie le service. À appeler au logout.
  void dispose() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    WidgetsBinding.instance.removeObserver(this);
    _goOffline();
    _initialized = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _goOnline();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _goOffline();
        break;
    }
  }

  static Future<void> _goOnline() async {
    final uid = FirebaseDataService.currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.debug('PresenceService._goOnline: $e', 'Presence');
    }
  }

  static Future<void> _goOffline() async {
    final uid = FirebaseDataService.currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.debug('PresenceService._goOffline: $e', 'Presence');
    }
  }

  /// Formate le statut de présence pour l'affichage.
  /// Retourne "En ligne" ou "Vu il y a X min/h/j".
  static String formatPresence({bool? isOnline, Timestamp? lastSeen}) {
    if (isOnline == true) return 'En ligne';
    if (lastSeen == null) return '';

    final now = DateTime.now();
    final seen = lastSeen.toDate();
    final diff = now.difference(seen);

    if (diff.inMinutes < 1) return 'Vu à l\'instant';
    if (diff.inMinutes < 60) return 'Vu il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Vu il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Vu il y a ${diff.inDays}j';
    return 'Vu le ${seen.day.toString().padLeft(2, '0')}/${seen.month.toString().padLeft(2, '0')}';
  }

  /// Stream du statut de présence d'un utilisateur.
  static Stream<Map<String, dynamic>> presenceStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) {
      final data = snap.data();
      return {
        'isOnline': data?['isOnline'] ?? false,
        'lastSeen': data?['lastSeen'] as Timestamp?,
      };
    });
  }
}
