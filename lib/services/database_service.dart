import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/consumer.dart';
import '../models/meter_reading.dart';
import '../models/adjustment.dart';
import '../models/bill.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();
  Database? _db;

  Future<Database> get db async => _db ??= await _init();

  Future<Database> _init() async {
    final path = p.join(await getDatabasesPath(), 'billing.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''CREATE TABLE consumers(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          cost_per_unit REAL NOT NULL
        );''');
        await database.execute('''CREATE TABLE meter_readings(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          consumer_id INTEGER NOT NULL,
          previous_reading REAL NOT NULL,
          current_reading REAL NOT NULL,
            previous_image_path TEXT,
            current_image_path TEXT,
            reading_date TEXT NOT NULL,
            FOREIGN KEY(consumer_id) REFERENCES consumers(id) ON DELETE CASCADE
        );''');
        await database.execute('''CREATE TABLE bills(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          consumer_id INTEGER NOT NULL,
          meter_reading_id INTEGER NOT NULL,
          base_amount REAL NOT NULL,
          adjustments_total REAL NOT NULL,
          total_amount REAL NOT NULL,
          adjustments_json TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY(consumer_id) REFERENCES consumers(id) ON DELETE CASCADE,
          FOREIGN KEY(meter_reading_id) REFERENCES meter_readings(id) ON DELETE CASCADE
        );''');
      },
    );
  }

  // Consumers
  Future<int> insertConsumer(Consumer c) async =>
      (await db).insert('consumers', c.toMap());
  Future<List<Consumer>> getConsumers() async {
    final rows = await (await db).query(
      'consumers',
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(Consumer.fromMap).toList();
  }

  Future<Consumer?> getConsumer(int id) async {
    final rows = await (await db).query(
      'consumers',
      where: 'id=?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Consumer.fromMap(rows.first);
  }

  // Meter readings
  Future<int> insertMeterReading(MeterReading r) async =>
      (await db).insert('meter_readings', r.toMap());
  Future<MeterReading?> getMeterReading(int id) async {
    final rows = await (await db).query(
      'meter_readings',
      where: 'id=?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return MeterReading.fromMap(rows.first);
  }

  Future<MeterReading?> getLastMeterReadingForConsumer(int consumerId) async {
    final rows = await (await db).query(
      'meter_readings',
      where: 'consumer_id=?',
      whereArgs: [consumerId],
      orderBy: 'reading_date DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return MeterReading.fromMap(rows.first);
  }

  // delete consumer and its meter readings
  Future<void> deleteConsumer(int id) async {
    await (await db).delete('consumers', where: 'id=?', whereArgs: [id]);
    await (await db).delete(
      'meter_readings',
      where: 'consumer_id=?',
      whereArgs: [id],
    );
  }

  // Bills
  Future<int> insertBill(Bill b) async => (await db).insert('bills', b.toMap());
  Future<List<Bill>> getBillsForConsumer(int consumerId) async {
    final rows = await (await db).query(
      'bills',
      where: 'consumer_id=?',
      whereArgs: [consumerId],
      orderBy: 'created_at DESC',
    );
    return rows.map(Bill.fromMap).toList();
  }

  Future<Bill?> getBill(int id) async {
    final rows = await (await db).query(
      'bills',
      where: 'id=?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Bill.fromMap(rows.first);
  }

  Future<Bill> createBill({
    required Consumer consumer,
    required MeterReading reading,
    required List<Adjustment> adjustments,
  }) async {
    final base = reading.kwhConsumed * consumer.costPerUnit;
    final adjustmentsTotal = adjustments.fold<double>(
      0,
      (sum, a) => sum + a.amount,
    );
    final total = base + adjustmentsTotal;
    final bill = Bill(
      consumerId: consumer.id!,
      meterReadingId: reading.id!,
      baseAmount: base,
      adjustmentsTotal: adjustmentsTotal,
      totalAmount: total,
      adjustments: adjustments,
    );
    final id = await insertBill(bill);
    return bill.copyWith(id: id);
  }
}

extension on Bill {
  Bill copyWith({int? id}) => Bill(
    id: id ?? this.id,
    consumerId: consumerId,
    meterReadingId: meterReadingId,
    baseAmount: baseAmount,
    adjustmentsTotal: adjustmentsTotal,
    totalAmount: totalAmount,
    adjustments: adjustments,
    createdAt: createdAt,
  );
}
