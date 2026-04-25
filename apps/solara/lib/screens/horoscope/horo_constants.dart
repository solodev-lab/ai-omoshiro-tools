import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════
// Shared constants for Horoscope screen
// ══════════════════════════════════════════════════

const signs = ['♈','♉','♊','♋','♌','♍','♎','♏','♐','♑','♒','♓'];
const signNames = ['牡羊','牡牛','双子','蟹','獅子','乙女','天秤','蠍','射手','山羊','水瓶','魚'];
const signColors = [0xFFFF4444,0xFF4CAF50,0xFFFFD700,0xFFC0C0C0,0xFFFF8C00,0xFF8BC34A,
  0xFFE91E63,0xFF9C27B0,0xFF9C27B0,0xFF607D8B,0xFF00BCD4,0xFF3F51B5];
const planetGlyphs = {'sun':'☉','moon':'☽','mercury':'☿','venus':'♀','mars':'♂',
  'jupiter':'♃','saturn':'♄','uranus':'♅','neptune':'♆','pluto':'♇'};
const planetNamesJP = {'sun':'太陽','moon':'月','mercury':'水星','venus':'金星','mars':'火星',
  'jupiter':'木星','saturn':'土星','uranus':'天王星','neptune':'海王星','pluto':'冥王星'};

// HTML: FORTUNE_CATEGORIES (L2748-2773)
// 'score' / 'direction' は 2026-04 に未使用となり削除済（数値スコア表示廃止に伴う）。
const fortuneCategories = [
  {'id':'overall','icon':'✦','nameJP':'全体運','color':0xFFF6BD60,'bg':0x14F6BD60,'border':0x33F6BD60},
  {'id':'love','icon':'💕','nameJP':'恋愛運','color':0xFFFF6B9D,'bg':0x14FF6B9D,'border':0x33FF6B9D},
  {'id':'money','icon':'💰','nameJP':'金運','color':0xFFFFD370,'bg':0x14FFD370,'border':0x33FFD370},
  {'id':'career','icon':'💼','nameJP':'仕事運','color':0xFFFF8C42,'bg':0x14FF8C42,'border':0x33FF8C42},
  {'id':'communication','icon':'💬','nameJP':'対話運','color':0xFF6BB5FF,'bg':0x146BB5FF,'border':0x336BB5FF},
];

// HTML: ASPECT_TYPES — 日本語名・シンボル付き (L1162-1171)
const aspectNameJP = {
  'conjunction': 'コンジャンクション',
  'opposition': 'オポジション',
  'trine': 'トライン',
  'square': 'スクエア',
  'sextile': 'セクスタイル',
  'quincunx': 'クインカンクス',
  'semisextile': 'セミセクスタイル',
  'semisquare': 'セミスクエア',
};
const aspectSymbol = {
  'conjunction': '☌',
  'opposition': '☍',
  'trine': '△',
  'square': '□',
  'sextile': '⚹',
  'quincunx': 'Qx',
  'semisextile': '⚺',
  'semisquare': '∠',
};

final aspectTypes = [
  {'key':'conjunction','angle':0.0,'orb':2.0,'quality':'neutral','color':const Color(0xFF26D0CE),'minor':false},
  {'key':'opposition','angle':180.0,'orb':2.0,'quality':'hard','color':const Color(0xFF6B5CE7),'minor':false},
  {'key':'trine','angle':120.0,'orb':2.0,'quality':'soft','color':const Color(0xFFC9A84C),'minor':false},
  {'key':'square','angle':90.0,'orb':2.0,'quality':'hard','color':const Color(0xFF6B5CE7),'minor':false},
  {'key':'sextile','angle':60.0,'orb':2.0,'quality':'soft','color':const Color(0xFFC9A84C),'minor':false},
  {'key':'quincunx','angle':150.0,'orb':2.0,'quality':'neutral','color':const Color(0xFF26D0CE),'minor':false},
  {'key':'semisextile','angle':30.0,'orb':1.0,'quality':'soft','color':const Color(0xFF8BC34A),'minor':true},
  {'key':'semisquare','angle':45.0,'orb':1.0,'quality':'hard','color':const Color(0xFFFF7043),'minor':true},
];

// HTML: IDX_PLANET_GROUPS (L1132-1136) + getPlanetGroup(idx>=10) → 'angle'
const planetGroups = {
  'sun': 'personal', 'moon': 'personal', 'mercury': 'personal', 'venus': 'personal', 'mars': 'personal',
  'jupiter': 'social', 'saturn': 'social',
  'uranus': 'generational', 'neptune': 'generational', 'pluto': 'generational',
  'asc': 'angle', 'mc': 'angle', 'dsc': 'angle', 'ic': 'angle',
};

// Angle point glyphs and names
const angleGlyphs = {'asc': 'ASC', 'mc': 'MC', 'dsc': 'DSC', 'ic': 'IC'};
const angleNamesJP = {'asc': 'ASC', 'mc': 'MC', 'dsc': 'DSC', 'ic': 'IC'};

// HTML: PATTERN_ORB_SETTINGS
const patternOrbSettings = {
  'grandtrine': 3.0,
  'tsquare_opp': 3.0,
  'tsquare_sq': 2.5,
  'yod_sextile': 2.5,
  'yod_quincunx': 1.5,
};

// HTML: PATTERN_STYLES
const patternStyles = {
  'grandtrine': {'label': 'Grand Trine', 'labelJP': 'グランドトライン', 'color': 0xFFC9A84C},
  'tsquare': {'label': 'T-Square', 'labelJP': 'Tスクエア', 'color': 0xFF6B5CE7},
  'yod': {'label': 'Yod', 'labelJP': 'ヨッド', 'color': 0xFF26D0CE},
};

// HTML: IDX_FORTUNE_PLANETS (L1139-1145)
// ⚠️ UIフィルタ用 (Horo絞込チップ「癒し/金運/恋愛/仕事/対話」で使用)
// Fortune API (Gemini) 用のテーブルは utils/fortune_api.dart の fortuneApiPlanets (key='overall')
const fortunePlanets = {
  'healing': ['moon', 'neptune', 'jupiter'],
  'money': ['venus', 'jupiter', 'saturn'],
  'love': ['venus', 'mars', 'moon'],
  'career': ['saturn', 'venus', 'sun'],
  'communication': ['mercury', 'moon', 'jupiter'],
};
