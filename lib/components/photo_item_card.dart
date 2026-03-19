import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Vignette pour les éléments "photo" dans une wishlist.
/// Visuellement distincte de [SharedProductCard] :
///   · Fond bleu nuit gradient
///   · Bordure cyan (#00D4FF)
///   · Badge 📷 en haut à gauche
///   · Photo plein cadre + légende en bas
///   · Tap → plein écran via Hero + Dialog
class PhotoItemCard extends StatelessWidget {
  final Map<String, dynamic> photo;
  final int index;

  static const Color _cyan = Color(0xFF00D4FF);
  static const Color _darkBg = Color(0xFF0A1F3D);

  const PhotoItemCard({
    super.key,
    required this.photo,
    required this.index,
  });

  String get _imageUrl => photo['image'] ?? photo['imageUrl'] ?? '';
  String get _caption => photo['caption'] ?? photo['name'] ?? '';

  @override
  Widget build(BuildContext context) {
    final heroTag = 'photo_${photo['id'] ?? index}';

    return GestureDetector(
      onTap: () {
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
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Photo plein cadre
                if (_imageUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: _imageUrl,
                    fit: BoxFit.cover,
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
                      child: const Icon(Icons.broken_image, color: Colors.white24, size: 40),
                    ),
                  )
                else
                  Container(
                    color: _darkBg,
                    child: const Icon(Icons.photo, color: Colors.white24, size: 40),
                  ),

                // Overlay gradient sombre en bas pour la légende
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xCC000000)],
                      ),
                    ),
                    child: _caption.isNotEmpty
                        ? Text(
                            _caption,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),

                // Badge 📷 en haut à gauche
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: _cyan.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_camera, color: Colors.white, size: 11),
                        const SizedBox(width: 3),
                        Text(
                          'Photo',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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
                        ? CachedNetworkImage(
                            imageUrl: _imageUrl,
                            fit: BoxFit.contain,
                          )
                        : Container(
                            width: 200,
                            height: 200,
                            color: _darkBg,
                            child: const Icon(Icons.photo, color: Colors.white24, size: 60),
                          ),
                  ),
                ),
              ),
              // Légende
              if (_caption.isNotEmpty)
                Positioned(
                  bottom: 40,
                  left: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _caption,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
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
                    decoration: BoxDecoration(
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
