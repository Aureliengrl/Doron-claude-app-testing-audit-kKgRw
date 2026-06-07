import '/utils/app_logger.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/components/cached_image.dart';
import '/components/liquid_glass.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import '/utils/iconly_compat.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'favourites_model.dart';
export 'favourites_model.dart';

class FavouritesWidget extends StatefulWidget {
  const FavouritesWidget({super.key});

  static String routeName = 'Favourites';
  static String routePath = '/favourites';

  @override
  State<FavouritesWidget> createState() => _FavouritesWidgetState();
}

class _FavouritesWidgetState extends State<FavouritesWidget>
    with TickerProviderStateMixin {
  late FavouritesModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final Color violetColor = const Color(0xFF8A2BE2);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FavouritesModel());

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await _loadFavorites();
    });
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _model.loader = true;
    });

    try {
      _model.favourite = await queryFavouritesRecordOnce(
        queryBuilder: (favouritesRecord) => favouritesRecord
            .where('uid', isEqualTo: currentUserReference)
            .orderBy('TimeStamp', descending: true),
      );

      // Filtrer pour ne garder que les favoris "en vrac" (sans personId)
      // Ces favoris viennent de la page d'accueil
      _model.favouritesList = _model.favourite!
          .where((fav) => !fav.hasPersonId() || fav.personId == null || fav.personId!.isEmpty)
          .toList()
          .cast<FavouritesRecord>();

      AppLogger.debug('? Loaded ${_model.favouritesList.length} "en vrac" favorites (from home page)', 'Debug');
    } catch (e) {
      AppLogger.debug('? Error loading favorites: $e', 'Debug');
    }

    setState(() {
      _model.loader = false;
    });
  }

  @override
  void dispose() {
    _model.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<FavouritesRecord> get _filteredFavorites {
    if (_searchQuery.isEmpty) {
      return _model.favouritesList;
    }

    return _model.favouritesList.where((fav) {
      final title = fav.product.productTitle.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: LiquidGlassTokens.pageDark,
        body: RefreshIndicator(
          color: violetColor,
          onRefresh: _loadFavorites,
          child: CustomScrollView(
            slivers: [
              // Header moderne
              SliverToBoxAdapter(child: _buildHeader()),

              // Barre de recherche
              SliverToBoxAdapter(child: _buildSearchBar()),

              // Stats card
              SliverToBoxAdapter(child: _buildStatsCard()),

              // Contenu principal
              _buildContent(),

              // Espacement pour la bottom nav
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            LiquidGlassTokens.primary.withOpacity(0.50),
            LiquidGlassTokens.secondary.withOpacity(0.35),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        border: const Border(
          bottom: BorderSide(color: Color(0x44FFFFFF), width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: LiquidGlassTokens.primary.withOpacity(0.30),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Mes Favoris',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tous vos cadeaux préférés en un seul endroit',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
        ),
      ), // BackdropFilter
    ); // ClipRRect
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: 'Rechercher un cadeau...',
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.45),
            ),
            prefixIcon: Icon(
              IconlyLight.search,
              color: Colors.white.withOpacity(0.70),
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, size: 20, color: Colors.white.withOpacity(0.60)),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    if (_model.loader || _model.favouritesList.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculer quelques stats
    final totalItems = _model.favouritesList.length;
    final uniqueBrands = _model.favouritesList
        .map((f) => f.product.productTitle)
        .toSet()
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: violetColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: violetColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              IconlyLight.infoSquare,
              color: violetColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Vous avez $totalItems cadeau${totalItems > 1 ? 's' : ''} en favoris !',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_model.loader) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(60),
            child: CircularProgressIndicator(
              color: violetColor,
              strokeWidth: 3,
            ),
          ),
        ),
      );
    }

    final filteredList = _filteredFavorites;

    if (filteredList.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final favorite = filteredList[index];
            return _buildFavoriteCard(favorite);
          },
          childCount: filteredList.length,
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(FavouritesRecord favorite) {
    final product = favorite.product;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showProductDetail(favorite),
        borderRadius: BorderRadius.circular(20),
        child: Container(
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
              // Image avec bouton supprimer
              Stack(
                children: [
                  ProductImage(
                    imageUrl: product.productPhoto.isNotEmpty
                        ? product.productPhoto
                        : 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=600&q=80',
                    height: 180,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  // Bouton supprimer
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          await favorite.reference.delete();
                          _model.removeFromFavouritesList(favorite);
                          setState(() {});

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Retiré des favoris',
                                style: GoogleFonts.poppins(),
                              ),
                              backgroundColor: const Color(0xFF374151),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            IconlyBold.heart,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Info produit
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.productTitle.isNotEmpty
                            ? product.productTitle
                            : 'Produit',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          if (product.productPrice.isNotEmpty)
                            Expanded(
                              child: Text(
                                product.productPrice,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: violetColor,
                                ),
                              ),
                            ),
                          if (product.productUrl.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: violetColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.open_in_new,
                                size: 14,
                                color: violetColor,
                              ),
                            ),
                        ],
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: violetColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _searchQuery.isNotEmpty ? IconlyLight.search : IconlyLight.heart,
              size: 64,
              color: violetColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty
                ? 'Aucun résultat'
                : 'Pas encore de favoris',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Essayez avec d\'autres mots-clés'
                : 'Explorez l\'app et ajoutez vos cadeaux préférés !',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  void _showProductDetail(FavouritesRecord favorite) {
    final product = favorite.product;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xF01A0035), Color(0xF00D001A)],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          border: Border(
            top: BorderSide(color: Color(0x44FFFFFF), width: 1.0),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 14),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Image
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: CachedImage(
                  imageUrl: product.productPhoto.isNotEmpty
                      ? product.productPhoto
                      : 'https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=600&q=80',
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

            // Info
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (product.productPrice.isNotEmpty)
                      Text(
                        product.productPrice,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: violetColor,
                        ),
                      ),
                    const Spacer(),

                    // Boutons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (product.productUrl.isNotEmpty) {
                                final uri = Uri.parse(product.productUrl);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              }
                            },
                            icon: const Icon(IconlyLight.buy, size: 20),
                            label: Text(
                              'Voir le produit',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: violetColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await favorite.reference.delete();
                            _model.removeFromFavouritesList(favorite);
                            setState(() {});
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Icon(IconlyLight.delete, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ),
          ],
        ),
        ),
      ), // BackdropFilter
      ), // ClipRRect
    );
  }
}
