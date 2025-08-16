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
    // Currency symbol (display purpose only, no logic change)
    const currencySymbol = 'Rs';
    String money(double v) => '$currencySymbol ${v.toStringAsFixed(2)}';

    pw.Widget meterImages() {
      final List<pw.Widget> imgs = [];
      if (reading.previousImagePath != null) {
        final f = File(reading.previousImagePath!);
        if (f.existsSync()) {
          final bytes = f.readAsBytesSync();
          imgs.add(
            pw.Column(
              children: [
                pw.Text(
                  'Previous',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400, width: .5),
                  ),
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Image(
                    pw.MemoryImage(bytes),
                    height: 160,
                    fit: pw.BoxFit.contain,
                  ),
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
                pw.Text(
                  'Current',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400, width: .5),
                  ),
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Image(
                    pw.MemoryImage(bytes),
                    height: 160,
                    fit: pw.BoxFit.contain,
                  ),
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
          pw.Text(
            'Meter Images',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: imgs
                .map(
                  (w) => pw.Expanded(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6),
                      child: w,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      );
    }

    doc.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Enhanced Header
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Electricity Bill',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Generated: ${dateFmt.format(bill.createdAt)}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Bill ID: ${bill.id}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          'Consumer ID: ${consumer.id ?? '-'}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 12),

              // Consumer Details & Usage Summary
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1, color: PdfColors.grey400),
                  color: PdfColors.grey50,
                ),
                padding: const pw.EdgeInsets.all(10),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Consumer Information',
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text('Name: ${consumer.name}'),
                          pw.Text(
                            'Rate / Unit: ${money(consumer.costPerUnit)}',
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.grey300,
                            width: .5,
                          ),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Usage Summary',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Previous:'),
                                pw.Text('${reading.previousReading} kWh'),
                              ],
                            ),
                            pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Current:'),
                                pw.Text('${reading.currentReading} kWh'),
                              ],
                            ),
                            pw.Divider(),
                            pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'Units Consumed',
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.Text(
                                  '${reading.kwhConsumed} kWh',
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 18),

              // Meter Images (if any)
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1, color: PdfColors.grey300),
                ),
                padding: const pw.EdgeInsets.all(10),
                child: meterImages(),
              ),
              pw.SizedBox(height: 18),

              // Charges & Calculation Breakdown
              pw.Text(
                'Billing Breakdown',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: .8),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _cellHeader('Description'),
                      _cellHeader('Units'),
                      _cellHeader('Rate'),
                      _cellHeader('Amount'),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _cell('Energy Charge'),
                      _cell(reading.kwhConsumed.toStringAsFixed(2)),
                      _cell(money(consumer.costPerUnit)),
                      _cell(money(bill.baseAmount)),
                    ],
                  ),
                  // Adjustments header (only if adjustments exist)
                  if (bill.adjustments.isNotEmpty)
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        _cellBold('Adjustments (${bill.adjustments.length})'),
                        _cell(''),
                        _cell(''),
                        _cell(money(bill.adjustmentsTotal), bold: true),
                      ],
                    ),
                  ...bill.adjustments.map(
                    (a) => pw.TableRow(
                      children: [
                        _cell(a.label),
                        _cell(''),
                        _cell(''),
                        _cell(money(a.amount)),
                      ],
                    ),
                  ),
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _cellBold('Grand Total'),
                      _cell(''),
                      _cell(''),
                      _cell(money(bill.totalAmount), bold: true, large: true),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),

              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: .5),
                  color: PdfColors.grey50,
                ),
                child: pw.Text(
                  'Note: This is a system-generated bill and does not require a signature.',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    final dir = await _billsDir();
    // Overwrite existing per-bill PDF (single file per bill id)
    final file = File('${dir.path}/bill_${bill.id}.pdf');
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
    const currencySymbol = 'Rs';
    String money(double v) => '$currencySymbol ${v.toStringAsFixed(2)}';

    // Pre-computed totals (display only)
    final totalBase = bills.fold<double>(0, (s, b) => s + b.baseAmount);
    final totalAdj = bills.fold<double>(0, (s, b) => s + b.adjustmentsTotal);
    final totalGrand = bills.fold<double>(0, (s, b) => s + b.totalAmount);

    doc.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        header: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Bills Summary',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Consumer: ${consumer.name}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Page ${ctx.pageNumber}/${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Generated on ${dateFmt.format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (ctx) {
          return [
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: .7),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _cellHeader('Date'),
                    _cellHeader('Consumed'),
                    _cellHeader('Base'),
                    _cellHeader('Adj'),
                    _cellHeader('Total'),
                  ],
                ),
                ...List.generate(bills.length, (index) {
                  final b = bills[index];
                  final r = readings[b.meterReadingId];
                  final alt = index % 2 == 0;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: alt ? PdfColors.grey50 : PdfColors.white,
                    ),
                    children: [
                      _cell(dateFmt.format(b.createdAt)),
                      _cell(r?.kwhConsumed.toStringAsFixed(2) ?? '-'),
                      _cell(money(b.baseAmount)),
                      _cell(money(b.adjustmentsTotal)),
                      _cell(money(b.totalAmount)),
                    ],
                  );
                }),
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _cellBold('Totals'),
                    _cell(''),
                    _cell(money(totalBase), bold: true),
                    _cell(money(totalAdj), bold: true),
                    _cell(money(totalGrand), bold: true),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 18),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: .6),
                color: PdfColors.grey50,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Summary Totals',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('Base: ${money(totalBase)}'),
                  pw.Text('Adjustments: ${money(totalAdj)}'),
                  pw.Text(
                    'Grand Total: ${money(totalGrand)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );
    final dir = await _billsDir();
    // Overwrite existing summary PDF per consumer
    final file = File('${dir.path}/bills_summary_${consumer.id}.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  static pw.Widget _cell(
    String text, {
    bool bold = false,
    bool large = false,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: large ? 12 : 10,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
  static pw.Widget _cellHeader(String text) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(
      text,
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
    ),
  );
  static pw.Widget _cellBold(String text, {bool large = false}) =>
      _cell(text, bold: true, large: large);

  static Future<Directory> _billsDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/bills');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}
