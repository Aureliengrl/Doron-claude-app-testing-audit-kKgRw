import '/utils/app_logger.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/services/openai_home_service.dart';
import '/services/firebase_data_service.dart';
import '/services/product_matching_service.dart';
import '/services/product_url_service.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import '/components/cached_image.dart';
import '/components/skeleton_loader.dart';
import '/components/connection_required_dialog.dart';
import '/components/tutorial_overlay.dart';
import '/components/brand_filters.dart';
import '/components/aesthetic_buttons.dart';
import '/components/micro_interactions.dart' as micro;
import '/components/liquid_glass.dart';
import 'home_pinterest_model.dart';
import 'home_pinterest_widgets_extra.dart';
export 'home_pinterest_model.dart';

class HomePinterestWidget extends StatefulWidget {
  const HomePinterestWidget({super.key});

  static String routeName = 'HomePinterest';
  static String routePath = '/home-pinterest';

  @override
  State<HomePinterestWidget> createState() => _HomePinterestWidgetState();
}

class _HomePinterestWidgetState extends State<HomePinterestWidget> {
  late HomePinterestModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final Color violetColor = const Color(0xFF8A2BE2);
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // ==========================================================
  // SHOWCASE / TUTORIAL KEYS
  // ==========================================================
  final GlobalKey _one = GlobalKey();
  final GlobalKey _two = GlobalKey();
  final GlobalKey _three = GlobalKey();

  @override
  void initState() {
    super.initState();
    _model = HomePinterestModel();
    FirebaseDataService.setCurrentPersonContext(null);
    _loadFavorites();
    _loadProducts();

    _scrollController.addListener(_onScroll);
    _showInteractiveTutorialIfNeeded();
  }

