import '/utils/app_logger.dart';
import 'package:flutter/material.dart';
import '/backend/backend.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/services/firebase_data_service.dart';

class UserProfileModel extends ChangeNotifier {
  bool isLoading = true;
  List<FavouritesRecord> favourites = [];
  Map<String, dynamic>? userProfile;
  List<Map<String, dynamic>> wishlists = [];
  String? errorMessage;

  /// Charge les favoris de l'utilisateur
  Future<void> loadFavourites() async {
    try {
      isLoading = true;
      notifyListeners();

      if (currentUserReference == null) {
        errorMessage = 'Utilisateur non connecté';
        isLoading = false;
        notifyListeners();
        return;
      }

      // Charger le profil (Bio, Name, stats) et les wishlists
      userProfile = await FirebaseDataService.loadUserProfile();
      wishlists = await FirebaseDataService.loadWishlists();

      // Charger les favoris depuis Firestore
      final favQuery = await queryFavouritesRecordOnce(
        queryBuilder: (favouritesRecord) => favouritesRecord
            .where('uid', isEqualTo: currentUserReference)
            .orderBy('created_at', descending: true),
      );

      favourites = favQuery;
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
