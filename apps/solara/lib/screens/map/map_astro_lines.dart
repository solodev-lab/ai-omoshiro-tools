import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../theme/solara_colors.dart';
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

/// B1: アスペクト線の Soft/Hard エネルギー色。
/// Solara 設計思想 = 吉凶判定しない。square=Hard、trine/sextile=Soft の
/// 独立2エネルギーとして色分けする (赤緑の吉凶色にしない)。
Color _aspectEnergyColor(String aspect) => switch (aspect) {
      'square' => SolaraColors.energyHard,
      'trine' || 'sextile' => SolaraColors.energySoft,
      _ => SolaraColors.energySoft,
    };

/// アストロラインを Polyline[] に変換。
///
/// [activeCategory] は 'all' / 'love' / 'money' 等。
/// [allPlanetMode] が true なら category 連動を無視して全表示。
///
/// アスペクト線 (line.isAspectLine) は本線より細く・薄く・破線で描画し、
/// 色を Soft/Hard エネルギー色へ寄せる。表示 ON/OFF は呼出側 (_visibleAstroLines)
/// が制御するため、本関数は渡された線をすべて描画する。
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

    // B1: アスペクト線 (square/trine/sextile) は本線より控えめ。
    //   太さ細く・不透明度低め (本線が主役)、細かい破線で本線と区別、
    //   色は惑星色を Soft/Hard エネルギー色へ寄せる (吉凶判定しない)。
    final isAspect = line.isAspectLine;
    final weight = isAspect ? 1.3 : style.weight;
    final baseOpacity = isAspect ? style.opacity * 0.55 : style.opacity;
    final opacity = (isHighlighted ? baseOpacity : baseOpacity * _dimMultiplier) *
        frameStyle.opacityMul;

    // 本線: 惑星色をフレームaccentへ tint mix (Natal は tint=0)。
    // アスペクト線: さらに Soft/Hard エネルギー色へ寄せる。
    var base = _lerpColor(meta.color, frameStyle.accent, frameStyle.tintMix);
    if (isAspect) {
      base = _lerpColor(base, _aspectEnergyColor(line.aspect), 0.5);
    }
    final color = base.withAlpha((opacity * 255).round());

    final pattern = isAspect
        ? StrokePattern.dashed(segments: const [3.0, 4.0])
        : (style.dashPattern != null
            ? StrokePattern.dashed(segments: style.dashPattern!)
            : const StrokePattern.solid());

    for (final segment in line.segments) {
      if (segment.length < 2) continue;
      polylines.add(Polyline(
        points: segment,
        color: color,
        strokeWidth: weight,
        pattern: pattern,
      ));
    }
  }
  return polylines;
}

// ── L3 / Lewis: 天頂・天底緯度線 (Zenith/Nadir Latitude Bands) ──
// Lewis 理論では、天頂点・天底点は単独の1点ではなく、その緯度線全周に
// 惑星エネルギーを発動させるとされる (緯度効果)。
// 経度を問わず、同じ緯度の都市はすべて影響を受ける、という見立て。
// MapタイルがWebMercator上で緯度線は水平直線になるため、サンプル2点 (lng=-180/+180)
// で十分な精度の Polyline が引ける。

/// 緯度線の Polyline 点列を生成。
///
/// 経度 ±180 ぴったりは flutter_map の projection が破綻する場合があるため、
/// 端点は ±179.9 に内側化する。さらに -90/0/90 の中間点を挿入することで
/// 極端なズームでもクリッピング起因の NaN を防ぐ (中間点なしで端点だけだと
/// Mercator pixel bounds 計算で巨大数値を経由する)。
///
/// 2026-05-11 ACG モードズームアウト時の `LatLng(NaN, NaN)` 連発バグ対策。
List<LatLng> _latitudePolylinePoints(double lat) => [
      LatLng(lat, -179.9),
      LatLng(lat, -90),
      LatLng(lat, 0),
      LatLng(lat, 90),
      LatLng(lat, 179.9),
    ];

