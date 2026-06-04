// ══════════════════════════════════════════════════
// Shared constants for Observe (Tarot) screen
// ══════════════════════════════════════════════════

import '../../utils/solara_i18n.dart';

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

/// 惑星キー → 英語名 (en ロケール用)。ja は planetInfo[k][1]。
const _planetNamesEN = <String, String>{
  'sun': 'Sun', 'moon': 'Moon', 'mercury': 'Mercury', 'venus': 'Venus',
  'mars': 'Mars', 'jupiter': 'Jupiter', 'saturn': 'Saturn',
  'uranus': 'Uranus', 'neptune': 'Neptune', 'pluto': 'Pluto',
};

/// 惑星キー → ロケール別表示名 (ja=漢字 / en=英名)。
String observePlanetName(String key) =>
    isEnLocale() ? (_planetNamesEN[key] ?? key) : (planetInfo[key]?[1] ?? key);

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
const _elementNamesEN = <String, String>{
  'fire': 'Fire', 'water': 'Water', 'air': 'Air', 'earth': 'Earth',
};

/// エレメントキー → ロケール別表示名 (ja=漢字 / en=英名)。
String elementName(String key) =>
    isEnLocale() ? (_elementNamesEN[key] ?? key) : (elementNames[key] ?? key);
const elementEmojis = <String, String>{
  'fire': '🔥', 'water': '🌊', 'air': '💨', 'earth': '🌿',
};
