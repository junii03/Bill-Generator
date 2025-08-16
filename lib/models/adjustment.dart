import 'dart:convert';

class Adjustment {
  final String label;
  final double amount; // positive for charge, negative for discount

  Adjustment({required this.label, required this.amount});

  Map<String, dynamic> toMap() => {'label': label, 'amount': amount};

  static Adjustment fromMap(Map<String, dynamic> map) => Adjustment(
    label: map['label'] as String,
    amount: (map['amount'] as num).toDouble(),
  );

  static String encodeList(List<Adjustment> list) =>
      jsonEncode(list.map((e) => e.toMap()).toList());

  static List<Adjustment> decodeList(String jsonStr) {
    final data = jsonDecode(jsonStr) as List;
    return data
        .map((e) => Adjustment.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
