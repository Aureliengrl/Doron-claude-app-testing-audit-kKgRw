import '/utils/app_logger.dart';
import 'package:flutter/material.dart';
import '/services/firebase_data_service.dart';
import '/services/product_matching_service.dart';
import '/services/product_url_service.dart';
import '/backend/backend.dart';
import '/auth/firebase_auth/auth_util.dart';

class SearchPageModel {
  static List<Map<String, dynamic>>? _cachedProfiles;
  static Map<String, List<Map<String, dynamic>>>? _cachedPersonGifts;
  static Map<String, List<Map<String, dynamic>>>? _cachedPersonSuggestions;

  int? selectedProfileId;
  Set<int> likedProducts = {};
  Set<String> likedProductTitles = {}; // Pour identifier les produits likés par titre
  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> profiles = _cachedProfiles ?? [];
  Map<String, List<Map<String, dynamic>>> personGifts = _cachedPersonGifts ?? {}; // Cache des cadeaux par personId
  Map<String, List<Map<String, dynamic>>> personSuggestions = _cachedPersonSuggestions ?? {}; // Cache des suggestions par personId
  bool isLoadingSuggestions = false;

  /// Normalise un ID (String ou int) en int pour cohérence
  int _normalizeId(dynamic id) {
    if (id is int) return id;
    if (id is String) return id.hashCode;
    return 0;
  }

