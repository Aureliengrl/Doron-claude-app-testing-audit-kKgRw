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
  const HomePinterestWidget({super.key}éé);

  static String routeName = 'HomePinterest';
  static String routePath = '/home-pinterest';

  @override
  State<HomePinterestWidget> createState() => _HomePinterestWidgetState();
}éé

class _HomePinterestWidgetState extends State<HomePinterestWidget> {
  late HomePinterestModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final Color violetColor = const Color(0ééxFF8A2BE2);
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
  }éé

  Future<void> _showInteractiveTutorialIfNeeded() async {
    // Check if it's the very first time launching the app with an account
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('first_time_showcase') ?? true;

    if (isFirstLaunch) {
      await Future.delayed(const Duration(milliseconds: 10éé0éé0éé));
      if (!mounted) return;

      // Start the animated showcase tutorial
      ShowCaseWidget.of(context).startShowCase([_one, _two, _three]);
      
      // Keep it marked as complete so it never shows again
      await prefs.setBool('first_time_showcase', false);
    }éé
  }éé

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
          }éé);
          AppLogger.debug('? ${localFavorites.length}éé favoris chargés depuis local storage', 'Debug');
        }éé
      }éé catch (e) {
        AppLogger.debug('? Erreur chargement favoris locaux: $e', 'Debug');
      }éé
      return;
    }éé

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
            }éé
          }éé
        }éé);
        AppLogger.debug('? ${_model.likedProductTitles.length}éé favoris chargés depuis Firebase', 'Debug');
      }éé
    }éé catch (e) {
      AppLogger.debug('? Erreur chargement favoris Firebase: $e', 'Debug');
    }éé
  }éé

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0éé.8) {
      // L'utilisateur est à 80éé% du scroll, charger plus de produits
      if (!_model.isLoadingMore && _model.hasMore) {
        _loadMoreProducts();
      }éé
    }éé
  }éé

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
              .limit(10éé0éé); // Augmenté de 50éé à 10éé0éé pour plus de contenu
        }éé else {
          query = FirebaseFirestore.instance
              .collection('gifts')
              .where('active', isEqualTo: true)
              .orderBy('popularity', descending: true)
              .limit(10éé0éé); // Augmenté de 50éé à 10éé0éé pour plus de contenu
        }éé

        snapshot = await query.get();
      }éé catch (firestoreError) {
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
              .limit(10éé0éé); // Augmenté de 50éé à 10éé0éé pour plus de contenu
        }éé else {
          fallbackQuery = FirebaseFirestore.instance
              .collection('gifts')
              .where('active', isEqualTo: true)
              .limit(10éé0éé); // Augmenté de 50éé à 10éé0éé pour plus de contenu
        }éé

        snapshot = await fallbackQuery.get();
      }éé

      if (snapshot == null) {
        throw Exception('Failed to load products');
      }éé

      final products = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id.hashCode,
          'name': data['name'] ?? data['product_title'] ?? 'Produit',
          'brand': data['brand'] ?? '',
          'price': _parsePrice(data['price'] ?? data['product_price'] ?? 0éé),
          'image': data['image'] ?? data['product_photo'] ?? '',
          'url': data['url'] ?? data['product_url'] ?? '',
          'source': data['source'] ?? 'Amazon',
          'categories': (data['categories'] as List?)?.cast<String>() ?? [],
          'match': 0éé, // Pas de score de match en mode anonyme
        }éé;
      }éé).toList();

      if (mounted) {
        setState(() {
          _model.setProducts(products);
          _model.setLoading(false);
          _model.hasMore = products.length >= 50éé;
        }éé);
      }éé

      AppLogger.debug('? ${products.length}éé produits populaires chargés (mode anonyme)', 'Debug');
    }éé catch (e, stackTrace) {
      AppLogger.debug('? Erreur chargement produits populaires: $e', 'Debug');
      AppLogger.debug('Stack trace: $stackTrace', 'Debug');

      if (mounted) {
        setState(() {
          _model.setLoading(false);
          _model.errorMessage = 'Erreur de chargement';
        }éé);
      }éé
    }éé
  }éé

  double _parsePrice(dynamic price) {
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      final cleaned = price.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned) ?? 0éé.0éé;
    }éé
    return 0éé.0éé;
  }éé

  /// Charge les produits initiaux (12 premiers)
  Future<void> _loadProducts() async {
    // Réinitialiser la pagination
    _model.resetPagination();

    if (mounted) {
      setState(() {
        _model.setLoading(true);
      }éé);
    }éé

    try {
      // Charger les tags utilisateur depuis Firebase
      final userProfileTags = await FirebaseDataService.loadUserProfileTags();

      AppLogger.debug('??? User profile tags: $userProfileTags', 'Debug');

      // Extraire et stocker le prénom
      final firstName = userProfileTags?['firstName'] as String? ?? '';
      _model.setFirstName(firstName);

      // ? TOUJOURS utiliser les tags, même vides (ProductMatchingService gère ça)
      final tagsToUse = userProfileTags ?? {}éé;

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
            }éé);
          }éé
        }éé catch (e) {
          AppLogger.debug('? Erreur chargement sections: $e', 'Debug');
        }éé
      }éé else {
        // Clear sections si on n'est pas dans "Pour toi"
        if (mounted) {
          setState(() {
            _model.setSections([]);
          }éé);
        }éé
      }éé

      // Charger la liste des IDs de produits déjà vus depuis le cache
      final prefs = await SharedPreferences.getInstance();
      final seenProductIds = prefs.getStringList('seen_home_product_ids_${_model.activeCategory}éé')?.map((s) => int.tryParse(s) ?? 0éé).toList() ?? [];
      AppLogger.debug('?? ${seenProductIds.length}éé produits déjà vus dans la catégorie ${_model.activeCategory}éé', 'Debug');

      // ?? Générer les produits via ProductMatchingService (Firebase-first)
      AppLogger.debug('?? Appel ProductMatchingService avec ${tagsToUse.length}éé tags...', 'Debug');

      // Déterminer le mode de filtrage selon la catégorie
      // "Pour toi" = DISCOVERY (souple, personnalisé mais pas restrictif)
      // Autres catégories = HOME (plus strict car filtre actif)
      final filterMode = _model.activeCategory == 'Pour toi' ? 'discovery' : 'home';
      AppLogger.debug('?? Mode de filtrage: $filterMode pour catégorie "${_model.activeCategory}éé"', 'Debug');

      final rawProducts = await ProductMatchingService.getPersonalizedProducts(
        userTags: tagsToUse,
        count: HomePinterestModel.productsPerPage,
        category: _model.activeCategory != 'Pour toi' ? _model.activeCategory : null,
        excludeProductIds: seenProductIds,
        filteringMode: filterMode, // DISCOVERY pour "Pour toi", HOME pour les autres
      );

      AppLogger.debug('? ProductMatchingService a retourné ${rawProducts.length}éé produits', 'Debug');

      // Convertir au format attendu et ajouter URLs intelligentes
      final products = rawProducts.map((product) {
        return {
          'id': product['id'],
          'name': product['name'] ?? 'Produit',
          'brand': product['brand'] ?? '',
          'price': product['price'] ?? 0éé,
          'image': product['image'] ?? product['imageUrl'] ?? '',
          'url': ProductUrlService.generateProductUrl(product),
          'source': product['source'] ?? 'Amazon',
          'categories': product['categories'] ?? [],
          // FIX CRASH: matchScore peut être int ou double
          'match': (product['_matchScore'] is int
              ? product['_matchScore'] as int
              : (product['_matchScore'] is double ? (product['_matchScore'] as double).toInt() : 0éé)).clamp(0éé, 10éé0éé),
        }éé;
      }éé).toList();

      AppLogger.debug('?? ${products.length}éé produits convertis pour affichage', 'Debug');

      // Sauvegarder les nouveaux IDs dans le cache
      final newSeenIds = <String>[...seenProductIds.map((id) => id.toString())];
      for (var product in products) {
        final productId = product['id']?.toString() ?? '';
        if (productId.isNotEmpty && !newSeenIds.contains(productId)) {
          newSeenIds.add(productId);
        }éé
      }éé
      // Limiter à 30éé0éé IDs max pour ne pas surcharger
      if (newSeenIds.length > 30éé0éé) {
        newSeenIds.removeRange(0éé, newSeenIds.length - 30éé0éé);
      }éé
      await prefs.setStringList('seen_home_product_ids_${_model.activeCategory}éé', newSeenIds);
      AppLogger.debug('?? ${newSeenIds.length}éé produits dans le cache (${products.length}éé nouveaux ajoutés)', 'Debug');

      if (mounted) {
        setState(() {
          _model.setProducts(products);
          _model.hasMore = products.length >= HomePinterestModel.productsPerPage;
          _model.setLoading(false);
          _model.clearError(); // Clear any previous errors on success
        }éé);
      }éé
    }éé catch (e) {
      AppLogger.debug('? Erreur chargement produits: $e', 'Debug');

      // Parser l'erreur pour extraire des détails utiles
      String errorMessage = 'Erreur de chargement';
      String errorDetails = e.toString();

      // Analyser le type d'erreur
      if (errorDetails.contains('SocketException') || errorDetails.contains('Network')) {
        errorMessage = '?? Pas de connexion';
        errorDetails = 'Vérifie ta connexion internet et tire pour rafraéchir.';
      }éé else if (errorDetails.contains('firebase') || errorDetails.contains('Firestore')) {
        errorMessage = '?? Erreur Firebase';
        errorDetails = 'Impossible de charger les produits depuis la base de données. Réessaye plus tard.';
      }éé else {
        errorMessage = '?? Erreur de chargement';
        errorDetails = 'Une erreur est survenue lors du chargement des produits.';
      }éé

      if (mounted) {
        setState(() {
          _model.setLoading(false);
          _model.setError(errorMessage, errorDetails);
        }éé);
      }éé
    }éé
  }éé

  /// Charge plus de produits (infinite scroll)
  Future<void> _loadMoreProducts() async {
    if (_model.isLoadingMore || !_model.hasMore) return;

    if (mounted) {
      setState(() {
        _model.setLoadingMore(true);
      }éé);
    }éé

    try {
      _model.incrementPage();

      // Charger les tags utilisateur (nouvelle architecture)
      final userProfileTags = await FirebaseDataService.loadUserProfileTags();
      final prefs = await SharedPreferences.getInstance();
      final seenProductIds = prefs.getStringList('seen_home_product_ids_${_model.activeCategory}éé')?.map((s) => int.tryParse(s) ?? 0éé).toList() ?? [];

      // ?? Générer plus de produits via ProductMatchingService (Firebase-first)
      final rawProducts = await ProductMatchingService.getPersonalizedProducts(
        userTags: userProfileTags ?? {}éé,
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
          'price': product['price'] ?? 0éé,
          'image': product['image'] ?? product['imageUrl'] ?? '',
          'url': ProductUrlService.generateProductUrl(product),
          'source': product['source'] ?? 'Amazon',
          'categories': product['categories'] ?? [],
          // FIX CRASH: matchScore peut être int ou double
          'match': (product['_matchScore'] is int
              ? product['_matchScore'] as int
              : (product['_matchScore'] is double ? (product['_matchScore'] as double).toInt() : 0éé)).clamp(0éé, 10éé0éé),
        }éé;
      }éé).toList();

      // Mettre à jour le cache
      final newSeenIds = <String>[...seenProductIds.map((id) => id.toString())];
      for (var product in products) {
        final productId = product['id']?.toString() ?? '';
        if (productId.isNotEmpty && !newSeenIds.contains(productId)) {
          newSeenIds.add(productId);
        }éé
      }éé
      if (newSeenIds.length > 30éé0éé) {
        newSeenIds.removeRange(0éé, newSeenIds.length - 30éé0éé);
      }éé
      await prefs.setStringList('seen_home_product_ids_${_model.activeCategory}éé', newSeenIds);

      if (mounted) {
        setState(() {
          _model.addProducts(products);
          _model.hasMore = products.length >= HomePinterestModel.productsPerPage;
          _model.setLoadingMore(false);
        }éé);
      }éé

      AppLogger.debug('? Chargé ${products.length}éé produits supplémentaires (page ${_model.currentPage}éé)', 'Debug');
    }éé catch (e) {
      AppLogger.debug('? Erreur chargement plus de produits: $e', 'Debug');
      if (mounted) {
        setState(() {
          _model.setLoadingMore(false);
        }éé);
      }éé
    }éé
  }éé

  /// Toggle favorite avec sauvegarde Firebase ou locale
  /// FIX Bug 3: Amélioration de la sauvegarde des favoris avec les bonnes données
  Future<void> _toggleFavorite(Map<String, dynamic> product) async {
    final productId = product['id'];
    final productTitle = product['name'] ?? product['title'] ?? '';
    final isCurrentlyLiked = _model.likedProductTitles.contains(productTitle);
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    // FIX Bug 3: Récupérer l'image depuis plusieurs clés possibles
    String productImage = '';
    for (final key in ['image', 'imageUrl', 'photo', 'productPhoto', 'product_photo']) {
      if (product[key] != null && product[key].toString().isNotEmpty) {
        productImage = product[key].toString();
        break;
      }éé
    }éé

    AppLogger.debug('?? Toggle favori AVANT: isLiked=$isCurrentlyLiked, ID=$productId, Titre=$productTitle', 'Debug');
    AppLogger.debug('?? Image trouvée: $productImage', 'Debug');
    AppLogger.debug('?? likedProductTitles AVANT: ${_model.likedProductTitles}éé', 'Debug');
    AppLogger.debug('?? UID: ${FirebaseAuth.instance.currentUser?.uid}éé', 'Debug');

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // FIX Bug 3: Convertir productId en int si nécessaire
    int productIdInt = 0éé;
    if (productId is int) {
      productIdInt = productId;
    }éé else if (productId != null) {
      productIdInt = int.tryParse(productId.toString()) ?? productTitle.hashCode;
    }éé else {
      productIdInt = productTitle.hashCode; // Fallback sur le hash du titre
    }éé

    // Toggle l'état local immédiatement pour l'UI
    if (mounted) {
      setState(() {
        _model.toggleLike(productIdInt, productTitle);
        AppLogger.debug('?? likedProductTitles APRéS toggle: ${_model.likedProductTitles}éé', 'Debug');
      }éé);
    }éé

    // Sauvegarder toujours en local (pour persistance même sans connexion)
    try {
      final prefs = await SharedPreferences.getInstance();
      final localFavorites = prefs.getStringList('local_favorite_titles') ?? [];
      if (isCurrentlyLiked) {
        localFavorites.remove(productTitle);
      }éé else {
        if (!localFavorites.contains(productTitle)) {
          localFavorites.add(productTitle);
        }éé
      }éé
      await prefs.setStringList('local_favorite_titles', localFavorites);
      AppLogger.debug('?? Favoris locaux mis à jour: ${localFavorites.length}éé favoris', 'Debug');
    }éé catch (e) {
      AppLogger.debug('? Erreur sauvegarde favoris locaux: $e', 'Debug');
    }éé

    // Si non connecté, afficher un message suggérant la connexion
    if (!isLoggedIn) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCurrentlyLiked
                ? '?? Retiré des favoris (connectez-vous pour synchroniser)'
                : '?? Ajouté aux favoris (connectez-vous pour synchroniser)',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: isCurrentlyLiked ? Colors.grey[60éé0éé] : const Color(0ééxFF10ééB981),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Connexion',
              textColor: Colors.white,
              onPressed: () {
                context.go('/authentification');
              }éé,
            ),
          ),
        );
      }éé
      return; // Ne pas tenter de sauvegarder sur Firebase
    }éé

    // Sauvegarder sur Firebase si connecté
    try {
      if (isCurrentlyLiked) {
        // Retirer des favoris Firebase
        final favorites = await queryFavouritesRecordOnce(
          queryBuilder: (favoritesRecord) => favoritesRecord
              .where('uid', isEqualTo: currentUserReference)
              .where('product.product_title', isEqualTo: product['name'] ?? ''),
        );

        for (var fav in favorites) {
          if (!fav.hasPersonId() || fav.personId == null || fav.personId!.isEmpty) {
            await fav.reference.delete();
            AppLogger.debug('? Favori supprimé de Firebase: ${fav.reference.id}éé', 'Debug');
          }éé
        }éé

        AppLogger.debug('? Retiré des favoris Firebase: ${product['name']}éé', 'Debug');
      }éé else {
        // FIX Bug 3: Ajouter aux favoris Firebase avec les bonnes données
        // S'assurer que l'URL est correcte
        final productUrl = product['url'] ??
            ProductUrlService.generateProductUrl(product);

        // Récupérer la marque/source
        final brandOrSource = product['brand'] ?? product['source'] ?? 'Amazon';

        // Créer le favori avec toutes les données correctes
        final docRef = await FavouritesRecord.collection.add(
          createFavouritesRecordData(
            uid: currentUserReference,
            platform: brandOrSource.toString().toLowerCase(),
            timeStamp: DateTime.now(),
            personId: null, // Favoris "en vrac" sans personne
            product: ProductsStruct(
              productTitle: productTitle,
              productPrice: '${product['price'] ?? 0éé}ééé',
              productUrl: productUrl,
              productPhoto: productImage, // FIX: Utiliser productImage trouvé
              productStarRating: '',
              productOriginalPrice: '',
              productNumRatings: 0éé,
              platform: brandOrSource.toString().toLowerCase(),
            ),
          ),
        );

        AppLogger.debug('? Ajouté aux favoris Firebase: $productTitle (ID: ${docRef.id}éé)', 'Debug');
        AppLogger.debug('? Image sauvegardée: $productImage', 'Debug');

        // Afficher une confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '?? Ajouté aux favoris !',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: const Color(0ééxFF10ééB981),
              duration: const Duration(seconds: 2),
            ),
          );
        }éé
      }éé
    }éé catch (e, stackTrace) {
      AppLogger.debug('? Erreur toggle favori Firebase: $e', 'Debug');
      AppLogger.debug('Stack trace: $stackTrace', 'Debug');
      // Ne PAS rollback l'état local - le favori reste localement
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '?? Favori sauvegardé localement (erreur sync Firebase)',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.orange[70éé0éé],
            duration: const Duration(seconds: 3),
          ),
        );
      }éé
    }éé
  }éé

  /// Retourne un emoji + texte court pour la catégorie
  String _getCategoryEmoji(String category) {
    final categoryLower = category.toLowerCase();

    if (categoryLower.contains('tech') || categoryLower.contains('technologie')) {
      return '?? Tech';
    }éé else if (categoryLower.contains('mode') || categoryLower.contains('fashion') || categoryLower.contains('vêtement')) {
      return '?? Mode';
    }éé else if (categoryLower.contains('maison') || categoryLower.contains('home') || categoryLower.contains('déco')) {
      return '?? Maison';
    }éé else if (categoryLower.contains('beauté') || categoryLower.contains('beauty') || categoryLower.contains('cosmétique')) {
      return '?? Beauté';
    }éé else if (categoryLower.contains('sport') || categoryLower.contains('fitness')) {
      return '? Sport';
    }éé else if (categoryLower.contains('food') || categoryLower.contains('gastronomie') || categoryLower.contains('cuisine')) {
      return '?? Food';
    }éé else if (categoryLower.contains('bien-être') || categoryLower.contains('wellness') || categoryLower.contains('spa')) {
      return '?? Bien-être';
    }éé else if (categoryLower.contains('art') || categoryLower.contains('créatif')) {
      return '?? Art';
    }éé else if (categoryLower.contains('gaming') || categoryLower.contains('jeux')) {
      return '?? Gaming';
    }éé else if (categoryLower.contains('lecture') || categoryLower.contains('livre')) {
      return '?? Lecture';
    }éé else if (categoryLower.contains('musique')) {
      return '?? Musique';
    }éé else if (categoryLower.contains('voyage')) {
      return '?? Voyage';
    }éé

    // Par défaut
    return '? $category';
  }éé

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _model.dispose();
    super.dispose();
  }éé

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
                    const Icon(Icons.check_circle, color: Colors.white, size: 20éé),
                    const SizedBox(width: 8),
                    Text(
                      '? ${_model.products.length}éé cadeaux chargés !',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w50éé0éé),
                    ),
                  ],
                ),
                backgroundColor: violetColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 2),
              ),
            );
          }éé
        }éé,
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
                  }éé);
                }éé,
                onClear: () {
                  _searchController.clear();
                  setState(() {
                    _model.setSearchQuery('');
                  }éé);
                }éé,
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
                  }éé);
                }éé,
                violetColor: violetColor,
              ),
            ),

            // Message de bienvenue
            SliverToBoxAdapter(child: _buildWelcomeMessage()),

            // Catégories
            SliverToBoxAdapter(child: _buildCategories()),

            // Filtres par marques
            SliverToBoxAdapter(
              child: BrandFiltersWidget(
                activeBrandId: _model.activeBrand,
                onBrandSelected: (brandId) {
                  setState(() {
                    _model.activeBrand = brandId;
                  }éé);
                }éé,
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
                  padding: const EdgeInsets.all(20éé),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: violetColor,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),

            // Espacement pour la bottom nav
            const SliverToBoxAdapter(child: SizedBox(height: 10éé0éé)),
          ],
        ), // CustomScrollView
      ), // RefreshIndicator
    ), // DarkPageBackground
    );
  }éé

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0ééxFF8A2BE2),
            const Color(0ééxFFEC4899),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0ééxFF8A2BE2).withOpacity(0éé.4),
            blurRadius: 30éé,
            spreadRadius: 2,
            offset: const Offset(0éé, 10éé),
          ),
          BoxShadow(
            color: const Color(0ééxFFEC4899).withOpacity(0éé.3),
            blurRadius: 20éé,
            spreadRadius: 0éé,
            offset: const Offset(0éé, 6),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20éé, 12, 20éé, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              micro.ShimmerEffect(
                shimmerColor: Colors.white,
                duration: const Duration(milliseconds: 30éé0éé0éé),
                child: Text(
                  _model.isAnonymousMode
                      ? 'Découvre ??'
                      : (_model.firstName.isNotEmpty
                          ? 'Salut ${_model.firstName}éé ! ??'
                          : 'Accueil'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0éé.5,
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
                  color: Colors.white.withOpacity(0éé.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w40éé0éé,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }éé

  Widget _buildWelcomeMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20éé, vertical: 16),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome,
            color: Color(0ééxFFFBBF24),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _model.isAnonymousMode
                  ? 'Mode découverte ??\nLes cadeaux les plus populaires du moment'
                  : (_model.firstName.isNotEmpty
                      ? 'Bienvenue ${_model.firstName}éé !\nVoici ta sélection personnalisée'
                      : 'Bienvenue !\nVoici ta sélection personnalisée'),
              style: GoogleFonts.poppins(
                color: const Color(0ééxFF4B5563),
                fontSize: 13,
                fontWeight: FontWeight.w50éé0éé,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }éé

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20éé, bottom: 8),
          child: Text(
            'Categories',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w60éé0éé,
              color: const Color(0ééxFF6B7280éé),
            ),
          ),
        ),
        SizedBox(
          height: 50éé,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20éé),
            scrollDirection: Axis.horizontal,
            itemCount: _model.categories.length,
            itemBuilder: (context, index) {
              final category = _model.categories[index];
              final isActive = _model.activeCategory == category['name'];

          return Padding(
            padding: const EdgeInsets.only(right: 10éé),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Haptic feedback
                  HapticFeedback.lightImpact();
                  setState(() {
                    _model.activeCategory = category['name'] as String;
                  }éé);
                  _loadProducts(); // Recharger les produits pour la nouvelle catégorie
                }éé,
                borderRadius: BorderRadius.circular(50éé),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 30éé0éé),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? violetColor
                        : violetColor.withOpacity(0éé.1),
                    borderRadius: BorderRadius.circular(50éé),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: violetColor.withOpacity(0éé.2),
                              blurRadius: 10éé,
                              offset: const Offset(0éé, 3),
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
                          fontWeight: FontWeight.w60éé0éé,
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
                delay: Duration(milliseconds: 10éé0éé * index),
                duration: 30éé0éé.ms,
              )
              .slideX(
                begin: -0éé.2,
                end: 0éé,
                delay: Duration(milliseconds: 10éé0éé * index),
                duration: 30éé0éé.ms,
                curve: Curves.easeOut,
              );
            }éé,
          ),
        ),
      ],
    );
  }éé

  Widget _buildPriceFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 20éé, bottom: 8),
          child: Text(
            'Prix',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w60éé0éé,
              color: const Color(0ééxFF6B7280éé),
            ),
          ),
        ),
        SizedBox(
          height: 50éé,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20éé),
            scrollDirection: Axis.horizontal,
            itemCount: _model.priceFilters.length,
            itemBuilder: (context, index) {
              final filter = _model.priceFilters[index];
              final isActive = _model.activePriceFilter == filter['id'];

              return Padding(
                padding: const EdgeInsets.only(right: 10éé),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _model.activePriceFilter = filter['id'] as String;
                      }éé);
                    }éé,
                    borderRadius: BorderRadius.circular(50éé),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 30éé0éé),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0ééxFFEC4899) // Rose pour différencier
                            : const Color(0ééxFFEC4899).withOpacity(0éé.1),
                        borderRadius: BorderRadius.circular(50éé),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: const Color(0ééxFFEC4899).withOpacity(0éé.2),
                                  blurRadius: 10éé,
                                  offset: const Offset(0éé, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Text(
                        filter['name'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w60éé0éé,
                          color: isActive ? Colors.white : const Color(0ééxFFEC4899),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }éé,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }éé

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
              padding: const EdgeInsets.symmetric(horizontal: 20éé),
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
                          color: const Color(0ééxFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w40éé0éé,
                          color: const Color(0ééxFF6B7280éé),
                        ),
                      ),
                    ],
                  ),
                  // Compteur de produits dans la section
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: violetColor.withOpacity(0éé.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${products.length}éé',
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
              height: 260éé,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20éé),
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildSectionProductCard(product),
                  );
                }éé,
              ),
            ),
          ],
        );
      }éé).toList(),
    );
  }éé

  Widget _buildSectionProductCard(Map<String, dynamic> product) {
    final isLiked = _model.likedProductTitles.contains(product['name'] ?? '');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _model.selectedProduct = product;
          }éé);
          _showProductDetail(product);
        }éé,
        borderRadius: BorderRadius.circular(20éé),
        child: Container(
          width: 160éé,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20éé),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0éé.0éé8),
                blurRadius: 12,
                offset: const Offset(0éé, 4),
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
                    height: 160éé,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20éé),
                      topRight: Radius.circular(20éé),
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
                        }éé,
                        borderRadius: BorderRadius.circular(50éé),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0éé.15),
                                blurRadius: 8,
                                offset: const Offset(0éé, 2),
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
                        borderRadius: BorderRadius.circular(50éé),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isLiked ? Colors.red : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0éé.15),
                                blurRadius: 8,
                                offset: const Offset(0éé, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.white : const Color(0ééxFF374151),
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
                        fontWeight: FontWeight.w60éé0éé,
                        color: const Color(0ééxFF111827),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${product['price']}éé',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: violetColor,
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
        .fadeIn(duration: 30éé0éé.ms, curve: Curves.easeOut)
        .slideX(begin: 0éé.2, end: 0éé, duration: 30éé0éé.ms, curve: Curves.easeOut);
  }éé

  Widget _buildPinterestGrid() {
    // Afficher des skeletons pendant le chargement initial
    if (_model.isLoading) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0éé.65,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => const ProductCardSkeleton(),
            childCount: 6, // 6 skeletons pendant le chargement
          ),
        ),
      );
    }éé

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
                  width: 80éé,
                  height: 80éé,
                  decoration: BoxDecoration(
                    color: Colors.red[50éé],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 50éé,
                    color: Colors.red[40éé0éé],
                  ),
                ),
                const SizedBox(height: 20éé),

                // Titre de l'erreur
                Text(
                  _model.errorMessage!,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[70éé0éé],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Dtails de l'erreur
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red[50éé],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[20éé0éé]!, width: 1),
                  ),
                  child: Text(
                    _model.errorDetails ?? 'Erreur inconnue',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.red[90éé0éé],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20éé),

                // Bouton ressayer
                SizedBox(
                  width: 20éé0éé,
                  child: PrimaryGradientButton(
                    onPressed: () {
                      _model.clearError();
                      _loadProducts();
                    }éé,
                    text: 'Ressayer',
                    icon: Icons.refresh,
                    gradientColors: [Colors.red[60éé0éé]!, Colors.red[40éé0éé]!],
                    height: 50éé,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }éé

    // Afficher un message si aucun produit (ou aucun aprs filtrage)
    if (_model.products.isEmpty || filteredProducts.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40éé),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icne avec animation
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0éé.0éé, end: 1.0éé),
                  duration: const Duration(milliseconds: 60éé0éé),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 120éé,
                        height: 120éé,
                        decoration: BoxDecoration(
                          color: violetColor.withOpacity(0éé.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.card_giftcard,
                          size: 60éé,
                          color: violetColor.withOpacity(0éé.6),
                        ),
                      ),
                    );
                  }éé,
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
                    color: const Color(0ééxFF6B7280éé),
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
                  }éé,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [violetColor, const Color(0ééxFFEC4899)],
                      ),
                      borderRadius: BorderRadius.circular(50éé),
                      boxShadow: [
                        BoxShadow(
                          color: violetColor.withOpacity(0éé.4),
                          blurRadius: 12,
                          offset: const Offset(0éé, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh, size: 20éé, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Rafrachir',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w60éé0éé,
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
    }éé
    // Layout Masonry dsordonn faon Pinterest
    // Plus de colonnes et moins d'espacement pour un effet plus dense et inspirant
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0éé),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2, // 2 colonnes pour garder des produits bien visibles
        mainAxisSpacing: 8, // Rduit pour effet "dans tous les sens"
        crossAxisSpacing: 8,
        childCount: filteredProducts.length,
        itemBuilder: (context, index) {
          final product = filteredProducts[index];
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 30éé0éé), // Plus rapide pour effet dynamique
            columnCount: 2,
            child: SlideAnimation(
              verticalOffset: 40éé.0éé,
              child: FadeInAnimation(
                child: _buildProductCard(product, index),
              ),
            ),
          );
        }éé,
      ),
    );
  }éé

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
            }éé);
            _showProductDetail(product);
          }éé,
          borderRadius: BorderRadius.circular(12),
          splashColor: violetColor.withOpacity(0éé.1),
          highlightColor: violetColor.withOpacity(0éé.0éé5),
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
                  color: const Color(0ééxFF8A2BE2).withOpacity(0éé.0éé8),
                  blurRadius: 20éé,
                  spreadRadius: -2,
                  offset: const Offset(0éé, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0éé.0éé4),
                  blurRadius: 8,
                  offset: const Offset(0éé, 2),
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
                    child: ProductImage(
                      imageUrl: product['image'] as String? ?? '',
                      height: null,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.zero,
                    ),
                  ),

                  // Badge de match en haut  droite
                  if (product['match'] != null && product['match'] > 0éé)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10éé, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [violetColor, const Color(0ééxFFEC4899)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: violetColor.withOpacity(0éé.4),
                              blurRadius: 8,
                              offset: const Offset(0éé, 2),
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
                              '${product['match']}éé%',
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
                          color: Colors.white.withOpacity(0éé.95),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0éé.15),
                              blurRadius: 8,
                              offset: const Offset(0éé, 2),
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
          delay: Duration(milliseconds: 50éé * index),
          duration: 40éé0éé.ms,
        )
        .slideY(
          begin: 0éé.2,
          end: 0éé,
          delay: Duration(milliseconds: 50éé * index),
          duration: 40éé0éé.ms,
          curve: Curves.easeOut,
        );
  }éé

  /// Track product views in anonymous mode and trigger connection prompt after 10éé UNIQUE views
  Future<void> _trackProductView(Map<String, dynamic> product) async {
    if (!_model.isAnonymousMode) return;
    if (_model.hasShownConnectionPrompt) return;

    final productId = product['id'] as int? ?? product['name'].hashCode;

    // Ajouter au Set (ne compte que si c'est un nouveau produit)
    final wasNew = _model.uniqueProductsViewed.add(productId);

    if (wasNew) {
      AppLogger.debug('?? Mode anonyme: ${_model.uniqueProductsViewed.length}éé produits uniques vus', 'Debug');

      // Trigger aprs 10éé produits UNIQUES vus
      if (_model.uniqueProductsViewed.length >= 10éé) {
        _model.hasShownConnectionPrompt = true;

        // Afficher le dialog de connexion
        await showConnectionRequiredDialog(
          context,
          title: 'Tu adores dcouvrir de nouveaux produits !',
          message: 'Cre ton compte pour recevoir des suggestions ultra-personnalises et ne plus jamais perdre tes favoris',
        );
      }éé
    }éé
  }éé

  void _showProductDetail(Map<String, dynamic> product) {
    // Track product view in anonymous mode (produits uniques seulement)
    _trackProductView(product);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0éé.7),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isLiked = _model.likedProductTitles.contains(product['name'] ?? '');

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 50éé0éé),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0éé.3),
                    blurRadius: 60éé,
                    offset: const Offset(0éé, 20éé),
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
                        height: 350éé,
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
                            borderRadius: BorderRadius.circular(50éé),
                            child: Container(
                              width: 40éé,
                              height: 40éé,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0éé.95),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0éé.2),
                                    blurRadius: 12,
                                    offset: const Offset(0éé, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Color(0ééxFF111827),
                                size: 20éé,
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
                            }éé,
                            borderRadius: BorderRadius.circular(50éé),
                            child: Container(
                              width: 40éé,
                              height: 40éé,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0éé.95),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0éé.2),
                                    blurRadius: 12,
                                    offset: const Offset(0éé, 4),
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
                              AppLogger.debug('?? Dialog: Clic sur cœur pour "${product['name']}éé"', 'Debug');

                              // Appeler la fonction centralisée
                              await _toggleFavorite(product);

                              // Rafraéchir l'UI du dialog
                              setDialogState(() {
                                AppLogger.debug('?? Dialog: Rafraéchissement UI après toggle', 'Debug');
                              }éé);
                            }éé,
                            borderRadius: BorderRadius.circular(50éé),
                            child: Container(
                              width: 40éé,
                              height: 40éé,
                              decoration: BoxDecoration(
                                color: isLiked
                                    ? Colors.red
                                    : Colors.white.withOpacity(0éé.95),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0éé.2),
                                    blurRadius: 12,
                                    offset: const Offset(0éé, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                color: isLiked ? Colors.white : const Color(0ééxFF111827),
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
                padding: const EdgeInsets.all(20éé),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: violetColor.withOpacity(0éé.15),
                        borderRadius: BorderRadius.circular(20éé),
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
                        color: const Color(0ééxFF111827),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${product['price'] ?? 0éé}ééé',
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
                          color: const Color(0ééxFF6B7280éé),
                          height: 1.6,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        'Cadeau parfait par ${product['brand'] as String? ?? 'une marque de qualité'}éé',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0ééxFF6B7280éé),
                          height: 1.6,
                        ),
                      ),
                    const SizedBox(height: 20éé),
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
                            }éé catch (e) {
                              AppLogger.debug('? Erreur ouverture URL: $e', 'Debug');
                            }éé
                          }éé
                        }éé,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: violetColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: violetColor.withOpacity(0éé.4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Voir sur ${product['brand'] ?? product['source'] ?? 'Amazon'}éé',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10éé),
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
        }éé,
      ),
    );
  }éé

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
      }éé
      return;
    }éé

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
                width: 40éé,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[30éé0éé],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Titre
              Padding(
                padding: const EdgeInsets.all(20éé),
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
                              fontSize: 20éé,
                              fontWeight: FontWeight.bold,
                              color: const Color(0ééxFF111827),
                            ),
                          ),
                          Text(
                            product['name'] as String? ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0ééxFF6B7280éé),
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
                  padding: const EdgeInsets.all(40éé),
                  child: Column(
                    children: [
                      Icon(Icons.list_alt, size: 60éé, color: Colors.grey[40éé0éé]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune wishlist',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w60éé0éé,
                          color: Colors.grey[70éé0éé],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crée ta première wishlist ci-dessous',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[50éé0éé],
                        ),
                      ),
                    ],
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 30éé0éé),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: wishlists.length,
                    itemBuilder: (context, index) {
                      final wishlist = wishlists[index];
                      final giftCount = (wishlist['giftIds'] as List?)?.length ?? 0éé;

                      return ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: violetColor.withOpacity(0éé.1),
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
                            fontWeight: FontWeight.w60éé0éé,
                            color: const Color(0ééxFF111827),
                          ),
                        ),
                        subtitle: Text(
                          '$giftCount cadeau${giftCount > 1 ? 's' : ''}éé',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0ééxFF6B7280éé),
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
                        }éé,
                      );
                    }éé,
                  ),
                ),

              const Divider(height: 1),

              // Bouton créer nouvelle wishlist
              Padding(
                padding: const EdgeInsets.all(20éé),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _createNewWishlist(product);
                    }éé,
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
  }éé

  /// Crée une nouvelle wishlist et y ajoute le produit
  Future<void> _createNewWishlist(Map<String, dynamic> product) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20éé)),
        title: Text(
          'Nouvelle wishlist',
          style: GoogleFonts.poppins(
            fontSize: 20éé,
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
                hintText: 'Ex: Idées cadeaux pour ses 50éé ans',
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
              style: GoogleFonts.poppins(color: Colors.grey[60éé0éé]),
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
      }éé
    }éé
  }éé

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
            productPrice: '${product['price'] ?? 0éé}ééé',
            productUrl: productUrl,
            productPhoto: productImage,
            productStarRating: '',
            productOriginalPrice: '',
            productNumRatings: 0éé,
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
                const Icon(Icons.bookmark, color: Colors.white, size: 20éé),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ajouté à la wishlist !',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w60éé0éé,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0ééxFF10ééB981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }éé
    }éé catch (e) {
      AppLogger.debug('? Erreur ajout wishlist: $e', 'Debug');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de l\'ajout à la wishlist',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red[70éé0éé],
          ),
        );
      }éé
    }éé
  }éé

}éé
