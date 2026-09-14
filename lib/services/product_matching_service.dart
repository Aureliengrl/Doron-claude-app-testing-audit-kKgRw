import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '/utils/app_logger.dart';
import '/services/tags_definitions.dart';
import '/domain/matching/tag_converter.dart';
import '/domain/matching/matching_engine.dart';
import '/services/claude_api_service.dart';
import '/services/serp_live_search_service.dart';

/// Service de matching de produits basé sur les tags.
/// 
/// ⚠️ TOUS les produits viennent UNIQUEMENT de Firebase (collections 'gifts' ou 'products')
/// ⛔ PLUS AUCUN FALLBACK - Si Firebase vide, l'app crash pour identifier le problème.
///
/// Architecture interne:
/// - [TagConverter] : convertit les réponses utilisateur → tags officiels Doron (classe pure, testable)
/// - [MatchingEngine] : calcule le score de pertinence produit/utilisateur (classe pure, testable)
/// - [ProductMatchingService] : orchestre les appels Firebase + applique TagConverter + MatchingEngine
class ProductMatchingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Extrait l'URL de l'image d'un produit en cherchant dans TOUS les champs possibles
  /// Retourne une URL par défaut si aucune image n'est trouvée
  static String _extractImageUrl(Map<String, dynamic> product) {
    // Liste EXHAUSTIVE de tous les champs possibles pour une image
    final possibleFields = [
      'image',
      'imageUrl',
      'image_url',
      'photo',
      'img',
      'product_photo',
      'product_image',
      'productPhoto',
      'productImage',
      'picture',
      'thumbnail',
      'main_image',
      'mainImage',
      'cover',
      'coverImage',
      'image1',
      'images', // Parfois c'est un array
    ];

    // Essayer chaque champ
    for (var field in possibleFields) {
      final value = product[field];

      // Si c'est une string non vide
      if (value is String && value.isNotEmpty && value.startsWith('http')) {
        AppLogger.debug('🖼️ Image trouvée dans champ "$field": ${value.substring(0, value.length > 50 ? 50 : value.length)}...', 'Matching');
        return value;
      }

      // Si c'est un array, prendre le premier élément
      if (value is List && value.isNotEmpty) {
        final firstImage = value.first;
        if (firstImage is String && firstImage.isNotEmpty && firstImage.startsWith('http')) {
          AppLogger.debug('🖼️ Image trouvée dans array "$field": ${firstImage.substring(0, firstImage.length > 50 ? 50 : firstImage.length)}...', 'Matching');
          return firstImage;
        }
      }
    }

    // Aucune image trouvée - logger pour debug
    AppLogger.warning('⚠️ AUCUNE IMAGE trouvée pour produit "${product['name']}" - Champs disponibles: ${product.keys.join(", ")}', 'Matching');

    // FIX Bug 1: Retourner une chaîne vide au lieu d'un placeholder qui ne marche pas sur iOS
    // Les produits sans image seront filtrés par les widgets appelants
    return '';
  }

  /// Génère des produits personnalisés en matchant les tags utilisateur avec la base de produits
  ///
  /// Mode de filtrage:
  /// - "home": Page d'accueil - Strict sur SEXE uniquement (basé sur soi), souple sur le reste
  /// - "person": Recherche personne - Modéré sur tout (scoring uniquement pour cadeaux innovants)
  // Cache mémoire global ultra-rapide pour affichage instantané en 0 ms
  static List<Map<String, dynamic>> _inMemoryCatalog = [];
  static bool _isPreloading = false;

  /// Précharge le catalogue en mémoire vive dès le démarrage
  static Future<void> preloadCatalog() async {
    if (_inMemoryCatalog.isNotEmpty || _isPreloading) return;
    _isPreloading = true;
    try {
      final jsonStr = await rootBundle.loadString('assets/jsons/fallback_products.json');
      final List<dynamic> rawList = jsonDecode(jsonStr);
      _inMemoryCatalog = rawList.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      AppLogger.success('⚡ [MatchingEngine] ${_inMemoryCatalog.length} produits préchargés en mémoire vive (RAM)', 'Matching');
    } catch (e) {
      AppLogger.warning('⚠️ [MatchingEngine] Erreur préchargement JSON: $e', 'Matching');
    } finally {
      _isPreloading = false;
    }
  }

  /// Normalise un identifiant ou nom de catégorie vers le tag officiel cat_*
  static String? normalizeCategoryTag(String? category) {
    if (category == null) return null;
    final c = category.toLowerCase().trim();
    if (c == 'all' || c == 'pour toi' || c.isEmpty) return null;
    if (c.startsWith('cat_')) return c;

    const mapping = {
      'tech': 'cat_tech',
      'fashion': 'cat_mode',
      'mode': 'cat_mode',
      'home': 'cat_maison',
      'maison': 'cat_maison',
      'beauty': 'cat_beaute',
      'beaute': 'cat_beaute',
      'beauté': 'cat_beaute',
      'food': 'cat_food',
      'sport': 'cat_sport',
      'art': 'cat_art',
      'reading': 'cat_lecture',
      'lecture': 'cat_lecture',
      'livres': 'cat_lecture',
      'travel': 'cat_voyage',
      'voyage': 'cat_voyage',
      'gaming': 'cat_jeuxvideo',
      'jeuxvideo': 'cat_jeuxvideo',
      'jeux video': 'cat_jeuxvideo',
      'music': 'cat_musique',
      'musique': 'cat_musique',
      'garden': 'cat_jardinage',
      'jardinage': 'cat_jardinage',
      'jardin': 'cat_jardinage',
      'wellness': 'cat_bienetre',
      'bienetre': 'cat_bienetre',
      'bien-etre': 'cat_bienetre',
      'bien-être': 'cat_bienetre',
      'mechanic': 'cat_mecanique_auto',
      'mecanique': 'cat_mecanique_auto',
      'mécanique': 'cat_mecanique_auto',
      'auto': 'cat_mecanique_auto',
      'automobile': 'cat_mecanique_auto',
      'aeronautic': 'cat_aeronautique',
      'aeronautique': 'cat_aeronautique',
      'aéronautique': 'cat_aeronautique',
      'aviation': 'cat_aeronautique',
      'trending': 'popularite_5',
      'tendances': 'popularite_5',
    };

    return mapping[c] ?? (TagsDefinitions.categoryConversion[c] ?? c);
  }

  /// - "discovery": Mode Inspirations - Très souple, variété maximale
  static Future<List<Map<String, dynamic>>> getPersonalizedProducts({
    required Map<String, dynamic> userTags,
    int count = 50,
    String? category,
    String? brand,
    List<dynamic>? excludeProductIds,
    String filteringMode = "discovery",
    List<String>? brandsSeen,
  }) async {
    try {
      AppLogger.info('🎯 Matching produits pour tags: ${userTags.keys.join(", ")}', 'Matching');
      AppLogger.info('🔒 Mode filtrage: $filteringMode (catégorie: $category, marque: $brand)', 'Matching');

      // S'assurer que le catalogue mémoire est prêt
      if (_inMemoryCatalog.isEmpty) {
        await preloadCatalog();
      }

      // FIX F2: clé isolée par UID
      List<String> effectiveBrandsSeen = brandsSeen ?? [];
      if (effectiveBrandsSeen.isEmpty && (brand == null || brand == 'all')) {
        try {
          final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
          final prefs = await SharedPreferences.getInstance();
          effectiveBrandsSeen = prefs.getStringList('brands_seen_v3_$uid') ?? [];
        } catch (e) {
          AppLogger.warning('⚠️ Impossible de charger brands_seen: $e', 'Matching');
        }
      }

      final searchTags = _convertUserTagsToSearchTags(userTags);

      String? genderFilter;
      final gender = userTags['gender'] ?? userTags['recipientGender'];
      if (gender != null) {
        final genderStr = gender.toString();
        if (genderStr.contains('Femme') || genderStr.contains('femme')) {
          genderFilter = 'gender_femme';
        } else if (genderStr.contains('Homme') || genderStr.contains('homme')) {
          genderFilter = 'gender_homme';
        } else {
          genderFilter = 'gender_mixte';
        }
      }

      final normalizedCat = normalizeCategoryTag(category);
      final cleanCatLower = normalizedCat?.toLowerCase().trim();
      final cleanBrandLower = (brand != null && brand != 'all')
          ? brand.toLowerCase().trim()
          : null;

      // ⚡ CHARGEMENT INSTANTANÉ DEPUIS LE CACHE MÉMOIRE VIVE (0 ms)
      List<Map<String, dynamic>> allProducts = [];

      if (_inMemoryCatalog.isNotEmpty) {
        allProducts = _inMemoryCatalog.where((p) {
          if (cleanBrandLower != null) {
            final pBrand = (p['brand'] ?? '').toString().toLowerCase();
            final pBrandNorm = pBrand.replaceAll('&', '').replaceAll(' ', '').replaceAll('-', '');
            final filterNorm = cleanBrandLower.replaceAll('&', '').replaceAll(' ', '').replaceAll('-', '');
            final pCats = (p['categories'] as List<dynamic>? ?? []).map((c) => c.toString().toLowerCase()).toList();
            final matchesBrand = pBrand.contains(cleanBrandLower) ||
                pBrandNorm.contains(filterNorm) ||
                pCats.contains(cleanBrandLower) ||
                pCats.contains(filterNorm);
            if (!matchesBrand) return false;
          }
          if (cleanCatLower != null) {
            final pCat = (p['category'] ?? '').toString().toLowerCase();
            final pCats = (p['categories'] as List<dynamic>? ?? []).map((c) => c.toString().toLowerCase()).toList();
            final pTags = (p['tags'] as List<dynamic>? ?? []).map((t) => t.toString().toLowerCase()).toList();
            final allPList = {pCat, ...pCats, ...pTags};
            if (cleanCatLower == 'popularite_5') {
              return allPList.contains('popularite_5') || allPList.contains('popularite_4');
            }
            return allPList.contains(cleanCatLower) || (category != null && allPList.contains(category.toLowerCase()));
          }
          return true;
        }).toList();

        // Si le filtre spécifique ne donne rien en mémoire, fallback sur le catalogue complet
        if (allProducts.isEmpty && cleanCatLower == null && cleanBrandLower == null) {
          allProducts = List.from(_inMemoryCatalog);
        }
      }

      // Si le cache mémoire était vide, fallback Firestore
      if (allProducts.isEmpty) {
        var q = _firestore.collection('gifts') as Query<Map<String, dynamic>>;
        if (cleanBrandLower != null) {
          final normBrand = cleanBrandLower.replaceAll('&', '').replaceAll(' ', '').replaceAll('-', '');
          q = q.where('categories', arrayContains: normBrand);
        } else if (cleanCatLower != null) {
          q = q.where('categories', arrayContains: cleanCatLower);
        }
        final snap = await q.limit(300).get(const GetOptions(source: Source.serverAndCache));
        allProducts = snap.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      }

      // Synchronisation en arrière-plan avec Firestore (Stale-While-Revalidate silencieux)
      Future.microtask(() async {
        try {
          final snap = await _firestore.collection('gifts').limit(300).get(const GetOptions(source: Source.serverAndCache));
          if (snap.docs.isNotEmpty) {
            final remote = snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList();
            // Mettre à jour le cache mémoire
            final mapById = {for (var p in _inMemoryCatalog) p['id']: p};
            for (var r in remote) {
              mapById[r['id']] = r;
            }
            _inMemoryCatalog = mapById.values.toList();
          }
        } catch (_) {}
      });

      // 3️⃣ Fallback vers collection 'products' si toujours vide
      if (allProducts.isEmpty) {
        try {
          final snapProd = await _firestore.collection('products').limit(300).get(const GetOptions(source: Source.serverAndCache));
          allProducts = snapProd.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        } catch (_) {}
      }

      // ⛔ Si toujours vide, erreur critique
      if (allProducts.isEmpty) {
        AppLogger.error('❌ AUCUN PRODUIT DANS LE CATALOGUE', 'Matching', null);
        throw Exception('FIREBASE VIDE - Aucun produit trouvé.');
      }

      AppLogger.success('✅ ${allProducts.length} produits disponibles (0 ms)', 'Matching');


      // FIX F12: N'injecter la wishlist QUE si personIdentifier est un UID Firebase
      // (format: 20-28 chars alphanumériques). Un prénom libre comme "Marie" peut
      // matcher n'importe quel utilisateur Doron nommé Marie, y compris des inconnus.
      final personIdentifier = userTags['personUid'] ?? userTags['personIdentifier'];
      final isUsername = userTags['isUsername'] == true || (personIdentifier != null && personIdentifier.toString().startsWith('@'));
      final looksLikeUid = personIdentifier != null &&
          personIdentifier.toString().length >= 20 &&
          !personIdentifier.toString().contains(' ');
      if (looksLikeUid || isUsername) {
        final wishlistProducts = await _fetchWishlistByUsername(personIdentifier.toString());
        if (wishlistProducts.isNotEmpty) {
           AppLogger.info('🪄 Wishlist de $personIdentifier: ${wishlistProducts.length} produits injectés', 'Matching');
           final existingIds = allProducts.map((p) => p['id']).toSet();
           for (final wp in wishlistProducts) {
             if (!existingIds.contains(wp['id'])) {
               allProducts.add(wp);
             } else {
               final index = allProducts.indexWhere((p) => p['id'] == wp['id']);
               if (index != -1) allProducts[index]['isFromRecipientWishlist'] = true;
             }
           }
        }
      }

      // ⚡ RECHERCHE EN DIRECT SERPAPI (Google Shopping France) POUR LE QUESTIONNAIRE
      if (filteringMode == "person") {
        try {
          final liveProducts = await SerpLiveSearchService.fetchLiveProductsForQuiz(userTags);
          if (liveProducts.isNotEmpty) {
            AppLogger.info('✨ [LiveSearch] ${liveProducts.length} produits Google Shopping en direct injectés !', 'Matching');
            allProducts.insertAll(0, liveProducts);
          }
        } catch (e) {
          AppLogger.warning('⚠️ LiveSearch error (non bloquant): $e', 'Matching');
        }
      }


      // ============= FILTRAGE PAR TYPE DE CADEAU =============
      // JAMAIS de filtrage strict sur les types de cadeaux - seulement scoring
      // Cela permet d'avoir des cadeaux innovants même en mode PERSON
      final giftTypes = userTags['giftTypes'];
      if (giftTypes != null) {
        final typesList = giftTypes is List ? giftTypes : [giftTypes];
        AppLogger.info('🎁 Types de cadeaux demandés: ${typesList.join(", ")} (scoring favorisera ces types)', 'Matching');
      }

      // Scorer et trier les produits par pertinence
      AppLogger.info('🎯 Début du scoring de ${allProducts.length} produits...', 'Matching');
      final scoredProducts = <Map<String, dynamic>>[];
      int scoringErrors = 0;

      // 🎲 Seed de variation unique par appel — garantit des ordres différents
      // entre deux requêtes identiques (epsilon ±8pts)
      final sessionSeed = DateTime.now().microsecondsSinceEpoch;
      final variationRng = Random(sessionSeed);
      AppLogger.debug('🎲 Session seed: $sessionSeed (variation ±8pts)', 'Matching');

      for (var product in allProducts) {
        try {
          final score = _calculateMatchScore(
            product,
            searchTags,
            userTags,
            filteringMode: filteringMode,
            categoryFilter: category,
            brandsSeen: effectiveBrandsSeen, // Anti-doublon marque
          );
          // Epsilon de variation : ±8pts — brise les égalités sans déplacer les tops nets
          final epsilon = score > -1000 ? (variationRng.nextDouble() * 16.0 - 8.0) : 0.0;
          scoredProducts.add({
            ...product,
            '_matchScore': score + epsilon,
            '_baseScore': score,
          });
        } catch (e) {
          scoringErrors++;
          AppLogger.warning('⚠️ Erreur scoring produit ${product['id']}: $e', 'Matching');
          scoredProducts.add({
            ...product,
            '_matchScore': 0.0,
            '_baseScore': 0.0,
          });
        }
      }

      if (scoringErrors > 0) {
        AppLogger.warning('⚠️ $scoringErrors produits ont eu des erreurs de scoring', 'Matching');
      }
      AppLogger.success('✅ Scoring terminé: ${scoredProducts.length} produits', 'Matching');

      // 🎯 PAS DE SEUIL MINIMUM - On prend les meilleurs produits peu importe leur score
      // Cela garantit qu'on a toujours des produits variés même si le matching n'est pas parfait
      AppLogger.info('📊 ${scoredProducts.length} produits disponibles pour sélection', 'Matching');

      // Trier par score décroissant pour avoir les meilleurs en premier
      scoredProducts.sort((a, b) => (b['_matchScore'] as double).compareTo(a['_matchScore'] as double));

      // Filtrer les produits avec score d'exclusion (-10000) SAUF en mode discovery
      var relevantProducts = scoredProducts;
      if (filteringMode != "discovery") {
        // Compter les produits exclus pour debug
        final excludedProducts = scoredProducts.where((p) => (p['_matchScore'] as double) <= -1000).toList();
        AppLogger.warning('⚠️ EXCLUS: ${excludedProducts.length} produits avec score <= -1000', 'Matching');

        // Log sample de produits exclus pour debug
        if (excludedProducts.isNotEmpty) {
          final sample = excludedProducts.first;
          AppLogger.debug('🔍 PRODUIT EXCLU: "${sample['name']}" score=${sample['_matchScore']}, tags=${sample['tags']}', 'Matching');
        }

        relevantProducts = scoredProducts.where((p) => (p['_matchScore'] as double) > -1000).toList();
        AppLogger.info('📊 Filtrage par score: ${relevantProducts.length} produits après exclusion (${excludedProducts.length} exclus)', 'Matching');

        // 🆘 FALLBACK: Si TOUS les produits sont exclus (score <= -1000)
        // Cela signifie que TOUS ont le mauvais genre explicite
        if (relevantProducts.isEmpty && scoredProducts.isNotEmpty) {
          AppLogger.warning('⚠️ TOUS LES PRODUITS EXCLUS par filtrage genre strict', 'Matching');
          AppLogger.warning('📝 Prendre les meilleurs scores parmi les non-exclus ou les produits universels', 'Matching');

          // Chercher les produits avec score > -5000 (exclus mais pas pour genre explicite)
          // Les produits à -10000 ont un tag genre_homme/gender_femme explicite qui ne correspond pas
          // Les produits neutres/universels auront un score positif
          final lessStrictProducts = scoredProducts.where((p) => (p['_matchScore'] as double) > -5000).toList();

          if (lessStrictProducts.isNotEmpty) {
            relevantProducts = lessStrictProducts;
            AppLogger.info('🆘 FALLBACK: ${relevantProducts.length} produits avec score > -5000', 'Matching');
          } else {
            // Vraiment aucun produit compatible - prendre les meilleurs quand même
            relevantProducts = scoredProducts.take(count * 2).toList();
            AppLogger.warning('🆘 FALLBACK ULTIME: ${relevantProducts.length} meilleurs produits (même mauvais genre)', 'Matching');
          }
        }

        // Log sample de produits gardés pour debug
        if (relevantProducts.isNotEmpty) {
          final sample = relevantProducts.first;
          AppLogger.debug('✅ PRODUIT GARDÉ: "${sample['name']}" score=${sample['_matchScore']}, tags=${sample['tags']}', 'Matching');
        }
      } else {
        AppLogger.info('📊 Mode discovery: AUCUN filtrage par score, ${relevantProducts.length} produits disponibles', 'Matching');
      }

      // 🎲 PRÉSERVATION DU TOP & SHUFFLE INTELLIGENT
      final random = Random(DateTime.now().microsecondsSinceEpoch);
      List<Map<String, dynamic>> shuffledProducts;

      if (filteringMode == 'home' || category != null || brand != null) {
        // En mode Home/Catégorie/Marque : On garde les 25% meilleurs produits (flagships & tendances phares) strictement au sommet, et on shuffle le reste pour la découverte
        final topCount = (relevantProducts.length * 0.25).ceil();
        final topProducts = relevantProducts.take(topCount).toList();
        final restProducts = relevantProducts.skip(topCount).toList();
        restProducts.shuffle(random);
        shuffledProducts = [...topProducts, ...restProducts];
        AppLogger.debug('🏆 Top $topCount produits phares maintenus en tête, ${restProducts.length} produits secondaires mélangés', 'Matching');
      } else {
        // En mode Quiz : Top 15% préservé en tête, 85% mélangé pour la variété
        final topCount = (relevantProducts.length * 0.15).ceil();
        final topProducts = relevantProducts.take(topCount).toList();
        final middleProducts = relevantProducts.skip(topCount).toList();
        middleProducts.shuffle(random);
        shuffledProducts = [...topProducts, ...middleProducts];
        AppLogger.debug('🎲 Quiz: top $topCount préservé + ${middleProducts.length} mélangés', 'Matching');
      }

      // ⚠️ VÉRIFICATION CRITIQUE: Y a-t-il des produits à ce stade ?
      if (shuffledProducts.isEmpty) {
        AppLogger.error('❌ AUCUN PRODUIT après shuffle ! Tous exclus par scoring ou filtres.', 'Matching');
        return [];
      }
      AppLogger.success('✅ ${shuffledProducts.length} produits disponibles pour sélection finale', 'Matching');

      // 🎯 DÉDUPLICATION ET DIVERSITÉ DES MARQUES (max 20% d'une même marque)
      final selectedProducts = <Map<String, dynamic>>[];
      final brandCounts = <String, int>{};
      final categoryCounts = <String, int>{}; // Diversité des catégories
      final maxPerBrand = (count * 0.2).ceil(); // 20% max par marque
      final maxPerCategory = (count * 0.3).ceil(); // 30% max par catégorie
      final seenProductIds = <dynamic>{};
      final seenProductNames = <String>{}; // Déduplication par nom normalisé
      final excludedIds = excludeProductIds?.toSet() ?? {};
      int categoryFilteredCount = 0; // Compteur de produits filtrés par catégorie

      // ✅ EXCLUSION RÉACTIVÉE pour éviter de revoir les mêmes produits
      AppLogger.info('🎯 Exclusion de ${excludedIds.length} produits déjà vus', 'Matching');
      AppLogger.debug('🎯 Max par marque: $maxPerBrand produits (20%)', 'Matching');
      AppLogger.debug('🎯 Max par catégorie: $maxPerCategory produits (30%)', 'Matching');

      for (var product in shuffledProducts) {
        if (selectedProducts.length >= count) break;

        final productId = product['id'];
        final brand = product['brand']?.toString() ?? 'Unknown';
        final productName = product['name']?.toString() ?? '';
        final normalizedName = _normalizeProductName(productName);

        // Extraire la catégorie principale
        final categories = (product['categories'] as List?)?.cast<String>() ?? [];
        final mainCategory = categories.isNotEmpty ? categories.first : 'Autre';

        // 1️⃣ Vérifier exclusion des produits déjà vus
        if (excludedIds.contains(productId)) {
          continue;
        }

        // 2️⃣ Vérifier dédupli par ID
        if (seenProductIds.contains(productId)) {
          continue;
        }

        // 3️⃣ Vérifier dédupli par nom normalisé (doublons visuels)
        if (seenProductNames.contains(normalizedName)) {
          continue;
        }

        final isBrandSpecific = cleanBrandLower != null && cleanBrandLower != 'all';
        final currentBrandCount = brandCounts[brand] ?? 0;
        final currentCategoryCount = categoryCounts[mainCategory] ?? 0;

        // 4️⃣ Vérifier limite par marque et catégorie (uniquement en mode découverte globale)
        if (!isBrandSpecific) {
          if (currentBrandCount >= maxPerBrand) {
            continue; // Skip, trop de produits de cette marque
          }
          if (currentCategoryCount >= maxPerCategory) {
            continue; // Skip, trop de produits de cette catégorie
          }
        } else {
          // En mode marque spécifique (ex: Zara), s'assurer que le produit appartient strictement à cette marque
          final pBrand = (product['brand'] ?? '').toString().toLowerCase();
          final pCategories = (product['categories'] as List?)?.cast<String>() ?? [];
          final matchesBrand = pBrand.contains(cleanBrandLower) || pCategories.any((c) => c.toLowerCase() == cleanBrandLower);
          if (!matchesBrand) {
            continue; // Skip les produits des autres marques (comme Apple / AirPods)
          }
        }

        // 6️⃣ SUPPRIMÉ: Filtrage par genre (redondant avec scoring qui fait déjà exclusion -10000)
        // Le scoring _calculateMatchScore() gère déjà l'exclusion par genre
        // Pas besoin de filtrer une 2ème fois ici

        // 7️⃣ Vérifier correspondance catégorie - FILTRAGE STRICT si catégorie sélectionnée
        // Si l'utilisateur a cliqué sur une catégorie (Tech, Mode, etc.), montrer UNIQUEMENT cette catégorie
        if (category != null && category != 'Pour toi' && category != 'all') {
          final productTags = (product['tags'] as List?)?.cast<String>() ?? [];
          final productCategories = (product['categories'] as List?)?.cast<String>() ?? [];
          final productCategory = product['category']?.toString() ?? '';

          // Normaliser la catégorie recherchée
          final normalizedCategory = _normalizeTag(category);

          // Vérifier si le produit appartient à cette catégorie
          final matchesCategory =
            productTags.any((tag) => _normalizeTag(tag) == normalizedCategory || _normalizeTag(tag).contains(normalizedCategory)) ||
            productCategories.any((cat) => _normalizeTag(cat) == normalizedCategory || _normalizeTag(cat).contains(normalizedCategory)) ||
            _normalizeTag(productCategory) == normalizedCategory ||
            _normalizeTag(productCategory).contains(normalizedCategory);

          if (!matchesCategory) {
            // Ce produit n'appartient pas à la catégorie demandée, on le skip
            categoryFilteredCount++;
            continue;
          }
        }

        // ✅ Ajouter le produit
        selectedProducts.add(product);
        seenProductIds.add(productId);
        seenProductNames.add(normalizedName);
        brandCounts[brand] = currentBrandCount + 1;
        categoryCounts[mainCategory] = currentCategoryCount + 1;
      }

      // 📊 Log du filtrage par catégorie
      if (category != null && category != 'Pour toi' && category != 'all') {
        AppLogger.info('📁 Filtrage catégorie "$category": ${categoryFilteredCount} produits exclus, ${selectedProducts.length} produits retenus', 'Matching');
      }

      // FIX F2: clé isolée par UID pour ne pas polluer les autres comptes
      try {
        final seenBrands = selectedProducts
            .take(10)
            .map((p) => (p['brand'] ?? '').toString().toLowerCase())
            .where((b) => b.isNotEmpty)
            .toSet()
            .take(5)
            .toList();
        if (seenBrands.isNotEmpty) {
          final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList('brands_seen_v3_$uid', seenBrands);
          AppLogger.debug('💾 Marques sauvegardées (uid=$uid): $seenBrands', 'Matching');
        }
      } catch (e) {
        AppLogger.warning('⚠️ Impossible de sauvegarder brands_seen: $e', 'Matching');
      }

      // 🎨 MÉLANGE INTELLIGENT FINAL pour éviter produits similaires côte à côte
      // Séparer par catégorie et entremêler
      final productsByCategory = <String, List<Map<String, dynamic>>>{};
      for (var product in selectedProducts) {
        final categories = (product['categories'] as List?)?.cast<String>() ?? [];
        final mainCategory = categories.isNotEmpty ? categories.first : 'Autre';
        productsByCategory.putIfAbsent(mainCategory, () => []).add(product);
      }

      // Reconstruire la liste en alternant les catégories
      final diversifiedProducts = <Map<String, dynamic>>[];
      final categoryKeys = productsByCategory.keys.toList();
      int maxIterations = selectedProducts.length;
      int iteration = 0;

      while (diversifiedProducts.length < selectedProducts.length && iteration < maxIterations) {
        for (var category in categoryKeys) {
          final products = productsByCategory[category]!;
          if (products.isNotEmpty) {
            diversifiedProducts.add(products.removeAt(0));
            if (diversifiedProducts.length >= selectedProducts.length) break;
          }
        }
        iteration++;
      }

      // Remplacer la liste sélectionnée par la version diversifiée
      selectedProducts
        ..clear()
        ..addAll(diversifiedProducts);

      // Retirer le score de matching avant de retourner
      for (var product in selectedProducts) {
        product.remove('_matchScore');
      }

      // 🖼️ EXTRACTION ROBUSTE DES IMAGES - Ajouter le champ 'image' standardisé
      AppLogger.info('🖼️ Extraction des URLs d\'images pour ${selectedProducts.length} produits...', 'Matching');
      int imagesFound = 0;
      int imagesPlaceholder = 0;

      for (var product in selectedProducts) {
        final imageUrl = _extractImageUrl(product);
        product['image'] = imageUrl;

        if (imageUrl.contains('placeholder')) {
          imagesPlaceholder++;
        } else {
          imagesFound++;
        }

        // FIX F11: Marquer les produits récents (< 30 jours) comme isNew
        // pour que le filtre "Nouveau" de la page Home soit fonctionnel
        try {
          final createdAt = product['createdAt'];
          if (createdAt != null) {
            DateTime? createdDate;
            if (createdAt is DateTime) {
              createdDate = createdAt;
            } else if (createdAt.runtimeType.toString().contains('Timestamp')) {
              createdDate = (createdAt as dynamic).toDate() as DateTime;
            }
            if (createdDate != null) {
              final age = DateTime.now().difference(createdDate).inDays;
              product['isNew'] = age <= 30;
            }
          }
        } catch (_) {}
      }

      AppLogger.success('🖼️ Images extraites: $imagesFound URLs valides, $imagesPlaceholder placeholders', 'Matching');

      // 🔥 NOUVEAU: Reranking "Perfect Match 200%" avec l'IA Claude
      // On le fait uniquement si le mode n\'est pas "discovery" pour garder le fun
      // et pour limiter les coûts d\'API sur les recherches très vagues.
      List<Map<String, dynamic>> finalProducts = selectedProducts;
      if (filteringMode != "discovery" && finalProducts.length > 5) {
        // We only take the top 50 to rerank (Claude input limit/token optimization)
        final top50ToRerank = finalProducts.take(50).toList();
        
        // Appeler ClaudeApiService (il faut l\'importer si pas déjà fait)
        // Note: l\'import sera ajouté au début du fichier
        try {
           finalProducts = await ClaudeApiService.rerankProducts(top50ToRerank, userTags);
           // Re-append the rest if any
           if (selectedProducts.length > 50) {
             finalProducts.addAll(selectedProducts.skip(50));
           }
        } catch (e) {
           AppLogger.error('Erreur lors du reranking IA, fallback aux résultats classiques', 'Matching');
        }
      }

      AppLogger.success('${finalProducts.length} produits matchés et retournés', 'Matching');
      AppLogger.info('📊 Diversité des marques: ${brandCounts.length} marques différentes', 'Matching');
      AppLogger.debug('📊 Répartition marques: ${brandCounts.entries.map((e) => "${e.key}: ${e.value}").take(10).join(", ")}', 'Matching');
      AppLogger.debug('📊 Répartition catégories: ${categoryCounts.entries.map((e) => "${e.key}: ${e.value}").join(", ")}', 'Matching');
      return finalProducts;
    } catch (e, stackTrace) {
      // ⚠️ ERREUR LORS DU CHARGEMENT - Logger détails complets
      AppLogger.error('❌ ERREUR lors du matching produits', 'Matching', e);
      AppLogger.error('Type erreur: ${e.runtimeType}', 'Matching', null);
      AppLogger.error('Message: ${e.toString()}', 'Matching', null);
      AppLogger.error('StackTrace complet:', 'Matching', null);
      AppLogger.error('$stackTrace', 'Matching', null);

      // Vérifier si c'est une erreur Firebase spécifique
      if (e.toString().contains('permission') || e.toString().contains('Permission')) {
        AppLogger.error('⚠️ ERREUR PERMISSIONS FIREBASE - Vérifier les Firestore Rules!', 'Matching', null);
      }
      if (e.toString().contains('network') || e.toString().contains('Network')) {
        AppLogger.error('⚠️ ERREUR RÉSEAU - Pas de connexion internet?', 'Matching', null);
      }

      // Retourner liste vide au lieu de crasher pour que l'app continue
      AppLogger.warning('Retour liste vide pour éviter crash app', 'Matching');
      return [];
    }
  }

  /// Convertit les tags utilisateur en tags de recherche OFFICIELS
  /// Utilise UNIQUEMENT les tags de TagsDefinitions
  static Set<String> _convertUserTagsToSearchTags(Map<String, dynamic> userTags) {
    final tags = <String>{};

    // ========================================================================
    // 1️⃣ GENRE
    // ========================================================================
    final gender = userTags['gender'] ?? userTags['recipientGender'];
    if (gender != null) {
      final genderStr = gender.toString().toLowerCase();
      // FIX: Détecter "Femme" et "Homme" même avec emojis
      if (genderStr.contains('femme')) {
        tags.add('gender_femme');
        AppLogger.debug('🚹 Genre converti: $genderStr → gender_femme', 'TagsConversion');
      } else if (genderStr.contains('homme')) {
        tags.add('gender_homme');
        AppLogger.debug('🚹 Genre converti: $genderStr → gender_homme', 'TagsConversion');
      } else if (genderStr.contains('enfant')) {
        // Enfant: neutre de base, on évite le filtrage strict de genre
        tags.add('gender_mixte');
        AppLogger.debug('🚹 Genre converti: $genderStr → gender_mixte', 'TagsConversion');
      } else {
        tags.add('gender_mixte');
      }
    }

    // ========================================================================
    // 2️⃣ ÂGE (Directement en tags de recherche)
    // ========================================================================
    final age = userTags['age'] ?? userTags['recipientAge'];
    if (age != null) {
      final ageStr = age.toString().toLowerCase();
      if (ageStr.contains('moins de 12') || ageStr.contains('enfant')) {
        tags.add('age_enfant');
      } else if (ageStr.contains('ados') || ageStr.contains('13-17')) {
        tags.add('age_ado');
      } else if (ageStr.contains('18-25') || ageStr.contains('26-45')) {
        tags.add('age_adulte');
      } else if (ageStr.contains('45-65') || ageStr.contains('65+')) {
        tags.add('age_senior');
      }
    }

    // ========================================================================
    // 3️⃣ BUDGET (STRICT - 1 seul tag principal, conversion des paliers)
    // ========================================================================
    final budgetTier = userTags['budgetTier'] ?? userTags['budget'];
    if (budgetTier != null) {
      final budgetStr = budgetTier.toString().toLowerCase();
      if (budgetStr.contains('< 20') || budgetStr == '10.0' || budgetStr == '20.0') {
        tags.add('budget_0_50');
      } else if (budgetStr.contains('20€ - 50€') || budgetStr == '50.0') {
        tags.add('budget_0_50'); // Jusqu'à 50€
        tags.add('budget_50_100'); // Marge de tolérance
      } else if (budgetStr.contains('50€ - 150€')) {
        tags.addAll(['budget_50_100', 'budget_100_200']);
      } else if (budgetStr.contains('luxe')) {
        tags.addAll(['budget_100_200', 'budget_200+']);
      } else if (budgetTier is num) {
        tags.add(TagsDefinitions.getBudgetTagFromPrice(budgetTier.toInt()));
      }
    }

    // ========================================================================
    // 4️⃣ PERSONNALITÉS / STYLE DE VIE (L'entonnoir principal de la refonte)
    // ========================================================================
    final personality = userTags['recipientPersonality'];
    if (personality != null) {
      final personalityList = personality is List ? personality : [personality];
      for (final p in personalityList) {
        final pStr = p.toString().toLowerCase();
        if (pStr.contains("explorateur")) {
          tags.addAll(['passion_voyages', 'passion_nature', 'type_voyage_aventure', 'type_sport_outdoor', 'perso_aventurier']);
        } else if (pStr.contains("casanier")) {
          tags.addAll(['cat_maison', 'passion_lecture', 'passion_cuisine', 'style_minimaliste', 'type_maison_deco']);
        } else if (pStr.contains("tech-enthusiast") || pStr.contains("tech")) {
          tags.addAll(['cat_tech', 'passion_jeuxvideo', 'passion_tech', 'type_high_tech', 'perso_techie']);
        } else if (pStr.contains("fashioniste")) {
          tags.addAll(['cat_mode', 'cat_beaute', 'passion_mode', 'passion_beaute', 'style_tendance', 'style_elegant']);
        } else if (pStr.contains("épicurien") || pStr.contains("epicurien")) {
          tags.addAll(['cat_food', 'passion_vins', 'passion_cuisine', 'type_gastronomie', 'perso_gourmand']);
        } else if (pStr.contains("créatif") || pStr.contains("creatif")) {
          tags.addAll(['passion_art', 'passion_musique', 'passion_loisirs_creatifs', 'perso_creatif', 'type_loisirs_creatifs', 'style_boheme']);
        } else {
          // Fallback legacy behavior
          TagsDefinitions.personalityConversion.forEach((key, value) {
            if (pStr.contains(key.toLowerCase())) tags.add(value);
          });
        }
      }
    }

    // ========================================================================
    // 5️⃣ OCCASION
    // ========================================================================
    final occasion = userTags['occasion'];
    if (occasion != null) {
      final occStr = occasion.toString().toLowerCase();
      if (occStr.contains('anniversaire')) {
        tags.add('occasion_anniversaire');
      } else if (occStr.contains('noël') || occStr.contains('noel')) {
        tags.add('occasion_noel');
      } else if (occStr.contains('valentin')) {
        tags.add('occasion_saint_valentin');
      } else if (occStr.contains('crémaillère') || occStr.contains('cremaillere')) {
        tags.addAll(['occasion_fete', 'cat_maison', 'type_maison_deco']);
      } else if (occStr.contains('mariage')) {
        tags.addAll(['occasion_mariage', 'style_luxe']);
      } else if (occStr.contains('naissance')) {
        tags.add('occasion_naissance');
      } else if (occStr.contains('remerciement')) {
        tags.add('occasion_remerciement');
      } else if (occStr.contains('diplôme') || occStr.contains('diplome')) {
        tags.add('occasion_diplome');
      } else if (occStr.contains('fête') || occStr.contains('fete')) {
        // "Fête des Mères/Pères" et occasions génériques
        tags.add('occasion_fete');
      }
    }

    // ========================================================================
    // 5️⃣bis SAISON (explicite si fournie, sinon déduite de la date du jour)
    // ========================================================================
    final saison = userTags['saison'] ?? userTags['season'];
    if (saison != null && saison.toString().isNotEmpty) {
      final saisonStr = saison.toString().toLowerCase();
      if (saisonStr.contains('print')) {
        tags.add('saison_printemps');
      } else if (saisonStr.contains('été') || saisonStr.contains('ete')) {
        tags.add('saison_ete');
      } else if (saisonStr.contains('automne')) {
        tags.add('saison_automne');
      } else if (saisonStr.contains('hiver')) {
        tags.add('saison_hiver');
      } else {
        tags.add(TagsDefinitions.getSaisonTag());
      }
    } else {
      // Pas de saison explicite dans le quiz → on déduit de la date du jour,
      // ça favorise les produits de saison sans jamais exclure les autres
      // (voir scoring souple dans _calculateMatchScore).
      tags.add(TagsDefinitions.getSaisonTag());
    }

    // ========================================================================
    // 6️⃣ CATÉGORIE PRINCIPALE (Fallback au cas où)
    // ========================================================================
    final preferredCategories = userTags['preferredCategories'];
    if (preferredCategories != null) {
      final catList = preferredCategories is List ? preferredCategories : [preferredCategories];
      for (final cat in catList) {
        final catStr = cat.toString();
        final converted = TagsDefinitions.categoryConversion[catStr];
        if (converted != null) {
          tags.add(converted);
        }
      }
    }

    // ========================================================================
    // 7️⃣ TYPES DE CADEAUX (Physique vs Expérience)
    // ========================================================================
    final giftTypes = userTags['giftTypes'];
    if (giftTypes != null) {
      final typesList = giftTypes is List ? giftTypes : [giftTypes];
      for (final type in typesList) {
        final typeStr = type.toString().toLowerCase();
        if (typeStr.contains('physique')) {
          tags.addAll(['type_mode_accessoires', 'type_maison_deco', 'type_livres_bd', 'type_high_tech', 'cat_mode', 'cat_tech', 'cat_maison']);
        } else if (typeStr.contains('expérience') || typeStr.contains('experience') || typeStr.contains('activité') || typeStr.contains('activite')) {
          tags.addAll(['type_voyage_aventure', 'type_bien_etre', 'type_gastronomie', 'type_culture', 'passion_voyages']);
        } else {
          // Fallback legacy behavior
          for (final validType in TagsDefinitions.giftTypeTags) {
            if (typeStr.contains(validType.replaceFirst('type_', '')) || validType.contains(typeStr)) {
              tags.add(validType);
              break;
            }
          }
        }
      }
    }

    // ========================================================================
    // VALIDATION FINALE - Ne garder QUE les tags valides
    // ========================================================================
    final validTags = TagsDefinitions.filterValidTags(tags.toList());

    // Normaliser les tags : toLowerCase + remplacer tirets par underscores
    // Pour être cohérent avec les tags Firebase (budget_100-200 → budget_100_200)
    final normalizedTags = validTags.map((t) => t.toLowerCase().replaceAll('-', '_')).toSet();

    AppLogger.success('✅ Tags convertis: ${normalizedTags.length} tags valides sur ${tags.length} générés', 'TagsConversion');
    AppLogger.debug('🏷️ Tags finaux: ${normalizedTags.join(", ")}', 'TagsConversion');

    return normalizedTags;
  }

  /// Calcule le score de matching selon le NOUVEAU SYSTÈME DE TAGS OFFICIEL
  ///
  /// LOGIQUE STRICTE (correspondance exacte REQUISE - sinon exclusion):
  /// - Genre (gender_*) - SAUF en mode discovery
  /// - Catégorie principale (cat_*) - SAUF en mode discovery
  /// - Tranche de prix (budget_*) - SAUF en mode discovery
  ///
  /// LOGIQUE SOUPLE (scoring partiel - augmente score si match):
  /// - Styles (style_*)
  /// - Personnalités (perso_*)
  /// - Passions (passion_*)
  /// - Types de cadeaux (type_*)
  static double _calculateMatchScore(
    Map<String, dynamic> product,
    Set<String> searchTags,
    Map<String, dynamic> userTags, {
    String filteringMode = "home",
    String? categoryFilter,
    List<String> brandsSeen = const [], // Anti-doublon marque
  }) {
    // ⭐ BONUS DE BASE: +150 points pour TOUS les produits
    // Garantit qu'un produit avec quelques pénalités aura quand même un score positif
    // Évite que tous les produits aient scores négatifs et soient filtrés
    double score = 150.0;

    // Déterminer si un filtre de catégorie est actif
    final hasCategoryFilter = categoryFilter != null &&
                               categoryFilter != 'Pour toi' &&
                               categoryFilter != 'all';

    // Extraire TOUS les tags du produit (tags + categories)
    final productTags = (product['tags'] as List?)?.cast<String>() ?? [];
    final productCategories = (product['categories'] as List?)?.cast<String>() ?? [];
    // Normaliser les tags : toLowerCase + remplacer tirets par underscores
    // Firebase peut avoir "budget_100-200" ou "budget_100_200", on standardise
    final allProductTags = {...productTags, ...productCategories}
        .map((t) => t.toLowerCase().replaceAll('-', '_'))
        .toSet();

    AppLogger.debug('🔍 Scoring produit "${product['name']}" (mode: $filteringMode): ${allProductTags.length} tags', 'Debug');

    // Modes de filtrage:
    // - HOME: TRÈS STRICT (genre, âge, catégories) - cadeaux pour SOI
    // - PERSON: EXCLUSION STRICTE sur genre/âge, SOUPLE sur catégories/budget - cadeaux pour QUELQU'UN
    // - DISCOVERY: TRÈS SOUPLE partout - exploration maximale
    final isDiscoveryMode = filteringMode == "discovery";
    final isHomeMode = filteringMode == "home";
    final isPersonMode = filteringMode == "person";

    // ========================================================================
    // RÈGLES STRICTES - EXCLUSION OU PÉNALITÉ SELON MODE
    // ========================================================================

    // 🔒 1. GENRE (EXCLUSION STRICTE 0% FUITE)
    final userGenderTags = searchTags.where((t) => t.startsWith('gender_')).toList();
    if (userGenderTags.isNotEmpty) {
      final userGender = userGenderTags.first.toLowerCase();
      final productGenderTags = allProductTags.where((t) => t.toLowerCase().startsWith('gender_')).map((t) => t.toLowerCase()).toList();
      final productName = (product['name'] ?? '').toString().toLowerCase();
      final productBrand = (product['brand'] ?? '').toString().toLowerCase();
      final subcat = (product['subcategory'] ?? '').toString().toLowerCase();

      final strongFeminineKeywords = [
        'robe', 'jupe', 'escarpin', 'talons', 'lingerie', 'soutien-gorge', 'culotte', 'dentelle',
        'maquillage', 'rouge à lèvres', 'mascara', 'blush', 'palette', 'vernis', 'dyson airwrap',
        'airwrap', 'lisseur', 'sac à main', 'sac cabas', 'pochette soirée', 'polène', 'polene',
        'jacquemus', 'chiquito', 'bambino', 'miss dior', 'coco mademoiselle', 'gabrielle chanel',
        'black opium', 'la vie est belle', 'boucles d\'oreilles'
      ];

      final strongMasculineKeywords = [
        'cravate', 'nœud papillon', 'tondeuse barbe', 'rasoir barbe', 'barbe', 'aftershave',
        'costume homme', 'caleçon', 'boxer homme', 'sauvage dior', 'bleu de chanel', 'terre d\'hermès'
      ];

      final isStrongFeminine = strongFeminineKeywords.any((kw) => productName.contains(kw) || productBrand.contains(kw)) ||
          subcat == 'subcat_vetements_femme' || subcat == 'subcat_maquillage' || subcat == 'subcat_lingerie_nuit';

      final isStrongMasculine = strongMasculineKeywords.any((kw) => productName.contains(kw)) ||
          subcat == 'subcat_vetements_homme' || subcat == 'subcat_rasage_barbe';

      // 🛑 VÉRIFICATION DE FUITE CROISÉE : EXCLUSION ABSOLUE 0% FUITE
      if (userGender == 'gender_homme' && (isStrongFeminine || productGenderTags.contains('gender_femme'))) {
        AppLogger.debug('❌ EXCLUSION STRICTE PRODUIT FÉMININ POUR HOMME: "$productName"', 'Matching');
        return -10000.0;
      }

      if (userGender == 'gender_femme' && (isStrongMasculine || productGenderTags.contains('gender_homme'))) {
        AppLogger.debug('❌ EXCLUSION STRICTE PRODUIT MASCULIN POUR FEMME: "$productName"', 'Matching');
        return -10000.0;
      }

      if (productGenderTags.contains(userGender)) {
        AppLogger.debug('✅ GENRE MATCH: $userGender +100pts', 'Matching');
        score += 100.0;
      } else if (productGenderTags.contains('gender_mixte') || productGenderTags.isEmpty) {
        AppLogger.debug('✅ Produit mixte accepté: +70pts', 'Matching');
        score += 70.0;
      }
    } else {
      AppLogger.debug('📝 Utilisateur sans préférence genre: +50 pour tous les produits', 'Debug');
      score += 50.0;
    }

    // 🔒 2. ÂGE (SCORING UNIQUEMENT - JAMAIS d'exclusion)
    final age = userTags['age'] ?? userTags['recipientAge'];
    if (age != null) {
      final ageInt = int.tryParse(age.toString()) ?? 0;
      if (ageInt > 0) {
        // 🔒 1.B PROTECTION MINEURS (ZÉRO TOLÉRANCE ALCOOL)
        if (ageInt < 18 && allProductTags.contains('cat_alcool')) {
          AppLogger.debug('❌ EXCLUSION MINEUR: Produit alcoolisé interdit pour $ageInt ans', 'Debug');
          return -10000.0;
        }

        // Déterminer la tranche d'âge de l'utilisateur
        String userAgeTag;
        if (ageInt < 13) {
          userAgeTag = 'age_enfant';
        } else if (ageInt < 25) {
          userAgeTag = 'age_ado'; // FIX: était 'age_jeune' (tag invalide)
        } else if (ageInt < 55) {
          userAgeTag = 'age_adulte';
        } else {
          userAgeTag = 'age_senior';
        }

        // Vérifier si le produit a des tags d'âge
        final productAgeTags = allProductTags.where((t) => t.startsWith('age_')).toList();

        if (productAgeTags.isNotEmpty) {
          if (productAgeTags.contains(userAgeTag)) {
            // Match exact de la tranche d'âge = BONUS
            AppLogger.debug('✅ ÂGE MATCH: $userAgeTag ($ageInt ans) = +50 points', 'Debug');
            score += 50.0;
          } else {
            // Âge ne correspond pas = petite pénalité (PAS d'exclusion)
            AppLogger.debug('⚠️ ÂGE différent: $userAgeTag ≠ ${productAgeTags.join(", ")} => -15 points', 'Debug');
            score -= 15.0;
          }
        } else {
          // Produit sans tag d'âge => neutre
          AppLogger.debug('📝 Produit sans tag âge (universel): +10', 'Debug');
          score += 10.0;
        }
      }
    }

    // 🔒 3. CATÉGORIE PRINCIPALE (SCORING uniquement, PLUS JAMAIS d'exclusion)
    final userCategoryTags = searchTags.where((t) => t.startsWith('cat_')).toList();
    if (userCategoryTags.isNotEmpty) {
      final productCategoryTags = allProductTags.where((t) => t.startsWith('cat_')).toList();

      if (productCategoryTags.isEmpty) {
        AppLogger.debug('⚠️ Produit sans catégorie: +20', 'Debug');
        score += 20.0;
      } else {
        bool categoryMatched = false;
        
        for (final userCategory in userCategoryTags) {
          if (productCategoryTags.contains(userCategory.toLowerCase())) {
            categoryMatched = true;
            AppLogger.debug('✅ CATÉGORIE MATCH: $userCategory = +80 points', 'Debug');
            break; // On donne les points une seule fois si au moins une catégorie matche
          }
        }

        if (categoryMatched) {
            score += 80.0;
        } else {
            // Catégorie ne correspond PAS - PÉNALITÉ mais PAS d'exclusion
            if (isHomeMode) {
              AppLogger.debug('⚠️ CATÉGORIE NE CORRESPOND PAS (home) => Pénalité -45', 'Debug');
              score -= 45.0;
            } else if (isPersonMode) {
              AppLogger.debug('⚠️ CATÉGORIE NE CORRESPOND PAS (person) => Pénalité -30', 'Debug');
              score -= 30.0;
            } else {
              AppLogger.debug('⚠️ CATÉGORIE NE CORRESPOND PAS (discovery) => Pénalité -10', 'Debug');
              score -= 10.0;
            }
        }
      }
    }

    // 🔒 4. BUDGET (SCORING avec élasticité budgétaire)
    final userBudgetTags = searchTags.where((t) => t.startsWith('budget_')).toList();
    if (userBudgetTags.isNotEmpty) {
      final userBudget = userBudgetTags.first;
      String productBudget = '';

      final productBudgetTags = allProductTags.where((t) => t.startsWith('budget_')).toList();
      if (productBudgetTags.isEmpty) {
        final price = product['price'];
        final priceInt = price is int ? price : (price is double ? price.toInt() : 0);
        productBudget = TagsDefinitions.getBudgetTagFromPrice(priceInt);
      } else {
        productBudget = productBudgetTags.first;
      }

      if (productBudget.toLowerCase() == userBudget.toLowerCase()) {
        AppLogger.debug('✅ BUDGET MATCH: $userBudget = +60 points', 'Debug');
        score += 60.0;
      } else {
        // Calculer l'élasticité (distance entre les budgets)
        int getBudgetIndex(String b) {
          if (b.contains('0_50')) return 0;
          if (b.contains('50_100')) return 1;
          if (b.contains('100_200')) return 2;
          if (b.contains('200')) return 3;
          return -1;
        }

        final userIdx = getBudgetIndex(userBudget);
        final prodIdx = getBudgetIndex(productBudget);

        if (userIdx != -1 && prodIdx != -1) {
          final diff = (userIdx - prodIdx).abs();
          if (diff == 1) {
            AppLogger.debug('⚠️ BUDGET ÉLASTIQUE (diff 1): $productBudget ≠ $userBudget => Pénalité -25', 'Debug');
            score -= 25.0;
          } else if (diff == 2) {
            AppLogger.debug('⚠️ BUDGET ÉLASTIQUE (diff 2): $productBudget ≠ $userBudget => Pénalité -60', 'Debug');
            score -= 60.0;
          } else if (diff >= 3) {
            AppLogger.debug('❌ BUDGET HORS SCÉNARIO (diff 3+): $productBudget ≠ $userBudget => EXCLUSION', 'Debug');
            return -10000.0;
          }
        } else {
            // Fallback
            score -= 20.0;
        }
      }
    }

    // ========================================================================
    // RÈGLES SOUPLES - SCORING PARTIEL (pas d'exclusion)
    // ========================================================================

    // 💫 4. STYLES (SOUPLE - max 40 points)
    final userStyleTags = searchTags.where((t) => t.startsWith('style_')).toList();
    if (userStyleTags.isNotEmpty) {
      final productStyleTags = allProductTags.where((t) => t.startsWith('style_')).toList();
      int styleMatches = 0;

      for (final userStyle in userStyleTags) {
        if (productStyleTags.contains(userStyle.toLowerCase())) {
          styleMatches++;
          AppLogger.debug('✨ Style match: $userStyle', 'Debug');
        }
      }

      if (styleMatches > 0) {
        final styleScore = styleMatches * 20.0; // 20 points par style matché
        score += styleScore.clamp(0, 40); // Max 40 points
        AppLogger.debug('🎨 STYLES: $styleMatches matches = +${styleScore.clamp(0, 40)} points', 'Debug');
      }
    }

    // 💫 5. PERSONNALITÉS (SOUPLE - max 30 points)
    final userPersonalityTags = searchTags.where((t) => t.startsWith('perso_')).toList();
    if (userPersonalityTags.isNotEmpty) {
      final productPersonalityTags = allProductTags.where((t) => t.startsWith('perso_')).toList();
      int personalityMatches = 0;

      for (final userPersonality in userPersonalityTags) {
        if (productPersonalityTags.contains(userPersonality.toLowerCase())) {
          personalityMatches++;
          AppLogger.debug('✨ Personnalité match: $userPersonality', 'Debug');
        }
      }

      if (personalityMatches > 0) {
        final personalityScore = personalityMatches * 15.0; // 15 points par personnalité matchée
        score += personalityScore.clamp(0, 30); // Max 30 points
        AppLogger.debug('😊 PERSONNALITÉS: $personalityMatches matches = +${personalityScore.clamp(0, 30)} points', 'Debug');
      }
    }

    // 💫 6. PASSIONS (SOUPLE - max 50 points - le plus important des souples)
    final userPassionTags = searchTags.where((t) => t.startsWith('passion_')).toList();
    if (userPassionTags.isNotEmpty) {
      final productPassionTags = allProductTags.where((t) => t.startsWith('passion_')).toList();
      int passionMatches = 0;

      for (final userPassion in userPassionTags) {
        if (productPassionTags.contains(userPassion.toLowerCase())) {
          passionMatches++;
          AppLogger.debug('✨ Passion match: $userPassion', 'Debug');
        }
      }

      if (passionMatches > 0) {
        final passionScore = passionMatches * 25.0; // 25 points par passion matchée
        score += passionScore.clamp(0, 50); // Max 50 points
        AppLogger.debug('❤️ PASSIONS: $passionMatches matches = +${passionScore.clamp(0, 50)} points', 'Debug');
      }
    }

    // 💫 7. TYPES DE CADEAUX (SOUPLE - max 70 points)
    final userTypeTags = searchTags.where((t) => t.startsWith('type_')).toList();
    if (userTypeTags.isNotEmpty) {
      final productTypeTags = allProductTags.where((t) => t.startsWith('type_')).toList();
      int typeMatches = 0;

      for (final userType in userTypeTags) {
        if (productTypeTags.contains(userType.toLowerCase())) {
          typeMatches++;
          AppLogger.debug('✨ Type cadeau match: $userType', 'Debug');
        }
      }

      if (typeMatches > 0) {
        final typeScore = typeMatches * 35.0; // 35 points par type matché
        score += typeScore.clamp(0, 70); // Max 70 points
        AppLogger.debug('🎁 TYPES: $typeMatches matches = +${typeScore.clamp(0, 70)} points', 'Debug');
      }
    }

    // 💫 7bis. OCCASION (SOUPLE - max 45 points)
    // Les tags occasion_* existent depuis toujours sur les produits importés
    // mais n'étaient jamais lus ici — un cadeau taggé "Noël" ne remontait pas
    // plus haut qu'un autre pendant la recherche "Noël".
    final userOccasionTags = searchTags.where((t) => t.startsWith('occasion_')).toList();
    if (userOccasionTags.isNotEmpty) {
      final productOccasionTags = allProductTags.where((t) => t.startsWith('occasion_')).toList();
      if (productOccasionTags.any((t) => userOccasionTags.contains(t))) {
        score += 45.0;
        AppLogger.debug('🎉 OCCASION MATCH: +45 points', 'Debug');
      }
    }

    // 💫 7ter. SAISON (SOUPLE - max 15 points, jamais d'exclusion)
    final userSaisonTags = searchTags.where((t) => t.startsWith('saison_')).toList();
    if (userSaisonTags.isNotEmpty) {
      final productSaisonTags = allProductTags.where((t) => t.startsWith('saison_')).toList();
      if (productSaisonTags.any((t) => userSaisonTags.contains(t))) {
        score += 15.0;
        AppLogger.debug('🍂 SAISON MATCH: +15 points', 'Debug');
      }
    }

    // ========================================================================
    // 8️⃣ LOCATION (Boost activités locales) - NOUVEAU
    // ========================================================================
    final location = userTags['location'];
    if (location != null && location.toString().isNotEmpty) {
      final locStr = location.toString().toLowerCase();
      
      // Est-ce une activité ?
      final isActivity = allProductTags.any((t) => 
        t == 'type_voyage_aventure' || 
        t == 'type_bien_etre' || 
        t == 'type_gastronomie' || 
        t == 'type_culture'
      );
      
      if (isActivity) {
        // Obtenir la description ou le nom ou un tag location du produit
        final productName = (product['name'] ?? '').toString().toLowerCase();
        final productDesc = (product['description'] ?? '').toString().toLowerCase();
        
        // On cherche le nom de la ville ou département (ex: "Paris", "Île-de-France")
        final parts = locStr.replaceAll(RegExp(r'[()]'), ' ').split(' ').where((p) => p.length > 3).toList();
        for (final part in parts) {
          if (productName.contains(part) || productDesc.contains(part) || allProductTags.contains(part)) {
             score += 150.0; // GROS BONUS pour une activité locale pertinente
             AppLogger.debug('📍 ACTIVITÉ LOCALE détectée ($part) = +150 points', 'Debug');
             break;
          }
        }
      }
    }

    // ========================================================================
    // 9️⃣ WISHLIST USERNAME MATCH - NOUVEAU
    // ========================================================================
    final isWishlisted = product['isFromRecipientWishlist'] == true;
    if (isWishlisted) {
      score += 500.0; // BONUS MASSIF ABSOLU pour les produits issus de leur vraie wishlist
      AppLogger.debug('🎯 WISHLIST MATCH ABSOLU = +500 points', 'Debug');
    }

    // ========================================================================
    // BONUS SECONDAIRES
    // ========================================================================

    // 📈 Popularité & Tendance Flagship (bonus dynamique jusqu'à 45 points pour les produits stars/tendances)
    final popularity = product['popularity'] as int? ?? 85;
    if (popularity > 70) {
      final popularityScore = ((popularity - 70) * 1.5).clamp(0.0, 45.0);
      score += popularityScore;
      AppLogger.debug('📈 Popularité & Tendance: $popularity = +${popularityScore.toStringAsFixed(1)} points', 'Debug');
    }

    // 🎲 Variation aléatoire légère (0-5 points pour éviter ordre identique)
    final randomBonus = Random().nextDouble() * 5.0;
    score += randomBonus;

    AppLogger.debug('🏁 SCORE FINAL: ${score.toStringAsFixed(1)} points', 'Debug');
    AppLogger.debug('', 'Debug');

    return score;
  }

  /// NOUVEAU: Récupère les favoris/wishlists d'un utilisateur par son username
  static Future<List<Map<String, dynamic>>> _fetchWishlistByUsername(String username) async {
    try {
      if (username.isEmpty) return [];
      
      // Nettoyer le @ si présent
      final cleanUsername = username.startsWith('@') ? username.substring(1) : username;
      
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      // Chercher l'utilisateur par username (requiert que le champ username existe dans 'users')
      final usersSnapshot = await firestore
          .collection('users')
          .where('username', isEqualTo: cleanUsername)
          .limit(1)
          .get();
          
      if (usersSnapshot.docs.isEmpty) {
        // Fallback: chercher par email au cas où (ou par displayName)
         final emailSnapshot = await firestore
          .collection('users')
          .where('displayName', isEqualTo: cleanUsername)
          .limit(1)
          .get();
          
         if (emailSnapshot.docs.isEmpty) return [];
         
         // On remplace le résultat si trouvé par displayName
         usersSnapshot.docs.addAll(emailSnapshot.docs);
      }
      
      final targetUid = usersSnapshot.docs.first.id;
      AppLogger.debug('🔍 Utilisateur trouvé pour username $cleanUsername: UID = $targetUid', 'Matching');
      
      // Récupérer la collection 'favorites'
      final favSnapshot = await firestore
          .collection('users')
          .doc(targetUid)
          .collection('favorites')
          .get();
          
      final products = favSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['isFromRecipientWishlist'] = true; // Flag très important
        return data;
      }).toList();
      
      AppLogger.success('🎁 ${products.length} produits trouvés dans la wishlist de $cleanUsername', 'Matching');
      return products;
      
    } catch (e) {
      AppLogger.error('Erreur lors de la récupération de la wishlist pour $username', 'Matching', e);
      return [];
    }
  }

  /// ⛔ FONCTION SUPPRIMÉE - Plus de fallback assets
  /// Tous les produits DOIVENT venir de Firebase uniquement

  /// Génère des sections thématiques pour la page d'accueil
  /// Retourne une liste de sections avec titre et produits
  static Future<List<Map<String, dynamic>>> getHomeSections({
    required Map<String, dynamic> userTags,
  }) async {
    final sections = <Map<String, dynamic>>[];

    // Extraire sexe et âge de l'utilisateur
    final gender = userTags['gender'] ?? userTags['recipientGender'];
    final age = userTags['age'] ?? userTags['recipientAge'];
    final ageInt = age is int ? age : int.tryParse(age.toString()) ?? 25;

    String genderLabel = 'Unisexe';
    String ageLabel = '';

    if (gender != null) {
      final genderStr = gender.toString().toLowerCase();
      if (genderStr.contains('homme') || genderStr.contains('male')) {
        genderLabel = 'Homme';
      } else if (genderStr.contains('femme') || genderStr.contains('female')) {
        genderLabel = 'Femme';
      }
    }

    if (ageInt < 18) {
      ageLabel = 'Ado';
    } else if (ageInt < 30) {
      ageLabel = '18–25';
    } else if (ageInt < 50) {
      ageLabel = '30–50';
    } else {
      ageLabel = '50+';
    }

    // Section 1: Tendances personnalisées (60% relevance)
    final trendingPersonalizedProducts = await getPersonalizedProducts(
      userTags: userTags,
      count: 10,
    );
    sections.add({
      'title': '🔥 Tendance $genderLabel $ageLabel',
      'subtitle': 'Les must-have du moment pour toi',
      'products': trendingPersonalizedProducts,
      'filter': {'gender': genderLabel, 'age': ageLabel},
    });

    // Section 2: Top Tech (catégorie spécifique)
    final techProducts = await getPersonalizedProducts(
      userTags: {...userTags},
      count: 10,
      category: 'tech',
    );
    sections.add({
      'title': '📱 Top Tech $ageLabel',
      'subtitle': 'Les gadgets qui font la différence',
      'products': techProducts,
      'filter': {'category': 'tech', 'age': ageLabel},
    });

    // Section 3: Beauté/Mode selon le sexe
    if (genderLabel == 'Femme') {
      final beautyProducts = await getPersonalizedProducts(
        userTags: {...userTags},
        count: 10,
        category: 'beauty',
      );
      sections.add({
        'title': '💄 Beauté qui cartonne',
        'subtitle': 'Les produits beauté tendance',
        'products': beautyProducts,
        'filter': {'category': 'beauty'},
      });
    } else if (genderLabel == 'Homme') {
      final fashionProducts = await getPersonalizedProducts(
        userTags: {...userTags},
        count: 10,
        category: 'fashion',
      );
      sections.add({
        'title': '👔 Mode Homme Tendance',
        'subtitle': 'Le style qui fait mouche',
        'products': fashionProducts,
        'filter': {'category': 'fashion'},
      });
    }

    // Section 4: Sport du moment (si pertinent)
    final sportProducts = await getPersonalizedProducts(
      userTags: {...userTags},
      count: 10,
      category: 'sport',
    );
    if (sportProducts.length >= 5) {
      sections.add({
        'title': '⚽ Sport du moment',
        'subtitle': 'Pour rester actif',
        'products': sportProducts,
        'filter': {'category': 'sport'},
      });
    }

    // Section 5: Maison & Déco
    final homeProducts = await getPersonalizedProducts(
      userTags: {...userTags},
      count: 10,
      category: 'home',
    );
    if (homeProducts.length >= 5) {
      sections.add({
        'title': '🏠 Maison Cosy',
        'subtitle': 'Pour un intérieur stylé',
        'products': homeProducts,
        'filter': {'category': 'home'},
      });
    }

    // Section 6: Coups de cœur budget (prix < 50€)
    final budgetTags = {...userTags, 'budget': 'Moins de 50€'};
    final budgetProducts = await getPersonalizedProducts(
      userTags: budgetTags,
      count: 10,
    );
    sections.add({
      'title': '💝 Petits prix, grandes idées',
      'subtitle': 'Moins de 50€',
      'products': budgetProducts,
      'filter': {'maxPrice': 50},
    });

    AppLogger.success('${sections.length} sections générées pour l\'accueil', 'Matching');
    return sections;
  }

  /// Normalise un tag pour le matching (gère pluriels, synonymes, accents)
  /// Ex: "sports" → "sport", "fitness" → "sport", "beauté" → "beaute"
  static String _normalizeTag(String tag) {
    var normalized = tag
        .toLowerCase()
        .trim()
        // Retirer les accents
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ýÿ]'), 'y')
        .replaceAll('ç', 'c')
        .replaceAll('ñ', 'n');

    // Dictionnaire de synonymes et mapping pluriel → singulier
    final synonymMap = {
      // Sport & Fitness
      'sports': 'sport',
      'fitness': 'sport',
      'musculation': 'sport',
      'gym': 'sport',
      'running': 'sport',
      'yoga': 'sport',

      // Tech
      'technologie': 'tech',
      'high-tech': 'tech',
      'hightech': 'tech',
      'gadgets': 'tech',
      'gadget': 'tech',

      // Mode
      'mode': 'fashion',
      'vetements': 'fashion',
      'vetement': 'fashion',
      'style': 'fashion',

      // Beauté
      'beaute': 'beauty',
      'cosmetique': 'beauty',
      'cosmetiques': 'beauty',
      'maquillage': 'beauty',
      'soin': 'beauty',
      'soins': 'beauty',

      // Maison
      'maison': 'home',
      'deco': 'home',
      'decoration': 'home',
      'interieur': 'home',

      // Gaming
      'jeux': 'gaming',
      'jeu': 'gaming',
      'gaming': 'gaming',
      'gamer': 'gaming',
      'console': 'gaming',
      'consoles': 'gaming',

      // Lecture
      'lecture': 'book',
      'livres': 'book',
      'livre': 'book',
      'reading': 'book',

      // Musique
      'musique': 'music',
      'audio': 'music',
      'son': 'music',

      // Cuisine
      'cuisine': 'cooking',
      'culinaire': 'cooking',
      'gastronomie': 'cooking',

      // Art
      'art': 'art',
      'artistique': 'art',
      'creation': 'art',
      'creatif': 'art',

      // Voyage
      'voyage': 'travel',
      'voyages': 'travel',
      'aventure': 'travel',
      'aventures': 'travel',
    };

    return synonymMap[normalized] ?? normalized;
  }

  /// Normalise un nom de produit pour détecter les doublons visuels
  /// Retire les espaces, ponctuation, accents, convertit en minuscules
  static String _normalizeProductName(String name) {
    return name
        .toLowerCase()
        .trim()
        // Retirer les accents
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ýÿ]'), 'y')
        .replaceAll('ç', 'c')
        .replaceAll('ñ', 'n')
        // Retirer les caractères spéciaux et espaces multiples
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// ⛔ FONCTION SUPPRIMÉE - Plus de produits hardcodés en fallback
  /// Si Firebase est vide, l'app doit crasher pour qu'on identifie le problème
  /// Tous les produits DOIVENT venir de Firebase (collection 'gifts' ou 'products')
  ///
  /// ANCIENNE FONCTION _getFallbackProducts() SUPPRIMÉE
  /// Contenait 50 produits hardcodés (tech, mode, beauté, sport, maison)
  /// Ces produits génériques masquaient le vrai problème: Firebase vide
  ///
  /// DÉSORMAIS:
  /// - Firebase vide → Exception lancée
  /// - L'utilisateur voit immédiatement qu'il y a un problème
  /// - On peut identifier pourquoi le scraping n'a pas fonctionné
}
