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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          offset: _dirty ? Offset.zero : const Offset(0, 1),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _dirty ? 1 : 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [scheme.surface.withOpacity(0.9), scheme.surface],
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 20,
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.pending_actions_rounded,
                      color: scheme.secondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unsaved Changes',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Tap save to apply your settings',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: _busy ? null : _save,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _busy
                          ? SizedBox(
                              key: const ValueKey('loading'),
                              width: 16,
                              height: 16,
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
                    label: Text(_busy ? 'Saving...' : 'Save'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.surface,
              scheme.surfaceContainerHighest.withOpacity(0.1),
            ],
          ),
        ),

        child: SafeArea(
          child: AbsorbPointer(
            absorbing: _busy,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // General Settings Card
                    Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(24),
                      shadowColor: scheme.primary.withOpacity(0.1),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              scheme.surface,
                              scheme.surfaceContainerHighest.withOpacity(0.3),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                    Icons.settings_rounded,
                                    color: scheme.onPrimaryContainer,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'General Settings',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: scheme.onSurface,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _currencyCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Currency Symbol',
                                hintText: 'e.g. PKR, EUR, USD',
                                prefixIcon: Icon(
                                  Icons.currency_exchange_rounded,
                                ),
                              ),
                              onChanged: (_) => setState(() => _dirty = true),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _taxCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Default Tax Percent',
                                hintText: 'Auto-added to bills',
                                prefixIcon: Icon(Icons.percent_rounded),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (_) => setState(() => _dirty = true),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest
                                    .withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: scheme.outline.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: settings.darkMode
                                          ? scheme.primary.withOpacity(0.2)
                                          : scheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      settings.darkMode
                                          ? Icons.dark_mode_rounded
                                          : Icons.light_mode_rounded,
                                      color: settings.darkMode
                                          ? scheme.primary
                                          : scheme.onSurfaceVariant,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Dark Mode',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Switch between light and dark themes',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: scheme.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: settings.darkMode,
                                    onChanged: (v) {
                                      settings.toggleDarkMode(v);
                                      setState(() => _dirty = true);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Backup & Restore Card
                    Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(20),
                      shadowColor: Colors.black.withOpacity(0.05),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: scheme.surface,
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: scheme.tertiaryContainer.withOpacity(
                                      0.3,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.backup_rounded,
                                    color: scheme.tertiary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Backup & Restore',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: scheme.onSurface,
                                        ),
                                  ),
                                ),
                                if (_busy)
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: scheme.primary,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: _busy ? null : _backup,
                                    icon: const Icon(Icons.download_rounded),
                                    label: const Text('Create Backup'),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _busy ? null : _restore,
                                    icon: const Icon(Icons.upload_rounded),
                                    label: const Text('Restore'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_busy) ...[
                              const SizedBox(height: 16),
                              LinearProgressIndicator(
                                borderRadius: BorderRadius.circular(2),
                                minHeight: 3,
                              ),
                            ],
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: scheme.primary.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: scheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Backup creates a .zip archive of your data. Restore will overwrite existing data.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
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
                    const SizedBox(height: 100), // spacer for bottom bar
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
