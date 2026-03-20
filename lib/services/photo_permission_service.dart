import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service centralisé pour la gestion des permissions photos/caméra.
/// Gère automatiquement iOS (y compris Limited Photo Access) et Android 13+.
class PhotoPermissionService {
  static final ImagePicker _picker = ImagePicker();

  /// Demande la permission galerie et ouvre le picker si accordée.
  /// Retourne l'XFile sélectionné, ou null si refusée/annulée.
  static Future<XFile?> pickFromGallery(BuildContext context, {int imageQuality = 80}) async {
    final granted = await _requestPhotoPermission(context);
    if (!granted) return null;
    return await _picker.pickImage(source: ImageSource.gallery, imageQuality: imageQuality, requestFullMetadata: false);
  }

  /// Demande la permission caméra et ouvre le picker si accordée.
  static Future<XFile?> pickFromCamera(BuildContext context, {int imageQuality = 80}) async {
    final granted = await _requestCameraPermission(context);
    if (!granted) return null;
    return await _picker.pickImage(source: ImageSource.camera, imageQuality: imageQuality, requestFullMetadata: false);
  }

  /// Affiche une bottom sheet pour choisir galerie ou caméra,
  /// demande les permissions correspondantes, et retourne l'XFile.
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
            Text(
              'Sélectionner une photo',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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

    if (source == null) return null;
    if (source == ImageSource.gallery) return pickFromGallery(context);
    return pickFromCamera(context);
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  static Future<bool> _requestPhotoPermission(BuildContext context) async {
    Permission permission;
    if (Platform.isIOS) {
      permission = Permission.photos;
    } else {
      // Android 13+ utilise READ_MEDIA_IMAGES, avant c'est READ_EXTERNAL_STORAGE
      permission = Permission.photos; // permission_handler abstraite
    }

    var status = await permission.status;

    if (status.isGranted || status.isLimited) return true;

    if (status.isDenied) {
      status = await permission.request();
      if (status.isGranted || status.isLimited) return true;
    }

    if (status.isPermanentlyDenied && context.mounted) {
      await _showOpenSettingsDialog(context, 'photos');
      return false;
    }

    return false;
  }

  static Future<bool> _requestCameraPermission(BuildContext context) async {
    var status = await Permission.camera.status;

    if (status.isGranted) return true;

    if (status.isDenied) {
      status = await Permission.camera.request();
      if (status.isGranted) return true;
    }

    if (status.isPermanentlyDenied && context.mounted) {
      await _showOpenSettingsDialog(context, 'caméra');
      return false;
    }

    return false;
  }

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
