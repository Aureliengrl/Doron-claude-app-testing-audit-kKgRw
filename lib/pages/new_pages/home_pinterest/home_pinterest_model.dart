import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '/utils/app_logger.dart';

class HomePinterestModel {
  String activeCategory = 'Pour toi'; // Label d'affichage (traduit dynamiquement dans le widget)
  String activeCategoryId = 'all';    // ID logique — utilisé pour Firestore & comparaisons
  String activeEventFilter = '';
  String activeBrand = 'all'; // Filtre par marque/retailer
  String activeSubMenu = 'all'; // Filtre de sous-menu personnalisé

  Set<int> likedProducts = {};
  Set<String> likedProductTitles = {}; // Pour FlutterFlow system (par titre)
  Map<String, dynamic>? selectedProduct;
  bool isLoading = false;
  bool isLoadingMore = false;
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> sections = []; // Sections thématiques pour l'accueil
  String firstName = '';
  String searchQuery = '';
  // Résultats de la recherche plein-texte sur TOUTE la base Firestore
  // (par opposition à `products`, qui n'est que le lot de la catégorie
  // active). Non-null dès qu'une recherche DB a été lancée pour la requête
  // courante.
  List<Map<String, dynamic>>? searchResults;
  bool isSearching = false;
  String? errorMessage;
  String? errorDetails;
  List<String> personalizedEvents = [];

  // Mode anonyme
  bool isAnonymousMode = false;
  Set<int> uniqueProductsViewed = {}; // Set pour tracker les produits UNIQUES vus
  bool hasShownConnectionPrompt = false; // Pour ne montrer qu'une fois

  // Quick filters
  bool showOnlyFavorites = false;
  bool showOnlyNew = false;
  bool showFreeShipping = false;

  // Pagination
  static const int productsPerPage = 40;
  static const int infiniteScrollChunk = 40;
  int currentPage = 0;
  bool hasMore = true;

  static IconData getCategoryIcon(String id) {
    switch (id) {
      case 'all': return CupertinoIcons.sparkles;
      case 'trending': return CupertinoIcons.flame_fill;
      case 'tech': return Icons.devices_rounded;
      case 'fashion': return Icons.checkroom_rounded;
      case 'home': return CupertinoIcons.house_fill;
      case 'beauty': return Icons.face_retouching_natural_rounded;
      case 'food': return Icons.restaurant_rounded;
      case 'aeronautic': return CupertinoIcons.airplane;
      case 'mechanic': return Icons.directions_car_filled_rounded;
      case 'sport': return Icons.fitness_center_rounded;
      case 'art': return Icons.palette_rounded;
      case 'reading': return CupertinoIcons.book_fill;
      case 'travel': return Icons.luggage_rounded;
      case 'gaming': return Icons.sports_esports_rounded;
      case 'music': return Icons.headphones_rounded;
      case 'garden': return Icons.eco_rounded;
      case 'wellness': return Icons.self_improvement_rounded;
      default: return CupertinoIcons.circle_grid_hex_fill;
    }
  }

  static IconData getEventIcon(String id) {
    switch (id) {
      case 'all': return CupertinoIcons.calendar_today;
      case 'noel': return Icons.ac_unit_rounded;
      case 'anniversaire': return Icons.cake_rounded;
      case 'st_valentin': return CupertinoIcons.heart_fill;
      case 'fete_meres': return Icons.local_florist_rounded;
      case 'fete_peres': return Icons.watch_rounded;
      case 'fete_musique': return Icons.music_note_rounded;
      case 'fete_nationale': return Icons.celebration_rounded;
      case 'world_cup': return Icons.emoji_events_rounded;
      case 'fete_grand_meres': return Icons.family_restroom_rounded;
      case 'pot_depart': return Icons.flight_takeoff_rounded;
      case 'mariage': return Icons.diamond_rounded;
      case 'naissance': return Icons.child_friendly_rounded;
      case 'cremaillere': return Icons.key_rounded;
      case 'diplome': return Icons.school_rounded;
      case 'halloween': return Icons.nightlight_round;
      default: return CupertinoIcons.gift_fill;
    }
  }

