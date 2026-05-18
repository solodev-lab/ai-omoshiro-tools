import 'dart:convert';

class WeightRecord {
  final DateTime date;
  final double weight;
  final String? memo;

  WeightRecord({
    required this.date,
    required this.weight,
    this.memo,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'weight': weight,
        'memo': memo,
      };

  factory WeightRecord.fromJson(Map<String, dynamic> json) => WeightRecord(
        date: DateTime.parse(json['date']),
        weight: (json['weight'] as num).toDouble(),
        memo: json['memo'],
      );

  static String encodeList(List<WeightRecord> records) =>
      jsonEncode(records.map((r) => r.toJson()).toList());

  static List<WeightRecord> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List;
    return list.map((e) => WeightRecord.fromJson(e)).toList();
  }
}
