import '/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/services/firebase_data_service.dart';

class UserProfileModel extends ChangeNotifier {
  bool isLoading = true;
  /// Liste des produits likés — lus depuis users/{uid}/favorites
  List<Map<String, dynamic>> favourites = [];
  Map<String, dynamic>? userProfile;
  List<Map<String, dynamic>> wishlists = [];
  String? errorMessage;

  /// Vérifie si un produit (par nom) est déjà liké
  bool isProductLiked(String productName) {
    return favourites.any((f) => (f['name'] as String? ?? '') == productName);
  }

  /// Charge les favoris de l'utilisateur depuis users/{uid}/favorites
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

      // Charger le profil (Bio, Name, stats) et les wishlists
      userProfile = await FirebaseDataService.loadUserProfile();
      wishlists = await FirebaseDataService.loadWishlists();

      // Charger les favoris depuis la nouvelle collection Firestore
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
          'name': d['name'] ?? '',
          'brand': d['brand'] ?? '',
          'price': (d['price'] ?? '').toString(),
          'image': d['image'] ?? '',
          'url': d['url'] ?? '',
        };
      }).toList();

      isLoading = false;
      notifyListeners();

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
    favourites.clear();
    super.dispose();
  }
}
