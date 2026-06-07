import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '/utils/iconly_compat.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tiktok_inspiration_page_model.dart';
import '/components/product_detail_modal.dart';
import '/utils/app_logger.dart';

class TikTokInspirationPageWidget extends StatefulWidget {
  static const String routeName = 'TikTokInspiration';
  static const String routePath = '/tikTokInspiration';

  const TikTokInspirationPageWidget({Key? key}) : super(key: key);

  @override
  State<TikTokInspirationPageWidget> createState() => _TikTokInspirationPageWidgetState();
}

class _TikTokInspirationPageWidgetState extends State<TikTokInspirationPageWidget> {
  late TikTokInspirationPageModel _model;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _model = TikTokInspirationPageModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _model.loadProducts();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _toggleLike(Map<String, dynamic> product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connexion requise pour les favoris.')));
      return;
    }

    final String productId = product['id']?.toString() ?? '';
    if (productId.isEmpty) return;

    final bool isLiked = _model.likedProductTitles.contains(productId);

    setState(() {
      if (isLiked) {
        _model.likedProductTitles.remove(productId);
      } else {
        _model.likedProductTitles.add(productId);
      }
    });

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(productId);

      if (isLiked) {
        await docRef.delete();
      } else {
        await docRef.set({
          'id': productId,
          'name': product['name'] ?? '',
          'price': product['price'] ?? 0,
          'image': product['image'] ?? '',
          'url': product['url'] ?? '',
          'brand': product['brand'] ?? '',
          'source': product['source'] ?? 'Amazon',
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      AppLogger.error('Erreur favoris global', 'Debug', e);
      // Revert UI on error
      setState(() {
        if (isLiked) {
          _model.likedProductTitles.add(productId);
        } else {
          _model.likedProductTitles.remove(productId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _model,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Consumer<TikTokInspirationPageModel>(
          builder: (context, model, child) {
            if (model.isLoading && model.products.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            if (model.hasError && model.products.isEmpty) {
              return Center(
                child: Text(
                  model.errorMessage,
                  style: GoogleFonts.poppins(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              );
            }
            if (model.products.isEmpty) {
              return Center(
                child: Text(
                  'Aucune inspiration disponible',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              );
            }

            return PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: model.products.length,
              onPageChanged: (index) {
                model.setCurrentIndex(index);
              },
              itemBuilder: (context, index) {
                final product = model.products[index];
                final imageUrl = product['image'] as String? ?? '';
                final isLiked = model.likedProductTitles.contains(product['id']?.toString() ?? '');

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image de fond
                    GestureDetector(
                      onTap: () {
                        GlobalProductDetailModal.show(context, product, initialIsLiked: isLiked, onLikeToggled: () {
                           // Sync si liké depuis la popup
                           setState(() {
                             if (_model.likedProductTitles.contains(product['id'])) {
                               _model.likedProductTitles.remove(product['id']);
                             } else {
                               _model.likedProductTitles.add(product['id']);
                             }
                           });
                        });
                      },
                      child: imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(color: Colors.white24),
                              ),
                              errorWidget: (context, url, error) => const Center(
                                child: Icon(Icons.error, color: Colors.white),
                              ),
                            )
                          : Container(color: Colors.grey[900]),
                    ),

                    // Overlay Sombre Bas (pour visibilité)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 150,
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Bouton Like à droite (Style TikTok)
                    Positioned(
                      right: 20,
                      bottom: 80, 
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Bouton Like
                          GestureDetector(
                            onTap: () => _toggleLike(product),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isLiked ? Colors.red.withOpacity(0.2) : Colors.black45,
                              ),
                              child: Icon(
                                isLiked ? IconlyBold.heart : IconlyLight.heart,
                                color: isLiked ? Colors.red : Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Bouton Wishlist (Marque-page)
                          GestureDetector(
                            onTap: () => GlobalProductDetailModal.showWishlistPicker(context, product),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black45,
                              ),
                              child: const Icon(
                                IconlyLight.bookmark,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Bouton Partage / Options (3 petits points)
                          GestureDetector(
                            onTap: () => GlobalProductDetailModal.showProductActionsSheet(context, product),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black45,
                              ),
                              child: const Icon(
                                IconlyLight.moreCircle,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
