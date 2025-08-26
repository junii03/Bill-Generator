import 'dart:io';
import 'package:flutter/cupertino.dart';
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
import 'bill_preview_screen.dart';

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
    if (!mounted) return;
    // Open preview screen immediately
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => BillPreviewScreen(pdfPath: file.path)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Detail'),
        actions: [
          IconButton(
            tooltip: 'Generate PDF',
            onPressed: (bill != null && consumer != null && reading != null)
                ? _generatePdf
                : null,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          if (pdfFile != null)
            IconButton(
              tooltip: 'Share',
              icon: const Icon(Icons.ios_share_outlined),
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
          : LayoutBuilder(
              builder: (context, constraints) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    children: [
                      _HeaderCard(
                        consumer: consumer!,
                        reading: reading!,
                        settings: settings,
                      ),
                      const SizedBox(height: 12),
                      _AmountSummaryCard(bill: bill!, settings: settings),
                      const SizedBox(height: 16),
                      Text(
                        'Adjustments',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (bill!.adjustments.isEmpty)
                        Text(
                          'No adjustments applied',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      if (bill!.adjustments.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: bill!.adjustments.map((a) {
                            final isNegative = a.amount < 0;
                            return Chip(
                              label: Text(
                                '${a.label}: ${FormatUtil.money(a.amount, settings)}',
                              ),
                              avatar: Icon(
                                isNegative
                                    ? Icons.remove_circle
                                    : Icons.add_circle,
                                color: isNegative
                                    ? scheme.error
                                    : scheme.primary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 24),
                      if (pdfFile != null)
                        SelectableText(
                          'PDF generated at: ${pdfFile!.path}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: (bill != null && consumer != null && reading != null)
          ? SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, -2),
                      blurRadius: 8,
                      color: Colors.black.withValues(alpha: 0.1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total: ${FormatUtil.money(bill!.totalAmount, settings)}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _generatePdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('PDF'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonalIcon(
                      onPressed: pdfFile == null
                          ? null
                          : () => SharePlus.instance.share(
                              ShareParams(
                                files: [XFile(pdfFile!.path)],
                                text: 'Electricity Bill for ${consumer!.name}',
                                previewThumbnail: XFile(pdfFile!.path),
                                fileNameOverrides: [
                                  "${DateTime.now().month}-${DateTime.now().day}-${DateTime.now().year}.pdf",
                                ],
                              ),
                            ),
                      icon: const Icon(Icons.ios_share_outlined),
                      label: const Text('Share'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Consumer consumer;
  final MeterReading reading;
  final SettingsProvider settings;
  const _HeaderCard({
    required this.consumer,
    required this.reading,
    required this.settings,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: Text(consumer.name.substring(0, 1).toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    consumer.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                _kv(
                  'Cost/Unit',
                  FormatUtil.money(consumer.costPerUnit, settings),
                ),
                _kv('Prev', reading.previousReading.toStringAsFixed(2)),
                _kv('Curr', reading.currentReading.toStringAsFixed(2)),
                _kv(
                  'Consumed',
                  '${reading.kwhConsumed.toStringAsFixed(2)} kWh',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        k,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 2),
      Text(v, style: const TextStyle(fontWeight: FontWeight.w500)),
    ],
  );
}

class _AmountSummaryCard extends StatelessWidget {
  final Bill bill;
  final SettingsProvider settings;
  const _AmountSummaryCard({required this.bill, required this.settings});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amounts',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _row('Base', FormatUtil.money(bill.baseAmount, settings)),
            _row(
              'Adjustments',
              FormatUtil.money(bill.adjustmentsTotal, settings),
            ),
            const Divider(height: 28),
            _row(
              'Total',
              FormatUtil.money(bill.totalAmount, settings),
              emphasize: true,
              color: scheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    bool emphasize = false,
    Color? color,
  }) {
    final style = TextStyle(
      fontWeight: emphasize ? FontWeight.bold : FontWeight.w500,
      fontSize: emphasize ? 18 : 14,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
