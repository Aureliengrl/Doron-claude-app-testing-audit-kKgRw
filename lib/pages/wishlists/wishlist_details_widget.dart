import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/services/firebase_data_service.dart';
import '/components/liquid_glass.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '/components/product_detail_modal.dart';
import '/components/wishlist_picker_sheet.dart';
import 'package:flutter/services.dart';
import '/components/shared_product_card.dart';

class WishlistDetailsWidget extends StatefulWidget {
  final String wishlistId;
  const WishlistDetailsWidget({Key? key, required this.wishlistId}) : super(key: key);

  static String routeName = 'WishlistDetails';
  static String routePath = '/wishlist-details/:wishlistId';

  @override
  State<WishlistDetailsWidget> createState() => _WishlistDetailsWidgetState();
}

class _WishlistDetailsWidgetState extends State<WishlistDetailsWidget> {
  Map<String, dynamic>? _wishlistData;
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  final Color violetColor = const Color(0xFF8A2BE2);
  final Color pinkColor = const Color(0xFFEC4899);

  @override
  void initState() {
    super.initState();
    _loadWishlistData();
  }

  Future<void> _loadWishlistData() async {
    setState(() => _isLoading = true);
    
    // Fetch wishlist metadata (if available, else fallback)
    final allWishlists = await FirebaseDataService.loadWishlists();
    final match = allWishlists.where((w) => w['id'] == widget.wishlistId).toList();
    
    if (match.isNotEmpty) {
      _wishlistData = match.first;
    } else {
      _wishlistData = {'name': 'Wishlist Publique', 'isPublic': true};
    }

    final products = await FirebaseDataService.loadWishlistProducts(widget.wishlistId);
    
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  Future<void> _removeProduct(String productId) async {
    final success = await FirebaseDataService.removeProductFromWishlist(widget.wishlistId, productId);
    if (success) {
      setState(() {
        _products.removeWhere((p) => p['product_id'] == productId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Produit retiré', style: GoogleFonts.poppins()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                LiquidGlassTokens.primary.withOpacity(0.50),
                LiquidGlassTokens.secondary.withOpacity(0.35),
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            border: const Border(
              bottom: BorderSide(color: Color(0x44FFFFFF), width: 1.0),
            ),
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
                    Expanded(
                      child: Text(
                        _wishlistData?['name'] ?? 'Chargement...',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 56),
                  child: Text(
                    '${_products.length} produit${_products.length > 1 ? 's' : ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: CircularProgressIndicator(
        color: violetColor,
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildContent() {
    if (_products.isEmpty) {
      return Center(
        child: Text(
          'Cette wishlist est vide.',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final docData = _products[index];
        final productId = docData['id'] as String? ?? '';

        // Normaliser depuis FavouritesRecord ou Map plat
        final nested = docData['product'] as Map<String, dynamic>? ?? {};
        final normalizedProduct = {
          'id': productId,
          'name': nested['product_title'] ?? docData['name'] ?? docData['product_name'] ?? 'Inconnu',
          'brand': nested['platform'] ?? docData['brand'] ?? docData['source'] ?? '',
          'image': nested['product_photo'] ?? docData['image'] ?? docData['image_url'] ?? '',
          'price': nested['product_price'] ?? docData['price']?.toString() ?? '',
          'url': nested['product_url'] ?? docData['product_url'] ?? docData['url'] ?? '',
        };

        return SharedProductCard(
          product: normalizedProduct,
          index: index,
          showWishlistButton: true,
          onRemove: productId.isNotEmpty ? () => _removeProduct(productId) : null,
        );
      },
    );
  }
}
