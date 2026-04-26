import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import '/components/liquid_glass.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/services/firebase_data_service.dart';
import '/services/optimistic_image_uploader.dart';
import '/utils/image_compress_utils.dart';
import '/pages/pages/change_language/change_language_widget.dart';
import '/pages/pages/components/change_password/change_password_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'user_profile_model.dart';
import '/components/liquid_glass_loader.dart';
import 'dart:io';
import '/components/shared_product_card.dart';
import '/services/photo_permission_service.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  List<Map<String, dynamic>> _wishlists = [];
  bool _wishlistsLoading = true;
  int _friendsCount = 0;

  @override
  void initState() {
    super.initState();
    _model = UserProfileModel();
    _tabController = TabController(length: 2, vsync: this);

    // VÃ©rifier le mode anonyme
    _checkAnonymousMode();
    // Charger les wishlists initiales + nb amis
    _loadWishlists();
    _loadFriendsCount();

    // Charger les favoris et le profil aprÃ¨s le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isAnonymous) {
        _model.loadFavourites();
      }
    });

    // Ã©couter les changements du model
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

  // â”€â”€â”€ Changement de photo de profil â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Chemin local affichÃ© immÃ©diatement avant que l'upload termine.
  File? _localProfilePhoto;

  /// URL CDN mÃ©morisÃ©e aprÃ¨s upload â€” affichÃ©e mÃªme si AuthUserStream
  /// n'est pas encore rafraÃ®chi (Ã©vite le dÃ©lai de latence).
  String? _uploadedPhotoUrl;

  /// Fallback avatar (initiales / icÃ´ne)
  Widget _buildAvatarFallback() => Container(
    color: violetColor.withOpacity(0.3),
    child: Icon(IconlyLight.profile, size: 40, color: Colors.white),
  );

  Future<void> _changeProfilePicture() async {
    final pickedFile = await PhotoPermissionService.pickWithChoice(context);
    if (pickedFile == null || !mounted) return;

    final file = File(pickedFile.path);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // â”€â”€ Affichage OPTIMISTE IMMÃ‰DIAT â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (mounted) setState(() { _localProfilePhoto = file; _uploadedPhotoUrl = null; });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Sauvegarde de la photoâ€¦', style: GoogleFonts.outfit()),
        backgroundColor: LiquidGlassTokens.pageDark,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));
    }

    OptimisticImageUploader.upload(
      localPath: pickedFile.path,
      storagePath: 'users/$uid/profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      onUploadComplete: (downloadUrl) async {
        try {
          // â”€â”€ Ã‰criture ATOMIQUE : photo_url + photoUrl en un seul update â”€â”€
          // Synchronise les deux champs â†’ tous les lecteurs voient la photo
          // immÃ©diatement (public_profile_page, friend_service, etc.)
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .update({
                'photo_url': downloadUrl, // champ natif
                'photoUrl':  downloadUrl, // champ legacy FlutterFlow
              });
          await FirebaseAuth.instance.currentUser?.updatePhotoURL(downloadUrl);
          // Invalider cache CDN pour forcer le rechargement
          await CachedNetworkImage.evictFromCache(downloadUrl);
        } catch (_) {}

        if (mounted) {
          setState(() {
            _localProfilePhoto = null;
            _uploadedPhotoUrl  = downloadUrl; // mÃ©morisÃ© â†’ affichÃ© immÃ©diatement
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Photo de profil mise Ã  jour âœ“', style: GoogleFonts.outfit()),
            backgroundColor: const Color(0xFF8A2BE2),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ));
        }
      },
      onUploadError: (e) {
        if (mounted) {
          setState(() { _localProfilePhoto = null; _uploadedPhotoUrl = null; });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur upload photo: $e', style: GoogleFonts.outfit()),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
    );
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
          // App Bar avec photo de profil et bouton paramÃªtres
          _buildAppBar(),          // Tabs (Produits likÃ©s / Wishlists)
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
          // Contenu floutÃ©
          CustomScrollView(
            slivers: [
              _buildAppBar(),
              _buildTabBar(),
              _buildTabContent(),
            ],
          ),

          // Overlay floutÃ©
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
                    child: const Icon(IconlyLight.lock, color: Colors.white, size: 40),
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
                    'CrÃ©e ton compte pour accÃ©der Ã  ton profil, tes produits likÃ©s et tes wishlists',
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
                      onPressed: () => context.go('/authentification'),
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
    return SliverToBoxAdapter(
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  violetColor.withOpacity(0.12),
                  pinkColor.withOpacity(0.06),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.10),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top action buttons row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // F3: Bouton calendrier anniversaires (remplace le ticket)
                        IconButton(
                          icon: const Icon(
                            Icons.cake_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            context.push('/birthday-calendar');
                          },
                          tooltip: 'Calendrier & Anniversaires',
                        ),
                        IconButton(
                          icon: const Icon(
                            IconlyLight.moreSquare,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: () {
                            _showSettingsBottomSheet(context);
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Photo de profil
                        Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8A2BE2).withOpacity(0.6),
                                    blurRadius: 15,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                // â”€â”€ Avatar optimiste â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                                // Si un upload est en cours : fichier local
                                // Sinon : URL CDN via AuthUserStreamWidget
                                child: _localProfilePhoto != null
                                    ? Stack(fit: StackFit.expand, children: [
                                        Image.file(_localProfilePhoto!,
                                            fit: BoxFit.cover),
                                        // Micro-badge upload discret
                                        Positioned(
                                          bottom: 0, right: 0, left: 0,
                                          child: Container(
                                            height: 18,
                                            color: Colors.black45,
                                            child: const Center(
                                              child: SizedBox(
                                                width: 10, height: 10,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 1.5,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ])
                                     : _uploadedPhotoUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl: _uploadedPhotoUrl!,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => Container(
                                              color: violetColor.withOpacity(0.3),
                                              child: const Center(child: LiquidGlassLoader(size: 16, isDark: false)),
                                            ),
                                            errorWidget: (_, __, ___) => _buildAvatarFallback(),
                                          )
                                        : AuthUserStreamWidget(
                                            builder: (context) {
                                              final url = currentUserPhoto?.isNotEmpty == true ? currentUserPhoto! : null;
                                              return url != null
                                                  ? CachedNetworkImage(
                                                      imageUrl: url,
                                                      fit: BoxFit.cover,
                                                      placeholder: (_, __) => Container(
                                                        color: Colors.grey[800],
                                                        child: const Center(child: LiquidGlassLoader(size: 16, isDark: false)),
                                                      ),
                                                      errorWidget: (_, __, ___) => _buildAvatarFallback(),
                                                    )
                                                  : _buildAvatarFallback();
                                            },
                                          ),
                              ),
                            ),
                            // Badge modifier
                            Positioned(
                              bottom: 0,
                              right: 0,
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
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    IconlyLight.camera,
                                    size: 14,
                                    color: violetColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        // Stats â€” Amis / Wishlists / Cadeaux
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildProfileStat('Amis', '$_friendsCount'),
                              _buildProfileStat('Wishlists', '${_wishlists.length}'),
                              _buildProfileStat('Cadeaux', '${_model.favourites.length}'),
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
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (_model.userProfile?['handle'] != null)
                      Text(
                        '@${_model.userProfile!['handle']}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    // Bio
                    if (_model.userProfile?['bio'] != null && _model.userProfile!['bio'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _model.userProfile!['bio'],
                          style: GoogleFonts.poppins(
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
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            onTap: () {
                               _showEditProfileSheet(context);
                            },
                            child: Text(
                              'Modifier le profil',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LiquidGlassCard(
                            blur: LiquidGlassTokens.blurLight,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            onTap: () => context.push('/friends'),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(IconlyLight.people, color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Amis',
                                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LiquidGlassCard(
                            blur: LiquidGlassTokens.blurLight,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            onTap: () {
                               _shareProfile();
                            },
                            child: Text(
                              'Partager',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
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
      ),
    );
  }

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
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabBarDelegate(
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
                  const Icon(IconlyLight.document),
                  const SizedBox(width: 8),
                  Text('Wishlists'),
                ],
              ),
            ),
            Tab(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(IconlyBold.heart),
                  const SizedBox(width: 8),
                  Text('Produits likÃ©s'),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: LiquidGlassTokens.pageDark.withOpacity(0.9),
      ),
    );
  }

  Widget _buildTabContent() {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildWishlists(),
          _buildLikedProducts(),
        ],
      ),
    );
  }

  Widget _buildLikedProducts() {
    if (_model.isLoading) {
      return const Center(
        child: LiquidGlassLoader(size: 32),
      );
    }

    if (_model.favourites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              IconlyLight.heart,
              size: 80,
              color: Colors.white.withOpacity(0.35),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun produit likÃ©',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore l\'accueil et like tes produits prÃ©fÃ©rÃ©s !',
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

    return ReorderableGridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      childAspectRatio: 0.75,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      onReorder: (oldIndex, newIndex) {
        HapticFeedback.mediumImpact();
        setState(() {
          final item = _model.favourites.removeAt(oldIndex);
          _model.favourites.insert(newIndex, item);
        });
      },
      children: [
        for (int i = 0; i < _model.favourites.length; i++)
          SharedProductCard(
            key: ValueKey(_model.favourites[i]['id'] ?? i.toString()),
            product: _model.favourites[i],
            index: i,
            showWishlistButton: true,
            onRemove: null,
          ),
      ],
    );
  }

  // Unused after refactor
  Widget _buildLikedProductCard(Map<String, dynamic> favourite, int index) {
    return SharedProductCard(
      key: ValueKey(favourite['id'] ?? index.toString()),
      product: favourite,
      index: index,
      showWishlistButton: true,
      onRemove: null,
    );
  }

  Future<void> _loadFriendsCount() async {
    try {
      final uid = currentUserReference?.id;
      if (uid == null) return;
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!mounted) return;
      final friends = (doc.data()?['friends'] as List?) ?? [];
      setState(() => _friendsCount = friends.length);
    } catch (_) {}
  }

  Future<void> _loadWishlists() async {
    if (!mounted) return;
    setState(() => _wishlistsLoading = true);
    final data = await FirebaseDataService.loadWishlists();
    if (!mounted) return;
    setState(() {
      _wishlists = data;
      _wishlistsLoading = false;
    });
  }

  Widget _buildWishlists() {
    if (_wishlistsLoading) {
      return Center(child: LiquidGlassLoader(size: 40));
    }
    final wishlists = _wishlists;

        if (wishlists.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(IconlyLight.bookmark, size: 80, color: Colors.white.withOpacity(0.35)),
                const SizedBox(height: 16),
                Text('Aucune wishlist', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.7))),
                const SizedBox(height: 8),
                Text('CrÃ©e des wishlists pour organiser tes cadeaux', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500])),
              ],
            ),
          );
        }

        return Stack(
          children: [
            GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: wishlists.length,
              itemBuilder: (context, index) {
                final wishlist = wishlists[index];
                final coverUrl = wishlist['coverPhoto'] as String?;

                return GestureDetector(
                  onTap: () async {
                    await _showWishlistDetail(wishlist);
                    // Recharger la liste pour mettre Ã  jour le compteur sur la pochette
                    _loadWishlists();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0x1AFFFFFF),
                          Color(0x0AFFFFFF),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (coverUrl != null && coverUrl.isNotEmpty)
                            CachedNetworkImage(
                              imageUrl: coverUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.white.withOpacity(0.05),
                                child: const Center(
                                  child: LiquidGlassLoader(size: 24, isDark: false),
                                ),
                              ),
                              errorWidget: (context, url, error) => _buildDefaultCover(),
                            )
                          else
                            _buildDefaultCover(),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 80,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 12,
                            right: 12,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  wishlist['name'] as String? ?? 'Wishlist',
                                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _updateWishlistCover(wishlist['id'] as String),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(IconlyBold.camera, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // â€” Bouton CrÃ©er un album â€”
            Positioned(
              bottom: 90,
              left: 24,
              right: 24,
              child: GestureDetector(
                onTap: () async {
                  final created = await _showCreateAlbumDialog();
                  if (created == true) setState(() {});
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8A2BE2), Color(0xFFEC4899)],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8A2BE2).withOpacity(0.45),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text('CrÃ©er un album', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
  }

  /// Dialog de crÃ©ation d'un nouvel album (wishlist)
  Future<bool?> _showCreateAlbumDialog() async {
    final nameController = TextEditingController();
    final emojiController = TextEditingController(text: 'ðŸŽ');
    bool isCreating = false;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A0030),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(IconlyBold.bookmark, color: Color(0xFF8A2BE2), size: 24),
              const SizedBox(width: 10),
              Text('Nouvel album', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nom de l\'album (ex : pour NoÃ«l)',
                  hintStyle: GoogleFonts.poppins(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.07),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emojiController,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 22),
                decoration: InputDecoration(
                  hintText: 'Emoji (optionnel)',
                  hintStyle: GoogleFonts.poppins(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.07),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Annuler', style: GoogleFonts.poppins(color: Colors.white54)),
            ),
            TextButton(
              onPressed: isCreating
                  ? null
                  : () {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;
                      final emoji = emojiController.text.trim().isEmpty ? 'ðŸŽ' : emojiController.text.trim();

                      // â”€â”€ OPTIMISTIC UI :
                      // 1. Fermer le dialog immÃ©diatement
                      Navigator.pop(ctx, true);

                      // 2. Ajouter localement pour affichage instantanÃ©
                      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
                      final optimisticWishlist = {
                        'id': tempId,
                        'name': name,
                        'emoji': emoji,
                        'productCount': 0,
                        'coverPhoto': null,
                        'createdAt': DateTime.now().toIso8601String(),
                      };
                      setState(() => _wishlists.insert(0, optimisticWishlist));

                      // 3. CrÃ©er en arriÃ¨re-plan dans Firestore
                      FirebaseDataService.createWishlist(name: name, emoji: emoji).then((realId) {
                        if (realId != null && mounted) {
                          setState(() {
                            final idx = _wishlists.indexWhere((w) => w['id'] == tempId);
                            if (idx != -1) _wishlists[idx] = {...optimisticWishlist, 'id': realId};
                          });
                        }
                      });
                    },
              child: Text('CrÃ©er', style: GoogleFonts.poppins(color: const Color(0xFF8A2BE2), fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultCover() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8A2BE2),
            Color(0xFFEC4899),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          IconlyLight.activity,
          size: 48,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  Future<void> _updateWishlistCover(String wishlistId) async {
    // 1. Pick an image with permission
    final pickedFile = await PhotoPermissionService.pickFromGallery(context, imageQuality: 70);
    
    if (pickedFile == null || !mounted) return;

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Upload de la couverture en cours...')),
    );

    try {
      // 2. Upload to Firebase Storage
      final String uid = FirebaseAuth.instance.currentUser!.uid;
      final fileExtension = pickedFile.name.split('.').last;
      final fileName = 'wishlist_$wishlistId.${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final ref = FirebaseStorage.instance.ref().child('users/$uid/wishlist_covers/$fileName');
      // Compresser l'image avant l'upload
      final originalFile = File(pickedFile.path);
      final compressedFile = await ImageCompressUtils.compressImage(originalFile);
      final fileToUpload = compressedFile ?? originalFile;
      
      final uploadTask = await ref.putFile(fileToUpload);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // 3. Update Firestore Document
      await FirebaseFirestore.instance.collection('users').doc(uid).collection('wishlists').doc(wishlistId).update({
        'coverPhoto': downloadUrl,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('âœ… Couverture mise Ã  jour !')),
      );

      // Mettre Ã  jour immÃ©diatement en mÃ©moire + vider le cache image
      setState(() {
        final idx = _wishlists.indexWhere((w) => w['id'] == wishlistId);
        if (idx != -1) {
          _wishlists[idx] = {..._wishlists[idx], 'coverPhoto': downloadUrl};
        }
      });

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'upload: $e')),
      );
    }
  }

  Future<void> _showWishlistDetail(Map<String, dynamic> wishlist) async {
    final wishlistId = wishlist['id'] as String;
    final products = await FirebaseDataService.loadWishlistProducts(wishlistId);

    if (!mounted) return;

    // Normaliser les clÃ©s pour SharedProductCard (conserver le type pour routing photo/product)
    final normalizedProducts = products.map((p) => {
      'id': p['id'] ?? '',
      'type': p['type'] ?? 'product',  // phÃ©nomÃ¨ne clÃ© pour le routing PhotoItemCard
      'name': p['title'] ?? p['name'] ?? p['product_title'] ?? 'Produit',
      'brand': p['brand'] ?? p['platform'] ?? p['source'] ?? '',
      'price': (p['price'] ?? p['product_price'] ?? '').toString(),
      'image': p['imageUrl'] ?? p['image'] ?? p['product_photo'] ?? p['photo'] ?? '',
      'caption': p['caption'] ?? '',
      'url': p['url'] ?? p['productUrl'] ?? p['product_url'] ?? '',
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bsCtx) {
        final sheetProducts = List<Map<String, dynamic>>.from(normalizedProducts);
        return StatefulBuilder(
          builder: (bsCtx, setSheetState) => Container(
            height: MediaQuery.of(bsCtx).size.height * 0.88,
            decoration: BoxDecoration(
              color: LiquidGlassTokens.pageDark,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Column(
            children: [
              // PoignÃ©e
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              // En-tÃªte
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wishlist['name'] as String? ?? 'Wishlist',
                          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        if (wishlist['description'] != null && (wishlist['description'] as String).isNotEmpty)
                          Text(
                            wishlist['description'] as String,
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white54),
                          ),
                            Text(
                              '${sheetProducts.length} article${sheetProducts.length > 1 ? 's' : ''}',
                              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF8A2BE2)),
                        ),
                      ],
                    ),
                      ),
                      // Bouton + Photo (cyan)
                      GestureDetector(
                        onTap: () async {
                          final newPhoto = await _addPhotoToAlbum(wishlistId);
                          if (newPhoto != null) setSheetState(() => sheetProducts.insert(0, newPhoto));
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D4FF).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(IconlyBold.camera, color: Color(0xFF00D4FF), size: 16),
                              const SizedBox(width: 4),
                              Text('Photo', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF00D4FF))),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(bsCtx),
                        icon: const Icon(Icons.close_rounded, color: Colors.white54),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.white.withOpacity(0.08), height: 1),
            // Contenu
                if (sheetProducts.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(IconlyLight.heart, size: 64, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text('Aucun produit dans cette liste', style: GoogleFonts.poppins(fontSize: 16, color: Colors.white38, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('Ajoute des cadeaux via le bouton \u22ee sur chaque produit.', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white24)),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ReorderableGridView.count(
                  padding: const EdgeInsets.all(12),
                  crossAxisCount: 3,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  onReorder: (oldIndex, newIndex) {
                    HapticFeedback.mediumImpact();
                    setSheetState(() {
                      final item = sheetProducts.removeAt(oldIndex);
                      sheetProducts.insert(newIndex, item);
                    });
                  },
                  children: [
                    for (int i = 0; i < sheetProducts.length; i++)
                      SharedProductCard(
                        key: ValueKey(sheetProducts[i]['id'] ?? i.toString()),
                        product: sheetProducts[i],
                        index: i,
                        showWishlistButton: false,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        );
      },
    );
  }

  /// Ouvre un picker pour ajouter une photo dans un album wishlist.
  /// â”€ Upload OPTIMISTE : la photo s'affiche immÃ©diatement en local,
  ///   l'upload Firebase se fait en arriÃ¨re-plan.
  Future<Map<String, dynamic>?> _addPhotoToAlbum(
    String wishlistId, {
    /// Callback appelÃ© quand l'URL Firebase est disponible (mise Ã  jour en arriÃ¨re-plan)
    void Function(String photoId, String firebaseUrl, String price)? onUploaded,
  }) async {
    // â”€â”€ 1. Choix de la source â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    ImageSource? source;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: LiquidGlassTokens.pageDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: const Icon(IconlyLight.image, color: Color(0xFF00D4FF)),
              title: Text('Depuis la galerie', style: GoogleFonts.poppins(color: Colors.white)),
              onTap: () { source = ImageSource.gallery; Navigator.pop(ctx); },
            ),
            ListTile(
              leading: const Icon(IconlyBold.camera, color: Color(0xFF00D4FF)),
              title: Text('Prendre une photo', style: GoogleFonts.poppins(color: Colors.white)),
              onTap: () { source = ImageSource.camera; Navigator.pop(ctx); },
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return null;

    // â”€â”€ 2. SÃ©lection de la photo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final picked = source == ImageSource.gallery
        ? await PhotoPermissionService.pickFromGallery(context, imageQuality: 80)
        : await PhotoPermissionService.pickFromCamera(context, imageQuality: 80);
    if (picked == null || !mounted) return null;

    // â”€â”€ 3. Dialog Nom + Prix â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    String caption = '';
    String price = '';
    final captionCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0030),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(IconlyLight.editSquare, color: Color(0xFF00D4FF), size: 22),
            const SizedBox(width: 8),
            Text('DÃ©tails (optionnel)', style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Champ nom
            TextField(
              controller: captionCtrl,
              autofocus: true,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nom du produit (ex : Robe Zara)',
                hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(IconlyLight.document, color: Color(0xFF00D4FF), size: 18),
                filled: true,
                fillColor: Colors.white.withOpacity(0.07),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            // Champ prix
            TextField(
              controller: priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Prix (ex : 29.99)',
                hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.euro_rounded, color: Color(0xFFF59E0B), size: 18),
                filled: true,
                fillColor: Colors.white.withOpacity(0.07),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Passer', style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              caption = captionCtrl.text.trim();
              price = priceCtrl.text.trim();
              Navigator.pop(ctx);
            },
            child: Text('OK', style: GoogleFonts.poppins(
                color: const Color(0xFF00D4FF), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    captionCtrl.dispose();
    priceCtrl.dispose();
    if (!mounted) return null;

    // â”€â”€ 4. Affichage OPTIMISTE immÃ©diat (fichier local) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final localPath = picked.path;
    final optimisticEntry = {
      'id': tempId,
      'type': 'photo',
      'image': localPath,      // chemin fichier local â€” PhotoItemCard le gÃ¨re
      'caption': caption,
      'price': price,
      'url': '',
      '_isUploading': true,    // flag pour indicateur discret
    };

    // â”€â”€ 5. Upload en arriÃ¨re-plan â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    FirebaseDataService.addPhotoToWishlist(
      wishlistId,
      localPath,
      caption: caption.isEmpty ? null : caption,
      productName: caption.isEmpty ? null : caption,
      productPrice: price.isEmpty ? null : price,
    ).then((ok) {
      if (!ok || !mounted) return;
      // Snack discret de confirmation
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('ðŸ“· Photo ajoutÃ©e !', style: GoogleFonts.poppins(
            color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ));
    });

    // Retourner l'entrÃ©e optimiste â€” la grille l'affiche immÃ©diatement
    return optimisticEntry;
  }
  // â”€â”€â”€ Gamification & Stats â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Removed "Ton activitÃ©" and "Badges" per user request.

  // â”€â”€â”€ Actions & Modals â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _shareProfile() async {
    final handle = _model.userProfile?['handle'] as String?;
    if (handle == null || handle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez configurer un @pseudo dans Modifier le profil.', style: GoogleFonts.outfit(color: Colors.white)),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
        )
      );
      return;
    }
    final url = 'https://doron.app/@$handle';
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lien copiÃ© ! $url', style: GoogleFonts.outfit()),
          backgroundColor: const Color(0xFF8A2BE2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // â”€â”€â”€ ParamÃ¨tres â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: LiquidGlassTokens.pageDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text('ParamÃ¨tres', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              LiquidGlassSurface(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(IconlyLight.filter, color: Colors.white),
                      title: Text('Modifier mes prÃ©fÃ©rences (IA)', style: GoogleFonts.outfit(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.pushNamed('OnboardingAdvancedWidget', extra: {
                          'skipUserQuestions': true,
                          'onlyUserQuestions': true,
                          'returnTo': '/user-profile',
                        });
                      },
                    ),
                    Divider(color: Colors.white.withOpacity(0.1), height: 1),
                    ListTile(
                      leading: const Icon(IconlyLight.lock, color: Colors.white),
                      title: Text('Changer le mot de passe', style: GoogleFonts.outfit(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await showModalBottomSheet(
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          context: context,
                          builder: (c) => Padding(padding: MediaQuery.viewInsetsOf(c), child: const ChangePasswordWidget()),
                        );
                      },
                    ),
                    Divider(color: Colors.white.withOpacity(0.1), height: 1),
                    ListTile(
                      leading: const Icon(IconlyLight.discovery, color: Colors.white),
                      title: Text('Changer de langue', style: GoogleFonts.outfit(color: Colors.white)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await showModalBottomSheet(
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          context: context,
                          builder: (c) => Padding(padding: MediaQuery.viewInsetsOf(c), child: const ChangeLanguageWidget()),
                        );
                      },
                    ),
                    Divider(color: Colors.white.withOpacity(0.1), height: 1),
                    ListTile(
                      leading: const Icon(Icons.mic_rounded, color: Color(0xFF8A2BE2)),
                      title: Text('Assistant vocal', style: GoogleFonts.outfit(color: Colors.white)),
                      subtitle: Text('Trouver des cadeaux par la voix', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.go('/voice-guided-onboarding');
                      },
                    ),
                    Divider(color: Colors.white.withOpacity(0.1), height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                      title: Text('Supprimer mon compte', style: GoogleFonts.outfit(color: Colors.red)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.red),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _deleteAccount(context);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              LiquidGlassPill(
                height: 56,
                activeColor: const Color(0xFFE53935),
                isActive: true,
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: ctx,
                    builder: (alertCtx) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Déconnexion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?', style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(alertCtx, false), child: const Text('Annuler', style: TextStyle(color: Colors.white54))),
                        TextButton(onPressed: () => Navigator.pop(alertCtx, true), child: const Text('Se déconnecter', style: TextStyle(color: Color(0xFFE53935)))),
                      ],
                    ),
                  ) ?? false;
                  if (confirm) {
                    await authManager.signOut();
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('anonymous_mode');
                    if (ctx.mounted) ctx.go('/authentification');
                  }
                },
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(IconlyLight.logout, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Text('Se dÃ©connecter', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  // BUG 9 FIX: Suppression du compte (Firebase Auth uniquement)
  Future<void> _deleteAccount(BuildContext context) async {
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer le compte', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Cette action est irrÃ©versible. Votre compte sera dÃ©finitivement supprimÃ©.',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Annuler', style: GoogleFonts.poppins(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Continuer', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600))),
        ],
      ),
    ) ?? false;
    if (!confirm1 || !context.mounted) return;

    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirmation finale', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text('ÃŠtes-vous ABSOLUMENT sÃ»r ? Vous ne pourrez plus rÃ©cupÃ©rer votre compte.', style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Non, garder mon compte', style: GoogleFonts.poppins(color: Colors.white))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Oui, supprimer', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600))),
        ],
      ),
    ) ?? false;
    if (!confirm2 || !context.mounted) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await user.delete();
      await authManager.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('anonymous_mode');
      if (context.mounted) context.go('/authentification');
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Reconnectez-vous pour supprimer votre compte.', style: GoogleFonts.poppins()),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
        ));
        await authManager.signOut();
        context.go('/authentification');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : ${e.message}', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur inattendue : $e', style: GoogleFonts.poppins()),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // BUG 8 FIX: Ã‰dition complÃ¨te du profil (nom, pseudo, bio)
  void _showEditProfileSheet(BuildContext context) {
    final nameCtrl = TextEditingController(text: _model.userProfile?['first_name'] as String? ?? '');
    final handleCtrl = TextEditingController(text: _model.userProfile?['handle'] as String? ?? '');
    final bioCtrl = TextEditingController(text: _model.userProfile?['bio'] as String? ?? '');

    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          bool isSaving = false;
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: LiquidGlassTokens.pageDark,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Text('Modifier le profil', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Text('PrÃ©nom', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  _buildEditField(nameCtrl, 'Votre prÃ©nom', IconlyLight.profile),
                  const SizedBox(height: 16),
                  Text('Pseudo', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  _buildEditField(handleCtrl, 'votre_pseudo', IconlyLight.user1, prefix: '@'),
                  const SizedBox(height: 16),
                  Text('Bio', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: TextField(
                      controller: bioCtrl,
                      style: GoogleFonts.poppins(color: Colors.white),
                      maxLines: 3,
                      maxLength: 150,
                      decoration: InputDecoration(
                        hintText: 'Parlez de vous en quelques motsâ€¦',
                        hintStyle: GoogleFonts.poppins(color: Colors.white38),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(12),
                        counterStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        setModal(() => isSaving = true);
                        try {
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          if (uid != null) {
                            final newHandle = handleCtrl.text.trim().replaceAll('@', '').toLowerCase();
                            await FirebaseFirestore.instance.collection('users').doc(uid).update({
                              'first_name': nameCtrl.text.trim(),
                              'display_name': nameCtrl.text.trim(),
                              if (newHandle.isNotEmpty) 'handle': newHandle,
                              'bio': bioCtrl.text.trim(),
                            });
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          _model.loadFavourites();
                          _loadWishlists();
                        } catch (_) {
                          setModal(() => isSaving = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: violetColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Sauvegarder', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditField(TextEditingController ctrl, String hint, IconData icon, {String? prefix}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(icon, color: Colors.white54, size: 18),
          if (prefix != null) ...[
            const SizedBox(width: 4),
            Text(prefix, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 15)),
          ],
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: ctrl,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.poppins(color: Colors.white38),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// DÃ©lÃ©guÃ© pour la tab bar sticky
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this.tabBar, {this.backgroundColor = Colors.white});

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
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}


