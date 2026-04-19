import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '/utils/app_logger.dart';

class ImageCompressUtils {
  static Future<File?> compressImage(File file, {int quality = 60, int minWidth = 800, int minHeight = 800}) async {
    try {
      final String filePath = file.absolute.path;
      final Directory tempDir = await getTemporaryDirectory();
      
      // Generate a unique filename in temp dir
      final String targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';
      
      var result = await FlutterImageCompress.compressAndGetFile(
        filePath, 
        targetPath,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
        format: CompressFormat.jpeg,
      );
      
      if (result != null) {
        return File(result.path);
      }
      return null;
    } catch (e) {
      AppLogger.error('Erreur de compression image', 'ImageCompress', e);
      return file; // Retourner le fichier original en cas d'erreur
    }
  }
}
