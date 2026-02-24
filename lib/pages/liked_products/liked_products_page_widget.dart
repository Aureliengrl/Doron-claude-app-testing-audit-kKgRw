import '/utils/app_logger.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/backend/backend.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/components/liquid_glass.dart';

class LikedProductsPageWidget extends StatefulWidget {
  const LikedProductsPageWidget({super.key});

  static String routeName = 'LikedProducts';
  static String routePath = '/liked-products';

  @override
  State<LikedProductsPageWidget> createState() => _LikedProductsPageWidgetState();
}

class _LikedProductsPageWidgetState extends State<LikedProductsPageWidget> {
  List<FavouritesRecord> _likedProducts = [];
  bool _isLoading = true;

  final Color goldColor = const Color(0xFFF59E0B);
  final Color redColor = const Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _loadLikedProducts();
  }

  Future<void> _loadLikedProducts() async {
    setState(() => _isLoading = true);

    try {
      final products = await queryFavouritesRecordOnce(
        queryBuilder: (query) => query
            .where('uid', isEqualTo: currentUserReference)
            .orderBy('TimeStamp', descending: true),
      );

      setState(() {
        _likedProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.debug('Error loading liked products: $e', 'Debug');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTokens.pageDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading ? _buildLoading() : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [goldColor, redColor],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: goldColor.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  'Produits Likés',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 56),
              child: Text(
                '${_likedProducts.length} coup${_likedProducts.length > 1 ? 's' : ''} de cœur',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: goldColor,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_likedProducts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadLikedProducts,
      color: goldColor,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _likedProducts.length,
        itemBuilder: (context, index) {
          final favourite = _likedProducts[index];
          final product = favourite.product;

          return _buildProductCard(product, index);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [goldColor.withOpacity(0.2), redColor.withOpacity(0.2)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.thumb_up_outlined,
                size: 60,
                color: goldColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun produit liké',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Explorez l\'app et likez vos produits préférés pour les retrouver ici',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.white.withOpacity(0.65),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductsStruct product, int index) {
    return Container(
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
          // Image du produit
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: CachedNetworkImage(
                  imageUrl: product.productPhoto,
                  width: double.infinity,
                  height: 140,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: const Color(0xFFF3F4F6),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: goldColor,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFFF3F4F6),
                    child: Icon(
                      Icons.image_not_supported,
                      color: const Color(0xFF9CA3AF),
                      size: 40,
                    ),
                  ),
                ),
              ),
              // Badge like
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [goldColor, redColor]),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: goldColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.thumb_up_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          // Informations produit
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  if (product.productPrice.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            goldColor.withOpacity(0.1),
                            redColor.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.productPrice,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: goldColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(delay: Duration(milliseconds: index * 50))
      .scale(
        begin: const Offset(0.9, 0.9),
        end: const Offset(1.0, 1.0),
        duration: 300.ms,
        curve: Curves.easeOutCubic,
      );
  }
}
