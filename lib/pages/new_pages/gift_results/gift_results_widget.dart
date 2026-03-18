import '/utils/app_logger.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  const GiftResultsWidget({super.key});

  static String routeName = 'GiftResults';
  static String routePath = '/gift-results';

  @override
  State<GiftResultsWidget> createState() => _GiftResultsWidgetState();
}

class _GiftResultsWidgetState extends State<GiftResultsWidget>
    with TickerProviderStateMixin {
  late GiftResultsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final Color violetColor = const Color(0xFF8A2BE2);
  bool _isReordering = false;

  @override
  void initState() {
    super.initState();
    _model = GiftResultsModel();
    _loadGiftsAndInitAnimations();
  }

  Future<void> _loadGiftsAndInitAnimations() async {
    await _model.loadGifts();
    if (mounted) {
      _model.initAnimations(this);
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
                      fontWeight: FontWeight.w600,
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
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            violetColor,
            const Color(0xFFEC4899),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: violetColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              // Bouton retour
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.go('/home-pinterest'),
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Badge IA
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFFBBF24),
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'IA',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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
  }

  Widget _buildAIMessage() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            violetColor.withOpacity(0.1),
            const Color(0xFFEC4899).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: violetColor.withOpacity(0.2),
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
                    color: Colors.white.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  });
                },
                borderRadius: BorderRadius.circular(50),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? violetColor
                        : Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: isActive
                          ? violetColor
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: violetColor.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    filter,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsList() {
    if (_isReordering) {
      // Mode réorganisation : liste réordonnable
      return SliverToBoxAdapter(
        child: ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          itemCount: _model.giftResults.length,
          proxyDecorator: (child, index, animation) => Material(
            color: Colors.transparent,
            elevation: 8,
            child: Opacity(opacity: 0.85, child: child),
          ),
          onReorder: (int oldIndex, int newIndex) {
            HapticFeedback.selectionClick();
            setState(() {
              if (oldIndex < newIndex) newIndex -= 1;
              final item = _model.giftResults.removeAt(oldIndex);
              _model.giftResults.insert(newIndex, item);
            });
          },
          itemBuilder: (context, index) {
            final gift = _model.giftResults[index];
            return Container(
              key: ValueKey(gift['id']?.toString() ?? '$index'),
              child: _buildGiftCard(gift, index, isReordering: true),
            );
          },
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final gift = _model.giftResults[index];
            return GestureDetector(
              key: ValueKey(gift['id']?.toString() ?? '$index'),
              onLongPress: () {
                HapticFeedback.mediumImpact();
                setState(() => _isReordering = true);
              },
              child: FadeTransition(
                opacity: _model.fadeAnimations[index],
                child: SlideTransition(
                  position: _model.slideAnimations[index],
                  child: _buildGiftCard(gift, index),
                ),
              ),
            );
          },
          childCount: _model.giftResults.length,
        ),
      ),
    );
  }

  Widget _buildGiftCard(Map<String, dynamic> gift, int index, {bool isReordering = false}) {
    final isLiked = _model.likedGifts.contains(gift['id']);
    // FIX: Cast sécurisé pour éviter crash si type inattendu
    final matchRaw = gift['match'];
    final matchPercent = matchRaw is int ? matchRaw : (matchRaw is double ? matchRaw.toInt() : 85);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          BounceCard(
            onTap: isReordering ? null : () => _showGiftDetail(gift),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: isReordering
                  ? Border.all(color: violetColor.withOpacity(0.5), width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
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
                          width: 140,
                          height: 160,
                          fit: BoxFit.cover,
                          memCacheWidth: 280,
                          placeholder: (context, url) => Container(color: Colors.grey[200]),
                          errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.error)),
                        ),
                      // Match badge
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getMatchColor(matchPercent),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
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
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: violetColor.withOpacity(0.1),
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
                                '${gift['price']}€',
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
                                    final giftId = idRaw is int ? idRaw : (int.tryParse(idRaw.toString()) ?? 0);
                                    _model.toggleLike(giftId);
                                  });
                                },
                                borderRadius: BorderRadius.circular(50),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isLiked
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.grey[100],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    color: isLiked ? Colors.red : const Color(0xFF9CA3AF),
                                    size: 20,
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
  }

  Color _getMatchColor(int matchPercent) {
    if (matchPercent >= 90) {
      return const Color(0xFF10B981); // Vert
    } else if (matchPercent >= 80) {
      return const Color(0xFF3B82F6); // Bleu
    } else {
      return const Color(0xFFF59E0B); // Orange
    }
  }

  void _showGiftDetail(Map<String, dynamic> gift) {
    final isLiked = _model.likedGifts.contains(gift['id']);
    // FIX: Cast sécurisé pour éviter crash
    final matchRaw = gift['match'];
    final matchPercent = matchRaw is int ? matchRaw : (matchRaw is double ? matchRaw.toInt() : 85);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
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
                      height: 280,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      memCacheWidth: 600,
                      placeholder: (context, url) => Container(color: Colors.white10),
                      errorWidget: (context, url, error) => Container(color: Colors.white10, child: const Icon(Icons.error, color: Colors.white)),
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
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: violetColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
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
                      '${gift['price']}€',
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
                        color: Colors.white.withOpacity(0.55),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Raison du match
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Color(0xFFFBBF24),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              gift['reason'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF4B5563),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
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
                                  final giftId = idRaw is int ? idRaw : (int.tryParse(idRaw.toString()) ?? 0);
                                  _model.toggleLike(giftId);
                                });
                                context.pop();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isLiked
                                  ? Colors.red
                                  : Colors.grey[200],
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.white : const Color(0xFF6B7280),
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
                                } else {
                                  AppLogger.debug('? Cannot launch URL: $url', 'Debug');
                                }
                              }
                            },
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
                                  'Voir sur ${gift['brand']}',
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
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Row(
        children: [
          // Bouton REFAIRE (secondaire)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // Retour à l'onboarding (skip questions sur soi)
                context.go('/onboarding-advanced?skipUserQuestions=true');
              },
              icon: const Icon(Icons.refresh, size: 20),
              label: Text(
                'Refaire',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.white.withOpacity(0.55),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
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
                }
              },
              icon: const Icon(Icons.check_circle, size: 20),
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
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 6,
                shadowColor: violetColor.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
