/// Constellation name generator.
/// Ported from mockup/galaxy.html generateConstellationName().
class ConstellationNamer {
  static const _adjectivesEN = [
    'Golden', 'Silver', 'Crimson', 'Ethereal', 'Radiant',
    'Silent', 'Infinite', 'Luminous', 'Frozen', 'Mystic',
  ];
  static const _nounsEN = [
    'Crown', 'Arrow', 'Veil', 'Flame', 'Chalice',
    'Mirror', 'Gate', 'Wing', 'Orbit', 'Sigil',
  ];
  static const _adjectivesJP = [
    '\u9ec4\u91d1\u306e', '\u9280\u8272\u306e', '\u6df1\u7d05\u306e',
    '\u9759\u5bc2\u306e', '\u714c\u3081\u304d\u306e', '\u7121\u9650\u306e',
    '\u5149\u8f1d\u306e', '\u51cd\u3066\u3064\u304f', '\u79d8\u5bc6\u306e',
    '\u6c38\u9060\u306e',
  ];
  static const _nounsJP = [
    '\u51a0', '\u77e2', '\u5e37', '\u708e', '\u8056\u676f',
    '\u93e1', '\u9580', '\u7ffc', '\u8ecc\u9053', '\u5370\u7ae0',
  ];

  /// Generate a deterministic constellation name from seedCardId and date.
  static String generate({
    required int seedCardId,
    required DateTime date,
    String lang = 'en',
  }) {
    final dateStr = date.toIso8601String().substring(0, 10);
    final seed = '$seedCardId$dateStr';

    int hash = 0;
    for (int i = 0; i < seed.length; i++) {
      hash = ((hash << 5) - hash) + seed.codeUnitAt(i);
      hash = hash & 0x7FFFFFFF; // keep positive
    }

    if (lang == 'jp') {
      final adj = _adjectivesJP[hash % _adjectivesJP.length];
      final noun = _nounsJP[(hash >> 4) % _nounsJP.length];
      return '$adj$noun';
    }
    final adj = _adjectivesEN[hash % _adjectivesEN.length];
    final noun = _nounsEN[(hash >> 4) % _nounsEN.length];
    return 'The $adj $noun';
  }
}
