class DailyReading {
  final String date; // ISO "2026-04-03"
  final int cardId; // 0-77
  final bool isMajor;
  final double moonPhase; // 0.0-29.53
  final bool reversed; // 正逆位置（false=正位置, true=逆位置）
  String reading; // Stella による /tarot リーディング本文
  String synchronicity; // HTML: sync-input textarea (editable)

  /// A3 で追加した質問入力欄 (Pro のみ送信、最大 200 字)。
  /// 旧データには無いので nullable、未保存時は null。
  String? question;

  /// 占いカテゴリ。null = 全体運。
  /// 値: love / money / work / communication / healing / newStart の 6 種。
  /// 2026-05-26 Tarot 1日1回統一改修で追加: 翌日まで引き直しできないので、
  /// 当日の Tarot 画面復元時にこのカテゴリで chip selected 表示にする。
  /// 旧データには無いので nullable、未保存時は null (= 全体運扱い)。
  final String? category;

  DailyReading({
    required this.date,
    required this.cardId,
    required this.isMajor,
    required this.moonPhase,
    this.reversed = false,
    this.reading = '',
    this.synchronicity = '',
    this.question,
    this.category,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'cardId': cardId,
        'isMajor': isMajor,
        'moonPhase': moonPhase,
        'reversed': reversed,
        'reading': reading,
        'synchronicity': synchronicity,
        if (question != null && question!.isNotEmpty) 'question': question,
        if (category != null && category!.isNotEmpty) 'category': category,
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
      question: json['question'] as String?,
      category: json['category'] as String?,
    );
  }
}
