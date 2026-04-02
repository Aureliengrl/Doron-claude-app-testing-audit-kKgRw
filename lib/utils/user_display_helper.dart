import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralise la logique de nom d'affichage pour éviter la duplication
/// du fallback (display_name ?? first_name ?? name ?? email ?? 'Utilisateur')
/// dans 10+ fichiers de l'app.
class UserDisplayHelper {
  /// Retourne le meilleur nom d'affichage à partir d'un document Firestore user.
  static String getName(Map<String, dynamic>? data) {
    if (data == null) return 'Utilisateur';

    final displayName = _nonEmpty(data['display_name'] as String?);
    if (displayName != null) return displayName;

    final firstName = _nonEmpty(data['first_name'] as String?);
    if (firstName != null) return firstName;

    final name = _nonEmpty(data['name'] as String?);
    if (name != null) return name;

    final username = _nonEmpty(data['username'] as String?);
    if (username != null) return username;

    final email = data['email'] as String?;
    if (email != null && email.contains('@')) {
      final prefix = email.split('@').first;
      if (prefix.isNotEmpty) return prefix;
    }

    return 'Utilisateur';
  }

  /// Retourne le handle (@pseudo) formaté.
  static String getHandle(Map<String, dynamic>? data) {
    if (data == null) return '';
    return (data['handle'] as String?) ??
        (data['username'] as String?) ??
        '';
  }

  /// Retourne l'URL de la photo de profil.
  static String getPhotoUrl(Map<String, dynamic>? data) {
    if (data == null) return '';
    return (data['photo_url'] as String?) ??
        (data['photoUrl'] as String?) ??
        '';
  }

  /// Retourne les initiales (1-2 caractères) pour un avatar placeholder.
  static String getInitials(Map<String, dynamic>? data) {
    final name = getName(data);
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  static String? _nonEmpty(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// Cache mémoire de profils utilisateurs pour éviter les requêtes Firestore
/// répétées (FutureBuilder dans les ListView, etc.).
class UserProfileCache {
  UserProfileCache._();
  static final UserProfileCache instance = UserProfileCache._();

  final Map<String, Map<String, dynamic>> _cache = {};
  final Map<String, Future<Map<String, dynamic>?>> _pending = {};

  /// Récupère un profil, depuis le cache ou Firestore.
  Future<Map<String, dynamic>?> getProfile(String uid) async {
    if (uid.isEmpty) return null;
    if (_cache.containsKey(uid)) return _cache[uid];

    // Éviter les requêtes concurrentes pour le même uid
    if (_pending.containsKey(uid)) return _pending[uid];

    final future = _fetchProfile(uid);
    _pending[uid] = future;
    final result = await future;
    _pending.remove(uid);
    return result;
  }

  /// Récupère le nom d'affichage directement (raccourci).
  Future<String> getDisplayName(String uid) async {
    final profile = await getProfile(uid);
    return UserDisplayHelper.getName(profile);
  }

  /// Ajoute ou met à jour un profil dans le cache.
  void put(String uid, Map<String, dynamic> data) {
    _cache[uid] = data;
  }

  /// Invalide un profil du cache.
  void invalidate(String uid) {
    _cache.remove(uid);
  }

  /// Vide tout le cache (à appeler au logout).
  void clear() {
    _cache.clear();
    _pending.clear();
  }

  Future<Map<String, dynamic>?> _fetchProfile(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _cache[uid] = data;
        return data;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
