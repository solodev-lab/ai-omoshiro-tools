import 'dart:math';
import 'dart:ui' show Offset;

import 'package:latlong2/latlong.dart';

/// ============================================================
/// Solara Astro Lines — Phase M2 論点3 (アスペクト線 / アストロカートグラフィ)
///
/// 各惑星 × 4アングル (MC/IC/ASC/DSC) = 40本のラインを地球曲面上に計算する。
///
/// アストロカートグラフィ (Jim Lewis, 1970年代) の標準実装:
///   - MC line: その惑星が天頂 (子午線通過) する地点。経度固定の縦直線。
///   - IC line: MC line の反対側 (経度 180° シフト)。
///   - ASC line: その惑星が東の地平線に昇る地点。曲線。
///   - DSC line: 西の地平線に沈む地点。曲線。
///
/// 入力:
///   natal 10惑星の黄経 (chart.natal)
///   baselineMc / baselineLng (chart.mc + chart fetch時の lng)
///     ↑ ここから GMST と惑星赤道座標が逆算可能
///
/// 出力:
///   `List<AstroLine>`: 40本 (惑星10 × 4アングル)
///     各 line.points は地球曲面上の経度緯度サンプル列
///
/// 設計: project_solara_astrocartography_m2.md 論点3 (M2 に含める 確定)
/// ============================================================

const double _obliquityDeg = 23.4393; // J2000 平均値、astro_houses.dart と統一
const _planetKeys = [
  'sun', 'moon', 'mercury', 'venus', 'mars',
  'jupiter', 'saturn', 'uranus', 'neptune', 'pluto',
];
const angleKeys = ['mc', 'ic', 'asc', 'dsc'];

/// アストロカートグラフィの惑星フレーム (Tier A #5 / CCG)。
/// natal: 出生時の惑星 (固定)。Jim Lewis 1976 の A*C*G。
/// transit: 任意UTC時の天体位置 (動的)。CCG = Cyclo*Carto*Graphy。
/// progressed: 2次進行 (1日=1年)。Worker 計算済み。
/// solarArc: ソーラーアーク方向、natal[p] + (prog.sun - natal.sun)。
enum AstroFrame { natal, transit, progressed, solarArc }

String astroFrameKey(AstroFrame f) => switch (f) {
      AstroFrame.natal => 'natal',
      AstroFrame.transit => 'transit',
      AstroFrame.progressed => 'progressed',
      AstroFrame.solarArc => 'solarArc',
    };

double _toRad(double d) => d * pi / 180;
double _toDeg(double r) => r * 180 / pi;
double _norm360(double d) {
  d = d % 360;
  return d < 0 ? d + 360 : d;
}

/// 経度を -180..180 に正規化 (flutter_map の LatLng 用)
double _normLng(double d) {
  d = ((d + 180) % 360 + 360) % 360 - 180;
  return d;
}

double _clamp(double v, double lo, double hi) =>
    v < lo ? lo : (v > hi ? hi : v);

/// アストロカートグラフィの 1 本のライン。
class AstroLine {
  final String planet; // 'sun' | 'moon' | ...
  final String angle;  // 'mc' | 'ic' | 'asc' | 'dsc'
  final AstroFrame frame; // natal | transit | progressed | solarArc
  final List<List<LatLng>> segments; // 子午線跨ぎで区切ったセグメント

  /// 天頂点 (zenith point) の地点情報。
  /// MC ライン上で 緯度 = 惑星赤緯 δ となる唯一の地点。
  /// 物理的に「惑星が真上(高度90°)に来る」場所。
  /// Astro*Carto*Graphy モードでマーカー描画に使う。
  /// MC line のみ非null。他の angle (ic/asc/dsc) では null。
  final LatLng? zenith;

  AstroLine({
    required this.planet,
    required this.angle,
    required this.segments,
    this.frame = AstroFrame.natal,
    this.zenith,
  });

  /// 線のキー (UI から参照しやすいように) "natal_venus_asc" 等
  String get key => '${astroFrameKey(frame)}_${planet}_$angle';
}

