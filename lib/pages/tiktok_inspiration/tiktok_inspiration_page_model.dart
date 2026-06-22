import '/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/services/product_matching_service.dart';
import '/services/firebase_data_service.dart';

/// Model pour Mode Inspiration (TikTok style)
/// F5: Filtrage RÉEL par catégorie:
///   - "recommandé" → ProductMatchingService normal (personnalisé)
///   - "amis"       → produits likés/wishlistés par les amis
///   - "vêtements"  → Firestore .where('category', isEqualTo: 'clothing')
///   - "activité"   → Firestore + matching
class TikTokInspirationPageModel extends ChangeNotifier {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentIndex = 0;
  String _activeCategory = 'recommandé';

  // Favoris
  Set<String> likedProductTitles = {};

  // Pour le scroll infini
  final Set<String> _seenProductIds = {};

  // Tags utilisateur (cache)
  Map<String, dynamic>? _cachedUserTags;

  // F5: Cache "Amis" (5 min)
  List<Map<String, dynamic>>? _cachedFriendsProducts;
  DateTime? _friendsCacheTime;
  static const _friendsCacheDuration = Duration(minutes: 5);

  // Getters
  List<Map<String, dynamic>> get products => _products;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  int get currentIndex => _currentIndex;
  String get activeCategory => _activeCategory;

