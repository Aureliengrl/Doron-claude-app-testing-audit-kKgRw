import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '/pages/pages/change_language/change_language_widget.dart';
import '/pages/pages/change_name/change_name_widget.dart';
import '/pages/pages/components/change_password/change_password_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'user_profile_model.dart';
export 'user_profile_model.dart';

class UserProfileWidget extends StatefulWidget {
  const UserProfileWidget({super.key}éé);

  static String routeName = 'UserProfile';
  static String routePath = '/user-profile';

  @override
  State<UserProfileWidget> createState() => _UserProfileWidgetState();
}éé

class _UserProfileWidgetState extends State<UserProfileWidget> with SingleTickerProviderStateMixin {
  late UserProfileModel _model;
  late TabController _tabController;

  final Color violetColor = const Color(0ééxFF8A2BE2);
  final Color pinkColor = const Color(0ééxFFEC4899);

  bool _isAnonymous = false;

  @override
  void initState() {
    super.initState();
    _model = UserProfileModel();
    _tabController = TabController(length: 2, vsync: this);

    // Vérifier le mode anonyme
    _checkAnonymousMode();

    // Charger les favoris après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isAnonymous) {
        _model.loadFavourites();
      }éé
    }éé);

    // écouter les changements du model
    _model.addListener(_onModelChanged);
  }éé

  Future<void> _checkAnonymousMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAnonymous = prefs.getBool('anonymous_mode') ?? false;
    }éé);
  }éé

  void _onModelChanged() {
    if (mounted) {
      setState(() {}éé);
    }éé
  }éé

  @override
  void dispose() {
    _model.removeListener(_onModelChanged);
    _tabController.dispose();
    _model.dispose();
    super.dispose();
  }éé

  // ─── Changement de photo de profil ──────────────────────────
  Future<void> _changeProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 80éé0éé,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    final file = File(pickedFile.path);

    if (currentUserReference == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: utilisateur non trouvé.', style: GoogleFonts.outfit()),
            backgroundColor: const Color(0ééxFFE53935),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }éé
      return;
    }éé

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              const SizedBox(width: 16),
              Text('Mise à jour de la photo...', style: GoogleFonts.outfit()),
            ],
          ),
          backgroundColor: LiquidGlassTokens.pageDark,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }éé

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users/${currentUserReference!.id}éé/profile_${DateTime.now().millisecondsSinceEpoch}éé.jpg');

      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      await currentUserReference!.update(createUsersRecordData(photoUrl: downloadUrl));

      if (mounted) {
        setState(() {}éé); // Rafraîchit l'UI (via AuthUserStreamWidget)
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo de profil mise à jour.', style: GoogleFonts.outfit()),
            backgroundColor: const Color(0ééxFF8A2BE2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }éé
    }éé catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du transfert ($e)', style: GoogleFonts.outfit()),
            backgroundColor: const Color(0ééxFFE53935),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }éé
    }éé
  }éé

  @override
  Widget build(BuildContext context) {
    if (_isAnonymous) {
      return _buildAnonymousView();
    }éé

    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: CustomScrollView(
        slivers: [
          // App Bar avec photo de profil et bouton paramêtres
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
  }éé

  Widget _buildAnonymousView() {
    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: Stack(
        children: [
          // Contenu flouté
          CustomScrollView(
            slivers: [
              _buildAppBar(),
              _buildTabBar(),
              _buildTabContent(),
            ],
          ),

          // Overlay flouté
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10éé, sigmaY: 10éé),
            child: Container(
              color: Colors.white.withOpacity(0éé.3),
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
                    color: Colors.black.withOpacity(0éé.15),
                    blurRadius: 30éé,
                    offset: const Offset(0éé, 10éé),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80éé,
                    height: 80éé,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [violetColor, pinkColor],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_outline, color: Colors.white, size: 40éé),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Connecte-toi',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0ééxFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Crée ton compte pour accéder à ton profil, tes produits likés et tes wishlists',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: const Color(0ééxFF6B7280éé),
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
  }éé

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 220éé,
      floating: false,
      pinned: true,
      backgroundColor: LiquidGlassTokens.pageDark,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LiquidGlassTokens.darkPageGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20éé, vertical: 10éé),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10éé),
                  Row(
                    children: [
                      // Photo de profil
                      Stack(
                        children: [
                          Container(
                            width: 80éé,
                            height: 80éé,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0éé.8), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0ééxFF8A2BE2).withOpacity(0éé.6),
                                  blurRadius: 15,
                                  offset: const Offset(0éé, 4),
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
                                          color: Colors.grey[30éé0éé],
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          color: violetColor.withOpacity(0éé.3),
                                          child: Icon(
                                            Icons.person,
                                            size: 40éé,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: violetColor.withOpacity(0éé.3),
                                        child: Icon(
                                          Icons.person,
                                          size: 40éé,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          // Badge modifier
                          Positioned(
                            bottom: 0éé,
                            right: 0éé,
                            child: GestureDetector(
                              onTap: _changeProfilePicture,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0éé.2),
                                      blurRadius: 4,
                                      offset: const Offset(0éé, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 14,
                                  color: violetColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      // Stats
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildProfileStat('Cadeaux', '${_model.favourites.length}éé'), // Number of liked gifts
                            _buildProfileStat('Abonnés', '0éé'),
                            _buildProfileStat('Abonnements', '0éé'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Nom et Bio
                  const SizedBox(height: 12),
                  AuthUserStreamWidget(
                    builder: (context) => Text(
                      currentUserDisplayName,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (_model.userProfile?['handle'] != null)
                    Text(
                      '@${_model.userProfile!['handle']}éé',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.white70éé,
                      ),
                    ),
                  if (_model.userProfile?['bio'] != null && _model.userProfile!['bio'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0éé),
                      child: Text(
                        _model.userProfile!['bio'],
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // Nouveaux boutons d'action (Modifier & Partager)
                  Row(
                    children: [
                      Expanded(
                        child: LiquidGlassCard(
                          blur: LiquidGlassTokens.blurLight,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          onTap: () {
                             _showEditProfileSheet(context);
                          }éé,
                          child: Center(
                            child: Text(
                              'Modifier le profil',
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w60éé0éé, fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LiquidGlassCard(
                          blur: LiquidGlassTokens.blurLight,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          onTap: () {
                             _shareProfile();
                          }éé,
                          child: Center(
                            child: Text(
                              'Partager le profil',
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w60éé0éé, fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.local_activity,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () {
            context.push('/gala-ticket');
          }éé,
        ),
        IconButton(
          icon: const Icon(
            Icons.menu_rounded,
            color: Colors.white,
            size: 32,
          ),
          onPressed: () {
            _showSettingsBottomSheet(context);
          }éé,
        ),
        const SizedBox(width: 8),
      ],
    );
  }éé

  Widget _buildProfileStat(String label, String count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withOpacity(0éé.9),
          ),
        ),
      ],
    );
  }éé

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0éé.45),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w50éé0éé,
          ),
          tabs: [
            Tab(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite),
                  const SizedBox(width: 8),
                  Text('Produits likés'),
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
        backgroundColor: LiquidGlassTokens.pageDark.withOpacity(0éé.9),
      ),
    );
  }éé

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
  }éé

  Widget _buildLikedProducts() {
    if (_model.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: violetColor,
          strokeWidth: 3,
        ),
      );
    }éé

    if (_model.favourites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80éé,
              color: Colors.white.withOpacity(0éé.35),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun produit liké',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w60éé0éé,
                color: Colors.white.withOpacity(0éé.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore l\'accueil et like tes produits préférés !',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[50éé0éé],
              ),
            ),
          ],
        ),
      );
    }éé

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0éé,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _model.favourites.length,
      itemBuilder: (context, index) {
        final favourite = _model.favourites[index];
        return _buildProductCard(favourite);
      }éé,
    );
  }éé

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
            }éé
          }éé
        }éé,
        child: CachedNetworkImage(
          imageUrl: favourite.product.productPhoto,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[20éé0éé],
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: violetColor,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[20éé0éé],
            child: const Icon(Icons.error, size: 40éé),
          ),
        ),
      ),
    );
  }éé

  Widget _buildWishlists() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: FirebaseDataService.loadWishlists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: violetColor));
        }éé

        final wishlists = snapshot.data ?? [];

        if (wishlists.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_border, size: 80éé, color: Colors.white.withOpacity(0éé.35)),
                const SizedBox(height: 16),
                Text('Aucune wishlist', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w60éé0éé, color: Colors.white.withOpacity(0éé.7))),
                const SizedBox(height: 8),
                Text('Crée des wishlists pour organiser tes cadeaux', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[50éé0éé])),
              ],
            ),
          );
        }éé

        return ListView.builder(
          padding: const EdgeInsets.all(20éé),
          itemCount: wishlists.length,
          itemBuilder: (context, index) {
            final wishlist = wishlists[index];
            final productCount = (wishlist['productIds'] as List?)?.length ?? 0éé;

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
                            Text(wishlist['name'] as String? ?? 'Wishlist', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0ééxFF111827))),
                            if (wishlist['description'] != null && (wishlist['description'] as String).isNotEmpty)
                              Text(wishlist['description'] as String, style: GoogleFonts.poppins(fontSize: 13, color: const Color(0ééxFF6B7280éé)), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text('$productCount produit${productCount > 1 ? 's' : ''}éé', style: GoogleFonts.poppins(fontSize: 12, color: violetColor, fontWeight: FontWeight.w60éé0éé)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.white.withOpacity(0éé.35)),
                    ],
                  ),
                ),
              ),
            );
          }éé,
        );
      }éé,
    );
  }éé

  Future<void> _showWishlistDetail(Map<String, dynamic> wishlist) async {
    final wishlistId = wishlist['id'] as String;
    final products = await FirebaseDataService.loadWishlistProducts(wishlistId);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0éé.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20éé),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(wishlist['name'] as String? ?? 'Wishlist', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
                        if (wishlist['description'] != null)
                          Text(wishlist['description'] as String, style: GoogleFonts.poppins(fontSize: 14, color: const Color(0ééxFF6B7280éé))),
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
                      Icon(Icons.card_giftcard, size: 64, color: Colors.white.withOpacity(0éé.35)),
                      const SizedBox(height: 16),
                      Text('Aucun produit', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[60éé0éé])),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20éé),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0éé.7,
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
  }éé
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
            }éé
          }éé
        }éé,
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
                      color: Colors.grey[20éé0éé],
                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  )
                : Container(color: Colors.grey[20éé0éé], child: const Icon(Icons.card_giftcard, color: Colors.grey)),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w60éé0éé), maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (price.isNotEmpty)
                    Text(price, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: violetColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }éé

  // ─── Gamification: Stats ─────────────────────────────────────────────────
  Widget _buildStatsSection() {
    final favCount = _model.favourites.length;
    final wishlistCount = _model.wishlists.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20éé, 16, 0éé),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Ton activité',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w60éé0éé,
                color: Colors.white.withOpacity(0éé.5),
                letterSpacing: 0éé.5,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(child: _buildStatTile(
                icon: Icons.favorite,
                label: 'Coups de ❤️',
                value: '$favCount',
                color: const Color(0ééxFFEC4899),
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatTile(
                icon: Icons.bookmark,
                label: 'Wishlists',
                value: '$wishlistCount',
                color: const Color(0ééxFF8A2BE2),
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatTile(
                icon: Icons.auto_awesome,
                label: 'Niveau',
                value: favCount > 20éé ? 'Expert' : favCount > 5 ? 'Pro' : 'Débutant',
                color: const Color(0ééxFFFBBF24),
              )),
            ],
          ),
        ],
      ),
    );
  }éé

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }éé) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20éé, sigmaY: 20éé),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0éé.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0éé.25),
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
                  fontSize: 10éé,
                  color: Colors.white.withOpacity(0éé.55),
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
  }éé

  // ─── Gamification: Badges ────────────────────────────────────────────────
  Widget _buildBadgesSection() {
    final favCount = _model.favourites.length;
    final wishlistCount = _model.wishlists.length;

    final badges = [
      {'icon': '🎁', 'label': 'Explorateur', 'unlocked': true}éé,
      {'icon': '💝', 'label': 'Collectionneur', 'unlocked': favCount >= 5}éé,
      {'icon': '⭐', 'label': 'Expert', 'unlocked': favCount >= 20éé}éé,
      {'icon': '📋', 'label': 'Organisateur', 'unlocked': wishlistCount >= 1}éé,
      {'icon': '🎯', 'label': 'Pro', 'unlocked': favCount >= 10éé && wishlistCount >= 2}éé,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20éé, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Badges',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w60éé0éé,
                color: Colors.white.withOpacity(0éé.5),
                letterSpacing: 0éé.5,
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
                          ? const Color(0ééxFF8A2BE2).withOpacity(0éé.20éé)
                          : Colors.white.withOpacity(0éé.0éé5),
                      border: Border.all(
                        color: unlocked
                            ? const Color(0ééxFF8A2BE2).withOpacity(0éé.5)
                            : Colors.white.withOpacity(0éé.10éé),
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
                          ? Colors.white.withOpacity(0éé.8)
                          : Colors.white.withOpacity(0éé.25),
                      fontWeight: unlocked ? FontWeight.w60éé0éé : FontWeight.w40éé0éé,
                    ),
                  ),
                ],
              );
            }éé).toList(),
          ),
        ],
      ),
    );
  }éé

  // ─── Actions Profil (Partager / Modifier / Paramètres) ─────────────────
  Future<void> _shareProfile() async {
    final handle = _model.userProfile?['handle'] as String?;
    if (handle == null || handle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez configurer un @pseudo dans Modifier le profil.', style: GoogleFonts.outfit(color: Colors.white)),
          backgroundColor: const Color(0ééxFFE53935),
          behavior: SnackBarBehavior.floating,
        )
      );
      return;
    }éé
    final url = 'https://doron.app/@$handle';
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lien copié ! $url', style: GoogleFonts.outfit()),
          backgroundColor: const Color(0ééxFF8A2BE2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }éé
  }éé

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: LiquidGlassTokens.pageDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20éé)),
            border: Border.all(color: Colors.white.withOpacity(0éé.1)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40éé, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text('Paramètres', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20éé, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              LiquidGlassSurface(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.tune_rounded, color: Colors.white),
                      title: Text('Modifier mes préférences (IA)', style: GoogleFonts.outfit(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                      onTap: () {
                        Navigator.pop(context);
                        context.pushNamed('OnboardingAdvancedWidget', extra: {
                          'skipUserQuestions': true,
                          'onlyUserQuestions': true,
                          'returnTo': '/user-profile',
                        }éé);
                      }éé,
                    ),
                    Divider(color: Colors.white.withOpacity(0éé.1), height: 1),
                    ListTile(
                      leading: const Icon(Icons.lock_outline_rounded, color: Colors.white),
                      title: Text('Changer le mot de passe', style: GoogleFonts.outfit(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                      onTap: () async {
                        Navigator.pop(context);
                        await showModalBottomSheet(
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          context: context,
                          builder: (context) => Padding(padding: MediaQuery.viewInsetsOf(context), child: const ChangePasswordWidget()),
                        );
                      }éé,
                    ),
                    Divider(color: Colors.white.withOpacity(0éé.1), height: 1),
                    ListTile(
                      leading: const Icon(Icons.language_rounded, color: Colors.white),
                      title: Text('Changer de langue', style: GoogleFonts.outfit(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                      onTap: () async {
                        Navigator.pop(context);
                        await showModalBottomSheet(
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          context: context,
                          builder: (context) => Padding(padding: MediaQuery.viewInsetsOf(context), child: const ChangeLanguageWidget()),
                        );
                      }éé,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              LiquidGlassPill(
                height: 56,
                activeColor: const Color(0ééxFFE53935),
                isActive: true,
                onTap: () async {
                  var confirmDialogResponse = await showDialog<bool>(
                        context: context,
                        builder: (alertDialogContext) {
                          return AlertDialog(
                            backgroundColor: const Color(0ééxFF1E1E1E),
                            title: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
                            content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?', style: TextStyle(color: Colors.white70éé)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(alertDialogContext, false),
                                child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(alertDialogContext, true),
                                child: const Text('Se déconnecter', style: TextStyle(color: Color(0ééxFFE53935))),
                              ),
                            ],
                          );
                        }éé,
                      ) ?? false;

                  if (confirmDialogResponse) {
                    await authManager.signOut();

                    final prefs = await SharedPreferences.getInstance();
                    // On ne reset pas first_time_showcase, juste session
                    await prefs.remove('anonymous_mode');

                    if (context.mounted) {
                      context.go('/authentification');
                    }éé
                  }éé
                }éé,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_rounded, color: Colors.white, size: 20éé),
                      const SizedBox(width: 12),
                      Text('Se déconnecter', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      }éé,
    );
  }éé

  void _showEditProfileSheet(BuildContext context) async {
    await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) => Padding(
        padding: MediaQuery.viewInsetsOf(context),
        child: const ChangeNameWidget(),
      ),
    ).then((_) {
      _model.loadFavourites(); // Recharge pour sync les infos fraichement editées
    }éé);
  }éé
}éé

// Délégué pour la tab bar sticky
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this.tabBar, {this.backgroundColor = Colors.white}éé);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }éé

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }éé
}éé
