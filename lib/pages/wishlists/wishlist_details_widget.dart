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
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final docData = _products[index];
        final productId = docData['id']; // Firestore document ID
        
        // Extract the nested 'product' struct from FavouritesRecord data
        final productMap = docData['product'] as Map<String, dynamic>? ?? {};
        
        final title = productMap['product_title'] ?? docData['product_name'] ?? 'Inconnu';
        final price = productMap['product_price'] ?? docData['price']?.toString() ?? 'N/A';
        final imageUrl = productMap['product_photo'] ?? docData['image_url'] ?? '';
        final brand = productMap['platform'] ?? docData['brand'] ?? docData['source'] ?? '';
        final productUrl = productMap['product_url'] ?? docData['product_url'] ?? '';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              GlobalProductDetailModal.show(
                context,
                productMap,
                initialIsLiked: true, // Assuming generally saved gifts are liked, but we let modal handle toggle if needed
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white.withOpacity(0.14), Colors.white.withOpacity(0.06)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: double.infinity,
                                height: 160,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: Colors.white10),
                                errorWidget: (context, url, error) => Container(color: Colors.white10, child: const Icon(Icons.error, color: Colors.white)),
                              )
                            : Container(
                                width: double.infinity,
                                height: 160,
                                color: Colors.white10,
                                child: const Icon(Icons.image, color: Colors.white),
                              ),
                      ),
                      // Bouton de suppression
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _removeProduct(productId),
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Détails : Marque, Titre, Prix
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (brand.isNotEmpty) ...[
                            Text(
                              brand,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: violetColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            title,
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              price.toString().endsWith('€') ? price : '$price €',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
          ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideY(begin: 0.1, end: 0),
        );
      },
    );
  }
}