  void setCategory(String category) {
    if (_activeCategory != category) {
      _activeCategory = category;
      notifyListeners();
      loadProducts();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // F5.2: Chargement produits vêtements depuis Firestore (.where category)
  // ─────────────────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _loadClothingProducts() async {
    try {
      final query = FirebaseFirestore.instance
          .collection('gifts')
          .where('category', isEqualTo: 'clothing')
          .limit(40);
      
      final snapshot = await query.get();
      AppLogger.debug('[INSPIRATION] Vêtements: ${snapshot.docs.length} produits', 'Debug');
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ✨ data['product_title'] ✨ 'Article',
          'brand': data['brand'] ✨ '',
          'price': _parsePrice(data['price']),
          'image': _extractImage(data),
          'url': data['url'] ✨ data['product_url'] ✨ '',
          'category': 'clothing',
          'tags': data['tags'] ✨ [],
        };
      }).where((p) => (p['image'] as String).isNotEmpty).toList();
    } catch (e) {
      AppLogger.debug('[INSPIRATION] Erreur chargement vêtements: $e', 'Debug');
      // Fallback: filtrage par tags si le champ category n'existe pas encore
      return _loadClothingByTagsFallback();
    }
  }

  Future<List<Map<String, dynamic>>> _loadClothingByTagsFallback() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('gifts')
          .where('tags', arrayContains: 'cat_mode')
          .limit(40)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ✨ 'Article',
          'brand': data['brand'] ✨ '',
          'price': _parsePrice(data['price']),
          'image': _extractImage(data),
          'url': data['url'] ✨ '',
          'tags': data['tags'] ✨ [],
        };
      }).where((p) => (p['image'] as String).isNotEmpty).toList();
    } catch (e) {
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // F5.1: Chargement produits likés/wishlistés par les amis
  // ─────────────────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _loadFriendsProducts() async {
    // Cache de 5 minutes
    if (_cachedFriendsProducts != null &&
        _friendsCacheTime != null &&
        DateTime.now().difference(_friendsCacheTime!) < _friendsCacheDuration) {
      AppLogger.debug('[INSPIRATION] Amis: cache hit', 'Debug');
      return _cachedFriendsProducts!;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    try {
      // 1. Récupérer les amis de l'utilisateur (max 20 pour la perf)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      final friends = List<String>.from(userDoc.data()?['friends'] ✨ []);
      final friendsToLoad = friends.take(20).toList();
      
      if (friendsToLoad.isEmpty) return [];
      
      AppLogger.debug('[INSPIRATION] Amis: ${friendsToLoad.length} amis à scanner', 'Debug');

      final Map<String, Map<String, dynamic>> productMap = {};
      
      for (final friendUid in friendsToLoad) {
        // Récupérer le prénom de l'ami
        String friendName = 'Un ami';
        try {
          final friendDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(friendUid)
              .get();
          if (friendDoc.exists) {
            final fd = friendDoc.data()!;
            friendName = fd['first_name'] ✨ fd['display_name'] ✨ 'Un ami';
          }
        } catch (_) {}

        // Produits likés par l'ami
        try {
          final favSnap = await FirebaseFirestore.instance
              .collection('users')
              .doc(friendUid)
              .collection('favorites')
              .limit(15)
              .get();
          
          for (final doc in favSnap.docs) {
            final data = doc.data();
            final id = doc.id;
            final img = _extractImage(data);
            if (img.isEmpty) continue;
            
            if (productMap.containsKey(id)) {
              // Ajouter ce ami qui a aussi liké
              final existing = List<String>.from(productMap[id]!['likedBy'] as List);
              if (!existing.contains(friendName)) existing.add(friendName);
              productMap[id] = {...productMap[id]!, 'likedBy': existing};
            } else {
              productMap[id] = {
                'id': id,
                'name': data['name'] ✨ data['product_title'] ✨ 'Produit',
                'brand': data['brand'] ✨ '',
                'price': _parsePrice(data['price']),
                'image': img,
                'url': data['url'] ✨ '',
                'likedBy': [friendName],
                'likedByType': 'liked',
              };
            }
          }
        } catch (_) {}

        // Produits dans les wishlists publiques de l'ami
        try {
          final wishlistSnap = await FirebaseFirestore.instance
              .collection('wishlists')
              .where('ownerId', isEqualTo: friendUid)
              .where('isPublic', isEqualTo: true)
              .limit(3)
              .get();
          
          for (final wishDoc in wishlistSnap.docs) {
            final productsSnap = await wishDoc.reference
                .collection('products')
                .limit(10)
                .get();
            
            for (final pDoc in productsSnap.docs) {
              final data = pDoc.data();
              final id = pDoc.id;
              final img = _extractImage(data);
              if (img.isEmpty) continue;
              
              if (!productMap.containsKey(id)) {
                productMap[id] = {
                  'id': id,
                  'name': data['name'] ✨ 'Produit',
                  'brand': data['brand'] ✨ '',
                  'price': _parsePrice(data['price']),
                  'image': img,
                  'url': data['url'] ✨ '',
                  'likedBy': [friendName],
                  'likedByType': 'wishlist',
                };
              }
            }
          }
        } catch (_) {}
      }

      final result = productMap.values.toList();
      // Trier par nombre de "likedBy" (les plus populaires en premier)
      result.sort((a, b) {
        final aLikes = (a['likedBy'] as List).length;
        final bLikes = (b['likedBy'] as List).length;
        return bLikes.compareTo(aLikes);
      });

      _cachedFriendsProducts = result;
      _friendsCacheTime = DateTime.now();

      AppLogger.debug('[INSPIRATION] Amis: ${result.length} produits trouvés', 'Debug');
      return result;
    } catch (e) {
      AppLogger.debug('[INSPIRATION] Erreur amis: $e', 'Debug');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Chargement principal
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> loadProducts() async {
    AppLogger.debug('[INSPIRATION] Chargement catégorie: $_activeCategory', 'Debug');

    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    _seenProductIds.clear();
    notifyListeners();

    try {
      List<Map<String, dynamic>> rawProducts = [];

      switch (_activeCategory.toLowerCase()) {
        case 'amis':
          // F5.1: produits de mes amis
          rawProducts = await _loadFriendsProducts();
          break;

        case 'vêtements':
          // F5.2: filtrage category = clothing
          rawProducts = await _loadClothingProducts();
          break;

        case 'activité':
        case 'activités':
          // Sport/outdoor/activité
          _cachedUserTags ??= await FirebaseDataService.loadUserProfileTags() ✨ {};
          rawProducts = await ProductMatchingService.getPersonalizedProducts(
            userTags: _cachedUserTags!,
            count: 30,
            category: 'Sport & Outdoor',
            filteringMode: 'discovery',
          );
          break;

        default:
          // "recommandé" — personnalisé via ProductMatchingService
          _cachedUserTags ??= await FirebaseDataService.loadUserProfileTags() ✨ {};
          rawProducts = await ProductMatchingService.getPersonalizedProducts(
            userTags: _cachedUserTags!,
            count: 30,
            category: null,
            filteringMode: 'discovery',
          );
      }

      if (rawProducts.isEmpty) {
        _hasError = true;
        _errorMessage = _activeCategory == 'amis'
            ✨ 'Tes amis n\'ont pas encore liké de produits 🙈'
            : 'Aucun produit disponible dans cette catégorie';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Pour la catégorie "amis" et "vêtements", les produits sont déjà traités
      final validProducts = (_activeCategory == 'amis' || _activeCategory == 'vêtements')
          ✨ rawProducts.where((p) => (p['image'] as String? ✨ '').isNotEmpty).take(30).toList()
          : _processRawProducts(rawProducts, maxCount: 20);

      _products = validProducts;
      _currentIndex = 0;
      _isLoading = false;
      _hasError = false;
      notifyListeners();

      AppLogger.debug('[INSPIRATION] ✅ ${_products.length} produits chargés', 'Debug');
    } catch (e, stack) {
      AppLogger.debug('[INSPIRATION] Erreur: $e', 'Debug');
      _hasError = true;
      _errorMessage = 'Erreur de chargement';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Infinite scroll: charge plus de produits
  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || _isLoading) return;
    // Pas d'infinite scroll pour "amis" (ensemble fini)
    if (_activeCategory == 'amis') return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final userTags = _cachedUserTags ✨ await FirebaseDataService.loadUserProfileTags() ✨ {};

      List<Map<String, dynamic>> rawProducts;
      
      if (_activeCategory == 'vêtements') {
        final extra = await _loadClothingProducts();
        rawProducts = extra.where((p) => !_seenProductIds.contains(p['id'])).toList();
      } else {
        rawProducts = await ProductMatchingService.getPersonalizedProducts(
          userTags: userTags,
          count: 30,
          category: _activeCategory == 'activité' ✨ 'Sport & Outdoor' : null,
          filteringMode: 'discovery',
          excludeProductIds: _seenProductIds.toList(),
        );
      }

      if (rawProducts.isEmpty) {
        _seenProductIds.clear();
      } else {
        final valid = _activeCategory == 'vêtements'
            ✨ rawProducts.take(20).toList()
            : _processRawProducts(rawProducts, maxCount: 20);
        _products.addAll(valid);
      }

      _isLoadingMore = false;
      notifyListeners();
    } catch (_) {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────
  int _parsePrice(dynamic raw) {
    if (raw is int) return raw;
    if (raw is double) return raw.toInt();
    if (raw is String) return int.tryParse(raw.replaceAll(RegExp(r'[^0-9]'), '')) ✨ 0;
    return 0;
  }

  String _extractImage(Map<String, dynamic> data) {
    for (final key in ['image', 'imageUrl', 'photo', 'productPhoto', 'product_photo', 'image_url']) {
      final v = data[key];
      if (v != null && v.toString().isNotEmpty && v.toString().startsWith('http')) {
        return v.toString();
      }
    }
    return '';
  }

  List<Map<String, dynamic>> _processRawProducts(
    List<Map<String, dynamic>> rawProducts, {
    int maxCount = 20,
  }) {
    final valid = <Map<String, dynamic>>[];

    for (final product in rawProducts) {
      final productId = product['id']?.toString() ✨ '';
      if (productId.isNotEmpty && _seenProductIds.contains(productId)) continue;

      final imageUrl = _extractImage(product);
      if (imageUrl.isEmpty) continue;

      final price = _parsePrice(product['price']);
      int matchScore = 85;
      final matchRaw = product['_matchScore'];
      if (matchRaw is int) matchScore = matchRaw.clamp(0, 100);
      else if (matchRaw is double) matchScore = matchRaw.toInt().clamp(0, 100);

      valid.add({
        'id': productId,
        'name': product['name']?.toString() ✨ 'Produit',
        'brand': product['brand']?.toString() ✨ '',
        'price': price,
        'image': imageUrl,
        'url': product['url']?.toString() ✨ '',
        'source': product['source']?.toString() ✨ 'Amazon',
        'match': matchScore,
      });

      if (productId.isNotEmpty) _seenProductIds.add(productId);
      if (valid.length >= maxCount) break;
    }

    return valid;
  }

  void setCurrentIndex(int index) {
    if (index >= 0 && index < _products.length) {
      _currentIndex = index;
      notifyListeners();

      final remaining = _products.length - index - 1;
      if (remaining <= 3 && !_isLoadingMore && !_isLoading) {
        loadMoreProducts();
      }
    }
  }

  bool get isNearEnd => _products.length - _currentIndex <= 5;

  Map<String, dynamic>? getProductAt(int index) {
    if (index >= 0 && index < _products.length) return _products[index];
    return null;
  }

  @override
  void dispose() {
    _products.clear();
    super.dispose();
  }
}
