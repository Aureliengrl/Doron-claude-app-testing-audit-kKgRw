import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '/components/liquid_glass.dart';

/// Modèle pour une marque/retailer
class BrandModel {
  final String id;
  final String name;
  final String displayName;
  final IconData? icon;
  final Color? color;
  final String? logo; // URL ou asset path

  const BrandModel({
    required this.id,
    required this.name,
    this.displayName = '',
    this.icon,
    this.color,
    this.logo,
  });

  String get label => displayName.isNotEmpty ? displayName : name;
}

/// Liste des marques populaires
  // Utilisation de l'API Favicon de Google pour une fiabilité à 100% sur mobile et web.
  static String _getLogoUrl(String domain) {
    return 'https://t3.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=http://$domain&size=128';
  }

  static final List<BrandModel> all = [
    const BrandModel(
      id: 'all',
      name: 'Toutes',
      displayName: '✨ Toutes',
      icon: Icons.apps_rounded,
      color: Color(0xFF8A2BE2),
    ),
    BrandModel(
      id: 'amazon',
      name: 'Amazon',
      logo: _getLogoUrl('amazon.com'),
      color: const Color(0xFFFF9900),
    ),
    BrandModel(
      id: 'zara',
      name: 'Zara',
      logo: _getLogoUrl('zara.com'),
      color: const Color(0xFF000000),
    ),
    BrandModel(
      id: 'hm',
      name: 'H&M',
      logo: _getLogoUrl('hm.com'),
      color: const Color(0xFFE50914),
    ),
    BrandModel(
      id: 'nike',
      name: 'Nike',
      logo: _getLogoUrl('nike.com'),
      color: const Color(0xFF111111),
    ),
    BrandModel(
      id: 'sephora',
      name: 'Sephora',
      logo: _getLogoUrl('sephora.fr'),
      color: const Color(0xFF000000),
    ),
    BrandModel(
      id: 'apple',
      name: 'Apple',
      logo: _getLogoUrl('apple.com'),
      color: const Color(0xFF555555),
    ),
    BrandModel(
      id: 'fnac',
      name: 'Fnac',
      logo: _getLogoUrl('fnac.com'),
      color: const Color(0xFFFFCC00),
    ),
    BrandModel(
      id: 'decathlon',
      name: 'Decathlon',
      logo: _getLogoUrl('decathlon.fr'),
      color: const Color(0xFF0082C3),
    ),
    BrandModel(
      id: 'ikea',
      name: 'IKEA',
      logo: _getLogoUrl('ikea.com'),
      color: const Color(0xFF0051BA),
    ),
  ];

  static BrandModel? getById(String id) {
    try {
      return all.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// Widget de filtres par marques
class BrandFiltersWidget extends StatefulWidget {
  final String activeBrandId;
  final Function(String) onBrandSelected;
  final Color? primaryColor;
  final double height;

  const BrandFiltersWidget({
    super.key,
    required this.activeBrandId,
    required this.onBrandSelected,
    this.primaryColor,
    this.height = 50,
  });

  @override
  State<BrandFiltersWidget> createState() => _BrandFiltersWidgetState();
}

class _BrandFiltersWidgetState extends State<BrandFiltersWidget> {
  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? const Color(0xFF8A2BE2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre
        // Liste des marques
        SizedBox(
          height: 56, // Homogénéisation de la hauteur des bulles
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24), // Uniformisation du padding global
            scrollDirection: Axis.horizontal,
            itemCount: PopularBrands.all.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final brand = PopularBrands.all[index];
              return _buildBrandChip(brand, primaryColor, index);
            },
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBrandChip(BrandModel brand, Color primaryColor, int index) {
    final isActive = widget.activeBrandId == brand.id;
    final brandColor = brand.color ?? primaryColor;
    final isAll = brand.id == 'all';

    return Padding(
      padding: const EdgeInsets.only(right: 16), // Espacement constant entre bulles
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onBrandSelected(brand.id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: isAll ? null : 56,
          height: 56,
          padding: isAll ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10) : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: isActive ? brandColor : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isActive
                  ? brandColor.withOpacity(0.5)
                  : const Color(0xFFE5E7EB),
              width: isActive ? 2 : 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: brandColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: isAll
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (brand.icon != null) ...[
                      Icon(
                        brand.icon,
                        size: 20,
                        color: isActive ? Colors.white : brandColor,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      brand.label,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : const Color(0xFF374151),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: brand.logo != null
                      ? Container(
                          padding: EdgeInsets.all(isAll ? 0 : 8), // Padding pour éviter que le logo touche les bords
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              brand.logo!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Text(
                                  brand.name.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                      color: isActive ? Colors.white : brandColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            brand.icon ?? Icons.storefront,
                            color: isActive ? Colors.white : brandColor,
                          ),
                        ),
                ),
        ).animate(target: isActive ? 1 : 0)
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.05, 1.05),
            duration: 200.ms,
            curve: Curves.easeOutBack,
          )
          .shimmer(
            duration: 1500.ms,
            color: Colors.white.withOpacity(0.3),
          ),
      ).animate()
        .fadeIn(delay: Duration(milliseconds: index * 50))
        .slideX(
          begin: -0.2,
          end: 0,
          delay: Duration(milliseconds: index * 50),
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        ),
    );
  }
}

/// Widget compact pour filtres de marques (version minimale)
class CompactBrandFilters extends StatelessWidget {
  final String activeBrandId;
  final Function(String) onBrandSelected;
  final Color? primaryColor;

  const CompactBrandFilters({
    super.key,
    required this.activeBrandId,
    required this.onBrandSelected,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = this.primaryColor ?? const Color(0xFF8A2BE2);

    // Seulement les marques principales
    final topBrands = PopularBrands.all.take(6).toList();

    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: topBrands.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final brand = topBrands[index];
          final isActive = activeBrandId == brand.id;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onBrandSelected(brand.id);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? primaryColor : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                brand.label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? Colors.white : Colors.grey[700],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
