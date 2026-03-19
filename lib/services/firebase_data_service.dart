import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '/utils/app_logger.dart';
import '/backend/backend.dart';
import '/auth/firebase_auth/auth_util.dart';

/// Service pour gérer les données Firebase
class FirebaseDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Retourne l'ID de l'utilisateur connecté
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Vérifie si un utilisateur est connecté
  static bool get isLoggedIn => _auth.currentUser != null;

  // ============= ONBOARDING ANSWERS =============

  /// Sauvegarde les réponses d'onboarding
  static Future<void> saveOnboardingAnswers(
    Map<String, dynamic> answers,
  ) async {
    // Sauvegarder localement TOUJOURS (que l'utilisateur soit connecté ou non)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_onboarding_answers', json.encode(answers));
      AppLogger.success('Onboarding answers saved locally', 'Firebase');
    } catch (e) {
      AppLogger.error('Error saving onboarding locally', 'Firebase', e);
    }

    // Sauvegarder sur Firebase si connecté
    if (!isLoggedIn) {
      AppLogger.warning('User not logged in, skipping Firebase save', 'Firebase');
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('onboarding')
          .doc('latest')
          .set({
        'answers': answers,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      AppLogger.firebase('Onboarding answers saved to Firebase');
    } catch (e) {
      AppLogger.error('Error saving onboarding to Firebase', 'Firebase', e);
    }
  }

  /// Charge les réponses d'onboarding
  static Future<Map<String, dynamic>?> loadOnboardingAnswers() async {
    // Essayer de charger depuis Firebase d'abord si connecté
    if (isLoggedIn) {
      try {
        final doc = await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('onboarding')
            .doc('latest')
            .get();

        if (doc.exists) {
          AppLogger.firebase('Loaded onboarding from Firebase');
          return doc.data()?['answers'] as Map<String, dynamic>?;
        }
      } catch (e) {
        AppLogger.error('Error loading onboarding from Firebase', 'Firebase', e);
      }
    }

    // Fallback : charger depuis SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final localData = prefs.getString('local_onboarding_answers');
      if (localData != null) {
        AppLogger.success('Loaded onboarding from local storage', 'Firebase');
        return json.decode(localData) as Map<String, dynamic>;
      }
    } catch (e) {
      AppLogger.error('Error loading onboarding from local storage', 'Firebase', e);
    }

    AppLogger.warning('No onboarding data found', 'Firebase');
    return null;
  }

  // ============= GIFT SEARCHES (renamed from gift_profiles to match spec) =============

  /// Sauvegarde une recherche de cadeau (Maman, Papa, etc.)
  static Future<String?> saveGiftProfile(Map<String, dynamic> profile) async {
    // Sauvegarder localement TOUJOURS
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = prefs.getString('local_gift_profiles') ?? '[]';
      final profiles = (json.decode(profilesJson) as List).cast<Map<String, dynamic>>();

      // Générer un ID unique pour le profil
      final profileId = const Uuid().v4();
      final profileWithId = {
        'id': profileId,
        ...profile,
        'createdAt': DateTime.now().toIso8601String(),
      };

      profiles.add(profileWithId);
      await prefs.setString('local_gift_profiles', json.encode(profiles));
      AppLogger.success('Gift search saved locally: $profileId', 'Firebase');
    } catch (e) {
      AppLogger.error('Error saving gift search locally', 'Firebase', e);
    }

    // Sauvegarder sur Firebase si connecté (collection giftSearches selon spec)
    if (!isLoggedIn) return null;

    try {
      final docRef = await _firestore
          .collection('giftSearches')
          .add({
        'userId': currentUserId,
        ...profile,
        'createdAt': FieldValue.serverTimestamp(),
      });

      AppLogger.firebase('Gift search saved to Firebase: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      AppLogger.error('Error saving gift search to Firebase', 'Firebase', e);
      return null;
    }
  }

  /// Charge toutes les recherches de cadeaux
  static Future<List<Map<String, dynamic>>> loadGiftProfiles() async {
    // Essayer de charger depuis Firebase si connecté
    if (isLoggedIn) {
      try {
        final snapshot = await _firestore
            .collection('giftSearches')
            .where('userId', isEqualTo: currentUserId)
            .orderBy('createdAt', descending: true)
            .get();

        if (snapshot.docs.isNotEmpty) {
          AppLogger.firebase('Loaded ${snapshot.docs.length} gift searches from Firebase');
          return snapshot.docs.map((doc) {
            return {
              'id': doc.id,
              ...doc.data(),
            };
          }).toList();
        }
      } catch (e) {
        AppLogger.error('Error loading gift searches from Firebase', 'Firebase', e);
      }
    }

    // Fallback : charger depuis SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = prefs.getString('local_gift_profiles') ?? '[]';
      final profiles = (json.decode(profilesJson) as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      AppLogger.success('Loaded ${profiles.length} gift searches from local storage', 'Firebase');
      return profiles;
    } catch (e) {
      AppLogger.error('Error loading gift searches from local storage', 'Firebase', e);
      return [];
    }
  }

  /// Met à jour une recherche de cadeau
  static Future<void> updateGiftProfile(
    String profileId,
    Map<String, dynamic> updates,
  ) async {
    if (!isLoggedIn) return;

    try {
      await _firestore
          .collection('giftSearches')
          .doc(profileId)
          .update(updates);

      AppLogger.firebase('Gift search updated: $profileId');
    } catch (e) {
      AppLogger.error('Error updating gift search', 'Firebase', e);
    }
  }

  // ============= CURRENT PERSON CONTEXT =============

  /// Sauvegarde l'ID de la personne actuellement visualisée (pour lier les favoris)
  static Future<void> setCurrentPersonContext(String? personId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (personId != null) {
        await prefs.setString('current_person_id', personId);
        AppLogger.info('Current person context set: $personId', 'Firebase');
      } else {
        await prefs.remove('current_person_id');
        AppLogger.info('Current person context cleared', 'Firebase');
      }
    } catch (e) {
      AppLogger.error('Error setting current person context', 'Firebase', e);
    }
  }

  /// Récupère l'ID de la personne actuellement visualisée
  static Future<String?> getCurrentPersonContext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('current_person_id');
    } catch (e) {
      AppLogger.error('Error getting current person context', 'Firebase', e);
      return null;
    }
  }

  /// Supprime une recherche de cadeau
  static Future<void> deleteGiftProfile(String profileId) async {
    if (!isLoggedIn) return;

    try {
      await _firestore
          .collection('giftSearches')
          .doc(profileId)
          .delete();

      AppLogger.firebase('Gift search deleted: $profileId');
    } catch (e) {
      AppLogger.error('Error deleting gift search', 'Firebase', e);
    }
  }

  // ============= SUGGESTIONS (AI-generated gifts) =============

  /// Sauvegarde les suggestions générées par l'IA
  static Future<void> saveGiftSuggestions({
    required String searchId,
    required List<Map<String, dynamic>> gifts,
  }) async {
    if (!isLoggedIn) return;

    try {
      await _firestore
          .collection('suggestions')
          .doc(searchId)
          .set({
        'userId': currentUserId,
        'searchId': searchId,
        'gifts': gifts,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      AppLogger.firebase('Gift suggestions saved for search: $searchId');
    } catch (e) {
      AppLogger.error('Error saving suggestions', 'Firebase', e);
    }
  }

  /// Charge les suggestions pour une recherche
  static Future<List<Map<String, dynamic>>?> loadGiftSuggestions(
    String searchId,
  ) async {
    if (!isLoggedIn) return null;

    try {
      final doc = await _firestore
          .collection('suggestions')
          .doc(searchId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        return (data?['gifts'] as List?)?.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      AppLogger.error('Error loading suggestions', 'Firebase', e);
    }
    return null;
  }

  // ============= FAVORITES =============

  /// Ajoute un cadeau aux favoris (Firebase + locale SharedPreferences)
  static Future<void> addToFavorites(Map<String, dynamic> gift) async {
    final giftId = gift['id']?.toString() ?? const Uuid().v4();
    final giftWithId = {...gift, 'id': giftId};

    // ── Persistance locale (offline first) ──────────────────────────────────
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString('local_favorites') ?? '[]';
      final localList = (json.decode(localJson) as List).cast<Map<String, dynamic>>();
      // Éviter les doublons
      localList.removeWhere((f) => f['id']?.toString() == giftId);
      localList.insert(0, {...giftWithId, 'addedAt': DateTime.now().toIso8601String()});
      await prefs.setString('local_favorites', json.encode(localList));
      AppLogger.success('Favorite saved locally: ${gift['name']}', 'Firebase');
    } catch (e) {
      AppLogger.error('Error saving favorite locally', 'Firebase', e);
    }

    // ── Firebase (si connecté) ────────────────────────────────────────────
    if (!isLoggedIn) return;
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorites')
          .doc(giftId)
          .set({
        ...giftWithId,
        'addedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.firebase('Added to favorites: ${gift['name']}');
    } catch (e) {
      AppLogger.error('Error adding to favorites (Firebase)', 'Firebase', e);
    }
  }

  /// Retire un cadeau des favoris (Firebase + locale)
  static Future<void> removeFromFavorites(String giftId) async {
    // ── Local ──────────────────────────────────────────────────────────────
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString('local_favorites') ?? '[]';
      final localList = (json.decode(localJson) as List).cast<Map<String, dynamic>>();
      localList.removeWhere((f) => f['id']?.toString() == giftId);
      await prefs.setString('local_favorites', json.encode(localList));
      AppLogger.success('Favorite removed locally: $giftId', 'Firebase');
    } catch (e) {
      AppLogger.error('Error removing favorite locally', 'Firebase', e);
    }

    // ── Firebase ──────────────────────────────────────────────────────────
    if (!isLoggedIn) return;
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorites')
          .doc(giftId)
          .delete();
      AppLogger.firebase('Removed from favorites: $giftId');
    } catch (e) {
      AppLogger.error('Error removing from favorites (Firebase)', 'Firebase', e);
    }
  }

  /// Charge tous les favoris — merge locale + Firebase
  static Future<List<Map<String, dynamic>>> loadFavorites() async {
    // ── Local (always) ────────────────────────────────────────────────────
    List<Map<String, dynamic>> localFavorites = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString('local_favorites') ?? '[]';
      localFavorites = (json.decode(localJson) as List).cast<Map<String, dynamic>>();
      AppLogger.success('Local favorites: ${localFavorites.length}', 'Firebase');
    } catch (e) {
      AppLogger.error('Error loading local favorites', 'Firebase', e);
    }

    // ── Firebase (si connecté) ────────────────────────────────────────────
    if (!isLoggedIn) return localFavorites;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorites')
          .orderBy('addedAt', descending: true)
          .get();

      final firebaseFavorites = snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();

      AppLogger.firebase('Firebase favorites: ${firebaseFavorites.length}');

      // Merge: Firebase en priorité + ajout des locaux non présents dans Firebase
      final seenIds = firebaseFavorites.map((f) => f['id']?.toString()).toSet();
      final onlyLocal = localFavorites.where((f) => !seenIds.contains(f['id']?.toString())).toList();

      // Sync locale → Firebase pour les favoris locaux manquants
      for (final fav in onlyLocal) {
        _syncLocalFavoriteToFirebase(fav);
      }

      return [...firebaseFavorites, ...onlyLocal];
    } catch (e) {
      AppLogger.error('Error loading favorites from Firebase', 'Firebase', e);
      return localFavorites;
    }
  }

  /// Sync silencieuse d'un favori local vers Firebase
  static Future<void> _syncLocalFavoriteToFirebase(Map<String, dynamic> fav) async {
    if (!isLoggedIn) return;
    try {
      final giftId = fav['id']?.toString();
      if (giftId == null || giftId.isEmpty) return;
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorites')
          .doc(giftId)
          .set({...fav, 'addedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      AppLogger.firebase('Synced local favorite to Firebase: $giftId');
    } catch (e) {
      AppLogger.error('Error syncing local favorite', 'Firebase', e);
    }
  }

  /// Vérifie si un cadeau est dans les favoris
  static Future<bool> isFavorite(String giftId) async {
    if (!isLoggedIn) return false;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorites')
          .doc(giftId)
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // ============= WISHLISTS =============

  /// Crée une nouvelle liste de souhaits dans la sous-collection de l'utilisateur.
  /// FIX: écrit dans users/{uid}/wishlists/ (pas la collection racine /wishlists/)
  static Future<String?> createWishlist({
    required String name,
    String? emoji,
    String? description,
    String? personId,
  }) async {
    final wishlistId = const Uuid().v4();
    final wishlistData = {
      'name': name,
      'emoji': emoji ?? '🎁',
      'description': description ?? '',
      'personId': personId,
      'productIds': <String>[],
      'createdAt': DateTime.now().toIso8601String(),
    };

    // ── Local ──────────────────────────────────────────────────────────────
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString('local_wishlists') ?? '[]';
      final localList = (json.decode(localJson) as List).cast<Map<String, dynamic>>();
      localList.insert(0, {'id': wishlistId, ...wishlistData});
      await prefs.setString('local_wishlists', json.encode(localList));
      AppLogger.success('Wishlist created locally: $name', 'Firebase');
    } catch (e) {
      AppLogger.error('Error creating wishlist locally', 'Firebase', e);
    }

    // ── Firebase (correcte sous-collection utilisateur) ───────────────────
    if (!isLoggedIn) return wishlistId;
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('wishlists')
          .doc(wishlistId)
          .set({...wishlistData, 'createdAt': FieldValue.serverTimestamp()});
      AppLogger.firebase('Wishlist created: $wishlistId ($name)');
    } catch (e) {
      AppLogger.error('Error creating wishlist in Firebase', 'Firebase', e);
    }
    return wishlistId;
  }

  /// Charge toutes les listes de souhaits.
  /// FIX: lit depuis users/{uid}/wishlists/ (sous-collection correcte)
  static Future<List<Map<String, dynamic>>> loadWishlists({String? personId}) async {
    // ── Local ──────────────────────────────────────────────────────────────
    List<Map<String, dynamic>> localWishlists = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString('local_wishlists') ?? '[]';
      localWishlists = (json.decode(localJson) as List).cast<Map<String, dynamic>>();
      if (personId != null) {
        localWishlists = localWishlists.where((w) => w['personId'] == personId).toList();
      }
    } catch (e) {
      AppLogger.error('Error loading local wishlists', 'Firebase', e);
    }

    if (!isLoggedIn) return localWishlists;

    // ── Firebase ──────────────────────────────────────────────────────────
    try {
      var query = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('wishlists')
          .orderBy('createdAt', descending: true);

      if (personId != null) {
        query = _firestore.collection('users').doc(currentUserId).collection('wishlists').orderBy('createdAt', descending: true).where('personId', isEqualTo: personId);
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('wishlists')
          .orderBy('createdAt', descending: true)
          .get();

      final firebaseWishlists = snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();

      final seenIds = firebaseWishlists.map((w) => w['id']?.toString()).toSet();
      final onlyLocal = localWishlists.where((w) => !seenIds.contains(w['id']?.toString())).toList();
      return [...firebaseWishlists, ...onlyLocal];
    } catch (e) {
      AppLogger.error('Error loading wishlists from Firebase', 'Firebase', e);
      return localWishlists;
    }
  }

  /// Ajoute un produit (Map) à une wishlist.
  /// FIX: stocke les données du produit directement dans
  ///      users/{uid}/wishlists/{wishlistId}/products/{productId}
  ///      (élimine l'indirection productIds → favorites qui causait le bug)
  static Future<bool> addProductToWishlist(
    String wishlistId,
    Map<String, dynamic> product,
  ) async {
    // Générer un ID stable basé sur le nom du produit (déterministe)
    final productName = product['name'] ?? product['title'] ?? product['product_title'] ?? '';
    final existingId = product['id']?.toString();
    final productId = (existingId != null && existingId.isNotEmpty && existingId != 'null')
        ? existingId
        : (productName.isNotEmpty ? productName.hashCode.abs().toString() : const Uuid().v4());

    // Normaliser le produit
    final normalizedProduct = {
      'id': productId,
      'type': 'product',
      'name': productName.isNotEmpty ? productName : 'Produit',
      'brand': product['brand'] ?? product['platform'] ?? product['source'] ?? '',
      'image': product['image'] ?? product['imageUrl'] ?? product['product_photo'] ?? product['photo'] ?? '',
      'price': (product['price'] ?? product['product_price'] ?? '').toString(),
      'url': product['url'] ?? product['product_url'] ?? product['link'] ?? '',
      'description': product['description'] ?? product['reason'] ?? '',
      'addedAt': DateTime.now().toIso8601String(),
    };

    // ── Local (SharedPreferences) ─────────────────────────────────────────
    try {
      final prefs = await SharedPreferences.getInstance();
      // 1) Mettre à jour la liste de produits du cache
      final localJson = prefs.getString('wishlist_products_$wishlistId') ?? '[]';
      final localList = (json.decode(localJson) as List).cast<Map<String, dynamic>>();
      localList.removeWhere((p) => p['id']?.toString() == productId);
      localList.insert(0, normalizedProduct);
      await prefs.setString('wishlist_products_$wishlistId', json.encode(localList));
      // 2) Mettre à jour productCount dans le cache des wishlists
      final wishlistsJson = prefs.getString('local_wishlists') ?? '[]';
      final wishlistsList = (json.decode(wishlistsJson) as List).cast<Map<String, dynamic>>();
      final idx = wishlistsList.indexWhere((w) => w['id']?.toString() == wishlistId);
      if (idx != -1) {
        final current = (wishlistsList[idx]['productCount'] as int?) ?? 0;
        wishlistsList[idx]['productCount'] = current + 1;
        await prefs.setString('local_wishlists', json.encode(wishlistsList));
      }
      AppLogger.success('Product saved locally in wishlist $wishlistId: $productId', 'Firebase');
    } catch (e) {
      AppLogger.error('Error saving wishlist product locally', 'Firebase', e);
    }

    // ── Firebase : sous-collection products ──────────────────────────────
    if (!isLoggedIn) return true;
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('wishlists')
          .doc(wishlistId)
          .collection('products')
          .doc(productId)
          .set({
        ...normalizedProduct,
        'addedAt': FieldValue.serverTimestamp(),
      });
      // Mettre à jour le compteur dans la wishlist parente
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('wishlists')
          .doc(wishlistId)
          .update({
        'productCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.firebase('Product added to wishlist in Firebase: $productId');
      return true;
    } catch (e) {
      AppLogger.error('Error adding product to wishlist (Firebase)', 'Firebase', e);
      // Essai de set sans productCount si l'update échoue
      try {
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('wishlists')
            .doc(wishlistId)
            .collection('products')
            .doc(productId)
            .set({
          ...normalizedProduct,
          'addedAt': FieldValue.serverTimestamp(),
        });
        return true;
      } catch (e2) {
        AppLogger.error('Second attempt failed: $e2', 'Firebase', e2);
        return false;
      }
    }
  }

  /// Ajoute une photo (depuis le disque local) à une wishlist.
  /// Upload sur Firebase Storage, puis écrit un item `type:'photo'`
  /// dans la sous-collection `products` et incrémente `productCount`.
  static Future<bool> addPhotoToWishlist(
    String wishlistId,
    String localImagePath, {
    String? caption,
  }) async {
    try {
      final uid = currentUserId;
      if (uid == null || uid.isEmpty) return false;

      final photoId = '${DateTime.now().millisecondsSinceEpoch}';
      final file = File(localImagePath);

      // ── Upload Firebase Storage ───────────────────────────────────────
      final ref = _storage
          .ref()
          .child('users/$uid/wishlist_photos/$wishlistId/$photoId.jpg');
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      final photoItem = {
        'id': photoId,
        'type': 'photo',
        'image': downloadUrl,
        'caption': caption ?? '',
        'addedAt': DateTime.now().toIso8601String(),
      };

      // ── Local cache ────────────────────────────────────────────────────
      try {
        final prefs = await SharedPreferences.getInstance();
        // liste produits
        final localJson = prefs.getString('wishlist_products_$wishlistId') ?? '[]';
        final localList = (json.decode(localJson) as List).cast<Map<String, dynamic>>();
        localList.insert(0, photoItem);
        await prefs.setString('wishlist_products_$wishlistId', json.encode(localList));
        // compteur
        final wishlistsJson = prefs.getString('local_wishlists') ?? '[]';
        final wishlistsList = (json.decode(wishlistsJson) as List).cast<Map<String, dynamic>>();
        final idx = wishlistsList.indexWhere((w) => w['id']?.toString() == wishlistId);
        if (idx != -1) {
          final current = (wishlistsList[idx]['productCount'] as int?) ?? 0;
          wishlistsList[idx]['productCount'] = current + 1;
          await prefs.setString('local_wishlists', json.encode(wishlistsList));
        }
      } catch (_) {}

      // ── Firestore ─────────────────────────────────────────────────────
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('wishlists')
          .doc(wishlistId)
          .collection('products')
          .doc(photoId)
          .set({...photoItem, 'addedAt': FieldValue.serverTimestamp()});

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('wishlists')
          .doc(wishlistId)
          .update({
        'productCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.firebase('Photo added to wishlist $wishlistId: $photoId');
      return true;
    } catch (e) {
      AppLogger.error('Error adding photo to wishlist', 'Firebase', e);
      return false;
    }
  }

  /// Retire un produit d'une wishlist.
  /// FIX: supprime depuis la sous-collection products
  static Future<bool> removeProductFromWishlist(
    String wishlistId,
    String productId,
  ) async {
    // ── Local ──────────────────────────────────────────────────────────────
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString('wishlist_products_$wishlistId') ?? '[]';
      final localList = (json.decode(localJson) as List).cast<Map<String, dynamic>>();
      localList.removeWhere((p) => p['id']?.toString() == productId);
      await prefs.setString('wishlist_products_$wishlistId', json.encode(localList));
    } catch (e) {
      AppLogger.error('Error removing from wishlist locally', 'Firebase', e);
    }

    // ── Firebase ──────────────────────────────────────────────────────────
    if (!isLoggedIn) return true;
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('wishlists')
          .doc(wishlistId)
          .collection('products')
          .doc(productId)
          .delete();
      // Décrémenter le compteur (ignore si déjà à 0)
      try {
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('wishlists')
            .doc(wishlistId)
            .update({
          'productCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
      AppLogger.firebase('Product removed from wishlist: $productId');
      return true;
    } catch (e) {
      AppLogger.error('Error removing from wishlist (Firebase)', 'Firebase', e);
      return false;
    }
  }


  /// Charge les produits d'une wishlist (retourne des Maps directement).
  /// FIX: lit depuis la sous-collection products (pas l'indirection productIds)
  static Future<List<Map<String, dynamic>>> loadWishlistProducts(
    String wishlistId,
  ) async {
    // ── Local d'abord ─────────────────────────────────────────────────────
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString('wishlist_products_$wishlistId') ?? '[]';
      final localList = (json.decode(localJson) as List).cast<Map<String, dynamic>>();
      if (localList.isNotEmpty) {
        AppLogger.success('Loaded ${localList.length} products from wishlist (local)', 'Firebase');
        // Si connecté, fusionner avec Firebase en arrière-plan
        if (isLoggedIn) {
          _loadWishlistProductsFromFirebase(wishlistId).then((fbProducts) {
            // Sync silencieuse — les nouveaux IDs venant d'autres appareils
            // seront disponibles au prochain chargement
          });
        }
        return localList;
      }
    } catch (e) {
      AppLogger.error('Error loading wishlist products (local)', 'Firebase', e);
    }
    // Pas de données locales → Firebase
    return _loadWishlistProductsFromFirebase(wishlistId);
  }

  static Future<List<Map<String, dynamic>>> _loadWishlistProductsFromFirebase(
    String wishlistId,
  ) async {
    if (!isLoggedIn) return [];
    try {
      // Lire directement depuis la sous-collection products
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('wishlists')
          .doc(wishlistId)
          .collection('products')
          .orderBy('addedAt', descending: true)
          .get();

      final products = snapshot.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList();

      // Sauvegarder en local pour la prochaine fois
      if (products.isNotEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          // Convertir les Timestamps en string pour JSON
          final serializable = products.map((p) => {
            ...p,
            'addedAt': (p['addedAt'] is String) ? p['addedAt'] : DateTime.now().toIso8601String(),
          }).toList();
          await prefs.setString('wishlist_products_$wishlistId', json.encode(serializable));
        } catch (_) {}
      }

      AppLogger.firebase('Loaded ${products.length} products from wishlist (Firebase)');
      return products;
    } catch (e) {
      AppLogger.error('Error loading wishlist products from Firebase', 'Firebase', e);
      return [];
    }
  }

  /// Supprime une wishlist
  static Future<bool> deleteWishlist(String wishlistId) async {
    // ── Local ──────────────────────────────────────────────────────────────
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString('local_wishlists') ?? '[]';
      final localList = (json.decode(localJson) as List).cast<Map<String, dynamic>>();
      localList.removeWhere((w) => w['id']?.toString() == wishlistId);
      await prefs.setString('local_wishlists', json.encode(localList));
    } catch (e) {
      AppLogger.error('Error deleting wishlist locally', 'Firebase', e);
    }

    // ── Firebase ──────────────────────────────────────────────────────────
    if (!isLoggedIn) return true;
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('wishlists')
          .doc(wishlistId)
          .delete();
      AppLogger.firebase('Wishlist deleted: $wishlistId');
      return true;
    } catch (e) {
      AppLogger.error('Error deleting wishlist from Firebase', 'Firebase', e);
      return false;
    }
  }

  // ============= GIFTS CATALOG =============

  /// Récupère les produits du catalogue
  static Future<List<Map<String, dynamic>>> getGifts({
    int? limit,
    List<String>? categories,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      var query = _firestore.collection('gifts').where('active', isEqualTo: true);

      if (categories != null && categories.isNotEmpty) {
        query = query.where('category', whereIn: categories);
      }

      if (minPrice != null) {
        query = query.where('price', isGreaterThanOrEqualTo: minPrice);
      }

      if (maxPrice != null) {
        query = query.where('price', isLessThanOrEqualTo: maxPrice);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    } catch (e) {
      AppLogger.error('Error loading gifts', 'Firebase', e);
      return [];
    }
  }

  /// Récupère un produit spécifique
  static Future<Map<String, dynamic>?> getGift(String giftId) async {
    try {
      final doc = await _firestore.collection('gifts').doc(giftId).get();

      if (doc.exists) {
        return {'id': doc.id, ...doc.data() ?? {}};
      }
    } catch (e) {
      AppLogger.error('Error loading gift', 'Firebase', e);
    }
    return null;
  }

  // ============= TRANSLATIONS =============

  /// Récupère les traductions pour une clé
  static Future<Map<String, String>?> getTranslation(String key) async {
    try {
      final doc = await _firestore.collection('translations').doc(key).get();

      if (doc.exists) {
        final data = doc.data();
        return {
          'fr': data?['fr'] ?? '',
          'en': data?['en'] ?? '',
          'es': data?['es'] ?? '',
        };
      }
    } catch (e) {
      AppLogger.error('Error loading translation', 'Firebase', e);
    }
    return null;
  }

  /// Charge toutes les traductions pour une langue
  static Future<Map<String, String>> loadTranslationsForLanguage(String languageCode) async {
    try {
      final snapshot = await _firestore.collection('translations').get();

      final translations = <String, String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        translations[doc.id] = data[languageCode] ?? '';
      }

      AppLogger.firebase('Loaded ${translations.length} translations for $languageCode');
      return translations;
    } catch (e) {
      AppLogger.error('Error loading translations', 'Firebase', e);
      return {};
    }
  }

  // ============= USER PROFILE =============

  /// Met à jour le profil utilisateur
  static Future<void> updateUserProfile(Map<String, dynamic> profile) async {
    if (!isLoggedIn) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .set(profile, SetOptions(merge: true));

      AppLogger.firebase('User profile updated');
    } catch (e) {
      AppLogger.error('Error updating user profile', 'Firebase', e);
    }
  }

  /// Charge le profil utilisateur
  static Future<Map<String, dynamic>?> loadUserProfile() async {
    if (!isLoggedIn) return null;

    try {
      final doc =
          await _firestore.collection('users').doc(currentUserId).get();

      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      AppLogger.error('Error loading user profile', 'Firebase', e);
    }
    return null;
  }

  // ============= NEW ARCHITECTURE: USER PROFILE TAGS =============
  //
  // IMPORTANT: Distinction entre 2 types de données :
  // 1. USER PROFILE TAGS (ci-dessous) = Données de L'UTILISATEUR
  //    - Stockées dans: users/{uid}/profile/tags
  //    - Utilisées pour: Personnaliser le feed d'accueil (page Home)
  //    - Contenu: firstName, age, gender, interests, style, giftTypes
  //
  // 2. PEOPLE (voir section suivante) = Données des DESTINATAIRES DE CADEAUX
  //    - Stockées dans: users/{uid}/people/{personId}
  //    - Utilisées pour: Générer des cadeaux pour des personnes spécifiques
  //    - Contenu: name, gender, recipient, budget, recipientAge, hobbies, etc.
  //
  // Ces deux entités sont SÉPARÉES par design et ne doivent PAS être confondues.

  /// Sauvegarde les tags du profil utilisateur (Étape A onboarding)
  /// Ces tags servent uniquement pour le feed d'accueil personnalisé
  static Future<void> saveUserProfileTags(Map<String, dynamic> tags) async {
    // Sauvegarder localement
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_user_profile_tags', json.encode(tags));
      AppLogger.success('User profile tags saved locally', 'Firebase');
    } catch (e) {
      AppLogger.error('Error saving user profile tags locally', 'Firebase', e);
    }

    // Sauvegarder sur Firebase si connecté
    if (!isLoggedIn) {
      AppLogger.warning('User not logged in, skipping Firebase save for profile tags', 'Firebase');
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .set({
        'profile': {
          'tags': tags,
          'updatedAt': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));

      AppLogger.firebase('User profile tags saved to Firebase');
    } catch (e) {
      AppLogger.error('Error saving user profile tags to Firebase', 'Firebase', e);
    }
  }

  /// Charge les tags du profil utilisateur
  static Future<Map<String, dynamic>?> loadUserProfileTags() async {
    // Essayer Firebase d'abord si connecté
    if (isLoggedIn) {
      try {
        final doc = await _firestore.collection('users').doc(currentUserId).get();
        if (doc.exists && doc.data()?['profile']?['tags'] != null) {
          AppLogger.firebase('Loaded user profile tags from Firebase');
          return doc.data()!['profile']['tags'] as Map<String, dynamic>;
        }
      } catch (e) {
        AppLogger.error('Error loading user profile tags from Firebase', 'Firebase', e);
      }
    }

    // Fallback local
    try {
      final prefs = await SharedPreferences.getInstance();
      final localData = prefs.getString('local_user_profile_tags');
      if (localData != null) {
        AppLogger.success('Loaded user profile tags from local storage', 'Firebase');
        return json.decode(localData) as Map<String, dynamic>;
      }
    } catch (e) {
      AppLogger.error('Error loading user profile tags locally', 'Firebase', e);
    }

    return null;
  }

  // ============= NEW ARCHITECTURE: PEOPLE (GIFT RECIPIENTS) =============
  //
  // NOTE: Ces données concernent les DESTINATAIRES pour qui on cherche des cadeaux,
  // PAS l'utilisateur lui-même. Les données de l'utilisateur sont dans profile/tags.
  //
  // Architecture:
  // - Stockage: users/{uid}/people/{personId}
  // - Utilisation: Page Personnes/Search, génération de cadeaux par personne
  // - Persistance: Local (SharedPreferences) + Firebase (si connecté)

  /// Crée une nouvelle personne (Étape B onboarding ou ajout manuel)
  /// Retourne le personId généré
  static Future<String?> createPerson({
    required Map<String, dynamic> tags,
    bool isPendingFirstGen = false,
  }) async {
    final personId = const Uuid().v4();

    // Sauvegarder localement
    try {
      final prefs = await SharedPreferences.getInstance();
      final peopleJson = prefs.getString('local_people') ?? '[]';
      final people = (json.decode(peopleJson) as List).cast<Map<String, dynamic>>();

      people.add({
        'id': personId,
        'tags': tags,
        'meta': {
          'isPendingFirstGen': isPendingFirstGen,
          'createdAt': DateTime.now().toIso8601String(),
        },
      });

      await prefs.setString('local_people', json.encode(people));
      AppLogger.success('Person created locally: $personId (pending=$isPendingFirstGen)', 'Firebase');
    } catch (e) {
      AppLogger.error('Error creating person locally', 'Firebase', e);
    }

    // Sauvegarder sur Firebase si connecté
    if (!isLoggedIn) return personId;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('people')
          .doc(personId)
          .set({
        'tags': tags,
        'meta': {
          'isPendingFirstGen': isPendingFirstGen,
          'createdAt': FieldValue.serverTimestamp(),
        },
      });

      AppLogger.firebase('Person created in Firebase: $personId');
      return personId;
    } catch (e) {
      AppLogger.error('Error creating person in Firebase', 'Firebase', e);
      return personId; // Retourne quand même l'ID local
    }
  }

  /// FIX ONBOARDING: Synchronise une personne locale vers Firebase
  /// Utilisé après le premier onboarding quand la personne a été cre AVANT la connexion
  static Future<bool> syncLocalPersonToFirebase(String personId) async {
    if (!isLoggedIn) {
      AppLogger.error('Cannot sync: user not logged in', 'Firebase', null);
      return false;
    }

    try {
      // Charger la personne depuis le storage local
      final prefs = await SharedPreferences.getInstance();
      final peopleJson = prefs.getString('local_people') ?? '[]';
      final localPeople = (json.decode(peopleJson) as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      // Trouver la personne avec cet ID
      final person = localPeople.firstWhere(
        (p) => p['id'] == personId,
        orElse: () => {},
      );

      if (person.isEmpty) {
        AppLogger.error('Person not found in local storage: $personId', 'Firebase', null);
        return false;
      }

      AppLogger.info('🔄 Syncing person $personId to Firebase...', 'Firebase');

      // Sauvegarder dans Firebase
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('people')
          .doc(personId)
          .set({
        'tags': person['tags'],
        'meta': person['meta'] ?? {
          'isPendingFirstGen': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
      });

      AppLogger.success('✅ Person $personId synced to Firebase', 'Firebase');
      return true;
    } catch (e) {
      AppLogger.error('Error syncing person to Firebase', 'Firebase', e);
      return false;
    }
  }

  /// Charge toutes les personnes
  static Future<List<Map<String, dynamic>>> loadPeople() async {
    AppLogger.info('🔍 loadPeople: isLoggedIn=$isLoggedIn, currentUserId=$currentUserId', 'Firebase');

    // ⚠️ FIX ONBOARDING: TOUJOURS charger le local storage EN PREMIER
    // Cela garantit que les personnes cres AVANT la connexion sont disponibles
    List<Map<String, dynamic>> localPeople = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final peopleJson = prefs.getString('local_people') ?? '[]';
      localPeople = (json.decode(peopleJson) as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      if (localPeople.isNotEmpty) {
        AppLogger.success('💾 LOCAL: ${localPeople.length} people found', 'Firebase');
        final localIds = localPeople.map((p) => p['id']).toList();
        AppLogger.debug('   Local IDs: $localIds', 'Firebase');
      } else {
        AppLogger.warning('⚠️ LOCAL: empty', 'Firebase');
      }
    } catch (e) {
      AppLogger.error('❌ LOCAL: error loading', 'Firebase', e);
    }

    // Charger Firebase seulement si connecté
    List<Map<String, dynamic>>? firebasePeople;
    if (isLoggedIn) {
      try {
        final snapshot = await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('people')
            .orderBy('meta.createdAt', descending: true)
            .get();

        AppLogger.info('📊 FIREBASE: ${snapshot.docs.length} docs', 'Firebase');
        if (snapshot.docs.isNotEmpty) {
          firebasePeople = snapshot.docs.map((doc) {
            return {
              'id': doc.id,
              ...doc.data(),
            };
          }).toList();
        } else {
          firebasePeople = [];
        }
      } catch (e) {
        AppLogger.error('❌ FIREBASE: error', 'Firebase', e);
      }
    }

    // ⚠️ FIX ONBOARDING: Si LOCAL a des données, TOUJOURS les inclure
    // Merge avec Firebase si disponible, sinon retourner local uniquement
    if (localPeople.isNotEmpty) {
      if (firebasePeople != null && firebasePeople.isNotEmpty) {
        // Les deux ont des données: merger (local en priorité)
        AppLogger.info('🔄 MERGE: local ${localPeople.length} + firebase ${firebasePeople.length}', 'Firebase');
        final localIds = localPeople.map((p) => p['id']).toSet();
        final merged = [...localPeople];

        for (var fbPerson in firebasePeople) {
          if (!localIds.contains(fbPerson['id'])) {
            merged.add(fbPerson);
          }
        }

        final deduplicated = _deduplicatePeopleByName(merged);
        // Sort by createdAt descending (most recent first)
        final sorted = _sortPeopleByDate(deduplicated);
        AppLogger.success('✅ RETURN: ${sorted.length} people (merged & sorted)', 'Firebase');
        return sorted;
      } else {
        // Seulement local - trier par date
        final deduplicated = _deduplicatePeopleByName(localPeople);
        final sorted = _sortPeopleByDate(deduplicated);
        AppLogger.success('✅ RETURN: ${sorted.length} people (local only, sorted)', 'Firebase');
        return sorted;
      }
    }

    // Local vide: retourner Firebase si disponible (déjà trié par Firebase)
    if (firebasePeople != null && firebasePeople.isNotEmpty) {
      final deduplicated = _deduplicatePeopleByName(firebasePeople);
      AppLogger.success('✅ RETURN: ${deduplicated.length} people (firebase only)', 'Firebase');
      return deduplicated;
    }

    // Aucune donnée
    AppLogger.warning('⚠️ RETURN: 0 people (nothing found)', 'Firebase');
    return [];
  }

  /// FIX Bug 3: Déduplique les personnes par nom (garde la plus récente)
  static List<Map<String, dynamic>> _deduplicatePeopleByName(List<Map<String, dynamic>> people) {
    final seenNames = <String, Map<String, dynamic>>{};

    for (var person in people) {
      final tags = person['tags'] as Map<String, dynamic>? ?? {};
      // Extraire le nom depuis plusieurs clés possibles
      final name = (tags['name'] as String? ??
                   tags['personName'] as String? ??
                   tags['recipient'] as String? ??
                   '').toLowerCase().trim();

      // Si le nom est vide, utiliser l'ID comme clé unique
      if (name.isEmpty) {
        seenNames[person['id'].toString()] = person;
        continue;
      }

      // Si on a déjà vu ce nom, comparer les dates pour garder le plus récent
      if (seenNames.containsKey(name)) {
        final existingMeta = seenNames[name]!['meta'] as Map<String, dynamic>? ?? {};
        final newMeta = person['meta'] as Map<String, dynamic>? ?? {};

        final existingDate = existingMeta['createdAt']?.toString() ?? '';
        final newDate = newMeta['createdAt']?.toString() ?? '';

        // Garder le plus récent (date plus grande = plus récent)
        if (newDate.compareTo(existingDate) > 0) {
          AppLogger.debug('🔄 Doublon trouvé pour "$name": remplacement par version plus récente', 'Firebase');
          seenNames[name] = person;
        }
      } else {
        seenNames[name] = person;
      }
    }

    final result = seenNames.values.toList();
    if (result.length < people.length) {
      AppLogger.success('✅ Déduplication: ${people.length} → ${result.length} personnes', 'Firebase');
    }
    return result;
  }

  /// Trie les personnes par date de création (plus récent d'abord)
  static List<Map<String, dynamic>> _sortPeopleByDate(List<Map<String, dynamic>> people) {
    people.sort((a, b) {
      final aMeta = a['meta'] as Map<String, dynamic>? ?? {};
      final bMeta = b['meta'] as Map<String, dynamic>? ?? {};

      final aDate = aMeta['createdAt'];
      final bDate = bMeta['createdAt'];

      // Si les deux ont des timestamps Firestore
      if (aDate is Timestamp && bDate is Timestamp) {
        return bDate.compareTo(aDate); // Descending (newest first)
      }

      // Si les deux sont des strings
      if (aDate is String && bDate is String) {
        return bDate.compareTo(aDate); // Descending
      }

      // Si un seul a une date, le mettre en premier
      if (aDate != null && bDate == null) return -1;
      if (aDate == null && bDate != null) return 1;

      // Si aucun n'a de date, garder l'ordre actuel
      return 0;
    });

    AppLogger.debug('✅ Personnes triées par date (plus récent d\'abord)', 'Firebase');
    return people;
  }

  /// FIX ONBOARDING: Charge une personne par ID sans déduplication
  /// Utilisé pour l'onboarding où on a l'ID exact
  static Future<Map<String, dynamic>?> loadPersonById(String personId) async {
    AppLogger.info('🔍 loadPersonById: $personId', 'Firebase');

    // Charger depuis local storage d'abord
    try {
      final prefs = await SharedPreferences.getInstance();
      final peopleJson = prefs.getString('local_people') ?? '[]';
      final localPeople = (json.decode(peopleJson) as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      // Chercher par ID dans local
      final localPerson = localPeople.firstWhere(
        (p) => p['id'] == personId,
        orElse: () => {},
      );

      if (localPerson.isNotEmpty) {
        AppLogger.success('✅ Person found in LOCAL: $personId', 'Firebase');
        return localPerson;
      }
    } catch (e) {
      AppLogger.error('Error loading from local', 'Firebase', e);
    }

    // Si pas trouvé en local et user connecté, chercher dans Firebase
    if (isLoggedIn) {
      try {
        final doc = await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('people')
            .doc(personId)
            .get();

        if (doc.exists) {
          AppLogger.success('✅ Person found in FIREBASE: $personId', 'Firebase');
          return {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          };
        }
      } catch (e) {
        AppLogger.error('Error loading from Firebase', 'Firebase', e);
      }
    }

    AppLogger.warning('⚠️ Person NOT FOUND: $personId', 'Firebase');
    return null;
  }

  /// Charge la première personne avec isPendingFirstGen=true
  static Future<Map<String, dynamic>?> getFirstPendingPerson() async {
    final people = await loadPeople();
    final person = people.firstWhere(
      (p) => p['meta']?['isPendingFirstGen'] == true,
      orElse: () => {}, // Retourne map vide si non trouvé
    );
    return person.isEmpty ? null : person;
  }

  /// Met à jour le flag isPendingFirstGen d'une personne
  static Future<void> updatePersonPendingFlag(
    String personId,
    bool isPending,
  ) async {
    // Mise à jour locale
    try {
      final prefs = await SharedPreferences.getInstance();
      final peopleJson = prefs.getString('local_people') ?? '[]';
      final people = (json.decode(peopleJson) as List).cast<Map<String, dynamic>>();

      final index = people.indexWhere((p) => p['id'] == personId);
      if (index != -1) {
        people[index]['meta'] = {
          ...people[index]['meta'] ?? {},
          'isPendingFirstGen': isPending,
        };
        await prefs.setString('local_people', json.encode(people));
        AppLogger.success('Person pending flag updated locally', 'Firebase');
      }
    } catch (e) {
      AppLogger.error('Error updating person pending flag locally', 'Firebase', e);
    }

    // Mise à jour Firebase si connecté
    if (!isLoggedIn) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('people')
          .doc(personId)
          .update({
        'meta.isPendingFirstGen': isPending,
      });

      AppLogger.firebase('Person pending flag updated in Firebase');
    } catch (e) {
      AppLogger.error('Error updating person pending flag in Firebase', 'Firebase', e);
    }
  }

  /// Supprime une personne
  static Future<void> deletePerson(String personId) async {
    // Suppression locale
    try {
      final prefs = await SharedPreferences.getInstance();
      final peopleJson = prefs.getString('local_people') ?? '[]';
      final people = (json.decode(peopleJson) as List).cast<Map<String, dynamic>>();

      people.removeWhere((p) => p['id'] == personId);
      await prefs.setString('local_people', json.encode(people));
      AppLogger.success('Person deleted locally: $personId', 'Firebase');
    } catch (e) {
      AppLogger.error('Error deleting person locally', 'Firebase', e);
    }

    // Suppression Firebase si connecté
    if (!isLoggedIn) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('people')
          .doc(personId)
          .delete();

      AppLogger.firebase('Person deleted from Firebase: $personId');
    } catch (e) {
      AppLogger.error('Error deleting person from Firebase', 'Firebase', e);
    }
  }

  // ============= GIFT LISTS (PER PERSON) =============

  /// Sauvegarde une liste de cadeaux pour une personne
  static Future<String?> saveGiftListForPerson({
    required String personId,
    required List<Map<String, dynamic>> gifts,
    String? listName,
  }) async {
    final listId = const Uuid().v4();

    // Sauvegarder localement
    try {
      final prefs = await SharedPreferences.getInstance();
      final listsJson = prefs.getString('local_gift_lists_$personId') ?? '[]';
      final lists = (json.decode(listsJson) as List).cast<Map<String, dynamic>>();

      lists.add({
        'id': listId,
        'personId': personId,
        'name': listName ?? 'Liste ${DateTime.now().day}/${DateTime.now().month}',
        'gifts': gifts,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await prefs.setString('local_gift_lists_$personId', json.encode(lists));
      AppLogger.success('Gift list saved locally for person $personId', 'Firebase');
    } catch (e) {
      AppLogger.error('Error saving gift list locally', 'Firebase', e);
    }

    // Sauvegarder sur Firebase si connecté
    if (!isLoggedIn) return listId;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('people')
          .doc(personId)
          .collection('gift_lists')
          .doc(listId)
          .set({
        'name': listName ?? 'Liste ${DateTime.now().day}/${DateTime.now().month}',
        'gifts': gifts,
        'createdAt': FieldValue.serverTimestamp(),
      });

      AppLogger.firebase('Gift list saved to Firebase for person $personId');
      return listId;
    } catch (e) {
      AppLogger.error('Error saving gift list to Firebase', 'Firebase', e);
      return listId;
    }
  }

  /// Charge toutes les listes de cadeaux pour une personne
  static Future<List<Map<String, dynamic>>> loadGiftListsForPerson(
    String personId,
  ) async {
    // Essayer Firebase si connecté
    if (isLoggedIn) {
      try {
        final snapshot = await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('people')
            .doc(personId)
            .collection('gift_lists')
            .orderBy('createdAt', descending: true)
            .get();

        if (snapshot.docs.isNotEmpty) {
          AppLogger.firebase('Loaded ${snapshot.docs.length} gift lists from Firebase');
          return snapshot.docs.map((doc) {
            return {
              'id': doc.id,
              ...doc.data(),
            };
          }).toList();
        }
      } catch (e) {
        AppLogger.error('Error loading gift lists from Firebase', 'Firebase', e);
      }
    }

    // Fallback local
    try {
      final prefs = await SharedPreferences.getInstance();
      final listsJson = prefs.getString('local_gift_lists_$personId') ?? '[]';
      final lists = (json.decode(listsJson) as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      AppLogger.success('Loaded ${lists.length} gift lists from local storage', 'Firebase');
      return lists;
    } catch (e) {
      AppLogger.error('Error loading gift lists locally', 'Firebase', e);
      return [];
    }
  }

  /// Charge la dernière liste de cadeaux pour une personne
  static Future<Map<String, dynamic>?> loadLatestGiftListForPerson(
    String personId,
  ) async {
    final lists = await loadGiftListsForPerson(personId);
    return lists.isEmpty ? null : lists.first;
  }

  /// Ajoute un cadeau à la liste de cadeaux d'une personne
  static Future<bool> addGiftToPerson({
    required String personId,
    required Map<String, dynamic> gift,
  }) async {
    try {
      // Charger la liste actuelle
      final currentList = await loadLatestGiftListForPerson(personId);

      if (currentList == null) {
        // Aucune liste existante, créer une nouvelle
        await saveGiftListForPerson(
          personId: personId,
          gifts: [gift],
          listName: 'Liste ${DateTime.now().day}/${DateTime.now().month}',
        );
        AppLogger.success('New gift list created with gift for person $personId', 'Firebase');
        return true;
      }

      // Liste existante, ajouter le cadeau
      final List<Map<String, dynamic>> gifts =
          (currentList['gifts'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      // Vérifier si le cadeau existe déjà (par ID ou nom)
      final giftId = gift['id'];
      final giftName = gift['name'];
      final alreadyExists = gifts.any((g) =>
        (g['id'] != null && g['id'] == giftId) ||
        (g['name'] != null && g['name'] == giftName)
      );

      if (alreadyExists) {
        AppLogger.warning('Gift already exists in list for person $personId', 'Firebase');
        return false;
      }

      gifts.add(gift);

      // Sauvegarder la liste mise à jour
      final listId = currentList['id'] as String;

      // Sauvegarder localement
      try {
        final prefs = await SharedPreferences.getInstance();
        final listsJson = prefs.getString('local_gift_lists_$personId') ?? '[]';
        final lists = (json.decode(listsJson) as List).cast<Map<String, dynamic>>();

        final listIndex = lists.indexWhere((l) => l['id'] == listId);
        if (listIndex != -1) {
          lists[listIndex]['gifts'] = gifts;
          await prefs.setString('local_gift_lists_$personId', json.encode(lists));
        }

        AppLogger.success('Gift added locally for person $personId', 'Firebase');
      } catch (e) {
        AppLogger.error('Error adding gift locally', 'Firebase', e);
      }

      // Sauvegarder sur Firebase si connecté
      if (isLoggedIn) {
        try {
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .collection('people')
              .doc(personId)
              .collection('gift_lists')
              .doc(listId)
              .update({'gifts': gifts});

          AppLogger.firebase('Gift added to Firebase for person $personId');
        } catch (e) {
          AppLogger.error('Error adding gift to Firebase', 'Firebase', e);
        }
      }

      return true;
    } catch (e) {
      AppLogger.error('Error adding gift to person', 'Firebase', e);
      return false;
    }
  }

  // ============= HOME FEED =============

  /// Sauvegarde un feed d'accueil généré
  static Future<void> saveHomeFeed(List<Map<String, dynamic>> products) async {
    final feedId = const Uuid().v4();

    // Sauvegarder localement
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('local_home_feed_latest', json.encode({
        'id': feedId,
        'products': products,
        'createdAt': DateTime.now().toIso8601String(),
      }));
      AppLogger.success('Home feed saved locally', 'Firebase');
    } catch (e) {
      AppLogger.error('Error saving home feed locally', 'Firebase', e);
    }

    // Sauvegarder sur Firebase si connecté
    if (!isLoggedIn) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('home_feed')
          .doc(feedId)
          .set({
        'products': products,
        'createdAt': FieldValue.serverTimestamp(),
      });

      AppLogger.firebase('Home feed saved to Firebase');
    } catch (e) {
      AppLogger.error('Error saving home feed to Firebase', 'Firebase', e);
    }
  }

  /// Charge le dernier feed d'accueil
  static Future<List<Map<String, dynamic>>?> loadLatestHomeFeed() async {
    // Essayer Firebase si connecté
    if (isLoggedIn) {
      try {
        final snapshot = await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('home_feed')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final products = snapshot.docs.first.data()['products'] as List?;
          if (products != null) {
            AppLogger.firebase('Loaded home feed from Firebase');
            return products.cast<Map<String, dynamic>>();
          }
        }
      } catch (e) {
        AppLogger.error('Error loading home feed from Firebase', 'Firebase', e);
      }
    }

    // Fallback local
    try {
      final prefs = await SharedPreferences.getInstance();
      final feedJson = prefs.getString('local_home_feed_latest');
      if (feedJson != null) {
        final feedData = json.decode(feedJson) as Map<String, dynamic>;
        final products = feedData['products'] as List?;
        if (products != null) {
          AppLogger.success('Loaded home feed from local storage', 'Firebase');
          return products.cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      AppLogger.error('Error loading home feed locally', 'Firebase', e);
    }

    return null;
  }

  /// Ajoute un produit (par son docId) dans une wishlist
  static Future<void> addToWishlist(String wishlistId, String productDocId) async {
    final userId = currentUserId;
    if (userId == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('wishlists')
          .doc(wishlistId)
          .update({
        'productIds': FieldValue.arrayUnion([productDocId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ addToWishlist error: $e');
    }
  }
}