  /// Charge les profils depuis Firebase/Local Storage (nouvelle architecture)
  Future<void> loadProfiles() async {
    try {
      isLoading = profiles.isEmpty; // N'affiche le chargement bloquant que s'il n'y a pas de cache
      errorMessage = null;

      // Charger les personnes depuis la collection people
      final people = await FirebaseDataService.loadPeople();

      // FIX F3: Traiter TOUS les profils en parallèle avec Future.wait
      // Avant: boucle séquentielle → 5 profils × 3-6s = 15-30s de chargement
      // Après: toutes les générations lancées simultanément → ~3-6s max
      final profileFutures = people.map((person) async {
        final personId = person['id'] as String;
        final tags = person['tags'] as Map<String, dynamic>? ?? {};
        final meta = person['meta'] as Map<String, dynamic>? ?? {};

        final recipientName = tags['name'] as String? ??
                               tags['personName'] as String? ??
                               tags['recipient'] as String? ??
                               'Sans nom';
        final relation = tags['recipient'] as String? ?? tags['relation'] as String? ?? 'Proche';
        final occasion = tags['occasion'] as String? ?? 'Occasion';

        final initials = _generateInitials(recipientName, relation);
        final color = _generateColor(recipientName);

        final isPendingFirstGen = meta['isPendingFirstGen'] == true;
        List<Map<String, dynamic>> gifts = [];

        if (isPendingFirstGen) {
          AppLogger.debug('🔄 Génération cadeaux pour $recipientName (isPendingFirstGen=true)', 'Debug');
          try {
            final rawGifts = await ProductMatchingService.getPersonalizedProducts(
              userTags: tags,
              count: 50,
              filteringMode: "person",
            );

            gifts = rawGifts.map((product) {
              return {
                'id': product['id'],
                'name': product['name'] ?? 'Produit',
                'brand': product['brand'] ?? '',
                'price': product['price'] ?? 0,
                'image': product['image'] ?? product['imageUrl'] ?? '',
                'url': ProductUrlService.generateProductUrl(product),
                'buyLinks': product['buyLinks'], // FIX-BUG2: conserver pour le modal
                'source': product['source'] ?? 'Amazon',
                'categories': product['categories'] ?? [],
                'match': (() {
                  final raw = product['_matchScore'] is int
                      ? (product['_matchScore'] as int).toDouble()
                      : (product['_matchScore'] is double ? product['_matchScore'] as double : 150.0);
                  return ((raw / 400.0) * 100).clamp(0, 100).toInt();
                })(),
              };
            }).toList();

            AppLogger.debug('✅ ${gifts.length} cadeaux générés pour $recipientName', 'Debug');

            if (gifts.isNotEmpty) {
              try {
                // FIX F7: Nom de liste contextuel au lieu d'une date brute
                // Avant: 'Liste 27/4' — aucun contexte sur la personne ou l'occasion
                final listName = 'Idées pour $recipientName';
                await FirebaseDataService.saveGiftListForPerson(
                  personId: personId,
                  gifts: gifts,
                  listName: listName,
                );
                await FirebaseDataService.updatePersonPendingFlag(personId, false);
                AppLogger.debug('💾 Auto-sauvegarde "$listName" effectuée', 'Debug');
              } catch (e) {
                AppLogger.debug('⚠️ Erreur auto-save (non-bloquant): $e', 'Debug');
              }
            }
          } catch (e) {
            AppLogger.debug('❌ Erreur génération cadeaux pour $recipientName: $e', 'Debug');
            final giftListData = await FirebaseDataService.loadLatestGiftListForPerson(personId);
            gifts = (giftListData?['gifts'] as List? ?? []).cast<Map<String, dynamic>>();
          }
        } else {
          final giftListData = await FirebaseDataService.loadLatestGiftListForPerson(personId);
          gifts = (giftListData?['gifts'] as List? ?? []).cast<Map<String, dynamic>>();
          AppLogger.debug('📦 ${gifts.length} cadeaux chargés depuis Firebase pour $recipientName', 'Debug');
        }

        return {
          'profile': {
            'id': personId,
            'name': recipientName,
            'initials': initials,
            'color': color,
            'relation': relation,
            'occasion': occasion,
            'tags': tags,
            'meta': meta,
            // FIX C1+C6: persistance du chatId entre les sessions
            // chatId peut être dans meta (collab) ou dans tags (compatibilité)
            'chatId': meta['chatId'] as String? ?? tags['chatId'] as String?,
            'isShared': meta['isShared'] == true || tags['isShared'] == true,
            'collabId': meta['collabId'] as String? ?? tags['collabId'] as String?,
          },
          'personId': personId,
          'gifts': gifts,
        };
      }).toList();

      // Attendre que tous les profils soient traités en parallèle (avec un timeout de 10 secondes)
      final results = await Future.wait(profileFutures, eagerError: false)
          .timeout(const Duration(seconds: 10));

      // Reconstruire les listes dans l'ordre original
      profiles = [];
      for (final result in results) {
        final personId = result['personId'] as String;
        final gifts = result['gifts'] as List<Map<String, dynamic>>;
        personGifts[personId] = gifts;
        profiles.add(result['profile'] as Map<String, dynamic>);
      }
      _cachedProfiles = profiles; // Update cache
      _cachedPersonGifts = personGifts; // Update cache

      // Sélectionner le premier profil par défaut
      if (profiles.isNotEmpty && selectedProfileId == null) {
        selectedProfileId = _normalizeId(profiles[0]['id']);

        final personId = profiles[0]['id'].toString();
        try {
          await loadPersonFavorites(personId);
        } catch (e) {
          AppLogger.debug('⚠️ Could not load favorites (non-blocking): $e', 'Debug');
        }

        await FirebaseDataService.setCurrentPersonContext(personId);

        if (personGifts[personId]?.isNotEmpty == true) {
          try {
            await loadSuggestionsForPerson(personId);
          } catch (e) {
            AppLogger.debug('⚠️ Could not load suggestions (non-blocking): $e', 'Debug');
          }
        }
      }

      isLoading = false;
      AppLogger.debug('✅ ${profiles.length} profils chargés en parallèle', 'Debug');
    } catch (e) {
      AppLogger.debug('❌ Error loading profiles: $e', 'Debug');
      isLoading = false;
      // Ne pas afficher d'erreur si c'est juste qu'il n'y a pas de profils
      if (profiles.isEmpty) {
        errorMessage = null; // Pas d'erreur, juste vide
      } else {
        errorMessage = 'Erreur lors du chargement: ${e.toString()}';
      }
    }
  }