  static String getCategoryEmoji(String id) {
    switch (id) {
      case 'all': return '✨';
      case 'trending': return '🔥';
      case 'tech': return '📱';
      case 'fashion': return '👗';
      case 'home': return '🏠';
      case 'beauty': return '💄';
      case 'food': return '🍷';
      case 'aeronautic': return '✈️';
      case 'mechanic': return '🏎️';
      case 'sport': return '⚽';
      case 'art': return '🎨';
      case 'reading': return '📚';
      case 'travel': return '🧳';
      case 'gaming': return '🎮';
      case 'music': return '🎧';
      case 'garden': return '🌱';
      case 'wellness': return '🧘';
      default: return '✨';
    }
  }

  static String? getEventImageAsset(String id) {
    switch (id) {
      case 'all': return 'assets/images/event_all.png';
      case 'noel': return 'assets/images/event_noel.png';
      case 'anniversaire': return 'assets/images/event_anniversaire.png';
      case 'st_valentin': return 'assets/images/event_st_valentin.png';
      case 'fete_meres': return 'assets/images/event_fete_meres.png';
      case 'fete_peres': return 'assets/images/event_fete_peres.png';
      case 'fete_musique': return 'assets/images/event_fete_musique.png';
      case 'fete_nationale': return 'assets/images/event_fete_nationale.png';
      case 'world_cup': return 'assets/images/event_world_cup.png';
      case 'fete_grand_meres': return 'assets/images/event_fete_grand_meres.png';
      case 'pot_depart': return 'assets/images/event_pot_depart.png';
      case 'mariage': return 'assets/images/event_mariage.png';
      case 'naissance': return 'assets/images/event_naissance.png';
      case 'cremaillere': return 'assets/images/event_cremaillere.png';
      case 'diplome': return 'assets/images/event_diplome.png';
      case 'halloween': return 'assets/images/event_halloween.png';
      default: return null;
    }
  }

  static String getEventEmoji(String id) {
    switch (id) {
      case 'all': return '📅';
      case 'noel': return '🎄';
      case 'anniversaire': return '🎂';
      case 'st_valentin': return '❤️';
      case 'fete_meres': return '💐';
      case 'fete_peres': return '👔';
      case 'fete_musique': return '🎵';
      case 'fete_nationale': return '🎆';
      case 'world_cup': return '🏆';
      case 'fete_grand_meres': return '👵';
      case 'pot_depart': return '👋';
      case 'mariage': return '💍';
      case 'naissance': return '👶';
      case 'cremaillere': return '🗝️';
      case 'diplome': return '🎓';
      case 'halloween': return '🎃';
      default: return '🎁';
    }
  }

  final List<Map<String, String>> categories = [
    {'id': 'all', 'name': 'Pour toi', 'emoji': '✨'},
    {'id': 'trending', 'name': 'Tendances', 'emoji': '🔥'},
    {'id': 'tech', 'name': 'Tech', 'emoji': '📱'},
    {'id': 'fashion', 'name': 'Mode', 'emoji': '👗'},
    {'id': 'home', 'name': 'Maison', 'emoji': '🏠'},
    {'id': 'beauty', 'name': 'Beauté', 'emoji': '💄'},
    {'id': 'food', 'name': 'Food', 'emoji': '🍷'},
    {'id': 'aeronautic', 'name': 'Aéronautique', 'emoji': '✈️'},
    {'id': 'mechanic', 'name': 'Mécanique', 'emoji': '🏎️'},
    {'id': 'sport', 'name': 'Sport', 'emoji': '⚽'},
    {'id': 'art', 'name': 'Art', 'emoji': '🎨'},
    {'id': 'reading', 'name': 'Lecture', 'emoji': '📚'},
    {'id': 'travel', 'name': 'Voyage', 'emoji': '🧳'},
    {'id': 'gaming', 'name': 'Jeux vidéo', 'emoji': '🎮'},
    {'id': 'music', 'name': 'Musique', 'emoji': '🎧'},
    {'id': 'garden', 'name': 'Jardinage', 'emoji': '🌱'},
    {'id': 'wellness', 'name': 'Bien-être', 'emoji': '🧘'},
  ];

