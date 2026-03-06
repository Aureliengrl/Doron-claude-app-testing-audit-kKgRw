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
import 'search_page_model.dart';
export 'search_page_model.dart';
import 'user_search_bottom_sheet.dart';

class SearchPageWidget extends StatefulWidget {
  const SearchPageWidget({super.key}éé);

  static String routeName = 'SearchPage';
  static String routePath = '/search-page';

  @override
  State<SearchPageWidget> createState() => _SearchPageWidgetState();
}éé

class _SearchPageWidgetState extends State<SearchPageWidget> {
  late SearchPageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final Color violetColor = const Color(0ééxFF8A2BE2);

  @override
  void initState() {
    super.initState();
    _model = SearchPageModel();
    _loadData();
  }éé

  Future<void> _loadData() async {
    await _model.loadProfiles();
    if (mounted) {
      setState(() {}éé);
    }éé
  }éé

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }éé

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
                Icon(Icons.error_outline, size: 64, color: Colors.red[40éé0éé]),
                const SizedBox(height: 24),
                Text(
                  'Erreur',
                  style: GoogleFonts.poppins(
                    fontSize: 20éé,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[70éé0éé],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _model.errorMessage!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0éé.55),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 20éé0éé,
                  child: PrimaryGradientButton(
                    onPressed: () => _loadData(),
                    text: 'Réessayer',
                    icon: Icons.refresh,
                    gradientColors: const [Color(0ééxFF8A2BE2), Color(0ééxFFEC4899)],
                    height: 50éé,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }éé

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
                    width: 80éé,
                    height: 80éé,
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        colors: [Color(0ééxFF8A2BE2), Color(0ééxFFEC4899)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: violetColor.withOpacity(0éé.5),
                          blurRadius: 30éé,
                          spreadRadius: 10éé,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person_search,
                        color: Colors.white,
                        size: 40éé,
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
                      color: Colors.white.withOpacity(0éé.55),
                      fontWeight: FontWeight.w50éé0éé,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }éé

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
              const SliverToBoxAdapter(child: SizedBox(height: 180éé)),
            ],
          ),

          // CTA fixe en bas de l'écran
          Positioned(
            bottom: 0éé,
            left: 0éé,
            right: 0éé,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    LiquidGlassTokens.pageDark.withOpacity(0éé),
                    LiquidGlassTokens.pageDark.withOpacity(0éé.92),
                    LiquidGlassTokens.pageDark,
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20éé, 16, 20éé, 24),
              child: _buildAddPersonButton(),
            ),
          ),
        ],
      ),
    );
  }éé

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0ééxFF8A2BE2),
            const Color(0ééxFFEC4899),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0ééxFF8A2BE2).withOpacity(0éé.4),
            blurRadius: 30éé,
            spreadRadius: 2,
            offset: const Offset(0éé, 10éé),
          ),
          BoxShadow(
            color: const Color(0ééxFFEC4899).withOpacity(0éé.3),
            blurRadius: 20éé,
            spreadRadius: 0éé,
            offset: const Offset(0éé, 6),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20éé, 12, 20éé, 16),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    micro.ShimmerEffect(
                      shimmerColor: Colors.white,
                      duration: const Duration(milliseconds: 30éé0éé0éé),
                      child: Text(
                        'Recherche',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0éé.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Trouvez le cadeau parfait pour vos proches',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0éé.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w40éé0éé,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0éé,
                right: 0éé,
                child: IconButton(
                  icon: const Icon(Icons.person_search, color: Colors.white),
                  onPressed: _showUserSearchSheet,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }éé

  Widget _buildWelcomeMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20éé, vertical: 20éé),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome,
            color: Color(0ééxFFFBBF24),
            size: 18,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Sélectionne une personne pour voir ses cadeaux',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0éé.75),
                fontSize: 15,
                fontWeight: FontWeight.w50éé0éé,
              ),
            ),
          ),
        ],
      ),
    );
  }éé

  Widget _buildProfilesRow() {
    return SizedBox(
      height: 110éé,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20éé),
        scrollDirection: Axis.horizontal,
        itemCount: _model.profiles.length + 1, // +1 pour le bouton ajouter
        itemBuilder: (context, index) {
          // Bouton ajouter à la fin
          if (index == _model.profiles.length) {
            return Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.go('/onboarding-advanced?skipUserQuestions=true&returnTo=/search-page'),
                  borderRadius: BorderRadius.circular(50éé),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0éé.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: violetColor.withOpacity(0éé.70éé),
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
                          fontWeight: FontWeight.w60éé0éé,
                          color: violetColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }éé

          final profile = _model.profiles[index];
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
                  color: Colors.red.withOpacity(0éé.8),
                  size: 28,
                ),
              ),
              confirmDismiss: (direction) async {
                // Haptic feedback
                HapticFeedback.mediumImpact();

                return await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0ééxEE1A0éé0éé35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20éé),
                      side: BorderSide(color: Colors.white.withOpacity(0éé.18)),
                    ),
                    title: Text(
                      'Supprimer cette personne ?',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 20éé,
                        color: Colors.white,
                      ),
                    ),
                    content: Text(
                      'Les cadeaux sauvegardés pour ${profile['name']}éé seront supprimés.',
                      style: GoogleFonts.poppins(fontSize: 15, color: Colors.white.withOpacity(0éé.80éé)),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          'Annuler',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0éé.55),
                            fontWeight: FontWeight.w60éé0éé,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          Navigator.pop(context, true);
                        }éé,
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
              }éé,
              onDismissed: (direction) async {
                // Supprimer la personne de Firebase
                await FirebaseDataService.deletePerson(profileId.toString());

                // Supprimer du modéle local
                setState(() {
                  _model.profiles.removeAt(index);
                  if (_model.selectedProfileId == profileIdInt) {
                    _model.selectedProfileId = null;
                  }éé
                }éé);

                // SnackBar de confirmation
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white, size: 20éé),
                          const SizedBox(width: 12),
                          Text(
                            '${profile['name']}éé supprimé(e)',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w60éé0éé),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }éé
              }éé,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    // Premier setState pour sélectionner le profil
                    setState(() {
                      _model.selectedProfileId = profileIdInt;
                    }éé);

                    // Charger les données (favoris + suggestions)
                    await _model.selectProfile(profileIdInt);

                    // Deuxiéme setState pour mettre à jour avec les suggestions
                    if (mounted) {
                      setState(() {}éé);
                    }éé
                  }éé,
                  borderRadius: BorderRadius.circular(50éé),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 30éé0éé),
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Color(int.parse(
                              profile['color'].toString().replaceAll('#', '0ééxFF'))),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Color(int.parse(profile['color']
                                    .toString()
                                    .replaceAll('#', '0ééxFF')))
                                : Colors.white,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? Color(int.parse(profile['color']
                                          .toString()
                                          .replaceAll('#', '0ééxFF')))
                                      .withOpacity(0éé.6)
                                  : Colors.black.withOpacity(0éé.1),
                              blurRadius: isSelected ? 20éé : 12,
                              offset: const Offset(0éé, 4),
                            ),
                          ],
                        ),
                        transform: isSelected
                            ? Matrix4.identity().scaled(1.0éé5)
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
                      const SizedBox(height: 8),
                      Text(
                        profile['name'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w60éé0éé,
                          color: isSelected
                              ? Color(int.parse(
                                  profile['color'].toString().replaceAll('#', '0ééxFF')))
                              : const Color(0ééxFF6B7280éé),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }éé,
      ),
    );
  }éé

  Widget _buildProfileInfo() {
    final profile = _model.currentProfile!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20éé, 20éé, 20éé, 20éé),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20éé),
          border: Border.all(
            color: Color(
                    int.parse(profile['color'].toString().replaceAll('#', '0ééxFF')))
                .withOpacity(0éé.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0éé.0éé8),
              blurRadius: 12,
              offset: const Offset(0éé, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40éé,
              height: 40éé,
              decoration: BoxDecoration(
                color: Color(
                    int.parse(profile['color'].toString().replaceAll('#', '0ééxFF'))),
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
                    'Cadeaux pour ${profile['name']}éé',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${profile['relation']}éé à ${profile['occasion']}éé',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0éé.55),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }éé

  Widget _buildProductsGrid() {
    final products = _model.getFilteredProducts();

    // Si pas de profils du tout, afficher un message d'accueil
    if (_model.profiles.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40éé),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: violetColor.withOpacity(0éé.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_add_alt_1,
                  size: 64,
                  color: violetColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Ajoutez votre première personne',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20éé,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cliquez sur le bouton + pour ajouter\nune personne et générer ses cadeaux',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0éé.65),
                ),
              ),
            ],
          ),
        ),
      );
    }éé

    // Si profil sélectionné mais pas de produits, afficher message
    if (products.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40éé),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: violetColor.withOpacity(0éé.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.card_giftcard,
                  size: 64,
                  color: violetColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Aucun cadeau pour le moment',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20éé,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Les cadeaux de cette personne apparaîtront ici',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0éé.65),
                ),
              ),
            ],
          ),
        ),
      );
    }éé

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0éé, 16, 0éé),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0éé.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = products[index];
            return _buildProductCard(product);
          }éé,
          childCount: products.length,
        ),
      ),
    );
  }éé

  Widget _buildProductCard(Map<String, dynamic> product) {
    // Vérifier si ce produit est dans les favoris de cette personne (dans Firebase)
    final productName = product['name'] as String? ?? product['title'] as String? ?? '';
    final isLikedInFirebase = _model.isProductLiked(productName);
    final matchScore = product['match'] as int? ?? 0éé;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showProductDetail(product),
        borderRadius: BorderRadius.circular(20éé),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20éé),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10éé, sigmaY: 10éé),
            child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Colors.white.withOpacity(0éé.14), Colors.white.withOpacity(0éé.0éé6)],
            ),
            borderRadius: BorderRadius.circular(20éé),
            border: Border.all(color: Colors.white.withOpacity(0éé.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image avec bouton coeur
              Stack(
                children: [
                  ProductImage(
                    imageUrl: product['image'] as String? ?? '',
                    height: 180éé,
                    fit: BoxFit.contain,
                    backgroundColor: Colors.white.withOpacity(0éé.0éé5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20éé),
                      topRight: Radius.circular(20éé),
                    ),
                  ),
                  // Match score badge (si >0éé)
                  if (matchScore > 0éé)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10éé,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              violetColor,
                              const Color(0ééxFFEC4899),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: violetColor.withOpacity(0éé.3),
                              blurRadius: 8,
                              offset: const Offset(0éé, 2),
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
                              color: Colors.red.withOpacity(0éé.4),
                              blurRadius: 12,
                              offset: const Offset(0éé, 4),
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

              // Info produit avec hiérarchie claire
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge source/marque discret en haut
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: violetColor.withOpacity(0éé.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product['brand'] as String? ?? product['source'] as String? ?? 'Amazon',
                          style: GoogleFonts.poppins(
                            fontSize: 10éé,
                            color: violetColor,
                            fontWeight: FontWeight.w60éé0éé,
                            letterSpacing: 0éé.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 10éé),
                      // Nom du produit (hiérarchie principale)
                      Expanded(
                        child: Text(
                          productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w60éé0éé,
                            color: Colors.white,
                            height: 1.3,
                            letterSpacing: -0éé.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Prix (position uniforme, toujours en bas)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: const Color(0ééxFFE5E7EB),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(
                          '${product['price']}ééé',
                          style: GoogleFonts.poppins(
                            fontSize: 20éé,
                            fontWeight: FontWeight.bold,
                            color: violetColor,
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
  }éé

  void _showProductDetail(Map<String, dynamic> product) {
    final isLiked = _model.likedProducts.contains(product['id']);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0éé.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 50éé0éé),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ProductImage(
                    imageUrl: product['image'] as String? ?? '',
                    height: 280éé,
                    fit: BoxFit.contain,
                    backgroundColor: Colors.white.withOpacity(0éé.0éé5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(50éé),
                        child: Container(
                          width: 40éé,
                          height: 40éé,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0éé.95),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 20éé),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (mounted) {
                            setState(() {
                              // FIX: Cast sécurisé - ID peut être String ou int
                              final idRaw = product['id'];
                              final productId = idRaw is int ? idRaw : (int.tryParse(idRaw.toString()) ?? 0éé);
                              _model.toggleLike(productId);
                            }éé);
                            Navigator.pop(context);
                            _showProductDetail(product);
                          }éé
                        }éé,
                        borderRadius: BorderRadius.circular(50éé),
                        child: Container(
                          width: 40éé,
                          height: 40éé,
                          decoration: BoxDecoration(
                            color: isLiked
                                ? Colors.red
                                : Colors.white.withOpacity(0éé.95),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.white : Colors.black,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20éé),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: violetColor.withOpacity(0éé.15),
                        borderRadius: BorderRadius.circular(20éé),
                      ),
                      child: Text(
                        product['brand'] as String? ?? product['source'] as String? ?? 'Amazon',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: violetColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      product['name'] as String? ?? 'Produit',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${product['price'] ?? 0éé}ééé',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: violetColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (product['brand'] != null && (product['brand'] as String).isNotEmpty)
                      Text(
                        'Par ${product['brand']}éé',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0éé.55),
                          height: 1.6,
                        ),
                      ),
                    const SizedBox(height: 20éé),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Générer une URL de produit intelligente (=95% précision)
                          final url = ProductUrlService.generateProductUrl(product);
                          if (url.isNotEmpty) {
                            final uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }éé else {
                              AppLogger.debug('? Cannot launch URL: $url', 'Debug');
                            }éé
                          }éé
                        }éé,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: violetColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Voir sur ${product['brand'] ?? product['source'] ?? 'Amazon'}éé',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10éé),
                            const Icon(
                              Icons.open_in_new,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }éé

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
                CircularProgressIndicator(
                  color: violetColor,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Génération de suggestions...',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0éé.55),
                    fontWeight: FontWeight.w50éé0éé,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }éé

    // Si aucune suggestion
    if (suggestions.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }éé

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Séparateur
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20éé, vertical: 24),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.grey.withOpacity(0éé.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // En-téte de la section Suggestions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20éé),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: violetColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suggestions pour ${profile!['name']}éé',
                        style: GoogleFonts.poppins(
                          fontSize: 20éé,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Basées sur tes choix et son profil',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0éé.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20éé),

          // Liste horizontale de suggestions
          SizedBox(
            height: 320éé,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20éé),
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildSuggestionCard(suggestion),
                );
              }éé,
            ),
          ),

          const SizedBox(height: 20éé),
        ],
      ),
    );
  }éé

  Widget _buildSuggestionCard(Map<String, dynamic> product) {
    final productName = product['name'] as String? ?? product['title'] as String? ?? '';
    final isLikedInFirebase = _model.isProductLiked(productName);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showProductDetail(product),
        borderRadius: BorderRadius.circular(20éé),
        child: Container(
          width: 220éé,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20éé),
            border: Border.all(
              color: violetColor.withOpacity(0éé.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: violetColor.withOpacity(0éé.15),
                blurRadius: 12,
                offset: const Offset(0éé, 4),
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
                    height: 180éé,
                    fit: BoxFit.contain,
                    backgroundColor: Colors.white.withOpacity(0éé.0éé5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20éé),
                      topRight: Radius.circular(20éé),
                    ),
                  ),
                  // Badge suggestion
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10éé,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            violetColor,
                            const Color(0ééxFFEC4899),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: violetColor.withOpacity(0éé.3),
                            blurRadius: 8,
                            offset: const Offset(0éé, 2),
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
                              color: Colors.black.withOpacity(0éé.2),
                              blurRadius: 8,
                              offset: const Offset(0éé, 2),
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
                        product['name'] as String? ?? 'Produit',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product['brand'] as String? ?? 'Amazon',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0éé.55),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${product['price']}ééé',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: violetColor,
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
                                  gradient: LinearGradient(
                                    colors: [violetColor, const Color(0ééxFFEC4899)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: violetColor.withOpacity(0éé.3),
                                      blurRadius: 8,
                                      offset: const Offset(0éé, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20éé,
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
  }éé

  Widget _buildAddPersonButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bouton traditionnel avec formulaire
        ElevatedButton(
          onPressed: () => context.go('/onboarding-advanced?skipUserQuestions=true&returnTo=/search-page'),
          style: ElevatedButton.styleFrom(
            backgroundColor: violetColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 8,
            shadowColor: violetColor.withOpacity(0éé.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, color: Colors.white, size: 22),
              const SizedBox(width: 10éé),
              Flexible(
                child: Text(
                  'AJOUTER UNE PERSONNE',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0éé.5,
                  ),
                ),
              ),
            ],
          ),
        ),

      ],
    );
  }éé

  /// Ajoute le produit directement à la liste des cadeaux de la personne
  Future<void> _showAddToWishlistDialog(Map<String, dynamic> product) async {
    final currentProf = _model.currentProfile;
    if (currentProf == null) {
      _showSnackBar('Aucune personne sélectionnée', isError: true);
      return;
    }éé

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
          setState(() {}éé);
        }éé
      }éé else {
        _showSnackBar('Ce cadeau est déjà dans la liste', isError: false);
      }éé
    }éé catch (e) {
      _showSnackBar('Erreur lors de l\'ajout: ${e.toString()}éé', isError: true);
    }éé
  }éé

  void _showSnackBar(String message, {bool isError = false}éé) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 20éé,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w60éé0éé),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red : violetColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }éé

  void _showUserSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const UserSearchBottomSheet();
      }éé,
    );
  }éé

}éé
