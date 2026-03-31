import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '/utils/app_logger.dart';

/// Service centralisé pour la gestion des permissions photos/caméra.
/// Sur iOS 14+, image_picker utilise PHPickerViewController qui gère
/// ses propres permissions — pas besoin de demander Permission.photos.
/// On essaie d'abord directement le picker, et on ne gère la permission
/// manuellement que si le picker échoue.
class PhotoPermissionService {
  static final ImagePicker _picker = ImagePicker();

  /// Ouvre la galerie et retourne l'image sélectionnée.
  /// Retourne null si annulé ou erreur.
  static Future<XFile?> pickFromGallery(BuildContext context, {int imageQuality = 80}) async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
        requestFullMetadata: false,
      );
      return file;
    } catch (e) {
      AppLogger.debug('pickFromGallery error: $e', 'Photo');
      // Si le picker échoue (permission refusée), proposer d'ouvrir les réglages
      if (context.mounted) {
        await _showOpenSettingsDialog(context, 'photos');
      }
      return null;
    }
  }

  /// Ouvre la caméra et retourne l'image prise.
  /// Retourne null si annulé ou erreur.
  static Future<XFile?> pickFromCamera(BuildContext context, {int imageQuality = 80}) async {
    try {
      // La caméra nécessite une permission explicite
      if (Platform.isIOS || Platform.isAndroid) {
        var status = await Permission.camera.status;
        if (status.isDenied) {
          status = await Permission.camera.request();
        }
        if (!status.isGranted) {
          if (context.mounted) {
            await _showOpenSettingsDialog(context, 'caméra');
          }
          return null;
        }
      }

      final file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
        requestFullMetadata: false,
      );
      return file;
    } catch (e) {
      AppLogger.debug('pickFromCamera error: $e', 'Photo');
      if (context.mounted) {
        await _showOpenSettingsDialog(context, 'caméra');
      }
      return null;
    }
  }

  /// Affiche une bottom sheet pour choisir galerie ou caméra,
  /// puis ouvre le picker correspondant.
  static Future<XFile?> pickWithChoice(BuildContext context) async {
    ImageSource? source;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0014),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const Text(
              'Sélectionner une photo',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF8A2BE2)),
              title: const Text('Galerie photos', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Choisir depuis votre bibliothèque', style: TextStyle(color: Colors.white54, fontSize: 12)),
              onTap: () { source = ImageSource.gallery; Navigator.pop(ctx); },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFFEC4899)),
              title: const Text('Appareil photo', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Prendre une nouvelle photo', style: TextStyle(color: Colors.white54, fontSize: 12)),
              onTap: () { source = ImageSource.camera; Navigator.pop(ctx); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null || !context.mounted) return null;
    if (source == ImageSource.gallery) return pickFromGallery(context);
    return pickFromCamera(context);
  }

  // ── Dialog réglages ──────────────────────────────────────────────────────

  static Future<void> _showOpenSettingsDialog(BuildContext context, String type) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0035),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.photo_library_outlined, color: Color(0xFF8A2BE2)),
            SizedBox(width: 10),
            Text('Accès requis', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Doron a besoin d\'accéder à votre $type pour cette fonctionnalité. '
          'Veuillez autoriser l\'accès dans les Réglages de votre appareil.',
          style: const TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Ouvrir les Réglages', style: TextStyle(color: Color(0xFF8A2BE2), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
