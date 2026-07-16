import '/utils/app_logger.dart';

class HomePinterestModel {
  String activeCategory = 'Pour toi'; // Label d'affichage (traduit dynamiquement dans le widget)
  String activeCategoryId = 'all';    // ID logique — utilisé pour Firestore & comparaisons
  String activeEventFilter = 'all';
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
  static const int productsPerPage = 12;
  static const int infiniteScrollChunk = 25;
  int currentPage = 0;
  bool hasMore = true;

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
    {'id': 'travel', 'name': 'Voyage', 'emoji': '✈️'},
    {'id': 'gaming', 'name': 'Jeux vidéo', 'emoji': '🎮'},
    {'id': 'music', 'name': 'Musique', 'emoji': '🎵'},
    {'id': 'garden', 'name': 'Jardinage', 'emoji': '🌱'},
    {'id': 'wellness', 'name': 'Bien-être', 'emoji': '🧘'},
  ];

  final List<Map<String, String>> defaultEvents = [
    {'id': 'all', 'name': 'Tous les événements'},
    {'id': 'noel', 'name': '🎄 Noël'},
    {'id': 'anniversaire', 'name': '🎂 Anniversaire'},
    {'id': 'st_valentin', 'name': '❤️ St Valentin'},
    {'id': 'fete_meres', 'name': '💐 Fête des Mères'},
    {'id': 'fete_peres', 'name': '👔 Fête des Pères'},
    {'id': 'fete_musique', 'name': '🎵 Fête de la musique'},
    {'id': 'fete_nationale', 'name': '🎆 Fête Nationale'},
    {'id': 'world_cup', 'name': '🏆 Finale Coupe du monde'},
    {'id': 'fete_grand_meres', 'name': '👵 Fête des grands-mères'},
    {'id': 'pot_depart', 'name': '👋 Pot de départ'},
    {'id': 'mariage', 'name': '💍 Mariage'},
    {'id': 'naissance', 'name': '👶 Naissance'},
    {'id': 'cremaillere', 'name': '🏠 Crémaillère'},
    {'id': 'diplome', 'name': '🎓 Diplôme'},
    {'id': 'halloween', 'name': '🎃 Halloween'},
  ];

  final Map<String, List<String>> subMenusMap = {
    // Marques
    'apple': ['Sport (Apple Watch)', 'Professionnel (MacBook)', 'Sons (HomePod, AirPods)'],
    'nike': ['Running', 'Lifestyle', 'Football', 'Basketball'],
    'lego': ['Star Wars', 'Technic', 'Architecture', 'Harry Potter', 'Adultes'],
    'sephora': ['Parfums', 'Maquillage', 'Soins Visage', 'Coffrets'],
    'dyson': ['Cheveux', 'Aspirateurs', 'Purificateurs'],
    'sony': ['PlayStation', 'Audio', 'Photo/Vidéo'],
    
    // Catégories
    'trending': ['Viral TikTok', 'Nouveautés', 'Édition Limitée', 'Rupture de stock'],
    'tech': ['Smartphones', 'Audio', 'Ordinateurs', 'Objets Connectés', 'Gaming', 'Photo'],
    'fashion': ['Sneakers', 'Streetwear', 'Luxe', 'Accessoires', 'Bijoux', 'Montres'],
    'home': ['Cuisine', 'Salon', 'Chambre', 'Extérieurs', 'Décoration', 'Linge de maison'],
    'beauty': ['Skincare', 'Parfums', 'Maquillage', 'Soins du corps', 'Accessoires beauté'],
    'food': ['Chocolat', 'Vin & Spiritueux', 'Épicerie fine', 'Café & Thé', 'Box culinaires'],
    'aeronautic': ['Maquettes', 'Simulateurs', 'Expériences de vol', 'Livres aviation'],
    'mechanic': ['Accessoires Auto', 'Modélisme', 'Stage de pilotage', 'Outillage'],
    'sport': ['Football', 'Running', 'Fitness', 'Tennis', 'Cyclisme', 'Nutrition sportive'],
    'art': ['Matériel de dessin', 'Peinture', 'Livres d\'art', 'Sculpture', 'Tableaux'],
    'reading': ['Romans', 'Mangas', 'BD', 'Développement personnel', 'Liseuses'],
    'travel': ['Bagages', 'Accessoires de voyage', 'Expériences insolites', 'Guides'],
    'gaming': ['Consoles', 'Jeux PC', 'Jeux Rétro', 'Accessoires Gamer', 'Décoration'],
    'music': ['Instruments', 'Vinyles', 'Concerts', 'Hi-Fi', 'Merchandising'],
    'garden': ['Plantes d\'intérieur', 'Outillage jardin', 'Graines', 'Mobilier extérieur'],
    'wellness': ['Massages', 'Yoga', 'Huiles essentielles', 'Spa à domicile'],

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
      activeEventFilter = 'all';
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
      filtered = filtered.where((product) {
        // Champ structuré (nouveaux produits importés) — priorité, match exact.
        final brandId = (product['brandId'] as String? ?? '').toLowerCase();
        if (brandId.isNotEmpty) return brandId == brandFilter;

        // Fallback pour les produits legacy sans brandId : sous-chaîne.
        final brand = (product['brand'] as String? ?? '').toLowerCase();
        final source = (product['source'] as String? ?? '').toLowerCase();
        final platform = (product['platform'] as String? ?? '').toLowerCase();
        return brand.contains(brandFilter) || source.contains(brandFilter) || platform.contains(brandFilter);
      }).toList();
    }

    if (activeEventFilter != 'all') {
      final eventFilter = activeEventFilter.replaceAll('_', ' ').toLowerCase();
      filtered = filtered.where((product) {
        final name = (product['name'] as String? ?? '').toLowerCase();
        final description = (product['description'] as String? ?? '').toLowerCase();
        final keywordsList = product['keywords'] as List<dynamic>? ?? [];
        final keywordsStr = keywordsList.join(' ').toLowerCase();
        return name.contains(eventFilter) || description.contains(eventFilter) || keywordsStr.contains(eventFilter);
      }).toList();
    }
    
    // Filtrage dynamique par le sous-menu
    if (activeSubMenu != 'all') {
      final subQuery = activeSubMenu.toLowerCase();
      final cleanSubQueryWords = subQuery.replaceAll(RegExp(r'[()]'), ' ').split(' ').where((w) => w.length > 3).toList();
      
      // Fallback si le mot est très court (ex: "Art", "Vin")
      if (cleanSubQueryWords.isEmpty) {
        cleanSubQueryWords.addAll(subQuery.split(' ').where((w) => w.length > 2));
      }

      filtered = filtered.where((product) {
        final name = (product['name'] as String? ?? '').toLowerCase();
        final description = (product['description'] as String? ?? '').toLowerCase();
        final categoriesList = (product['categories'] as List<dynamic>? ?? []).join(' ').toLowerCase();
        final keywordsList = product['keywords'] as List<dynamic>? ?? [];
        final keywordsStr = keywordsList.join(' ').toLowerCase();
        
        final combined = '$name $description $categoriesList $keywordsStr';
        
        if (cleanSubQueryWords.isEmpty) return true;
        for (final word in cleanSubQueryWords) {
          if (combined.contains(word)) return true; // match au moins un mot clef significatif
        }
        return false;
      }).toList();
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

  void dispose() {
    products.clear();
    likedProducts.clear();
    selectedProduct = null;
  }
}
