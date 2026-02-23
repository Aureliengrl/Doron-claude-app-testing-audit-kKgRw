import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/utils/app_logger.dart';
import '/services/firebase_data_service.dart';
import '/services/product_matching_service.dart';
import '/services/product_url_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FEED STATE NOTIFIER
// Remplace la logique de chargement dans HomePinterestWidget / HomePinterestModel
// sans casser l'existant (les widgets continuent à utiliser leur modèle POPO).
// Ce StateNotifier peut être adopté progressivement dans les nouveaux widgets.
// ─────────────────────────────────────────────────────────────────────────────

/// État du feed d'accueil
class FeedState {
  final List<Map<String, dynamic>> products;
  final bool isLoading;
  final bool isLoadingMore;
  final String category;
  final String? errorMessage;
  final bool hasMore;
  final int page;

  const FeedState({
    this.products = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.category = 'all',
    this.errorMessage,
    this.hasMore = true,
    this.page = 0,
  });

  FeedState copyWith({
    List<Map<String, dynamic>>? products,
    bool? isLoading,
    bool? isLoadingMore,
    String? category,
    String? errorMessage,
    bool? hasMore,
    int? page,
    bool clearError = false,
  }) {
    return FeedState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      category: category ?? this.category,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
  }
}

/// Notifier du feed d'accueil
class FeedNotifier extends StateNotifier<FeedState> {
  FeedNotifier() : super(const FeedState());

  static const int _pageSize = 20;

  /// Charge la première page du feed pour une catégorie donnée
  Future<void> loadFeed({
    required Map<String, dynamic> userTags,
    String category = 'all',
  }) async {
    state = state.copyWith(
      isLoading: true,
      category: category,
      products: [],
      page: 0,
      hasMore: true,
      clearError: true,
    );

    try {
      final products = await ProductMatchingService.getPersonalizedProducts(
        userTags: userTags,
        count: _pageSize,
        category: category,
        filteringMode: 'home',
      );

      state = state.copyWith(
        products: _deduplicate(products),
        isLoading: false,
        hasMore: products.length >= _pageSize,
        page: 1,
      );
      AppLogger.info('🏠 Feed chargé: ${products.length} produits', 'FeedNotifier');
    } catch (e) {
      AppLogger.error('Erreur chargement feed', 'FeedNotifier', e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Impossible de charger les produits. Réessayez.',
      );
    }
  }

