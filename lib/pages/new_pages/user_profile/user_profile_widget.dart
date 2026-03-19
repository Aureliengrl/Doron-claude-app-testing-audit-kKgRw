import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'user_profile_model.dart';
import '/components/liquid_glass_loader.dart';
import 'dart:io';
import '/components/product_detail_modal.dart';
import '/components/shared_product_card.dart';
import '/utils/image_compress_utils.dart';
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

    // Vérifier le mode anonyme
    _checkAnonymousMode();
    // Charger les wishlists initiales + nb amis
    _loadWishlists();
    _loadFriendsCount();

    // Charger les favoris et le profil après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isAnonymous) {
        _model.loadFavourites();
      }
    });

    // écouter les changements du model
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

  // ─── Changement de photo de profil ──────────────────────────
  Future<void> _changeProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
      requestFullMetadata: false,
    );

    if (pickedFile == null) return;

    final file = File(pickedFile.path);

    if (currentUserReference == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: utilisateur non trouvé.', style: GoogleFonts.outfit()),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const LiquidGlassLoader(size: 24, isDark: false),
              const SizedBox(width: 16),
              Text('Mise à jour de la photo...', style: GoogleFonts.outfit()),
            ],
          ),
          backgroundColor: LiquidGlassTokens.pageDark,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users/${currentUserReference!.id}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg');
      // Compresser l'image avant l'upload
      final compressedFile = await ImageCompressUtils.compressImage(file);
      final fileToUpload = compressedFile ?? file;
      
      final uploadTask = await storageRef.putFile(fileToUpload);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      await currentUserReference!.update(createUsersRecordData(photoUrl: downloadUrl));

      if (mounted) {
        setState(() {}); // Rafraîchit l'UI (via AuthUserStreamWidget)
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo de profil mise à jour.', style: GoogleFonts.outfit()),
            backgroundColor: const Color(0xFF8A2BE2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du transfert ($e)', style: GoogleFonts.outfit()),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
          // App Bar avec photo de profil et bouton paramêtres
          _buildAppBar(),          // Tabs (Produits likés / Wishlists)
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
                    'Crée ton compte pour accéder à ton profil, tes produits likés et tes wishlists',
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
      expandedHeight: 220,
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
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
                              child: AuthUserStreamWidget(
                                builder: (context) => currentUserPhoto != null && currentUserPhoto!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: currentUserPhoto!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: LiquidGlassLoader(size: 16, isDark: false),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          color: violetColor.withOpacity(0.3),
                                          child: Icon(
                                            Icons.person,
                                            size: 40,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: violetColor.withOpacity(0.3),
                                        child: Icon(
                                          Icons.person,
                                          size: 40,
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
                      // Stats — Amis / Wishlists / Cadeaux
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
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (_model.userProfile?['handle'] != null)
                    Text(
                      '@${_model.userProfile!['handle']}',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  // Bio Moved directly under username/handle (it's already here but ensure it's below the stats)
                  if (_model.userProfile?['bio'] != null && _model.userProfile!['bio'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
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
                          },
                          child: Center(
                            child: Text(
                              'Modifier le profil',
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LiquidGlassCard(
                          blur: LiquidGlassTokens.blurLight,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          onTap: () => context.push('/friends'),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.people_outline, color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Amis',
                                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ],
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
                          },
                          child: Center(
                            child: Text(
                              'Partager',
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
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
          },
        ),
        IconButton(
          icon: const Icon(
            Icons.menu_rounded,
            color: Colors.white,
            size: 32,
          ),
          onPressed: () {
            _showSettingsBottomSheet(context);
          },
        ),
        const SizedBox(width: 8),
      ],
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
                  const Icon(Icons.list),
                  const SizedBox(width: 8),
                  Text('Wishlists'),
                ],
              ),
            ),
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
              Icons.favorite_border,
              size: 80,
              color: Colors.white.withOpacity(0.35),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun produit liké',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore l\'accueil et like tes produits préférés !',
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

    // ── Grille avec drag & drop natif (appui long) ─────────────────────
    return ReorderableListView(
      padding: const EdgeInsets.all(16),
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        HapticFeedback.mediumImpact();
        if (newIndex > oldIndex) newIndex -= 1;
        setState(() {
          final item = _model.favourites.removeAt(oldIndex);
          _model.favourites.insert(newIndex, item);
        });
      },
      children: [
        for (int i = 0; i < _model.favourites.length; i++)
          _buildLikedProductCard(_model.favourites[i], i),
      ],
    );
  }

  Widget _buildLikedProductCard(FavouritesRecord favourite, int index) {
    final productMap = {
      'id': favourite.reference.id,
      'name': favourite.product.productTitle,
      'brand': favourite.product.platform,
      'price': favourite.product.productPrice.replaceAll('€', '').trim(),
      'image': favourite.product.productPhoto,
      'url': favourite.product.productUrl,
    };
    return ReorderableDragStartListener(
      key: ValueKey(favourite.reference.id),
      index: index,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: 16,
          right: index.isEven ? 8 : 0,
          left: index.isEven ? 0 : 8,
        ),
        child: SharedProductCard(
          product: productMap,
          index: index,
          showWishlistButton: true,
          onRemove: null,
        ),
      ),
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
                Icon(Icons.bookmark_border, size: 80, color: Colors.white.withOpacity(0.35)),
                const SizedBox(height: 16),
                Text('Aucune wishlist', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.7))),
                const SizedBox(height: 8),
                Text('Crée des wishlists pour organiser tes cadeaux', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500])),
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
                    // Recharger la liste pour mettre à jour le compteur sur la pochette
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
                                  child: const Icon(Icons.add_a_photo, color: Colors.white, size: 16),
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
            // — Bouton Créer un album —
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
                      Text('Créer un album', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
  }

  /// Dialog de création d'un nouvel album (wishlist)
  Future<bool?> _showCreateAlbumDialog() async {
    final nameController = TextEditingController();
    final emojiController = TextEditingController(text: '🎁');
    bool isCreating = false;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A0030),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.bookmark_add_rounded, color: Color(0xFF8A2BE2), size: 24),
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
                  hintText: 'Nom de l\'album (ex : pour Noël)',
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
                      final emoji = emojiController.text.trim().isEmpty ? '🎁' : emojiController.text.trim();

                      // ── OPTIMISTIC UI :
                      // 1. Fermer le dialog immédiatement
                      Navigator.pop(ctx, true);

                      // 2. Ajouter localement pour affichage instantané
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

                      // 3. Créer en arrière-plan dans Firestore
                      FirebaseDataService.createWishlist(name: name, emoji: emoji).then((realId) {
                        if (realId != null && mounted) {
                          setState(() {
                            final idx = _wishlists.indexWhere((w) => w['id'] == tempId);
                            if (idx != -1) _wishlists[idx] = {...optimisticWishlist, 'id': realId};
                          });
                        }
                      });
                    },
              child: Text('Créer', style: GoogleFonts.poppins(color: const Color(0xFF8A2BE2), fontWeight: FontWeight.w700)),
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
          Icons.interests,
          size: 48,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  Future<void> _updateWishlistCover(String wishlistId) async {
    // 1. Pick an image
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70, requestFullMetadata: false);
    
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
        const SnackBar(content: Text('Couverture mise à jour avec succès!')),
      );

      // Refresh UI by triggering a rebuild
      setState(() {});

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

    // Normaliser les clés pour SharedProductCard (conserver le type pour routing photo/product)
    final normalizedProducts = products.map((p) => {
      'id': p['id'] ?? '',
      'type': p['type'] ?? 'product',  // phénomène clé pour le routing PhotoItemCard
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
              // Poignée
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              // En-tête
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
                              const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF00D4FF), size: 16),
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
                      Icon(Icons.favorite_border_rounded, size: 64, color: Colors.white.withOpacity(0.2)),
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
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: sheetProducts.length,
                  itemBuilder: (context, index) => SharedProductCard(
                    product: sheetProducts[index],
                    index: index,
                    showWishlistButton: false,
                  ),
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
  Future<Map<String, dynamic>?> _addPhotoToAlbum(String wishlistId) async {
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
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF00D4FF)),
              title: Text('Depuis la galerie', style: GoogleFonts.poppins(color: Colors.white)),
              onTap: () { source = ImageSource.gallery; Navigator.pop(ctx); },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF00D4FF)),
              title: Text('Prendre une photo', style: GoogleFonts.poppins(color: Colors.white)),
              onTap: () { source = ImageSource.camera; Navigator.pop(ctx); },
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return null;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source!, imageQuality: 80, requestFullMetadata: false);
    if (picked == null || !mounted) return null;
    // Légende optionnelle
    String caption = '';
    final captionCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0030),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Légende (optionnel)', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: captionCtrl, autofocus: true,
          style: GoogleFonts.poppins(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Ex : Pour Noël ✨',
            hintStyle: GoogleFonts.poppins(color: Colors.white38),
            filled: true, fillColor: Colors.white.withOpacity(0.07),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Passer', style: GoogleFonts.poppins(color: Colors.white54))),
          TextButton(
            onPressed: () { caption = captionCtrl.text.trim(); Navigator.pop(ctx); },
            child: Text('OK', style: GoogleFonts.poppins(color: const Color(0xFF00D4FF), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (!mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
        const SizedBox(width: 12),
        Text('Upload en cours...', style: GoogleFonts.poppins(color: Colors.white)),
      ]),
      backgroundColor: const Color(0xFF0A1F3D),
      duration: const Duration(seconds: 10),
    ));
    final ok = await FirebaseDataService.addPhotoToWishlist(wishlistId, picked.path, caption: caption.isEmpty ? null : caption);
    if (!mounted) return null;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur upload', style: GoogleFonts.poppins()), backgroundColor: Colors.red));
      return null;
    }
    final updated = await FirebaseDataService.loadWishlistProducts(wishlistId);
    final newest = updated.isNotEmpty ? updated.first : null;
    if (newest == null) return null;
    return {
      'id': newest['id'] ?? '',
      'type': 'photo',
      'image': newest['image'] ?? newest['imageUrl'] ?? '',
      'caption': newest['caption'] ?? caption,
      'url': '',
    };
  }
  // ─── Gamification & Stats ────────────────────────────────────────────────
  // Removed "Ton activité" and "Badges" per user request.

  // ─── Actions & Modals ──────────────────────────────────────────────────────
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
          content: Text('Lien copié ! $url', style: GoogleFonts.outfit()),
          backgroundColor: const Color(0xFF8A2BE2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
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
              Text('Paramètres', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
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
                        });
                      },
                    ),
                    Divider(color: Colors.white.withOpacity(0.1), height: 1),
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
                      },
                    ),
                    Divider(color: Colors.white.withOpacity(0.1), height: 1),
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
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              LiquidGlassPill(
                height: 56,
                activeColor: const Color(0xFFE53935),
                isActive: true,
                onTap: () async {
                  var confirmDialogResponse = await showDialog<bool>(
                        context: context,
                        builder: (alertDialogContext) {
                          return AlertDialog(
                            backgroundColor: const Color(0xFF1E1E1E),
                            title: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
                            content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?', style: TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(alertDialogContext, false),
                                child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(alertDialogContext, true),
                                child: const Text('Se déconnecter', style: TextStyle(color: Color(0xFFE53935))),
                              ),
                            ],
                          );
                        },
                      ) ?? false;

                  if (confirmDialogResponse) {
                    await authManager.signOut();

                    final prefs = await SharedPreferences.getInstance();
                    // On ne reset pas first_time_showcase, juste session
                    await prefs.remove('anonymous_mode');

                    if (context.mounted) {
                      context.go('/authentification');
                    }
                  }
                },
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
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
      },
    );
  }

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
    });
  }
}

// Délégué pour la tab bar sticky
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
