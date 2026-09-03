import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doron/services/firebase_data_service.dart';
import '/components/liquid_glass.dart';
import '/utils/app_tr.dart';

class WishlistPickerSheet extends StatefulWidget {
  final Map<String, dynamic> product;

  const WishlistPickerSheet({super.key, required this.product});

  static void show(BuildContext context, dynamic product) {
    if (product == null) return;

    Map<String, dynamic> productMap;
    if (product is Map<String, dynamic>) {
      productMap = product;
    } else {
      productMap = Map<String, dynamic>.from(product as Map);
    }

    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: WishlistPickerSheet(product: productMap),
      ),
    );
  }

  @override
  State<WishlistPickerSheet> createState() => _WishlistPickerSheetState();
}

class _WishlistPickerSheetState extends State<WishlistPickerSheet> {
  static const _violet = Color(0xFF8A2BE2);
  static const _pink = Color(0xFFEC4899);

  List<Map<String, dynamic>> _wishlists = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadWishlists();
  }

  Future<void> _loadWishlists() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('wishlists')
          .get();

      if (mounted) {
        setState(() {
          _wishlists = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addToWishlist(String wishlistId, String wishlistName) async {
    if (_isSaving) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    nav.pop();

    try {
      await FirebaseDataService.addProductToWishlist(wishlistId, widget.product);

      messenger.showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.redeem_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ajouté à $wishlistName ! 🎁',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _violet,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Erreur lors de l\'ajout', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final productName = widget.product['name'] as String? ??
        widget.product['title'] as String? ??
        'Produit';
    final productImg = widget.product['image_url'] as String? ??
        widget.product['imageUrl'] as String? ??
        widget.product['image'] as String? ??
        '';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF140D26).withOpacity(0.85),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: Colors.white.withOpacity(0.20),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: _violet.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Apple Indicator Bar ──
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 12),
                    width: 36,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),

                // ── Header avec icône produit & bouton fermer ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
                  child: Row(
                    children: [
                      // Vignette Produit ou Icone Circulaire
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [_violet, _pink],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _pink.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: productImg.isNotEmpty
                              ? Image.network(
                                  productImg,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.card_giftcard_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                )
                              : const Icon(
                                  Icons.card_giftcard_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('Ajouter à une wishlist', 'Add to wishlist'),
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              productName,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                color: Colors.white.withOpacity(0.65),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Bouton Fermer Apple Glass
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  height: 0.5,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.white.withOpacity(0.12),
                ),
                const SizedBox(height: 12),

                // ── Contenu Liste des Wishlists ──
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: _pink,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                else if (_wishlists.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                          child: const Icon(
                            Icons.bookmark_border_rounded,
                            size: 28,
                            color: Colors.white38,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Aucune wishlist trouvée',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Créez une wishlist dans votre profil pour y ajouter des cadeaux.',
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: _wishlists.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final wl = _wishlists[index];
                        final name = wl['name'] as String? ?? 'Sans titre';
                        final count = (wl['productCount'] as int?) ?? 0;
                        return _AppleGlassWishlistTile(
                          name: name,
                          productCount: count,
                          onTap: () => _addToWishlist(wl['id'], name),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppleGlassWishlistTile extends StatefulWidget {
  final String name;
  final int productCount;
  final VoidCallback onTap;

  const _AppleGlassWishlistTile({
    required this.name,
    required this.productCount,
    required this.onTap,
  });

  @override
  State<_AppleGlassWishlistTile> createState() => _AppleGlassWishlistTileState();
}

class _AppleGlassWishlistTileState extends State<_AppleGlassWishlistTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeInOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _pressed
                ? Colors.white.withOpacity(0.14)
                : Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _pressed
                  ? Colors.white.withOpacity(0.28)
                  : Colors.white.withOpacity(0.12),
              width: 0.7,
            ),
          ),
          child: Row(
            children: [
              // Icone circulaire Apple Style
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8A2BE2).withOpacity(0.35),
                      const Color(0xFFEC4899).withOpacity(0.35),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 0.5,
                  ),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${widget.productCount} produit${widget.productCount > 1 ? 's' : ''}',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Bouton Add Apple Pill
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8A2BE2), Color(0xFFEC4899)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
