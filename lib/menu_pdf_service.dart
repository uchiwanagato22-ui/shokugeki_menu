import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_config.dart';

// ═══════════════════════════════════════════════════════
//  MENU PDF SERVICE
//  Génère un PDF propre du menu du restaurant — pratique pour
//  imprimer en salle, envoyer par WhatsApp, ou avoir une carte
//  de secours si l'app est en panne.
// ═══════════════════════════════════════════════════════

class MenuPdfService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> genererEtPartager({
    required String nomRestaurant,
    String? logoUrl,
  }) async {
    final snap = await _db.collection(AppConfig.menu).orderBy('categorie').get();
    final plats = snap.docs.map((d) => d.data()).toList();

    // Regrouper par catégorie, dans l'ordre d'apparition
    final Map<String, List<Map<String, dynamic>>> parCategorie = {};
    for (final plat in plats) {
      if (plat['disponible'] == false) continue; // pas les plats en rupture
      final cat = (plat['categorie']?.toString().trim().isNotEmpty ?? false)
          ? plat['categorie'].toString()
          : 'Autres';
      parCategorie.putIfAbsent(cat, () => []).add(plat);
    }

    final doc = pw.Document();
    final rouge = PdfColor.fromHex('#D92D20');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              nomRestaurant.toUpperCase(),
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: rouge),
            ),
            pw.SizedBox(height: 4),
            pw.Text('NOTRE CARTE', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
            pw.SizedBox(height: 16),
            pw.Divider(color: rouge, thickness: 1.5),
          ],
        ),
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Genere via Shokugeki Menu — page ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            textAlign: pw.TextAlign.center,
          ),
        ),
        build: (context) {
          final widgets = <pw.Widget>[];

          parCategorie.forEach((categorie, listePlats) {
            widgets.add(pw.SizedBox(height: 14));
            widgets.add(pw.Text(
              categorie.toUpperCase(),
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: rouge),
            ));
            widgets.add(pw.SizedBox(height: 8));

            for (final plat in listePlats) {
              final nom = plat['nom']?.toString() ?? '';
              final description = plat['description']?.toString() ?? '';
              final prix = plat['prix'];
              final prixTexte = prix != null ? '${prix.toString()} MRU' : '';

              widgets.add(pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(nom, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          if (description.isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 2),
                              child: pw.Text(
                                description,
                                style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey600),
                              ),
                            ),
                        ],
                      ),
                    ),
                    pw.Text(prixTexte, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: rouge)),
                  ],
                ),
              ));
            }
          });

          return widgets;
        },
      ),
    );

    final bytes = await doc.save();
    await Printing.sharePdf(bytes: bytes, filename: 'menu_${nomRestaurant.toLowerCase().replaceAll(' ', '_')}.pdf');
  }
}