/// chart.mc + chart fetch時の lng から GMST_hours を逆算。
/// LST_baseline = recover(MC), GMST_hours = (LST_baseline - baselineLng) / 15
double _gmstHoursFromBaseline(double baselineMc, double baselineLng) {
  final mcR = _toRad(baselineMc);
  final cosEps = cos(_toRad(_obliquityDeg));
  final lstBase = _norm360(_toDeg(atan2(sin(mcR) * cosEps, cos(mcR))));
  // GMST は時単位、LST は度単位
  return ((lstBase - baselineLng) / 15) % 24;
}

/// 任意UTC時刻から GMST (時間, 0..24) を計算。Tier A #5 / CCG 用。
///
/// 標準公式 (USNO Astronomical Almanac, Meeus):
///   JD_UTC = 2440587.5 + ms_since_epoch / 86400000
///   d = JD_UTC - 2451545.0
///   GMST = 18.697374558 + 24.06570982441908 * d  (時間)
///
/// ±50年で誤差 <0.05秒。Solara の線描画 (1°オーダー) に対し十分。
/// Worker calcGMST と同じアルゴリズム (worker/src/astro.js)。
double gmstHoursFromUtc(DateTime utc) {
  final u = utc.toUtc();
  final jd = u.millisecondsSinceEpoch / 86400000.0 + 2440587.5;
  final d = jd - 2451545.0;
  final g = 18.697374558 + 24.06570982441908 * d;
  return ((g % 24) + 24) % 24;
}

/// natal + progressed から Solar Arc (ソーラーアーク方向) の惑星位置を導出。
/// 全惑星に同じ arc (= prog.sun - natal.sun) を加算する古典的計算法。
/// CCG Tier A #5 用、Worker 側で計算しないためクライアント側で生成。
Map<String, double> solarArcPlanets({
  required Map<String, double> natal,
  required Map<String, double> progressed,
}) {
  final natalSun = natal['sun'];
  final progSun = progressed['sun'];
  if (natalSun == null || progSun == null) return const {};
  // 弧は順方向 (時間進行方向) なので 0..360° に正規化
  final arc = ((progSun - natalSun) % 360 + 360) % 360;
  final result = <String, double>{};
  for (final entry in natal.entries) {
    result[entry.key] = (entry.value + arc) % 360;
  }
  return result;
}

/// 黄経 (β=0 仮定) → 赤道座標 (RA, Dec)
({double ra, double dec}) _eclipticToEquatorial(double lambdaDeg) {
  final lR = _toRad(lambdaDeg);
  final eR = _toRad(_obliquityDeg);
  // 標準公式 (β=0 簡略化):
  //   sin(δ) = sin(ε)·sin(λ)
  //   cos(α)·cos(δ) = cos(λ),  sin(α)·cos(δ) = cos(ε)·sin(λ)
  final dec = asin(sin(eR) * sin(lR));
  final ra = atan2(cos(eR) * sin(lR), cos(lR));
  return (ra: _norm360(_toDeg(ra)), dec: _toDeg(dec));
}

/// MC ライン: lng_obs = α - GMST*15、緯度範囲全体で縦線
/// IC ライン: lng_obs = α - GMST*15 + 180、同上
/// 戻り: -75..75 度緯度範囲を端点 2 点だけで結ぶセグメント。
///
/// 2026-05-01 (K-2):
///   子午線は経度固定なので Web Mercator 投影上は完全な縦直線。
///   旧版は 5度刻みで 31 点をサンプリングしていたが、これらは画面上で
///   完全に同一直線上に並ぶため GPU の path 頂点を無駄に増やすだけだった。
///   端点 2 点だけに削減 (1 line あたり頂点 31 → 2、約 -94%) しても
///   視覚は完全に同一。Adreno 系で path op 数が減り fd 枯渇耐性が向上。
List<List<LatLng>> _meridianLine(double raDeg, double gmstHours,
    {required bool antiMeridian, double latMin = -75, double latMax = 75}) {
  double lng = raDeg - gmstHours * 15;
  if (antiMeridian) lng += 180;
  lng = _normLng(lng);
  return [
    [LatLng(latMin, lng), LatLng(latMax, lng)],
  ];
}

