import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart' hide Consumer;
import '../services/database_service.dart';
import '../services/pdf_service.dart';
import '../services/settings_service.dart';
import '../utils/format.dart';
import '../models/bill.dart';
import '../models/consumer.dart';
import '../models/meter_reading.dart';

class BillDetailScreen extends StatefulWidget {
  final int billId;
  const BillDetailScreen({super.key, required this.billId});

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  Bill? bill;
  Consumer? consumer;
  MeterReading? reading;
  bool loading = true;
  File? pdfFile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DatabaseService.instance;
    final b = await db.getBill(widget.billId);
    if (b == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final r = await db.getMeterReading(b.meterReadingId);
    final c = await db.getConsumer(b.consumerId);
    setState(() {
      bill = b;
      reading = r;
      consumer = c;
      loading = false;
    });
  }

  Future<void> _generatePdf() async {
    if (bill == null || consumer == null || reading == null) return;
    final file = await PdfService.generateBillPdf(
      bill: bill!,
      consumer: consumer!,
      reading: reading!,
    );
    setState(() => pdfFile = file);
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PDF generated')));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Detail'),
        actions: [
          IconButton(
            onPressed: (bill != null && consumer != null && reading != null)
                ? _generatePdf
                : null,
            icon: const Icon(Icons.picture_as_pdf),
          ),
          if (pdfFile != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => Share.shareXFiles([
                XFile(pdfFile!.path),
              ], text: 'Electricity Bill'),
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : bill == null
          ? const Center(child: Text('Bill not found'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Consumer: ${consumer!.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Cost/Unit: ${FormatUtil.money(consumer!.costPerUnit, settings)}',
                ),
                const SizedBox(height: 12),
                Text('Previous Reading: ${reading!.previousReading}'),
                Text('Current Reading: ${reading!.currentReading}'),
                Text('Consumed: ${reading!.kwhConsumed} kWh'),
                const SizedBox(height: 12),
                Text(
                  'Base Amount: ${FormatUtil.money(bill!.baseAmount, settings)}',
                ),
                Text(
                  'Adjustments Total: ${FormatUtil.money(bill!.adjustmentsTotal, settings)}',
                ),
                const Divider(height: 32),
                Text(
                  'Total: ${FormatUtil.money(bill!.totalAmount, settings)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Adjustments:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (bill!.adjustments.isEmpty) const Text('None'),
                if (bill!.adjustments.isNotEmpty)
                  ...bill!.adjustments.map(
                    (a) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(a.label),
                      trailing: Text(FormatUtil.money(a.amount, settings)),
                    ),
                  ),
                const SizedBox(height: 24),
                if (pdfFile != null)
                  Text(
                    'PDF: ${pdfFile!.path}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ElevatedButton.icon(
                  onPressed:
                      (bill != null && consumer != null && reading != null)
                      ? _generatePdf
                      : null,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Generate PDF'),
                ),
                if (pdfFile != null)
                  ElevatedButton.icon(
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(
                        files: [XFile(pdfFile!.path)],
                        text: 'Electricity Bill for ${consumer!.name}',
                        previewThumbnail: XFile(pdfFile!.path),
                        fileNameOverrides: [
                          "${DateTime.now().month}-${DateTime.now().day}-${DateTime.now().year}.pdf",
                        ],
                      ),
                    ),
                    icon: const Icon(Icons.share),
                    label: const Text('Share PDF'),
                  ),
              ],
            ),
    );
  }
}
