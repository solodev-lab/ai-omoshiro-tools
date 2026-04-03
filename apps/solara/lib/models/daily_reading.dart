class DailyReading {
  final String date; // ISO "2026-04-03"
  final int cardId; // 0-77
  final bool isMajor;
  final double moonPhase; // 0.0-29.53

  const DailyReading({
    required this.date,
    required this.cardId,
    required this.isMajor,
    required this.moonPhase,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'cardId': cardId,
        'isMajor': isMajor,
        'moonPhase': moonPhase,
      };

  factory DailyReading.fromJson(Map<String, dynamic> json) {
    return DailyReading(
      date: json['date'] as String,
      cardId: json['cardId'] as int,
      isMajor: json['isMajor'] as bool,
      moonPhase: (json['moonPhase'] as num).toDouble(),
    );
  }
}
