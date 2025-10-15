import 'package:flutter/material.dart';
import '../widgets/morph_transition.dart';
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
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Consumer'),
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
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Hero(
                      tag: 'add-consumer-card',
                      flightShuttleBuilder:
                          MorphTransition.flightShuttleBuilder,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(24),
                        shadowColor: scheme.primary.withValues(alpha: 0.1),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                scheme.surface,
                                scheme.surfaceContainerHighest.withValues(
                                  alpha: 0.3,
                                ),
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            scheme.primaryContainer,
                                            scheme.secondaryContainer,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.person_add_alt_1_rounded,
                                        color: scheme.onPrimaryContainer,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      'Consumer Details',
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: scheme.onSurface,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                TextFormField(
                                  controller: _nameCtrl,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Consumer Name',
                                    hintText: 'Enter full name',
                                    prefixIcon: Icon(
                                      Icons.person_outline_rounded,
                                    ),
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'Consumer name is required'
                                      : null,
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _costCtrl,
                                  textInputAction: TextInputAction.done,
                                  decoration: const InputDecoration(
                                    labelText: 'Cost per Unit',
                                    hintText: 'e.g. 25.50 PKR/kWh',
                                    prefixIcon: Icon(
                                      Icons.electric_bolt_rounded,
                                    ),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Cost per unit is required';
                                    }
                                    final d = double.tryParse(v.trim());
                                    if (d == null) {
                                      return 'Please enter a valid number';
                                    }
                                    if (d <= 0) {
                                      return 'Cost must be greater than 0';
                                    }
                                    return null;
                                  },
                                  onFieldSubmitted: (_) => _save(),
                                ),
                                const SizedBox(height: 12),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  height: _saving ? 3 : 0,
                                  child: _saving
                                      ? LinearProgressIndicator(
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                                const SizedBox(height: 28),
                                FilledButton.icon(
                                  onPressed: _saving ? null : _save,
                                  icon: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: _saving
                                        ? SizedBox(
                                            key: const ValueKey('loading'),
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: scheme.onPrimary,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.save_rounded,
                                            key: ValueKey('save'),
                                          ),
                                  ),
                                  label: Text(
                                    _saving ? 'Saving...' : 'Save Consumer',
                                  ),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            color: scheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Cost per unit should reflect your billing rate (e.g., PKR per kWh for electricity).',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.4,
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
        ),
      ),
    );
  }
}
