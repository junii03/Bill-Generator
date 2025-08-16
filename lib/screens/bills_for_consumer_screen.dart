import 'package:bill_generator/screens/bill_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/consumer.dart';
import '../models/bill.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';
import 'bill_detail_screen.dart';
import 'new_bill_screen.dart';
import 'package:intl/intl.dart';

class BillsForConsumerScreen extends StatefulWidget {
  final Consumer consumer;
  const BillsForConsumerScreen({super.key, required this.consumer});

  @override
  State<BillsForConsumerScreen> createState() => _BillsForConsumerScreenState();
}

class _BillsForConsumerScreenState extends State<BillsForConsumerScreen> {
  List<Bill> bills = [];
  bool loading = true;
  bool exporting = false;
  final _fmt = DateFormat('yyyy-MM-dd HH:mm');
  int? _openingBillId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await DatabaseService.instance.getBillsForConsumer(
      widget.consumer.id!,
    );
    setState(() {
      bills = data;
      loading = false;
    });
  }

  Future<void> _exportSummary() async {
    setState(() => exporting = true);
    try {
      final file = await PdfService.generateBillsSummaryPdf(
        consumer: widget.consumer,
      );
      if (mounted) {
        // Open preview screen immediately
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BillPreviewScreen(pdfPath: file.path),
          ),
        );
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            previewThumbnail: XFile(file.path),
            fileNameOverrides: [
              "${DateTime.now().month}-${DateTime.now().day}-${DateTime.now().year}.pdf",
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  Future<void> _openBillPdf(Bill bill) async {
    if (_openingBillId != null) return; // prevent concurrent
    setState(() => _openingBillId = bill.id);
    try {
      final reading = await DatabaseService.instance.getMeterReading(
        bill.meterReadingId,
      );
      if (reading == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Meter reading not found')),
          );
        }
        return;
      }
      final file = await PdfService.generateBillPdf(
        bill: bill,
        consumer: widget.consumer,
        reading: reading,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BillPreviewScreen(pdfPath: file.path),
        ),
      ).then((_) {
        if (mounted) setState(() => _openingBillId = null);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to open PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _openingBillId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text('Bills: ${widget.consumer.name}')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : bills.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 80,
                      color: scheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No bills yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first bill for this consumer.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                NewBillScreen(consumer: widget.consumer),
                          ),
                        );
                        _load();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('New Bill'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                children: [
                  _HeaderSummary(consumer: widget.consumer, bills: bills),
                  const SizedBox(height: 12),
                  ...bills.map(
                    (b) => _BillCard(
                      bill: b,
                      opening: _openingBillId == b.id,
                      fmt: _fmt,
                      onOpen: () => _openBillPdf(b),
                      onLongPress: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BillDetailScreen(billId: b.id!),
                        ),
                      ).then((_) => _load()),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Tooltip(
            message: 'Export summary PDF',
            child: FloatingActionButton.small(
              heroTag: 'export',
              onPressed: exporting ? null : _exportSummary,
              child: exporting
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : const Icon(Icons.picture_as_pdf_outlined),
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NewBillScreen(consumer: widget.consumer),
                ),
              );
              _load();
            },
            icon: const Icon(Icons.add),
            label: const Text('Bill'),
          ),
        ],
      ),
    );
  }
}

class _HeaderSummary extends StatelessWidget {
  final Consumer consumer;
  final List<Bill> bills;
  const _HeaderSummary({required this.consumer, required this.bills});
  @override
  Widget build(BuildContext context) {
    final total = bills.fold<double>(0, (s, b) => s + b.totalAmount);
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              child: Text(consumer.name.substring(0, 1).toUpperCase()),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    consumer.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${bills.length} bills',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Total Billed',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  total.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final Bill bill;
  final bool opening;
  final DateFormat fmt;
  final VoidCallback onOpen;
  final VoidCallback onLongPress;
  const _BillCard({
    required this.bill,
    required this.opening,
    required this.fmt,
    required this.onOpen,
    required this.onLongPress,
  });
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Icon(Icons.receipt_outlined, color: scheme.primary, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total: ${bill.totalAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fmt.format(bill.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              opening
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
            ],
          ),
        ),
      ),
    );
  }
}