  final List<Map<String, String>> defaultEvents = [
    {'id': 'noel', 'name': 'Noël', 'emoji': '🎄'},
    {'id': 'anniversaire', 'name': 'Anniversaire', 'emoji': '🎂'},
    {'id': 'st_valentin', 'name': 'St Valentin', 'emoji': '❤️'},
    {'id': 'fete_meres', 'name': 'Fête des Mères', 'emoji': '💐'},
    {'id': 'fete_peres', 'name': 'Fête des Pères', 'emoji': '👔'},
    {'id': 'fete_musique', 'name': 'Fête Musique', 'emoji': '🎵'},
    {'id': 'fete_nationale', 'name': 'Fête Nationale', 'emoji': '🎆'},
    {'id': 'world_cup', 'name': 'Coupe du Monde', 'emoji': '🏆'},
    {'id': 'fete_grand_meres', 'name': 'Grands-Mères', 'emoji': '👵'},
    {'id': 'pot_depart', 'name': 'Pot de départ', 'emoji': '👋'},
    {'id': 'mariage', 'name': 'Mariage', 'emoji': '💍'},
    {'id': 'naissance', 'name': 'Naissance', 'emoji': '👶'},
    {'id': 'cremaillere', 'name': 'Crémaillère', 'emoji': '🗝️'},
    {'id': 'diplome', 'name': 'Diplôme', 'emoji': '🎓'},
    {'id': 'halloween', 'name': 'Halloween', 'emoji': '🎃'},
  ];

  final Map<String, List<String>> subMenusMap = {
    // Marques
    'apple': ['Sport (Apple Watch)', 'Professionnel (MacBook)', 'Sons (HomePod, AirPods)'],
    'nike': ['Running', 'Lifestyle', 'Football', 'Basketball'],
    'lego': ['Star Wars', 'Technic', 'Architecture', 'Harry Potter', 'Adultes'],
    'sephora': ['Parfums', 'Maquillage', 'Soins Visage', 'Coffrets'],
    'dyson': ['Cheveux', 'Aspirateurs', 'Purificateurs'],
    'sony': ['PlayStation', 'Audio', 'Photo/Vidéo'],
    
    // Catégories (15 Grandes Catégories x Sous-catégories officielles)
    'trending': ['Viral TikTok', 'Bestsellers', 'Nouveautés', 'Édition Limitée'],
    'tech': ['Smartphones & Tablettes', 'Ordinateurs & Accessoires', 'Audio', 'Wearables & Montres', 'Photo & Vidéo', 'Maison Connectée', 'Accessoires Auto Tech', 'Gadgets & Recharge'],
    'fashion': ['Mode Femme', 'Mode Homme', 'Chaussures & Sneakers', 'Sacs & Maroquinerie', 'Bijoux & Joaillerie', 'Montres Classiques', 'Accessoires de Mode', 'Lingerie & Nuit', 'Sportswear & Outdoor'],
    'home': ['Déco Murale & Objets', 'Linge de Maison', 'Cuisine & Arts de la Table', 'Bougies & Senteurs', 'Rangement & Organisation', 'Électroménager Design', 'Luminaires'],
    'beauty': ['Parfums', 'Soin Visage', 'Soin Corps', 'Maquillage', 'Cheveux & Coiffure', 'Rasage & Barbe', 'Appareils Beauté'],
    'food': ['Épicerie Fine', 'Vins & Spiritueux', 'Chocolats & Confiseries', 'Café & Thé', 'Coffrets Dégustation', 'Sommellerie & Bar'],
    'sport': ['Running & Athlétisme', 'Fitness & Musculation', 'Outdoor & Rando', 'Sports de Raquette', 'Sports de Glisse & Eau', 'Nutrition & Récupération', 'Vêtements Techniques'],
    'art': ['Peinture & Dessin', 'Sculpture & Modelage', 'Loisirs Créatifs & DIY', 'Livres d\'Art', 'Affiches & Tirages', 'Arts Graphiques'],
    'reading': ['Romans & Littérature', 'BD & Romans Graphiques', 'Mangas & Comics', 'Développement Personnel', 'Liseuses & Accessoires', 'Beaux Livres'],
    'travel': ['Valises & Bagages', 'Sacs à Dos Voyage', 'Accessoires Nomades', 'Organisation Bagages', 'Bivouac & Aventure', 'Guides & Carnets'],
    'gaming': ['Consoles Next-Gen', 'Manettes & Accessoires', 'Casques Gaming', 'Jeux Vidéo', 'Mobilier & Sièges', 'Goodies & Figurines'],
    'music': ['Guitares & Cordes', 'Pianos & Claviers', 'Platines Vinyles & Hi-Fi', 'Home Studio & MAO', 'Accessoires Musique', 'Batteries & Percussions'],
    'garden': ['Plantes & Cache-Pots', 'Potagers Connectés', 'Outils de Jardinage', 'Graines & Semis Bio', 'Braséros & Mobilier', 'Arrosage & Soins'],
    'wellness': ['Massages & Relaxation', 'Yoga & Méditation', 'Sommeil & Réveils Lumière', 'Diffuseurs & Huiles', 'Bains & Thalasso', 'Acupression & Chaleur'],
    'mechanic': ['Accessoires Intérieur Auto', 'Entretien & Detailing', 'Outils & Compresseurs', 'Dashcam & Antivol GPS', 'Lifestyle & Miniature Auto', 'Équipement Motard'],
    'aeronautic': ['Drones & Prises de Vue', 'Maquettes de Collection', 'Simulation & Pilotage', 'Livres Aviation', 'Style Aviateur', 'Télescopes & Espace'],

    // Événements
    'noel': ['Secret Santa', 'Gros Cadeaux', 'Petites attentions', 'Calendriers de l\'Avent'],
    'anniversaire': ['Fête surprise', 'Cadeaux marquants', 'Bons cadeaux', 'Humour'],
    'st_valentin': ['Romantique', 'Expériences à deux', 'Coquin', 'Personnalisé'],
    'fete_meres': ['Détente', 'Bijoux', 'Fleurs', 'Gourmandise'],
    'fete_peres': ['High-Tech', 'Gastronomie', 'Bricolage', 'Sport'],
    'fete_musique': ['Instruments', 'Billets de concert', 'Enceintes portables'],
    'fete_nationale': ['Produits locaux', 'Festif', 'Feux d\'artifice'],
    'world_cup': ['Maillots', 'Écrans', 'Ambiance', 'Snacks'],
    'fete_grand_meres': ['Photos de famille', 'Thé & Biscuits', 'Confort', 'Plantes'],
    'pot_depart': ['Cadeaux communs', 'Cagnotte', 'Humour', 'Voyage'],
    'mariage': ['Liste de mariage', 'Cadeaux de luxe', 'Voyage de noces', 'Maison'],
    'naissance': ['Vêtements bébé', 'Jouets d\'éveil', 'Puériculture', 'Cadeaux Maman'],
    'cremaillere': ['Décoration', 'Électroménager', 'Plantes', 'Vaisselle'],
    'diplome': ['Montres', 'Stylos de luxe', 'Voyages', 'High-Tech'],
    'halloween': ['Déguisements', 'Décoration flippante', 'Bonbons', 'Films d\'horreur'],
  };

