class TarotCard {
  final int id;
  final String nameEN;
  final String nameJP;
  final String keyword;
  final String? planet;
  final String element;
  final String? suit;
  final int? rank;
  final String displayName;
  final String emoji;
  final bool isMajor;

  /// カード画像のアセットパス
  /// Major: M00〜M21, Wands: W01〜W14, Cups: C01〜C14, Swords: S01〜S14, Pentacles: P01〜P14
  String get imagePath {
    if (isMajor) return 'assets/card-images/M${id.toString().padLeft(2, '0')}.webp';
    final suitPrefix = {'wands':'W','cups':'C','swords':'S','pentacles':'P'}[suit] ?? 'W';
    final rankNum = (id - 22) % 14 + 1;
    return 'assets/card-images/$suitPrefix${rankNum.toString().padLeft(2, '0')}.webp';
  }

  const TarotCard({
    required this.id,
    required this.nameEN,
    required this.nameJP,
    required this.keyword,
    this.planet,
    required this.element,
    this.suit,
    this.rank,
    required this.displayName,
    required this.emoji,
    required this.isMajor,
  });

  factory TarotCard.fromMajorJson(Map<String, dynamic> json) {
    return TarotCard(
      id: json['id'] as int,
      nameEN: json['nameEN'] as String,
      nameJP: json['nameJP'] as String,
      keyword: json['keyword'] as String,
      planet: json['planet'] as String?,
      element: json['element'] as String,
      displayName: json['displayName'] as String,
      emoji: json['emoji'] as String,
      isMajor: true,
    );
  }

  factory TarotCard.fromMinorJson(
    Map<String, dynamic> json, {
    required int id,
    required String element,
    required String suitEmoji,
    String? planet, // HTML: SUIT_MAP[suit].planets[0]
  }) {
    return TarotCard(
      id: id,
      nameEN: json['nameEN'] as String,
      nameJP: json['nameJP'] as String,
      keyword: json['keyword'] as String,
      planet: planet,
      element: element,
      suit: json['suit'] as String,
      rank: json['rank'] as int,
      displayName: json['displayName'] as String,
      emoji: suitEmoji,
      isMajor: false,
    );
  }
}