/// ASC ライン: 惑星が東の地平線にある地点 = 高度 h=0 かつ 方位は東半球
/// 公式: cos(H) = -tan(δ)·tan(φ), H は時角 (LST - α)
///   - 解が存在: |tan(δ)·tan(φ)| ≤ 1
///   - 解 H: 2つあり、ASC は -π..0 (東半球)、DSC は 0..π (西半球)
/// 緯度を 1〜2度刻みでスキャン → 各 lat で対応する lng を計算
/// 子午線跨ぎ (lng が +180→-180 を跨ぐ) で segments に分割
List<List<LatLng>> _horizonLine({
  required double raDeg,
  required double decDeg,
  required double gmstHours,
  required bool ascending, // true=ASC (東), false=DSC (西)
  double latMin = -75,
  double latMax = 75,
  // 2026-05-01 (K-2): 2.0 → 5.0 に粗化。ACG モードは世界規模ビュー
  // (zoom 2.5) 想定で、5度刻みでも画面上の角張りはほぼ知覚不能。
  // GPU path 頂点を約 60% 削減し Adreno 系の fd 枯渇耐性を改善する。
  double latStep = 5.0,
}) {
  final raR = _toRad(raDeg);
  final decR = _toRad(decDeg);
  final tanDec = tan(decR);
  final segments = <List<LatLng>>[];
  var current = <LatLng>[];
  double? prevLng;

  for (double lat = latMin; lat <= latMax + 0.01; lat += latStep) {
    final tanLat = tan(_toRad(lat));
    final cosH = -tanDec * tanLat;
    if (cosH < -1 || cosH > 1) {
      // この緯度では惑星が地平線を横切らない (周極) → セグメント終了
      if (current.length >= 2) segments.add(current);
      current = <LatLng>[];
      prevLng = null;
      continue;
    }
    final h = acos(_clamp(cosH, -1, 1)); // 0..π
    // ASC: 時角 H = -h (天体が地平線を昇るのは LST < α 側)
    // DSC: 時角 H = +h
    final hSigned = ascending ? -h : h;
    final lstR = raR + hSigned;
    final lst = _norm360(_toDeg(lstR));
    double lng = lst - gmstHours * 15;
    lng = _normLng(lng);

    // 子午線跨ぎ判定 (前 lng と差 >180 ならラップ)
    if (prevLng != null && (lng - prevLng).abs() > 180) {
      if (current.length >= 2) segments.add(current);
      current = <LatLng>[];
    }
    current.add(LatLng(lat, lng));
    prevLng = lng;
  }
  if (current.length >= 2) segments.add(current);
  return segments;
}

/// 全 40本のアストロラインを計算 (natal フレーム)。
///
/// [natal] は 10惑星の黄経 (度)。
/// [baselineMc] / [baselineLng] は chart fetch時の MC と地点経度
/// (relocate設定時は relocated MC と home lng、未設定なら birth)。
/// [latRange] は描画緯度範囲 (デフォルト -75..75 度)。
/// [latStep] はホライズン線のサンプリング間隔 (度、デフォルト2)。
///
/// 内部で GMST を baseline から逆算して [buildAstroLinesAt] に委譲する。
/// 後方互換 API: 既存の natal-only 呼出はこのまま動く。
List<AstroLine> buildAstroLines({
  required Map<String, double> natal,
  required double baselineMc,
  required double baselineLng,
  double latMin = -75,
  double latMax = 75,
  // 2026-05-01 (K-2): _horizonLine と同期。2.0 → 5.0
  double latStep = 5.0,
}) {
  final gmst = _gmstHoursFromBaseline(baselineMc, baselineLng);
  return buildAstroLinesAt(
    planets: natal,
    gmstHours: gmst,
    frame: AstroFrame.natal,
    latMin: latMin,
    latMax: latMax,
    latStep: latStep,
  );
}

