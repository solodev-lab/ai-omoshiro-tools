import 'package:flutter_map/flutter_map.dart';

import '../../utils/astro_lines.dart';
import 'map_constants.dart';

/// ============================================================
/// Map Astro Lines Renderer — Phase M2 論点3
///
/// buildAstroLines の結果 (40本) を flutter_map の Polyline 列に変換する。
///
/// アングル別の線スタイル:
///   ASC (上昇宮): 太め実線
///   MC  (天頂):   実線
///   DSC (下降宮): 細め点線
///   IC  (天底):   細め点線
///
/// FORTUNE カテゴリ連動 (論点6 4-B5):
///   activeCategory != 'all' のとき関連惑星 (love=Venus/Mars/Moon等) のみ100%、
///   他はdim (alpha=0.12)。
///
/// allPlanetMode == true なら活性化カテゴリ無視で全惑星100%表示 (ガチ勢用)。
/// ============================================================

class _AngleStyle {
  final double weight;
  final double opacity;
  final List<double>? dashPattern;
  final String labelSuffix; // ポップアップで使う

  const _AngleStyle({
    required this.weight,
    required this.opacity,
    required this.dashPattern,
    required this.labelSuffix,
  });
}

const _angleStyles = <String, _AngleStyle>{
  'asc': _AngleStyle(weight: 2.6, opacity: 0.85, dashPattern: null, labelSuffix: 'ASC'),
  'mc':  _AngleStyle(weight: 2.2, opacity: 0.80, dashPattern: null, labelSuffix: 'MC'),
  'dsc': _AngleStyle(weight: 1.6, opacity: 0.65, dashPattern: [6, 6], labelSuffix: 'DSC'),
  'ic':  _AngleStyle(weight: 1.6, opacity: 0.65, dashPattern: [4, 6], labelSuffix: 'IC'),
};

/// dim (非該当 FORTUNE 惑星のライン) の alpha 倍率
const double _dimMultiplier = 0.18;

/// アスペクトラインを Polyline[] に変換。
///
/// [activeCategory] は 'all' / 'love' / 'money' 等。
/// [allPlanetMode] が true なら category 連動を無視して全表示。
List<Polyline> buildAstroPolylines({
  required List<AstroLine> lines,
  required String activeCategory,
  bool allPlanetMode = false,
}) {
  final highlightSet = (allPlanetMode || activeCategory == 'all')
      ? null // null = 全部 100%
      : astroLineFortunePlanets[activeCategory];

  final polylines = <Polyline>[];
  for (final line in lines) {
    final style = _angleStyles[line.angle];
    if (style == null) continue;
    final meta = planetMeta[line.planet];
    if (meta == null) continue;

    final isHighlighted = highlightSet == null || highlightSet.contains(line.planet);
    final opacity = isHighlighted
        ? style.opacity
        : style.opacity * _dimMultiplier;
    final color = meta.color.withAlpha((opacity * 255).round());

    for (final segment in line.segments) {
      if (segment.length < 2) continue;
      polylines.add(Polyline(
        points: segment,
        color: color,
        strokeWidth: style.weight,
        pattern: style.dashPattern != null
            ? StrokePattern.dashed(segments: style.dashPattern!)
            : const StrokePattern.solid(),
      ));
    }
  }
  return polylines;
}