/// 天頂帯・天底帯 (latitude bands) の緯度線を Polyline[] に変換する。
///
/// 1本のラインから最大2本生成:
///   - [zenithFrames] にフレームが含まれ zenith!=null → 緯度=δ の実線 (惑星色)
///   - [nadirFrames]  にフレームが含まれ nadir!=null  → 緯度=-δ の点線 (惑星色を暗トーン化)
/// 線データを 1 度しか走査しない (PolylineLayer も 1 つで済む) ため zenith/nadir を
/// 分離した旧設計より効率的。
///
/// [activeCategory] FORTUNE 連動。非該当惑星の緯度線は dim。
/// [opacityBase] 緯度線のベース透明度 (default 0.22、視覚密度抑え目)。
List<Polyline> buildAstroLatitudeBandPolylines({
  required List<AstroLine> lines,
  required String activeCategory,
  bool allPlanetMode = false,
  Set<AstroFrame> zenithFrames = const {},
  Set<AstroFrame> nadirFrames = const {},
  double latLimit = 75,
  double opacityBase = 0.22,
}) {
  final highlightSet = (allPlanetMode || activeCategory == 'all')
      ? null
      : astroLineFortunePlanets[activeCategory];

  final polylines = <Polyline>[];
  for (final line in lines) {
    final showZenith = zenithFrames.contains(line.frame);
    final showNadir = nadirFrames.contains(line.frame);
    if (!showZenith && !showNadir) continue;
    final meta = planetMeta[line.planet];
    if (meta == null) continue;
    final frameStyle =
        astroFrameStyles[line.frame] ?? astroFrameStyles[AstroFrame.natal]!;
    final isHighlighted =
        highlightSet == null || highlightSet.contains(line.planet);
    final alphaMul =
        (isHighlighted ? 1.0 : _dimMultiplier) * frameStyle.opacityMul;

    if (showZenith) {
      final p = line.zenith;
      if (p != null && p.latitude.isFinite && p.latitude.abs() <= latLimit) {
        final tinted = _lerpColor(meta.color, frameStyle.accent, frameStyle.tintMix);
        polylines.add(Polyline(
          points: _latitudePolylinePoints(p.latitude),
          color: tinted.withAlpha((opacityBase * alphaMul * 255).round()),
          strokeWidth: 1.4,
        ));
      }
    }
    if (showNadir) {
      final p = line.nadir;
      if (p != null && p.latitude.isFinite && p.latitude.abs() <= latLimit) {
        final darkened = Color.from(
          alpha: 1.0,
          red: meta.color.r * 0.6,
          green: meta.color.g * 0.6,
          blue: meta.color.b * 0.6,
        );
        final tinted =
            _lerpColor(darkened, frameStyle.accent, frameStyle.tintMix * 0.6);
        polylines.add(Polyline(
          points: _latitudePolylinePoints(p.latitude),
          color: tinted.withAlpha((opacityBase * alphaMul * 0.85 * 255).round()),
          strokeWidth: 1.2,
          pattern: StrokePattern.dashed(segments: const [5, 6]),
        ));
      }
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
/// 呼出側は `_zenithMarkerFrames()` 等で ON 中のフレームを渡す (2 層メニュー連動)。
/// Lewis 理論的にはどのフレームの天頂も「同じ緯度線全周に効くポイント」として
/// 等価なので、natal だけでなく動的フレーム (T/P/SA) でも表示する設計。
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

// ── Astro*Carto*Graphy モード: 天底点 (Nadir Point) マーカー (L2) ──
// 各惑星の IC ライン上、緯度=-δ となる点 = 「真下に星がある土地」
// (= 地球を貫通すると裏側の天頂点に出る、対称ペア)。
// 占星術的意味:
//   IC ライン全体 = 家庭・大地・ルーツ方向で惑星が働く帯
//   天底点        = エネルギーが大地の核から逆流する「裏側ノズル」
// 緯度が -δ で描画範囲外(極地)になる場合は表示しない。

/// 各惑星の天底点 (= AstroLine.nadir) に装飾マーカーを生成。
/// IC line にのみ nadir が設定されるため自動的に1フレーム×1惑星=1マーカー。
/// FORTUNE 連動 dim 対象の惑星はマーカーも非表示(ノイズ削減)。
/// [onTap] が指定されていれば、タップで (planet, frame, nadir座標) を通知する。
/// [framesWithNadir] 天底マーカーを表示するフレーム集合。
List<Marker> buildAstroNadirMarkers({
  required List<AstroLine> lines,
  required String activeCategory,
  bool allPlanetMode = false,
  double latLimit = 75,
  void Function(String planetKey, AstroFrame frame, LatLng nadir)? onTap,
  Set<AstroFrame> framesWithNadir = const {AstroFrame.natal},
}) {
  final highlightSet = (allPlanetMode || activeCategory == 'all')
      ? null
      : astroLineFortunePlanets[activeCategory];

  final markers = <Marker>[];
  for (final line in lines) {
    if (!framesWithNadir.contains(line.frame)) continue;
    final nadir = line.nadir;
    if (nadir == null) continue; // IC 以外は nadir null
    if (nadir.latitude.abs() > latLimit) continue;

    final meta = planetMeta[line.planet];
    if (meta == null) continue;
    final isHighlighted = highlightSet == null || highlightSet.contains(line.planet);
    if (!isHighlighted) continue;

    final marker = AstroNadirMarker(
      planetSym: meta.sym,
      planetColor: meta.color,
      frame: line.frame,
    );
    final planetKey = line.planet;
    final frame = line.frame;
    final point = nadir;
    markers.add(Marker(
      point: nadir,
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

/// 装飾的な天底点マーカー (Lewis 理論: 裏側に在る天体)。
/// 天頂マーカーの暗いペア版として描画:
///   - 中心円が暗トーン (惑星色を 60% 暗くした色)
///   - リング色は frame accent (天頂と同じ) だが alpha を低めに
///   - ラベルは「天底 (N/T/P/SA)」
class AstroNadirMarker extends StatelessWidget {
  final String planetSym;
  final Color planetColor;
  final AstroFrame frame;

  const AstroNadirMarker({
    super.key,
    required this.planetSym,
    required this.planetColor,
    this.frame = AstroFrame.natal,
  });

  /// 惑星色を暗トーン化 (sRGB線形に 0.55 倍 → 大地の底のイメージ)
  Color get _darkenedPlanet => Color.from(
        alpha: 1.0,
        red: planetColor.r * 0.55,
        green: planetColor.g * 0.55,
        blue: planetColor.b * 0.55,
      );

  @override
  Widget build(BuildContext context) {
    final isNatal = frame == AstroFrame.natal;
    final frameStyle = astroFrameStyles[frame] ?? astroFrameStyles[AstroFrame.natal]!;
    // 天頂より控えめなリング (alpha 180/100 程度)
    final ringColor = isNatal ? const Color(0x99C9A84C) : frameStyle.accent.withAlpha(170);
    final innerRing = isNatal ? const Color(0x66C9A84C) : frameStyle.accent.withAlpha(100);
    final labelColor = isNatal ? const Color(0xFFA88A38) : frameStyle.accent.withAlpha(220);
    final labelText = switch (frame) {
      AstroFrame.natal => '天底 (N)',
      AstroFrame.transit => '天底 (T)',
      AstroFrame.progressed => '天底 (P)',
      AstroFrame.solarArc => '天底 (SA)',
    };
    final size = isNatal ? 28.0 : 22.0;
    final fontSize = isNatal ? 14.0 : 11.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ringColor, width: isNatal ? 1.1 : 0.9),
            // 天頂より弱いグロー (大地の底に沈む感)
            boxShadow: [
              BoxShadow(
                color: _darkenedPlanet.withAlpha(isNatal ? 120 : 90),
                blurRadius: 9,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Container(
            margin: EdgeInsets.all(isNatal ? 2.2 : 1.8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xE6080814), // 天頂より暗い背景
              border: Border.all(color: innerRing, width: 0.6),
            ),
            child: Center(
              child: Text(
                planetSym,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: _darkenedPlanet,
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
            color: const Color(0xCC080814),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: labelColor.withAlpha(80), width: 0.6),
          ),
          child: Text(
            labelText,
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              fontSize: 12,
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

/// 装飾的な天頂点マーカー (frame で見た目を切替):
///   Natal      : 32px、金色二重リング、「天頂 (N)」ラベル
///   Transit    : 24px、オレンジリング、「天頂 (T)」ラベル (毎日動く)
///   Progressed : 24px、緑リング、「天頂 (P)」ラベル
///   SolarArc   : 24px、紫リング、「天頂 (SA)」ラベル
///
/// 2026-05-11 ラベル統一: 全フレーム共通で「天頂」表記とし、括弧内のフレーム略号
/// (N/T/P/SA) で識別。Lewis 理論的にはどのフレームでも「真上に来る点」という
/// 同一概念なので「TRANS」「PROG」のように天頂であることを隠す表記は不適切。
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
    final labelText = switch (frame) {
      AstroFrame.natal => '天頂 (N)',
      AstroFrame.transit => '天頂 (T)',
      AstroFrame.progressed => '天頂 (P)',
      AstroFrame.solarArc => '天頂 (SA)',
    };
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
          // 2026-05-08: textScaler.noScaling で fontSize 13 固定。
          // 天頂マーカーラベルは地図上のオブジェクトとして固定サイズが望ましく、
          // 端末フォント拡大時にサイズが変わると周囲のラインや他マーカーとの
          // 視覚バランスが崩れるため。
          child: Text(
            labelText,
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              fontSize: 13,
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
