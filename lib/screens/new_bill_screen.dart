import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' hide Consumer;
import '../models/consumer.dart';
import '../models/meter_reading.dart';
import '../models/adjustment.dart';
import '../services/database_service.dart';
import '../services/image_service.dart';
import '../services/settings_service.dart';
import 'bill_detail_screen.dart';
import '../widgets/morph_transition.dart';

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
  final _costCtrl = TextEditingController();
  List<Adjustment> adjustments = [];
  String? prevImagePath;
  String? currImagePath;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _costCtrl.text = widget.consumer.costPerUnit.toStringAsFixed(2);
    _loadLastReading();
  }

  @override
  void dispose() {
    _costCtrl.dispose();
    _prevCtrl.dispose();
    _currCtrl.dispose();
    super.dispose();
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

  double get effectiveCostPerUnit =>
      double.tryParse(_costCtrl.text.trim()) ?? widget.consumer.costPerUnit;
  double get baseAmount => consumed * effectiveCostPerUnit;
  double get defaultTaxAmount {
    final settings = context.read<SettingsProvider>();
    if (settings.defaultTaxPercent <= 0) return 0;
    return baseAmount * settings.defaultTaxPercent / 100.0;
  }

  double get adjustmentsTotal => adjustments.fold(0, (s, a) => s + a.amount);
  double get totalAmount => baseAmount + adjustmentsTotal;

  Future<void> _pickImage(bool previous, {required bool camera}) async {
    // Pick a distinct image for previous or current reading.
    final path = await ImageService.pickAndStore(isCamera: camera);
    if (path != null) {
      setState(() {
        if (previous) {
          // Remove previously selected previous image if replacing
          if (prevImagePath != null && prevImagePath != path) {
            try {
              File(prevImagePath!).deleteSync();
            } catch (_) {}
          }
          prevImagePath = path;
        } else {
          if (currImagePath != null && currImagePath != path) {
            try {
              File(currImagePath!).deleteSync();
            } catch (_) {}
          }
          currImagePath = path;
        }
      });
    }
  }

  Future<void> _chooseImage(bool previous) async {
    if (!mounted) return;
    final scheme = Theme.of(context).colorScheme;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.add_a_photo_rounded,
                        color: scheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Add ${previous ? 'Previous' : 'Current'} Reading Photo',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.photo_camera_rounded,
                    color: scheme.secondary,
                    size: 20,
                  ),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Capture with camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(previous, camera: true);
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.photo_library_rounded,
                    color: scheme.tertiary,
                    size: 20,
                  ),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select existing photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(previous, camera: false);
                },
              ),
              if ((previous && prevImagePath != null) ||
                  (!previous && currImagePath != null))
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: scheme.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: scheme.error,
                      size: 20,
                    ),
                  ),
                  title: const Text('Remove Photo'),
                  subtitle: const Text('Clear current selection'),
                  onTap: () {
                    setState(() {
                      if (previous) {
                        prevImagePath = null;
                      } else {
                        currImagePath = null;
                      }
                    });
                    Navigator.pop(ctx);
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
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
      builder: (_) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: scheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const Text('Add Adjustment'),
            ],
          ),
          content: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Adjustment Label',
                    hintText: 'e.g., Discount, Late Fee',
                    prefixIcon: Icon(Icons.label_outline_rounded),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Label is required'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    hintText: 'Positive or negative',
                    prefixIcon: Icon(Icons.attach_money_rounded),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Amount is required';
                    }
                    if (double.tryParse(v.trim()) == null) {
                      return 'Invalid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Use positive values for charges, negative for discounts',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
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
              child: const Text('Add Adjustment'),
            ),
          ],
        );
      },
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

    // Update consumer cost per unit if it changed
    final newCost = effectiveCostPerUnit;
    Consumer consumerForBill = widget.consumer;
    if ((newCost - widget.consumer.costPerUnit).abs() > 0.0001) {
      await DatabaseService.instance.updateConsumerCost(
        widget.consumer.id!,
        newCost,
      );
      consumerForBill = widget.consumer.copyWith(costPerUnit: newCost);
    }

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
      consumer: consumerForBill,
      reading: readingPersisted,
      adjustments: adjList,
    );
    if (mounted) {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (_) => BillDetailScreen(billId: bill.id!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Bill'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.surface,
              scheme.surfaceContainerHighest.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Consumer Info Header
              Hero(
                tag: 'consumer-${widget.consumer.id}',
                flightShuttleBuilder: MorphTransition.flightShuttleBuilder,
                child: Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(20),
                  shadowColor: scheme.primary.withValues(alpha: 0.1),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.primaryContainer.withValues(alpha: 0.3),
                          scheme.secondaryContainer.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                scheme.primaryContainer,
                                scheme.secondaryContainer,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              widget.consumer.name.isNotEmpty
                                  ? widget.consumer.name
                                        .substring(0, 1)
                                        .toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: scheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.consumer.name,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${widget.consumer.costPerUnit.toStringAsFixed(2)} per kWh',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: scheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Meter Readings Card
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(20),
                shadowColor: Colors.black.withValues(alpha: 0.05),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: scheme.surface,
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.speed_rounded,
                            color: scheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Meter Readings',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _prevCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Previous Reading',
                                hintText: 'kWh',
                                prefixIcon: Icon(Icons.history_rounded),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (v) =>
                                  v == null || double.tryParse(v.trim()) == null
                                  ? 'Required'
                                  : null,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _currCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Current Reading',
                                hintText: 'kWh',
                                prefixIcon: Icon(Icons.speed_rounded),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (v) {
                                if (v == null ||
                                    double.tryParse(v.trim()) == null) {
                                  return 'Required';
                                }
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
                      if (consumed > 0) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: scheme.tertiaryContainer.withValues(
                              alpha: 0.3,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.electric_bolt_rounded,
                                color: scheme.tertiary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Consumption: ${consumed.toStringAsFixed(2)} kWh',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: scheme.onTertiaryContainer,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Cost Override Card
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(20),
                shadowColor: Colors.black.withValues(alpha: 0.05),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: scheme.surface,
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            color: scheme.secondary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Cost Override (Optional)',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _costCtrl,
                        decoration: InputDecoration(
                          labelText: 'Custom Cost per Unit',
                          hintText:
                              'Default: ${widget.consumer.costPerUnit.toStringAsFixed(2)}',
                          prefixIcon: const Icon(
                            Icons.currency_exchange_rounded,
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) {
                          if (v != null && v.trim().isNotEmpty) {
                            final d = double.tryParse(v.trim());
                            if (d == null) return 'Invalid number';
                            if (d <= 0) return 'Must be > 0';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Meter Images Card
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(20),
                shadowColor: Colors.black.withValues(alpha: 0.05),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: scheme.surface,
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.camera_alt_rounded,
                            color: scheme.tertiary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Meter Images',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _ModernImageBox(
                                  path: prevImagePath,
                                  label: 'Previous Reading',
                                  icon: Icons.history_rounded,
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () => _chooseImage(true),
                                  icon: const Icon(Icons.add_a_photo_rounded),
                                  label: const Text('Add Photo'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: [
                                _ModernImageBox(
                                  path: currImagePath,
                                  label: 'Current Reading',
                                  icon: Icons.speed_rounded,
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () => _chooseImage(false),
                                  icon: const Icon(Icons.add_a_photo_rounded),
                                  label: const Text('Add Photo'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
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
              const SizedBox(height: 20),

              // Adjustments Card
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(20),
                shadowColor: Colors.black.withValues(alpha: 0.05),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: scheme.surface,
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                color: scheme.secondary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Adjustments',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onSurface,
                                    ),
                              ),
                            ],
                          ),
                          IconButton.filledTonal(
                            onPressed: _addAdjustmentDialog,
                            icon: const Icon(Icons.add_rounded),
                            tooltip: 'Add Adjustment',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (adjustments.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withValues(
                              alpha: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'No adjustments added yet',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (adjustments.isNotEmpty)
                        ...adjustments.asMap().entries.map(
                          (e) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest.withValues(
                                alpha: 0.3,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: scheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.value.label,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${e.value.amount >= 0 ? '+' : ''}${e.value.amount.toStringAsFixed(2)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: e.value.amount >= 0
                                                  ? scheme.primary
                                                  : scheme.error,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    color: scheme.error,
                                  ),
                                  onPressed: () => setState(
                                    () => adjustments.removeAt(e.key),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Totals Preview (Animated when values change)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 360),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: CurvedAnimation(
                    parent: anim,
                    curve: Curves.easeOutBack,
                  ),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: KeyedSubtree(
                  key: ValueKey<double>(totalAmount + defaultTaxAmount),
                  child: _ModernTotalsPreview(
                    consumed: consumed,
                    baseAmount: baseAmount,
                    adjustmentsTotal: adjustmentsTotal + defaultTaxAmount,
                    totalAmount: totalAmount + defaultTaxAmount,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              FilledButton.icon(
                onPressed: saving ? null : _save,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: saving
                      ? SizedBox(
                          key: const ValueKey('loading'),
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.save_rounded, key: ValueKey('save')),
                ),
                label: Text(saving ? 'Creating Bill...' : 'Create Bill'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernImageBox extends StatelessWidget {
  final String? path;
  final String label;
  final IconData icon;
  const _ModernImageBox({
    required this.path,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      child: path == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: scheme.primary, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(path!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ModernTotalsPreview extends StatelessWidget {
  final double consumed;
  final double baseAmount;
  final double adjustmentsTotal;
  final double totalAmount;
  const _ModernTotalsPreview({
    required this.consumed,
    required this.baseAmount,
    required this.adjustmentsTotal,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = [
      _ModernKV(
        'Consumption',
        '${consumed.toStringAsFixed(2)} kWh',
        Icons.electric_bolt_rounded,
      ),
      _ModernKV(
        'Base Amount',
        baseAmount.toStringAsFixed(2),
        Icons.attach_money_rounded,
      ),
      _ModernKV(
        'Adjustments',
        adjustmentsTotal.toStringAsFixed(2),
        Icons.tune_rounded,
      ),
    ];

    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(20),
      shadowColor: scheme.primary.withValues(alpha: 0.1),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primaryContainer.withValues(alpha: 0.2),
              scheme.tertiaryContainer.withValues(alpha: 0.2),
            ],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  color: scheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Bill Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: item,
              ),
            ),
            const Divider(height: 24),
            _ModernKV(
              'Total Amount',
              totalAmount.toStringAsFixed(2),
              Icons.account_balance_wallet_rounded,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernKV extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isTotal;

  const _ModernKV(this.label, this.value, this.icon, {this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isTotal
                ? scheme.primary.withValues(alpha: 0.2)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isTotal ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isTotal ? scheme.onSurface : scheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: isTotal ? scheme.primary : scheme.onSurface,
            fontSize: isTotal ? 18 : 16,
          ),
        ),
      ],
    );
  }
}
