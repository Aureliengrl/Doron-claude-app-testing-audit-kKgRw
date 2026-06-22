import 'dart:ui';
import '/components/aesthetic_bottom_sheet_notch.dart';
import 'package:flutter/material.dart';
import '/components/premium_3d_icon.dart';
import '/utils/iconly_compat.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/components/cached_image.dart';
import '/components/aesthetic_buttons.dart';
import '/components/micro_interactions.dart' as micro;
import '/components/liquid_glass.dart';
import '/services/firebase_data_service.dart';
import '/services/optimistic_image_uploader.dart';
import '/backend/backend.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/utils/pdf_export_utils.dart';
import 'search_page_model.dart';
import '/utils/app_tr.dart';
export 'search_page_model.dart';
import 'package:doron/pages/new_pages/search_page/user_search_bottom_sheet.dart';
import 'share_list.dart';
import '/components/liquid_glass_empty_state_widget.dart';
import '/components/liquid_glass_loader.dart';
import '/components/product_detail_modal.dart';
import '/components/shared_product_card.dart';
import '/components/floating_cta_button.dart';
import '/services/friend_service.dart';
import '/services/gift_events_service.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class SearchPageWidget extends StatefulWidget {
  const SearchPageWidget({super.key});

  static String routeName = 'SearchPage';
  static String routePath = '/search-page';

  @override
  State<SearchPageWidget> createState() => _SearchPageWidgetState();
}

