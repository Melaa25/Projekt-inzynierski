import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/entities/material_entity.dart';

class MaterialLabelPrintService {
  static Future<void> printSingleLabel(MaterialEntity material) async {
    await printManyLabels([material]);
  }

  static Future<void> printManyLabels(List<MaterialEntity> materials) async {
    if (materials.isEmpty) {
      throw StateError('Brak materiałów do wydruku.');
    }

    await Printing.layoutPdf(
      name: materials.length == 1
          ? 'etykieta_${materials.first.serialNumber}.pdf'
          : 'etykiety_${materials.length}.pdf',
      onLayout: (_) => _buildLabelsDocument(materials),
    );
  }

  static Future<Uint8List> _buildLabelsDocument(List<MaterialEntity> materials) async {
    final pdf = pw.Document();
    const labelWidth = 62 * PdfPageFormat.mm;
    const labelHeight = 28 * PdfPageFormat.mm;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(8 * PdfPageFormat.mm),
        build: (context) {
          return [
            pw.Wrap(
              spacing: 3 * PdfPageFormat.mm,
              runSpacing: 3 * PdfPageFormat.mm,
              children: materials
                  .map(
                    (material) => _buildSingleSmallLabel(
                      material,
                      width: labelWidth,
                      height: labelHeight,
                    ),
                  )
                  .toList(),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSingleSmallLabel(
    MaterialEntity material, {
    required double width,
    required double height,
  }) {
    final safeName = _toPdfSafeText(material.name);

    return pw.Container(
      width: width,
      height: height,
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.6),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            safeName,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
            maxLines: 1,
          ),
          pw.SizedBox(height: 1.5),
          pw.Text(
            material.serialNumber,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Expanded(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.code128(),
              data: material.serialNumber,
              drawText: false,
            ),
          ),
        ],
      ),
    );
  }

  static String _toPdfSafeText(String input) {
    const replacements = <String, String>{
      'ą': 'a',
      'ć': 'c',
      'ę': 'e',
      'ł': 'l',
      'ń': 'n',
      'ó': 'o',
      'ś': 's',
      'ż': 'z',
      'ź': 'z',
      'Ą': 'A',
      'Ć': 'C',
      'Ę': 'E',
      'Ł': 'L',
      'Ń': 'N',
      'Ó': 'O',
      'Ś': 'S',
      'Ż': 'Z',
      'Ź': 'Z',
    };

    var output = input;
    replacements.forEach((key, value) {
      output = output.replaceAll(key, value);
    });

    return output;
  }
}
