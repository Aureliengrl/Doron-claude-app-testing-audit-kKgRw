import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '/components/liquid_glass.dart';
import '/services/store_finder_service.dart';
import '/utils/app_logger.dart';

/// Bottom sheet montrant les magasins physiques proches
/// pour un produit donné (selon sa marque).
class StoreFinderBottomSheet extends StatefulWidget {
  final String productName;
  final String brand;

  const StoreFinderBottomSheet({
    super.key,
    required this.productName,
    required this.brand,
  });

  @override
  State<StoreFinderBottomSheet> createState() => _StoreFinderBottomSheetState();

  /// Ouvre le bottom sheet depuis n'importe où.
  static Future<void> show(
    BuildContext context, {
    required String productName,
    required String brand,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StoreFinderBottomSheet(
        productName: productName,
        brand: brand,
      ),
    );
  }
}

class _StoreFinderBottomSheetState extends State<StoreFinderBottomSheet> {
  static const _violet = Color(0xFF8A2BE2);
  static const _pink = Color(0xFFEC4899);

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _stores = [];
  String _statusText = 'Localisation en cours…';

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    try {
      // 1. Vérif permissions GPS
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Localisation désactivée dans les paramètres.';
          _isLoading = false;
        });
        return;
      }

      setState(() => _statusText = 'Recherche autour de vous…');

      // 2. Position GPS
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      );

      // 3. Recherche magasins
      final stores = await StoreFinderService.findNearbyStores(
        brand: widget.brand,
        lat: pos.latitude,
        lng: pos.longitude,
      );

      setState(() {
        _stores = stores;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.debug('❌ StoreFinderBottomSheet: $e', 'Stores');
      setState(() {
        _error = 'Impossible de trouver votre position.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(32),
        topRight: Radius.circular(32),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xF01A0035),
                Color(0xF00D001A),
              ],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            border: Border(
              top: BorderSide(color: Color(0x44FFFFFF), width: 1.0),
              left: BorderSide(color: Color(0x22FFFFFF), width: 0.5),
              right: BorderSide(color: Color(0x22FFFFFF), width: 0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandle(),
              _buildHeader(),
              Divider(height: 1, color: Colors.white.withOpacity(0.12)),
              Flexible(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() => Container(
        margin: const EdgeInsets.only(top: 14, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.35),
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_violet, _pink],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
              ),
              child:
                  const Icon(IconlyBold.location, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trouver en magasin',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    widget.productName,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.60),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildContent() {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: _violet, strokeWidth: 2.5),
            const SizedBox(height: 20),
            Text(
              _statusText,
              style: GoogleFonts.poppins(
                  fontSize: 15, color: const Color(0xFF6B7280)),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(IconlyLight.location, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 15, color: const Color(0xFF6B7280)),
            ),
          ],
        ),
      );
    }

    if (_stores.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(IconlyLight.buy,
                size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Aucun magasin trouvé près de vous.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 15, color: const Color(0xFF6B7280)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: _stores.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildStoreCard(_stores[index]),
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store) {
    final isOpen = store['isOpenNow'] as bool?;
    final distance = store['distanceText'] as String? ?? '';
    final rating = store['rating'] as num?;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final url = store['mapsUrl'] as String?;
            if (url != null) {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _violet.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(IconlyLight.buy, color: _violet, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store['name'] as String? ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      Text(
                        store['address'] as String? ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isOpen == true
                                  ? const Color(0xFF10B981).withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isOpen == true
                                  ? 'Ouvert'
                                  : isOpen == false
                                      ? 'Fermé'
                                      : 'Horaires inconnus',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isOpen == true
                                    ? const Color(0xFF10B981)
                                    : isOpen == false
                                        ? Colors.red
                                        : Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.directions_walk,
                              size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 2),
                          Text(
                            distance,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                          if (rating != null) ...[
                            const SizedBox(width: 8),
                            const Icon(IconlyBold.star,
                                size: 12, color: Color(0xFFFBBF24)),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
