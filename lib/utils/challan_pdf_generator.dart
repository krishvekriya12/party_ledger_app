import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/challan.dart';

class ChallanPdfGenerator {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final PdfColor _pinkAccent = PdfColor.fromHex('#E91E63');
  static final PdfColor _lightPink = PdfColor.fromHex('#FCE4EC');
  static final PdfColor _darkText = PdfColor.fromHex('#1C1C1E');

  static Future<pw.Document> generatePdf(Challan challan) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _pinkAccent, width: 2),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Top Header Section
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // From Column
                    pw.Expanded(
                      flex: 3,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'From:',
                            style: pw.TextStyle(
                              color: _pinkAccent,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            challan.fromName.isNotEmpty
                                ? challan.fromName
                                : 'Yashvant Vissani',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: _darkText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bill of Supply Header Box
                    pw.Expanded(
                      flex: 4,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: _pinkAccent, width: 1.5),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'BILL OF SUPPLY',
                              style: pw.TextStyle(
                                color: _pinkAccent,
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              'CASH / CREDIT MEMO',
                              style: pw.TextStyle(
                                color: _pinkAccent,
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 6),
                            pw.Row(
                              children: [
                                pw.Text('Bill No.: ',
                                    style: pw.TextStyle(
                                        fontSize: 11, color: _pinkAccent)),
                                pw.Text(challan.billNo,
                                    style: pw.TextStyle(
                                        fontSize: 11,
                                        fontWeight: pw.FontWeight.bold)),
                              ],
                            ),
                            pw.Row(
                              children: [
                                pw.Text('Date: ',
                                    style: pw.TextStyle(
                                        fontSize: 11, color: _pinkAccent)),
                                pw.Text(_dateFormat.format(challan.challanDate),
                                    style: pw.TextStyle(
                                        fontSize: 11,
                                        fontWeight: pw.FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 10),
                pw.Divider(color: _pinkAccent, thickness: 1.5),
                pw.SizedBox(height: 6),

                // Party Name Row
                pw.Row(
                  children: [
                    pw.Text('M/s. ',
                        style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: _pinkAccent)),
                    pw.Text(challan.partyName,
                        style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: _darkText)),
                  ],
                ),

                pw.SizedBox(height: 8),

                // GSTIN Box format (15 boxes)
                _buildGstinSection(challan.gstin),

                pw.SizedBox(height: 12),

                // Table of Items
                pw.Expanded(
                  child: _buildItemsTable(challan.items),
                ),

                pw.SizedBox(height: 10),

                // Summary Total Row
                _buildTotalRow(challan),

                pw.SizedBox(height: 12),
                pw.Divider(color: _pinkAccent, thickness: 1.5),
                pw.SizedBox(height: 6),

                // Footer Note & Signatures
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          challan.note.isNotEmpty
                              ? challan.note
                              : 'Goods once sold will not be taken back.',
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.grey700),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Thank you',
                          style: pw.TextStyle(
                            color: _pinkAccent,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          challan.preparedBy.isNotEmpty
                              ? challan.preparedBy
                              : (challan.fromName.isNotEmpty
                                  ? challan.fromName
                                  : 'Yashvant Vissani'),
                          style: pw.TextStyle(
                              fontSize: 12, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Prepared By',
                          style: pw.TextStyle(fontSize: 10, color: _pinkAccent),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildGstinSection(String gstin) {
    final chars = gstin.padRight(15, ' ').split('');
    return pw.Row(
      children: [
        pw.Text('GSTIN / UIN No.: ',
            style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: _pinkAccent)),
        pw.SizedBox(width: 4),
        ...List.generate(15, (index) {
          final char = index < chars.length ? chars[index] : '';
          return pw.Container(
            width: 14,
            height: 16,
            margin: const pw.EdgeInsets.only(right: 1),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _pinkAccent, width: 0.8),
            ),
            child: pw.Center(
              child: pw.Text(
                char,
                style: pw.TextStyle(
                    fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
            ),
          );
        }),
      ],
    );
  }

  static pw.Widget _buildItemsTable(List<ChallanItem> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: _pinkAccent, width: 1),
      columnWidths: {
        0: const pw.FlexColumnWidth(3.5), // Particular
        1: const pw.FlexColumnWidth(2.5), // Quantity (size/pis)
        2: const pw.FlexColumnWidth(1.5), // Rate
        3: const pw.FlexColumnWidth(2.0), // Amount
      },
      children: [
        // Table Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _lightPink),
          children: [
            _headerCell('Particular'),
            _headerCell('Quantity (size / pis)'),
            _headerCell('Rate (pis)'),
            _headerCell('Amount (pis)'),
          ],
        ),
        // Item Rows
        ...items.map((item) {
          final sizeDetails = item.sizes.entries
              .where((e) => e.value > 0)
              .map((e) => '${e.key}: ${e.value} pis')
              .join('\n');

          return pw.TableRow(
            children: [
              // Particular
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  item.particular,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 11),
                ),
              ),
              // Quantity (size details)
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  sizeDetails.isNotEmpty
                      ? sizeDetails
                      : '${item.totalPcs} pis',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              // Rate
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  '₹${item.rate.toStringAsFixed(2)}',
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              // Amount
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  '₹${item.amount.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: _pinkAccent,
          fontWeight: pw.FontWeight.bold,
          fontSize: 11,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTotalRow(Challan challan) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _pinkAccent, width: 1),
        color: _lightPink,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'TOTAL',
            style: pw.TextStyle(
              color: _pinkAccent,
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
          ),
          pw.Text(
            'Total Pcs: ${challan.totalPcs} pis',
            style: pw.TextStyle(
              color: _pinkAccent,
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
          ),
          pw.Text(
            'Total Amount: ₹${challan.totalAmount.toStringAsFixed(2)}',
            style: pw.TextStyle(
              color: _pinkAccent,
              fontWeight: pw.FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  /// Print / View PDF using system print dialogue
  static Future<void> printChallan(Challan challan) async {
    final pdf = await generatePdf(challan);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Challan_${challan.billNo}_${challan.partyName}',
    );
  }

  /// Share PDF file via WhatsApp, Email, File Share
  static Future<void> shareChallan(Challan challan) async {
    final pdf = await generatePdf(challan);
    final bytes = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final fileName = 'Challan_${challan.billNo}_${challan.partyName.replaceAll(' ', '_')}.pdf';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Challan / Bill of Supply #${challan.billNo} - ${challan.partyName}',
    );
  }
}