class _SearchPageWidgetState extends State<SearchPageWidget> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late SearchPageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final Color violetColor = const Color(0xFF8A2BE2);
  bool _searchReorderMode = false;
  StreamSubscription<GiftAddedEvent>? _giftEventSub;

  @override
  void initState() {
    super.initState();
    _model = SearchPageModel();
    _loadData();

    // Ã‰coute les cadeaux ajoutés depuis le modal produit (3 points â†’ "Ajouter pour quelqu'un")
    _giftEventSub = GiftEventsService.onGiftAdded.listen((event) {
      if (!mounted) return;
      // Injection optimiste en tête de liste sans recharger tous les profils
      setState(() {
        _model.personGifts[event.personId] ??= [];
        // Ã‰viter un doublon si le produit est déjà présent
        final alreadyPresent = _model.personGifts[event.personId]!
            .any((g) => g['id'] == event.gift['id']);
        if (!alreadyPresent) {
          _model.personGifts[event.personId]!.insert(0, event.gift);
        }
      });
    });
  }

  Future<void> _loadData() async {
    await _model.loadProfiles();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _giftEventSub?.cancel();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

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
                        IconlyLight.profile,
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
      body: RefreshIndicator(
        color: const Color(0xFF8A2BE2),
        backgroundColor: const Color(0xFF1A0030),
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          await _loadData();
        },
        child: Stack(
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
              if (_model.currentProfile != null) ...[
                SliverToBoxAdapter(child: _buildProfileInfo()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 0, bottom: 8, right: 24),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _addPhotoForPerson(_model.currentProfile!);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(IconlyLight.camera, color: Colors.white70, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Ajouter une photo',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],

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
          FloatingCtaButton(
            title: 'Secret Santa',
            subtitle: 'Créez un groupe pour Noël',
            onTap: () {
              HapticFeedback.heavyImpact();
              context.push('/secret-santa');
            },
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
                  context.tr('Recherche', 'Search'),
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
                context.tr('Trouvez le cadeau parfait pour vos proches', 'Find the perfect gift for your loved ones'),
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


  Widget _buildChatButtonWithBadge() {
    final uid = currentUserUid;

    return StreamBuilder<QuerySnapshot>(
      stream: uid.isNotEmpty
          ✨ FirebaseFirestore.instance
              .collection('chats')
              .where('participants', arrayContains: uid)
              .snapshots()
          : null,
      builder: (context, snapshot) {
        int unread = 0;
        if (snapshot.hasData && uid.isNotEmpty) {
          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final counts = data['unreadCount'] as Map<String, dynamic>?;
            if (counts != null && counts.containsKey(uid)) {
              final c = counts[uid];
              unread += (c is int ✨ c : (c is num ✨ c.toInt() : 0));
            }
          }
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              context.push('/chat-list');
            },
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
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
                    IconlyLight.chat,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                if (unread > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          unread > 99 ✨ '99+' : '$unread',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
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
          final int profileIdInt = profileId is int ✨ profileId : (profileId as String).hashCode;
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
                  IconlyLight.delete,
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
                      context.tr('Supprimer cette personne ?', 'Remove this person?'),
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
                // FIX: Soft-delete â€” suppression Firebase différée avec annulation
                final removedProfile = _model.profiles[index - 1];
                setState(() {
                  _model.profiles.removeAt(index - 1); // FIX: index-1 car index=0 = bouton "Ajouter"
                  if (_model.selectedProfileId == profileIdInt) {
                    _model.selectedProfileId = null;
                  }
                });
                bool cancelled = false;
                // Afficher snackbar avec annulation
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("${profile['name']} supprimé(e)", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    backgroundColor: Colors.red[700],
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 4),
                    action: SnackBarAction(label: context.tr('Annuler', 'Cancel'), textColor: Colors.white, onPressed: () {
                      cancelled = true;
                      setState(() { _model.profiles.insert(index - 1, removedProfile); _model.selectedProfileId = profileIdInt; });
                    }),
                  ));
                }
                await Future.delayed(const Duration(seconds: 4));
                if (!cancelled) await FirebaseDataService.deletePerson(profileId.toString());
                // Continuer si non annulé
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
                                    ✨ Color(int.parse(profile['color']
                                        .toString()
                                        .replaceAll('#', '0xFF')))
                                    : Colors.white,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ✨ Color(int.parse(profile['color']
                                              .toString()
                                              .replaceAll('#', '0xFF')))
                                          .withOpacity(0.6)
                                      : Colors.black.withOpacity(0.1),
                                  blurRadius: isSelected ✨ 20 : 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            transform: isSelected
                                ✨ Matrix4.identity().scaled(1.05)
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
                                child: const Icon(IconlyLight.user2, size: 10, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profile['name'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: isSelected ✨ FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ✨ Color(int.parse(
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
                    '${context.tr('Cadeaux pour ', 'Gifts for ')}${profile['name']}',
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
                        icon: IconlyBold.send,
                        label: context.tr('Partager', 'Share'),
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          _showSnackBar(context.tr('Génération du PDF en cours...', 'Generating PDF...'), isError: false);
                          
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
                        icon: IconlyLight.edit,
                        label: context.tr('Modifier', 'Edit'),
                        onTap: () {
                          // Retourner au quizz avec l'ID du profil
                          context.go('/onboarding-advanced?skipUserQuestions=true&editProfileId=${profile['id']}&returnTo=/search-page');
                        },
                      ),
                      _buildProfileActionButton(
                        // FIX C8: label change si collab déjà active
                        icon: (profile['isShared'] == true || profile['chatId'] != null)
                            ✨ IconlyBold.addUser
                            : IconlyLight.addUser,
                        label: (profile['isShared'] == true || profile['chatId'] != null)
                            ✨ context.tr('Ma collab', 'My collab')
                            : context.tr('Collaborer', 'Collaborate'),
                        onTap: () {
                           // #FIX-9: ne pas ouvrir si aucun cadeau ajouté
                           final profileId = profile['id']?.toString() ✨ profile['personId']?.toString() ✨ '';
                           final giftsList = _model.personGifts[profileId] ✨ [];
                           if (giftsList.isEmpty) {
                             HapticFeedback.lightImpact();
                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                               content: Text('Ajoutez d\'abord des idées cadeaux pour partager !', style: GoogleFonts.poppins(fontSize: 13)),
                               backgroundColor: const Color(0xFFF59E0B),
                               behavior: SnackBarBehavior.floating,
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                               margin: const EdgeInsets.all(12),
                             ));
                             return;
                           }
                           showModalBottomSheet(
                             context: context,
                             isScrollControlled: true,
                             backgroundColor: Colors.transparent,
                             builder: (context) => Padding(
                               padding: EdgeInsets.only(
                                 bottom: MediaQuery.of(context).viewInsets.bottom,
                                 top: MediaQuery.of(context).size.height * 0.2,
                               ),
                               child: ShareListBottomSheet(profile: profile), // bypassed ShareListBottomSheet
                             ),
                           ).then((chatId) {
                             if (chatId != null && mounted) {
                               final personId = profile['id']?.toString() ✨ '';
                               setState(() {
                                 profile['chatId'] = chatId;
                                 profile['isShared'] = true;
                               });
                               // FIX C6: Persister dans Firebase pour survivre au redémarrage
                               if (personId.isNotEmpty) {
                                 FirebaseDataService.updatePersonMeta(personId, {
                                   'chatId': chatId,
                                   'isShared': true,
                                 });
                               }
                             }
                           });
                        }
                      ),
                      // FIX C1: afficher si chatId présent OU isShared=true
                      if (profile['chatId'] != null || profile['isShared'] == true)
                        _buildProfileActionButton(
                          icon: IconlyLight.chat,
                          label: 'Chat',
                          onTap: () {
                             context.push('/chat-room/${profile['chatId']}', extra: {
                               'id': profile['chatId'],
                               'name': '${context.tr('Cadeaux pour ', 'Gifts for ')}${profile['name']}',
                               'isGroup': true,
                             });
                          }
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
          icon: IconlyLight.addUser,
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
            // FIX: utiliser updateGiftOrderForPerson au lieu de saveGiftListForPerson
            // pour modifier la liste existante et non en créer une nouvelle à chaque drag
            try {
              await FirebaseDataService.updateGiftOrderForPerson(
                personId: personId,
                gifts: _model.personGifts[personId]!,
              );
            } catch (_) {}
          },
          children: [
            for (int i = 0; i < products.length; i++)
              SharedProductCard(
                key: ValueKey(products[i]['id']?.toString() ✨ 'product_$i'),
                product: products[i],
                index: i + 1,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPhotoCard(Map<String, dynamic> profile) {
    return Material(
      color: Colors.transparent,
      key: const ValueKey('add_photo_button'),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _addPhotoForPerson(profile);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white38, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(IconlyLight.camera, color: Colors.white70, size: 40),
              const SizedBox(height: 8),
              Text(
                'Ajouter photo',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductDetail(Map<String, dynamic> product) {
    final isLiked = _model.likedProducts.contains(product['id']);

    final idRaw = product['id'];
    final productId = idRaw is int ✨ idRaw : (int.tryParse(idRaw.toString()) ✨ 0);

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
                  IconlyLight.infoSquare,
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
    return SizedBox(
      width: 160,
      child: SharedProductCard(
        product: product,
        index: 0,
      ),
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
    final productName = product['name'] as String? ✨ 'Produit';

    try {
      // Ajouter le cadeau directement à la liste de la personne
      final success = await FirebaseDataService.addGiftToPerson(
        personId: personId,
        gift: product,
      );

        if (success) {
          _showSnackBar('$productName ajouté aux cadeaux de $personName');

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
              isError ✨ Icons.error_outline : Icons.check_circle,
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
        backgroundColor: isError ✨ Colors.red : const Color(0xFF8A2BE2),
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
    final name = profile['name'] as String? ✨ 'Personne';
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
            const AestheticBottomSheetNotch(),
            Text(name, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            // Bouton Collaborer sur la liste (chat de groupe)
            _buildAvatarOption(
              icon: IconlyLight.addUser,
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
                      'name': context.tr('Cadeaux pour ', 'Gifts for ') + (profile['name'] as String? ✨ ''),
                      'isGroup': true,
                    });
                  }
                });
              },
            ),
            if (uid != null) ...[
              const SizedBox(height: 12),
              _buildAvatarOption(
                icon: IconlyLight.addUser,
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
                icon: IconlyLight.chat,
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

  /// Ajoute une photo dans la liste de cadeaux d'une personne (page Recherche).
  /// â”€ Stocke dans : users/{uid}/people/{personId}/gift_lists/   (même endroit que les autres cadeaux)
  /// â”€ NE passe plus par les wishlists albums (comportement précédent incorrect)
  Future<void> _addPhotoForPerson(Map<String, dynamic> profile) async {
    final personId = profile['id']?.toString() ✨ '';
    final personName = (profile['name'] as String?) ✨ 'Personne';
    if (personId.isEmpty) return;

    // â”€â”€ 1. Choix de la source image â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
            leading: const Icon(IconlyLight.image, color: Color(0xFF00D4FF)),
            title: Text('Depuis la galerie', style: GoogleFonts.poppins(color: Colors.white)),
            onTap: () { source = ImageSource.gallery; Navigator.pop(ctx); },
          ),
          ListTile(
            leading: const Icon(IconlyBold.camera, color: Color(0xFF00D4FF)),
            title: Text('Prendre une photo', style: GoogleFonts.poppins(color: Colors.white)),
            onTap: () { source = ImageSource.camera; Navigator.pop(ctx); },
          ),
        ]),
      ),
    );
    if (source == null || !mounted) return;

    // â”€â”€ 2. Sélection de la photo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source!, imageQuality: 60, maxWidth: 1200, maxHeight: 1200, requestFullMetadata: false); // FIX P1-C: qualit\u00e9 r\u00e9duite + contrainte taille â†’ 3x plus rapide
    if (picked == null || !mounted) return;

    // â”€â”€ 3. Dialog Nom + Prix â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    String productName = '';
    String productPrice = '';
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0030),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(IconlyLight.ticket, color: Color(0xFF8A2BE2), size: 20),
          const SizedBox(width: 8),
          Text('Détails du produit', style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nameCtrl,
            autofocus: true,
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Nom du produit',
              hintStyle: GoogleFonts.poppins(color: Colors.white38),
              prefixIcon: const Icon(IconlyLight.buy, color: Color(0xFF00D4FF), size: 18),
              filled: true,
              fillColor: Colors.white.withOpacity(0.07),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Prix (ex: 29.99)',
              hintStyle: GoogleFonts.poppins(color: Colors.white38),
              prefixIcon: const Icon(Icons.euro_rounded, color: Color(0xFFF59E0B), size: 18),
              filled: true,
              fillColor: Colors.white.withOpacity(0.07),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('Annuler', 'Cancel'), style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              productName = nameCtrl.text.trim();
              productPrice = priceCtrl.text.trim();
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8A2BE2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(context.tr('Ajouter', 'Add'), style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
    priceCtrl.dispose();
    if (confirmed != true || !mounted) return;

    // â”€â”€ 4. Construction du gift local â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final photoId = 'photo_${DateTime.now().millisecondsSinceEpoch}';
    final photoGiftLocal = {
      'id': photoId,
      'type': 'photo',
      'name': productName.isNotEmpty ✨ productName : 'Photo',
      'image': picked.path,    // chemin local â€” affiché immédiatement
      'price': productPrice,
      'caption': productName,
      'brand': '',
      'url': '',
      'addedAt': DateTime.now().toIso8601String(),
      '_uploading': true,
    };

    // â”€â”€ 5. INJECTION OPTIMISTE IMMÃ‰DIATE dans la grille â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    // On insère en tête de liste sans attendre Firebase â†’ UI instantanée
    _model.personGifts[personId] ??= [];
    _model.personGifts[personId]!.insert(0, photoGiftLocal);
    if (mounted) setState(() {}); // grille mise à jour en < 16ms

    // Snack discret immédiat
    _showSnackBar('ðŸ“· Photo ajoutée ! Upload en coursâ€¦');

    // â”€â”€ 6. Persistance en arrière-plan (Firebase + Storage) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    FirebaseDataService.addGiftToPerson(
      personId: personId,
      gift: photoGiftLocal,
    ).then((ok) {
      if (!ok) {
        // Doublon détecté : retirer l'entrée optimiste
        if (mounted) {
          setState(() {
            _model.personGifts[personId]?.removeWhere((g) => g['id'] == photoId);
          });
          _showSnackBar('Ce produit est déjà dans la liste', isError: false);
        }
      }
    });

    // Upload Storage en arrière-plan
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      OptimisticImageUploader.upload(
        localPath: picked.path,
        storagePath: 'users/$uid/person_photos/$personId/$photoId.jpg',
        onUploadComplete: (cdnUrl) async {
          // Remplacer le chemin local par l'URL CDN dans la grille
          if (mounted) {
            setState(() {
              final idx = _model.personGifts[personId]
                  ?.indexWhere((g) => g['id'] == photoId) ✨ -1;
              if (idx != -1) {
                _model.personGifts[personId]![idx] = {
                  ..._model.personGifts[personId]![idx],
                  'image': cdnUrl,
                  '_uploading': false,
                };
              }
            });
          }
          // Mettre à jour le gift avec l'URL CDN dans Firestore
          try {
            await FirebaseDataService.updateGiftInPerson(
              personId: personId,
              giftId: photoId,
              updates: {'image': cdnUrl, '_uploading': false},
            );
          } catch (_) {}
          if (mounted) _showSnackBar('ðŸ“· Photo de $personName sauvegardée !');
        },
        onUploadError: (_) {
          if (mounted) _showSnackBar('âš ï¸ Erreur upload â€” photo sauvegardée localement', isError: true);
        },
        );
      }
  }

  /// Upload une photo locale vers Firebase Storage et retourne l'URL de téléchargement.
  /// Chemin : users/{uid}/person_photos/{personId}/{timestamp}.jpg
  /// @deprecated â€” utiliser OptimisticImageUploader.upload() à la place
  Future<String?> _uploadPhotoToStorage(String localPath, String personId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final photoId = DateTime.now().millisecondsSinceEpoch.toString();
    return OptimisticImageUploader.uploadAndWait(
      localPath: localPath,
      storagePath: 'users/$uid/person_photos/$personId/$photoId.jpg',
    );
  }
}

