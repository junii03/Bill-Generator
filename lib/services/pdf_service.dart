import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/bill.dart';
import '../models/consumer.dart';
import '../models/meter_reading.dart';
import '../services/database_service.dart';

class PdfService {
  static Future<File> generateBillPdf({
    required Bill bill,
    required Consumer consumer,
    required MeterReading reading,
  }) async {
    final doc = pw.Document();
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');
    pw.Widget meterImages() {
      final List<pw.Widget> imgs = [];
      if (reading.previousImagePath != null) {
        final f = File(reading.previousImagePath!);
        if (f.existsSync()) {
          final bytes = f.readAsBytesSync();
          imgs.add(
            pw.Column(
              children: [
                pw.Text('Previous'),
                pw.SizedBox(height: 4),
                pw.Image(
                  pw.MemoryImage(bytes),
                  height: 200,
                  fit: pw.BoxFit.contain,
                ),
              ],
            ),
          );
        }
      }
      if (reading.currentImagePath != null) {
        final f = File(reading.currentImagePath!);
        if (f.existsSync()) {
          final bytes = f.readAsBytesSync();
          imgs.add(
            pw.Column(
              children: [
                pw.Text('Current'),
                pw.SizedBox(height: 4),
                pw.Image(
                  pw.MemoryImage(bytes),
                  height: 200,
                  fit: pw.BoxFit.contain,
                ),
              ],
            ),
          );
        }
      }
      if (imgs.isEmpty) return pw.SizedBox();
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Meter Images'),
          pw.SizedBox(height: 8),
          pw.Row(children: imgs.map((w) => pw.Expanded(child: w)).toList()),
        ],
      );
    }

    doc.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Electricity Bill',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text('Date: ${dateFmt.format(bill.createdAt)}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              // Consumer Details Box
              pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                padding: const pw.EdgeInsets.all(8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Consumer Information',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Name: ${consumer.name}'),
                    pw.Text(
                      'Cost per Unit: ${consumer.costPerUnit.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Meter Reading
              pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                padding: const pw.EdgeInsets.all(8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Meter Readings',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Previous: ${reading.previousReading} kWh'),
                        pw.Text('Current: ${reading.currentReading} kWh'),
                        pw.Text('Consumed: ${reading.kwhConsumed} kWh'),
                      ],
                    ),
                  ],
                ),
              ),

              pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                padding: const pw.EdgeInsets.all(8),
                margin: const pw.EdgeInsets.symmetric(vertical: 20),
                child: meterImages(),
              ),
              pw.SizedBox(height: 20),

              // Charges Table
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Description',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Amount',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Base Amount'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(bill.baseAmount.toStringAsFixed(2)),
                      ),
                    ],
                  ),
                  ...bill.adjustments.map(
                    (a) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(a.label),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(a.amount.toStringAsFixed(2)),
                        ),
                      ],
                    ),
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Adjustments Total',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          bill.adjustmentsTotal.toStringAsFixed(2),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Grand Total',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          bill.totalAmount.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // // Footer / Notes
              // pw.Text(
              //   'Note: This is a system-generated bill and does not require a signature.',
              //   style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              // ),
            ],
          );
        },
      ),
    );

    final dir = await _billsDir();
    final file = File(
      '${dir.path}/bill_${bill.id}_${bill.createdAt.millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await doc.save());
    return file;
  }

  static Future<File> generateBillsSummaryPdf({
    required Consumer consumer,
  }) async {
    final db = DatabaseService.instance;
    final bills = await db.getBillsForConsumer(consumer.id!);
    final readings = <int, MeterReading>{};
    for (final b in bills) {
      readings[b.meterReadingId] =
          await db.getMeterReading(b.meterReadingId) ??
          readings[b.meterReadingId]!;
    }
    final doc = pw.Document();
    final dateFmt = DateFormat('yyyy-MM-dd');
    doc.addPage(
      pw.MultiPage(
        build: (ctx) {
          return [
            pw.Text(
              'Bills Summary for ${consumer.name}',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Consumed', 'Base', 'Adj', 'Total'],
              data: bills.map((b) {
                final r = readings[b.meterReadingId];
                return [
                  dateFmt.format(b.createdAt),
                  r?.kwhConsumed.toStringAsFixed(2) ?? '-',
                  b.baseAmount.toStringAsFixed(2),
                  b.adjustmentsTotal.toStringAsFixed(2),
                  b.totalAmount.toStringAsFixed(2),
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Totals:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Base: ${bills.fold<double>(0, (s, b) => s + b.baseAmount).toStringAsFixed(2)}',
            ),
            pw.Text(
              'Adjustments: ${bills.fold<double>(0, (s, b) => s + b.adjustmentsTotal).toStringAsFixed(2)}',
            ),
            pw.Text(
              'Grand Total: ${bills.fold<double>(0, (s, b) => s + b.totalAmount).toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ];
        },
      ),
    );
    final dir = await _billsDir();
    final file = File(
      '${dir.path}/bills_summary_${consumer.id}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await doc.save());
    return file;
  }

  static Future<Directory> _billsDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/bills');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}
