import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/consumer.dart';

class AddConsumerScreen extends StatefulWidget {
  const AddConsumerScreen({super.key});

  @override
  State<AddConsumerScreen> createState() => _AddConsumerScreenState();
}

class _AddConsumerScreenState extends State<AddConsumerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final consumer = Consumer(
      name: _nameCtrl.text.trim(),
      costPerUnit: double.parse(_costCtrl.text.trim()),
    );
    await DatabaseService.instance.insertConsumer(consumer);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Add Consumer')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Consumer Details',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Consumer Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _costCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Cost per Unit (e.g. PKR/kWh)',
                              prefixIcon: Icon(Icons.flash_on_outlined),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Required';
                              final d = double.tryParse(v.trim());
                              if (d == null) return 'Invalid number';
                              if (d <= 0) return 'Must be > 0';
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          AnimatedOpacity(
                            opacity: _saving ? 1 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: _saving
                                ? const LinearProgressIndicator(minHeight: 2)
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _saving
                                  ? const SizedBox(
                                      key: ValueKey('prog'),
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.save_outlined,
                                      key: ValueKey('icon'),
                                    ),
                            ),
                            label: const Text('Save Consumer'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Tip: Cost per unit should reflect your billing rate (e.g., PKR per kWh).',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
