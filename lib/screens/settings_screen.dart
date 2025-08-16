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
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _currencyCtrl,
              decoration: const InputDecoration(
                labelText: 'Currency Symbol (e.g. PKR, EUR, USD)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _taxCtrl,
              decoration: const InputDecoration(
                labelText: 'Default Tax Percent (auto added)',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: settings.darkMode,
              onChanged: (v) => settings.toggleDarkMode(v),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save Settings'),
            ),
            const Divider(height: 40),
            Text(
              'Backup & Restore',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _backup,
              icon: const Icon(Icons.download),
              label: const Text('Create Backup (.zip)'),
            ),
            ElevatedButton.icon(
              onPressed: _restore,
              icon: const Icon(Icons.upload),
              label: const Text('Restore from Backup (.zip)'),
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
