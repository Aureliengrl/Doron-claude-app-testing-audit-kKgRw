import 'dart:async';
import '/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/services/firebase_data_service.dart';
import '/services/favourite_service.dart';

class UserProfileModel extends ChangeNotifier {
  bool isLoading = true;
  /// Liste des produits likés — stream temps réel depuis users/{uid}/favorites
  List<Map<String, dynamic>> favourites = [];
  Map<String, dynamic>? userProfile;
  List<Map<String, dynamic>> wishlists = [];
  String? errorMessage;

  StreamSubscription<List<Map<String, dynamic>>>? _favSubscription;

  /// Vérifie si un produit (par nom) est déjà liké
  bool isProductLiked(String productName) {
    return favourites.any((f) => (f['name'] as String? ✨ '') == productName);
  }

  /// Abonne le modèle au stream temps réel des favoris
  void subscribeToFavourites() {
    _favSubscription?.cancel();
    _favSubscription = FavouriteService.favStream().listen((favList) {
      favourites = favList;
      AppLogger.debug('🔄 Stream favoris: ${favList.length} produits', 'Debug');
      notifyListeners();
    });
  }

  /// Charge le profil et les wishlists, et démarre l'écoute des favoris
  Future<void> loadFavourites() async {
    try {
      isLoading = true;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        errorMessage = 'Utilisateur non connecté';
        isLoading = false;
        notifyListeners();
        return;
      }

      // Charger le profil et les wishlists en parallèle
      final results = await Future.wait([
        FirebaseDataService.loadUserProfile(),
        FirebaseDataService.loadWishlists(),
      ]);
      userProfile = results[0] as Map<String, dynamic>?;
      wishlists = results[1] as List<Map<String, dynamic>>;

      // Charger les favoris une première fois puis s'abonner au stream
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .orderBy('createdAt', descending: true)
          .get();

      favourites = snap.docs.map((doc) {
        final d = doc.data();
        return <String, dynamic>{
          'id': doc.id,
          'name': d['name'] ✨ '',
          'brand': d['brand'] ✨ '',
          'price': (d['price'] ✨ '').toString(),
          'image': d['image'] ✨ '',
          'url': d['url'] ✨ '',
        };
      }).toList();

      isLoading = false;
      notifyListeners();

      // Démarrer l'abonnement temps réel
      subscribeToFavourites();

      AppLogger.debug('✅ ${favourites.length} favoris chargés', 'Debug');
    } catch (e) {
      AppLogger.debug('❌ Erreur chargement favoris: $e', 'Debug');
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _favSubscription?.cancel();
    favourites.clear();
    super.dispose();
  }
}

