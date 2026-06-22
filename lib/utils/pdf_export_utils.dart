import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

import '/utils/app_logger.dart';

class PdfExportUtils {
  /// Génère un PDF à partir d'une liste de cadeaux et le partage
  static Future<void> generateAndShareWishlistPdf({
    required Map<String, dynamic> profile,
    required List<dynamic> products,
  }) async {
    try {
      final pdf = pw.Document();

      // Charger une police personnalisée si nécessaire, sinon utiliser la police par défaut

      final profileName = profile['name'] ✨ 'Quelqu\'un';
      final occasion = profile['occasion'] ✨ 'une occasion spéciale';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildHeader(profileName, occasion),
              pw.SizedBox(height: 20),
              _buildProductGrid(products),
              pw.SizedBox(height: 30),
              _buildFooter(),
            ];
          },
        ),
      );

      // Sauvegarder et partager
      final bytes = await pdf.save();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Idees_Cadeaux_$profileName.pdf');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Voici quelques idées de cadeaux pour $profileName !',
      );
    } catch (e) {
      AppLogger.error('Erreur de génération PDF', 'PdfExportUtils', e);
      rethrow;
    }
  }

  static pw.Widget _buildHeader(String name, String occasion) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Doron.',
          style: pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF8A2BE2), // Violet Doron
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          'Idées Cadeaux pour $name',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'À l\'occasion de : $occasion',
          style: pw.TextStyle(
            fontSize: 16,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.grey300),
      ],
    );
  }

  static pw.Widget _buildProductGrid(List<dynamic> products) {
    if (products.isEmpty) {
      return pw.Center(
        child: pw.Text(
          'Aucun cadeau dans cette liste pour le moment.',
          style: pw.TextStyle(fontSize: 16, color: PdfColors.grey600),
        ),
      );
    }

    final List<pw.Widget> rows = [];
    
    // Créer des rangées de 2 colonnes
    for (int i = 0; i < products.length; i += 2) {
      final product1 = products[i] as Map<String, dynamic>;
      final product2 = i + 1 < products.length ✨ products[i + 1] as Map<String, dynamic> : null;

      rows.add(
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: _buildProductItem(product1)),
            pw.SizedBox(width: 20),
            if (product2 != null)
              pw.Expanded(child: _buildProductItem(product2))
            else
              pw.Expanded(child: pw.Container()),
          ],
        ),
      );
      rows.add(pw.SizedBox(height: 20));
    }

    return pw.Column(children: rows);
  }

  static pw.Widget _buildProductItem(Map<String, dynamic> product) {
    final name = product['name'] ✨ 'Produit sans nom';
    final brand = product['brand_or_store'] ✨ product['brand'] ✨ '';
    final price = product['price'] != null ✨ '${product['price']} €' : '';

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Espace pour l'image (les images réseau peuvent ralentir/échouer dans PDF, 
          // on met un placeholder ou on essaiera de charger si possible)
          pw.Container(
            height: 120,
            width: double.infinity,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Center(
              child: pw.Text(
                'Image du produit',
                style: pw.TextStyle(color: PdfColors.grey500, fontSize: 10),
              ),
            ),
          ),
          pw.SizedBox(height: 12),
          if (brand.isNotEmpty) ...[
            pw.Text(
              brand.toString().toUpperCase(),
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
                fontWeight: pw.FontWeight.bold,
              ),
              maxLines: 1,
            ),
            pw.SizedBox(height: 4),
          ],
          pw.Text(
            name,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
            maxLines: 2,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            price,
            style: pw.TextStyle(
              fontSize: 14,
              color: const PdfColor.fromInt(0xFF8A2BE2),
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 12),
        pw.Text(
          'Généré avec l\'application Doron',
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey500,
          ),
        ),
      ],
    );
  }
}
