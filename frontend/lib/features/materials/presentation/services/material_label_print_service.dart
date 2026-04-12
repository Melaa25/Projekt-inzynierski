import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/entities/material_entity.dart';

class MaterialLabelPrintService {
  static Future<void> printSingleLabel(MaterialEntity material) async {
    await Printing.layoutPdf(
      name: 'etykieta_${material.serialNumber}.pdf',
      onLayout: (_) => _buildSingleLabel(material),
    );
  }

  static Future<Uint8List> _buildSingleLabel(MaterialEntity material) async {
    final pdf = pw.Document();
    final safeName = _toPdfSafeText(material.name);

    const pageFormat = PdfPageFormat(
      90 * PdfPageFormat.mm,
      54 * PdfPageFormat.mm,
      marginAll: 4 * PdfPageFormat.mm,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.8),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  safeName,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  maxLines: 1,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Kod seryjny: ${material.serialNumber}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Waga: ${material.weight.toStringAsFixed(2)} | Dlugosc: ${material.length.toStringAsFixed(2)}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.SizedBox(height: 6),
                pw.Expanded(
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.code128(),
                    data: material.serialNumber,
                    drawText: true,
                    textStyle: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
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
