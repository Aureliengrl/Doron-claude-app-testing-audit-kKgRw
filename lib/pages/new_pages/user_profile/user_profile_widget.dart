import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import '/components/liquid_glass.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/services/product_url_service.dart';
import '/services/firebase_data_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'user_profile_model.dart';
export 'user_profile_model.dart';

class UserProfileWidget extends StatefulWidget {
  const UserProfileWidget({super.key});

  static String routeName = 'UserProfile';
  static String routePath = '/user-profile';

  @override
  State<UserProfileWidget> createState() => _UserProfileWidgetState();
}

class _UserProfileWidgetState extends State<UserProfileWidget> with SingleTickerProviderStateMixin {
  late UserProfileModel _model;
  late TabController _tabController;

  final Color violetColor = const Color(0xFF8A2BE2);
  final Color pinkColor = const Color(0xFFEC4899);

  bool _isAnonymous = false;

  @override
  void initState() {
    super.initState();
    _model = UserProfileModel();
    _tabController = TabController(length: 2, vsync: this);

    // V+�rifier le mode anonyme
    _checkAnonymousMode();

    // Charger les favoris apr+�s le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isAnonymous) {
        _model.loadFavourites();
      }
    });

    // +�couter les changements du model
    _model.addListener(_onModelChanged);
  }

  Future<void> _checkAnonymousMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAnonymous = prefs.getBool('anonymous_mode') ?? false;
    });
  }

  void _onModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _model.removeListener(_onModelChanged);
    _tabController.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAnonymous) {
      return _buildAnonymousView();
    }

    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: CustomScrollView(
        slivers: [
          // App Bar avec photo de profil et bouton param+�tres
          _buildAppBar(),          // Gamification Stats
          SliverToBoxAdapter(child: _buildStatsSection()),
          // Gamification Badges
          SliverToBoxAdapter(child: _buildBadgesSection()),

          // Tabs (Produits likés / Wishlists)
          _buildTabBar(),

          // Contenu des tabs
          _buildTabContent(),
        ],
      ),
    );
  }

  Widget _buildAnonymousView() {
    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: Stack(
        children: [
          // Contenu flout+�
          CustomScrollView(
            slivers: [
              _buildAppBar(),
              _buildTabBar(),
              _buildTabContent(),
            ],
          ),

          // Overlay flout+�
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.white.withOpacity(0.3),
            ),
          ),

          // Message connexion
          Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [violetColor, pinkColor],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_outline, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Connecte-toi',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Cr+�e ton compte pour acc+�der +� ton profil, tes produits lik+�s et tes wishlists',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/auth'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: violetColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Se connecter',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: LiquidGlassTokens.pageDark,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LiquidGlassTokens.darkPageGradient,
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Photo de profil
                Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.8), width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8A2BE2).withOpacity(0.6),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: AuthUserStreamWidget(
                          builder: (context) => currentUserPhoto != null && currentUserPhoto!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: currentUserPhoto!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: violetColor.withOpacity(0.3),
                                    child: Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: violetColor.withOpacity(0.3),
                                  child: Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    // Badge modifier
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          // TODO: Ouvrir s+�lecteur de photo
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Modifier la photo de profil - +� venir',
                                style: GoogleFonts.poppins(),
                              ),
                              backgroundColor: violetColor,
                            ),
                          );
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: violetColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Nom d'utilisateur
                AuthUserStreamWidget(
                  builder: (context) => Text(
                    '@${currentUserDisplayName ?? 'utilisateur'}',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Email
                Text(
                  currentUserEmail ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        // Bouton billet (mode d+�couverte)
        IconButton(
          icon: const Icon(
            Icons.local_activity,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () {
            context.push('/gala-ticket'); // Vers la page du gala
          },
        ),
        // Bouton param+�tres
        IconButton(
          icon: const Icon(
            Icons.settings,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () {
            context.push('/profile'); // Vers l'ancienne page param+�tres
          },
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabBarDelegate(backgroundColor: LiquidGlassTokens.pageDark.withOpacity(0.9),
        TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.45),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Tab(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite),
                  const SizedBox(width: 8),
                  Text('Produits lik+�s'),
                ],
              ),
            ),
            Tab(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.list),
                  const SizedBox(width: 8),
                  Text('Wishlists'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildLikedProducts(),
          _buildWishlists(),
        ],
      ),
    );
  }

  Widget _buildLikedProducts() {
    if (_model.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: violetColor,
          strokeWidth: 3,
        ),
      );
    }

    if (_model.favourites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.white.withOpacity(0.35),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun produit lik+�',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore l\'accueil et like tes produits pr+�f+�r+�s !',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _model.favourites.length,
      itemBuilder: (context, index) {
        final favourite = _model.favourites[index];
        return _buildProductCard(favourite);
      },
    );
  }

  Widget _buildProductCard(FavouritesRecord favourite) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          // Ouvrir l'URL du produit
          final url = favourite.product.productUrl;
          if (url.isNotEmpty) {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        },
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
              // Image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: favourite.product.productPhoto,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: violetColor,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.error, size: 40),
                      ),
                    ),
                  ),
                  // Coeur rouge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 32,
                      height: 32,
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
                        Icons.favorite,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),

              // Infos produit
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        favourite.product.productTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (favourite.platform != null && favourite.platform!.isNotEmpty)
                        Text(
                          favourite.platform!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      const Spacer(),
                      if (favourite.product.productPrice.isNotEmpty)
                        Text(
                          favourite.product.productPrice,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: violetColor,
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

  Widget _buildWishlists() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: FirebaseDataService.loadWishlists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: violetColor));
        }

        final wishlists = snapshot.data ?? [];

        if (wishlists.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_border, size: 80, color: Colors.white.withOpacity(0.35)),
                const SizedBox(height: 16),
                Text('Aucune wishlist', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.7))),
                const SizedBox(height: 8),
                Text('Cr+�e des wishlists pour organiser tes cadeaux', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: wishlists.length,
          itemBuilder: (context, index) {
            final wishlist = wishlists[index];
            final productCount = (wishlist['productIds'] as List?)?.length ?? 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: InkWell(
                onTap: () => _showWishlistDetail(wishlist),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [violetColor, pinkColor]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.bookmark, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(wishlist['name'] as String? ?? 'Wishlist', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
                            if (wishlist['description'] != null && (wishlist['description'] as String).isNotEmpty)
                              Text(wishlist['description'] as String, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6B7280)), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text('$productCount produit${productCount > 1 ? 's' : ''}', style: GoogleFonts.poppins(fontSize: 12, color: violetColor, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.35)),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showWishlistDetail(Map<String, dynamic> wishlist) async {
    final wishlistId = wishlist['id'] as String;
    final products = await FirebaseDataService.loadWishlistProducts(wishlistId);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(wishlist['name'] as String? ?? 'Wishlist', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
                        if (wishlist['description'] != null)
                          Text(wishlist['description'] as String, style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            const Divider(height: 1),
            if (products.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.card_giftcard, size: 64, color: Colors.white.withOpacity(0.35)),
                      const SizedBox(height: 16),
                      Text('Aucun produit', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) => _buildWishlistProductCard(products[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildWishlistProductCard(Map<String, dynamic> product) {
    final title = product['title'] as String? ?? product['name'] as String? ?? 'Produit';
    final price = product['price'] != null ? product['price'].toString() : '';
    final imageUrl = product['imageUrl'] as String? ?? product['image'] as String? ?? '';
    final url = product['url'] as String? ?? product['productUrl'] as String? ?? '';

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          if (url.isNotEmpty) {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  )
                : Container(color: Colors.grey[200], child: const Icon(Icons.card_giftcard, color: Colors.grey)),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (price.isNotEmpty)
                    Text(price, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: violetColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

  // ─── Gamification: Stats ─────────────────────────────────────────────────
  Widget _buildStatsSection() {
    final favCount = _model.favourites.length;
    final wishlistCount = _model.wishlists.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Ton activité',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.5),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(child: _buildStatTile(
                icon: Icons.favorite,
                label: 'Coups de ❤️',
                value: '$favCount',
                color: const Color(0xFFEC4899),
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatTile(
                icon: Icons.bookmark,
                label: 'Wishlists',
                value: '$wishlistCount',
                color: const Color(0xFF8A2BE2),
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatTile(
                icon: Icons.auto_awesome,
                label: 'Niveau',
                value: favCount > 20 ? 'Expert' : favCount > 5 ? 'Pro' : 'Débutant',
                color: const Color(0xFFFBBF24),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.55),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Gamification: Badges ────────────────────────────────────────────────
  Widget _buildBadgesSection() {
    final favCount = _model.favourites.length;
    final wishlistCount = _model.wishlists.length;

    final badges = [
      {'icon': '🎁', 'label': 'Explorateur', 'unlocked': true},
      {'icon': '💝', 'label': 'Collectionneur', 'unlocked': favCount >= 5},
      {'icon': '⭐', 'label': 'Expert', 'unlocked': favCount >= 20},
      {'icon': '📋', 'label': 'Organisateur', 'unlocked': wishlistCount >= 1},
      {'icon': '🎯', 'label': 'Pro', 'unlocked': favCount >= 10 && wishlistCount >= 2},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Badges',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.5),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: badges.map((badge) {
              final unlocked = badge['unlocked'] as bool;
              return Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: unlocked
                          ? const Color(0xFF8A2BE2).withOpacity(0.20)
                          : Colors.white.withOpacity(0.05),
                      border: Border.all(
                        color: unlocked
                            ? const Color(0xFF8A2BE2).withOpacity(0.5)
                            : Colors.white.withOpacity(0.10),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        badge['icon'] as String,
                        style: TextStyle(
                          fontSize: 22,
                          color: unlocked ? null : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    badge['label'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: unlocked
                          ? Colors.white.withOpacity(0.8)
                          : Colors.white.withOpacity(0.25),
                      fontWeight: unlocked ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

// D+�l+�gu+� pour la tab bar sticky
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
