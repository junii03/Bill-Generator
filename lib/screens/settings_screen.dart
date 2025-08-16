import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../services/backup_service.dart';

class SettingsScreen extends StatefulWidget {
  static const route = '/settings';
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _currencyCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  bool _busy = false;
  bool _dirty = false; // track unsaved changes

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsProvider>();
    _currencyCtrl.text = s.currencySymbol;
    _taxCtrl.text = s.defaultTaxPercent.toString();
  }

  Future<void> _save() async {
    final s = context.read<SettingsProvider>();
    await s.setCurrencySymbol(
      _currencyCtrl.text.trim().isEmpty
          ? s.currencySymbol
          : _currencyCtrl.text.trim(),
    );
    final tax = double.tryParse(_taxCtrl.text.trim()) ?? s.defaultTaxPercent;
    await s.setDefaultTaxPercent(tax < 0 ? 0 : tax);
    setState(() => _dirty = false);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _backup() async {
    setState(() => _busy = true);
    try {
      final file = await BackupService.createBackupArchive();
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Backup created: ${file.path}')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      final restored = await BackupService.restoreFromArchive();
      if (!restored) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Restore cancelled')));
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Restore complete. Restart app.')),
          );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _busy,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
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
                            'General',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _currencyCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Currency Symbol (e.g. PKR, EUR, USD)',
                              prefixIcon: Icon(Icons.currency_exchange),
                            ),
                            onChanged: (_) => setState(() => _dirty = true),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _taxCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Default Tax Percent (auto added)',
                              prefixIcon: Icon(Icons.percent),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() => _dirty = true),
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Dark Mode'),
                            value: settings.darkMode,
                            onChanged: (v) {
                              settings.toggleDarkMode(v);
                              setState(() => _dirty = true);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Backup & Restore',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              if (_busy)
                                const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              FilledButton.icon(
                                onPressed: _busy ? null : _backup,
                                icon: const Icon(Icons.download_outlined),
                                label: const Text('Create Backup'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _busy ? null : _restore,
                                icon: const Icon(Icons.upload_outlined),
                                label: const Text('Restore Backup'),
                              ),
                            ],
                          ),
                          if (_busy) ...[
                            const SizedBox(height: 16),
                            const LinearProgressIndicator(minHeight: 3),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            'Backup creates a .zip archive of your data. Restore will overwrite existing data.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 80), // spacer for bottom bar
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 250),
          offset: _dirty ? Offset.zero : const Offset(0, 1),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: _dirty ? 1 : 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    color: Colors.black.withOpacity(.1),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Unsaved changes',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _busy ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save'),
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