/// 任意フレーム × 任意 GMST のアスペクト線 40本を計算 (Tier A #5 / CCG 汎用)。
///
/// [planets]   フレームに対応する10惑星の黄経マップ
///   - natal:      chart.natal (出生時の固定値)
///   - transit:    chart.transit (任意UTC時の動的値、Worker から取得)
///   - progressed: chart.progressed (2次進行、Worker から取得)
///   - solarArc:   solarArcPlanets(natal, progressed) の戻り
/// [gmstHours] そのフレームの GMST (時間, 0..24)
///   - natal:      _gmstHoursFromBaseline(chart.mc, baselineLng) ※buildAstroLines 経由
///   - dynamic:    gmstHoursFromUtc(viewDate.toUtc())
/// [frame]     線の所属フレーム。AstroLine.frame に設定され UI 側で色分けに使う。
List<AstroLine> buildAstroLinesAt({
  required Map<String, double> planets,
  required double gmstHours,
  required AstroFrame frame,
  double latMin = -75,
  double latMax = 75,
  // 2026-05-01 (K-2): _horizonLine と同期。2.0 → 5.0
  double latStep = 5.0,
}) {
  final lines = <AstroLine>[];

  for (final planet in _planetKeys) {
    final lon = planets[planet];
    if (lon == null) continue;
    final coord = _eclipticToEquatorial(lon);

    // MC line + zenith point
    // zenith: 緯度=惑星赤緯δ、経度=MC line の固定経度
    // δ が描画緯度範囲外でも理論値として保持(マーカー表示時にクランプ判定)。
    final mcLng = _normLng(coord.ra - gmstHours * 15);
    lines.add(AstroLine(
      planet: planet,
      angle: 'mc',
      frame: frame,
      segments: _meridianLine(coord.ra, gmstHours,
          antiMeridian: false, latMin: latMin, latMax: latMax),
      zenith: LatLng(coord.dec, mcLng),
    ));
    // IC line
    lines.add(AstroLine(
      planet: planet,
      angle: 'ic',
      frame: frame,
      segments: _meridianLine(coord.ra, gmstHours,
          antiMeridian: true, latMin: latMin, latMax: latMax),
    ));
    // ASC line
    lines.add(AstroLine(
      planet: planet,
      angle: 'asc',
      frame: frame,
      segments: _horizonLine(
        raDeg: coord.ra,
        decDeg: coord.dec,
        gmstHours: gmstHours,
        ascending: true,
        latMin: latMin,
        latMax: latMax,
        latStep: latStep,
      ),
    ));
    // DSC line
    lines.add(AstroLine(
      planet: planet,
      angle: 'dsc',
      frame: frame,
      segments: _horizonLine(
        raDeg: coord.ra,
        decDeg: coord.dec,
        gmstHours: gmstHours,
        ascending: false,
        latMin: latMin,
        latMax: latMax,
        latStep: latStep,
      ),
    ));
  }
  return lines;
}

/// FORTUNE カテゴリ → ハイライト対象の惑星セット
/// 設計: project_solara_astrocartography_m2.md 論点6 (4-B5)
const Map<String, Set<String>> astroLineFortunePlanets = {
  'all': {
    'sun', 'moon', 'mercury', 'venus', 'mars',
    'jupiter', 'saturn', 'uranus', 'neptune', 'pluto',
  },
  'love': {'venus', 'mars', 'moon'},
  'money': {'jupiter', 'venus', 'sun'},
  'work': {'saturn', 'mars', 'jupiter', 'sun'},
  'communication': {'mercury', 'venus', 'moon'},
  'healing': {'moon', 'neptune', 'venus'},
};

// ── 論点10 統合 popup 用: 近接線の検出 ──

/// タップ地点と AstroLine の各セグメント点との最小 Haversine 距離 (km)。
double _haversineKm(LatLng a, LatLng b) {
  const R = 6371.0;
  final lat1 = _toRad(a.latitude);
  final lat2 = _toRad(b.latitude);
  final dLat = lat2 - lat1;
  final dLng = _toRad(b.longitude - a.longitude);
  final h = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
  return 2 * R * asin(min(1.0, sqrt(h)));
}

/// 1本のラインの全セグメント点とタップ地点の最小距離 (km)。
double _minDistanceKmToLine(LatLng tap, AstroLine line) {
  double minDist = double.infinity;
  for (final seg in line.segments) {
    for (final pt in seg) {
      final d = _haversineKm(tap, pt);
      if (d < minDist) minDist = d;
    }
  }
  return minDist;
}

/// 近接ラインの結果。距離付き。
class NearbyAstroLine {
  final AstroLine line;
  final double distanceKm;
  const NearbyAstroLine(this.line, this.distanceKm);
}

