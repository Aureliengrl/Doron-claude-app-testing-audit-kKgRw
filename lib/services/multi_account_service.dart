import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/services/firebase_data_service.dart';
import '/pages/new_pages/search_page/search_page_model.dart';
import '/utils/app_logger.dart';

class SavedAccount {
  final String uid;
  final String email;
  final String displayName;
  final String handle;
  final String photoUrl;
  final String authProvider;
  final DateTime lastActive;

  SavedAccount({
    required this.uid,
    this.email = '',
    this.displayName = '',
    this.handle = '',
    this.photoUrl = '',
    this.authProvider = '',
    DateTime? lastActive,
  }) : lastActive = lastActive ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'handle': handle,
        'photoUrl': photoUrl,
        'authProvider': authProvider,
        'lastActive': lastActive.toIso8601String(),
      };

  factory SavedAccount.fromMap(Map<String, dynamic> map) => SavedAccount(
        uid: map['uid'] as String? ?? '',
        email: map['email'] as String? ?? '',
        displayName: map['displayName'] as String? ?? '',
        handle: map['handle'] as String? ?? '',
        photoUrl: map['photoUrl'] as String? ?? '',
        authProvider: map['authProvider'] as String? ?? '',
        lastActive: map['lastActive'] != null
            ? DateTime.tryParse(map['lastActive'] as String)
            : null,
      );

  SavedAccount copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? handle,
    String? photoUrl,
    String? authProvider,
    DateTime? lastActive,
  }) {
    return SavedAccount(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      handle: handle ?? this.handle,
      photoUrl: photoUrl ?? this.photoUrl,
      authProvider: authProvider ?? this.authProvider,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}

class MultiAccountService {
  static const String _storageKey = 'saved_user_accounts';

  /// Récupère la liste de tous les comptes enregistrés sur cet appareil.
  /// Si l'utilisateur actuel n'est pas encore enregistré ou a des infos périmées,
  /// on le met à jour automatiquement.
  static Future<List<SavedAccount>> getSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_storageKey) ?? [];

    List<SavedAccount> accounts = [];
    for (final raw in rawList) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        accounts.add(SavedAccount.fromMap(map));
      } catch (e) {
        AppLogger.error('Error parsing saved account', 'MultiAccount', e);
      }
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid.isNotEmpty) {
      final index = accounts.indexWhere((a) => a.uid == currentUser.uid);
      if (index == -1) {
        // Enregistrer le compte courant
        final newAccount = await _fetchAccountData(currentUser);
        accounts.insert(0, newAccount);
        await _persistAccounts(accounts);
      } else {
        // Mettre à jour l'heure de dernière activité et infos
        final updated = accounts[index].copyWith(
          displayName: currentUser.displayName?.isNotEmpty == true
              ? currentUser.displayName
              : accounts[index].displayName,
          email: currentUser.email?.isNotEmpty == true
              ? currentUser.email
              : accounts[index].email,
          photoUrl: currentUser.photoURL?.isNotEmpty == true
              ? currentUser.photoURL
              : accounts[index].photoUrl,
          lastActive: DateTime.now(),
        );
        accounts[index] = updated;
        await _persistAccounts(accounts);
      }
    }

    return accounts;
  }

  /// Sauvegarde ou met à jour le compte actuellement connecté
  static Future<void> saveCurrentAccount({
    Map<String, dynamic>? profileData,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid.isEmpty) return;

    try {
      final accounts = await getSavedAccounts();
      final index = accounts.indexWhere((a) => a.uid == currentUser.uid);

      String handle = '';
      String displayName = currentUser.displayName ?? '';
      String photoUrl = currentUser.photoURL ?? '';
      String email = currentUser.email ?? '';
      String provider = currentUser.providerData.isNotEmpty
          ? currentUser.providerData.first.providerId
          : 'custom';

      if (profileData != null) {
        if (profileData['handle'] != null &&
            (profileData['handle'] as String).isNotEmpty) {
          handle = profileData['handle'] as String;
        }
        if (profileData['displayName'] != null &&
            (profileData['displayName'] as String).isNotEmpty) {
          displayName = profileData['displayName'] as String;
        }
        if (profileData['photo_url'] != null &&
            (profileData['photo_url'] as String).isNotEmpty) {
          photoUrl = profileData['photo_url'] as String;
        }
      } else {
        // Essayer de récupérer depuis Firestore si handle manquant
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();
          if (doc.exists) {
            final data = doc.data();
            if (data != null) {
              if (data['handle'] != null &&
                  (data['handle'] as String).isNotEmpty) {
                handle = data['handle'] as String;
              }
              if (data['displayName'] != null &&
                  (data['displayName'] as String).isNotEmpty) {
                displayName = data['displayName'] as String;
              }
              if (data['display_name'] != null &&
                  (data['display_name'] as String).isNotEmpty) {
                displayName = data['display_name'] as String;
              }
              if (data['photo_url'] != null &&
                  (data['photo_url'] as String).isNotEmpty) {
                photoUrl = data['photo_url'] as String;
              }
            }
          }
        } catch (_) {}
      }

      final saved = SavedAccount(
        uid: currentUser.uid,
        email: email,
        displayName: displayName.isNotEmpty ? displayName : (handle.isNotEmpty ? handle : 'Utilisateur'),
        handle: handle,
        photoUrl: photoUrl,
        authProvider: provider,
        lastActive: DateTime.now(),
      );

      if (index >= 0) {
        accounts[index] = saved;
      } else {
        accounts.insert(0, saved);
      }

      await _persistAccounts(accounts);
      AppLogger.info('Saved account ${currentUser.uid} (@$handle)', 'MultiAccount');
    } catch (e) {
      AppLogger.error('Error saving current account', 'MultiAccount', e);
    }
  }

  /// Supprime un compte de la liste sauvegardée
  static Future<void> removeAccount(String uid) async {
    try {
      final accounts = await getSavedAccounts();
      accounts.removeWhere((a) => a.uid == uid);
      await _persistAccounts(accounts);
      AppLogger.info('Removed account $uid from saved accounts', 'MultiAccount');
    } catch (e) {
      AppLogger.error('Error removing account', 'MultiAccount', e);
    }
  }

  /// Prépare l'ajout d'un nouveau compte sans perdre les comptes existants
  static Future<void> startAddAccount(BuildContext context) async {
    HapticFeedback.mediumImpact();
    // Sauvegarder le compte actuel avant de se déconnecter
    await saveCurrentAccount();
    // Invalider les caches locaux
    FirebaseDataService.invalidateProfileTagsCache();
    SearchPageModel.clearCache();
    // Déconnexion Firebase Auth
    await authManager.signOut();
    if (context.mounted) {
      context.go('/authentification?addingAccount=true');
    }
  }

  /// Bascule vers un compte cible
  static Future<void> switchAccount(
    BuildContext context,
    SavedAccount targetAccount, {
    VoidCallback? onAccountSwitched,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == targetAccount.uid) {
      // Déjà connecté sur ce compte
      Navigator.of(context).pop();
      return;
    }

    HapticFeedback.mediumImpact();

    // 1. Sauvegarder le compte actif avant de basculer
    await saveCurrentAccount();

    // 2. Nettoyer les caches locaux du compte précédent
    FirebaseDataService.invalidateProfileTagsCache();
    SearchPageModel.clearCache();

    // 3. Déconnecter la session actuelle
    await authManager.signOut();

    // 4. Rediriger vers l'authentification avec contexte du compte sélectionné
    if (context.mounted) {
      Navigator.of(context).pop(); // Fermer le modal
      context.go(
        '/authentification?targetEmail=${Uri.encodeComponent(targetAccount.email)}&targetHandle=${Uri.encodeComponent(targetAccount.handle)}',
      );
    }
  }

  static Future<SavedAccount> _fetchAccountData(User user) async {
    String handle = '';
    String displayName = user.displayName ?? '';
    String photoUrl = user.photoURL ?? '';

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          handle = data['handle'] as String? ?? '';
          if (data['displayName'] != null && (data['displayName'] as String).isNotEmpty) {
            displayName = data['displayName'] as String;
          } else if (data['display_name'] != null && (data['display_name'] as String).isNotEmpty) {
            displayName = data['display_name'] as String;
          }
          if (data['photo_url'] != null && (data['photo_url'] as String).isNotEmpty) {
            photoUrl = data['photo_url'] as String;
          }
        }
      }
    } catch (_) {}

    return SavedAccount(
      uid: user.uid,
      email: user.email ?? '',
      displayName: displayName.isNotEmpty ? displayName : (handle.isNotEmpty ? handle : 'Utilisateur'),
      handle: handle,
      photoUrl: photoUrl,
      authProvider: user.providerData.isNotEmpty
          ? user.providerData.first.providerId
          : 'google.com',
      lastActive: DateTime.now(),
    );
  }

  static Future<void> _persistAccounts(List<SavedAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = accounts.map((a) => jsonEncode(a.toMap())).toList();
    await prefs.setStringList(_storageKey, rawList);
  }
}
