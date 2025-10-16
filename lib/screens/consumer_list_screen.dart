import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../widgets/morph_transition.dart';
import '../models/consumer.dart';
import '../services/database_service.dart';
import 'add_consumer_screen.dart';
import 'package:bill_generator/widgets/glass_card.dart';
import 'new_bill_screen.dart';
import 'bills_for_consumer_screen.dart';
import 'settings_screen.dart';

class ConsumerListScreen extends StatefulWidget {
  const ConsumerListScreen({super.key});

  @override
  State<ConsumerListScreen> createState() => _ConsumerListScreenState();
}

class _ConsumerListScreenState extends State<ConsumerListScreen> {
  List<Consumer> consumers = [];
  bool loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await DatabaseService.instance.getConsumers();
    if (!mounted) return;
    setState(() {
      consumers = data;
      loading = false;
    });
  }

  void _addConsumer() async {
    await Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const AddConsumerScreen()),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = consumers
        .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    final body = AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
          ? _EmptyState(onAdd: _addConsumer)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                key: ValueKey(filtered.length),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                itemCount: filtered.length,
                itemBuilder: (c, i) {
                  final consumer = filtered[i];
                  return _ConsumerCard(
                    consumer: consumer,
                    onAction: (v) async {
                      if (v == 'new_bill') {
                        await Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) => NewBillScreen(consumer: consumer),
                          ),
                        );
                      } else if (v == 'bills') {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) =>
                                BillsForConsumerScreen(consumer: consumer),
                          ),
                        );
                      } else if (v == 'remove') {
                        await _removeConsumer(consumer);
                        _load();
                      }
                      _load();
                    },
                  );
                },
              ),
            ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(
              context,
              SettingsScreen.route,
            ).then((_) => _load()),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onTapOutside: (event) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search consumers...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                ),
                onChanged: (v) => setState(() => _query = v),
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
              Theme.of(context).colorScheme.surface,
              Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: body,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addConsumer,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Consumer'),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
      ),
    );
  }

  // remove consumer
  Future<void> _removeConsumer(Consumer consumer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            const Text('Remove Consumer'),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${consumer.name}"? This action cannot be undone and will also remove all associated bills.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseService.instance.deleteConsumer(consumer.id!);
      _load();
    }
  }
}

class _ConsumerCard extends StatelessWidget {
  final Consumer consumer;
  final ValueChanged<String> onAction;
  const _ConsumerCard({required this.consumer, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => onAction('bills'),
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Hero(
                    tag: 'consumer-${consumer.id}',
                    flightShuttleBuilder: MorphTransition.flightShuttleBuilder,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            scheme.primaryContainer,
                            scheme.secondaryContainer,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          consumer.name.isNotEmpty
                              ? consumer.name.substring(0, 1).toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          consumer.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        // ...add more info here if needed...
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    color: scheme.surfaceContainer.withValues(alpha: 0.55),
                    onSelected: onAction,
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'new_bill',
                        child: Row(
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: 20,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 12),
                            const Text('New Bill'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'bills',
                        child: Row(
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 20,
                              color: scheme.secondary,
                            ),
                            const SizedBox(width: 12),
                            const Text('View Bills'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: scheme.error,
                            ),
                            const SizedBox(width: 12),
                            const Text('Remove'),
                          ],
                        ),
                      ),
                    ],
                    tooltip: 'More actions',
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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

  // Removed invalid trailing PopupMenuItem and related code after _ConsumerCard
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primaryContainer.withValues(alpha: 0.3),
                    scheme.secondaryContainer.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.groups_2_rounded,
                size: 64,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to Bill Generator!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add your first consumer to start generating professional electricity bills.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add Your First Consumer'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, SettingsScreen.route),
              icon: const Icon(Icons.settings_rounded),
              label: const Text('Configure Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
