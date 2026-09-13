import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/utils/iconly_compat.dart';
import 'package:google_fonts/google_fonts.dart';
import '/components/cached_image.dart';

/// PERF AXE 2: ProductCard extrait en StatelessWidget dédié.
///
/// Avant: _buildProductCard() était une méthode du HomePinterestWidget (2343 lignes).
/// Chaque setState() (like, filtre, scroll) reconstruisait TOUTE la grille.
///
/// Après: Flutter peut réutiliser ce widget via sa `key` stable.
/// Seules les cartes dont le `isLiked` change sont reconstruites.
class ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final bool isLiked;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onLikeTap;

  const ProductCard({
    required Key key,
    required this.product,
    required this.isLiked,
    required this.index,
    required this.onTap,
    required this.onLikeTap,
  }) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _hasError = false;
  static const Color _violet = Color(0xFF8A2BE2);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final imageUrl = widget.product['image'] as String? ?? '';

    if (imageUrl.isEmpty || _hasError || imageUrl.contains('placeholder')) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onTap();
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: _violet.withOpacity(0.12),
          highlightColor: _violet.withOpacity(0.06),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF161626).withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.fitWidth,
                    width: double.infinity,
                    borderRadius: BorderRadius.circular(16),
                    errorWidget: const SizedBox.shrink(),
                    onError: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && !_hasError) {
                          setState(() {
                            _hasError = true;
                          });
                        }
                      });
                    },
                  ),
                ),

                // Badge like (haut gauche)
                if (widget.isLiked)
                  const Positioned(
                    top: 8,
                    left: 8,
                    child: _LikeBadge(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge like extrait pour éviter les rebuilds inutiles
class _LikeBadge extends StatelessWidget {
  const _LikeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(IconlyBold.heart, size: 16, color: Colors.red),
    );
  }
}
