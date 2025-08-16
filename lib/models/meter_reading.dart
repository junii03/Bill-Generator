class MeterReading {
  final int? id;
  final int consumerId;
  final double previousReading; // kWh previous
  final double currentReading; // kWh current
  final String? previousImagePath;
  final String? currentImagePath;
  final DateTime readingDate;

  MeterReading({
    this.id,
    required this.consumerId,
    required this.previousReading,
    required this.currentReading,
    this.previousImagePath,
    this.currentImagePath,
    DateTime? readingDate,
  }) : readingDate = readingDate ?? DateTime.now();

  double get kwhConsumed =>
      (currentReading - previousReading).clamp(0, double.infinity);

  Map<String, dynamic> toMap() => {
    'id': id,
    'consumer_id': consumerId,
    'previous_reading': previousReading,
    'current_reading': currentReading,
    'previous_image_path': previousImagePath,
    'current_image_path': currentImagePath,
    'reading_date': readingDate.toIso8601String(),
  };

  static MeterReading fromMap(Map<String, dynamic> map) => MeterReading(
    id: map['id'] as int?,
    consumerId: map['consumer_id'] as int,
    previousReading: (map['previous_reading'] as num).toDouble(),
    currentReading: (map['current_reading'] as num).toDouble(),
    previousImagePath: map['previous_image_path'] as String?,
    currentImagePath: map['current_image_path'] as String?,
    readingDate: DateTime.parse(map['reading_date'] as String),
  );

  MeterReading copyWith({
    int? id,
    double? previousReading,
    double? currentReading,
    String? previousImagePath,
    String? currentImagePath,
    DateTime? readingDate,
  }) => MeterReading(
    id: id ?? this.id,
    consumerId: consumerId,
    previousReading: previousReading ?? this.previousReading,
    currentReading: currentReading ?? this.currentReading,
    previousImagePath: previousImagePath ?? this.previousImagePath,
    currentImagePath: currentImagePath ?? this.currentImagePath,
    readingDate: readingDate ?? this.readingDate,
  );
}
