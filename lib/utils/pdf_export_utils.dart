import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfExportUtils {
  /// Génère et partage (ou télécharge) un PDF stylisé contenant la liste des cadeaux
  static Future<void> generateAndShareWishlistPdf({
    required Map<String, dynamic> profile,
    required List<dynamic> products,
  }) async {
    final pdf = pw.Document();

    // Couleurs de la marque (approx. pour le PDF)
    final PdfColor violetColor = PdfColor.fromHex('#8A2BE2');
    final PdfColor darkBlue = PdfColor.fromHex('#062248');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              padding: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'DORON',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: violetColor,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Idées Cadeaux pour ${profile['name']}',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: darkBlue,
                    ),
                  ),
                  pw.Text(
                    '${profile['relation']} - ${profile['occasion']}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),

            // Liste des produits
            ...products.map((dynamic productObj) {
              final product = productObj as Map<String, dynamic>;
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 16),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            product['name'] ?? 'Produit',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Marque: ${product['brand'] ?? 'Inconnue'}',
                            style: const pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey600,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            '${product['price']}',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: violetColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            
            pw.SizedBox(height: 30),
            
            // Footer
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                'Généré via l\'application Doron',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey500,
                ),
              ),
            ),
          ];
        },
      ),
    );

    // Partage le PDF (affiche l'interface système pour partager/imprimer)
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'cadeaux_${profile['name']}.pdf',
    );
  }
}