  /// Génère des initiales à partir d'un nom et de la relation
  String _generateInitials(String name, String relation) {
    // D'abord, vérifier la relation pour retourner une icône personnalisée
    final relationLower = relation.toLowerCase();

    // Icônes personnalisées selon la relation
    if (relationLower.contains('maman') || relationLower.contains('mère') || relationLower.contains('mere')) {
      return 'M';
    }
    if (relationLower.contains('papa') || relationLower.contains('père') || relationLower.contains('pere')) {
      return 'P';
    }
    if (relationLower.contains('amoureux') || relationLower.contains('amoureuse') ||
        relationLower.contains('conjoint') || relationLower.contains('conjointe') ||
        relationLower.contains('chéri') || relationLower.contains('chérie') ||
        relationLower.contains('copain') || relationLower.contains('copine')) {
      return '❤️';
    }
    if (relationLower.contains('frère') || relationLower.contains('frere')) {
      return 'F';
    }
    if (relationLower.contains('sœur') || relationLower.contains('soeur')) {
      return 'S';
    }
    if (relationLower.contains('ami') || relationLower.contains('amie')) {
      return 'A';
    }
    if (relationLower.contains('enfant') || relationLower.contains('fils') || relationLower.contains('fille')) {
      return 'E';
    }
    if (relationLower.contains('grand-père') || relationLower.contains('grand-mere') ||
        relationLower.contains('grand-mère') || relationLower.contains('grands-parents')) {
      return 'G';
    }
    if (relationLower.contains('collègue') || relationLower.contains('collegue')) {
      return 'C';
    }

    // Si pas de relation correspondante, utiliser les initiales du nom
    if (name.isEmpty) return '?';

    // Nettoyer le nom (enlever les emojis et caractères spéciaux)
    final cleanName = name
        .replaceAll(RegExp(r'[^\p{L}\s]', unicode: true), '') // Supprimer tout sauf lettres et espaces
        .trim();

    if (cleanName.isEmpty) return '?';

    final parts = cleanName.split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      // Prendre la première lettre de chaque mot (prénom + nom)
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    // Si un seul mot, prendre les 2 premières lettres ou la première si trop court
    if (cleanName.length >= 2) {
      return cleanName.substring(0, 2).toUpperCase();
    }

    return cleanName.substring(0, 1).toUpperCase();
  }

  /// Génère une couleur basée sur le nom (couleurs cohérentes)
  String _generateColor(String name) {
    final colors = [
      '#8A2BE2', // Violet
      '#EC4899', // Rose
      '#F59E0B', // Orange
      '#10B981', // Vert
      '#3B82F6', // Bleu
      '#EF4444', // Rouge
      '#8B5CF6', // Violet clair
      '#06B6D4', // Cyan
    ];
    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }

  /// Charge les favoris pour une personne spécifique
  Future<void> loadPersonFavorites(String personId) async {
    try {
      final favorites = await queryFavouritesRecordOnce(
        queryBuilder: (favouritesRecord) => favouritesRecord
            .where('uid', isEqualTo: currentUserReference)
            .where('personId', isEqualTo: personId),
      );

      // Extraire les titres des produits likés pour cette personne
      likedProductTitles = favorites
          .map((fav) => fav.product.productTitle)
          .toSet();

      AppLogger.debug('✅ Loaded ${likedProductTitles.length} favorites for person $personId', 'Debug');
    } catch (e) {
      AppLogger.debug('❌ Error loading person favorites: $e', 'Debug');
      likedProductTitles = {};
    }
  }

  Map<String, dynamic>? get currentProfile {
    if (selectedProfileId == null) return null;

    try {
      return profiles.firstWhere((p) {
        return _normalizeId(p['id']) == selectedProfileId;
      });
    } catch (e) {
      AppLogger.debug('⚠️ Profile not found for ID $selectedProfileId', 'Debug');
      return null;
    }
  }

  List<Map<String, dynamic>> getFilteredProducts() {
    if (selectedProfileId == null) return [];

    // Récupérer les cadeaux depuis le cache pour la personne sélectionnée
    final currentProf = currentProfile;
    if (currentProf != null) {
      final personId = currentProf['id'] as String;

      // Retourner les cadeaux depuis le cache
      if (personGifts.containsKey(personId)) {
        return personGifts[personId] ?? [];
      }
    }

    // Si pas de cadeaux, retourner une liste vide
    return [];
  }

  Future<void> selectProfile(dynamic profileId) async {
    selectedProfileId = _normalizeId(profileId);

    // Charger les favoris de la personne sélectionnée
    final profile = currentProfile;
    if (profile != null && profile.containsKey('id')) {
      final personId = profile['id'].toString();
      await loadPersonFavorites(personId);

      // Définir le contexte actuel pour que les nouveaux favoris soient liés à cette personne
      await FirebaseDataService.setCurrentPersonContext(personId);

      // Charger les suggestions pour cette personne (si pas déjà chargées)
      if (!personSuggestions.containsKey(personId) && personGifts[personId]?.isNotEmpty == true) {
        await loadSuggestionsForPerson(personId);
      }
    }
  }

