import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
class PopularBrands {
  static final List<BrandModel> all = [
    const BrandModel(
      id: 'all',
      name: 'Toutes',
      displayName: '✨ Toutes',
      icon: Icons.apps_rounded,
      color: Color(0xFF8A2BE2),
    ),
    const BrandModel(
      id: 'amazon',
      name: 'Amazon',
      displayName: '📦 Amazon',
      icon: Icons.shopping_cart_rounded,
      color: Color(0xFFFF9900),
    ),
    const BrandModel(
      id: 'zara',
      name: 'Zara',
      displayName: '👗 Zara',
      icon: Icons.checkroom_rounded,
      color: Color(0xFF000000),
    ),
    const BrandModel(
      id: 'hm',
      name: 'H&M',
      displayName: '👕 H&M',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFFE50914),
    ),
    const BrandModel(
      id: 'nike',
      name: 'Nike',
      displayName: '👟 Nike',
      icon: Icons.directions_run_rounded,
      color: Color(0xFF111111),
    ),
    const BrandModel(
      id: 'sephora',
      name: 'Sephora',
      displayName: '💄 Sephora',
      icon: Icons.face_rounded,
      color: Color(0xFF000000),
    ),
    const BrandModel(
      id: 'apple',
      name: 'Apple Store',
      displayName: ' Apple',
      icon: Icons.phone_iphone_rounded,
      color: Color(0xFF555555),
    ),
    const BrandModel(
      id: 'fnac',
      name: 'Fnac',
      displayName: '📚 Fnac',
      icon: Icons.local_library_rounded,
      color: Color(0xFFFFCC00),
    ),
    const BrandModel(
      id: 'decathlon',
      name: 'Decathlon',
      displayName: '⚽ Decathlon',
      icon: Icons.sports_soccer_rounded,
      color: Color(0xFF0082C3),
    ),
    const BrandModel(
      id: 'ikea',
      name: 'IKEA',
      displayName: '🏠 IKEA',
      icon: Icons.weekend_rounded,
      color: Color(0xFF0051BA),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withOpacity(0.2),
                      primaryColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.store_rounded,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Marques & Enseignes',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ).animate()
            .fadeIn(duration: 400.ms)
            .slideX(begin: -0.2, end: 0, duration: 500.ms),
        ),

        // Liste des marques
        SizedBox(
          height: widget.height,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: PopularBrands.all.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final brand = PopularBrands.all[index];
              return _buildBrandChip(brand, primaryColor, index);
            },
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildBrandChip(BrandModel brand, Color primaryColor, int index) {
    final isActive = widget.activeBrandId == brand.id;
    final brandColor = brand.color ?? primaryColor;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onBrandSelected(brand.id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [brandColor, brandColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive ? null : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isActive
                  ? brandColor.withOpacity(0.3)
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
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (brand.icon != null) ...[
                Icon(
                  brand.icon,
                  size: 18,
                  color: isActive ? Colors.white : brandColor,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                brand.label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : const Color(0xFF374151),
                  letterSpacing: 0.3,
                ),
              ),
            ],
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
