import 'package:flutter/material.dart';

/// 16方位の方位名
const dir16 = ['N','NNE','NE','ENE','E','ESE','SE','SSE',
               'S','SSW','SW','WSW','W','WNW','NW','NNW'];

/// 16方位の日本語名
const dir16JP = <String,String>{
  'N':'北','NNE':'北北東','NE':'北東','ENE':'東北東',
  'E':'東','ESE':'東南東','SE':'南東','SSE':'南南東',
  'S':'南','SSW':'南南西','SW':'南西','WSW':'西南西',
  'W':'西','WNW':'西北西','NW':'北西','NNW':'北北西',
};

/// HTML: fp-item --pc colors
const categoryColors = <String, Color>{
  'all': Color(0xFFE8E0D0), 'healing': Color(0xFF64C8B4), 'money': Color(0xFFF5D76E),
  'love': Color(0xFFFF88B4), 'work': Color(0xFF6BB5FF), 'communication': Color(0xFFB088FF),
};

/// カテゴリ日本語ラベル
/// 「金運」は設計思想（吉凶判定回避）に基づき「豊かさ」に変更（2026-04-29）。
const categoryLabels = <String, String>{
  'all':'総合','healing':'癒し','money':'豊かさ','love':'恋愛','work':'仕事','communication':'話す',
};

/// 4成分カラー（Solara 設計思想: ソフト=銀月色、ハード=金陽色）
/// 旧色 (赤紫の T剛/P剛) は吉凶判定的だったため2026-04-29に書き換え。
/// T (Transit) と P (Progressed) は同色相の明度違いで区別。
/// 関連: project_solara_design_philosophy.md
const compColors = <String, Color>{
  'tSoft': Color(0xFFC8D4E8), // ソフト・トランジット（銀月色 明）
  'tHard': Color(0xFFD6915C), // ハード・トランジット（金陽色 明）
  'pSoft': Color(0xFF8A9CB8), // ソフト・プログレス（銀月色 暗）
  'pHard': Color(0xFFA56838), // ハード・プログレス（金陽色 暗）
};
const compKeys = ['tSoft', 'tHard', 'pSoft', 'pHard'];

/// ソースタブラベル
const srcLabels = <String, String>{'combined':'合計','transit':'トランジット','progressed':'プログレス'};

/// HTML: CHART_STYLE — natal/progressed/transit の線スタイル
class ChartLineStyle {
  final Color color;
  final double weight;
  final double opacity;
  final List<double>? dashPattern;
  final Color bg;
  final Color fg;

  const ChartLineStyle({
    required this.color, required this.weight, required this.opacity,
    this.dashPattern, required this.bg, required this.fg,
  });
}

// Horoscope 画面と色を統一:
// - natal: gold 0xFFFFD370
// - progressed: purple 0xFFB088FF
// - transit: light blue 0xFF6BB5FF
// 線の太さ/不透明度/破線パターンは大圏線が画面上で混雑しないよう従来値を維持。
const chartStyles = <String, ChartLineStyle>{
  'natal': ChartLineStyle(
    color: Color(0xFFFFD370), weight: 2, opacity: 0.5, dashPattern: null,
    bg: Color(0xD9FFD370), fg: Color(0xFF1A0A30),
  ),
  'progressed': ChartLineStyle(
    color: Color(0xFFB088FF), weight: 1.8, opacity: 0.45, dashPattern: [8, 6],
    bg: Color(0xD9B088FF), fg: Color(0xFF1A0A30),
  ),
  'transit': ChartLineStyle(
    color: Color(0xFF6BB5FF), weight: 1.8, opacity: 0.45, dashPattern: [3, 6],
    bg: Color(0xD96BB5FF), fg: Color(0xFF1A0A30),
  ),
};

/// HTML: TAROT.planets — 惑星シンボルと色
class PlanetMeta {
  final String sym;
  final String jp;
  final Color color;
  const PlanetMeta(this.sym, this.jp, this.color);
}

// `sym` は仕様参照用（Map のマーカー描画は Horo と同じ PlanetVectorIcon の
// ベクターグリフを使用するため OS フォント依存なし — Venus/Mars が
// 絵文字化されない）。
const planetMeta = <String, PlanetMeta>{
  'sun':     PlanetMeta('☉', '太陽',   Color(0xFFFFD700)),
  'moon':    PlanetMeta('☽', '月',     Color(0xFFC0C0C0)),
  'mercury': PlanetMeta('☿', '水星',   Color(0xFF87CEEB)),
  'venus':   PlanetMeta('♀', '金星',   Color(0xFFFF69B4)),
  'mars':    PlanetMeta('♂', '火星',   Color(0xFFFF4500)),
  'jupiter': PlanetMeta('♃', '木星',   Color(0xFFFFA500)),
  'saturn':  PlanetMeta('♄', '土星',   Color(0xFF808080)),
  'uranus':  PlanetMeta('♅', '天王星', Color(0xFF00CED1)),
  'neptune': PlanetMeta('♆', '海王星', Color(0xFF4169E1)),
  'pluto':   PlanetMeta('♇', '冥王星', Color(0xFF8B0000)),
};

/// HTML: PLANET_GROUPS — personal/social/generational
const planetGroups = <String, List<String>>{
  'personal':     ['sun', 'moon', 'mercury', 'venus', 'mars'],
  'social':       ['jupiter', 'saturn'],
  'generational': ['uranus', 'neptune', 'pluto'],
};

/// HTML: FORTUNE_PLANETS — カテゴリ別関連惑星
const fortunePlanets = <String, List<String>>{
  'healing':       ['moon', 'neptune', 'venus'],
  'money':         ['jupiter', 'venus', 'sun'],
  'love':          ['venus', 'mars', 'moon'],
  'work':          ['saturn', 'sun', 'mars', 'jupiter'],
  'communication': ['mercury', 'sun', 'venus'],
};
