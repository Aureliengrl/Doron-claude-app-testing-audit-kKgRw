import '/components/aesthetic_bottom_sheet_notch.dart';
import '/utils/app_logger.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '/components/premium_3d_icon.dart';
import '/utils/iconly_compat.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '/components/floating_cta_button.dart';
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
import '/utils/app_tr.dart';

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

  // Cette page reste en mémoire (Offstage) tant que la NavBarPage n'est pas
  // recréée : sans ce listener, changer de compte depuis le menu "Se connecter
  // à un autre compte" laissait affichées les données de l'ancien compte.
  StreamSubscription<User?>? _authSub;
  String? _lastLoadedUid;

  @override
  void initState() {
    super.initState();
    _model = UserProfileModel();
    _tabController = TabController(length: 2, vsync: this);

    _lastLoadedUid = FirebaseAuth.instance.currentUser?.uid;

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

    // Recharger tout le profil si l'utilisateur connecté change (changement
    // de compte) pendant que cette page reste montée en arrière-plan.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user?.uid != _lastLoadedUid) {
        _lastLoadedUid = user?.uid;
        _reloadForAccountSwitch();
      }
    });
  }

  Future<void> _reloadForAccountSwitch() async {
    if (!mounted) return;
    setState(() {
      _wishlists = [];
      _wishlistsLoading = true;
      _friendsCount = 0;
      _localProfilePhoto = null;
      _uploadedPhotoUrl = null;
    });
    await _checkAnonymousMode();
    _loadWishlists();
    _loadFriendsCount();
    if (mounted && !_isAnonymous) {
      _model.loadFavourites();
    }
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
    _authSub?.cancel();
    _model.removeListener(_onModelChanged);
    _tabController.dispose();
    _model.dispose();
    super.dispose();
  }

  // âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬ Changement de photo de profil âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬

  /// Chemin local affiché immédiatement avant que l'upload termine.
  File? _localProfilePhoto;

  /// URL CDN mémorisée après upload âà¢ââ‚¬Å¡Ã‚Â¬à¢â"šÂ¬Ã‚Â affichée même si AuthUserStream
  /// n'est pas encore rafraîchi (évite le délai de latence).
  String? _uploadedPhotoUrl;

  /// Fallback avatar (initiales / icône)
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

    // âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬ Affichage OPTIMISTE IMMÉDIAT âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬
    if (mounted) setState(() { _localProfilePhoto = file; _uploadedPhotoUrl = null; });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Sauvegarde de la photo...', style: GoogleFonts.outfit()),
        backgroundColor: LiquidGlassTokens.pageDark,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));
    }

    OptimisticImageUploader.upload(
      localPath: pickedFile.path,
      storagePath: 'users/$uid/profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      onUploadComplete: (downloadUrl) async {
        bool saved = false;
        try {
          // âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬ Écriture ATOMIQUE : photo_url + photoUrl en un seul update âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬
          // Synchronise les deux champs -> tous les lecteurs voient la photo
          // immédiatement (public_profile_page, friend_service, etc.)
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
          saved = true;
        } catch (e) {
          AppLogger.error('Profile photo Firestore/Auth sync failed', 'Profile', e);
        }

        if (mounted) {
          setState(() {
            _localProfilePhoto = null;
            _uploadedPhotoUrl  = saved ? downloadUrl : null; // n'affiche pas une photo non enregistrée
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              saved ? 'Photo de profil mise à jour ✨' : 'Photo envoyée mais non enregistrée, réessaie',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: saved ? const Color(0xFF8A2BE2) : const Color(0xFFE53935),
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

    final isMe = true;

    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                _buildAppBar(),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      indicatorColor: pinkColor,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white54,
                      indicatorSize: TabBarIndicatorSize.label,
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(
                          icon: const Icon(Icons.card_giftcard, size: 22),
                          text: context.tr('Listes de cadeaux', 'Gift lists'),
                        ),
                        Tab(
                          icon: const Icon(IconlyBold.heart, size: 22),
                          text: context.tr('Coups de coeur', 'Favourites'),
                        ),
                      ],
                    ),
                    backgroundColor: LiquidGlassTokens.pageDark,
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.only(top: 16),
                      sliver: _buildWishlistsSliver(),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 140)),
                  ],
                ),
                CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.only(top: 16),
                      sliver: _buildLikedProductsSliver(),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 140)),
                  ],
                ),
              ],
            ),
          ),
          
          if (isMe)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: FloatingCtaButton(
                title: context.tr('Créer un album', 'Create album'),
                icon: Icons.add_rounded,
                onTap: () async {
                  final created = await _showCreateAlbumDialog();
                  if (created == true) setState(() {});
                },
              ),
            ),
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
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                _buildAppBar(),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      indicatorColor: pinkColor,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white54,
                      indicatorSize: TabBarIndicatorSize.label,
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(
                          icon: const Icon(Icons.card_giftcard, size: 22),
                          text: context.tr('Listes de cadeaux', 'Gift lists'),
                        ),
                        Tab(
                          icon: const Icon(IconlyBold.heart, size: 22),
                          text: context.tr('Coups de coeur', 'Favourites'),
                        ),
                      ],
                    ),
                    backgroundColor: LiquidGlassTokens.pageDark,
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.only(top: 16),
                      sliver: _buildWishlistsSliver(),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 140)),
                  ],
                ),
                CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.only(top: 16),
                      sliver: _buildLikedProductsSliver(),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 140)),
                  ],
                ),
              ],
            ),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // En-tête gauche (Style Instagram)
                        GestureDetector(
                          onTap: () {
                             HapticFeedback.lightImpact();
                             _showAccountSwitcherBottomSheet(context);
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Builder(
                                builder: (context) {
                                  final handle = _model.userProfile?['handle'] as String?;
                                  final display = handle != null && handle.isNotEmpty ? '@$handle' : 'Profil';
                                  
                                  return Text(
                                    display,
                                    style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 4),
                              const Icon(IconlyLight.arrowDown, color: Colors.white, size: 20),
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEC4899),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Boutons d'action droite
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        // à°Ã…Â¸ââ‚¬Âââ‚¬Â Bouton notifications avec badge
                        IconButton(
                          icon: const Icon(
                            IconlyLight.setting,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            _showSettingsBottomSheet(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                    Row(
                      children: [
                        // Photo de profil
                        Stack(
                          children: [
                            Container(
                              width: 110,
                              height: 110,
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
                                // âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬ Avatar optimiste âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬
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
                            // Badge modifier removed
                          ],
                        ),
                        const SizedBox(width: 24),
                        // Stats âà¢ââ‚¬Å¡Ã‚Â¬à¢â"šÂ¬Ã‚Â Amis / Wishlists / Cadeaux
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildProfileStat(context.tr('Amis', 'Friends'), '$_friendsCount'),
                              _buildProfileStat(context.tr('Wishlists', 'Wishlists'), '${_wishlists.length}'),
                              _buildProfileStat(context.tr('Cadeaux', 'Gifts'), '${_model.favourites.length}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Bio
                    if (_model.userProfile?['bio'] != null && _model.userProfile!['bio'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
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
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                            onTap: () {
                               _showEditProfileSheet(context);
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(IconlyLight.editSquare, color: Colors.white, size: 22),
                                const SizedBox(height: 6),
                                Text(
                                  'Modifier',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LiquidGlassCard(
                            blur: LiquidGlassTokens.blurLight,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                            onTap: () => context.push('/friends'),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(IconlyLight.user2, color: Colors.white, size: 22),
                                const SizedBox(height: 6),
                                Text(
                                  'Amis',
                                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LiquidGlassCard(
                            blur: LiquidGlassTokens.blurLight,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                            onTap: () {
                               _shareProfile();
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(IconlyLight.send, color: Colors.white, size: 22),
                                const SizedBox(height: 6),
                                Text(
                                  'Partager',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                              ],
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
                  // FIX C14: nom plus clair pour les wishlists partagées
                  Text(context.tr('Listes de cadeaux', 'Gift lists')),
                ],
              ),
            ),
            Tab(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(IconlyBold.heart),
                  const SizedBox(width: 8),
                  // FIX C14: nom plus clair pour les coups de cœur privés
                  Text(context.tr('Coups de cœur', 'Favourites')),
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

  Widget _buildWishlistsSliver() {
    if (_wishlistsLoading) {
      return const SliverToBoxAdapter(child: Center(child: LiquidGlassLoader(size: 40)));
    }
    
    final wishlists = _wishlists;

    if (wishlists.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Icon(IconlyLight.bookmark, size: 60, color: Colors.white.withOpacity(0.35)),
              const SizedBox(height: 16),
              Text('Aucune wishlist', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.7))),
              const SizedBox(height: 8),
              Text('Crée des wishlists pour organiser tes cadeaux', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500])),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
              _loadWishlists();
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
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
    );
  }

  Widget _buildLikedProductsSliver() {
    if (_model.isLoading) {
      return const SliverToBoxAdapter(
        child: Center(
          child: LiquidGlassLoader(size: 32),
        ),
      );
    }

    if (_model.favourites.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Icon(
                IconlyLight.heart,
                size: 60,
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: ReorderableGridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
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
                Icon(IconlyLight.bookmark, size: 80, color: Colors.white.withOpacity(0.35)),
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
            // 🎯 Bouton Créer un album 🎯
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: FloatingCtaButton(
                title: context.tr('Créer un album', 'Create album'),
                icon: Icons.add_rounded,
                onTap: () async {
                  final created = await _showCreateAlbumDialog();
                  if (created == true) setState(() {});
                },
              ),
            ),
          ],
        );
  }

  /// Dialog de création d'un nouvel album (wishlist)
  Future<bool?> _showCreateAlbumDialog() async {
    final nameController = TextEditingController();
    final emojiController = TextEditingController(text: '🎁');
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
              Text(context.tr('Nouvel album', 'New album'), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
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
                  hintText: context.tr('Nom de l\'album (ex : pour Noël)', 'Album name (e.g. for Christmas)'),
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
                  hintText: context.tr('Emoji (optionnel)', 'Emoji (optional)'),
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
              child: Text(context.tr('Annuler', 'Cancel'), style: GoogleFonts.poppins(color: Colors.white54)),
            ),
            TextButton(
              onPressed: isCreating
                  ? null
                  : () {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;
                      final emoji = emojiController.text.trim().isEmpty ? '🎁' : emojiController.text.trim();

                      // âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬ OPTIMISTIC UI :
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
              child: Text(context.tr('Créer', 'Create'), style: GoogleFonts.poppins(color: const Color(0xFF8A2BE2), fontWeight: FontWeight.w700)),
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
      SnackBar(content: Text(context.tr('Upload de la couverture en cours...', 'Uploading cover...'))),
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
        const SnackBar(content: Text('✅ Couverture mise à jour !')),
      );

      // Mettre à jour immédiatement en mémoire + vider le cache image
      setState(() {
        final idx = _wishlists.indexWhere((w) => w['id'] == wishlistId);
        if (idx != -1) {
          _wishlists[idx] = {..._wishlists[idx], 'coverPhoto': downloadUrl};
        }
      });

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Erreur lors de l\'upload: $e', 'Upload error: $e'))),
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
                        if (wishlist['description'] != null && wishlist['description'].toString().isNotEmpty)
                          Text(
                            wishlist['description'].toString(),
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white54),
                          ),
                        Text(
                          '${sheetProducts.length} ${context.tr(sheetProducts.length > 1 ? 'articles' : 'article', sheetProducts.length > 1 ? 'items' : 'item')}',
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
                              Text(context.tr('Photo', 'Photo'), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF00D4FF))),
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
  /// âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬ Upload OPTIMISTE : la photo s'affiche immédiatement en local,
  ///   l'upload Firebase se fait en arrière-plan.
  Future<Map<String, dynamic>?> _addPhotoToAlbum(
    String wishlistId, {
    /// Callback appelé quand l'URL Firebase est disponible (mise à jour en arrière-plan)
    void Function(String photoId, String firebaseUrl, String price)? onUploaded,
  }) async {
    // âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬ 1. Choix de la source âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬
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
              title: Text(context.tr('Depuis la galerie', 'From gallery'), style: GoogleFonts.poppins(color: Colors.white)),
              onTap: () { source = ImageSource.gallery; Navigator.pop(ctx); },
            ),
            ListTile(
              leading: const Icon(IconlyBold.camera, color: Color(0xFF00D4FF)),
              title: Text(context.tr('Prendre une photo', 'Take a photo'), style: GoogleFonts.poppins(color: Colors.white)),
              onTap: () { source = ImageSource.camera; Navigator.pop(ctx); },
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return null;

    // âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬ 2. Sélection de la photo âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬
    final picked = source == ImageSource.gallery
        ? await PhotoPermissionService.pickFromGallery(context, imageQuality: 80)
        : await PhotoPermissionService.pickFromCamera(context, imageQuality: 80);
    if (picked == null || !mounted) return null;

    // âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬ 3. Dialog Nom + Prix âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬
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
            Text('Détails (optionnel)', style: GoogleFonts.poppins(
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

    // âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬ 4. Affichage OPTIMISTE immédiat (fichier local) âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final localPath = picked.path;
    final optimisticEntry = {
      'id': tempId,
      'type': 'photo',
      'image': localPath,      // chemin fichier local âà¢ââ‚¬Å¡Ã‚Â¬à¢â"šÂ¬Ã‚Â PhotoItemCard le gère
      'caption': caption,
      'price': price,
      'url': '',
      '_isUploading': true,    // flag pour indicateur discret
    };

    // âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬ 5. Upload en arrière-plan âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬
    FirebaseDataService.addPhotoToWishlist(
      wishlistId,
      localPath,
      caption: caption.isEmpty ? null : caption,
      productName: caption.isEmpty ? null : caption,
      productPrice: price.isEmpty ? null : price,
    ).then((ok) {
      if (!mounted) return;
      if (!ok) {
        // L'écriture Firestore a échoué : la photo n'est pas réellement
        // sauvegardée (elle ne survivrait pas à un changement d'appareil).
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Échec de l\'enregistrement de la photo, réessaie', style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ));
        return;
      }
      // Snack discret de confirmation
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('📸 Photo ajoutée !', style: GoogleFonts.poppins(
            color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ));
    });

    // Retourner l'entrée optimiste âà¢ââ‚¬Å¡Ã‚Â¬à¢â"šÂ¬Ã‚Â la grille l'affiche immédiatement
    return optimisticEntry;
  }
  // âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬ Gamification & Stats âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬
  // Removed "Ton activité" and "Badges" per user request.

  // âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬ Actions & Modals âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬
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

  // âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬ Paramètres âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬âà¢â"šÂ¬Ã‚Âà¢ââ‚¬Å¡Ã‚Â¬
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
              Text('Paramètres', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              LiquidGlassSurface(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(IconlyLight.filter, color: Colors.white),
                      title: Text('Modifier mes préférences (IA)', style: GoogleFonts.outfit(color: Colors.white)),
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

  // BUG 9 FIX: Suppression du compte (Firebase Auth uniquement)
  Future<void> _deleteAccount(BuildContext context) async {
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer le compte', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Cette action est irréversible. Votre compte sera définitivement supprimé.',
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
        content: Text('Êtes-vous ABSOLUMENT sûr ? Vous ne pourrez plus récupérer votre compte.', style: GoogleFonts.poppins(color: Colors.white70)),
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

  // BUG 8 FIX: Édition complète du profil (nom, pseudo, bio)
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
                  
                  const SizedBox(height: 20),
                  Text(context.tr('Modifier le profil', 'Edit profile'), style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  // Section Photo de profil
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        await _changeProfilePicture();
                        setModal(() {});
                      },
                      child: Stack(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                            ),
                            child: ClipOval(
                              child: _localProfilePhoto != null
                                  ? Image.file(_localProfilePhoto!, fit: BoxFit.cover)
                                  : _uploadedPhotoUrl != null
                                      ? CachedNetworkImage(imageUrl: _uploadedPhotoUrl!, fit: BoxFit.cover)
                                      : (currentUserPhoto?.isNotEmpty == true
                                          ? CachedNetworkImage(imageUrl: currentUserPhoto!, fit: BoxFit.cover)
                                          : _buildAvatarFallback()),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: violetColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: LiquidGlassTokens.pageDark, width: 2),
                              ),
                              child: const Icon(IconlyLight.camera, size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Pseudo', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  _buildEditField(nameCtrl, 'Ton pseudo', IconlyLight.profile),
                  const SizedBox(height: 16),
                  Text('Nom d\'utilisateur', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  _buildEditField(handleCtrl, 'nom_utilisateur', IconlyLight.profile, prefix: '@'),
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
                        hintText: 'Parlez de vous en quelques mots...',
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

  void _showAccountSwitcherBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: LiquidGlassTokens.pageDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text('Changer de compte', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Compte actuel
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: currentUserPhoto?.isNotEmpty == true ? CachedNetworkImageProvider(currentUserPhoto!) : null,
                      child: currentUserPhoto?.isEmpty ?? true ? const Icon(IconlyLight.profile, color: Colors.white, size: 20) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(currentUserDisplayName.isNotEmpty ? currentUserDisplayName : 'Utilisateur', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                          if (_model.userProfile?['handle'] != null)
                            Text('@${_model.userProfile!['handle']}', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle, color: Color(0xFF8A2BE2), size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Action Se déconnecter pour changer
              InkWell(
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(ctx);
                  await authManager.signOut();
                  if (context.mounted) {
                    context.go('/authentification');
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text('Se connecter à un autre compte', style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
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





