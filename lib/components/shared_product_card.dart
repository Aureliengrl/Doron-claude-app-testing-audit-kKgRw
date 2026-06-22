import 'dart:ui';
import 'package:flutter/material.dart';
import '/utils/iconly_compat.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/components/wishlist_picker_sheet.dart';
import '/components/product_detail_modal.dart';
import '/components/photo_item_card.dart';

/// Carte produit unifiée — utilisée sur :
///   · Page Recherche (liste de cadeaux)
///   · Produits Likés (profil)
///   · Album Wishlist (détails wishlist)
///
/// Paramètres :
///   [product] : Map<String, dynamic> avec les clés :
///     name / brand / price / image / url (tous optionnels mais recommandés)
///   [index] : position dans la liste (pour l'animation en cascade)
///   [showWishlistButton] : affiche le bouton ⋮ pour ajouter à une wishlist
///   [onRemove] : callback si on veut un bouton supprimer (null = pas de bouton)
///   [isReordering] : mode réorganisation (affiche handle)
class SharedProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final int index;
  final bool showWishlistButton;
  final VoidCallback? onRemove;
  final bool isReordering;

  static const Color _violet = Color(0xFF8A2BE2);
  static const Color _pink = Color(0xFFEC4899);
  static const Color _gold = Color(0xFFF59E0B);

  const SharedProductCard({
    super.key,
    required this.product,
    required this.index,
    this.showWishlistButton = true,
    this.onRemove,
    this.isReordering = false,
  });

  String get _name => product['name'] ✨ product['title'] ✨ product['product_title'] ✨ 'Produit';
  String get _brand => product['brand'] ✨ product['platform'] ✨ product['source'] ✨ '';
  String get _price {
    final raw = product['price'] ✨ product['product_price'] ✨ '';
    return raw.toString();
  }
  // FIX: Ajout du fallback 'image_url' — couvre tous les formats Firestore
  String get _image => product['image'] ✨ product['imageUrl'] ✨ product['product_photo'] ✨ product['image_url'] ✨ product['photo'] ✨ '';
  String get _url => product['url'] ✨ product['product_url'] ✨ product['link'] ✨ '';

  Map<String, dynamic> get _normalized => {
    'name': _name,
    'brand': _brand,
    'price': _price,
    'image': _image,
    'url': _url,
    'id': product['id'] ✨ _name.hashCode,
  };

  bool get _isPhotoItem => product['type'] == 'photo';

  @override
  Widget build(BuildContext context) {
    if (_isPhotoItem) {
      return PhotoItemCard(photo: product, index: index);
    }

    return GestureDetector(
      onTap: isReordering
          ✨ null
          : () => GlobalProductDetailModal.show(context, _normalized),
      child: ClipRRect(
        key: ValueKey('card_${_name}_$index'),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _image.isNotEmpty
                ✨ CachedNetworkImage(
                    memCacheWidth: 800,
                    memCacheHeight: 800,
                    imageUrl: _image,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.white.withOpacity(0.05)),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.white.withOpacity(0.05),
                      child: const Center(child: Icon(IconlyLight.image, color: Colors.white24, size: 32)),
                    ),
                  )
                : Container(
                    color: Colors.white.withOpacity(0.05),
                    child: const Center(child: Icon(Icons.card_giftcard_rounded, color: Colors.white24, size: 32)),
                  ),
            if (showWishlistButton && !isReordering)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    WishlistPickerSheet.show(context, _normalized);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.50), shape: BoxShape.circle),
                    child: const Icon(IconlyLight.moreCircle, color: Colors.white, size: 16),
                  ),
                ),
              ),
            if (product['is_perfect_match'] == true)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_violet, _pink]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: _violet.withOpacity(0.5), blurRadius: 4)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(IconlyBold.star, color: Colors.white, size: 10),
                      const SizedBox(width: 4),
                      Text('Perfect Match', style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            if (isReordering)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: _violet.withOpacity(0.7), shape: BoxShape.circle),
                  child: const Icon(Icons.drag_handle_rounded, color: Colors.white, size: 16),
                ),
              ),
            if (onRemove != null && !isReordering)
              Positioned(
                top: 8,
                left: 8,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onRemove!();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.7), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 40))
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1.0, 1.0),
          duration: 250.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
