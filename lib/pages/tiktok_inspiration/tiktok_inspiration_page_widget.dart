import '/utils/app_logger.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import '/components/product_detail_modal.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/services/firebase_data_service.dart';
import '/services/favourite_service.dart';
import '/components/connection_required_dialog.dart';
import '/components/aesthetic_buttons.dart';
import '/components/micro_interactions.dart' as micro;
import 'tiktok_inspiration_page_model.dart';
export 'tiktok_inspiration_page_model.dart';


/// Mode Inspiration - TikTok Style SIMPLIFIÉ
/// Swipe vertical entre produits, clic pour voir la fiche
class TikTokInspirationPageWidget extends StatefulWidget {
  const TikTokInspirationPageWidget({super.key});

  static String routeName = 'TikTokInspiration';
  static String routePath = '/inspiration';

  @override
  State<TikTokInspirationPageWidget> createState() => _TikTokInspirationPageWidgetState();
}

class _TikTokInspirationPageWidgetState extends State<TikTokInspirationPageWidget> {
  late TikTokInspirationPageModel _model;
  late PageController _pageController;

  static const Color _violetColor = Color(0xFF8A2BE2);
  static const Color _pinkColor = Color(0xFFEC4899);

  @override
  void initState() {
    super.initState();
    _model = TikTokInspirationPageModel();
    _pageController = PageController();

    // Charger les produits après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _model.loadProducts();
      }
    });

    // Écouter les changements du model
    _model.addListener(_onModelChanged);
  }

  void _onModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _model.removeListener(_onModelChanged);
    _pageController.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildContent(),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                _buildCategoryTabs(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // État de chargement
    if (_model.isLoading) {
      return _buildLoadingState();
    }

    // État d'erreur
    if (_model.hasError) {
      return _buildErrorState();
    }

    // Liste vide
    if (_model.products.isEmpty) {
      return _buildEmptyState();
    }

    // Affichage des produits
    return _buildProductsView();
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8A2BE2),
            Color(0xFFEC4899),
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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              micro.ShimmerEffect(
                shimmerColor: Colors.white,
                duration: const Duration(milliseconds: 3000),
                child: Text(
                  'Inspirations ✨',
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
                'Des idées cadeaux qui vous correspondent',
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

  Widget _buildCategoryTabs() {
    final List<String> categories = ['recommandé', 'amis', 'vêtements', 'activité'];
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: 20),
            ...categories.map((category) {
              final isSelected = category.toLowerCase() == _model.activeCategory.toLowerCase();
              return Padding(
                padding: const EdgeInsets.only(right: 24),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _model.setCategory(category.toLowerCase());
                  },
                  child: Column(
                    children: [
                      Text(
                      category,
                      style: GoogleFonts.poppins(
                        color: Colors.white, // Inverted for dark background
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.8),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isSelected)
                      Container(
                        width: 40,
                        height: 2,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.black,
      child: Center(
        child: micro.FadeSlideIn(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              micro.PulseEffect(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      colors: [_violetColor, _pinkColor],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _violetColor.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.card_giftcard,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              micro.ShimmerEffect(
                child: Text(
                  'Chargement des inspirations...',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _model.errorMessage,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: PrimaryGradientButton(
                onPressed: () => _model.loadProducts(),
                text: 'Réessayer',
                icon: Icons.refresh,
                gradientColors: const [_violetColor, _pinkColor],
                height: 50,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Retour',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_giftcard,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune inspiration disponible',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Retour',
                style: GoogleFonts.poppins(color: _violetColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsView() {
    return Stack(
      children: [
        // PageView vertical pour swipe TikTok style
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: _model.products.length,
          onPageChanged: (index) {
            _model.setCurrentIndex(index);
            HapticFeedback.selectionClick();
          },
          itemBuilder: (context, index) {
            final product = _model.getProductAt(index);
            if (product == null) {
              return const SizedBox.shrink();
            }
            return _buildProductCard(product, index);
          },
        ),

        // ✨ INFINITE SCROLL: Indicateur de chargement en bas
        if (_model.isLoadingMore)
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Chargement...',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ✨ INFINITE SCROLL: Compteur de produits (pour debug/info)
        Positioned(
          top: 16,
          right: 60,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_model.currentIndex + 1} / ${_model.products.length}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final total = _model.products.length;
    final current = _model.currentIndex + 1;

    // Calculer le ratio de façon sécurisée
    double ratio = 0.0;
    if (total > 0) {
      ratio = current / total;
      // Sécurité: s'assurer que le ratio est valide
      if (ratio.isNaN || ratio.isInfinite) {
        ratio = 0.0;
      }
      ratio = ratio.clamp(0.0, 1.0);
    }

    return Container(
      width: 4,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.topCenter,
        heightFactor: ratio,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_pinkColor, _violetColor],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, int index) {
    // Extraire les données de façon sécurisée
    final String name = product['name']?.toString() ?? 'Produit';
    final String brand = product['brand']?.toString() ?? '';
    final String image = product['image']?.toString() ?? '';
    final String url = product['url']?.toString() ?? '';
    final int price = product['price'] is int ? product['price'] : 0;
    final int match = product['match'] is int ? product['match'] : 85;

    final bool isLiked = _model.likedProductTitles.contains(name);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Image en plein écran
        _buildProductImage(image),

        // Overlay gradient en bas
        // Overlay gradient en bas, plus haut
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 350,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.9),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ),

        // Informations produit en bas (remonté)
        Positioned(
          bottom: 120, // Espace pour la navbar flottante (72px) + marge + safe area
          left: 16,
          right: 70, // Laisser de la place pour les boutons d'action
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Swipe indicator moved near product info
              if (index == 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.keyboard_arrow_up,
                          color: Colors.white.withOpacity(0.8),
                          size: 32,
                        ),
                        Text(
                          'swipe',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Badge marque avec effet néon
              if (brand.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: _violetColor, width: 1.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    brand, // Plus original, majuscule/minuscule selon la DB
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              if (brand.isNotEmpty) const SizedBox(height: 8),

              // Nom du produit
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.white,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Prix
              Text(
                '${price}€',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Bouton voir le produit énorme et stylisé
              if (url.isNotEmpty)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openProductUrl(url),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: _pinkColor,
                          width: 2,
                        ),
                        color: _pinkColor.withOpacity(0.1),
                      ),
                      child: Center(
                        child: Text(
                          'Voir le produit',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Bouton actions en colonne à droite (remontés)
        Positioned(
          right: 16,
          bottom: 140,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bouton options ... → bottom sheet direct
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Ouvrir directement le bottom sheet d'actions (bug #7)
                  _showInspirationActionsSheet(context, {
                    'name': product['name'] ?? '',
                    'brand': product['brand'] ?? '',
                    'price': product['price'] ?? '',
                    'image': product['image'] ?? '',
                    'url': product['url'] ?? '',
                  });
                },
                child: Container(
                  width: 46,
                  height: 36,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _violetColor, width: 2),
                    color: Colors.transparent,
                  ),
                  child: const Icon(IconlyLight.moreSquare, color: Colors.white, size: 24),
                ),
              ),
              // Wishlist
              _buildWishlistButton(product),
              const SizedBox(height: 16),
              // Like
              _buildLikeButton(product, isLiked),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        color: const Color(0xFF0D0D0D),
        child: Center(
          child: Icon(
            IconlyLight.image,
            size: 64,
            color: Colors.grey[700],
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Fond sombre
        Container(color: const Color(0xFF0D0D0D)),

        // Image en background floue pour l'ambiance couleur
        Positioned.fill(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.72),
            colorBlendMode: BlendMode.darken,
            errorWidget: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),

        // Blur overlay
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),
        ),

        // ─── Cadre produit centré à taille fixe ───
        // Toutes les images occupent exactement la même zone,
        // quelle que soit leur forme (portrait / paysage / carré).
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AspectRatio(
              aspectRatio: 3 / 3.6, // ratio fixe identique pour tous
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(27),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain, // image entière, jamais coupée
                    placeholder: (context, url) => const Center(
                      child: micro.ShimmerLoading(
                        width: 200,
                        height: 200,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.grey[700]),
                          const SizedBox(height: 8),
                          Text(
                            'Image non disponible',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLikeButton(Map<String, dynamic> product, bool isLiked) {
    return GlassmorphicButton(
      onPressed: () => _toggleFavorite(product),
      icon: isLiked ? IconlyBold.heart : IconlyLight.heart,
      color: isLiked ? Colors.red : _violetColor,
      size: 56,
      isActive: isLiked,
    );
  }

  Future<void> _openProductUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      AppLogger.debug('❌ Erreur ouverture URL: $e', 'Debug');
    }
  }

  /// Bug #7 — Bottom sheet direct depuis la page Inspiration
  void _showInspirationActionsSheet(BuildContext context, Map<String, dynamic> product) {
    const violet = Color(0xFF8A2BE2);
    const pink = Color(0xFFEC4899);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    const Icon(IconlyLight.moreSquare, color: violet, size: 24),
                    const SizedBox(width: 12),
                    Text('Actions', style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white12),
              // Option 1 : Envoyer par message
              ListTile(
                leading: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: violet.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(IconlyBold.send, color: violet, size: 24),
                ),
                title: Text('Envoyer par message', style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                subtitle: Text('Partager ce produit dans une conversation', style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.white54)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  GlobalProductDetailModal.showChatPicker(context, product);
                },
              ),
              // Option 2 : Ajouter pour quelqu'un
              ListTile(
                leading: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: pink.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.card_giftcard, color: pink, size: 24),
                ),
                title: Text("Ajouter pour quelqu'un", style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                subtitle: Text("Ajouter ce cadeau dans la liste d'un proche", style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.white54)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  GlobalProductDetailModal.showPersonPicker(context, product);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(Map<String, dynamic> product) async {
    HapticFeedback.mediumImpact();

    final productName = product['name']?.toString() ?? '';
    if (productName.isEmpty) return;

    // Vérifier l'authentification
    if (!loggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connectez-vous pour sauvegarder vos favoris', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange[700],
        ),
      );
      return;
    }

    final isCurrentlyLiked = _model.likedProductTitles.contains(productName);

    // Mise à jour locale immédiate (optimistic UI)
    setState(() {
      if (isCurrentlyLiked) {
        _model.likedProductTitles.remove(productName);
      } else {
        _model.likedProductTitles.add(productName);
      }
    });

    // Écriture Firestore via FavouriteService (users/{uid}/favorites)
    final success = await FavouriteService.toggle(product);

    if (!success) {
      // Revert en cas d'erreur
      if (mounted) {
        setState(() {
          if (isCurrentlyLiked) {
            _model.likedProductTitles.add(productName);
          } else {
            _model.likedProductTitles.remove(productName);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour des favoris', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } else if (!isCurrentlyLiked && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❤️ Ajouté aux favoris !', style: GoogleFonts.poppins()),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }


  Widget _buildWishlistButton(Map<String, dynamic> product) {
    return GlassmorphicButton(
      onPressed: () => _showWishlistModal(product),
      icon: IconlyLight.bookmark,
      color: _pinkColor,
      size: 56,
      isActive: false,
    );
  }

  /// Affiche le modal de sélection de wishlist
  Future<void> _showWishlistModal(Map<String, dynamic> product) async {
    if (!loggedIn) {
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
                    const Icon(IconlyLight.bookmark, color: _violetColor, size: 28),
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
                      Icon(IconlyLight.document, size: 60, color: Colors.grey[400]),
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
                            color: _violetColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            IconlyBold.bookmark,
                            color: _violetColor,
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
                        trailing: const Icon(
                          Icons.add_circle,
                          color: _violetColor,
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
                child: PrimaryGradientButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _createNewWishlist(product);
                  },
                  text: 'Créer une nouvelle wishlist',
                  icon: Icons.add,
                  gradientColors: const [_violetColor, _pinkColor],
                  height: 56,
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
                  borderSide: const BorderSide(color: _violetColor, width: 2),
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
                  borderSide: const BorderSide(color: _violetColor, width: 2),
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
              backgroundColor: _violetColor,
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
      // Utilise addProductToWishlist qui écrit dans la sous-collection products/
      // (cohérent avec loadWishlistProducts et WishlistPickerSheet)
      final ok = await FirebaseDataService.addProductToWishlist(wishlistId, product);
      if (!ok) throw Exception('addProductToWishlist returned false');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(IconlyBold.bookmark, color: Colors.white, size: 20),
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
      AppLogger.debug('❌ Erreur ajout wishlist: $e', 'Debug');
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
