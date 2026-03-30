import '/utils/app_logger.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '/components/cached_image.dart';
import '/components/aesthetic_buttons.dart';
import '/components/micro_interactions.dart' as micro;
import '/components/liquid_glass.dart';
import '/services/product_url_service.dart';
import '/services/firebase_data_service.dart';
import '/backend/backend.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/utils/pdf_export_utils.dart';
import 'search_page_model.dart';
export 'search_page_model.dart';
import 'user_search_bottom_sheet.dart';
import 'share_list_bottom_sheet.dart';
import '/components/liquid_glass_empty_state_widget.dart';
import '/components/liquid_glass_loader.dart';
import '/components/product_detail_modal.dart';
import '/services/friend_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class SearchPageWidget extends StatefulWidget {
  const SearchPageWidget({super.key});

  static String routeName = 'SearchPage';
  static String routePath = '/search-page';

  @override
  State<SearchPageWidget> createState() => _SearchPageWidgetState();
}

class _SearchPageWidgetState extends State<SearchPageWidget> {
  late SearchPageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final Color violetColor = const Color(0xFF8A2BE2);
  bool _searchReorderMode = false;

  @override
  void initState() {
    super.initState();
    _model = SearchPageModel();
    _loadData();
  }

  Future<void> _loadData() async {
    await _model.loadProfiles();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Afficher une erreur si le chargement a échoué
    if (_model.errorMessage != null) {
      return Scaffold(
        key: scaffoldKey,
        backgroundColor: LiquidGlassTokens.pageDark,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 24),
                Text(
                  'Erreur',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _model.errorMessage!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.55),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 200,
                  child: PrimaryGradientButton(
                    onPressed: () => _loadData(),
                    text: 'Réessayer',
                    icon: Icons.refresh,
                    gradientColors: const [Color(0xFF8A2BE2), Color(0xFFEC4899)],
                    height: 50,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Afficher un indicateur de chargement si les données sont en cours de chargement
    if (_model.isLoading) {
      return Scaffold(
        key: scaffoldKey,
        backgroundColor: LiquidGlassTokens.pageDark,
        body: Center(
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
                        colors: [Color(0xFF8A2BE2), Color(0xFFEC4899)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: violetColor.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person_search,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                micro.ShimmerEffect(
                  child: Text(
                    'Chargement...',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.55),
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

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: LiquidGlassTokens.pageDark,
      body: Stack(
        children: [
          // Contenu principal scrollable avec physics premium
          CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // Header violet arrondi
              SliverToBoxAdapter(child: _buildHeader()),

              // Message de bienvenue
              SliverToBoxAdapter(child: _buildWelcomeMessage()),

              // Profils en scroll horizontal + Bouton ajouter
              SliverToBoxAdapter(child: _buildProfilesRow()),

              // Info sur la personne sélectionnée
              if (_model.currentProfile != null)
                SliverToBoxAdapter(child: _buildProfileInfo()),

              // Grille de produits
              _buildProductsGrid(),

              // Section Suggestions (après les cadeaux sauvegardés)
              if (_model.currentProfile != null && _model.getFilteredProducts().isNotEmpty)
                _buildSuggestionsSection(),

              // Espacement pour le CTA fixe en bas + bottom nav
              const SliverToBoxAdapter(child: SizedBox(height: 180)),
            ],
          ),

          // CTA fixe en bas de l'écran
          Positioned(
            bottom: 90,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    LiquidGlassTokens.pageDark.withOpacity(0),
                    LiquidGlassTokens.pageDark.withOpacity(0.92),
                    LiquidGlassTokens.pageDark,
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: _buildBottomActions(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final topPadding = MediaQuery.of(context).padding.top;
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          height: 120 + topPadding,
          padding: EdgeInsets.only(top: topPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                violetColor.withOpacity(0.12),
                const Color(0xFFEC4899).withOpacity(0.06),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.10),
                width: 0.5,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recherche ✨',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Trouve le cadeau parfait',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.60),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white.withOpacity(0.85),
                    size: 26,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildWelcomeMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome,
            color: Color(0xFFFBBF24),
            size: 18,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Sélectionne une personne pour voir ses cadeaux',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.75),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilesRow() {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _model.profiles.length + 1, // +1 pour le bouton ajouter
        itemBuilder: (context, index) {
          // Bouton ajouter au dbut (gauche)
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.go('/onboarding-advanced?skipUserQuestions=true&returnTo=/search-page'),
                  borderRadius: BorderRadius.circular(50),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: violetColor.withOpacity(0.70),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.add,
                          color: violetColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ajouter',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: violetColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final profile = _model.profiles[index - 1];
          final profileId = profile['id'];
          final int profileIdInt = profileId is int ? profileId : (profileId as String).hashCode;
          final isSelected = _model.selectedProfileId == profileIdInt;

          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Dismissible(
              key: ValueKey(profileId),
              direction: DismissDirection.up,
              background: Container(
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.only(bottom: 8),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red.withOpacity(0.8),
                  size: 28,
                ),
              ),
              confirmDismiss: (direction) async {
                // Haptic feedback
                HapticFeedback.mediumImpact();

                return await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xEE1A0035),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.white.withOpacity(0.18)),
                    ),
                    title: Text(
                      'Supprimer cette personne ?',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    content: Text(
                      'Les cadeaux sauvegardés pour ${profile['name']} seront supprimés.',
                      style: GoogleFonts.poppins(fontSize: 15, color: Colors.white.withOpacity(0.80)),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          'Annuler',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.55),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          Navigator.pop(context, true);
                        },
                        child: Text(
                          'Supprimer',
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (direction) async {
                // Supprimer la personne de Firebase
                await FirebaseDataService.deletePerson(profileId.toString());

                // Supprimer du modéle local
                setState(() {
                  _model.profiles.removeAt(index);
                  if (_model.selectedProfileId == profileIdInt) {
                    _model.selectedProfileId = null;
                  }
                });

                // SnackBar de confirmation
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            '${profile['name']} supprimé(e)',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    // Premier setState pour sélectionner le profil
                    setState(() {
                      _model.selectedProfileId = profileIdInt;
                    });

                    // Charger les données (favoris + suggestions)
                    await _model.selectProfile(profileIdInt);

                    // Deuxiéme setState pour mettre à jour avec les suggestions
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  onLongPress: () => _showProfileAvatarOptions(context, profile),
                  borderRadius: BorderRadius.circular(50),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Color(int.parse(
                                  profile['color'].toString().replaceAll('#', '0xFF'))),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Color(int.parse(profile['color']
                                        .toString()
                                        .replaceAll('#', '0xFF')))
                                    : Colors.white,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? Color(int.parse(profile['color']
                                              .toString()
                                              .replaceAll('#', '0xFF')))
                                          .withOpacity(0.6)
                                      : Colors.black.withOpacity(0.1),
                                  blurRadius: isSelected ? 20 : 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            transform: isSelected
                                ? Matrix4.identity().scaled(1.05)
                                : Matrix4.identity(),
                            child: Center(
                              child: Text(
                                profile['initials'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          if (profile['chatId'] != null || profile['isShared'] == true)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8A2BE2),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: const Icon(Icons.people, size: 10, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profile['name'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? Color(int.parse(
                                  profile['color'].toString().replaceAll('#', '0xFF')))
                              : Colors.white,
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 1),
                              blurRadius: 3.0,
                              color: Colors.black.withOpacity(0.8),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileInfo() {
    final profile = _model.currentProfile!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Color(
                    int.parse(profile['color'].toString().replaceAll('#', '0xFF')))
                .withOpacity(0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(
                    int.parse(profile['color'].toString().replaceAll('#', '0xFF'))),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  profile['initials'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cadeaux pour ${profile['name']}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${profile['relation']} à ${profile['occasion']}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.55),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildProfileActionButton(
                        icon: Icons.ios_share,
                        label: 'Partager',
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          _showSnackBar('Génération du PDF en cours...', isError: false);
                          
                          // On récupère les cadeaux sauvegardés pour cette personne
                          final products = _model.getFilteredProducts(); 
                          
                          try {
                            await PdfExportUtils.generateAndShareWishlistPdf(
                              profile: profile,
                              products: products,
                            );
                          } catch (e) {
                            _showSnackBar('Erreur lors de la génération du PDF', isError: true);
                          }
                        },
                      ),
                      _buildProfileActionButton(
                        icon: Icons.edit_outlined,
                        label: 'Modifier',
                        onTap: () {
                          // Retourner au quizz avec l'ID du profil
                          context.go('/onboarding-advanced?skipUserQuestions=true&editProfileId=${profile['id']}&returnTo=/search-page');
                        },
                      ),
                      _buildProfileActionButton(
                        icon: Icons.group_add,
                        label: 'Collaborer',
                        onTap: () {
                           showModalBottomSheet(
                             context: context,
                             isScrollControlled: true,
                             backgroundColor: Colors.transparent,
                             builder: (context) => Padding(
                               padding: EdgeInsets.only(
                                 bottom: MediaQuery.of(context).viewInsets.bottom,
                                 top: MediaQuery.of(context).size.height * 0.2,
                               ),
                               child: ShareListBottomSheet(profile: profile),
                             ),
                           ).then((chatId) {
                             if (chatId != null && mounted) {
                               setState(() {
                                 profile['chatId'] = chatId;
                                 profile['isShared'] = true;
                               });
                             }
                           });
                        }
                      ),
                      if (profile['chatId'] != null)
                        _buildProfileActionButton(
                          icon: Icons.chat_bubble_outline,
                          label: 'Chat',
                          onTap: () {
                             context.push('/chat-room/${profile['chatId']}', extra: {
                               'id': profile['chatId'],
                               'name': 'Cadeaux pour ${profile['name']}',
                               'isGroup': true,
                             });
                          }
                        ),
                      _buildProfileActionButton(
                        icon: Icons.add_photo_alternate_rounded,
                        label: 'Photo',
                        onTap: () => _addPhotoForPerson(profile),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsGrid() {
    final products = _model.getFilteredProducts();

    // Si pas de profils du tout, afficher un message d'accueil
    if (_model.profiles.isEmpty) {
      return const SliverToBoxAdapter(
        child: LiquidGlassEmptyStateWidget(
          icon: Icons.person_add_alt_1,
          title: 'Ajoutez votre première personne',
          subtitle: 'Cliquez sur le bouton + pour ajouter ou rejoindre une liste existante et générer des idées de cadeaux personnalisées.',
        ),
      );
    }

    // Si profil sélectionné mais pas de produits, afficher message
    if (products.isEmpty) {
      return const SliverToBoxAdapter(
        child: LiquidGlassEmptyStateWidget(
          icon: Icons.card_giftcard,
          title: 'Aucun cadeau pour le moment',
          subtitle: 'Les cadeaux de cette personne apparaîtront ici. Générez des idées de cadeaux ou ajoutez-les manuellement.',
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        child: ReorderableGridView.count(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) async {
            HapticFeedback.mediumImpact();
            final profile = _model.currentProfile;
            if (profile == null) return;
            final personId = profile['id'].toString();
            setState(() {
              final item = _model.personGifts[personId]!.removeAt(oldIndex);
              _model.personGifts[personId]!.insert(newIndex, item);
            });
            try {
              await FirebaseDataService.saveGiftListForPerson(
                personId: personId,
                gifts: _model.personGifts[personId]!,
                listName: 'Liste réorganisée',
              );
            } catch (_) {}
          },
          children: [
            for (int i = 0; i < products.length; i++)
              _buildProductCard(products[i], key: ValueKey(products[i]['id'] ?? i.toString())),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, {Key? key}) {
    // Vérifier si ce produit est dans les favoris de cette personne (dans Firebase)
    final productName = product['name'] as String? ?? product['title'] as String? ?? '';
    final isLikedInFirebase = _model.isProductLiked(productName);
    final matchScore = product['match'] as int? ?? 0;

    return Material(
      key: key,
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showProductDetail(product),
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Colors.white.withOpacity(0.14), Colors.white.withOpacity(0.06)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image avec bouton coeur
              Stack(
                children: [
                  ProductImage(
                    imageUrl: product['image'] as String? ?? '',
                    height: 180,
                    fit: BoxFit.contain,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  // Match score badge (si >0)
                  if (matchScore > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF8A2BE2),
                              Color(0xFFEC4899),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8A2BE2).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.stars_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$matchScore%',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Bouton coeur - affiche rouge si déjà liké dans Firebase
                  if (isLikedInFirebase)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Marque en violet (sans le nom du produit)
                      if ((product['brand'] as String? ?? product['source'] as String? ?? '').isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8A2BE2).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF8A2BE2).withOpacity(0.4)),
                          ),
                          child: Text(
                            product['brand'] as String? ?? product['source'] as String? ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFB97EF8),
                            ),
                          ),
                        ),
                      const Spacer(),
                      // Prix (toujours en bas)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(
                          '${product['price']}€',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1,
                          ),
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
    ),
  ),
);
  }

  void _showProductDetail(Map<String, dynamic> product) {
    final isLiked = _model.likedProducts.contains(product['id']);

    final idRaw = product['id'];
    final productId = idRaw is int ? idRaw : (int.tryParse(idRaw.toString()) ?? 0);

    GlobalProductDetailModal.show(
      context,
      product,
      initialIsLiked: isLiked,
      onLikeToggled: () {
        if (mounted) {
          setState(() {
            _model.toggleLike(productId);
          });
        }
      },
    );  }

  Widget _buildSuggestionsSection() {
    final suggestions = _model.getSuggestions();
    final profile = _model.currentProfile;

    // Si en cours de chargement
    if (_model.isLoadingSuggestions) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                const LiquidGlassLoader(size: 32),
                const SizedBox(height: 16),
                Text(
                  'Génération de suggestions...',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.55),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Si aucune suggestion
    if (suggestions.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Séparateur
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.grey.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // En-téte de la section Suggestions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: const Color(0xFF8A2BE2),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suggestions pour ${profile!['name']}',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Basées sur tes choix et son profil',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Liste horizontale de suggestions
          SizedBox(
            height: 320,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildSuggestionCard(suggestion),
                );
              },
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> product) {
    final productName = product['name'] as String? ?? product['title'] as String? ?? '';
    final isLikedInFirebase = _model.isProductLiked(productName);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showProductDetail(product),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF8A2BE2).withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8A2BE2).withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image avec badge "Suggestion"
              Stack(
                children: [
                  ProductImage(
                    imageUrl: product['image'] as String? ?? '',
                    height: 180,
                    fit: BoxFit.contain,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  // Badge suggestion
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF8A2BE2),
                            Color(0xFFEC4899),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8A2BE2).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Suggestion',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Bouton coeur si liké
                  if (isLikedInFirebase)
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

              // Info produit
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product['brand'] as String? ?? product['source'] as String? ?? 'Amazon',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                          height: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${product['price']}€',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF8A2BE2),
                            ),
                          ),
                          // Bouton "+" pour ajout direct à wishlist
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showAddToWishlistDialog(product),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8A2BE2), Color(0xFFEC4899)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF8A2BE2).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
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

  Widget _buildBottomActions() {
    return Row(
      children: [
        // Bouton Messages/Chat (Rond)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              // TODO: Naviguer vers la vue Chat
              context.push('/chat-list');
            },
            borderRadius: BorderRadius.circular(30),
            child: Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        
        // Bouton Trouver des amis (navigue vers FriendsPage)
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.heavyImpact();
                context.push('/friends');
              },
              borderRadius: BorderRadius.circular(28),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8A2BE2), Color(0xFFEC4899)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8A2BE2).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_search_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'TROUVER DES AMIS',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Ajoute le produit directement à la liste des cadeaux de la personne
  Future<void> _showAddToWishlistDialog(Map<String, dynamic> product) async {
    final currentProf = _model.currentProfile;
    if (currentProf == null) {
      _showSnackBar('Aucune personne sélectionnée', isError: true);
      return;
    }

    final personId = currentProf['id'] as String;
    final personName = currentProf['name'] as String;
    final productName = product['name'] as String? ?? 'Produit';

    try {
      // Ajouter le cadeau directement à la liste de la personne
      final success = await FirebaseDataService.addGiftToPerson(
        personId: personId,
        gift: product,
      );

        if (success) {
          _showSnackBar('? $productName ajouté aux cadeaux de $personName');

          // Recharger les données pour mettre à jour l'affichage
          await _model.loadProfiles();
          if (mounted) {
            setState(() {});
          }
      } else {
        _showSnackBar('Ce cadeau est déjà dans la liste', isError: false);
      }
    } catch (e) {
      _showSnackBar('Erreur lors de l\'ajout: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red : const Color(0xFF8A2BE2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showUserSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const UserSearchBottomSheet();
      },
    );
  }
  void _showProfileAvatarOptions(BuildContext context, Map<String, dynamic> profile) {
    HapticFeedback.mediumImpact();
    final name = profile['name'] as String? ?? 'Personne';
    // Chercher si ce profil a un uid Firebase (personne réelle vs profil local)
    final uid = profile['uid'] as String?;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF16002E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Poignée
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(name, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            // Bouton Collaborer sur la liste (chat de groupe)
            _buildAvatarOption(
              icon: Icons.group_add,
              label: 'Collaborer sur la liste de cadeaux',
              onTap: () {
                Navigator.pop(ctx);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => Padding(
                    padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.2),
                    child: ShareListBottomSheet(profile: profile),
                  ),
                ).then((chatId) {
                  if (chatId != null && mounted) {
                    setState(() {
                      profile['chatId'] = chatId;
                      profile['isShared'] = true;
                    });
                    context.push('/chat-room/$chatId', extra: {
                      'name': 'Cadeaux pour $name',
                      'isGroup': true,
                    });
                  }
                });
              },
            ),
            if (uid != null) ...[
              const SizedBox(height: 12),
              _buildAvatarOption(
                icon: Icons.person_add_outlined,
                label: 'Ajouter en ami',
                onTap: () async {
                  Navigator.pop(ctx);
                  await FriendService.addFriend(profile);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name ajouté(e) en ami !', style: GoogleFonts.poppins()),
                        backgroundColor: const Color(0xFF8A2BE2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildAvatarOption(
                icon: Icons.chat_bubble_outline,
                label: 'Envoyer un message',
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final chatId = await FriendService.getOrCreateDirectChat(uid);
                    if (mounted) {
                      context.push('/chat-room/$chatId', extra: {'name': name, 'isGroup': false});
                    }
                  } catch (e) {
                    if (mounted) _showSnackBar('Impossible d\'ouvrir le chat', isError: true);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 14),
            Text(label, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  /// Ajoute une photo dans la wishlist d'une personne (page Recherche).
  Future<void> _addPhotoForPerson(Map<String, dynamic> profile) async {
    final personId = profile['id']?.toString() ?? '';
    final wishlists = await FirebaseDataService.loadWishlists(personId: personId);
    final personName = (profile["name"] as String?) ?? 'Personne';
    String wishlistId;
    if (wishlists.isEmpty) {
      final newId = await FirebaseDataService.createWishlist(
        name: 'Cadeaux pour $personName',
        emoji: '\uD83C\uDF81',
      );
      if (newId == null || !mounted) return;
      wishlistId = newId;
    } else {
      wishlistId = wishlists.first['id'] as String;
    }
    ImageSource? source;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF16002E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
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
        ]),
      ),
    );
    if (source == null || !mounted) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source!, imageQuality: 80, requestFullMetadata: false);
    if (picked == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
        const SizedBox(width: 12),
        Text('Upload en cours...', style: GoogleFonts.poppins(color: Colors.white)),
      ]),
      backgroundColor: const Color(0xFF0A1F3D), duration: const Duration(seconds: 10),
    ));
    final ok = await FirebaseDataService.addPhotoToWishlist(wishlistId, picked.path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? '\ud83d\udcf7 Photo ajout\u00e9e !' : 'Erreur upload', style: GoogleFonts.poppins(color: Colors.white)),
      backgroundColor: ok ? const Color(0xFF00D4FF).withOpacity(0.85) : Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
    if (ok && mounted) setState(() {});
  }
}
