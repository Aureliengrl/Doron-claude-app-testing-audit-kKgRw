import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/components/bounce_button.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/services/user_search_service.dart';
import '/backend/backend.dart';
import '/components/liquid_glass.dart';

class WishlistsPageWidget extends StatefulWidget {
  const WishlistsPageWidget({super.key});

  static String routeName = 'Wishlists';
  static String routePath = '/wishlists';

  @override
  State<WishlistsPageWidget> createState() => _WishlistsPageWidgetState();
}

class _WishlistsPageWidgetState extends State<WishlistsPageWidget> {
  List<Map<String, dynamic>> _wishlists = [];
  bool _isLoading = true;
  Map<String, int> _wishlistCounts = {}; // Compteur de produits par wishlist

  final Color violetColor = const Color(0xFF8A2BE2);
  final Color pinkColor = const Color(0xFFEC4899);

  @override
  void initState() {
    super.initState();
    _loadWishlists();
  }

  Future<void> _loadWishlists() async {
    setState(() => _isLoading = true);

    final wishlists = await FirebaseDataService.loadWishlists();

    // Charger le nombre de produits pour chaque wishlist
    final counts = <String, int>{};
    for (var wishlist in wishlists) {
      final products = await FirebaseDataService.loadWishlistProducts(wishlist['id']);
      counts[wishlist['id']] = products.length;
    }

    setState(() {
      _wishlists = wishlists;
      _wishlistCounts = counts;
      _isLoading = false;
    });
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateWishlistDialog(),
        backgroundColor: violetColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Créer une liste',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
            boxShadow: [
              BoxShadow(
                color: LiquidGlassTokens.primary.withOpacity(0.35),
                blurRadius: 28,
                offset: const Offset(0, 10),
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
                      'Mes Wishlists',
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
                    '${_wishlists.length} liste${_wishlists.length > 1 ? 's' : ''} de souhaits',
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: violetColor,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_wishlists.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadWishlists,
      color: violetColor,
      child: ReorderableListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _wishlists.length,
        onReorder: (int oldIndex, int newIndex) {
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final item = _wishlists.removeAt(oldIndex);
            _wishlists.insert(newIndex, item);
          });
          // Update order in backend if there is an ordered index field.
        },
        itemBuilder: (context, index) {
          final wishlist = _wishlists[index];
          final productCount = _wishlistCounts[wishlist['id']] ?? 0;

          return Container(
            key: ValueKey(wishlist['id']),
            child: _buildWishlistCard(wishlist, productCount, index)
                .animate()
                .fadeIn(delay: Duration(milliseconds: index * 10))
                .slideY(
                  begin: 0.2,
                  end: 0,
                  duration: 400.ms,
                  curve: Curves.easeOutCubic,
                ),
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
                  colors: [violetColor.withOpacity(0.2), pinkColor.withOpacity(0.2)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border,
                size: 60,
                color: violetColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune liste pour le moment',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Créez votre première wishlist pour organiser vos produits favoris',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.white.withOpacity(0.60),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistCard(Map<String, dynamic> wishlist, int productCount, int index) {
    final colors = [
      [violetColor, pinkColor],
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
      [const Color(0xFF10B981), const Color(0xFF059669)],
      [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
    ];
    final gradientColors = colors[index % colors.length];
    final isPublic = wishlist['isPublic'] as bool? ?? false;
    final wishlistId = wishlist['id'] as String;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: BounceCard(
        onTap: () => context.push('/wishlist-details/$wishlistId'),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradientColors[0].withOpacity(0.1),
              gradientColors[1].withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: gradientColors[0].withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wishlist['name'] ?? 'Sans nom',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (wishlist['description'] != null && wishlist['description'].toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          wishlist['description'],
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.grid_view_rounded,
                            size: 16,
                            color: gradientColors[0],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$productCount produit${productCount > 1 ? 's' : ''}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: gradientColors[0],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Badge visibilité
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPublic
                                  ? const Color(0xFF10B981).withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPublic ? Icons.lock_open : Icons.lock,
                                  size: 11,
                                  color: isPublic ? const Color(0xFF10B981) : Colors.grey[500],
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  isPublic ? 'Publique' : 'Privée',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isPublic ? const Color(0xFF10B981) : Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Bouton toggle public/privé
                IconButton(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    final newIsPublic = !isPublic;
                    await UserSearchService.setWishlistVisibility(wishlistId, newIsPublic);
                    setState(() {
                      wishlist['isPublic'] = newIsPublic;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                          newIsPublic
                              ? '🔓 Liste rendue publique'
                              : '🔐 Liste rendue privée',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: newIsPublic ? const Color(0xFF10B981) : Colors.grey[700],
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        duration: const Duration(seconds: 2),
                      ));
                    }
                  },
                  tooltip: isPublic ? 'Rendre privée' : 'Rendre publique',
                  icon: Icon(
                    isPublic ? Icons.lock_open : Icons.lock_outline,
                    color: isPublic ? const Color(0xFF10B981) : Colors.grey[400],
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateWishlistDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(24),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [violetColor, pinkColor]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Nouvelle liste',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nom de la liste',
                      hintText: 'Ex: Noël 2026',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: violetColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: violetColor, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (optionnel)',
                      hintText: 'Ex: Cadeaux pour la famille',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: violetColor, width: 2),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Annuler',
                          style: GoogleFonts.poppins(color: const Color(0xFF6B7280)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty) return;
                          
                          Navigator.pop(context);
                          
                          final wishlistId = await FirebaseDataService.createWishlist(
                            name: nameController.text.trim(),
                            description: descriptionController.text.trim(),
                          );
                          
                          if (wishlistId != null) {
                            await _loadWishlists();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Liste créée avec succès !',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: violetColor,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: violetColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Créer',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
