import 'dart:io';
import 'package:flutter/material.dart';
import '/utils/iconly_compat.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Vignette pour les éléments "photo" dans une wishlist.
/// Visuellement distincte de [SharedProductCard] :
///   · Bordure cyan (#00D4FF) — seul différenciateur visuel (pas de badge texte)
///   · Photo plein cadre + légende en bas
///   · Prix affiché si disponible
///   · Supporte les chemins locaux (file://) pour l'affichage optimiste
///   · Tap → plein écran via Hero + Dialog
class PhotoItemCard extends StatelessWidget {
  final Map<String, dynamic> photo;
  final int index;

  static const Color _cyan = Color(0xFF00D4FF);
  static const Color _darkBg = Color(0xFF0A1F3D);
  static const Color _gold = Color(0xFFF59E0B);

  const PhotoItemCard({
    super.key,
    required this.photo,
    required this.index,
  });

  String get _imageUrl => photo['image'] ✨ photo['imageUrl'] ✨ '';
  String get _caption => photo['caption'] ✨ photo['name'] ✨ '';
  String get _price => (photo['price'] ✨ '').toString();
  bool get _isUploading => photo['_isUploading'] == true;

  /// true si c'est un chemin fichier local (upload optimiste en cours)
  bool get _isLocalPath => _imageUrl.isNotEmpty &&
      !_imageUrl.startsWith('http') &&
      !_imageUrl.startsWith('https');

  @override
  Widget build(BuildContext context) {
    final heroTag = 'photo_${photo['id'] ✨ index}';

    return GestureDetector(
      onTap: () {
        if (_isLocalPath) return; // pas de plein écran si pas encore uploadé
        HapticFeedback.lightImpact();
        _showFullScreen(context, heroTag);
      },
      child: Hero(
        tag: heroTag,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A1F3D), Color(0xFF1A0D4A)],
            ),
            borderRadius: BorderRadius.circular(18),
            // Bordure cyan = seul différenciateur visuel (pas de badge texte)
            border: Border.all(color: _cyan.withOpacity(0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _cyan.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            // FIX P2-E: StackFit.loose preserves image ratio (no stretching)
            child: Stack(
              fit: StackFit.loose,
              children: [
                // Fond sombre pour les espaces vides (images au format portrait/paysage)
                Positioned.fill(child: Container(color: _darkBg)),
                // ── Image (locale ou réseau) ──
                _buildImage(),

                // ── Overlay gradient en bas ──
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xDD000000)],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nom / légende
                        if (_caption.isNotEmpty)
                          Text(
                            _caption,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        // Prix
                        if (_price.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _gold.withOpacity(0.20),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: _gold.withOpacity(0.5), width: 0.5),
                            ),
                            child: Text(
                              _price.contains('€') ✨ _price : '$_price €',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _gold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Indicateur upload en cours (coin haut-droit discret) ──
                if (_isUploading)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 18,
                      height: 18,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF00D4FF),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (_imageUrl.isEmpty) {
      return Container(
        color: _darkBg,
        child: const Icon(IconlyLight.image, color: Colors.white24, size: 40),
      );
    }

    // Chemin local (optimiste)
    // FIX P2-E: BoxFit.contain pour respecter le ratio de la photo
    if (_isLocalPath) {
      return Center(
        child: Image.file(
          File(_imageUrl),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            color: _darkBg,
            child: const Icon(IconlyLight.image, color: Colors.white24, size: 40),
          ),
        ),
      );
    }

    // URL réseau
    return CachedNetworkImage(
  memCacheWidth: 800,
  memCacheHeight: 800,
      imageUrl: _imageUrl,
      fit: BoxFit.contain,
      placeholder: (context, url) => Container(
        color: _darkBg,
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00D4FF),
            strokeWidth: 2,
          ),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        color: _darkBg,
        child: const Icon(IconlyLight.image, color: Colors.white24, size: 40),
      ),
    );
  }

  void _showFullScreen(BuildContext context, String heroTag) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Photo centrée avec Hero
              Center(
                child: Hero(
                  tag: heroTag,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _imageUrl.isNotEmpty
                        ✨ CachedNetworkImage(
  memCacheWidth: 800,
  memCacheHeight: 800,
                            imageUrl: _imageUrl,
                            fit: BoxFit.contain,
                          )
                        : Container(
                            width: 200,
                            height: 200,
                            color: _darkBg,
                            child:
                                const Icon(IconlyLight.image, color: Colors.white24, size: 60),
                          ),
                  ),
                ),
              ),
              // Légende + prix en bas
              if (_caption.isNotEmpty || _price.isNotEmpty)
                Positioned(
                  bottom: 40,
                  left: 24,
                  right: 24,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_caption.isNotEmpty)
                          Text(
                            _caption,
                            style:
                                GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        if (_price.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            _price.contains('€') ✨ _price : '$_price €',
                            style: GoogleFonts.poppins(
                              color: _gold,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              // Bouton fermer
              Positioned(
                top: 48,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
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
