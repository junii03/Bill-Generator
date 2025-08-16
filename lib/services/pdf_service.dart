import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
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
                  height: 120,
                  fit: pw.BoxFit.cover,
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
                  height: 120,
                  fit: pw.BoxFit.cover,
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
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Electricity Bill',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Date: ${dateFmt.format(bill.createdAt)}'),
              pw.SizedBox(height: 16),
              pw.Text('Consumer'),
              pw.Text('Name: ${consumer.name}'),
              pw.Text('Cost/Unit: ${consumer.costPerUnit.toStringAsFixed(2)}'),
              pw.SizedBox(height: 16),
              pw.Text('Meter Reading'),
              pw.Text('Previous: ${reading.previousReading} kWh'),
              pw.Text('Current: ${reading.currentReading} kWh'),
              pw.Text('Consumed: ${reading.kwhConsumed} kWh'),
              pw.SizedBox(height: 16),
              meterImages(),
              pw.SizedBox(height: 16),
              pw.Text('Charges'),
              pw.Text('Base Amount: ${bill.baseAmount.toStringAsFixed(2)}'),
              if (bill.adjustments.isNotEmpty)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 8),
                    pw.Text('Adjustments:'),
                    ...bill.adjustments.map(
                      (a) =>
                          pw.Text('${a.label}: ${a.amount.toStringAsFixed(2)}'),
                    ),
                    pw.Text(
                      'Adjustments Total: ${bill.adjustmentsTotal.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              pw.Divider(),
              pw.Text(
                'Total: ${bill.totalAmount.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
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
            pw.Table.fromTextArray(
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
