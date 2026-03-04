import '/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget optimisé pour afficher des images avec cache automatique
class CachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? placeholderColor;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.placeholderColor,
  });

  @override
  Widget build(BuildContext context) {
    // Fallback image si URL vide
    if (imageUrl.isEmpty) {
      return _buildErrorWidget();
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        // Placeholder pendant le chargement
        placeholder: (context, url) {
          return placeholder ??
              Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF8A2BE2).withOpacity(0.1),
                      const Color(0xFFEC4899).withOpacity(0.1),
                    ],
                  ),
                ),
                child: Center(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF8A2BE2).withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              );
        },
        // Widget d'erreur si l'image ne charge pas
        errorWidget: (context, url, error) {
          AppLogger.debug('❌ Erreur chargement image: $url - $error', 'Debug');
          return errorWidget ?? _buildErrorWidget();
        },
        // Options de cache
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 100),
        // Cache l'image pendant 7 jours
        maxWidthDiskCache: 1000, // Optimisation mémoire
        maxHeightDiskCache: 1000,
        memCacheWidth: 800, // Cache en mémoire réduit
        memCacheHeight: 800,
      ),
    );
  }

  Widget _buildErrorWidget() {
    const violetColor = Color(0xFF8A2BE2);
    const pinkColor = Color(0xFFEC4899);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            violetColor.withOpacity(0.1),
            pinkColor.withOpacity(0.1),
          ],
        ),
        borderRadius: borderRadius ?? BorderRadius.zero,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_giftcard,
              size: width != null && width! < 100 ? 40 : 60,
              color: violetColor.withOpacity(0.5),
            ),
            if (width == null || width! >= 100) ...[
              const SizedBox(height: 8),
              Text(
                'Chargement...',
                style: TextStyle(
                  color: violetColor.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ProductImage extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final Color? backgroundColor;

  const ProductImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.backgroundColor,
  });

  static const _violetColor = Color(0xFF8A2BE2);
  static const _pinkColor = Color(0xFFEC4899);

  @override
  Widget build(BuildContext context) {
    // FIX: Si URL vide ou invalide, afficher placeholder violet au lieu de gris
    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      return Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor,
          gradient: backgroundColor == null ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _violetColor.withOpacity(0.1),
              _pinkColor.withOpacity(0.1),
            ],
          ) : null,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.card_giftcard,
                size: 50,
                color: _violetColor.withOpacity(0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Image en cours...',
                style: TextStyle(
                  color: _violetColor.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget imageWidget = CachedImage(
      imageUrl: imageUrl,
      height: height,
      width: double.infinity,
      fit: fit,
      borderRadius: borderRadius,
    );

    if (backgroundColor != null) {
      return Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius ?? BorderRadius.zero,
        ),
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

/// Widget optimisé pour le mode Inspirations (plein écran)
/// FIX Bug 4: Amélioration du placeholder et de la gestion d'erreur
class FullscreenProductImage extends StatelessWidget {
  final String imageUrl;
  final double height;
  final BorderRadius? borderRadius;

  const FullscreenProductImage({
    super.key,
    required this.imageUrl,
    this.height = double.infinity,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // FIX Bug 4: Log l'URL pour debug
    AppLogger.debug('🖼️ FullscreenProductImage: chargement de "$imageUrl"', 'Debug');

    // FIX Bug 4: Si URL vide ou invalide, afficher message d'erreur clair
    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      AppLogger.debug('❌ FullscreenProductImage: URL invalide - "$imageUrl"', 'Debug');
      return Container(
        height: height,
        width: double.infinity,
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                size: 80,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Image non disponible',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        // FIX Bug 4: Placeholder avec loader visible (pas juste gris)
        placeholder: (context, url) {
          return Container(
            height: height,
            width: double.infinity,
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF8A2BE2), // Violet de l'app
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chargement...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        // FIX Bug 4: Widget d'erreur visible avec message explicite
        errorWidget: (context, url, error) {
          AppLogger.debug('❌ FullscreenProductImage: Erreur chargement - $url - $error', 'Debug');
          return Container(
            height: height,
            width: double.infinity,
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.red.withOpacity(0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Swipe pour voir le suivant',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 100),
        maxWidthDiskCache: 1200,
        maxHeightDiskCache: 1600,
        memCacheWidth: 1000,
        memCacheHeight: 1400,
      ),
    );
  }
}

/// Preload une liste d'images pour améliorer les performances
Future<void> preloadImages(BuildContext context, List<String> imageUrls) async {
  final validUrls = imageUrls.where((url) => url.isNotEmpty).toList();

  AppLogger.debug('🖼️ Preloading ${validUrls.length} images...', 'Debug');

  for (final url in validUrls) {
    try {
      await precacheImage(
        CachedNetworkImageProvider(url),
        context,
      );
    } catch (e) {
      AppLogger.debug('⚠️ Failed to preload: $url', 'Debug');
    }
  }

  AppLogger.debug('✅ Preloaded ${validUrls.length} images', 'Debug');
}
