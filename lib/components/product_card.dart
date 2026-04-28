import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
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
    final imageUrl = product['image'] as String? ?? '';
    final name = product['name'] as String? ?? '';
    final match = product['match'] as int? ?? 0;

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
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x148A2BE2),
                blurRadius: 20,
                spreadRadius: -2,
                offset: Offset(0, 8),
              ),
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image avec badges
              Stack(
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

                  // Badge match (haut droite)
                  if (match > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_violet, _pink],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _violet.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome,
                                size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              '$match%',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
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

              // Nom du produit (optionnel — masqué pour effet Pinterest pur)
              if (name.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                      height: 1.3,
                    ),
                  ),
                ),
            ],
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
