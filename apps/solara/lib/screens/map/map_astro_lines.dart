import 'package:flutter/material.dart';
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

// ── Astro*Carto*Graphy モード: 天頂点 (Zenith Point) マーカー ──
// 各惑星のMCライン上、緯度=惑星赤緯δ となる唯一の点 = 「真上に星がある土地」。
// 理論上 1惑星=1天頂点(MC線上のみ)、計10個。
// 占星術的意味:
//   MCライン全体 = 社会的露出/評判の方向で惑星が強く働く帯
//   天頂点    = エネルギーがダイレクトに頭上から降る「シャワー直下」
// 緯度がδで描画範囲外(極地)になる場合は表示しない。

/// 各惑星の天頂点 (= AstroLine.zenith) に装飾マーカーを生成。
/// MC line にのみ zenith が設定されるため自動的に1惑星=1マーカーになる。
/// FORTUNE 連動 dim 対象の惑星はマーカーも非表示(ノイズ削減)。
/// [onTap] が指定されていれば、マーカータップで惑星キーを通知する。
List<Marker> buildAstroZenithMarkers({
  required List<AstroLine> lines,
  required String activeCategory,
  bool allPlanetMode = false,
  double latLimit = 75, // 描画緯度上限と揃える
  void Function(String planetKey)? onTap,
}) {
  final highlightSet = (allPlanetMode || activeCategory == 'all')
      ? null
      : astroLineFortunePlanets[activeCategory];

  final markers = <Marker>[];
  for (final line in lines) {
    final zenith = line.zenith;
    if (zenith == null) continue; // MC 以外は zenith null
    if (zenith.latitude.abs() > latLimit) continue; // 極地は表示外

    final meta = planetMeta[line.planet];
    if (meta == null) continue;
    final isHighlighted = highlightSet == null || highlightSet.contains(line.planet);
    if (!isHighlighted) continue;

    final marker = AstroZenithMarker(
      planetSym: meta.sym,
      planetColor: meta.color,
    );
    final planetKey = line.planet;
    markers.add(Marker(
      point: zenith,
      width: 56,
      height: 64,
      alignment: Alignment.center,
      child: onTap != null
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(planetKey),
              child: marker,
            )
          : marker,
    ));
  }
  return markers;
}

/// 装飾的な天頂点マーカー:
///   外側に惑星色のソフトグロー
///   金色二重リング(外1.2px + 内0.6px)
///   中央に惑星記号(惑星色)
///   下部に「天頂」小ラベル
class AstroZenithMarker extends StatelessWidget {
  final String planetSym;
  final Color planetColor;

  const AstroZenithMarker({
    super.key,
    required this.planetSym,
    required this.planetColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 装飾的な二重リング + グロー
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xCCC9A84C), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: planetColor.withAlpha(160),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xE60C0C1A),
              border: Border.all(color: const Color(0x88C9A84C), width: 0.6),
            ),
            child: Center(
              child: Text(
                planetSym,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: planetColor,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: const Color(0xCC0C0C1A),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: const Color(0x66C9A84C), width: 0.6),
          ),
          child: const Text(
            '天頂',
            style: TextStyle(
              fontSize: 8,
              color: Color(0xFFC9A84C),
              letterSpacing: 1.5,
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}
