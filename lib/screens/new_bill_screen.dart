import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' hide Consumer;
import '../models/consumer.dart';
import '../models/meter_reading.dart';
import '../models/adjustment.dart';
import '../services/database_service.dart';
import '../services/image_service.dart';
import '../services/settings_service.dart';
import 'bill_detail_screen.dart';

class NewBillScreen extends StatefulWidget {
  final Consumer consumer;
  const NewBillScreen({super.key, required this.consumer});

  @override
  State<NewBillScreen> createState() => _NewBillScreenState();
}

class _NewBillScreenState extends State<NewBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prevCtrl = TextEditingController();
  final _currCtrl = TextEditingController();
  List<Adjustment> adjustments = [];
  String? prevImagePath;
  String? currImagePath;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _loadLastReading();
  }

  Future<void> _loadLastReading() async {
    final last = await DatabaseService.instance.getLastMeterReadingForConsumer(
      widget.consumer.id!,
    );
    if (!mounted || last == null) return;
    setState(() {
      // Use last current as new previous
      _prevCtrl.text = last.currentReading.toStringAsFixed(2);
      // Carry forward the last current image as the new previous image reference
      prevImagePath = last.currentImagePath;
    });
  }

  double get consumed {
    final p = double.tryParse(_prevCtrl.text.trim()) ?? 0;
    final c = double.tryParse(_currCtrl.text.trim()) ?? 0;
    final diff = c - p;
    return diff < 0 ? 0 : diff;
  }

  double get baseAmount => consumed * widget.consumer.costPerUnit;
  double get defaultTaxAmount {
    final settings = context.read<SettingsProvider>();
    if (settings.defaultTaxPercent <= 0) return 0;
    return baseAmount * settings.defaultTaxPercent / 100.0;
  }

  double get adjustmentsTotal => adjustments.fold(0, (s, a) => s + a.amount);
  double get totalAmount => baseAmount + adjustmentsTotal;

  Future<void> _pickImage(bool previous, {required bool camera}) async {
    final path = await ImageService.pickAndStore(isCamera: camera);
    if (path != null) {
      setState(() {
        if (previous) {
          prevImagePath = path;
        } else {
          currImagePath = path;
        }
      });
    }
  }

  Future<void> _chooseImage(bool previous) async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(previous, camera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(previous, camera: false);
              },
            ),
            if (previous && prevImagePath != null)
              ListTile(
                leading: const Icon(Icons.restart_alt),
                title: const Text('Clear / Reset'),
                onTap: () {
                  setState(() => prevImagePath = null);
                  Navigator.pop(ctx);
                },
              ),
            if (!previous && currImagePath != null)
              ListTile(
                leading: const Icon(Icons.restart_alt),
                title: const Text('Clear / Reset'),
                onTap: () {
                  setState(() => currImagePath = null);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addAdjustmentDialog() async {
    final labelCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final form = GlobalKey<FormState>();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Adjustment'),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: labelCtrl,
                decoration: const InputDecoration(labelText: 'Label'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: amountCtrl,
                decoration: const InputDecoration(labelText: 'Amount (+/-)'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (double.tryParse(v.trim()) == null) return 'Invalid';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                setState(() {
                  adjustments.add(
                    Adjustment(
                      label: labelCtrl.text.trim(),
                      amount: double.parse(amountCtrl.text.trim()),
                    ),
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (consumed > 1000000) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Consumed kWh too large.')));
      return;
    }
    setState(() => saving = true);
    final settings = context.read<SettingsProvider>();
    final reading = MeterReading(
      consumerId: widget.consumer.id!,
      previousReading: double.parse(_prevCtrl.text.trim()),
      currentReading: double.parse(_currCtrl.text.trim()),
      previousImagePath: prevImagePath,
      currentImagePath: currImagePath,
    );
    final readingId = await DatabaseService.instance.insertMeterReading(
      reading,
    );
    final readingPersisted = reading.copyWith(id: readingId);

    // Auto-add default tax if configured and not already present
    final adjList = List<Adjustment>.from(adjustments);
    if (settings.defaultTaxPercent > 0 &&
        !adjList.any((a) => a.label.startsWith('Default Tax'))) {
      final taxAmt = baseAmount * settings.defaultTaxPercent / 100.0;
      adjList.add(
        Adjustment(
          label:
              'Default Tax (${settings.defaultTaxPercent.toStringAsFixed(2)}%)',
          amount: taxAmt,
        ),
      );
    }

    final bill = await DatabaseService.instance.createBill(
      consumer: widget.consumer,
      reading: readingPersisted,
      adjustments: adjList,
    );
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BillDetailScreen(billId: bill.id!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Bill')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consumer: ${widget.consumer.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _prevCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Previous Reading (kWh)',
                              prefixIcon: Icon(Icons.history),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) =>
                                v == null || double.tryParse(v.trim()) == null
                                ? 'Required'
                                : null,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _currCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Current Reading (kWh)',
                              prefixIcon: Icon(Icons.speed),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) {
                              if (v == null ||
                                  double.tryParse(v.trim()) == null)
                                return 'Required';
                              final curr = double.parse(v.trim());
                              final prev =
                                  double.tryParse(_prevCtrl.text.trim()) ?? 0;
                              if (curr < prev) return 'Must be >= previous';
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meter Images',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _ImageBox(path: prevImagePath, label: 'Prev'),
                              TextButton.icon(
                                onPressed: () => _chooseImage(true),
                                icon: const Icon(Icons.add_a_photo_outlined),
                                label: const Text('Prev (Cam/Gallery)'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: [
                              _ImageBox(path: currImagePath, label: 'Curr'),
                              TextButton.icon(
                                onPressed: () => _chooseImage(false),
                                icon: const Icon(Icons.add_a_photo_outlined),
                                label: const Text('Curr (Cam/Gallery)'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Adjustments',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          onPressed: _addAdjustmentDialog,
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: 'Add Adjustment',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (adjustments.isEmpty) const Text('None'),
                    if (adjustments.isNotEmpty)
                      ...adjustments.asMap().entries.map(
                        (e) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(e.value.label),
                          subtitle: Text(e.value.amount.toStringAsFixed(2)),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () =>
                                setState(() => adjustments.removeAt(e.key)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _TotalsPreview(
              consumed: consumed,
              baseAmount: baseAmount,
              adjustmentsTotal: adjustmentsTotal + defaultTaxAmount,
              totalAmount: totalAmount + defaultTaxAmount,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: saving ? null : _save,
              icon: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(saving ? 'Saving...' : 'Save Bill'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageBox extends StatelessWidget {
  final String? path;
  final String label;
  const _ImageBox({required this.path, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(.4),
        ),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      child: path == null
          ? Center(
              child: Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(path!),
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
    );
  }
}

class _TotalsPreview extends StatelessWidget {
  final double consumed;
  final double baseAmount;
  final double adjustmentsTotal;
  final double totalAmount;
  const _TotalsPreview({
    required this.consumed,
    required this.baseAmount,
    required this.adjustmentsTotal,
    required this.totalAmount,
  });
  @override
  Widget build(BuildContext context) {
    final items = [
      _KV('Consumed', '${consumed.toStringAsFixed(2)} kWh'),
      _KV('Base', baseAmount.toStringAsFixed(2)),
      _KV('Adjust.', adjustmentsTotal.toStringAsFixed(2)),
      _KV('Total', totalAmount.toStringAsFixed(2), highlight: true),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(spacing: 24, runSpacing: 12, children: items),
      ),
    );
  }
}

class _KV extends StatelessWidget {
  final String k;
  final String v;
  final bool highlight;
  const _KV(this.k, this.v, {this.highlight = false});
  @override
  Widget build(BuildContext context) {
    final style = highlight
        ? Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium;
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            k,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(v, style: style),
        ],
      ),
    );
  }
}
