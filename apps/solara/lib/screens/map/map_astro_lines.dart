import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../utils/astro_lines.dart';
import 'map_constants.dart';

/// ============================================================
/// Map Astro Lines Renderer — Phase M2 論点3 + Tier A #5 (CCG)
///
/// buildAstroLines / buildAstroLinesAt の結果を flutter_map の Polyline 列に変換する。
///
/// アングル別の線スタイル:
///   ASC (上昇宮): 太め実線
///   MC  (天頂):   実線
///   DSC (下降宮): 細め点線
///   IC  (天底):   細め点線
///
/// フレーム別のスタイル (Tier A #5):
///   Natal (出生時固定):   原色、opacity 100%
///   Transit (今この瞬間): 暖色寄りに +25% tint、opacity 85%
///   Progressed (2次進行): 緑系に +25% tint、opacity 70%
///   SolarArc (ソーラーアーク): 紫系に +25% tint、opacity 55%
///
/// FORTUNE カテゴリ連動 (論点6 4-B5):
///   activeCategory != 'all' のとき関連惑星 (love=Venus/Mars/Moon等) のみ100%、
///   他はdim (alpha=0.18)。
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

/// フレーム別の視覚プリセット。Tier A #5 で4フレーム同時描画する際の
/// 識別用 (色味/不透明度)。
class AstroFrameStyle {
  /// このフレームの代表色 (LayerPanel/Pill UI で使う)
  final Color accent;
  /// 線色に対するtint混合度 (0=色変えない、1=accentに完全置換)
  final double tintMix;
  /// 全線に乗せる不透明度倍率
  final double opacityMul;
  /// UI 表示ラベル
  final String label;

  const AstroFrameStyle({
    required this.accent,
    required this.tintMix,
    required this.opacityMul,
    required this.label,
  });
}

const Map<AstroFrame, AstroFrameStyle> astroFrameStyles = {
  AstroFrame.natal: AstroFrameStyle(
    accent: Color(0xFFE9D29A), // 既存ゴールド (アイコン色と統一)
    tintMix: 0.0,
    opacityMul: 1.0,
    label: 'Natal',
  ),
  AstroFrame.transit: AstroFrameStyle(
    accent: Color(0xFFFF8E5C), // 暖色オレンジ系
    tintMix: 0.28,
    opacityMul: 0.88,
    label: 'Transit',
  ),
  AstroFrame.progressed: AstroFrameStyle(
    accent: Color(0xFF63D6A0), // 緑/ターコイズ
    tintMix: 0.30,
    opacityMul: 0.72,
    label: 'Progressed',
  ),
  AstroFrame.solarArc: AstroFrameStyle(
    accent: Color(0xFFB07CFF), // 紫
    tintMix: 0.32,
    opacityMul: 0.62,
    label: 'Solar Arc',
  ),
};