  List<Map<String, String>> get currentEvents {
    if (personalizedEvents.isNotEmpty) {
      return [
        {'id': 'all', 'name': 'Tous les événements'},
        ...personalizedEvents.map((e) => {'id': e.toLowerCase().replaceAll(' ', '_'), 'name': e})
      ];
    }
    return defaultEvents;
  }

  void resetOtherFilters(String activeType) {
    if (activeType != 'category') {
      activeCategory = 'Pour toi';
      activeCategoryId = 'all';
    }
    if (activeType != 'event') {
      activeEventFilter = '';
    }
    if (activeType != 'brand') {
      activeBrand = 'all';
    }
    // Quand on change le parent, on réinitialise toujours le sous-menu
    activeSubMenu = 'all';
  }

  void toggleLike(int productId, String productTitle) {
    if (likedProducts.contains(productId)) {
      likedProducts.remove(productId);
      likedProductTitles.remove(productTitle);
      AppLogger.debug('🗑️ Produit retiré des favoris - ID: $productId', 'Home');
    } else {
      likedProducts.add(productId);
      likedProductTitles.add(productTitle);
      AppLogger.debug('❤️ Produit ajouté aux favoris - ID: $productId', 'Home');
    }
  }

  void setLoading(bool loading) {
    isLoading = loading;
  }

  void setProducts(List<Map<String, dynamic>> newProducts) {
    final seenIds = <dynamic>{};
    products = newProducts.where((product) {
      final productId = product['id'];
      if (seenIds.contains(productId)) return false;
      seenIds.add(productId);
      return true;
    }).toList();
  }

