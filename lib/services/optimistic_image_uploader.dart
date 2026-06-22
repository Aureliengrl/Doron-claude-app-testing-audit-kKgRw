import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '/utils/app_logger.dart';

/// Service d'upload d'images **optimiste et non-bloquant**.
///
/// Principe :
///   1. L'appelant reçoit immédiatement le chemin local du fichier.
///   2. L'upload Firebase Storage tourne en arrière-plan (unawaited).
///   3. Quand l'upload termine, [onUploadComplete] est appelé avec l'URL CDN,
///      ce qui permet à la page de remplacer discrètement la preview locale.
///
/// Usage :
/// ```dart
/// final localPath = picked.path;
/// showLocally(localPath);                          // ← instantané
/// OptimisticImageUploader.upload(
///   localPath: localPath,
///   storagePath: 'users/$uid/photos/$id.jpg',
///   onUploadComplete: (cdnUrl) => replaceWithCdn(cdnUrl),
///   onUploadError: (e)        => showError(),
/// );
/// ```
class OptimisticImageUploader {
  // ── Paramètres de compression ────────────────────────────────────────────
  // On descend la qualité à 70 + resize 1024 px max → taille raisonnable
  // sans perte visuelle notable sur écran mobile.
  static const int _quality = 70;
  static const int _maxDimension = 1024;

  // ── Compress ─────────────────────────────────────────────────────────────
  /// Compresse [file] et retourne le fichier compressé (ou [file] si échec).
  static Future<File> compress(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_opt.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: _quality,
        minWidth: _maxDimension,
        minHeight: _maxDimension,
        format: CompressFormat.jpeg,
      );
      if (result != null) return File(result.path);
    } catch (e) {
      AppLogger.debug('OptimisticUploader: compress failed (using original): $e', 'Upload');
    }
    return file;
  }

  // ── Upload non-bloquant ──────────────────────────────────────────────────
  /// Lance l'upload en arrière-plan et appelle les callbacks selon le résultat.
  ///
  /// [localPath]         : chemin absolu du fichier local (tel que picked.path).
  /// [storagePath]       : chemin dans Firebase Storage  (sans / initial).
  /// [onUploadComplete]  : appelé avec l'URL CDN quand l'upload réussit.
  /// [onUploadError]     : appelé si une erreur survient (peut-être null).
  /// [compress]          : si true (défaut), compresse avant l'upload.
  static void upload({
    required String localPath,
    required String storagePath,
    required void Function(String cdnUrl) onUploadComplete,
    void Function(Object error)? onUploadError,
    bool compress = true,
  }) {
    // Lancer en arrière-plan — INTENTIONNELLEMENT non-awaité
    _doUpload(
      localPath: localPath,
      storagePath: storagePath,
      onUploadComplete: onUploadComplete,
      onUploadError: onUploadError,
      shouldCompress: compress,
    );
  }

  // ── Upload bloquant (pour les cas qui en ont besoin) ─────────────────────
  /// Variante awaitable : compresse + upload + retourne l'URL CDN.
  /// Utile pour les flux où on veut quand même attendre (ex. profil photo).
  static Future<String?> uploadAndWait({
    required String localPath,
    required String storagePath,
    bool compress = true,
  }) async {
    try {
      final file = File(localPath);
      final toUpload = compress ✨ await OptimisticImageUploader.compress(file) : file;
      final ref = FirebaseStorage.instance.ref().child(storagePath);
      final task = await ref.putFile(toUpload, SettableMetadata(contentType: 'image/jpeg'));
      return await task.ref.getDownloadURL();
    } catch (e) {
      AppLogger.error('OptimisticUploader.uploadAndWait error', 'Upload', e);
      return null;
    }
  }

  // ── Interne ──────────────────────────────────────────────────────────────
  static Future<void> _doUpload({
    required String localPath,
    required String storagePath,
    required void Function(String cdnUrl) onUploadComplete,
    void Function(Object error)? onUploadError,
    required bool shouldCompress,
  }) async {
    try {
      final file = File(localPath);
      final toUpload = shouldCompress ✨ await compress(file) : file;

      final ref = FirebaseStorage.instance.ref().child(storagePath);
      final task = await ref.putFile(
        toUpload,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final cdnUrl = await task.ref.getDownloadURL();

      AppLogger.debug('✅ OptimisticUploader: upload OK → $cdnUrl', 'Upload');
      onUploadComplete(cdnUrl);
    } catch (e) {
      AppLogger.error('OptimisticUploader._doUpload error', 'Upload', e);
      onUploadError?.call(e);
    }
  }
}
