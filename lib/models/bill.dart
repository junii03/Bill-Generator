import 'adjustment.dart';

class Bill {
  final int? id;
  final int consumerId;
  final int meterReadingId;
  final double baseAmount;
  final double adjustmentsTotal;
  final double totalAmount;
  final List<Adjustment> adjustments;
  final DateTime createdAt;

  Bill({
    this.id,
    required this.consumerId,
    required this.meterReadingId,
    required this.baseAmount,
    required this.adjustmentsTotal,
    required this.totalAmount,
    required this.adjustments,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'consumer_id': consumerId,
    'meter_reading_id': meterReadingId,
    'base_amount': baseAmount,
    'adjustments_total': adjustmentsTotal,
    'total_amount': totalAmount,
    'adjustments_json': Adjustment.encodeList(adjustments),
    'created_at': createdAt.toIso8601String(),
  };

  static Bill fromMap(Map<String, dynamic> map) => Bill(
    id: map['id'] as int?,
    consumerId: map['consumer_id'] as int,
    meterReadingId: map['meter_reading_id'] as int,
    baseAmount: (map['base_amount'] as num).toDouble(),
    adjustmentsTotal: (map['adjustments_total'] as num).toDouble(),
    totalAmount: (map['total_amount'] as num).toDouble(),
    adjustments: Adjustment.decodeList(map['adjustments_json'] as String),
    createdAt: DateTime.parse(map['created_at'] as String),
  );
}