  void setSections(List<Map<String, dynamic>> newSections) {
    sections = newSections;
  }

  void setFirstName(String name) {
    firstName = name;
  }

  void setLoadingMore(bool loading) {
    isLoadingMore = loading;
  }

  void addProducts(List<Map<String, dynamic>> newProducts) {
    final existingIds = products.map((p) => p['id']).toSet();
    final uniqueNewProducts = newProducts.where((product) {
      return !existingIds.contains(product['id']);
    }).toList();
    products.addAll(uniqueNewProducts);
  }

  void resetPagination() {
    currentPage = 0;
    hasMore = true;
    products.clear();
  }

  void incrementPage() {
    currentPage++;
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    if (query.trim().isEmpty) {
      searchResults = null;
      isSearching = false;
    }
  }

  void setSearchResults(List<Map<String, dynamic>> results) {
    searchResults = results;
    isSearching = false;
  }

  void setSearching(bool value) {
    isSearching = value;
  }

  void toggleQuickFilter(String filter) {
    switch (filter) {
      case 'favorites':
        showOnlyFavorites = !showOnlyFavorites;
        break;
      case 'new':
        showOnlyNew = !showOnlyNew;
        break;
      case 'shipping':
        showFreeShipping = !showFreeShipping;
        break;
    }
  }

  void setError(String? message, String? details) {
    errorMessage = message;
    errorDetails = details;
  }

  void clearError() {
    errorMessage = null;
    errorDetails = null;
  }

  List<Map<String, dynamic>> getFilteredProducts() {
    // Une recherche texte active porte sur TOUTE la base (searchResults),
    // pas seulement sur le lot pré-chargé de la catégorie active.
    final usingDbSearch = searchQuery.trim().isNotEmpty && searchResults != null;
    var filtered = usingDbSearch ? searchResults! : products;

    if (activeBrand != 'all') {
      final brandFilter = activeBrand.toLowerCase();
      final filterNorm = brandFilter.replaceAll('&', '').replaceAll(' ', '').replaceAll('-', '');
      filtered = filtered.where((product) {
        final brandId = (product['brandId'] as String? ?? '').toLowerCase();
        if (brandId.isNotEmpty && (brandId == brandFilter || brandId == filterNorm)) return true;

        final brand = (product['brand'] as String? ?? '').toLowerCase();
        final brandNorm = brand.replaceAll('&', '').replaceAll(' ', '').replaceAll('-', '');
        final source = (product['source'] as String? ?? '').toLowerCase();
        final cats = (product['categories'] as List<dynamic>? ?? []).map((c) => c.toString().toLowerCase()).toList();

        return brand.contains(brandFilter) ||
            brandNorm.contains(filterNorm) ||
            source.contains(brandFilter) ||
            cats.contains(brandFilter) ||
            cats.contains(filterNorm);
      }).toList();
    }

    // 1. Filtrage par Catégorie principale (avec normalisation)
    if (activeCategoryId != 'all' && activeCategoryId.isNotEmpty) {
      filtered = filtered.where((p) => _matchesCategory(activeCategoryId, p)).toList();
    }

    // 2. Filtrage par Événement (avec règles strictes de genre et thématiques)
    if (activeEventFilter.isNotEmpty && activeEventFilter != 'all') {
      final eventFiltered = filtered.where((p) => _matchesEvent(activeEventFilter, p)).toList();
      filtered = eventFiltered;
    }
    
    // 3. Filtrage dynamique par le sous-menu
    if (activeSubMenu != 'all' && activeSubMenu.isNotEmpty) {
      final subFiltered = filtered.where((p) => _matchesSubMenu(activeSubMenu, p)).toList();
      if (subFiltered.isNotEmpty) {
        filtered = subFiltered;
      }
    }

    // Si une recherche DB (searchResults) est active, les résultats sont déjà
    // pré-matchés contre la requête par ProductSearchService — inutile (et
    // moins bon, cf. accents/pluriels) de refiltrer par simple `.contains`.
    if (searchQuery.isNotEmpty && !usingDbSearch) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((product) {
        final name = (product['name'] as String? ?? '').toLowerCase();
        final brand = (product['brand'] as String? ?? '').toLowerCase();
        final description = (product['description'] as String? ?? '').toLowerCase();
        return name.contains(query) || brand.contains(query) || description.contains(query);
      }).toList();
    }

