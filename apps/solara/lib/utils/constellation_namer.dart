import 'dart:math';

/// Constellation name generator v2.
/// 20 adjectives × 61 nouns = 1,220 unique names.
/// Deterministic hash from seedCardId + date.
/// Rarity based on adjective tier × noun tier.
class ConstellationNamer {
  // === 形容詞 20個 (10色系統 × 2段階) ===
  static const _adjectivesEN = [
    'Golden', 'Sacred', // 金/暖色
    'Silver', 'Luminous', // 銀/月光
    'Crimson', 'Burning', // 赤/炎
    'Ethereal', 'Spectral', // 青白/霊的
    'Mystic', 'Arcane', // 紫/神秘
    'Silent', 'Veiled', // 暗/静寂
    'Frozen', 'Abyssal', // 氷/青
    'Ancient', 'Verdant', // 緑/自然
    'Infinite', 'Celestial', // 白/光
    'Radiant', 'Phantom', // 虹/多色
  ];
  static const _adjectivesJP = [
    '黄金の', '聖なる',
    '銀色の', '光輝の',
    '深紅の', '燃ゆる',
    '幽玄の', '霊妙の',
    '秘密の', '秘奥の',
    '静寂の', '隠されし',
    '凍てつく', '深淵の',
    '古の', '翠の',
    '無限の', '天上の',
    '煌めきの', '幻影の',
  ];

  /// Adjective rarity tiers: 0=Common, 1=Uncommon, 2=Rare
  static const _adjTiers = [
    0, 1, // Golden(C), Sacred(U)
    0, 0, // Silver(C), Luminous(C)
    0, 0, // Crimson(C), Burning(C)
    0, 1, // Ethereal(C), Spectral(U)
    2, 2, // Mystic(R), Arcane(R)
    0, 1, // Silent(C), Veiled(U)
    0, 1, // Frozen(C), Abyssal(U)
    0, 0, // Ancient(C), Verdant(C)
    0, 0, // Infinite(C), Celestial(C)
    0, 2, // Radiant(C), Phantom(R)
  ];

  // === 名詞 61個 (50通常 + 11レア) ===
  static const _nounsEN = [
    // 天体・宇宙 (5+1)
    'Orbit', 'Comet', 'Meteor', 'Nova', 'Crescent', 'Singularity',
    // 神話の生き物 (6+1)
    'Phoenix', 'Dragon', 'Griffin', 'Unicorn', 'Pegasus', 'Kraken', 'Ouroboros',
    // 動物・鳥 (5+1)
    'Serpent', 'Raven', 'Wolf', 'Owl', 'Butterfly', 'Leviathan',
    // 武器・道具 (5+1)
    'Arrow', 'Sword', 'Shield', 'Key', 'Lantern', 'Excalibur',
    // 王権・宝物 (5+1)
    'Crown', 'Chalice', 'Throne', 'Scepter', 'Jewel', "Philosopher's Stone",
    // 自然・植物 (5+1)
    'Flame', 'Tempest', 'Lotus', 'Ember', 'Glacier', 'Yggdrasil',
    // 建造物・場所 (4+1)
    'Gate', 'Tower', 'Labyrinth', 'Fountain', 'Babel',
    // 象徴・紋章 (5+1)
    'Sigil', 'Mirror', 'Hourglass', 'Scale', 'Mask', 'Akashic',
    // 楽器・芸術 (3+1)
    'Harp', 'Bell', 'Requiem', 'Orpheus',
    // 身体・翼 (4+1)
    'Wing', 'Feather', 'Eye', 'Halo', 'Third Eye',
    // 幾何・抽象 (3+1)
    'Spiral', 'Prism', 'Vortex', 'Möbius',
  ]; // 61 total

  static const _nounsJP = [
    // 天体・宇宙
    '軌道', '彗星', '流星', '新星', '三日月', '特異点',
    // 神話の生き物
    'フェニックス', 'ドラゴン', 'グリフィン', 'ユニコーン', 'ペガサス', 'クラーケン', 'ウロボロス',
    // 動物・鳥
    'サーペント', 'レイヴン', '狼', 'アウル', '蝶', 'レヴィアタン',
    // 武器・道具
    '矢', '剣', '盾', '鍵', '灯火', '聖剣',
    // 王権・宝物
    '冠', '聖杯', '玉座', '笏杖', '宝玉', '賢者の石',
    // 自然・植物
    '炎', '嵐', '蓮', '残火', '氷河', '世界樹',
    // 建造物・場所
    '門', '塔', '迷宮', '泉', '天楼',
    // 象徴・紋章
    '印章', '鏡', '砂時計', '天秤', '仮面', '阿頼耶',
    // 楽器・芸術
    '竪琴', '鐘', '鎮魂歌', '竪琴師',
    // 身体・翼
    '翼', '羽根', '眼', '光輪', '第三の眼',
    // 幾何・抽象
    '螺旋', '稜鏡', '渦', '無終環',
  ]; // 61 total