  /// Charge la page suivante (pagination)
  Future<void> loadMore({required Map<String, dynamic> userTags}) async {
    if (!state.hasMore || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final seenIds = state.products.map((p) => p['id']).toList();
      final more = await ProductMatchingService.getPersonalizedProducts(
        userTags: userTags,
        count: _pageSize,
        category: state.category,
        excludeProductIds: seenIds,
        filteringMode: 'home',
      );

      state = state.copyWith(
        products: [...state.products, ..._deduplicate(more)],
        isLoadingMore: false,
        hasMore: more.length >= _pageSize,
        page: state.page + 1,
      );
    } catch (e) {
      AppLogger.error('Erreur loadMore feed', 'FeedNotifier', e);
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Change de catégorie et recharge le feed
  Future<void> switchCategory({
    required String category,
    required Map<String, dynamic> userTags,
  }) async {
    if (state.category == category && !state.isLoading) return;
    await loadFeed(userTags: userTags, category: category);
  }

  List<Map<String, dynamic>> _deduplicate(List<Map<String, dynamic>> products) {
    final seen = <dynamic>{};
    return products.where((p) => seen.add(p['id'])).toList();
  }
}

/// Provider du feed d'accueil
final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>(
  (ref) => FeedNotifier(),
);

// ─────────────────────────────────────────────────────────────────────────────
// PEOPLE STATE NOTIFIER
// Gère les destinataires + leurs listes de cadeaux
// ─────────────────────────────────────────────────────────────────────────────

/// État des destinataires (page Recherche)
class PeopleState {
  final List<Map<String, dynamic>> people;
  final Map<String, List<Map<String, dynamic>>> giftsByPersonId;
  final String? selectedPersonId;
  final bool isLoading;
  final String? errorMessage;

  const PeopleState({
    this.people = const [],
    this.giftsByPersonId = const {},
    this.selectedPersonId,
    this.isLoading = false,
    this.errorMessage,
  });

  PeopleState copyWith({
    List<Map<String, dynamic>>? people,
    Map<String, List<Map<String, dynamic>>>? giftsByPersonId,
    String? selectedPersonId,
    bool? isLoading,
    String? errorMessage,
    bool clearSelectedPerson = false,
    bool clearError = false,
  }) {
    return PeopleState(
      people: people ?? this.people,
      giftsByPersonId: giftsByPersonId ?? this.giftsByPersonId,
      selectedPersonId: clearSelectedPerson ? null : selectedPersonId ?? this.selectedPersonId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  /// Produits du destinataire sélectionné
  List<Map<String, dynamic>> get selectedPersonGifts {
    if (selectedPersonId == null) return [];
    return giftsByPersonId[selectedPersonId] ?? [];
  }

  /// Données du destinataire sélectionné
  Map<String, dynamic>? get selectedPerson {
    if (selectedPersonId == null) return null;
    try {
      return people.firstWhere((p) => p['id'] == selectedPersonId);
    } catch (_) {
      return null;
    }
  }
}

/// Notifier des destinataires
class PeopleNotifier extends StateNotifier<PeopleState> {
  PeopleNotifier() : super(const PeopleState());

  /// Charge tous les destinataires et leurs cadeaux
  Future<void> loadPeople() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final rawPeople = await FirebaseDataService.loadPeople();
      final giftsByPersonId = <String, List<Map<String, dynamic>>>{};

      final people = <Map<String, dynamic>>[];
      for (final person in rawPeople) {
        final personId = person['id'] as String;
        final tags = (person['tags'] as Map<String, dynamic>?) ?? {};
        final meta = (person['meta'] as Map<String, dynamic>?) ?? {};

        // Charger les cadeaux pour cette personne
        List<Map<String, dynamic>> gifts = [];
        final isPendingFirstGen = meta['isPendingFirstGen'] == true;

        if (isPendingFirstGen) {
          gifts = await _generateFirstGifts(personId: personId, tags: tags);
        } else {
          final listData = await FirebaseDataService.loadLatestGiftListForPerson(personId);
          gifts = (listData?['gifts'] as List? ?? []).cast<Map<String, dynamic>>();
        }

        giftsByPersonId[personId] = gifts;
        people.add({
          ...person,
          'tags': tags,
          'meta': meta,
        });
      }

      state = state.copyWith(
        people: people,
        giftsByPersonId: giftsByPersonId,
        isLoading: false,
        selectedPersonId: people.isNotEmpty ? (people.first['id'] as String) : null,
      );

      AppLogger.info('👥 ${people.length} destinataires chargés', 'PeopleNotifier');
    } catch (e) {
      AppLogger.error('Erreur chargement destinataires', 'PeopleNotifier', e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erreur lors du chargement des profils.',
      );
    }
  }

  /// Sélectionner un destinataire
  void selectPerson(String personId) {
    state = state.copyWith(selectedPersonId: personId);
    FirebaseDataService.setCurrentPersonContext(personId);
  }

  /// Rafraîchir les cadeaux d'une personne
  Future<void> refreshGiftsForPerson(String personId) async {
    final person = state.people.firstWhere(
      (p) => p['id'] == personId,
      orElse: () => {},
    );
    if (person.isEmpty) return;

    final tags = (person['tags'] as Map<String, dynamic>?) ?? {};
    final existing = state.giftsByPersonId[personId] ?? [];
    final excludeIds = existing.map((g) => g['id']).whereType<int>().toList();

    final newGifts = await ProductMatchingService.getPersonalizedProducts(
      userTags: tags,
      count: 20,
      excludeProductIds: excludeIds,
      filteringMode: 'person',
    );

    final mapped = _mapGifts(newGifts);
    state = state.copyWith(
      giftsByPersonId: {
        ...state.giftsByPersonId,
        personId: [...existing, ...mapped],
      },
    );
  }

  Future<List<Map<String, dynamic>>> _generateFirstGifts({
    required String personId,
    required Map<String, dynamic> tags,
  }) async {
    try {
      final rawGifts = await ProductMatchingService.getPersonalizedProducts(
        userTags: tags,
        count: 50,
        filteringMode: 'person',
      );
      final gifts = _mapGifts(rawGifts);

      // Auto-sauvegarde
      if (gifts.isNotEmpty) {
        final listName = 'Liste initiale';
        await FirebaseDataService.saveGiftListForPerson(
          personId: personId,
          gifts: gifts,
          listName: listName,
        );
        await FirebaseDataService.updatePersonPendingFlag(personId, false);
      }
      return gifts;
    } catch (e) {
      AppLogger.error('Erreur génération premiers cadeaux', 'PeopleNotifier', e);
      final listData = await FirebaseDataService.loadLatestGiftListForPerson(personId);
      return (listData?['gifts'] as List? ?? []).cast<Map<String, dynamic>>();
    }
  }

  List<Map<String, dynamic>> _mapGifts(List<Map<String, dynamic>> rawGifts) {
    return rawGifts.map((product) {
      final matchRaw = product['_matchScore'];
      final match = (matchRaw is int ? matchRaw : (matchRaw is double ? matchRaw.toInt() : 0)).clamp(0, 100);
      return {
        'id': product['id'],
        'name': product['name'] ?? 'Produit',
        'brand': product['brand'] ?? '',
        'price': product['price'] ?? 0,
        'image': product['image'] ?? product['imageUrl'] ?? '',
        'url': ProductUrlService.generateProductUrl(product),
        'source': product['source'] ?? '',
        'categories': product['categories'] ?? [],
        'match': match,
      };
    }).toList();
  }
}

/// Provider des destinataires
final peopleNotifierProvider = StateNotifierProvider<PeopleNotifier, PeopleState>(
  (ref) => PeopleNotifier(),
);

// ─────────────────────────────────────────────────────────────────────────────
// FAVORITES NOTIFIER
// Gère les favoris avec mise à jour optimiste (UI répond immédiatement)
// ─────────────────────────────────────────────────────────────────────────────

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super({});

  /// Charge les favoris depuis Firebase
  Future<void> load() async {
    try {
      final favorites = await FirebaseDataService.loadFavorites();
      final titles = favorites.map((f) => (f['name'] ?? f['title'] ?? '') as String).toSet();
      state = titles;
    } catch (e) {
      AppLogger.error('Erreur chargement favoris', 'FavoritesNotifier', e);
    }
  }

  /// Toggle favori (mise à jour optimiste)
  void toggle(String productTitle) {
    if (state.contains(productTitle)) {
      state = {...state}..remove(productTitle);
    } else {
      state = {...state, productTitle};
    }
  }

  bool isLiked(String productTitle) => state.contains(productTitle);
}

/// Provider des favoris (synced avec Firebase au chargement)
final favoritesNotifierProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) => FavoritesNotifier(),
);