    if (showOnlyFavorites) {
      filtered = filtered.where((product) {
        return likedProducts.contains(product['id']);
      }).toList();
    }

    if (showOnlyNew) {
      final hasNewProducts = filtered.any((p) => p['isNew'] == true);
      if (hasNewProducts) {
        filtered = filtered.where((p) => p['isNew'] == true).toList();
      }
    }

    return filtered;
  }

  bool _matchesCategory(String catId, Map<String, dynamic> product) {
    final c = catId.toLowerCase().trim();
    if (c == 'all' || c.isEmpty) return true;

    const categoryTagMap = {
      'tech': 'cat_tech',
      'fashion': 'cat_mode',
      'home': 'cat_maison',
      'beauty': 'cat_beaute',
      'food': 'cat_food',
      'sport': 'cat_sport',
      'art': 'cat_art',
      'reading': 'cat_lecture',
      'travel': 'cat_voyage',
      'gaming': 'cat_jeuxvideo',
      'music': 'cat_musique',
      'garden': 'cat_jardinage',
      'wellness': 'cat_bienetre',
      'mechanic': 'cat_mecanique_auto',
      'aeronautic': 'cat_aeronautique',
    };

    final targetTag = categoryTagMap[c] ?? c;
    final pCat = (product['category'] ?? '').toString().toLowerCase();
    final pCats = (product['categories'] as List<dynamic>? ?? []).map((e) => e.toString().toLowerCase()).toList();
    final pTags = (product['tags'] as List<dynamic>? ?? []).map((e) => e.toString().toLowerCase()).toList();
    final allList = {pCat, ...pCats, ...pTags};

    if (c == 'trending') {
      return allList.contains('popularite_5') || allList.contains('popularite_4') || allList.contains('cat_tendances');
    }

    return allList.contains(targetTag) || allList.contains(c);
  }

  bool _matchesEvent(String eventId, Map<String, dynamic> product) {
    final tags = ((product['tags'] as List?)?.cast<dynamic>() ?? [])
        .map((t) => t.toString().toLowerCase())
        .toSet();
    final categories = ((product['categories'] as List?)?.cast<dynamic>() ?? [])
        .map((c) => c.toString().toLowerCase())
        .toSet();
    final pCat = (product['category'] ?? '').toString().toLowerCase();
    final allTags = {...tags, ...categories, if (pCat.isNotEmpty) pCat};

    final name = (product['name'] ?? '').toString().toLowerCase();
    final brand = (product['brand'] ?? '').toString().toLowerCase();
    final description = (product['description'] ?? '').toString().toLowerCase();
    final text = '$name $brand $description';

    final isMaleProduct = allTags.contains('gender_homme') ||
        allTags.contains('subcat_vetements_homme') ||
        allTags.contains('subcat_rasage_barbe') ||
        text.contains('pour homme') ||
        (text.contains('homme') && !text.contains('femme'));

    final isFemaleProduct = allTags.contains('gender_femme') ||
        allTags.contains('subcat_vetements_femme') ||
        allTags.contains('subcat_lingerie_nuit') ||
        allTags.contains('subcat_maquillage') ||
        text.contains('pour femme');

    switch (eventId) {
      case 'fete_meres':
        // STRICTEMENT FEMININ OU MIXTE - EXCLUSION TOTALE HOMME
        if (isMaleProduct) return false;
        return allTags.contains('gender_femme') ||
            allTags.contains('gender_mixte') ||
            allTags.contains('cat_beaute') ||
            allTags.contains('cat_bienetre') ||
            allTags.contains('subcat_bijoux') ||
            allTags.contains('subcat_sacs_maroquinerie') ||
            allTags.contains('subcat_ambiance_bougies_senteurs') ||
            allTags.contains('subcat_linge_maison') ||
            allTags.contains('subcat_deco_murale_objets') ||
            allTags.contains('subcat_cuisine_arts_de_la_table') ||
            allTags.contains('subcat_chocolats_confiseries') ||
            allTags.contains('subcat_cafe_the') ||
            allTags.contains('subcat_coffrets_degustation') ||
            allTags.contains('subcat_plantes_interieur_cache_pots') ||
            allTags.contains('subcat_parfum') ||
            allTags.contains('subcat_soin_visage') ||
            allTags.contains('subcat_soin_corps') ||
            allTags.contains('occasion_fete');

      case 'fete_grand_meres':
        if (isMaleProduct) return false;
        return allTags.contains('gender_femme') ||
            allTags.contains('gender_mixte') ||
            allTags.contains('age_senior') ||
            allTags.contains('cat_bienetre') ||
            allTags.contains('cat_lecture') ||
            allTags.contains('subcat_cafe_the') ||
            allTags.contains('subcat_chocolats_confiseries') ||
            allTags.contains('subcat_plantes_interieur_cache_pots') ||
            allTags.contains('subcat_bijoux') ||
            allTags.contains('subcat_ambiance_bougies_senteurs') ||
            allTags.contains('subcat_linge_maison');

      case 'fete_peres':
        // STRICTEMENT MASCULIN OU MIXTE - EXCLUSION TOTALE FEMME
        if (isFemaleProduct) return false;
        return allTags.contains('gender_homme') ||
            allTags.contains('gender_mixte') ||
            allTags.contains('cat_mecanique_auto') ||
            allTags.contains('cat_tech') ||
            allTags.contains('subcat_vins_spiritueux') ||
            allTags.contains('subcat_accessoires_sommellerie_bar') ||
            allTags.contains('subcat_montres_classiques') ||
            allTags.contains('subcat_vetements_homme') ||
            allTags.contains('subcat_rasage_barbe') ||
            allTags.contains('subcat_sacs_maroquinerie') ||
            allTags.contains('cat_sport') ||
            allTags.contains('cat_aeronautique') ||
            allTags.contains('subcat_massages_relaxation') ||
            allTags.contains('occasion_fete');

      case 'st_valentin':
        return allTags.contains('occasion_saint_valentin') ||
            allTags.contains('subcat_bijoux') ||
            allTags.contains('subcat_parfum') ||
            allTags.contains('subcat_lingerie_nuit') ||
            allTags.contains('subcat_chocolats_confiseries') ||
            allTags.contains('subcat_vins_spiritueux') ||
            allTags.contains('subcat_ambiance_bougies_senteurs') ||
            allTags.contains('subcat_bains_thalasso_maison') ||
            allTags.contains('subcat_massages_relaxation') ||
            allTags.contains('subcat_montres_classiques') ||
            allTags.contains('perso_romantique');

      case 'naissance':
        return allTags.contains('occasion_naissance') ||
            allTags.contains('age_enfant') ||
            allTags.contains('cat_bienetre') ||
            allTags.contains('subcat_linge_maison') ||
            allTags.contains('subcat_ambiance_bougies_senteurs') ||
            allTags.contains('subcat_soin_corps') ||
            allTags.contains('subcat_massages_relaxation') ||
            allTags.contains('subcat_graines_kits_plantation');

      case 'mariage':
        return allTags.contains('occasion_mariage') ||
            allTags.contains('subcat_cuisine_arts_de_la_table') ||
            allTags.contains('subcat_linge_maison') ||
            allTags.contains('subcat_electromenager') ||
            allTags.contains('subcat_luminaire_ambiance') ||
            allTags.contains('subcat_vins_spiritueux') ||
            allTags.contains('subcat_bijoux') ||
            allTags.contains('subcat_montres_classiques') ||
            allTags.contains('subcat_valises_bagagerie');

      case 'cremaillere':
        return allTags.contains('occasion_cremaillere') ||
            allTags.contains('cat_maison') ||
            allTags.contains('cat_jardinage') ||
            allTags.contains('subcat_cuisine_arts_de_la_table') ||
            allTags.contains('subcat_deco_murale_objets') ||
            allTags.contains('subcat_ambiance_bougies_senteurs') ||
            allTags.contains('subcat_luminaire_ambiance') ||
            allTags.contains('subcat_plantes_interieur_cache_pots') ||
            allTags.contains('subcat_potager_interieur_connecte') ||
            allTags.contains('subcat_vins_spiritueux') ||
            allTags.contains('subcat_epicerie_fine') ||
            allTags.contains('subcat_accessoires_sommellerie_bar');

      case 'diplome':
        return allTags.contains('occasion_diplome') ||
            allTags.contains('subcat_ordinateurs_accessoires') ||
            allTags.contains('subcat_audio') ||
            allTags.contains('subcat_smartphones_tablettes') ||
            allTags.contains('subcat_montres_classiques') ||
            allTags.contains('subcat_sacs_maroquinerie') ||
            allTags.contains('subcat_valises_bagagerie') ||
            allTags.contains('subcat_beaux_livres_coffee_table');

      case 'fete_musique':
        return allTags.contains('cat_musique') ||
            allTags.contains('subcat_audio') ||
            allTags.contains('passion_musique') ||
            allTags.contains('type_musique_audio');

      case 'world_cup':
        return allTags.contains('cat_sport') ||
            allTags.contains('passion_sport') ||
            allTags.contains('subcat_sportswear_outdoor');

      case 'pot_depart':
        return allTags.contains('context_colleague') ||
            allTags.contains('subcat_vins_spiritueux') ||
            allTags.contains('subcat_coffrets_degustation') ||
            allTags.contains('subcat_valises_bagagerie') ||
            allTags.contains('subcat_sacs_maroquinerie') ||
            allTags.contains('subcat_accessoires_sommellerie_bar') ||
            allTags.contains('subcat_beaux_livres_coffee_table') ||
            allTags.contains('subcat_plantes_interieur_cache_pots');

      case 'halloween':
        return allTags.contains('subcat_chocolats_confiseries') ||
            allTags.contains('cat_jeuxvideo') ||
            allTags.contains('subcat_ambiance_bougies_senteurs') ||
            allTags.contains('subcat_mangas_comics');

      case 'fete_nationale':
        return allTags.contains('subcat_vins_spiritueux') ||
            allTags.contains('subcat_epicerie_fine') ||
            allTags.contains('subcat_coffrets_degustation') ||
            allTags.contains('subcat_accessoires_sommellerie_bar') ||
            brand.contains('bonsoirs') ||
            brand.contains('dalloyau') ||
            brand.contains('le creuset') ||
            brand.contains('hédène') ||
            brand.contains('hedene') ||
            brand.contains('mariage frères') ||
            brand.contains('mariage freres');

      case 'noel':
        return allTags.contains('occasion_noel') ||
            allTags.contains('popularite_5') ||
            allTags.contains('popularite_4') ||
            allTags.contains('style_luxe') ||
            allTags.contains('style_festif');

      case 'anniversaire':
        return allTags.contains('occasion_anniversaire') ||
            allTags.contains('popularite_5') ||
            allTags.contains('popularite_4');

      default:
        final eventFilter = eventId.replaceAll('_', ' ').toLowerCase();
        return text.contains(eventFilter) || allTags.contains(eventId);
    }
  }

  bool _matchesSubMenu(String subMenu, Map<String, dynamic> product) {
    final subQuery = _cleanAccents(subMenu.toLowerCase());
    final cleanSubQueryWords = subQuery.replaceAll(RegExp(r'[()]'), ' ').split(' ').where((w) => w.length > 2).toList();

    final name = _cleanAccents((product['name'] as String? ?? '').toLowerCase());
    final brand = _cleanAccents((product['brand'] as String? ?? '').toLowerCase());
    final description = _cleanAccents((product['description'] as String? ?? '').toLowerCase());
    final categoriesList = _cleanAccents((product['categories'] as List<dynamic>? ?? []).join(' ').toLowerCase());
    final keywordsList = product['keywords'] as List<dynamic>? ?? [];
    final keywordsStr = _cleanAccents(keywordsList.join(' ').toLowerCase());
    final tagsList = product['tags'] as List<dynamic>? ?? [];
    final tagsStr = _cleanAccents(tagsList.join(' ').toLowerCase());

    final combined = '$name $brand $description $categoriesList $keywordsStr $tagsStr';

    if (cleanSubQueryWords.isEmpty) return true;
    for (final word in cleanSubQueryWords) {
      if (combined.contains(word)) return true;
    }
    return false;
  }

  String _cleanAccents(String input) {
    return input
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c');
  }

  void dispose() {
    products.clear();
    likedProducts.clear();
    selectedProduct = null;
  }
}
