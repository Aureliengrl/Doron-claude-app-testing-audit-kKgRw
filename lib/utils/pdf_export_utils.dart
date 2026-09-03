import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:http/http.dart' as http;

import '/utils/app_logger.dart';

class PdfExportUtils {
  /// Assainit une chaîne de caractères pour éviter les crashs de polices PDF
  static String cleanText(String? input) {
    if (input == null || input.isEmpty) return '';
    return input
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('…', '...')
        .replaceAll('Õ', 'O')
        .replaceAll('õ', 'o');
  }

  /// Vérifie si les octets correspondent à une image JPEG ou PNG valide
  static bool _isValidImage(Uint8List bytes) {
    if (bytes.length < 8) return false;
    // JPEG magic bytes: FF D8 FF
    final isJpeg = bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
    // PNG magic bytes: 89 50 4E 47 0D 0A 1A 0A
    final isPng = bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
    return isJpeg || isPng;
  }

  /// Calcule un rectangle d'origine valide et non-nul pour la feuille de partage iOS
  static Rect getValidSharePosition([BuildContext? context]) {
    if (context != null) {
      try {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
          final pos = box.localToGlobal(Offset.zero);
          if (pos.dx >= 0 && pos.dy >= 0) {
            return Rect.fromLTWH(pos.dx, pos.dy, box.size.width, box.size.height);
          }
        }
      } catch (_) {}
    }
    try {
      final view = WidgetsBinding.instance.platformDispatcher.views.firstOrNull;
      if (view != null && view.physicalSize.width > 0 && view.physicalSize.height > 0) {
        final logicalWidth = view.physicalSize.width / (view.devicePixelRatio > 0 ? view.devicePixelRatio : 1.0);
        final logicalHeight = view.physicalSize.height / (view.devicePixelRatio > 0 ? view.devicePixelRatio : 1.0);
        return Rect.fromLTWH(
          logicalWidth * 0.1,
          logicalHeight * 0.4,
          logicalWidth * 0.8,
          logicalHeight * 0.2,
        );
      }
    } catch (_) {}
    return const Rect.fromLTWH(50, 200, 250, 150);
  }

  /// Génère un PDF minimaliste & luxueux à partir d'une liste de cadeaux et le partage
  static Future<void> generateAndShareWishlistPdf({
    required Map<String, dynamic> profile,
    required List<dynamic> products,
    BuildContext? context,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final pdf = pw.Document();

      final profileName = cleanText(profile['name']?.toString() ?? 'Quelqu\'un');
      final occasion = cleanText(profile['occasion']?.toString() ?? 'une occasion speciale');

      // Charger le logo officiel DORON depuis les assets
      Uint8List? logoBytes;
      try {
        final byteData = await rootBundle.load('assets/images/doron_logo_pdf.jpg');
        logoBytes = byteData.buffer.asUint8List();
      } catch (_) {
        try {
          final byteData = await rootBundle.load('assets/images/doron_logo.png');
          logoBytes = byteData.buffer.asUint8List();
        } catch (_) {}
      }

      // Télécharger les images de manière sécurisée
      final productImages = await _fetchProductImages(products);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
          build: (pw.Context context) {
            return [
              _buildHeader(logoBytes),
              pw.SizedBox(height: 12),
              _buildProductGrid(products, productImages),
              pw.SizedBox(height: 28),
              _buildFooter(),
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      final dir = await getTemporaryDirectory();
      
      // Nom de fichier nettoyé pour le système de fichier
      final safeName = profileName.replaceAll(RegExp(r'[^\w\s\-]'), '_');
      final file = File('${dir.path}/DORON_Cadeaux_$safeName.pdf');
      await file.writeAsBytes(bytes, flush: true);

      final xFile = XFile(
        file.path,
        mimeType: 'application/pdf',
        name: 'DORON_Cadeaux_$safeName.pdf',
      );

      final safeOrigin = sharePositionOrigin ?? getValidSharePosition(context);

      await Share.shareXFiles(
        [xFile],
        text: 'Decouvre la selection d\'idees cadeaux pour $profileName sur DORON !',
        sharePositionOrigin: safeOrigin,
      );
    } catch (e, stack) {
      AppLogger.error('Erreur de generation PDF: $e', 'PdfExportUtils', stack);
      rethrow;
    }
  }

  static Future<Map<int, Uint8List>> _fetchProductImages(
    List<dynamic> products,
  ) async {
    final result = <int, Uint8List>{};

    await Future.wait(products.asMap().entries.map((entry) async {
      final index = entry.key;
      final dynamic item = entry.value;
      if (item is! Map) return;
      final product = Map<String, dynamic>.from(item);

      final url = (product['image'] ?? product['imageUrl'] ?? product['photo'] ?? product['thumbnail']) as String?;
      if (url == null || url.isEmpty || !url.startsWith('http')) return;

      try {
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 6));
        if (response.statusCode == 200 && _isValidImage(response.bodyBytes)) {
          result[index] = response.bodyBytes;
        }
      } catch (e) {
        AppLogger.debug('PdfExportUtils: image ignoree ($url): $e', 'PdfExportUtils');
      }
    }));

    return result;
  }

  static pw.Widget _buildHeader(Uint8List? logoBytes) {
    return pw.Container(
      width: double.infinity,
      alignment: pw.Alignment.center,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logoBytes != null && logoBytes.isNotEmpty)
            pw.ClipRRect(
              horizontalRadius: 18,
              verticalRadius: 18,
              child: pw.Container(
                width: 72,
                height: 72,
                child: pw.Image(
                  pw.MemoryImage(logoBytes),
                  fit: pw.BoxFit.cover,
                ),
              ),
            )
          else
            pw.Text(
              'D O R O N',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 4,
                color: const PdfColor.fromInt(0xFF130E26),
              ),
            ),
          pw.SizedBox(height: 12),
        ],
      ),
    );
  }

  static pw.Widget _buildProductGrid(
    List<dynamic> products,
    Map<int, Uint8List> productImages,
  ) {
    if (products.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(32),
        alignment: pw.Alignment.center,
        child: pw.Text(
          'Aucun cadeau dans cette liste pour le moment.',
          style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey500),
        ),
      );
    }

    final List<pw.Widget> rows = [];

    for (int i = 0; i < products.length; i += 2) {
      final dynamic item1 = products[i];
      final product1 = item1 is Map ? Map<String, dynamic>.from(item1) : <String, dynamic>{};
      
      final dynamic item2 = i + 1 < products.length ? products[i + 1] : null;
      final product2 = item2 is Map ? Map<String, dynamic>.from(item2) : null;

      rows.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: _buildProductCard(product1, productImages[i])),
            pw.SizedBox(width: 16),
            if (product2 != null)
              pw.Expanded(child: _buildProductCard(product2, productImages[i + 1]))
            else
              pw.Expanded(child: pw.Container()),
          ],
        ),
      );
      rows.add(pw.SizedBox(height: 16));
    }

    return pw.Column(children: rows);
  }

  static pw.Widget _buildProductCard(
    Map<String, dynamic> product,
    Uint8List? imageBytes,
  ) {
    final name = cleanText((product['name'] ?? product['title'] ?? 'Cadeau').toString());
    final brand = cleanText((product['brand'] ?? product['brand_or_store'] ?? '').toString());
    final priceRaw = product['price'] ?? product['product_price'];
    final price = priceRaw != null ? '$priceRaw EUR' : '';

    pw.Widget imageWidget;
    if (imageBytes != null && imageBytes.isNotEmpty) {
      try {
        imageWidget = pw.Image(
          pw.MemoryImage(imageBytes),
          fit: pw.BoxFit.cover,
        );
      } catch (_) {
        imageWidget = _placeholderImage();
      }
    } else {
      imageWidget = _placeholderImage();
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE5E0EC), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.ClipRRect(
            horizontalRadius: 11,
            verticalRadius: 11,
            child: pw.Container(
              height: 140,
              width: double.infinity,
              color: const PdfColor.fromInt(0xFFF7F5FA),
              child: imageWidget,
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (brand.isNotEmpty) ...[
                  pw.Text(
                    brand.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: const PdfColor.fromInt(0xFF8A2BE2),
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                  ),
                  pw.SizedBox(height: 2),
                ],
                pw.Text(
                  name,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF130E26),
                  ),
                  maxLines: 2,
                ),
                if (price.isNotEmpty) ...[
                  pw.SizedBox(height: 6),
                  pw.Text(
                    price,
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFFEC4899),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _placeholderImage() {
    return pw.Center(
      child: pw.Text(
        'DORON',
        style: const pw.TextStyle(color: PdfColors.grey400, fontSize: 14),
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(color: const PdfColor.fromInt(0xFFECE5F5), thickness: 0.8),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Genere avec l\'application DORON',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
            ),
            pw.Text(
              'doron-app.com',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: const PdfColor.fromInt(0xFF8A2BE2),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