// ── Tier A #3: 画面pixel距離による線タップ判定 ──
//
// km固定閾値はズームに比例して破綻する:
//   zoom 2.5 (世界): 200km ≈ 7px  → タイトすぎ
//   zoom 14  (街)  : 200km ≈ 21,000px → 緩すぎ
// flutter_map の latLngToScreenOffset を projector として渡し、画面pixel距離で
// 点-線分距離を測ることで全ズームで一貫した「線にタップした」感覚を提供する。
//
// 子午線跨ぎ対策: セグメント内の隣接2点が画面幅以上離れている場合、その線分は
// 反対側へラップした見えない接続なので距離計算をスキップする (maxJumpPx = 4096)。
//
// 戻り値の distanceKm は表示用 (Haversine で別計算)。並び順は pixel 距離の昇順。

/// 点 p から線分 (a, b) への最短距離 (px)。
double _pointToSegmentPx(Offset p, Offset a, Offset b) {
  final dx = b.dx - a.dx;
  final dy = b.dy - a.dy;
  final lenSq = dx * dx + dy * dy;
  if (lenSq < 1e-9) {
    final ex = p.dx - a.dx;
    final ey = p.dy - a.dy;
    return sqrt(ex * ex + ey * ey);
  }
  double t = ((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) / lenSq;
  if (t < 0) t = 0;
  if (t > 1) t = 1;
  final cx = a.dx + t * dx;
  final cy = a.dy + t * dy;
  final ex = p.dx - cx;
  final ey = p.dy - cy;
  return sqrt(ex * ex + ey * ey);
}

/// 1本のラインの全セグメントとタップ位置 [tapPx] の最短pixel距離。
/// 隣接2点が [maxJumpPx] 以上離れた線分は (子午線跨ぎ等で見た目に繋がっていないため) 無視。
double _minPixelDistanceToLine({
  required Offset tapPx,
  required AstroLine line,
  required Offset Function(LatLng) project,
  double maxJumpPx = 4096,
}) {
  double minDist = double.infinity;
  for (final seg in line.segments) {
    if (seg.length < 2) continue;
    Offset prev = project(seg[0]);
    for (int i = 1; i < seg.length; i++) {
      final next = project(seg[i]);
      final jx = next.dx - prev.dx;
      final jy = next.dy - prev.dy;
      if (jx * jx + jy * jy < maxJumpPx * maxJumpPx) {
        final d = _pointToSegmentPx(tapPx, prev, next);
        if (d < minDist) minDist = d;
      }
      prev = next;
    }
  }
  return minDist;
}

class _RankedLine {
  final AstroLine line;
  final double distanceKm;
  final double distancePx;
  _RankedLine(this.line, this.distanceKm, this.distancePx);
}

/// 画面pixel距離で近接アスペクト線を検出する (Astro*Carto*Graphy モード専用)。
///
/// [tapPx]      タップの画面座標 (Map widget 基準)
/// [tapLatLng]  タップの地理座標 (distanceKm 表示用)
/// [project]    LatLng → Offset 投影関数 (通常 `camera.latLngToScreenOffset`)
/// [thresholdPx] この pixel 距離以内の線のみ採用 (default 20px)
///
/// 戻りは pixel 距離の昇順 (視覚的に最も近い線が先頭)。
/// `NearbyAstroLine.distanceKm` は Haversine 距離 (表示用、フィルタには使わない)。
List<NearbyAstroLine> findNearbyLinesScreen({
  required Offset tapPx,
  required LatLng tapLatLng,
  required List<AstroLine> lines,
  required Offset Function(LatLng) project,
  double thresholdPx = 20,
}) {
  final ranked = <_RankedLine>[];
  for (final line in lines) {
    final dPx = _minPixelDistanceToLine(
      tapPx: tapPx,
      line: line,
      project: project,
    );
    if (dPx <= thresholdPx) {
      final dKm = _minDistanceKmToLine(tapLatLng, line);
      ranked.add(_RankedLine(line, dKm, dPx));
    }
  }
  ranked.sort((a, b) => a.distancePx.compareTo(b.distancePx));
  return ranked.map((r) => NearbyAstroLine(r.line, r.distanceKm)).toList();
}
