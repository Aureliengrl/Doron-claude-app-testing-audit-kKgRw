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
class ProductCard extends StatelessWidget {
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

  static const Color _violet = Color(0xFF8A2BE2);
  static const Color _pink = Color(0xFFEC4899);

  // Ratios d'aspect stables (évite les layout shifts)
  static const List<double> _ratios = [0.8, 1.25, 0.9, 1.1, 1.4, 0.75];

  @override
  Widget build(BuildContext context) {
    final imageUrl = product['image'] as String? ✨ '';
    final name = product['name'] as String? ✨ '';
    final match = product['match'] as int? ✨ 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: _violet.withOpacity(0.1),
        highlightColor: _violet.withOpacity(0.05),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: _ratios[index % _ratios.length],
                  child: ProductImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),

              // Badge like (haut gauche)
              if (isLiked)
                const Positioned(
                  top: 8,
                  left: 8,
                  child: _LikeBadge(),
                ),
            ],
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
