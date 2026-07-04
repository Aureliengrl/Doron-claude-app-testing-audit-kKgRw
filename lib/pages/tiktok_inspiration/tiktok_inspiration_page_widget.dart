import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '/utils/iconly_compat.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tiktok_inspiration_page_model.dart';
import '/components/product_detail_modal.dart';
import '/components/app_notch.dart';
import '/components/aesthetic_buttons.dart';
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
  String _selectedFilter = 'Pour toi';
  final List<String> _filters = ['Pour toi', 'Amis', 'Vêtements', 'Activités'];

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connexion requise pour les favoris.')),
      );
      return;
    }

    final String productId = product['id']?.toString() ?? product['name']?.toString() ?? '';
    if (productId.isEmpty) return;

    final bool isLiked = _model.likedProductTitles.contains(productId);
    HapticFeedback.lightImpact();

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
      AppLogger.error('Erreur favoris inspiration', 'Debug', e);
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
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
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

            return Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: model.products.length,
                  onPageChanged: (index) {
                    model.setCurrentIndex(index);
                  },
                  itemBuilder: (context, index) {
                    final product = model.products[index];
                    final imageUrl = product['image'] as String? ?? '';
                    final productId = product['id']?.toString() ?? product['name']?.toString() ?? '';
                    final isLiked = model.likedProductTitles.contains(productId);

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // 1. Fond Flouté Immersif
                        if (imageUrl.isNotEmpty)
                          CachedNetworkImage(
  memCacheWidth: 800,
  memCacheHeight: 800,
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.black),
                            errorWidget: (context, url, error) => Container(color: Colors.black),
                          )
                        else
                          Container(color: Colors.black),
                          
                        // Filtre de flou et assombrissement
                        ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 45.0, sigmaY: 45.0),
                            child: Container(
                              color: Colors.black.withOpacity(0.55),
                            ),
                          ),
                        ),

                        // 2. Image du produit au centre (Carte Glassmorphism)
                        Center(
                          child: GestureDetector(
                            onDoubleTap: () {
                              if (!isLiked) _toggleLike(product);
                            },
                            onTap: () {
                              GlobalProductDetailModal.show(
                                context,
                                product,
                                initialIsLiked: isLiked,
                                onLikeToggled: () {
                                  setState(() {
                                    if (_model.likedProductTitles.contains(productId)) {
                                      _model.likedProductTitles.remove(productId);
                                    } else {
                                      _model.likedProductTitles.add(productId);
                                    }
                                  });
                                },
                              );
                            },
                            child: Hero(
                              tag: 'product_image_$productId',
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 20),
                                constraints: const BoxConstraints(
                                  maxHeight: 580,
                                  maxWidth: double.infinity,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(32),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      blurRadius: 40,
                                      offset: const Offset(0, 20),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.1),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.15),
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: imageUrl.isNotEmpty
                                      ? CachedNetworkImage(
  memCacheWidth: 800,
  memCacheHeight: 800,
                                          imageUrl: imageUrl,
                                          fit: BoxFit.cover, // ou contain si on veut voir tout le produit sans rogner
                                          placeholder: (context, url) => const Center(
                                            child: CircularProgressIndicator(color: Colors.grey),
                                          ),
                                          errorWidget: (context, url, error) => const Center(
                                            child: Icon(Icons.error, color: Colors.grey),
                                          ),
                                        )
                                      : Container(color: Colors.grey[200]),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 3. Overlay gradient très léger en bas
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 120,
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.6),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 4. Barre d'Actions Latérale (Boutons fonctionnels)
                        Positioned(
                          right: 16,
                          bottom: 100,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Bouton Like
                              _buildActionButton(
                                icon: isLiked ? IconlyBold.heart : IconlyLight.heart,
                                color: isLiked ? const Color(0xFFEC4899) : Colors.white,
                                label: isLiked ? 'Liké' : 'Like',
                                isLiked: isLiked,
                                onTap: () => _toggleLike(product),
                              ),
                              const SizedBox(height: 24),
                              
                              // Bouton Wishlist
                              _buildActionButton(
                                icon: IconlyLight.bookmark,
                                color: Colors.white,
                                label: 'Wishlist',
                                onTap: () {
                                  GlobalProductDetailModal.showWishlistPicker(context, product);
                                },
                              ),
                              const SizedBox(height: 24),
                              
                              // Bouton Options (les 3 points)
                              _buildActionButton(
                                icon: IconlyLight.moreCircle,
                                color: Colors.white,
                                label: 'Options',
                                onTap: () {
                                  GlobalProductDetailModal.showProductActionsSheet(context, product);
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        // Consigne d'interaction pour l'utilisateur
                        Positioned(
                          bottom: 40,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(IconlyLight.infoSquare, color: Colors.white70, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Appuyez sur l\'image pour les détails',
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
                      ],
                    );
                  },
                ),
                // AppNotch et Top Bar par dessus tout
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      const AppNotch(
                        title: 'Inspiration',
                        subtitle: 'Glissez pour découvrir',
                      ),
                      _buildTopFilters(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    bool isLiked = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isLiked ? color.withOpacity(0.15) : Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
              border: Border.all(
                color: isLiked ? color.withOpacity(0.5) : Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            shadows: [
              const Shadow(
                color: Colors.black87,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildTopFilters() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;
          
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedFilter = filter;
              });
              // Plus tard: déclencher le rechargement de _model en fonction du filtre
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  filter,
                  style: GoogleFonts.poppins(
                    color: isSelected ? Colors.black : Colors.white.withOpacity(0.9),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
