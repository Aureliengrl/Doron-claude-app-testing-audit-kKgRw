import '/utils/app_logger.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/backend.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/components/liquid_glass.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '/components/wishlist_picker_sheet.dart';
import '/components/product_detail_modal.dart';
import '/components/shared_product_card.dart';

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
  bool _isReordering = false;

  final Color goldColor = const Color(0xFFF59E0B);
  final Color redColor = const Color(0xFFEF4444);
  final Color violetColor = const Color(0xFF8A2BE2);

  @override
  void initState() {
    super.initState();
    _loadLikedProducts();
  }

  Future<void> _loadLikedProducts() async {
    setState(() => _isLoading = true);
    try {
      // Load with custom order if available, else fallback to TimeStamp
      final products = await queryFavouritesRecordOnce(
        queryBuilder: (query) => query
            .where('uid', isEqualTo: currentUserReference)
            .orderBy('order')
            .orderBy('TimeStamp', descending: true),
      );
      setState(() {
        _likedProducts = products;
        _isLoading = false;
      });
    } catch (_) {
      // Fallback: load without order
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
  }

  Future<void> _saveOrder() async {
    final batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < _likedProducts.length; i++) {
      batch.update(_likedProducts[i].reference, {'order': i});
    }
    await batch.commit();
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
                const Spacer(),
                // Bouton mode réorganisation
                if (_likedProducts.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      setState(() => _isReordering = !_isReordering);
                      if (!_isReordering) _saveOrder();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isReordering ? Icons.check_rounded : Icons.swap_vert_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isReordering ? 'Terminer' : 'Réorganiser',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 56),
              child: Text(
                _isReordering
                    ? 'Maintenez appuyé et glissez pour réorganiser'
                    : '${_likedProducts.length} coup${_likedProducts.length > 1 ? 's' : ''} de cœur',
                style: GoogleFonts.poppins(
                  fontSize: 13,
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
          CircularProgressIndicator(color: goldColor, strokeWidth: 3),
          const SizedBox(height: 16),
          Text(
            'Chargement...',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.white.withOpacity(0.65)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_likedProducts.isEmpty) return _buildEmptyState();

    if (_isReordering) {
      return ReorderableGridView.builder(
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
          return _buildProductCard(favourite.product, index, isReordering: true);
        },
        onReorder: (oldIndex, newIndex) {
          HapticFeedback.selectionClick();
          setState(() {
            final item = _likedProducts.removeAt(oldIndex);
            _likedProducts.insert(newIndex, item);
          });
        },
        dragWidgetBuilder: (index, child) {
          return Opacity(opacity: 0.85, child: child);
        },
      );
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
          return GestureDetector(
            key: ValueKey(_likedProducts[index].reference.id),
            onLongPress: () {
              HapticFeedback.mediumImpact();
              setState(() => _isReordering = true);
            },
            child: _buildProductCard(favourite.product, index),
          );
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
              child: Icon(Icons.thumb_up_outlined, size: 60, color: goldColor),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun produit liké',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Explorez l\'app et likez vos produits préférés pour les retrouver ici',
              style: GoogleFonts.poppins(fontSize: 15, color: Colors.white.withOpacity(0.65)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductsStruct product, int index, {bool isReordering = false}) {
    final Map<String, dynamic> productMap = {
      'name': product.productTitle.isNotEmpty ? product.productTitle : 'Produit',
      'brand': product.platform.isNotEmpty ? product.platform : '',
      'image': product.productPhoto,
      'price': product.productPrice,
      'url': product.productUrl,
    };
    return SharedProductCard(
      product: productMap,
      index: index,
      showWishlistButton: !isReordering,
      isReordering: isReordering,
      onRemove: null,
    );
  }
}
