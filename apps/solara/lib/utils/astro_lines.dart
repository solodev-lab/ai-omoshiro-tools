import 'dart:math';

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
    this.zenith,
  });

  /// 線のキー (UI から参照しやすいように) "venus_asc" 等
  String get key => '${planet}_$angle';
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
/// 戻り: -75..75 度緯度範囲のサンプル列、子午線跨ぎ対応セグメント
List<List<LatLng>> _meridianLine(double raDeg, double gmstHours,
    {required bool antiMeridian, double latMin = -75, double latMax = 75}) {
  double lng = raDeg - gmstHours * 15;
  if (antiMeridian) lng += 180;
  lng = _normLng(lng);
  // 緯度を細かくサンプリング (5度刻み)
  final pts = <LatLng>[];
  for (double lat = latMin; lat <= latMax + 0.1; lat += 5) {
    pts.add(LatLng(lat, lng));
  }
  return [pts]; // 子午線跨がない (固定経度) ので1セグメント
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
  double latStep = 2.0,
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

/// 全 40本のアストロラインを計算。
///
/// [natal] は 10惑星の黄経 (度)。
/// [baselineMc] / [baselineLng] は chart fetch時の MC と地点経度
/// (relocate設定時は relocated MC と home lng、未設定なら birth)。
/// [latRange] は描画緯度範囲 (デフォルト -75..75 度)。
/// [latStep] はホライズン線のサンプリング間隔 (度、デフォルト2)。
List<AstroLine> buildAstroLines({
  required Map<String, double> natal,
  required double baselineMc,
  required double baselineLng,
  double latMin = -75,
  double latMax = 75,
  double latStep = 2.0,
}) {
  final gmst = _gmstHoursFromBaseline(baselineMc, baselineLng);
  final lines = <AstroLine>[];

  for (final planet in _planetKeys) {
    final lon = natal[planet];
    if (lon == null) continue;
    final coord = _eclipticToEquatorial(lon);

    // MC line + zenith point
    // zenith: 緯度=惑星赤緯δ、経度=MC line の固定経度
    // δ が描画緯度範囲外でも理論値として保持(マーカー表示時にクランプ判定)。
    final mcLng = _normLng(coord.ra - gmst * 15);
    lines.add(AstroLine(
      planet: planet,
      angle: 'mc',
      segments: _meridianLine(coord.ra, gmst,
          antiMeridian: false, latMin: latMin, latMax: latMax),
      zenith: LatLng(coord.dec, mcLng),
    ));
    // IC line
    lines.add(AstroLine(
      planet: planet,
      angle: 'ic',
      segments: _meridianLine(coord.ra, gmst,
          antiMeridian: true, latMin: latMin, latMax: latMax),
    ));
    // ASC line
    lines.add(AstroLine(
      planet: planet,
      angle: 'asc',
      segments: _horizonLine(
        raDeg: coord.ra,
        decDeg: coord.dec,
        gmstHours: gmst,
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
      segments: _horizonLine(
        raDeg: coord.ra,
        decDeg: coord.dec,
        gmstHours: gmst,
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

/// タップ地点から [thresholdKm] 以内のアスペクト線を検出して
/// 近い順に並べて返す。FORTUNE カテゴリで dim されている線は除外しない
/// (popup は常に全情報を出す方針、表示側で処理)。
List<NearbyAstroLine> findNearbyLines({
  required LatLng tap,
  required List<AstroLine> lines,
  double thresholdKm = 200,
}) {
  final hits = <NearbyAstroLine>[];
  for (final line in lines) {
    final d = _minDistanceKmToLine(tap, line);
    if (d <= thresholdKm) hits.add(NearbyAstroLine(line, d));
  }
  hits.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  return hits;
}
