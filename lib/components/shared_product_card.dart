import 'dart:ui';
import 'package:flutter/material.dart';
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

  String get _name => product['name'] ?? product['title'] ?? product['product_title'] ?? 'Produit';
  String get _brand => product['brand'] ?? product['platform'] ?? product['source'] ?? '';
  String get _price {
    final raw = product['price'] ?? product['product_price'] ?? '';
    return raw.toString();
  }
  String get _image => product['image'] ?? product['imageUrl'] ?? product['product_photo'] ?? product['photo'] ?? '';
  String get _url => product['url'] ?? product['product_url'] ?? product['link'] ?? '';

  Map<String, dynamic> get _normalized => {
    'name': _name,
    'brand': _brand,
    'price': _price,
    'image': _image,
    'url': _url,
    'id': product['id'] ?? _name.hashCode,
  };

  bool get _isPhotoItem => product['type'] == 'photo';

  @override
  Widget build(BuildContext context) {
    // Déléguer au PhotoItemCard si c'est un item photo
    if (_isPhotoItem) {
      return PhotoItemCard(photo: product, index: index);
    }

    return GestureDetector(
      key: ValueKey('${_name}_$index'),
      onTap: isReordering
          ? null
          : () => GlobalProductDetailModal.show(context, _normalized),
      child: ClipRRect(
        key: ValueKey('card_${_name}_$index'),
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
        decoration: BoxDecoration(
          color: isReordering
              ? _violet.withOpacity(0.12)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isReordering
                ? _violet.withOpacity(0.4)
                : Colors.white.withOpacity(0.10),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──────────────────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: _image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _image,
                          width: double.infinity,
                          height: 120,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            height: 120,
                            color: Colors.white.withOpacity(0.05),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: _violet,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            height: 120,
                            color: Colors.white.withOpacity(0.05),
                            child: const Icon(
                              Icons.image_not_supported_rounded,
                              color: Colors.white24,
                              size: 40,
                            ),
                          ),
                        )
                      : Container(
                          height: 120,
                          color: Colors.white.withOpacity(0.05),
                          child: const Icon(
                            Icons.card_giftcard_rounded,
                            color: Colors.white24,
                            size: 40,
                          ),
                        ),
                ),

                // Bouton ⋮ wishlist (haut droite)
                if (showWishlistButton && !isReordering)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        WishlistPickerSheet.show(context, _normalized);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.50),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ),

                // Handle réorganisation
                if (isReordering)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: _violet.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.drag_handle_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),

                // Bouton supprimer (optionnel)
                if (onRemove != null && !isReordering)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onRemove!();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // ── Texte : brand / nom / prix ─────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_brand.isNotEmpty)
                      Text(
                        _brand.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _violet,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    if (_price.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_gold.withOpacity(0.18), _pink.withOpacity(0.12)],
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          _price.contains('€') ? _price : '$_price €',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _gold,
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
          ),
      ),
          .animate()
          .fadeIn(delay: Duration(milliseconds: index * 40))
          .scale(
            begin: const Offset(0.92, 0.92),
            end: const Offset(1.0, 1.0),
            duration: 250.ms,
            curve: Curves.easeOutCubic,
          ),
    );
  }
}
