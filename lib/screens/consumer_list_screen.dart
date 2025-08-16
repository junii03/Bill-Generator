import 'package:flutter/material.dart';
import '../models/consumer.dart';
import '../services/database_service.dart';
import 'add_consumer_screen.dart';
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
      MaterialPageRoute(builder: (_) => const AddConsumerScreen()),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = consumers
        .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    final body = loading
        ? const Center(child: CircularProgressIndicator())
        : filtered.isEmpty
        ? _EmptyState(onAdd: _addConsumer)
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
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
                        MaterialPageRoute(
                          builder: (_) => NewBillScreen(consumer: consumer),
                        ),
                      );
                    } else if (v == 'bills') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BillsForConsumerScreen(consumer: consumer),
                        ),
                      );
                    }
                    _load();
                  },
                );
              },
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consumers'),
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
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                onTapOutside: (event) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search consumers',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: body,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addConsumer,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add'),
      ),
    );
  }
}

class _ConsumerCard extends StatelessWidget {
  final Consumer consumer;
  final ValueChanged<String> onAction;
  const _ConsumerCard({required this.consumer, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onAction('bills'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  consumer.name.isNotEmpty
                      ? consumer.name.substring(0, 1).toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      consumer.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cost/Unit: ${consumer.costPerUnit}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: onAction,
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'new_bill', child: Text('New Bill')),
                  PopupMenuItem(value: 'bills', child: Text('View Bills')),
                ],
                tooltip: 'Actions',
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
            Icon(Icons.groups_2_outlined, size: 72, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              'No consumers yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first consumer to start generating bills.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add Consumer'),
            ),
          ],
        ),
      ),
    );
  }
}
