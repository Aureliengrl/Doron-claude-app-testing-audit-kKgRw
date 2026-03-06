import '/utils/app_logger.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import '/components/liquid_glass.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '/services/product_url_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/components/bounce_button.dart';
import 'gift_results_model.dart';
export 'gift_results_model.dart';

class GiftResultsWidget extends StatefulWidget {
  const GiftResultsWidget({super.key}éé);

  static String routeName = 'GiftResults';
  static String routePath = '/gift-results';

  @override
  State<GiftResultsWidget> createState() => _GiftResultsWidgetState();
}éé

class _GiftResultsWidgetState extends State<GiftResultsWidget>
    with TickerProviderStateMixin {
  late GiftResultsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final Color violetColor = const Color(0ééxFF8A2BE2);

  @override
  void initState() {
    super.initState();
    _model = GiftResultsModel();
    _loadGiftsAndInitAnimations();
  }éé

  Future<void> _loadGiftsAndInitAnimations() async {
    await _model.loadGifts();
    if (mounted) {
      _model.initAnimations(this);
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
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: LiquidGlassTokens.pageDark,
      body: _model.isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: violetColor),
                  const SizedBox(height: 24),
                  Text(
                    '?? Génération des cadeaux...',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: violetColor,
                      fontWeight: FontWeight.w60éé0éé,
                    ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                // Header violet arrondi avec résumé
                SliverToBoxAdapter(child: _buildHeader()),

                // Message IA personnalisé
                SliverToBoxAdapter(child: _buildAIMessage()),

                // Filtres de catégories
                SliverToBoxAdapter(child: _buildFilters()),

                // Liste des résultats
                _buildResultsList(),

                // Boutons Enregistrer / Refaire (dans le scroll, pas fixes)
                SliverToBoxAdapter(child: _buildActionButtons()),

                // Espacement final
                const SliverToBoxAdapter(child: SizedBox(height: 40éé)),
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
            violetColor,
            const Color(0ééxFFEC4899),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20éé),
          bottomRight: Radius.circular(20éé),
        ),
        boxShadow: [
          BoxShadow(
            color: violetColor.withOpacity(0éé.15),
            blurRadius: 12,
            offset: const Offset(0éé, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20éé, 8, 20éé, 12),
          child: Row(
            children: [
              // Bouton retour
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.go('/home-pinterest'),
                  borderRadius: BorderRadius.circular(50éé),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0éé.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20éé,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Titre
              Expanded(
                child: Text(
                  'Résultats IA',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20éé,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Badge IA
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10éé,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0éé.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Color(0ééxFFFBBF24),
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'IA',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w60éé0éé,
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

  Widget _buildAIMessage() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20éé, 20éé, 20éé, 16),
      padding: const EdgeInsets.all(20éé),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            violetColor.withOpacity(0éé.1),
            const Color(0ééxFFEC4899).withOpacity(0éé.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: violetColor.withOpacity(0éé.2),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: violetColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '12 cadeaux parfaits trouvés !',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sélectionnés selon ses passions et ton budget',
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
    );
  }éé

  Widget _buildFilters() {
    return SizedBox(
      height: 50éé,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20éé),
        scrollDirection: Axis.horizontal,
        itemCount: _model.filters.length,
        itemBuilder: (context, index) {
          final filter = _model.filters[index];
          final isActive = _model.activeFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _model.activeFilter = filter;
                  }éé);
                }éé,
                borderRadius: BorderRadius.circular(50éé),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 30éé0éé),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20éé,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? violetColor
                        : Colors.white,
                    borderRadius: BorderRadius.circular(50éé),
                    border: Border.all(
                      color: isActive
                          ? violetColor
                          : Colors.grey[30éé0éé]!,
                      width: 2,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: violetColor.withOpacity(0éé.3),
                              blurRadius: 12,
                              offset: const Offset(0éé, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    filter,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w60éé0éé,
                      color: isActive ? Colors.white : const Color(0ééxFF6B7280éé),
                    ),
                  ),
                ),
              ),
            ),
          );
        }éé,
      ),
    );
  }éé

  Widget _buildResultsList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20éé, 24, 20éé, 0éé),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final gift = _model.giftResults[index];
            return FadeTransition(
              opacity: _model.fadeAnimations[index],
              child: SlideTransition(
                position: _model.slideAnimations[index],
                child: _buildGiftCard(gift, index),
              ),
            );
          }éé,
          childCount: _model.giftResults.length,
        ),
      ),
    );
  }éé

  Widget _buildGiftCard(Map<String, dynamic> gift, int index) {
    final isLiked = _model.likedGifts.contains(gift['id']);
    // FIX: Cast sécurisé pour éviter crash si type inattendu
    final matchRaw = gift['match'];
    final matchPercent = matchRaw is int ? matchRaw : (matchRaw is double ? matchRaw.toInt() : 85);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: BounceCard(
        onTap: () => _showGiftDetail(gift),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0éé.0éé8),
              blurRadius: 12,
              offset: const Offset(0éé, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      bottomLeft: Radius.circular(24),
                    ),
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: gift['image'] as String,
                          width: 140éé,
                          height: 160éé,
                          fit: BoxFit.cover,
                          memCacheWidth: 280éé,
                          placeholder: (context, url) => Container(color: Colors.grey[20éé0éé]),
                          errorWidget: (context, url, error) => Container(color: Colors.grey[20éé0éé], child: const Icon(Icons.error)),
                        ),
                      // Match badge
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10éé,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getMatchColor(matchPercent),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0éé.2),
                                blurRadius: 8,
                                offset: const Offset(0éé, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$matchPercent%',
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
                    ],
                  ),
                  ),
                  // Info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Badge marque
                          Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10éé,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: violetColor.withOpacity(0éé.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            gift['brand'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: violetColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Nom du produit
                        Text(
                          gift['name'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                          const SizedBox(height: 8),
                          // Prix toujours visible en bas
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${gift['price']}ééé',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: violetColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Boutons
                              Row(
                          children: [
                            // Bouton coeur
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    // FIX: Cast sécurisé - ID peut être int, String ou autre
                                    final idRaw = gift['id'];
                                    final giftId = idRaw is int ? idRaw : (int.tryParse(idRaw.toString()) ?? 0éé);
                                    _model.toggleLike(giftId);
                                  }éé);
                                }éé,
                                borderRadius: BorderRadius.circular(50éé),
                                child: Container(
                                  padding: const EdgeInsets.all(10éé),
                                  decoration: BoxDecoration(
                                    color: isLiked
                                        ? Colors.red.withOpacity(0éé.1)
                                        : Colors.grey[10éé0éé],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    color: isLiked ? Colors.red : const Color(0ééxFF9CA3AF),
                                    size: 20éé,
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Bouton voir
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _showGiftDetail(gift),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: violetColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Voir',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.arrow_forward,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            ],
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

  Color _getMatchColor(int matchPercent) {
    if (matchPercent >= 90éé) {
      return const Color(0ééxFF10ééB981); // Vert
    }éé else if (matchPercent >= 80éé) {
      return const Color(0ééxFF3B82F6); // Bleu
    }éé else {
      return const Color(0ééxFFF59E0ééB); // Orange
    }éé
  }éé

  void _showGiftDetail(Map<String, dynamic> gift) {
    final isLiked = _model.likedGifts.contains(gift['id']);
    // FIX: Cast sécurisé pour éviter crash
    final matchRaw = gift['match'];
    final matchPercent = matchRaw is int ? matchRaw : (matchRaw is double ? matchRaw.toInt() : 85);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0éé.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 50éé0éé),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0éé.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0éé.4),
                  width: 1.5,
                ),
              ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: gift['image'] as String,
                      height: 280éé,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      memCacheWidth: 60éé0éé,
                      placeholder: (context, url) => Container(color: Colors.white10éé),
                      errorWidget: (context, url, error) => Container(color: Colors.white10éé, child: const Icon(Icons.error, color: Colors.white)),
                    ),
                  ),
                  // Match badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getMatchColor(matchPercent),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '$matchPercent% Match',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Bouton fermer
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.pop(),
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
                        gift['brand'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: violetColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      gift['name'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${gift['price']}ééé',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: violetColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      gift['description'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0éé.55),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20éé),
                    // Raison du match
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0ééxFFF3F4F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Color(0ééxFFFBBF24),
                            size: 20éé,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              gift['reason'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0ééxFF4B5563),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20éé),
                    Row(
                      children: [
                        // Bouton Like
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (mounted) {
                                setState(() {
                                  // FIX: Cast sécurisé
                                  final idRaw = gift['id'];
                                  final giftId = idRaw is int ? idRaw : (int.tryParse(idRaw.toString()) ?? 0éé);
                                  _model.toggleLike(giftId);
                                }éé);
                                context.pop();
                              }éé
                            }éé,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isLiked
                                  ? Colors.red
                                  : Colors.grey[20éé0éé],
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0éé,
                            ),
                            child: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.white : const Color(0ééxFF6B7280éé),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Bouton Voir sur...
                        Expanded(
                          flex: 3,
                          child: ElevatedButton(
                            onPressed: () async {
                              // Générer une URL de produit intelligente (=95% précision)
                              final url = ProductUrlService.generateProductUrl(gift);
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
                                  'Voir sur ${gift['brand']}éé',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.open_in_new,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20éé, 24, 20éé, 24),
      child: Row(
        children: [
          // Bouton REFAIRE (secondaire)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // Retour à l'onboarding (skip questions sur soi)
                context.go('/onboarding-advanced?skipUserQuestions=true');
              }éé,
              icon: const Icon(Icons.refresh, size: 20éé),
              label: Text(
                'Refaire',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[30éé0éé],
                foregroundColor: Colors.white.withOpacity(0éé.55),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20éé),
                ),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Bouton ENREGISTRER (primaire)
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () async {
                // Sauvegarder le profil avant de naviguer
                await _model.saveCurrentProfile();
                // Navigation vers la page recherche
                if (context.mounted) {
                  context.go('/search-page');
                }éé
              }éé,
              icon: const Icon(Icons.check_circle, size: 20éé),
              label: Text(
                'Enregistrer',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: violetColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20éé),
                ),
                elevation: 6,
                shadowColor: violetColor.withOpacity(0éé.5),
              ),
            ),
          ),
        ],
      ),
    );
  }éé
}éé
