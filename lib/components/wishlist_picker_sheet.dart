import 'package:flutter/material.dart';
import '/utils/app_tr.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '/services/firebase_data_service.dart';
import '/components/liquid_glass.dart';

/// Bottom sheet permettant de choisir une wishlist et d'y ajouter un produit.
/// Utilisable depuis n'importe quelle page (produits likés, cadeaux, inspiration…)
class WishlistPickerSheet {
  static final Color violetColor = const Color(0xFF8A2BE2);
  static final Color pinkColor = const Color(0xFFEC4899);

  /// Normalise un produit en Map uniforme pour être stocké dans favorites
  static Map<String, dynamic> _normalize(Map<String, dynamic> raw) {
    // Support deux structures: FlutterFlow FavouritesRecord ET gift Map
    final nested = raw['product'] as Map<String, dynamic>?;
    return {
      'id': raw['id']?.toString() ?? raw['product_id']?.toString(),
      'name': nested?['product_title'] ?? raw['name'] ?? raw['product_title'] ?? raw['title'] ?? 'Produit',
      'brand': nested?['platform'] ?? raw['brand'] ?? raw['platform'] ?? raw['source'] ?? '',
      'image': nested?['product_photo'] ?? raw['image'] ?? raw['product_photo'] ?? raw['image_url'] ?? '',
      'price': nested?['product_price']?.toString() ?? raw['price']?.toString() ?? raw['product_price']?.toString() ?? '',
      'url': nested?['product_url'] ?? raw['url'] ?? raw['product_url'] ?? '',
      'description': raw['description'] ?? raw['reason'] ?? '',
    };
  }

  /// Affiche la bottom sheet de sélection de wishlist et ajoute le produit.
  static Future<void> show(
    BuildContext context,
    Map<String, dynamic> rawProduct,
  ) async {
    final normalized = _normalize(rawProduct);
    
    HapticFeedback.mediumImpact();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _WishlistPickerWidget(product: normalized),
    );
  }
}

class _WishlistPickerWidget extends StatefulWidget {
  final Map<String, dynamic> product;
  const _WishlistPickerWidget({required this.product});

  @override
  State<_WishlistPickerWidget> createState() => _WishlistPickerWidgetState();
}

class _WishlistPickerWidgetState extends State<_WishlistPickerWidget> {
  List<Map<String, dynamic>> _wishlists = [];
  bool _isLoading = true;
  String? _addingToId;
  final Set<String> _addedIds = {};
  // Compteurs locaux (mis à jour en temps réel après ajout)
  final Map<String, int> _counters = {};

  final Color violetColor = const Color(0xFF8A2BE2);
  final Color pinkColor = const Color(0xFFEC4899);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lists = await FirebaseDataService.loadWishlists();
    if (mounted) {
      // Initialiser les compteurs depuis les données Firebase
      final counters = <String, int>{};
      for (final w in lists) {
        final id = w['id'] as String? ?? '';
        counters[id] = (w['productCount'] as int?) ?? 0;
      }
      setState(() {
        _wishlists = lists;
        _counters.addAll(counters);
        _isLoading = false;
      });
    }
  }

  Future<void> _addToWishlist(String wishlistId, String wishlistName) async {
    setState(() => _addingToId = wishlistId);
    HapticFeedback.selectionClick();
    final ok = await FirebaseDataService.addProductToWishlist(wishlistId, widget.product);
    if (mounted) {
      setState(() {
        _addingToId = null;
        if (ok) {
          _addedIds.add(wishlistId);
          // Incrément temps réel du compteur
          _counters[wishlistId] = (_counters[wishlistId] ?? 0) + 1;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          ok ? '✅ Ajouté à "$wishlistName"' : '❌ Erreur lors de l\'ajout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: ok ? violetColor : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                LiquidGlassTokens.pageDark,
                const Color(0xFF1A0A2E),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Titre
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [violetColor, pinkColor]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(IconlyBold.bookmark, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Ajouter à une wishlist',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Product preview
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        widget.product['image'] ?? '',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 50,
                          height: 50,
                          color: Colors.white10,
                          child: const Icon(IconlyLight.image, color: Colors.white30),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((widget.product['brand'] ?? '').isNotEmpty)
                            Text(
                              widget.product['brand'],
                              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: violetColor),
                            ),
                          Text(
                            widget.product['name'] ?? '',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if ((widget.product['price'] ?? '').isNotEmpty)
                            Text(
                              widget.product['price'].toString().contains('€') ? widget.product['price'] : '${widget.product['price']} €',
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFF59E0B)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Liste des wishlists
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: violetColor, strokeWidth: 2))
                    : _wishlists.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(IconlyLight.document, size: 48, color: Colors.white.withOpacity(0.3)),
                                const SizedBox(height: 12),
                                Text(
                                  'Aucune wishlist créée',
                                  style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.5)),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Créez d\'abord une wishlist dans votre profil',
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.35)),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _wishlists.length,
                            itemBuilder: (context, index) {
                              final wishlist = _wishlists[index];
                              final id = wishlist['id'] as String;
                              final name = wishlist['name'] as String? ?? 'Sans nom';
                              final emoji = wishlist['emoji'] as String? ?? '🎁';
                              final isAdded = _addedIds.contains(id);
                              final isAdding = _addingToId == id;
                              final count = _counters[id] ?? 0;

                              return GestureDetector(
                                onTap: isAdded ? null : () => _addToWishlist(id, name),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isAdded
                                          ? [const Color(0xFF10B981).withOpacity(0.15), const Color(0xFF059669).withOpacity(0.1)]
                                          : [Colors.white.withOpacity(0.09), Colors.white.withOpacity(0.04)],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isAdded
                                          ? const Color(0xFF10B981).withOpacity(0.5)
                                          : Colors.white.withOpacity(0.14),
                                      width: isAdded ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(emoji, style: const TextStyle(fontSize: 24)),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: GoogleFonts.poppins(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                            // Compteur temps réel
                                            AnimatedSwitcher(
                                              duration: const Duration(milliseconds: 300),
                                              child: Text(
                                                key: ValueKey(count),
                                                '$count produit${count > 1 ? 's' : ''}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  color: isAdded
                                                      ? const Color(0xFF10B981)
                                                      : Colors.white.withOpacity(0.45),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isAdding)
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(color: violetColor, strokeWidth: 2),
                                        )
                                      else if (isAdded)
                                        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22)
                                      else
                                        Icon(Icons.add_rounded, color: violetColor, size: 22),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
