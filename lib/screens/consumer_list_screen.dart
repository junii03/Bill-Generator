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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consumers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () =>
                Navigator.pushNamed(context, SettingsScreen.route).then((_) {
                  _load();
                }),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search consumers',
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('No consumers'))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (c, i) {
                            final consumer = filtered[i];
                            return ListTile(
                              title: Text(consumer.name),
                              subtitle: Text(
                                'Cost/Unit: ${consumer.costPerUnit}',
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v == 'new_bill') {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            NewBillScreen(consumer: consumer),
                                      ),
                                    );
                                  }
                                  if (v == 'bills') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BillsForConsumerScreen(
                                          consumer: consumer,
                                        ),
                                      ),
                                    );
                                  }
                                  _load();
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'new_bill',
                                    child: Text('New Bill'),
                                  ),
                                  PopupMenuItem(
                                    value: 'bills',
                                    child: Text('View Bills'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addConsumer,
        child: const Icon(Icons.add),
      ),
    );
  }
}
