class DailyReading {
  final String date; // ISO "2026-04-03"
  final int cardId; // 0-77
  final bool isMajor;
  final double moonPhase; // 0.0-29.53
  final bool reversed; // 正逆位置（false=正位置, true=逆位置）
  String reading; // Gemini /tarot 生成のリーディング本文
  String synchronicity; // HTML: sync-input textarea (editable)

  DailyReading({
    required this.date,
    required this.cardId,
    required this.isMajor,
    required this.moonPhase,
    this.reversed = false,
    this.reading = '',
    this.synchronicity = '',
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'cardId': cardId,
        'isMajor': isMajor,
        'moonPhase': moonPhase,
        'reversed': reversed,
        'reading': reading,
        'synchronicity': synchronicity,
      };

  factory DailyReading.fromJson(Map<String, dynamic> json) {
    return DailyReading(
      date: json['date'] as String,
      cardId: json['cardId'] as int,
      isMajor: json['isMajor'] as bool,
      moonPhase: (json['moonPhase'] as num).toDouble(),
      reversed: json['reversed'] as bool? ?? false,
      reading: json['reading'] as String? ?? '',
      synchronicity: json['synchronicity'] as String? ?? '',
    );
  }
}