  /// Noun rarity tiers: 0=Common, 1=Uncommon, 2=Rare, 3=Legendary
  static const _nounTiers = [
    // 天体 (5+1)
    0, 0, 1, 1, 0, 3,
    // 神話 (6+1)
    0, 0, 1, 0, 1, 2, 3,
    // 動物 (5+1)
    0, 0, 0, 1, 1, 3,
    // 武器 (5+1)
    0, 0, 0, 1, 1, 3,
    // 王権 (5+1)
    0, 0, 1, 1, 0, 3,
    // 自然 (5+1)
    0, 0, 1, 1, 2, 3,
    // 建造物 (4+1)
    0, 0, 1, 1, 3,
    // 象徴 (5+1)
    0, 0, 0, 1, 2, 3,
    // 楽器 (3+1)
    0, 0, 2, 3,
    // 身体 (4+1)
    0, 0, 1, 2, 3,
    // 幾何 (3+1)
    0, 1, 2, 3,
  ];

  /// Adjective color hue shifts for constellation illustration tinting.
  /// Returns a hue rotation in degrees (0-360).
  static const _adjHueShifts = [
    40, 45, // Golden, Sacred → warm
    210, 220, // Silver, Luminous → cool
    0, 15, // Crimson, Burning → red
    195, 200, // Ethereal, Spectral → light blue
    270, 280, // Mystic, Arcane → purple
    240, 250, // Silent, Veiled → dark
    190, 200, // Frozen, Abyssal → blue
    120, 130, // Ancient, Verdant → green
    0, 0, // Infinite, Celestial → white (no shift)
    50, 290, // Radiant, Phantom → gold / purple
  ];

  /// Generate a deterministic constellation name.
  /// [usedNames] — set of already-used EN names for deduplication.
  static ({String en, String jp, int adjIdx, int nounIdx}) generate({
    required int seedCardId,
    required DateTime date,
    Set<String>? usedNames,
  }) {
    final dateStr = date.toIso8601String().substring(0, 10);
    final seed = '$seedCardId$dateStr';
    int hash = _hash(seed);

    // Try up to 1220 combinations to find an unused name
    final totalCombos = _adjectivesEN.length * _nounsEN.length;
    for (int attempt = 0; attempt < totalCombos; attempt++) {
      final adjIdx = (hash + attempt) % _adjectivesEN.length;
      final nounIdx = ((hash >> 8) + attempt * 7) % _nounsEN.length;
      final nameEN = 'The ${_adjectivesEN[adjIdx]} ${_nounsEN[nounIdx]}';

      if (usedNames == null || !usedNames.contains(nameEN)) {
        final nameJP = '${_adjectivesJP[adjIdx]}${_nounsJP[nounIdx]}';
        return (en: nameEN, jp: nameJP, adjIdx: adjIdx, nounIdx: nounIdx);
      }
    }

    // Fallback (all 1220 used — 2nd orbit)
    final adjIdx = hash % _adjectivesEN.length;
    final nounIdx = (hash >> 8) % _nounsEN.length;
    return (
      en: '★★ The ${_adjectivesEN[adjIdx]} ${_nounsEN[nounIdx]}',
      jp: '★★ ${_adjectivesJP[adjIdx]}${_nounsJP[nounIdx]}',
      adjIdx: adjIdx,
      nounIdx: nounIdx,
    );
  }

  /// Calculate rarity from adjective and noun indices.
  /// Returns (stars: 1-5, label: String).
  static ({int stars, String label}) calculateRarity(int adjIdx, int nounIdx) {
    if (adjIdx >= _adjTiers.length || nounIdx >= _nounTiers.length) {
      return (stars: 1, label: 'Common');
    }
    final adjTier = _adjTiers[adjIdx]; // 0=Common, 1=Uncommon, 2=Rare
    final nounTier = _nounTiers[nounIdx]; // 0-3

    // Rarity matrix: adj tier + noun tier
    final combined = adjTier + nounTier;
    switch (combined) {
      case 0: return (stars: 1, label: 'Common');
      case 1: return (stars: 2, label: 'Uncommon');
      case 2: return (stars: 3, label: 'Rare');
      case 3: return (stars: 4, label: 'Legendary');
      default: return (stars: 5, label: 'Mythic');
    }
  }

  /// Hash-based rarity percentage (Phase 1: mathematical).
  /// Uses hash distribution to determine if this specific combo is
  /// even rarer than its tier suggests.
  static double rarityPercentage(int adjIdx, int nounIdx) {
    // Base percentage from tier
    final r = calculateRarity(adjIdx, nounIdx);
    switch (r.stars) {
      case 5: return 0.5 + Random(adjIdx * 61 + nounIdx).nextDouble() * 0.5;
      case 4: return 1.0 + Random(adjIdx * 61 + nounIdx).nextDouble() * 1.0;
      case 3: return 2.0 + Random(adjIdx * 61 + nounIdx).nextDouble() * 2.0;
      case 2: return 4.0 + Random(adjIdx * 61 + nounIdx).nextDouble() * 3.0;
      default: return 7.0 + Random(adjIdx * 61 + nounIdx).nextDouble() * 10.0;
    }
  }

  /// Get the hue shift for a given adjective index.
  static int hueShift(int adjIdx) {
    if (adjIdx < _adjHueShifts.length) return _adjHueShifts[adjIdx];
    return 0;
  }

  static int _hash(String s) {
    int hash = 0;
    for (int i = 0; i < s.length; i++) {
      hash = ((hash << 5) - hash) + s.codeUnitAt(i);
      hash = hash & 0x7FFFFFFF;
    }
    return hash;
  }
}
