import 'dart:math';
import 'dart:ui';

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
    // 動物・鳥 (5+1) — HTML galaxy.html NAME_NOUN_EN 準拠
    'Serpent', 'Trident', 'Anchor', 'Bow', 'Butterfly', 'Leviathan',
    // 武器・道具 (5+1)
    'Arrow', 'Sword', 'Shield', 'Key', 'Lantern', 'Excalibur',
    // 王権・宝物 (5+1)
    'Crown', 'Chalice', 'Throne', 'Scepter', 'Jewel', "Philosopher's Stone",
    // 自然・植物 (5+1)
    'Flame', 'Tempest', 'Pyramid', 'Ember', 'Glacier', 'Yggdrasil',
    // 建造物・場所 (4+1)
    'Gate', 'Tower', 'Lighthouse', 'Citadel', 'Babel',
    // 象徴・紋章 (5+1)
    'Emblem', 'Mirror', 'Hourglass', 'Scale', 'Mask', 'Pandora',
    // 楽器・芸術 (3+1)
    'Harp', 'Bell', 'Lyre', 'Compass',
    // 身体・翼 (4+1)
    'Wing', 'Feather', 'Eye', 'Halo', 'Third Eye',
    // 幾何・抽象 (3+1)
    'Crux', 'Prism', 'Ring', 'Möbius',
  ]; // 61 total

  static const _nounsJP = [
    // 天体・宇宙
    '軌道', '彗星', '流星', '新星', '三日月', '特異点',
    // 神話の生き物
    'フェニックス', 'ドラゴン', 'グリフィン', 'ユニコーン', 'ペガサス', 'クラーケン', 'ウロボロス',
    // 動物・鳥 — HTML galaxy.html NAME_NOUN_JP 準拠
    'サーペント', 'トライデント', 'アンカー', '弓', '蝶', 'レヴィアタン',
    // 武器・道具
    '矢', '剣', '盾', '鍵', '灯火', '聖剣',
    // 王権・宝物
    '冠', '聖杯', '玉座', '笏杖', '宝玉', '賢者の石',
    // 自然・植物
    '炎', '嵐', 'ピラミッド', '残火', '氷河', '世界樹',
    // 建造物・場所
    '門', '塔', '灯台', '城砦', '天楼',
    // 象徴・紋章
    '紋章', '鏡', '砂時計', '天秤', '仮面', 'パンドラ',
    // 楽器・芸術
    '竪琴', '鐘', 'リラ', 'コンパス',
    // 身体・翼
    '翼', '羽根', '眼', '光輪', '第三の眼',
    // 幾何・抽象
    'クラクス', '稜鏡', 'リング', '無終環',
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

  /// Build name directly from adjIdx + nounIdx
  static String buildName(int adjIdx, int nounIdx, {bool en = true}) {
    final adj = en ? _adjectivesEN : _adjectivesJP;
    final noun = en ? _nounsEN : _nounsJP;
    final a = adjIdx.clamp(0, adj.length - 1);
    final n = nounIdx.clamp(0, noun.length - 1);
    return en ? 'The ${adj[a]} ${noun[n]}' : '${adj[a]}${noun[n]}';
  }

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

  // ============================================================
  // NOUN_SHAPES — Connection type per noun (HTML exact: 61 entries)
  // ============================================================

  static const nounShapes = [
    'loop','linear','linear','radial','linear','radial',
    'open','open','open','open','open','radial','loop',
    'linear','radial','open','open','closed','open',
    'linear','linear','closed','open','closed','linear',
    'closed','closed','open','loop','closed','radial',
    'radial','closed','closed','closed','open','open',
    'closed','linear','linear','closed','open',
    'closed','closed','closed','open','closed','closed',
    'open','closed','closed','closed',
    'open','linear','closed','loop','closed',
    'loop','closed','loop','loop',
  ];

  // ============================================================
  // ADJ_COLORS — Primary color per adjective (HTML exact: 20 colors)
  // ============================================================

  static const adjColors = [
    0xFFF9D976, 0xFFC4923A, // Golden, Sacred
    0xFFC0C8E0, 0xFFE8ECF8, // Silver, Luminous
    0xFFDC143C, 0xFFFF6B35, // Crimson, Burning
    0xFF7EB8DA, 0xFFB8D8F0, // Ethereal, Spectral
    0xFF9B6BFF, 0xFF5A2D82, // Mystic, Arcane
    0xFF4A4A5A, 0xFF6A6A7A, // Silent, Veiled
    0xFF68C8E8, 0xFF1A3A5A, // Frozen, Abyssal
    0xFF5AA050, 0xFF3A5A2A, // Ancient, Verdant
    0xFFF0F0FF, 0xFFD0D8F0, // Infinite, Celestial
    0xFFFFF4C0, 0xFFC8A0FF, // Radiant, Phantom
  ];

  /// Get adjective color for a given adjective index.
  static Color adjColor(int adjIdx) {
    if (adjIdx >= 0 && adjIdx < adjColors.length) {
      return Color(adjColors[adjIdx]);
    }
    return const Color(0xFFF9D976);
  }

  // ============================================================
  // NOUN_TEMPLATES — Anchor coordinate templates per noun (HTML exact: 61 patterns)
  // Each is a list of [x, y] normalized 0-1.
  // ============================================================

  // galaxy.html NOUN_TEMPLATES (line 934-996) — 星座絵と一致する正しいテンプレート座標
  static const nounTemplates = <int, List<List<double>>>{
    0: [[.5,.2],[.75,.3],[.8,.5],[.7,.7],[.45,.8],[.2,.7],[.15,.5],[.25,.3]], // orbit
    1: [[.7,.25],[.55,.4],[.4,.55],[.25,.7],[.75,.35],[.8,.45]], // comet
    2: [[.2,.85],[.35,.65],[.5,.5],[.65,.35],[.8,.15]], // meteor
    3: [[.5,.5],[.5,.15],[.8,.35],[.8,.65],[.5,.85],[.2,.65],[.2,.35]], // nova
    4: [[.4,.2],[.55,.35],[.6,.5],[.55,.65],[.4,.8]], // crescent
    5: [[.5,.5],[.25,.2],[.75,.2],[.85,.5],[.75,.8],[.25,.8],[.15,.5]], // singularity
    6: [[.5,.8],[.4,.6],[.6,.6],[.2,.4],[.8,.4],[.15,.2],[.85,.2]], // phoenix
    7: [[.7,.2],[.55,.3],[.4,.45],[.5,.55],[.65,.65],[.5,.8],[.3,.75]], // dragon
    8: [[.7,.15],[.75,.25],[.65,.3],[.6,.4],[.55,.5],[.7,.55],[.75,.7],[.8,.85],[.45,.7],[.4,.85],[.3,.55],[.25,.7],[.2,.85],[.35,.35]], // griffin
    9: [[.82,.15],[.72,.2],[.62,.25],[.5,.3],[.45,.4],[.4,.5],[.5,.55],[.6,.55],[.55,.7],[.5,.85],[.65,.7],[.65,.85],[.35,.7],[.35,.85]], // unicorn
    10: [[.1,.3],[.25,.3],[.4,.3],[.5,.3],[.6,.3],[.75,.3],[.9,.3],[.5,.45],[.5,.55],[.5,.65],[.45,.8],[.55,.8],[.4,.85],[.6,.85]], // pegasus
    11: [[.5,.35],[.5,.2],[.35,.45],[.65,.45],[.2,.15],[.15,.35],[.1,.55],[.8,.15],[.85,.35],[.9,.55],[.25,.7],[.2,.85],[.75,.7],[.8,.85]], // kraken
    12: [[.5,.2],[.75,.3],[.8,.55],[.65,.75],[.35,.75],[.2,.55],[.25,.3]], // ouroboros
    13: [[.75,.2],[.6,.35],[.45,.45],[.55,.6],[.4,.75],[.3,.85]], // serpent
    14: [[.5,.15],[.5,.4],[.5,.7],[.5,.9],[.3,.2],[.7,.2],[.4,.2],[.6,.2]], // trident
    15: [[.5,.15],[.4,.25],[.6,.25],[.5,.35],[.5,.6],[.35,.8],[.65,.8],[.5,.9]], // anchor
    16: [[.3,.3],[.3,.5],[.3,.7],[.45,.35],[.55,.2],[.65,.15],[.75,.2],[.85,.35],[.55,.45]], // bow
    17: [[.5,.35],[.5,.55],[.5,.75],[.3,.2],[.2,.35],[.25,.55],[.35,.65],[.7,.2],[.8,.35],[.75,.55],[.65,.65]], // butterfly
    18: [[.85,.3],[.7,.4],[.55,.35],[.4,.45],[.25,.55],[.15,.7]], // leviathan
    19: [[.2,.8],[.35,.65],[.5,.5],[.65,.35],[.8,.2]], // arrow
    20: [[.5,.08],[.5,.3],[.5,.5],[.5,.65],[.5,.9],[.28,.65],[.72,.65]], // sword
    21: [[.3,.2],[.7,.2],[.75,.5],[.6,.75],[.5,.85],[.4,.75],[.25,.5]], // shield
    22: [[.5,.2],[.4,.3],[.6,.3],[.5,.4],[.5,.6],[.5,.8],[.6,.75]], // key
    23: [[.5,.15],[.5,.3],[.65,.5],[.5,.7],[.35,.5],[.5,.85]], // lantern
    24: [[.5,.05],[.5,.35],[.5,.65],[.5,.9],[.2,.3],[.8,.3]], // excalibur
    25: [[.2,.6],[.3,.3],[.5,.55],[.5,.2],[.7,.3],[.8,.6]], // crown
    26: [[.3,.25],[.7,.25],[.7,.5],[.3,.5],[.5,.6],[.5,.8],[.35,.85],[.65,.85]], // chalice
    27: [[.35,.1],[.65,.1],[.7,.15],[.7,.45],[.65,.5],[.35,.5],[.3,.45],[.3,.15],[.3,.75],[.7,.75]], // throne
    28: [[.45,.12],[.55,.12],[.58,.18],[.55,.24],[.45,.24],[.42,.18],[.5,.18],[.5,.35],[.5,.55],[.5,.85]], // scepter
    29: [[.5,.2],[.7,.4],[.65,.65],[.5,.8],[.35,.65],[.3,.4]], // jewel
    30: [[.5,.15],[.25,.7],[.75,.7],[.5,.45],[.3,.45],[.7,.45]], // philosophers_stone
    31: [[.5,.85],[.45,.65],[.55,.5],[.4,.35],[.6,.25],[.5,.1]], // flame
    32: [[.5,.3],[.65,.2],[.8,.3],[.85,.5],[.75,.7],[.55,.75],[.35,.7],[.15,.5],[.2,.3]], // tempest
    33: [[.5,.12],[.2,.82],[.8,.82],[.5,.82],[.5,.5],[.35,.47],[.65,.47]], // pyramid
    34: [[.25,.85],[.75,.85],[.8,.7],[.65,.5],[.55,.35],[.5,.2],[.45,.35],[.35,.5],[.2,.7]], // ember
    35: [[.1,.55],[.3,.4],[.45,.5],[.6,.35],[.75,.45],[.9,.5]], // glacier
    36: [[.5,.5],[.5,.4],[.5,.6],[.5,.3],[.5,.7],[.5,.85],[.35,.9],[.65,.9],[.2,.95],[.8,.95],[.15,.88],[.85,.88],[.5,.18],[.5,.08],[.3,.12],[.7,.12],[.15,.06],[.85,.06],[.25,.18],[.75,.18]], // yggdrasil
    37: [[.3,.8],[.3,.4],[.4,.2],[.6,.2],[.7,.4],[.7,.8]], // gate
    38: [[.5,.1],[.45,.3],[.55,.3],[.43,.6],[.57,.6],[.4,.85],[.6,.85]], // tower
    39: [[.5,.08],[.45,.25],[.55,.25],[.42,.5],[.58,.5],[.38,.8],[.62,.8],[.5,.12]], // lighthouse
    40: [[.2,.8],[.2,.5],[.2,.2],[.35,.15],[.5,.2],[.65,.15],[.8,.2],[.8,.5],[.8,.8],[.5,.8]], // citadel
    41: [[.5,.1],[.4,.3],[.6,.3],[.35,.55],[.65,.55],[.3,.8],[.7,.8]], // babel
    42: [[.5,.15],[.73,.3],[.73,.6],[.5,.75],[.27,.6],[.27,.3]], // emblem
    43: [[.5,.15],[.68,.3],[.68,.55],[.5,.65],[.32,.55],[.32,.3],[.5,.85]], // mirror
    44: [[.3,.12],[.7,.12],[.5,.5],[.3,.88],[.7,.88],[.5,.12],[.5,.88]], // hourglass
    45: [[.5,.2],[.5,.6],[.2,.4],[.8,.4],[.15,.55],[.85,.55]], // scale
    46: [[.5,.15],[.7,.3],[.72,.55],[.6,.75],[.4,.75],[.28,.55],[.3,.3]], // mask
    47: [[.25,.4],[.75,.4],[.75,.75],[.25,.75],[.3,.3],[.7,.3]], // pandora
    48: [[.35,.15],[.35,.85],[.65,.8],[.65,.5],[.65,.25],[.35,.5]], // harp
    49: [[.5,.15],[.5,.3],[.65,.5],[.7,.7],[.3,.7],[.35,.5]], // bell
    50: [[.3,.12],[.7,.12],[.75,.35],[.7,.65],[.3,.65],[.25,.35],[.5,.7],[.4,.15],[.5,.15],[.6,.15]], // lyre
    51: [[.5,.12],[.5,.88],[.12,.5],[.88,.5],[.5,.5],[.35,.25],[.65,.25],[.35,.75],[.65,.75]], // compass
    52: [[.2,.65],[.35,.5],[.5,.35],[.7,.2],[.85,.25],[.75,.45]], // wing
    53: [[.45,.15],[.47,.35],[.5,.55],[.53,.75],[.55,.9],[.35,.45],[.65,.45]], // feather
    54: [[.15,.5],[.35,.3],[.65,.3],[.85,.5],[.65,.7],[.35,.7],[.5,.5]], // eye
    55: [[.5,.2],[.72,.3],[.78,.5],[.72,.65],[.5,.72],[.28,.65],[.22,.5],[.28,.3]], // halo
    56: [[.5,.15],[.65,.4],[.5,.5],[.35,.4],[.5,.85],[.65,.6],[.35,.6]], // third_eye
    57: [[.5,.1],[.65,.18],[.78,.35],[.82,.55],[.72,.72],[.55,.82],[.38,.82],[.22,.72],[.15,.52],[.2,.32],[.32,.18],[.5,.5],[.5,.25],[.5,.75],[.25,.5],[.75,.5]], // crux
    58: [[.3,.25],[.3,.75],[.6,.5],[.75,.3],[.75,.5],[.75,.7]], // prism
    59: [[.5,.18],[.73,.28],[.82,.5],[.73,.72],[.5,.82],[.27,.72],[.18,.5],[.27,.28]], // ring
    60: [[.5,.4],[.6,.3],[.7,.25],[.75,.35],[.7,.48],[.6,.5],[.5,.55],[.4,.6],[.3,.68],[.25,.58],[.3,.45],[.4,.4]], // mobius
  };

  /// Get template anchor positions for a noun, with jitter.
  /// HTML exact: getTemplatePositions(nounIdx, numAnchors, seed)
  static List<List<double>> getTemplatePositions(int nounIdx, int numAnchors, int seed) {
    final template = nounTemplates[nounIdx];
    if (template == null) {
      final rng = Random(seed);
      return List.generate(numAnchors, (_) => [0.15 + rng.nextDouble() * 0.7, 0.15 + rng.nextDouble() * 0.7]);
    }

    final rng = Random(seed);
    const jitter = 0.04;

    if (numAnchors <= template.length) {
      final step = template.length / numAnchors;
      return List.generate(numAnchors, (i) {
        final ti = (i * step).round().clamp(0, template.length - 1);
        return [
          template[ti][0] + (rng.nextDouble() - 0.5) * jitter * 2,
          template[ti][1] + (rng.nextDouble() - 0.5) * jitter * 2,
        ];
      });
    }

    return List.generate(numAnchors, (i) {
      final tIdx = (i / numAnchors) * template.length;
      final lo = tIdx.floor();
      final hi = (lo + 1).clamp(0, template.length - 1);
      final frac = tIdx - lo;
      final x = template[lo][0] + frac * (template[hi][0] - template[lo][0]);
      final y = template[lo][1] + frac * (template[hi][1] - template[lo][1]);
      return [
        x + (rng.nextDouble() - 0.5) * jitter * 2,
        y + (rng.nextDouble() - 0.5) * jitter * 2,
      ];
    });
  }

  // ============================================================
  // MST (Prim's algorithm) + buildConstellationEdges
  // HTML exact: computeMST, buildConstellationEdges
  // ============================================================

  /// Compute Minimum Spanning Tree using Prim's algorithm.
  static List<({int from, int to})> computeMST(List<Offset> points) {
    final n = points.length;
    if (n <= 1) return [];
    if (n == 2) return [(from: 0, to: 1)];

    final inTree = List.filled(n, false);
    final minEdge = List.filled(n, double.infinity);
    final minFrom = List.filled(n, -1);
    final edges = <({int from, int to})>[];

    minEdge[0] = 0;
    for (int iter = 0; iter < n; iter++) {
      int u = -1;
      for (int i = 0; i < n; i++) {
        if (!inTree[i] && (u == -1 || minEdge[i] < minEdge[u])) u = i;
      }
      inTree[u] = true;
      if (minFrom[u] != -1) {
        edges.add((from: minFrom[u], to: u));
      }
      for (int v = 0; v < n; v++) {
        if (inTree[v]) continue;
        final d = (points[u] - points[v]).distance;
        if (d < minEdge[v]) {
          minEdge[v] = d;
          minFrom[v] = u;
        }
      }
    }
    return edges;
  }

  /// Build constellation edge list based on MST + shape type.
  /// HTML exact: buildConstellationEdges(anchorPoints, shapeType)
  static List<({int from, int to})> buildEdges(List<Offset> anchors, String shapeType) {
    if (anchors.length <= 1) return [];

    // -- Linear: nearest-neighbor chain
    if (shapeType == 'linear') {
      final remaining = List.generate(anchors.length, (i) => i);
      final ordered = [remaining.removeAt(0)];
      while (remaining.isNotEmpty) {
        final last = ordered.last;
        var nearIdx = 0;
        var nearDist = double.infinity;
        for (int i = 0; i < remaining.length; i++) {
          final d = (anchors[remaining[i]] - anchors[last]).distance;
          if (d < nearDist) { nearDist = d; nearIdx = i; }
        }
        ordered.add(remaining.removeAt(nearIdx));
      }
      return [for (int i = 0; i < ordered.length - 1; i++) (from: ordered[i], to: ordered[i + 1])];
    }

    final edges = computeMST(anchors);

    // -- Closed / Loop: connect farthest leaves
    if (shapeType == 'closed' || shapeType == 'loop') {
      final degree = List.filled(anchors.length, 0);
      for (final e in edges) { degree[e.from]++; degree[e.to]++; }
      final leaves = [for (int i = 0; i < anchors.length; i++) if (degree[i] == 1) i];
      if (leaves.length >= 2) {
        var bestDist = 0.0;
        var bestA = leaves[0], bestB = leaves[1];
        for (int i = 0; i < leaves.length; i++) {
          for (int j = i + 1; j < leaves.length; j++) {
            final d = (anchors[leaves[i]] - anchors[leaves[j]]).distance;
            if (d > bestDist) { bestDist = d; bestA = leaves[i]; bestB = leaves[j]; }
          }
        }
        edges.add((from: bestA, to: bestB));
        if (shapeType == 'loop' && leaves.length >= 4) {
          final rest = leaves.where((l) => l != bestA && l != bestB).toList();
          if (rest.length >= 2) edges.add((from: rest[0], to: rest[1]));
        }
      }
    }

    // -- Radial: connect all to center
    if (shapeType == 'radial') {
      final cx = anchors.fold(0.0, (s, p) => s + p.dx) / anchors.length;
      final cy = anchors.fold(0.0, (s, p) => s + p.dy) / anchors.length;
      var nearestIdx = 0;
      var nearestDist = double.infinity;
      for (int i = 0; i < anchors.length; i++) {
        final d = (anchors[i] - Offset(cx, cy)).distance;
        if (d < nearestDist) { nearestDist = d; nearestIdx = i; }
      }
      final connected = <int>{};
      for (final e in edges) {
        if (e.from == nearestIdx) connected.add(e.to);
        if (e.to == nearestIdx) connected.add(e.from);
      }
      for (int i = 0; i < anchors.length; i++) {
        if (i != nearestIdx && !connected.contains(i)) {
          edges.add((from: nearestIdx, to: i));
        }
      }
    }

    return edges;
  }

  // ============================================================
  // HTML: NOUN_FILENAMES — asset file names for constellation art
  // ============================================================

  static const nounFilenames = [
    'orbit','comet','meteor','nova','crescent','singularity',
    'phoenix','dragon','griffin','unicorn','pegasus','kraken','ouroboros',
    'serpent','trident','anchor','bow','butterfly','leviathan',
    'arrow','sword','shield','key','lantern','excalibur',
    'crown','chalice','throne','scepter','jewel','philosophers_stone',
    'flame','tempest','pyramid','ember','glacier','yggdrasil',
    'gate','tower','lighthouse','citadel','babel',
    'emblem','mirror','hourglass','scale','mask','pandora',
    'harp','bell','lyre','compass',
    'wing','feather','eye','halo','third_eye',
    'crux','prism','ring','mobius',
  ]; // 61 total

  /// HTML: NOUN_ART_TRANSFORMS — only index 4 (crescent) is flipX
  static bool isFlipX(int nounIdx) => nounIdx == 4;

  /// Get the asset path for a noun's constellation art
  static String artAssetPath(int nounIdx) {
    if (nounIdx < 0 || nounIdx >= nounFilenames.length) return '';
    return 'assets/constellation-art/${nounFilenames[nounIdx]}.webp';
  }
}
