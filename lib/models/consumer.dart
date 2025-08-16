class Consumer {
  final int? id;
  final String name;
  final double costPerUnit; // cost per kWh

  Consumer({this.id, required this.name, required this.costPerUnit});

  Consumer copyWith({int? id, String? name, double? costPerUnit}) => Consumer(
    id: id ?? this.id,
    name: name ?? this.name,
    costPerUnit: costPerUnit ?? this.costPerUnit,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'cost_per_unit': costPerUnit,
  };

  static Consumer fromMap(Map<String, dynamic> map) => Consumer(
    id: map['id'] as int?,
    name: map['name'] as String,
    costPerUnit: (map['cost_per_unit'] as num).toDouble(),
  );
}