  Future<void> _showInteractiveTutorialIfNeeded() async {
    // Check if it's the very first time launching the app with an account
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('first_time_showcase') ?? true;

    if (isFirstLaunch) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;

      // FIX: ShowCase widget was called with [_one, _two, _three] which are NEVER defined in the tree!
      // This causes a catastrophic Showcase finding loop or crash on fresh installs.
      // ShowCaseWidget.of(context).startShowCase([_one, _two, _three]);
      
      // Keep it marked as complete so it never shows again
      await prefs.setBool('first_time_showcase', false);
    }
  }

  /// Charge les favoris depuis Firebase (FlutterFlow system)
  Future<void> _loadFavorites() async {
    // Vrifier si l'utilisateur est connect
    if (FirebaseAuth.instance.currentUser == null) {
      AppLogger.debug('?? Utilisateur non connecté, favoris non chargés', 'Debug');
      // Charger les favoris locaux depuis SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        final localFavorites = prefs.getStringList('local_favorite_titles') ?? [];
        if (mounted && localFavorites.isNotEmpty) {
          setState(() {
            _model.likedProductTitles.clear();
            _model.likedProductTitles.addAll(localFavorites);
          });
          AppLogger.debug('? ${localFavorites.length} favoris chargés depuis local storage', 'Debug');
        }
      } catch (e) {
        AppLogger.debug('? Erreur chargement favoris locaux: $e', 'Debug');
      }
      return;
    }

    try {
      // Charger les favoris FlutterFlow (sans personId = favoris "en vrac")
      final favorites = await queryFavouritesRecordOnce(
        queryBuilder: (favoritesRecord) => favoritesRecord
            .where('uid', isEqualTo: currentUserReference)
            .where('personId', isNull: true),
      );

      if (mounted) {
        setState(() {
          // On ne peut pas utiliser les IDs car FlutterFlow utilise des titres
          // On va créer un Set de titres pour la comparaison
          _model.likedProductTitles.clear();
          for (var fav in favorites) {
            if (fav.product.productTitle.isNotEmpty) {
              _model.likedProductTitles.add(fav.product.productTitle);
            }
          }
        });
        AppLogger.debug('? ${_model.likedProductTitles.length} favoris chargés depuis Firebase', 'Debug');
      }
    } catch (e) {
      AppLogger.debug('? Erreur chargement favoris Firebase: $e', 'Debug');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // L'utilisateur est à 80% du scroll, charger plus de produits
      if (!_model.isLoadingMore && _model.hasMore) {
        _loadMoreProducts();
      }
    }
  }

  /// Charge les produits populaires (mode anonyme)
  Future<void> _loadPopularProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      QuerySnapshot? snapshot;

      // Tenter de charger les produits avec tri par popularité
      try {
        Query query;

        // Si catégorie spécifique, filtrer
        if (_model.activeCategory != 'Pour toi') {
          final categoryLower = _model.activeCategory.toLowerCase();
          // ATTENTION: Cette requête nécessite un index composite dans Firestore
          // Si l'index n'existe pas, on va fallback sur une requête sans orderBy
          query = FirebaseFirestore.instance
              .collection('gifts')
              .where('active', isEqualTo: true)
              .where('categories', arrayContains: categoryLower)
              .orderBy('popularity', descending: true)
              .limit(100); // Augmenté de 50 à 100 pour plus de contenu
        } else {
          query = FirebaseFirestore.instance
              .collection('gifts')
              .where('active', isEqualTo: true)
              .orderBy('popularity', descending: true)
              .limit(100); // Augmenté de 50 à 100 pour plus de contenu
        }

        snapshot = await query.get();
      } catch (firestoreError) {
        AppLogger.debug('?? Erreur requête avec orderBy (index manquant?): $firestoreError', 'Debug');
        AppLogger.debug('?? Fallback: chargement sans tri par popularité', 'Debug');

        // Fallback: requête sans orderBy (ne nécessite pas d'index composite)
        Query fallbackQuery;
        if (_model.activeCategory != 'Pour toi') {
          final categoryLower = _model.activeCategory.toLowerCase();
          fallbackQuery = FirebaseFirestore.instance
              .collection('gifts')
              .where('active', isEqualTo: true)
              .where('categories', arrayContains: categoryLower)
              .limit(100); // Augmenté de 50 à 100 pour plus de contenu
        } else {
          fallbackQuery = FirebaseFirestore.instance
              .collection('gifts')
              .where('active', isEqualTo: true)
              .limit(100); // Augmenté de 50 à 100 pour plus de contenu
        }

        snapshot = await fallbackQuery.get();
      }

      if (snapshot == null) {
        throw Exception('Failed to load products');
      }

      final products = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id.hashCode,
          'name': data['name'] ?? data['product_title'] ?? 'Produit',
          'brand': data['brand'] ?? '',
          'price': _parsePrice(data['price'] ?? data['product_price'] ?? 0),
          'image': data['image'] ?? data['product_photo'] ?? '',
          'url': data['url'] ?? data['product_url'] ?? '',
          'source': data['source'] ?? 'Amazon',
          'categories': (data['categories'] as List?)?.cast<String>() ?? [],
          'match': 0, // Pas de score de match en mode anonyme
        };
      }).toList();

      if (mounted) {
        setState(() {
          _model.setProducts(products);
          _model.setLoading(false);
          _model.hasMore = products.length >= 50;
        });
      }

      AppLogger.debug('? ${products.length} produits populaires chargés (mode anonyme)', 'Debug');
    } catch (e, stackTrace) {
      AppLogger.debug('? Erreur chargement produits populaires: $e', 'Debug');
      AppLogger.debug('Stack trace: $stackTrace', 'Debug');

      if (mounted) {
        setState(() {
          _model.setLoading(false);
          _model.errorMessage = 'Erreur de chargement';
        });
      }
    }
  }

  double _parsePrice(dynamic price) {
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      final cleaned = price.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  /// Charge les produits initiaux (12 premiers)
  Future<void> _loadProducts() async {
    // Réinitialiser la pagination
    _model.resetPagination();

    if (mounted) {
      setState(() {
        _model.setLoading(true);
      });
    }

    try {
      // Charger les tags utilisateur depuis Firebase
      final userProfileTags = await FirebaseDataService.loadUserProfileTags();

      AppLogger.debug('??? User profile tags: $userProfileTags', 'Debug');

      // Extraire et stocker le prénom
      final firstName = userProfileTags?['firstName'] as String? ?? '';
      _model.setFirstName(firstName);

      // ? TOUJOURS utiliser les tags, même vides (ProductMatchingService gère ça)
      final tagsToUse = userProfileTags ?? {};

      AppLogger.debug('?? Tags utilisés pour matching: $tagsToUse', 'Debug');

      // Charger les sections thématiques (seulement pour "Pour toi")
      if (_model.activeCategory == 'Pour toi' && userProfileTags != null) {
        try {
          final sections = await ProductMatchingService.getHomeSections(
            userTags: userProfileTags,
          );
          if (mounted) {
            setState(() {
              _model.setSections(sections);
            });
          }
        } catch (e) {
          AppLogger.debug('? Erreur chargement sections: $e', 'Debug');
        }
      } else {
        // Clear sections si on n'est pas dans "Pour toi"
        if (mounted) {
          setState(() {
            _model.setSections([]);
          });
        }
      }

      // Charger la liste des IDs de produits déjà vus depuis le cache
      final prefs = await SharedPreferences.getInstance();
      final seenProductIds = prefs.getStringList('seen_home_product_ids_${_model.activeCategory}')?.map((s) => int.tryParse(s) ?? 0).toList() ?? [];
      AppLogger.debug('?? ${seenProductIds.length} produits déjà vus dans la catégorie ${_model.activeCategory}', 'Debug');

      // ?? Générer les produits via ProductMatchingService (Firebase-first)
      AppLogger.debug('?? Appel ProductMatchingService avec ${tagsToUse.length} tags...', 'Debug');

      // Déterminer le mode de filtrage selon la catégorie
      // "Pour toi" = DISCOVERY (souple, personnalisé mais pas restrictif)
      // Autres catégories = HOME (plus strict car filtre actif)
      final filterMode = _model.activeCategory == 'Pour toi' ? 'discovery' : 'home';
      AppLogger.debug('?? Mode de filtrage: $filterMode pour catégorie "${_model.activeCategory}"', 'Debug');

      final rawProducts = await ProductMatchingService.getPersonalizedProducts(
        userTags: tagsToUse,
        count: HomePinterestModel.productsPerPage,
        category: _model.activeCategory != 'Pour toi' ? _model.activeCategory : null,
        excludeProductIds: seenProductIds,
        filteringMode: filterMode, // DISCOVERY pour "Pour toi", HOME pour les autres
      );

      AppLogger.debug('? ProductMatchingService a retourné ${rawProducts.length} produits', 'Debug');

      // Convertir au format attendu et ajouter URLs intelligentes
      final products = rawProducts.map((product) {
        return {
          'id': product['id'],
          'name': product['name'] ?? 'Produit',
          'brand': product['brand'] ?? '',
          'price': product['price'] ?? 0,
          'image': product['image'] ?? product['imageUrl'] ?? '',
          'url': ProductUrlService.generateProductUrl(product),
          'source': product['source'] ?? 'Amazon',
          'categories': product['categories'] ?? [],
          // FIX CRASH: matchScore peut être int ou double
          'match': (product['_matchScore'] is int
              ? product['_matchScore'] as int
              : (product['_matchScore'] is double ? (product['_matchScore'] as double).toInt() : 0)).clamp(0, 100),
        };
      }).toList();

      AppLogger.debug('?? ${products.length} produits convertis pour affichage', 'Debug');

      // Sauvegarder les nouveaux IDs dans le cache
      final newSeenIds = <String>[...seenProductIds.map((id) => id.toString())];
      for (var product in products) {
        final productId = product['id']?.toString() ?? '';
        if (productId.isNotEmpty && !newSeenIds.contains(productId)) {
          newSeenIds.add(productId);
        }
      }
      // Limiter à 300 IDs max pour ne pas surcharger
      if (newSeenIds.length > 300) {
        newSeenIds.removeRange(0, newSeenIds.length - 300);
      }
      await prefs.setStringList('seen_home_product_ids_${_model.activeCategory}', newSeenIds);
      AppLogger.debug('?? ${newSeenIds.length} produits dans le cache (${products.length} nouveaux ajoutés)', 'Debug');

      if (mounted) {
        setState(() {
          _model.setProducts(products);
          _model.hasMore = products.length >= HomePinterestModel.productsPerPage;
          _model.setLoading(false);
          _model.clearError(); // Clear any previous errors on success
        });
      }
    } catch (e) {
      AppLogger.debug('? Erreur chargement produits: $e', 'Debug');

      // Parser l'erreur pour extraire des détails utiles
      String errorMessage = 'Erreur de chargement';
      String errorDetails = e.toString();

      // Analyser le type d'erreur
      if (errorDetails.contains('SocketException') || errorDetails.contains('Network')) {
        errorMessage = '?? Pas de connexion';
        errorDetails = 'Vérifie ta connexion internet et tire pour rafraéchir.';
      } else if (errorDetails.contains('firebase') || errorDetails.contains('Firestore')) {
        errorMessage = '?? Erreur Firebase';
        errorDetails = 'Impossible de charger les produits depuis la base de données. Réessaye plus tard.';
      } else {
        errorMessage = '?? Erreur de chargement';
        errorDetails = 'Une erreur est survenue lors du chargement des produits.';
      }

      if (mounted) {
        setState(() {
          _model.setLoading(false);
          _model.setError(errorMessage, errorDetails);
        });
      }
    }
  }

  /// Charge plus de produits (infinite scroll)
  Future<void> _loadMoreProducts() async {
    if (_model.isLoadingMore || !_model.hasMore) return;

    if (mounted) {
      setState(() {
        _model.setLoadingMore(true);
      });
    }

    try {
      _model.incrementPage();

      // Charger les tags utilisateur (nouvelle architecture)
      final userProfileTags = await FirebaseDataService.loadUserProfileTags();
      final prefs = await SharedPreferences.getInstance();
      final seenProductIds = prefs.getStringList('seen_home_product_ids_${_model.activeCategory}')?.map((s) => int.tryParse(s) ?? 0).toList() ?? [];

      // ?? Générer plus de produits via ProductMatchingService (Firebase-first)
      final rawProducts = await ProductMatchingService.getPersonalizedProducts(
        userTags: userProfileTags ?? {},
        count: HomePinterestModel.productsPerPage,
        category: _model.activeCategory != 'Pour toi' ? _model.activeCategory : null,
        excludeProductIds: seenProductIds,
        filteringMode: "home", // Mode HOME: Strict sur sexe (basé sur soi-même)
      );

      // Convertir au format attendu et ajouter URLs intelligentes
      final products = rawProducts.map((product) {
        return {
          'id': product['id'],
          'name': product['name'] ?? 'Produit',
          'brand': product['brand'] ?? '',
          'price': product['price'] ?? 0,
          'image': product['image'] ?? product['imageUrl'] ?? '',
          'url': ProductUrlService.generateProductUrl(product),
          'source': product['source'] ?? 'Amazon',
          'categories': product['categories'] ?? [],
          // FIX CRASH: matchScore peut être int ou double
          'match': (product['_matchScore'] is int
              ? product['_matchScore'] as int
              : (product['_matchScore'] is double ? (product['_matchScore'] as double).toInt() : 0)).clamp(0, 100),
        };
      }).toList();

      // Mettre à jour le cache
      final newSeenIds = <String>[...seenProductIds.map((id) => id.toString())];
      for (var product in products) {
        final productId = product['id']?.toString() ?? '';
        if (productId.isNotEmpty && !newSeenIds.contains(productId)) {
          newSeenIds.add(productId);
        }
      }
      if (newSeenIds.length > 300) {
        newSeenIds.removeRange(0, newSeenIds.length - 300);
      }
      await prefs.setStringList('seen_home_product_ids_${_model.activeCategory}', newSeenIds);

      if (mounted) {
        setState(() {
          _model.addProducts(products);
          _model.hasMore = products.length >= HomePinterestModel.productsPerPage;
          _model.setLoadingMore(false);
        });
      }

      AppLogger.debug('? Chargé ${products.length} produits supplémentaires (page ${_model.currentPage})', 'Debug');
    } catch (e) {
      AppLogger.debug('? Erreur chargement plus de produits: $e', 'Debug');
      if (mounted) {
        setState(() {
          _model.setLoadingMore(false);
        });
      }
    }
  }

  /// Toggle favorite — écrit dans users/{uid}/favorites (Firestore rules autorisent)
  Future<void> _toggleFavorite(Map<String, dynamic> product) async {
    final user = FirebaseAuth.instance.currentUser;
    final productTitle = product['name'] ?? product['title'] ?? '';
    final isCurrentlyLiked = _model.likedProductTitles.contains(productTitle);

    // Récupérer l'image
    String productImage = '';
    for (final key in ['image', 'imageUrl', 'photo', 'productPhoto', 'product_photo']) {
      if (product[key] != null && product[key].toString().isNotEmpty) {
        productImage = product[key].toString();
        break;
      }
    }

    HapticFeedback.mediumImpact();

    // Convertir productId en int
    final productId = product['id'];
    int productIdInt = productId is int
        ? productId
        : int.tryParse(productId?.toString() ?? '') ?? productTitle.hashCode;

    // Toggle état local immédiatement pour l'UI
    if (mounted) {
      setState(() {
        _model.toggleLike(productIdInt, productTitle);
      });
    }

    // Sauvegarder toujours en local
    try {
      final prefs = await SharedPreferences.getInstance();
      final localFavorites = prefs.getStringList('local_favorite_titles') ?? [];
      if (isCurrentlyLiked) {
        localFavorites.remove(productTitle);
      } else {
        if (!localFavorites.contains(productTitle)) localFavorites.add(productTitle);
      }
      await prefs.setStringList('local_favorite_titles', localFavorites);
    } catch (_) {}

    // Si non connecté → message de connexion
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            isCurrentlyLiked
                ? 'Retiré des favoris (connectez-vous pour synchroniser)'
                : 'Ajouté aux favoris (connectez-vous pour synchroniser)',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: isCurrentlyLiked ? Colors.grey[600] : const Color(0xFF10B981),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Connexion',
            textColor: Colors.white,
            onPressed: () => context.go('/authentification'),
          ),
        ));
      }
      return;
    }

    // Sauvegarder dans users/{uid}/favorites (règles Firestore autorisent isOwner)
    try {
      final uid = user.uid;
      final favoritesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('favorites');

      if (isCurrentlyLiked) {
        // Supprimer le favori correspondant
        final snap = await favoritesRef
            .where('name', isEqualTo: productTitle)
            .limit(1)
            .get();
        for (final doc in snap.docs) {
          await doc.reference.delete();
        }
      } else {
        // Ajouter le favori
        final productUrl = product['url'] ?? ProductUrlService.generateProductUrl(product);
        final brand = product['brand'] ?? product['source'] ?? '';

        await favoritesRef.add({
          'id': productIdInt,
          'name': productTitle,
          'brand': brand,
          'image': productImage,
          'price': product['price']?.toString() ?? '',
          'url': productUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('❤️ Ajouté aux favoris !', style: GoogleFonts.poppins()),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        }
      }
    } catch (e, st) {
      AppLogger.debug('Erreur toggle favori Firebase: $e\n$st', 'Debug');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: ${e.toString().substring(0, e.toString().length.clamp(0, 80))}',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 3),
        ));
      }
    }
  }


  /// Retourne un emoji + texte court pour la catégorie
  String _getCategoryEmoji(String category) {
    final categoryLower = category.toLowerCase();

    if (categoryLower.contains('tech') || categoryLower.contains('technologie')) {
      return '?? Tech';
    } else if (categoryLower.contains('mode') || categoryLower.contains('fashion') || categoryLower.contains('vêtement')) {
      return '?? Mode';
    } else if (categoryLower.contains('maison') || categoryLower.contains('home') || categoryLower.contains('déco')) {
      return '?? Maison';
    } else if (categoryLower.contains('beauté') || categoryLower.contains('beauty') || categoryLower.contains('cosmétique')) {
      return '?? Beauté';
    } else if (categoryLower.contains('sport') || categoryLower.contains('fitness')) {
      return '? Sport';
    } else if (categoryLower.contains('food') || categoryLower.contains('gastronomie') || categoryLower.contains('cuisine')) {
      return '?? Food';
    } else if (categoryLower.contains('bien-être') || categoryLower.contains('wellness') || categoryLower.contains('spa')) {
      return '?? Bien-être';
    } else if (categoryLower.contains('art') || categoryLower.contains('créatif')) {
      return '?? Art';
    } else if (categoryLower.contains('gaming') || categoryLower.contains('jeux')) {
      return '?? Gaming';
    } else if (categoryLower.contains('lecture') || categoryLower.contains('livre')) {
      return '?? Lecture';
    } else if (categoryLower.contains('musique')) {
      return '?? Musique';
    } else if (categoryLower.contains('voyage')) {
      return '?? Voyage';
    }

    // Par défaut
    return '? $category';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: LiquidGlassTokens.pageDark,
      body: DarkPageBackground(
        addOrbs: true,
        child: RefreshIndicator(
        color: violetColor,
        onRefresh: () async {
          // Haptic feedback
          HapticFeedback.mediumImpact();

          // Charger les produits
          await _loadProducts();

          // Montrer un SnackBar de succès
          if (mounted && _model.products.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '? ${_model.products.length} cadeaux chargés !',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                backgroundColor: violetColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        // FIX: Removed AnimationLimiter wrapper which is unnecessary and problematic without stagger children
        child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // Header violet arrondi
              SliverToBoxAdapter(child: _buildHeader()),

              // Barre de recherche
              SliverToBoxAdapter(
                child: SearchBarWidget(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _model.setSearchQuery(value);
                    });
                  },
                  onClear: () {
                    _searchController.clear();
                    setState(() {
                      _model.setSearchQuery('');
                    });
                  },
                  violetColor: violetColor,
                ),
              ),

              // Quick filters
              SliverToBoxAdapter(
                child: QuickFiltersWidget(
                  showOnlyFavorites: _model.showOnlyFavorites,
                  onToggleFilter: (filter) {
                    setState(() {
                      _model.toggleQuickFilter(filter);
                    });
                  },
                  violetColor: violetColor,
                ),
              ),

              // Message de bienvenue (retir pour design plus pur)
              // SliverToBoxAdapter(child: _buildWelcomeMessage()),

              // Catégories
              SliverToBoxAdapter(child: _buildCategories()),

              // Filtres par marques
              SliverToBoxAdapter(
                child: BrandFiltersWidget(
                  activeBrandId: _model.activeBrand,
                  onBrandSelected: (brandId) {
                    setState(() {
                      _model.activeBrand = brandId;
                    });
                  },
                  primaryColor: violetColor,
                ),
              ),

              // Filtres par prix
              SliverToBoxAdapter(child: _buildPriceFilters()),

              // Sections thématiques désactivées - Pinterest uniquement
              // if (_model.sections.isNotEmpty) ...[
              //   SliverToBoxAdapter(child: _buildSections()),
              //   const SliverToBoxAdapter(child: SizedBox(height: 16)),
              // ],

              // Grille Pinterest 2 colonnes
              _buildPinterestGrid(),

              // Loader pour infinite scroll
              if (_model.isLoadingMore)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: violetColor,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),

              // Espacement pour la bottom nav
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ), // CustomScrollView
      ), // RefreshIndicator
    ), // DarkPageBackground
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF8A2BE2),
            const Color(0xFFEC4899),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8A2BE2).withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFFEC4899).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              micro.ShimmerEffect(
                shimmerColor: Colors.white,
                duration: const Duration(milliseconds: 3000),
                child: Text(
                  _model.isAnonymousMode
                      ? 'Découvre ??'
                      : (_model.firstName.isNotEmpty
                          ? 'Salut ${_model.firstName} ! ??'
                          : 'Accueil'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _model.isAnonymousMode
                    ? 'Idées cadeaux populaires'
                    : 'Voici tes inspirations cadeaux',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome,
            color: Color(0xFFFBBF24),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _model.isAnonymousMode
                  ? 'Mode découverte ??\nLes cadeaux les plus populaires du moment'
                  : (_model.firstName.isNotEmpty
                      ? 'Bienvenue ${_model.firstName} !\nVoici ta sélection personnalisée'
                      : 'Bienvenue !\nVoici ta sélection personnalisée'),
              style: GoogleFonts.poppins(
                color: const Color(0xFF4B5563),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24, bottom: 8), // Aligné avec 24
          child: Text(
            'Categories',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
        SizedBox(
          height: 56, // Hauteur uniformisée avec les marques (56)
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24), // Padding uniforme
            scrollDirection: Axis.horizontal,
            itemCount: _model.categories.length,
            itemBuilder: (context, index) {
              final category = _model.categories[index];
              final isActive = _model.activeCategory == category['name'];

          return Padding(
            padding: const EdgeInsets.only(right: 16), // Espacement uniforme constant (16)
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Haptic feedback
                  HapticFeedback.lightImpact();
                  setState(() {
                    _model.activeCategory = category['name'] as String;
                  });
                  _loadProducts(); // Recharger les produits pour la nouvelle catégorie
                },
                borderRadius: BorderRadius.circular(50),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? violetColor
                        : violetColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: violetColor.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category['emoji'] as String,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        category['name'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : violetColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: 100 * index),
                duration: 300.ms,
              )
              .slideX(
                begin: -0.2,
                end: 0,
                delay: Duration(milliseconds: 100 * index),
                duration: 300.ms,
                curve: Curves.easeOut,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPriceFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: _model.priceFilters.length,
            itemBuilder: (context, index) {
              final filter = _model.priceFilters[index];
              final isActive = _model.activePriceFilter == filter['id'];

              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _model.activePriceFilter = filter['id'] as String;
                      });
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFEC4899) // Rose pour différencier
                            : const Color(0xFFEC4899).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFEC4899).withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Text(
                        filter['name'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : const Color(0xFFEC4899),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _model.sections.map((section) {
        final title = section['title'] as String? ?? '';
        final subtitle = section['subtitle'] as String? ?? '';
        final products = section['products'] as List<Map<String, dynamic>>? ?? [];

        if (products.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            // Titre de la section avec flèche
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  // Compteur de produits dans la section
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: violetColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${products.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: violetColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Liste horizontale de produits
            SizedBox(
              height: 260,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildSectionProductCard(product),
                  );
                },
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSectionProductCard(Map<String, dynamic> product) {
    final isLiked = _model.likedProductTitles.contains(product['name'] ?? '');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _model.selectedProduct = product;
          });
          _showProductDetail(product);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image avec coeur et wishlist
              Stack(
                children: [
                  ProductImage(
                    imageUrl: product['image'] as String? ?? '',
                    height: 160,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  // Bouton wishlist
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showWishlistModal(product);
                        },
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.bookmark_border,
                            color: violetColor,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Bouton coeur
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _toggleFavorite(product),
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isLiked ? Colors.red : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.white : const Color(0xFF374151),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Info produit
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] as String? ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, curve: Curves.easeOut)
        .slideX(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }

  Widget _buildPinterestGrid() {
    // Afficher des skeletons pendant le chargement initial
    if (_model.isLoading) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => const ProductCardSkeleton(),
            childCount: 6, // 6 skeletons pendant le chargement
          ),
        ),
      );
    }

    // Sparer en 2 colonnes (avec filtrage par prix)
    final filteredProducts = _model.getFilteredProducts();

    // Afficher l'erreur si prsente
    if (_model.errorMessage != null) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icne d'erreur
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 50,
                    color: Colors.red[400],
                  ),
                ),
                const SizedBox(height: 20),

                // Titre de l'erreur
                Text(
                  _model.errorMessage!,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Dtails de l'erreur
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!, width: 1),
                  ),
                  child: Text(
                    _model.errorDetails ?? 'Erreur inconnue',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.red[900],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),

                // Bouton ressayer
                SizedBox(
                  width: 200,
                  child: PrimaryGradientButton(
                    onPressed: () {
                      _model.clearError();
                      _loadProducts();
                    },
                    text: 'Ressayer',
                    icon: Icons.refresh,
                    gradientColors: [Colors.red[600]!, Colors.red[400]!],
                    height: 50,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Afficher un message si aucun produit (ou aucun aprs filtrage)
    if (_model.products.isEmpty || filteredProducts.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icne avec animation
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: violetColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.card_giftcard,
                          size: 60,
                          color: violetColor.withOpacity(0.6),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  filteredProducts.isEmpty && _model.products.isNotEmpty
                      ? 'Oups, aucun produit !'
                      : 'Oups, on a rien trouv !',
                  style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  filteredProducts.isEmpty && _model.products.isNotEmpty
                      ? 'Essaie de changer de filtre de prix ou de catgorie'
                      : 'Essaie de changer de catgorie ou tire pour rafrachir',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF6B7280),
                    fontSize: 15,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                // Bouton de rafrachissement avec effet tap scale
                micro.TapScaleEffect(
                  onTap: () async {
                    await _loadProducts();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [violetColor, const Color(0xFFEC4899)],
                      ),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: violetColor.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Rafrachir',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    // Layout Masonry dsordonn faon Pinterest
    // Plus de colonnes et moins d'espacement pour un effet plus dense et inspirant
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2, // 2 colonnes pour garder des produits bien visibles
        mainAxisSpacing: 8, // Rduit pour effet "dans tous les sens"
        crossAxisSpacing: 8,
        childCount: filteredProducts.length,
        itemBuilder: (context, index) {
          final product = filteredProducts[index];
          // FIX: Removed flutter_staggered_animations wrappers (AnimationConfiguration, SlideAnimation, FadeInAnimation).
          // These wrappers combined with SliverMasonryGrid cause an infinite layout measure deadlock on iOS.
          // The product card already uses flutter_animate (.animate().fadeIn().slideY()) which is much safer.
          return _buildProductCard(product, index);
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, int index) {
    final isLiked = _model.likedProductTitles.contains(product['name'] ?? '');

    return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Haptic feedback
            HapticFeedback.lightImpact();
            setState(() {
              _model.selectedProduct = product;
            });
            _showProductDetail(product);
          },
          borderRadius: BorderRadius.circular(12),
          splashColor: violetColor.withOpacity(0.1),
          highlightColor: violetColor.withOpacity(0.05),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8A2BE2).withOpacity(0.08),
                  blurRadius: 20,
                  spreadRadius: -2,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image avec badge de match
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12), // Coins moins arrondis
                    // FIX: Ensure Image always has a fixed size via AspectRatio before it loads
                    // This explicitly prevents SliverMasonryGrid from infinite layout shift loops on image load.
                    // We use pseudo-random aspect ratios for a stable Pinterest look without image size thrashing.
                    child: AspectRatio(
                      aspectRatio: [0.8, 1.25, 0.9, 1.1, 1.4, 0.75][index % 6],
                      child: ProductImage(
                        imageUrl: product['image'] as String? ?? '',
                        height: null,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  ),

                  // Badge de match en haut  droite
                  if (product['match'] != null && product['match'] > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [violetColor, const Color(0xFFEC4899)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: violetColor.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${product['match']}%',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Badge like/favoris en haut  gauche
                  if (isLiked)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite,
                          size: 16,
                          color: Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate()
        .fadeIn(
          delay: Duration(milliseconds: 50 * index),
          duration: 400.ms,
        )
        .slideY(
          begin: 0.2,
          end: 0,
          delay: Duration(milliseconds: 50 * index),
          duration: 400.ms,
          curve: Curves.easeOut,
        );
  }

  /// Track product views in anonymous mode and trigger connection prompt after 10 UNIQUE views
  Future<void> _trackProductView(Map<String, dynamic> product) async {
    if (!_model.isAnonymousMode) return;
    if (_model.hasShownConnectionPrompt) return;

    final productId = product['id'] as int? ?? product['name'].hashCode;

    // Ajouter au Set (ne compte que si c'est un nouveau produit)
    final wasNew = _model.uniqueProductsViewed.add(productId);

    if (wasNew) {
      AppLogger.debug('?? Mode anonyme: ${_model.uniqueProductsViewed.length} produits uniques vus', 'Debug');

      // Trigger aprs 10 produits UNIQUES vus
      if (_model.uniqueProductsViewed.length >= 10) {
        _model.hasShownConnectionPrompt = true;

        // Afficher le dialog de connexion
        await showConnectionRequiredDialog(
          context,
          title: 'Tu adores dcouvrir de nouveaux produits !',
          message: 'Cre ton compte pour recevoir des suggestions ultra-personnalises et ne plus jamais perdre tes favoris',
        );
      }
    }
  }

  void _showProductDetail(Map<String, dynamic> product) {
    // Track product view in anonymous mode (produits uniques seulement)
    _trackProductView(product);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isLiked = _model.likedProductTitles.contains(product['name'] ?? '');

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 60,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image avec boutons
                  Stack(
                    children: [
                      ProductImage(
                        imageUrl: product['image'] as String? ?? '',
                        height: 350,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      // Bouton fermer
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Color(0xFF111827),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Bouton wishlist
                      Positioned(
                        top: 12,
                        right: 64,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                              _showWishlistModal(product);
                            },
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.bookmark_border,
                                color: violetColor,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Bouton coeur - Appel simplifi de _toggleFavorite
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              AppLogger.debug('?? Dialog: Clic sur cœur pour "${product['name']}"', 'Debug');

                              // Appeler la fonction centralisée
                              await _toggleFavorite(product);

                              // Rafraéchir l'UI du dialog
                              setDialogState(() {
                                AppLogger.debug('?? Dialog: Rafraéchissement UI après toggle', 'Debug');
                              });
                            },
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isLiked
                                    ? Colors.red
                                    : Colors.white.withOpacity(0.95),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                color: isLiked ? Colors.white : const Color(0xFF111827),
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

              // Détails du produit
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: violetColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        product['brand'] as String? ?? product['source'] as String? ?? 'Amazon',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: violetColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      product['name'] as String? ?? 'Produit',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${product['price'] ?? 0}€',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: violetColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (product['description'] != null && (product['description'] as String).isNotEmpty)
                      Text(
                        product['description'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                          height: 1.6,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        'Cadeau parfait par ${product['brand'] as String? ?? 'une marque de qualité'}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                          height: 1.6,
                        ),
                      ),
                    const SizedBox(height: 20),
                    // Bouton Voir sur...
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Générer une URL de produit intelligente (=95% précision)
                          final url = ProductUrlService.generateProductUrl(product);
                          if (url.isNotEmpty) {
                            try {
                              final uri = Uri.parse(url);
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } catch (e) {
                              AppLogger.debug('? Erreur ouverture URL: $e', 'Debug');
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: violetColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: violetColor.withOpacity(0.4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Voir sur ${product['brand'] ?? product['source'] ?? 'Amazon'}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.open_in_new,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
          );
        },
      ),
    );
  }

  /// Affiche le modal de sélection de wishlist
  Future<void> _showWishlistModal(Map<String, dynamic> product) async {
    // Vérifier si l'utilisateur est connecté
    final prefs = await SharedPreferences.getInstance();
    final isAnonymous = prefs.getBool('anonymous_mode') ?? false;

    if (isAnonymous || !loggedIn) {
      if (mounted) {
        await showConnectionRequiredDialog(
          context,
          title: 'Connexion requise',
          message: 'Crée ton compte pour organiser tes cadeaux en wishlists',
        );
      }
      return;
    }

    // Charger les wishlists existantes
    final wishlists = await FirebaseDataService.loadWishlists();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Titre
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.bookmark_border, color: violetColor, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ajouter à une wishlist',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          Text(
                            product['name'] as String? ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Liste des wishlists
              if (wishlists.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.list_alt, size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune wishlist',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crée ta première wishlist ci-dessous',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: wishlists.length,
                    itemBuilder: (context, index) {
                      final wishlist = wishlists[index];
                      final giftCount = (wishlist['giftIds'] as List?)?.length ?? 0;

                      return ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: violetColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.bookmark,
                            color: violetColor,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          wishlist['name'] as String? ?? 'Wishlist',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        subtitle: Text(
                          '$giftCount cadeau${giftCount > 1 ? 's' : ''}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        trailing: Icon(
                          Icons.add_circle,
                          color: violetColor,
                          size: 28,
                        ),
                        onTap: () async {
                          Navigator.pop(context);
                          await _addToWishlist(product, wishlist['id'] as String);
                        },
                      );
                    },
                  ),
                ),

              const Divider(height: 1),

              // Bouton créer nouvelle wishlist
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _createNewWishlist(product);
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text(
                      'Créer une nouvelle wishlist',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: violetColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Crée une nouvelle wishlist et y ajoute le produit
  Future<void> _createNewWishlist(Map<String, dynamic> product) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Nouvelle wishlist',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Nom de la wishlist',
                hintText: 'Ex: Anniversaire Maman',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: violetColor, width: 2),
                ),
              ),
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (optionnel)',
                hintText: 'Ex: Idées cadeaux pour ses 50 ans',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: violetColor, width: 2),
                ),
              ),
              style: GoogleFonts.poppins(),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: violetColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Créer',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      final wishlistId = await FirebaseDataService.createWishlist(
        name: nameController.text,
        description: descriptionController.text,
      );

      if (wishlistId != null) {
        await _addToWishlist(product, wishlistId);
      }
    }
  }

  /// Ajoute un produit à une wishlist
  Future<void> _addToWishlist(Map<String, dynamic> product, String wishlistId) async {
    try {
      // Créer d'abord le favori avec le produit
      final productTitle = product['name'] as String? ?? '';
      final productImage = product['image'] as String? ?? '';
      final productUrl = product['url'] ?? ProductUrlService.generateProductUrl(product);
      final brandOrSource = product['brand'] ?? product['source'] ?? 'Amazon';

      // Ajouter aux favoris Firebase avec wishlistId
      final docRef = await FavouritesRecord.collection.add(
        createFavouritesRecordData(
          uid: currentUserReference,
          platform: brandOrSource.toString().toLowerCase(),
          timeStamp: DateTime.now(),
          personId: null,
          product: ProductsStruct(
            productTitle: productTitle,
            productPrice: '${product['price'] ?? 0}€',
            productUrl: productUrl,
            productPhoto: productImage,
            productStarRating: '',
            productOriginalPrice: '',
            productNumRatings: 0,
            platform: brandOrSource.toString().toLowerCase(),
          ),
        ),
      );

      // Ajouter à la wishlist
      await FirebaseDataService.addToWishlist(wishlistId, docRef.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.bookmark, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ajouté à la wishlist !',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      AppLogger.debug('? Erreur ajout wishlist: $e', 'Debug');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de l\'ajout à la wishlist',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

}