  void toggleLike(int productId) {
    if (likedProducts.contains(productId)) {
      likedProducts.remove(productId);
    } else {
      likedProducts.add(productId);
    }
  }

  /// Vérifie si un produit est dans les favoris de la personne sélectionnée
  bool isProductLiked(String productTitle) {
    return likedProductTitles.contains(productTitle);
  }

  /// Charge les suggestions pour une personne spécifique
  /// Basé sur les cadeaux déjà sauvegardés + tags de la personne
  Future<void> loadSuggestionsForPerson(String personId) async {
    try {
      isLoadingSuggestions = true;
      AppLogger.debug('🔮 Génération de suggestions pour $personId...', 'Debug');

      // Récupérer le profil de la personne
      final profile = profiles.firstWhere(
        (p) => p['id'] == personId,
        orElse: () => {},
      );

      if (profile.isEmpty) {
        AppLogger.debug('⚠️ Profil non trouvé pour $personId', 'Debug');
        isLoadingSuggestions = false;
        return;
      }

      // Récupérer les tags (onboarding answers) de la personne
      final tags = profile['tags'] as Map<String, dynamic>? ?? {};

      // Récupérer les cadeaux déjà sauvegardés pour cette personne
      final existingGifts = personGifts[personId] ?? [];

      // Extraire les IDs des produits existants pour les exclure
      final excludeProductIds = existingGifts
          .map((gift) => gift['id'])
          .whereType<int>()
          .toList();

      AppLogger.debug('📦 ${existingGifts.length} cadeaux existants pour $personId', 'Debug');
      AppLogger.debug('🚫 Exclusion de ${excludeProductIds.length} produits déjà sauvegardés', 'Debug');

      // Générer des suggestions basées sur les tags + exclusion des produits existants
      final rawSuggestions = await ProductMatchingService.getPersonalizedProducts(
        userTags: tags,
        count: 20, // Générer 20 suggestions supplémentaires
        excludeProductIds: excludeProductIds,
        filteringMode: "person",
      );

      // Convertir au format attendu
      final suggestions = rawSuggestions.map((product) {
        return {
          'id': product['id'],
          'name': product['name'] ?? 'Produit',
          'brand': product['brand'] ?? '',
          'price': product['price'] ?? 0,
          'image': product['image'] ?? product['imageUrl'] ?? '',
          'url': ProductUrlService.generateProductUrl(product),
          'buyLinks': product['buyLinks'], // FIX-BUG6: conserver pour le modal
          'source': product['source'] ?? 'Amazon',
          'categories': product['categories'] ?? [],
          'match': (product['_matchScore'] is int
              ? product['_matchScore'] as int
              : (product['_matchScore'] is double ? (product['_matchScore'] as double).toInt() : 0)).clamp(0, 100),
        };
      }).toList();

      // Stocker les suggestions dans le cache
      personSuggestions[personId] = suggestions;
      _cachedPersonSuggestions = personSuggestions; // Update cache
      isLoadingSuggestions = false;

      AppLogger.debug('✅ ${suggestions.length} suggestions générées pour $personId', 'Debug');
    } catch (e) {
      AppLogger.debug('❌ Erreur lors de la génération de suggestions: $e', 'Debug');
      isLoadingSuggestions = false;
      personSuggestions[personId] = [];
    }
  }

  /// Récupère les suggestions pour la personne actuellement sélectionnée
  List<Map<String, dynamic>> getSuggestions() {
    if (selectedProfileId == null) return [];

    final currentProf = currentProfile;
    if (currentProf != null) {
      final personId = currentProf['id'] as String;
      return personSuggestions[personId] ?? [];
    }

    return [];
  }

  void handleAddNewPerson(BuildContext context) {
    AppLogger.debug('🎯 Redirection vers l\'onboarding "Pour qui veux-tu faire un cadeau ?"', 'Debug');
    // Navigation vers l'onboarding avec skip des questions utilisateur
    // Will be implemented in the widget
  }

  void dispose() {
    // Cleanup - clear all data to free memory
    profiles.clear();
    likedProducts.clear();
    likedProductTitles.clear();
    personGifts.clear();
    personSuggestions.clear();
    selectedProfileId = null;
  }
}