/// 2色を線形補間 (sRGB空間)。Flutter 3.27+ の新Color API (.r/.g/.b/.a, double 0..1) 対応。
Color _lerpColor(Color a, Color b, double t) {
  if (t <= 0) return a;
  if (t >= 1) return b;
  return Color.from(
    alpha: a.a,
    red: a.r + (b.r - a.r) * t,
    green: a.g + (b.g - a.g) * t,
    blue: a.b + (b.b - a.b) * t,
  );
}

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
    final frameStyle = astroFrameStyles[line.frame] ?? astroFrameStyles[AstroFrame.natal]!;

    final isHighlighted = highlightSet == null || highlightSet.contains(line.planet);
    final opacity = (isHighlighted
            ? style.opacity
            : style.opacity * _dimMultiplier) *
        frameStyle.opacityMul;
    // 惑星色をフレームaccentに向けて tint mix → 識別性UP (Natal は tint=0)
    final tinted = _lerpColor(meta.color, frameStyle.accent, frameStyle.tintMix);
    final color = tinted.withAlpha((opacity * 255).round());

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
/// MC line にのみ zenith が設定されるため自動的に1フレーム×1惑星=1マーカー。
/// FORTUNE 連動 dim 対象の惑星はマーカーも非表示(ノイズ削減)。
/// [onTap] が指定されていれば、タップで (planet, frame, zenith座標) を通知する。
/// [framesWithZenith] 天頂マーカーを表示するフレーム集合 (default: natal のみ)。
/// 4フレーム全部表示すると最大40個になるが、CCG では「惑星が今どこを真上に
/// 通っているか」が主役なので動的フレームの zenith こそ重要 (時間で動く)。
List<Marker> buildAstroZenithMarkers({
  required List<AstroLine> lines,
  required String activeCategory,
  bool allPlanetMode = false,
  double latLimit = 75, // 描画緯度上限と揃える
  void Function(String planetKey, AstroFrame frame, LatLng zenith)? onTap,
  Set<AstroFrame> framesWithZenith = const {AstroFrame.natal},
}) {
  final highlightSet = (allPlanetMode || activeCategory == 'all')
      ? null
      : astroLineFortunePlanets[activeCategory];

  final markers = <Marker>[];
  for (final line in lines) {
    if (!framesWithZenith.contains(line.frame)) continue;
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
      frame: line.frame,
    );
    final planetKey = line.planet;
    final frame = line.frame;
    final point = zenith;
    markers.add(Marker(
      point: zenith,
      width: 56,
      height: 64,
      alignment: Alignment.center,
      child: onTap != null
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(planetKey, frame, point),
              child: marker,
            )
          : marker,
    ));
  }
  return markers;
}

/// 装飾的な天頂点マーカー (frame で見た目を切替):
///   Natal      : 32px、金色二重リング、「天頂」ラベル
///   Transit    : 24px、オレンジリング、「TRANSIT」ラベル (毎日動く)
///   Progressed : 24px、緑リング、「PROG」ラベル
///   SolarArc   : 24px、紫リング、「S.ARC」ラベル
class AstroZenithMarker extends StatelessWidget {
  final String planetSym;
  final Color planetColor;
  final AstroFrame frame;

  const AstroZenithMarker({
    super.key,
    required this.planetSym,
    required this.planetColor,
    this.frame = AstroFrame.natal,
  });

  @override
  Widget build(BuildContext context) {
    final isNatal = frame == AstroFrame.natal;
    final frameStyle = astroFrameStyles[frame] ?? astroFrameStyles[AstroFrame.natal]!;
    // ring色 = natal はゴールド、それ以外は frame accent
    final ringColor = isNatal ? const Color(0xCCC9A84C) : frameStyle.accent.withAlpha(220);
    final innerRing = isNatal ? const Color(0x88C9A84C) : frameStyle.accent.withAlpha(140);
    final labelColor = isNatal ? const Color(0xFFC9A84C) : frameStyle.accent;
    final labelText = isNatal
        ? '天頂'
        : (frame == AstroFrame.transit
            ? 'TRANS'
            : frame == AstroFrame.progressed
                ? 'PROG'
                : 'S.ARC');
    final size = isNatal ? 32.0 : 24.0;
    final fontSize = isNatal ? 15.0 : 12.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ringColor, width: isNatal ? 1.2 : 1.0),
            boxShadow: [
              // 2026-05-03: blur/spread を固定値化 (ACG 画面点滅対策)。
              // 三項演算子で marker 毎に異なる値だと saveLayer 多発。
              BoxShadow(
                color: planetColor.withAlpha(isNatal ? 160 : 120),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Container(
            margin: EdgeInsets.all(isNatal ? 2.5 : 2.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xE60C0C1A),
              border: Border.all(color: innerRing, width: 0.6),
            ),
            child: Center(
              child: Text(
                planetSym,
                style: TextStyle(
                  fontSize: fontSize,
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
            border: Border.all(color: labelColor.withAlpha(102), width: 0.6),
          ),
          child: Text(
            labelText,
            style: TextStyle(
              fontSize: 7.5,
              color: labelColor,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}
