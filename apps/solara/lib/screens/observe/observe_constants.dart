// ══════════════════════════════════════════════════
// Shared constants for Observe (Tarot) screen
// ══════════════════════════════════════════════════

// tarotReadings 削除 (2026-06-03): タロット取得失敗時の静的テンプレ fallback。
// fake で取り繕わず素直に「失敗+再試行」を出す方針へ転換 (拠点/星読みと統一) → 参照ゼロ。
// tarotAdvices 削除 (audit dead-symbol, 2026-05-06): HTML mockup の遺物で参照ゼロ。

// HTML exact: PLANET_SYMBOLS
const planetInfo = <String, List<String>>{
  // key: [symbol, nameJP, color hex]
  'sun':     ['☉', '太陽',   'FFD700'],
  'moon':    ['☽', '月',     'C0C0C0'],
  'mercury': ['☿', '水星',   '87CEEB'],
  'venus':   ['♀', '金星',   'FF69B4'],
  'mars':    ['♂', '火星',   'FF4500'],
  'jupiter': ['♃', '木星',   'FFA500'],
  'saturn':  ['♄', '土星',   '808080'],
  'uranus':  ['♅', '天王星', '00CED1'],
  'neptune': ['♆', '海王星', '4169E1'],
  'pluto':   ['♇', '冥王星', '8B0000'],
};

// HTML exact: ELEMENT_* maps
const elementColors = <String, int>{
  'fire': 0xFFFF6B35,
  'water': 0xFF4169E1,
  'air': 0xFF87CEEB,
  'earth': 0xFF2E8B57,
};
const elementNames = <String, String>{
  'fire': '火', 'water': '水', 'air': '風', 'earth': '地',
};
const elementEmojis = <String, String>{
  'fire': '🔥', 'water': '🌊', 'air': '💨', 'earth': '🌿',
};
