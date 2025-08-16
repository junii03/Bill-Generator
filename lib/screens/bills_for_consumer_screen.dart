import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Summary PDF: ${file.path}')));
        await Share.shareXFiles([XFile(file.path)], text: 'Bills Summary');
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
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
      await Printing.layoutPdf(onLayout: (_) async => await file.readAsBytes());
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
    return Scaffold(
      appBar: AppBar(title: Text('Bills: ${widget.consumer.name}')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : bills.isEmpty
          ? const Center(child: Text('No bills yet'))
          : ListView.builder(
              itemCount: bills.length,
              itemBuilder: (c, i) {
                final b = bills[i];
                return ListTile(
                  title: Text('Total: ${b.totalAmount.toStringAsFixed(2)}'),
                  subtitle: Text(_fmt.format(b.createdAt)),
                  trailing: _openingBillId == b.id
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf),
                  onTap: () => _openBillPdf(b),
                  onLongPress: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BillDetailScreen(billId: b.id!),
                    ),
                  ).then((_) => _load()),
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'export',
            onPressed: exporting ? null : _exportSummary,
            child: exporting
                ? const CircularProgressIndicator(strokeWidth: 2)
                : const Icon(Icons.picture_as_pdf),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
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
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
