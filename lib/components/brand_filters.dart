import 'dart:ui';
import 'package:flutter/material.dart';
import '/utils/iconly_compat.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/utils/app_logger.dart';

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
  // Utilisation de l'API Favicon de Google pour une fiabilité à 100% sur mobile et web.
  static String _getLogoUrl(String domain) {
    return 'https://t3.gstatic.com/faviconV2?client=SOCIAL&type=FAVICON&fallback_opts=TYPE,SIZE,URL&url=http://$domain&size=128';
  }

  static const BrandModel _allEntry = BrandModel(
    id: 'all',
    name: 'Toutes',
    displayName: '✨ Toutes',
    icon: IconlyLight.category,
    color: Color(0xFF8A2BE2),
  );

  /// Liste courante des marques — démarre avec les 10 marques codées en dur
  /// ci-dessous, puis remplacée par [loadFromFirestore] dès que la
  /// collection `brands` (alimentée par l'import produits) contient des
  /// données. Un getter (pas une const list) pour que tous les call sites
  /// existants (`PopularBrands.all`) reflètent automatiquement le
  /// changement une fois le chargement terminé.
  static List<BrandModel> get all => _all;
  static bool _loadedFromFirestore = false;

  static List<BrandModel> _all = [
    _allEntry,
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

  static String? getBrandAsset(String id) {
    switch (id) {
      case 'all': return 'assets/images/brand_all.png';
      case 'amazon': return 'assets/images/brand_amazon.png';
      case 'zara': return 'assets/images/brand_zara.png';
      case 'hm': return 'assets/images/brand_hm.png';
      case 'nike': return 'assets/images/brand_nike.png';
      case 'sephora': return 'assets/images/brand_sephora.png';
      case 'apple': return 'assets/images/brand_apple.png';
      case 'fnac': return 'assets/images/brand_fnac.png';
      case 'decathlon': return 'assets/images/brand_decathlon.png';
      case 'ikea': return 'assets/images/brand_ikea.png';
      case 'lego': return 'assets/images/brand_lego.png';
      case 'dyson': return 'assets/images/brand_dyson.png';
      case 'sony': return 'assets/images/brand_sony.png';
      default: return null;
    }
  }

  static BrandModel? getById(String id) {
    try {
      return all.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Remplace la liste codée en dur par les marques réelles de la base
  /// produits (collection Firestore `brands`, alimentée par le pipeline
  /// d'import). Ne fait rien si la collection est vide/absente — la liste
  /// de secours ci-dessus reste alors affichée, l'app ne casse jamais.
  /// Sûr à appeler plusieurs fois (idempotent, se contente de re-fetch).
  static Future<void> loadFromFirestore() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('brands')
          .orderBy('order', descending: false)
          .limit(60)
          .get();

      if (snap.docs.isEmpty) return; // garde la liste de secours

      final loaded = snap.docs.map((doc) {
        final d = doc.data();
        final domain = d['domain'] as String?;
        final colorValue = d['color'] as int?;
        return BrandModel(
          id: doc.id,
          name: (d['name'] as String?) ?? doc.id,
          displayName: (d['displayName'] as String?) ?? '',
          logo: domain != null && domain.isNotEmpty ? _getLogoUrl(domain) : (d['logo'] as String?),
          color: colorValue != null ? Color(colorValue) : null,
        );
      }).toList();

      _all = [_allEntry, ...loaded];
      _loadedFromFirestore = true;
      AppLogger.info('PopularBrands: ${loaded.length} marques chargées depuis Firestore', 'Brands');
    } catch (e) {
      AppLogger.error('PopularBrands.loadFromFirestore failed — fallback liste codée en dur', 'Brands', e);
    }
  }

  static bool get isLoadedFromFirestore => _loadedFromFirestore;
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
    this.height = 38,
  });

  @override
  State<BrandFiltersWidget> createState() => _BrandFiltersWidgetState();
}

class _BrandFiltersWidgetState extends State<BrandFiltersWidget> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ListView.builder(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: PopularBrands.all.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final brand = PopularBrands.all[index];
          return _buildBrandChip(brand, index);
        },
      ),
    );
  }

  Widget _buildBrandChip(BrandModel brand, int index) {
    final isActive = widget.activeBrandId == brand.id;
    final isAll = brand.id == 'all';
    final localAsset = PopularBrands.getBrandAsset(brand.id);
    final primary = widget.primaryColor ?? const Color(0xFF8A2BE2);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onBrandSelected(brand.id);
          },
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? primary
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                    ? primary
                    : const Color(0xFFE5E7EB),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isActive
                      ? primary.withOpacity(0.35)
                      : Colors.black.withOpacity(0.06),
                  blurRadius: isActive ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo miniature
                if (isAll)
                  const Padding(
                    padding: EdgeInsets.only(right: 5),
                    child: Text(
                      '✨',
                      style: TextStyle(fontSize: 14),
                    ),
                  )
                else if (localAsset != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Image.asset(
                        localAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Text(
                          brand.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else if (brand.logo != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Image.network(
                        brand.logo!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Text(
                          brand.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                // Nom de la marque
                Text(
                  brand.name,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    color: isActive ? Colors.white : const Color(0xFF1F2937),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
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
