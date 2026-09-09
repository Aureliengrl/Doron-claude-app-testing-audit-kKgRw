import '/utils/app_logger.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import '/components/premium_3d_icon.dart';
import '/utils/iconly_compat.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';
import '/services/product_matching_service.dart';
import '/services/product_search_service.dart';
import '/utils/app_tr.dart';
import '/services/firebase_data_service.dart';
import '/services/product_url_service.dart';
import '/services/claude_api_service.dart';
import '/services/amazon_affiliation_service.dart';
import '/components/bounce_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'onboarding_gifts_result_model.dart';
export 'onboarding_gifts_result_model.dart';

class OnboardingGiftsResultWidget extends StatefulWidget {
  const OnboardingGiftsResultWidget({super.key});

  static String routeName = 'OnboardingGiftsResult';
  static String routePath = '/onboarding-gifts-result';

  @override
  State<OnboardingGiftsResultWidget> createState() =>
      _OnboardingGiftsResultWidgetState();
}

class _OnboardingGiftsResultWidgetState
    extends State<OnboardingGiftsResultWidget> {
  late OnboardingGiftsResultModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final Color violetColor = const Color(0xFF8A2BE2);
  late ConfettiController _confettiController;

  // Onglet « Recherche » (fin de quiz)
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isSearchingProducts = false;

  @override
  void initState() {
    super.initState();
    _model = OnboardingGiftsResultModel();

    // Initialiser le confetti controller
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    // Parse le personId depuis les query parameters (sera fait dans didChangeDependencies)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _parseQueryParameters();
      }
    });
  }

  String? _returnTo; // Page de retour (ex: /search-page)
  String _giftCategoryFilter = 'all'; // 'all', 'physical', 'experience'


  /// Parse les paramètres de query de l'URL et les données extra
  void _parseQueryParameters() {
    final goRouterState = GoRouterState.of(context);
    final extraData = goRouterState.extra;
    final personId = goRouterState.uri.queryParameters['personId'] ??
        goRouterState.uri.queryParameters['profileId'] ??
        goRouterState.uri.queryParameters['editProfileId'] ??
        (extraData is Map ? (extraData['personId'] ?? extraData['id'])?.toString() : null);
    _returnTo = goRouterState.uri.queryParameters['returnTo'];

    // ?? NOUVEAU: Récupérer les données passées via extra (assistant vocal)
    AppLogger.debug('?? Extra data détecté: ${extraData != null ? "OUI" : "NON"}', 'Debug');

    if (extraData != null && extraData is Map<String, dynamic>) {
      AppLogger.debug('? Profil vocal reçu via extra: ${extraData.keys.join(", ")}', 'Debug');
      _model.setVoiceProfile(extraData);
    }

    if (personId != null) {
      _model.setPersonId(personId);
      AppLogger.debug('? PersonId détecté: $personId', 'Debug');
    }

    if (_returnTo != null) {
      AppLogger.debug('? ReturnTo détecté: $_returnTo', 'Debug');
    }

    _loadGifts();
  }

  /// Charge les cadeaux personnalisés basés sur l'onboarding
  Future<void> _loadGifts({bool forceRefresh = false}) async {
    if (mounted) {
      setState(() {
        _model.setLoading(true);
        _model.clearError();
      });
    }

    try {
      Map<String, dynamic>? profileForGeneration;

      // ?? PRIORITÉ 1: Si profil vocal existe (assistant vocal), l'utiliser
      if (_model.voiceProfile != null) {
        AppLogger.debug('?? Utilisation du profil vocal pour génération', 'Debug');
        profileForGeneration = _model.voiceProfile;
        AppLogger.debug('? Profil vocal: ${profileForGeneration!.keys.join(", ")}', 'Debug');
      }
      // ?? PRIORITÉ 2: Si un personId est spécifié, charger les tags de la personne
      else if (_model.personId != null) {
        AppLogger.debug('?? Chargement direct par ID: ${_model.personId}', 'Debug');

        final person = await FirebaseDataService.loadPersonById(_model.personId!);

        if (person == null) {
          AppLogger.debug('? Person not found! Looking for ID: ${_model.personId}', 'Debug');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Personne non trouvée. Veuillez réessayer.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) context.pop();
            });
          }
          return;
        }

        final personTags = person['tags'] as Map<String, dynamic>?;
        if (personTags == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profil incomplet. Veuillez compléter l\'onboarding.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) context.pop();
            });
          }
          return;
        }

        _model.setPersonTags(personTags);
        profileForGeneration = personTags;
        AppLogger.debug('? Tags de personne chargés: ${personTags.keys.join(", ")}', 'Debug');
      }
      // ?? PRIORITÉ 3: Ancienne méthode (compatibilité)
      else {
        AppLogger.debug('?? Chargement du profil onboarding (mode compatibilité)', 'Debug');
        final userProfile = await FirebaseDataService.loadOnboardingAnswers();
        _model.setUserProfile(userProfile);
        profileForGeneration = userProfile;
      }

      if (profileForGeneration == null || profileForGeneration.isEmpty) {
        AppLogger.debug('?? Aucun profil trouvé pour la génération - utilisation du mode découverte', 'Debug');
        profileForGeneration = {};
      }

      // ---
      // ?? NOUVELLE LOGIQUE : Charger les wishlists Doron si handle connu
      // ---
      List<Map<String, dynamic>> wishlistGifts = [];
      final personHandle = (profileForGeneration['username'] ?? profileForGeneration['personIdentifier'] ?? '').toString().replaceAll('@', '').trim().toLowerCase();

      if (personHandle.isNotEmpty) {
        AppLogger.debug('?? Recherche compte Doron pour handle: @$personHandle', 'Debug');
        try {
          // Trouver l'UID par le handle
          final userQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('handle_lower', isEqualTo: personHandle)
              .limit(1)
              .get();

          if (userQuery.docs.isNotEmpty) {
            final targetUid = userQuery.docs.first.id;
            AppLogger.debug('? Compte Doron trouvé: $targetUid', 'Debug');

            // Charger ses wishlists
            final wishlistsSnap = await FirebaseFirestore.instance
                .collection('users')
                .doc(targetUid)
                .collection('wishlists')
                .get();

            for (final wDoc in wishlistsSnap.docs) {
              // Charger les produits de chaque wishlist
              final productsSnap = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(targetUid)
                  .collection('wishlists')
                  .doc(wDoc.id)
                  .collection('products')
                  .limit(30)
                  .get();

              for (final p in productsSnap.docs) {
                final data = p.data();
                final imageUrl = data['imageUrl'] ?? data['image'] ?? data['product_photo'] ?? data['photo'] ?? '';
                if (imageUrl.toString().startsWith('http')) {
                  wishlistGifts.add({
                    'id': p.id,
                    'name': data['title'] ?? data['name'] ?? data['product_title'] ?? 'Cadeau wishlist',
                    'brand': data['brand'] ?? data['platform'] ?? data['source'] ?? '@$personHandle',
                    'price': data['price'] ?? data['product_price'] ?? 0,
                    'image': imageUrl,
                    'url': data['url'] ?? data['productUrl'] ?? data['product_url'] ?? '',
                    'categories': data['categories'] ?? [],
                    'match': 95, // Score élevé car vient de sa vraie wishlist
                    'fromWishlist': true, // Badge spécial
                    'wishlistOwner': '@$personHandle',
                  });
                }
              }
            }
            AppLogger.debug('? ${wishlistGifts.length} produits récupérés depuis les wishlists Doron de @$personHandle', 'Debug');
          } else {
            AppLogger.debug('?? Aucun compte Doron trouvé pour @$personHandle  fallback classique', 'Debug');
          }
        } catch (e) {
          AppLogger.debug('?? Erreur récupération wishlists Doron (non bloquant): $e', 'Debug');
        }
      }
      // ---

      // Charger les IDs des produits déjà vus pour refresh intelligent
      final prefs = await SharedPreferences.getInstance();
      final seenProductIds = prefs.getStringList('seen_gift_product_ids')
          ?.map((s) => int.tryParse(s) ?? 0).toList() ?? [];

      // ?? Générer les cadeaux via ProductMatchingService
      final rawGifts = await ProductMatchingService.getPersonalizedProducts(
        userTags: profileForGeneration ?? {},
        count: 50,
        excludeProductIds: forceRefresh ? seenProductIds : null,
        filteringMode: "person",
      );

      final aiGifts = rawGifts.map((product) {
        String imageUrl = '';
        for (final key in ['image', 'imageUrl', 'photo', 'productPhoto', 'product_photo', 'img', 'thumbnail']) {
          if (product[key] != null && product[key].toString().isNotEmpty) {
            imageUrl = product[key].toString();
            break;
          }
        }
        final matchScore = product['_matchScore'];
        final matchScoreInt = matchScore is int
            ? matchScore
            : (matchScore is double ? matchScore.toInt() : 0);
        return {
          'id': product['id'],
          'name': product['name'] ?? 'Produit',
          'brand': product['brand'] ?? 'Amazon',
          'price': product['price'] ?? 0,
          'image': imageUrl,
          // FIX-URL: ProductUrlService cherche buyLinks[0].url en priorité (vraie URL directe)
          'url': ProductUrlService.generateProductUrl(product),
          'buyLinks': product['buyLinks'], // conserver pour le modal comparateur
          'categories': product['categories'] ?? [],
          'match': matchScoreInt.clamp(0, 100),
          'fromWishlist': false,
        };
      })
      .where((product) {
        final hasImage = product['image'] != null &&
                         product['image'].toString().isNotEmpty &&
                         product['image'].toString().startsWith('http');
        if (!hasImage) AppLogger.debug('?? Produit "${product['name']}" filtré: pas d\'image valide', 'Debug');
        return hasImage;
      })
      .toList();

      // ?? Fusionner : wishlists Doron en PREMIER, puis IA
      var gifts = [...wishlistGifts, ...aiGifts];

      if (gifts.isEmpty) {
        gifts = [
          {
            'id': 'fallback_1',
            'name': 'Coffret Spa Luxe Premium',
            'description': 'Un moment de détente incomparable.',
            'price': 89,
            'image': 'https://images.unsplash.com/photo-1596755389378-c31d21fd1273?w=600&q=80',
            'brand': 'Sephora',
            'match': 95,
            'url': 'https://www.sephora.fr',
            'fromWishlist': false,
          },
          {
            'id': 'fallback_2',
            'name': 'Livre de Recettes Gourmet',
            'description': 'Plus de 200 recettes raffinées.',
            'price': 35,
            'image': 'https://images.unsplash.com/photo-1543362906-acfc16c67564?w=600&q=80',
            'brand': 'Fnac',
            'match': 92,
            'url': 'https://www.fnac.com',
            'fromWishlist': false,
          },
        ];
      }

      // Mettre à jour le cache des produits vus
      if (forceRefresh) {
        final newSeenIds = seenProductIds.map((id) => id.toString()).toList();
        for (var gift in aiGifts) {
          final id = gift['id'];
          if (id != null) {
            final idStr = id.toString();
            if (!newSeenIds.contains(idStr)) newSeenIds.add(idStr);
          }
        }
        if (newSeenIds.length > 500) newSeenIds.removeRange(0, newSeenIds.length - 500);
        await prefs.setStringList('seen_gift_product_ids', newSeenIds);
      }

      AppLogger.debug('?? gifts total: {gifts.length}', 'Debug');

      if (mounted) {
        setState(() {
          _model.setGifts(gifts);
          // FIX P2-C: clear s\u00e9lection pour \u00e9viter les saves non voulus
          _model.selectedGiftIds.clear();
          _model.setLoading(false);
          _model.clearError();
        });
      }

      // ?? AUTO-SAUVEGARDE si premi\u00e8re g\u00e9n\u00e9ration
      if (_model.personId != null && gifts.isNotEmpty) {
        try {
          final people = await FirebaseDataService.loadPeople();
          final person = people.firstWhere(
            (p) => p['id'] == _model.personId,
            orElse: () => {},
          );
          final isPendingFirstGen = person['meta']?['isPendingFirstGen'] == true;
          if (isPendingFirstGen && !forceRefresh) {
            AppLogger.debug('?? Auto-sauvegarde: première génération détectée', 'Debug');
            final listName = 'Liste ${DateTime.now().day}/${DateTime.now().month}';
            final listId = await FirebaseDataService.saveGiftListForPerson(
              personId: _model.personId!,
              gifts: gifts,
              listName: listName,
            );
            AppLogger.debug('? ${gifts.length} cadeaux auto-sauvegardés (liste: $listId)', 'Debug');
            await FirebaseDataService.updatePersonPendingFlag(_model.personId!, false);
            await FirebaseDataService.setCurrentPersonContext(_model.personId!);
          }
        } catch (e) {
          AppLogger.debug('?? Erreur auto-sauvegarde (non-bloquant): $e', 'Debug');
        }
      }
    } catch (e) {
      AppLogger.debug('? Erreur chargement cadeaux: $e', 'Debug');
      String errorMessage = 'Erreur de génération des cadeaux';
      String errorDetails = e.toString();
      if (errorDetails.contains('SocketException') || errorDetails.contains('Network')) {
        errorMessage = '?? Pas de connexion internet';
        errorDetails = 'Vérifie ta connexion internet et réessaye.';
      } else if (errorDetails.contains('firebase')) {
        errorMessage = '?? Erreur Firebase';
        errorDetails = 'Impossible de charger les produits. Réessaye plus tard.';
      } else {
        errorMessage = '?? Erreur de chargement';
        errorDetails = 'Une erreur est survenue. Réessaye.';
      }
      if (mounted) {
        setState(() {
          _model.setLoading(false);
          _model.setError(errorMessage, errorDetails);
        });
      }
    }
  }

  /// Ouvre l'URL d'un produit
  Future<void> _openProductUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      AppLogger.debug('? Erreur ouverture URL: $e', 'Debug');
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _searchCtrl.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFFAF5FF),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFAF5FF),
                  const Color(0xFFFCE7F3),
                  Colors.white,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(),

                  // Contenu
                  Expanded(
                    child: _model.isLoading
                        ? _buildLoader()
                        : _model.errorMessage != null
                            ? _buildErrorState()
                            : _buildTabbedContent(),
                  ),

                  // Boutons d'action
                  _buildActionButtons(),
                ],
              ),
            ),
          ),

          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // Vers le bas
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              maxBlastForce: 30,
              minBlastForce: 15,
              gravity: 0.3,
              colors: [
                violetColor,
                const Color(0xFFEC4899),
                const Color(0xFFFBBF24),
                const Color(0xFF10B981),
                const Color(0xFF3B82F6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final personHandle = _model.personTags != null
        ? ((_model.personTags!['username'] ?? _model.personTags!['personIdentifier'] ?? '') as String)
            .replaceAll('@', '').trim()
        : '';
    final hasWishlistGifts = _model.gifts.any((g) => g['fromWishlist'] == true);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              // Bouton retour/fermer
              IconButton(
                onPressed: () {
                  if (!mounted) return;
                  if (_returnTo != null && _returnTo!.isNotEmpty) {
                    AppLogger.debug('?? Retour vers: $_returnTo', 'Debug');
                    context.go(_returnTo!);
                  } else {
                    context.go('/search-page');
                  }
                },
                icon: Icon(
                  _returnTo != null && _returnTo!.isNotEmpty
                      ? Icons.arrow_back
                      : Icons.close,
                  color: violetColor,
                ),
                tooltip: _returnTo != null && _returnTo!.isNotEmpty ? 'Retour' : 'Fermer',
              ),
              Icon(Icons.auto_awesome, color: violetColor, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tes cadeaux personnalisés',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: violetColor,
                      ),
                    ),
                    Text(
                      hasWishlistGifts && personHandle.isNotEmpty
                          ? '?? Incl. wishlist @$personHandle'
                          : 'Basés sur tes réponses',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: hasWishlistGifts ? const Color(0xFF10B981) : Colors.grey[600],
                        fontWeight: hasWishlistGifts ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Premium3DIcon(assetName: 'gift_3d.png', size: 160),
          const SizedBox(height: 32),
          Text(
            "L'IA prépare vos cadeaux...",
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Matching intelligent par tags (sexe, âge, centres d\'intérêt)',
            style: GoogleFonts.poppins(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'Aucun cadeau trouvé',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez de recharger',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône d'erreur
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),

            // Titre de l'erreur
            Text(
              _model.errorMessage ?? 'Une erreur est survenue',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Détails de l'erreur
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red[200]!, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(IconlyLight.infoSquare, size: 18, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Détails:',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _model.errorDetails ?? 'Erreur inconnue',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.red[900],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bouton réessayer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _loadGifts(forceRefresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.refresh, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Réessayer',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Bouton continuer quand même
            TextButton(
              onPressed: () async {
                // Marquer l'onboarding comme complété même sans cadeaux
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('onboarding_completed', true);

                if (mounted) {
                  if (FirebaseAuth.instance.currentUser != null) {
                    context.go('/search-page');
                  } else {
                    context.go('/authentification');
                  }
                }
              },
              child: Text(
                'Continuer sans cadeaux',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

    // ─── Filtrage Cadeaux Physiques vs Expériences & Activités ──────

  bool _isExperienceGift(Map<String, dynamic> gift) {
    final name = (gift['name'] ?? gift['title'] ?? '').toString().toLowerCase();
    final desc = (gift['description'] ?? '').toString().toLowerCase();
    final brand = (gift['brand'] ?? '').toString().toLowerCase();
    final type = (gift['type'] ?? '').toString().toLowerCase();

    final categories = gift['categories'];
    final tags = gift['tags'];

    List<String> allTokens = [];
    if (categories is List) {
      allTokens.addAll(categories.map((c) => c.toString().toLowerCase()));
    }
    if (tags is List) {
      allTokens.addAll(tags.map((t) => t.toString().toLowerCase()));
    }

    const experienceKeywords = [
      'experience', 'expérience', 'activite', 'activité', 'atelier', 'stage',
      'cours', 'spa', 'massage', 'voyage', 'sejour', 'séjour', 'hotel', 'hôtel',
      'restaurant', 'dégustation', 'degustation', 'billet', 'spectacle', 'concert',
      'theatre', 'théâtre', 'escapade', 'vol', 'saut', 'parapente', 'escape game',
      'visite', 'musée', 'musee', 'parc', 'aventure', 'wonderbox', 'smartbox',
      'type_voyage_aventure', 'type_bien_etre', 'type_gastronomie', 'type_culture',
      'passion_voyages', 'pass', 'ticket', 'abonnement', 'dîner', 'dejeuner', 'déjeuner',
      'nuitée', 'nuitee', 'détente', 'detente', 'thalasso', 'karting', 'simulateur',
      'oenologie', 'œnologie', 'gastronomie', 'croisière', 'croisiere', 'baptême',
      'coffret', 'box', 'weekend', 'week-end', 'escapade', 'soin'
    ];

    for (final kw in experienceKeywords) {
      if (type.contains(kw) || name.contains(kw) || desc.contains(kw) || brand.contains(kw)) {
        return true;
      }
      for (final token in allTokens) {
        if (token.contains(kw)) return true;
      }
    }

    return false;
  }

  List<Map<String, dynamic>> _filterGiftsList(List<Map<String, dynamic>> list) {
    if (_giftCategoryFilter == 'physical') {
      return list.where((g) => !_isExperienceGift(g)).toList();
    } else if (_giftCategoryFilter == 'experience') {
      return list.where((g) => _isExperienceGift(g)).toList();
    }
    return list;
  }

  Widget _buildCategoryFilterMenu() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterChip(
              id: 'physical',
              icon: '🎁',
              title: context.tr('Cadeaux physiques', 'Physical gifts'),
              isSelected: _giftCategoryFilter == 'physical',
              onTap: () {
                setState(() {
                  _giftCategoryFilter = _giftCategoryFilter == 'physical' ? 'all' : 'physical';
                });
                HapticFeedback.selectionClick();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterChip(
              id: 'experience',
              icon: '🎟️',
              title: context.tr('Expériences & Activités', 'Experiences & Activities'),
              isSelected: _giftCategoryFilter == 'experience',
              onTap: () {
                setState(() {
                  _giftCategoryFilter = _giftCategoryFilter == 'experience' ? 'all' : 'experience';
                });
                HapticFeedback.selectionClick();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String id,
    required String icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? violetColor.withOpacity(0.12)
                : Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? violetColor : Colors.black.withOpacity(0.08),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: violetColor.withOpacity(0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? violetColor : const Color(0xFF374151),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Fin de quiz : 3 onglets (Recommandés · Ses envies · Recherche) ──────

  Widget _buildTabbedContent() {
    final recommended =
        _model.gifts.where((g) => g['fromWishlist'] != true).toList();
    final wishlist =
        _model.gifts.where((g) => g['fromWishlist'] == true).toList();

    final filteredRecommended = _filterGiftsList(recommended);
    final filteredWishlist = _filterGiftsList(wishlist);

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: violetColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              isScrollable: false,
              labelColor: Colors.white,
              unselectedLabelColor: violetColor,
              labelStyle:
                  GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600),
              indicator: BoxDecoration(
                color: violetColor,
                borderRadius: BorderRadius.circular(14),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: context.tr('Recommandés', 'For them')),
                Tab(text: context.tr('Ses envies', 'Their wishes')),
                Tab(text: context.tr('Recherche', 'Search')),
              ],
            ),
          ),
          // Deux menus très légers en haut (Cadeaux physiques / Expériences & Activités)
          _buildCategoryFilterMenu(),
          Expanded(
            child: TabBarView(
              children: [
                filteredRecommended.isEmpty
                    ? (recommended.isEmpty
                        ? _buildEmptyState()
                        : _buildFilteredEmptyState(context.tr('Aucun cadeau trouvé', 'No gifts found')))
                    : _buildGiftsGrid(filteredRecommended),
                filteredWishlist.isEmpty
                    ? (wishlist.isEmpty
                        ? _buildTabEmpty(
                            Icons.favorite_border_rounded,
                            context.tr('Aucune envie connue',
                                'No known wishes'),
                            context.tr(
                                'Ses produits likés et wishlists apparaîtront ici.',
                                'Their liked products and wishlists will show here.'))
                        : _buildFilteredEmptyState(context.tr('Aucun cadeau trouvé', 'No gifts found')))
                    : _buildGiftsGrid(filteredWishlist),
                _buildSearchTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Grille compacte (3 colonnes) — plus de cadeaux visibles d'un coup.
  Widget _buildGiftsGrid(List<Map<String, dynamic>> gifts) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
        childAspectRatio: 0.60,
      ),
      itemCount: gifts.length,
      itemBuilder: (context, index) => _buildGiftGridCard(gifts[index]),
    );
  }

  /// Carte compacte avec le rond de sélection qui se remplit.
  Widget _buildGiftGridCard(Map<String, dynamic> gift) {
    final giftId = gift['id']?.toString() ?? '';
    final isSelected = _model.isGiftSelected(giftId);
    final img = (gift['image'] ?? gift['imageUrl'] ?? gift['image_url'] ?? '').toString();

    return GestureDetector(
      onTap: () {
        setState(() => _model.toggleGiftSelection(giftId));
        HapticFeedback.selectionClick();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: violetColor, width: 2.5) : null,
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? violetColor.withOpacity(0.25)
                  : Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: img.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: img,
                            fit: BoxFit.cover,
                            memCacheWidth: 300,
                            placeholder: (c, u) => Container(color: violetColor.withOpacity(0.06)),
                            errorWidget: (c, u, e) => Container(
                              color: violetColor.withOpacity(0.06),
                              child: Icon(Icons.card_giftcard,
                                  color: violetColor.withOpacity(0.4), size: 28),
                            ),
                          )
                        : Container(
                            color: violetColor.withOpacity(0.06),
                            child: Icon(Icons.card_giftcard,
                                color: violetColor.withOpacity(0.4), size: 28),
                          ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected ? violetColor : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: isSelected ? violetColor : Colors.grey[400]!, width: 2),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 15)
                        : null,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        (gift['name'] ?? 'Produit').toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F2937),
                            height: 1.2),
                      ),
                    ),
                    if (gift['price'] != null && '${gift['price']}'.isNotEmpty)
                      Text(
                        '${gift['price']}${'${gift['price']}'.contains('€') ? '' : ' €'}',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: violetColor),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTab() {
    final filteredSearch = _filterGiftsList(_model.searchGifts);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            textInputAction: TextInputAction.search,
            onSubmitted: _runProductSearch,
            style: GoogleFonts.poppins(fontSize: 14),
            decoration: InputDecoration(
              hintText: context.tr('Chercher un cadeau…', 'Search a gift…'),
              hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
              prefixIcon: Icon(Icons.search, color: violetColor),
              suffixIcon: IconButton(
                icon: Icon(Icons.arrow_forward, color: violetColor),
                onPressed: () => _runProductSearch(_searchCtrl.text),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: violetColor.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: violetColor.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: violetColor, width: 2),
              ),
            ),
          ),
        ),
        Expanded(
          child: _isSearchingProducts
              ? Center(child: CircularProgressIndicator(color: violetColor))
              : _model.searchGifts.isEmpty
                  ? _buildTabEmpty(
                      Icons.search_rounded,
                      context.tr('Cherche n\'importe quel cadeau',
                          'Search for any gift'),
                      context.tr(
                          'Tape un mot-clé pour trouver et ajouter un cadeau.',
                          'Type a keyword to find and add a gift.'))
                  : (filteredSearch.isEmpty
                      ? _buildFilteredEmptyState(context.tr('Aucun cadeau trouvé', 'No gifts found'))
                      : _buildGiftsGrid(filteredSearch)),
        ),
      ],
    );
  }

  Widget _buildFilteredEmptyState(String title) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _giftCategoryFilter == 'physical'
                  ? Icons.inventory_2_outlined
                  : Icons.confirmation_number_outlined,
              size: 44,
              color: violetColor.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              _giftCategoryFilter == 'physical'
                  ? context.tr('Aucun cadeau physique dans cette sélection', 'No physical gifts in this selection')
                  : context.tr('Aucune expérience dans cette sélection', 'No experiences in this selection'),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() => _giftCategoryFilter = 'all');
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(
                context.tr('Afficher tous les types', 'Show all types'),
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(foregroundColor: violetColor),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runProductSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    setState(() => _isSearchingProducts = true);
    try {
      final results = await ProductSearchService.search(q, limit: 40);
      final mapped = results.map<Map<String, dynamic>>((p) {
        final id = (p['id'] ?? p['objectID'] ?? p['name'] ?? '').toString();
        return {
          'id': id.isEmpty ? 'search_${p.hashCode}' : id,
          'name': p['name'] ?? p['product_title'] ?? 'Produit',
          'brand': p['brand'] ?? '',
          'price': p['price'] ?? '',
          'image': p['image'] ?? p['imageUrl'] ?? p['image_url'] ?? '',
          'url': p['url'] ?? p['product_url'] ?? '',
          'fromSearch': true,
        };
      }).toList();
      if (mounted) {
        setState(() {
          _model.searchGifts = mapped;
          _isSearchingProducts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSearchingProducts = false);
    }
  }

  Widget _buildTabEmpty(IconData icon, String title, String sub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: violetColor.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1F2937))),
            const SizedBox(height: 6),
            Text(sub,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      itemCount: _model.gifts.length,
      itemBuilder: (context, index) {
        final gift = _model.gifts[index];
        return _buildGiftCard(gift);
      },
    );
  }

  Widget _buildGiftCard(Map<String, dynamic> gift) {
    final giftId = gift['id']?.toString() ?? '';
    final isSelected = _model.isGiftSelected(giftId);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: BounceCard(
        onTap: () {
          // Toggle sélection au lieu d'ouvrir l'URL
          setState(() {
            _model.toggleGiftSelection(giftId);
          });
          HapticFeedback.selectionClick();
        },
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? Border.all(color: violetColor, width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? violetColor.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image du produit - FIX Bug 5: Améliorer le loading et l'erreur
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: gift['image'] ?? '',
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        memCacheWidth: 600,
                        placeholder: (context, url) => Container(
                          height: 250,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                violetColor.withOpacity(0.1),
                                const Color(0xFFEC4899).withOpacity(0.1),
                              ],
                            ),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: violetColor,
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 250,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                violetColor.withOpacity(0.1),
                                const Color(0xFFEC4899).withOpacity(0.1),
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.card_giftcard,
                                color: violetColor.withOpacity(0.5),
                                size: 60,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Erreur d\'image',
                                style: GoogleFonts.poppins(
                                  color: violetColor.withOpacity(0.7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Informations du produit
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Marque
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: violetColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              gift['brand'] ?? 'En ligne',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: violetColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Nom du produit
                          Text(
                            gift['name'] ?? 'Produit',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Description
                          if (gift['description'] != null && gift['description'].toString().isNotEmpty)
                            Text(
                              gift['description'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF6B7280),
                                height: 1.6,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 16),
                          // Prix et bouton
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Prix
                              Text(
                                '${gift['price']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: violetColor,
                                ),
                              ),
                              // Bouton voir
                              ElevatedButton(
                                onPressed: () => _openProductUrl(gift['url'] ?? ''),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: violetColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 2,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'Voir',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Checkbox de sélection (overlay top-right)
                Positioned(
                  top: 16,
                  right: 16,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected ? violetColor : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? violetColor : Colors.grey[400]!,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton Refaire
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _model.isLoading
                ? null
                : () => _loadGifts(forceRefresh: true),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: violetColor, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, color: violetColor),
                  const SizedBox(width: 8),
                  Text(
                    'Générer de nouveaux cadeaux',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: violetColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Bouton Valider (seulement si des cadeaux sont sélectionnés)
          if (_model.selectedCount > 0)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _model.isLoading
                    ? null
                    : () async {
                        // Haptic feedback au clic
                        HapticFeedback.mediumImpact();

                        // Récupérer uniquement les cadeaux sélectionnés
                        final selectedGifts = _model.getSelectedGifts();

                        if (selectedGifts.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Veuillez sélectionner au moins un cadeau',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                              ),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                          return;
                        }

                        // Nouvelle architecture: sauvegarder la liste de cadeaux pour une personne
                        if (_model.personId != null) {
                          AppLogger.debug('?? Sauvegarde via nouvelle architecture (personId: ${_model.personId})', 'Debug');
                          AppLogger.debug('?? ${selectedGifts.length} cadeaux sélectionnés sur ${_model.gifts.length}', 'Debug');

                          // Fusionner avec les cadeaux existants s'il y en a déjà
                          final existingList = await FirebaseDataService.loadLatestGiftListForPerson(_model.personId!);
                          final existingGifts = (existingList?['gifts'] as List? ?? []).cast<Map<String, dynamic>>();

                          final allGifts = <Map<String, dynamic>>[...existingGifts];
                          for (final g in selectedGifts) {
                            final gId = g['id']?.toString() ?? '';
                            if (gId.isNotEmpty && !allGifts.any((e) => (e['id']?.toString() ?? '') == gId)) {
                              allGifts.add(g);
                            }
                          }

                          final listName = existingList?['name'] as String? ?? 'Liste ${DateTime.now().day}/${DateTime.now().month}';
                          final listId = await FirebaseDataService.saveGiftListForPerson(
                            personId: _model.personId!,
                            gifts: allGifts.isNotEmpty ? allGifts : selectedGifts,
                            listName: listName,
                          );
                          AppLogger.debug('? ${selectedGifts.length} cadeaux sauvegardés (liste: $listId)', 'Debug');

                          // Retirer le flag isPendingFirstGen
                          await FirebaseDataService.updatePersonPendingFlag(_model.personId!, false);
                          AppLogger.debug('? Flag isPendingFirstGen retiré', 'Debug');

                          // Définir le contexte pour que les futurs favoris soient liés à cette personne
                          await FirebaseDataService.setCurrentPersonContext(_model.personId!);
                          AppLogger.debug('? Contexte de personne défini: ${_model.personId}', 'Debug');
                        } else {
                          // Ancienne méthode (compatibilité)
                          AppLogger.debug('?? Sauvegarde via ancienne architecture', 'Debug');
                          if (_model.userProfile != null) {
                            final profileWithGifts = {
                              ..._model.userProfile!,
                              'gifts': selectedGifts,
                              'savedAt': DateTime.now().toIso8601String(),
                            };
                            final profileId = await FirebaseDataService.saveGiftProfile(profileWithGifts);
                            AppLogger.debug('? Profil et ${selectedGifts.length} cadeaux sauvegardés', 'Debug');

                            if (profileId != null) {
                              await FirebaseDataService.setCurrentPersonContext(profileId);
                              AppLogger.debug('? Contexte de personne défini: $profileId', 'Debug');
                            }
                          }
                        }

                        // ?? CONFETTIS + HAPTIC lors de la sauvegarde réussie !
                        if (mounted) {
                          HapticFeedback.heavyImpact();
                          _confettiController.play();

                          // SnackBar de succès
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(IconlyBold.star, color: Colors.white, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '?? ${selectedGifts.length} cadeau${selectedGifts.length > 1 ? 'x' : ''} enregistré${selectedGifts.length > 1 ? 's' : ''} !',
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }

                        // Marquer l'onboarding comme complété
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('onboarding_completed', true);
                        await prefs.setString('not_first_time', 'true');
                        AppLogger.debug('? Onboarding marqué comme complété', 'Debug');

                        // Naviguer vers la page appropriée
                        if (mounted) {
                          // Vérifier si l'utilisateur est déjà authentifié
                          if (FirebaseAuth.instance.currentUser != null) {
                            AppLogger.debug('? Utilisateur déjà connecté, navigation retour', 'Debug');
                            if (context.canPop()) {
                              context.pop(true);
                            } else if (_returnTo != null && _returnTo!.isNotEmpty) {
                              context.go(_returnTo!);
                            } else {
                              context.go('/search-page?selectedProfileId=${_model.personId ?? ''}');
                            }
                          } else {
                            AppLogger.debug('?? Pas encore connecté, navigation vers auth', 'Debug');
                            context.go('/authentification');
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: violetColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: violetColor.withOpacity(0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Valider (${_model.selectedCount})',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Message si aucun cadeau sélectionné
          if (_model.selectedCount == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Sélectionne au moins un cadeau pour continuer',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
