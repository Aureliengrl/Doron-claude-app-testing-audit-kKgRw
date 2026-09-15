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
  /// on le met à jour automatiquement avec les données Firestore.
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

    final activeUid = FirebaseDataService.currentUserId;
    if (activeUid != null && activeUid.isNotEmpty) {
      final index = accounts.indexWhere((a) => a.uid == activeUid);
      if (index == -1) {
        // Enregistrer le compte courant depuis Firestore
        final currentAuth = FirebaseAuth.instance.currentUser;
        final newAccount = await _fetchAccountData(
          activeUid,
          fallbackEmail: (currentAuth != null && currentAuth.uid == activeUid) ? currentAuth.email : '',
          fallbackDisplayName: (currentAuth != null && currentAuth.uid == activeUid) ? currentAuth.displayName : '',
          fallbackPhotoUrl: (currentAuth != null && currentAuth.uid == activeUid) ? currentAuth.photoURL : '',
        );
        accounts.insert(0, newAccount);
        await _persistAccounts(accounts);
      } else {
        // Mettre à jour l'heure de dernière activité sans écraser le handle/nom custom
        final existing = accounts[index];
        final updated = existing.copyWith(
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
    final activeUid = FirebaseDataService.currentUserId;
    if (activeUid == null || activeUid.isEmpty) return;

    try {
      final accounts = await getSavedAccounts();
      final index = accounts.indexWhere((a) => a.uid == activeUid);
      final currentAuth = FirebaseAuth.instance.currentUser;
      final isAuthMatch = currentAuth != null && currentAuth.uid == activeUid;

      String handle = index >= 0 ? accounts[index].handle : '';
      String displayName = index >= 0 ? accounts[index].displayName : (isAuthMatch ? (currentAuth.displayName ?? '') : '');
      String photoUrl = index >= 0 ? accounts[index].photoUrl : (isAuthMatch ? (currentAuth.photoURL ?? '') : '');
      String email = index >= 0 ? accounts[index].email : (isAuthMatch ? (currentAuth.email ?? '') : '');
      String provider = isAuthMatch && currentAuth.providerData.isNotEmpty
          ? currentAuth.providerData.first.providerId
          : (index >= 0 ? accounts[index].authProvider : 'custom');

      if (profileData != null) {
        if (profileData['handle'] != null &&
            (profileData['handle'] as String).trim().isNotEmpty) {
          handle = (profileData['handle'] as String).trim();
        }
        if (profileData['displayName'] != null &&
            (profileData['displayName'] as String).trim().isNotEmpty) {
          displayName = (profileData['displayName'] as String).trim();
        } else if (profileData['display_name'] != null &&
            (profileData['display_name'] as String).trim().isNotEmpty) {
          displayName = (profileData['display_name'] as String).trim();
        } else if (profileData['first_name'] != null &&
            (profileData['first_name'] as String).trim().isNotEmpty) {
          displayName = (profileData['first_name'] as String).trim();
        }
        if (profileData['photo_url'] != null &&
            (profileData['photo_url'] as String).trim().isNotEmpty) {
          photoUrl = (profileData['photo_url'] as String).trim();
        } else if (profileData['photoUrl'] != null &&
            (profileData['photoUrl'] as String).trim().isNotEmpty) {
          photoUrl = (profileData['photoUrl'] as String).trim();
        }
        if (profileData['email'] != null &&
            (profileData['email'] as String).trim().isNotEmpty) {
          email = (profileData['email'] as String).trim();
        }
      } else {
        // Essayer de récupérer depuis Firestore
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(activeUid)
              .get();
          if (doc.exists) {
            final data = doc.data();
            if (data != null) {
              if (data['handle'] != null &&
                  (data['handle'] as String).trim().isNotEmpty) {
                handle = (data['handle'] as String).trim();
              }
              if (data['displayName'] != null &&
                  (data['displayName'] as String).trim().isNotEmpty) {
                displayName = (data['displayName'] as String).trim();
              } else if (data['display_name'] != null &&
                  (data['display_name'] as String).trim().isNotEmpty) {
                displayName = (data['display_name'] as String).trim();
              } else if (data['first_name'] != null &&
                  (data['first_name'] as String).trim().isNotEmpty) {
                displayName = (data['first_name'] as String).trim();
              }
              if (data['photo_url'] != null &&
                  (data['photo_url'] as String).trim().isNotEmpty) {
                photoUrl = (data['photo_url'] as String).trim();
              } else if (data['photoUrl'] != null &&
                  (data['photoUrl'] as String).trim().isNotEmpty) {
                photoUrl = (data['photoUrl'] as String).trim();
              }
              if (data['email'] != null &&
                  (data['email'] as String).trim().isNotEmpty) {
                email = (data['email'] as String).trim();
              }
            }
          }
        } catch (_) {}
      }

      final saved = SavedAccount(
        uid: activeUid,
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
      AppLogger.info('Saved account $activeUid (@$handle - $displayName)', 'MultiAccount');
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

  /// Initialise le compte actif au démarrage de l'application.
  /// ⚠️ FIX MULTI-COMPTE : on n'active l'override QUE si le UID sauvegardé
  /// correspond au compte Firebase Auth actuellement connecté.
  /// Si les deux diffèrent, l'override est supprimé pour éviter des erreurs
  /// permission-denied sur toutes les écritures Firestore.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedActiveUid = prefs.getString('active_account_uid');
      final authUid = FirebaseAuth.instance.currentUser?.uid;

      if (savedActiveUid != null && savedActiveUid.isNotEmpty) {
        if (savedActiveUid == authUid) {
          // Le compte sauvegardé correspond à l'auth Firebase → override sûr
          FirebaseDataService.setActiveUidOverride(savedActiveUid);
          AppLogger.info('MultiAccount init: override actif pour $savedActiveUid', 'MultiAccount');
        } else {
          // Mismatch : effacer l'override et la clé pour ne pas casser Firestore
          await prefs.remove('active_account_uid');
          AppLogger.warning(
            'MultiAccount init: override ignoré ($savedActiveUid ≠ auth $authUid) — nettoyé',
            'MultiAccount',
          );
        }
      }
    } catch (_) {}
  }

  /// Prépare l'ajout d'un nouveau compte sans perdre les comptes existants
  static Future<void> startAddAccount(BuildContext context) async {
    HapticFeedback.mediumImpact();
    // 1. Sauvegarder le compte actuel
    await saveCurrentAccount();
    // 2. Nettoyer les caches locaux et vider l'override UID
    FirebaseDataService.setActiveUidOverride(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_account_uid');
    FirebaseDataService.invalidateProfileTagsCache();
    SearchPageModel.clearCache();
    // 3. Déconnexion Firebase Auth
    await authManager.signOut();
    if (context.mounted) {
      context.go('/authentification?addingAccount=true');
    }
  }

  /// Bascule vers un compte cible.
  /// ⚠️ FIX MULTI-COMPTE :
  ///   - Si le compte cible est le compte Firebase Auth actuel → override sûr.
  ///   - Sinon → re-authentification obligatoire (sinon toutes les écritures
  ///     Firestore échouent en permission-denied car request.auth.uid ≠ UID cible).
  static Future<void> switchAccount(
    BuildContext context,
    SavedAccount targetAccount, {
    VoidCallback? onAccountSwitched,
  }) async {
    final currentUid = FirebaseDataService.currentUserId;
    if (currentUid == targetAccount.uid) {
      // Déjà sur ce compte
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      return;
    }

    HapticFeedback.mediumImpact();

    final authUid = FirebaseAuth.instance.currentUser?.uid;

    // CAS 1 : le compte cible est le compte Firebase Auth actuel
    // → l'override est sûr, pas besoin de re-auth
    if (targetAccount.uid == authUid) {
      // Sauvegarder le compte actif
      await saveCurrentAccount();

      // Nettoyer les caches
      FirebaseDataService.invalidateProfileTagsCache();
      SearchPageModel.clearCache();

      // Activer l'override (correspond à l'auth)
      FirebaseDataService.setActiveUidOverride(targetAccount.uid);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_account_uid', targetAccount.uid);

      // Mettre à jour l'ordre des comptes sauvegardés
      final accounts = await getSavedAccounts();
      final index = accounts.indexWhere((a) => a.uid == targetAccount.uid);
      if (index >= 0) {
        final acc = accounts.removeAt(index);
        accounts.insert(0, acc.copyWith(lastActive: DateTime.now()));
        await _persistAccounts(accounts);
      }

      if (context.mounted) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Compte actif : ${targetAccount.displayName.isNotEmpty ? targetAccount.displayName : (targetAccount.handle.isNotEmpty ? "@${targetAccount.handle}" : "Utilisateur")}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              )),
            ]),
            backgroundColor: const Color(0xFF8A2BE2),
            duration: const Duration(seconds: 2),
          ),
        );

        if (onAccountSwitched != null) {
          onAccountSwitched();
        } else {
          context.go('/user-profile');
        }
      }
      return;
    }

    // CAS 2 : le compte cible ≠ Firebase Auth actuel
    // → re-authentification obligatoire pour éviter permission-denied Firestore
    AppLogger.info(
      'switchAccount: re-auth requise (target ${targetAccount.uid} ≠ auth $authUid)',
      'MultiAccount',
    );

    // Sauvegarder le compte actuel avant de se déconnecter
    await saveCurrentAccount();

    // Nettoyer
    FirebaseDataService.invalidateProfileTagsCache();
    SearchPageModel.clearCache();
    FirebaseDataService.setActiveUidOverride(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_account_uid');

    // Se déconnecter de Firebase Auth
    await authManager.signOut();

    if (context.mounted) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();

      // Informer l'utilisateur de la reconnexion requise
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.login_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Reconnecte-toi avec le compte ${targetAccount.email.isNotEmpty ? targetAccount.email : targetAccount.displayName}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            )),
          ]),
          backgroundColor: const Color(0xFF6B21A8),
          duration: const Duration(seconds: 4),
        ),
      );

      context.go('/authentification');
    }
  }

  static Future<SavedAccount> _fetchAccountData(
    String uid, {
    String? fallbackEmail,
    String? fallbackDisplayName,
    String? fallbackPhotoUrl,
  }) async {
    String handle = '';
    String displayName = fallbackDisplayName ?? '';
    String photoUrl = fallbackPhotoUrl ?? '';
    String email = fallbackEmail ?? '';

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          handle = data['handle'] as String? ?? '';
          if (data['displayName'] != null && (data['displayName'] as String).trim().isNotEmpty) {
            displayName = (data['displayName'] as String).trim();
          } else if (data['display_name'] != null && (data['display_name'] as String).trim().isNotEmpty) {
            displayName = (data['display_name'] as String).trim();
          } else if (data['first_name'] != null && (data['first_name'] as String).trim().isNotEmpty) {
            displayName = (data['first_name'] as String).trim();
          }
          if (data['photo_url'] != null && (data['photo_url'] as String).trim().isNotEmpty) {
            photoUrl = (data['photo_url'] as String).trim();
          } else if (data['photoUrl'] != null && (data['photoUrl'] as String).trim().isNotEmpty) {
            photoUrl = (data['photoUrl'] as String).trim();
          }
          if (data['email'] != null && (data['email'] as String).trim().isNotEmpty) {
            email = (data['email'] as String).trim();
          }
        }
      }
    } catch (_) {}

    return SavedAccount(
      uid: uid,
      email: email,
      displayName: displayName.isNotEmpty ? displayName : (handle.isNotEmpty ? handle : 'Utilisateur'),
      handle: handle,
      photoUrl: photoUrl,
      authProvider: 'custom',
      lastActive: DateTime.now(),
    );
  }

  static Future<void> _persistAccounts(List<SavedAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = accounts.map((a) => jsonEncode(a.toMap())).toList();
    await prefs.setStringList(_storageKey, rawList);
  }
}
