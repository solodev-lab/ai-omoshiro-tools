import 'dart:math';

import 'package:latlong2/latlong.dart';

import 'astro_lines.dart' as al;
import 'world_cities.dart';

/// ============================================================
/// Solara (ii) AI 相談 — Stage 2 計算エンジン
///
/// 設計: apps/solara/docs/pro_candidates.md §7.2 Stage 2
///
/// 役割:
///   入力 (テーマ + モード + スコープ + 地理情報) → AstroLine 群を絞り込み
///   → 候補地点を生成 → AI (Stage 3) に渡せる JSON 構造で返す。
///
/// クライアント側で完結 (Worker は Stage 3 AI 呼出のみ担当)。
///
/// v1 制約:
///   - theme 線フィルタは conjunction 本線のみ (40 本中の theme 該当)。
///     aspect 線 (square/trine/sextile) は v2 以降で追加検討。
///   - 都市プールは world_cities.dart の 333 件キュレートリスト。
/// ============================================================

/// 相談モード。pro_candidates.md §7.2 Stage 1 の 3 モードに対応。
enum ConsultationMode {
  /// 移住: natal ACG (永続)。大陸・国スケール。
  migration,

  /// 旅行: 旅行日の CCG (日付指定)。地域・都市スケール。
  travel,

  /// おでかけ: 今日の CCG (現在地周辺)。方角・エリアスケール、daily 価値の核。
  daily,
}

/// 相談スコープ。candidate 数と生成ロジックが変わる。
enum ConsultationScope {
  /// 具体地点 (タップ/検索/保存地点): 1 候補。
  specific,

  /// 範囲指定 (bbox or 国セット): 3 候補。
  region,

  /// 世界全体: 3 候補、人口バイアスやや強。
  world,

  /// おでかけ専用 (方角別): 3 候補。
  bearings,
}

/// テーマキー (6 種、astroLineFortunePlanets の `all` 以外と一致)。
const List<String> consultationThemes = [
  'love',
  'money',
  'work',
  'communication',
  'healing',
  'newStart',
];

/// 候補地点に紐づく近接 theme 線。
class CandidateNearLine {
  final String planet; // 'sun'..'pluto'
  final String angle; // 'mc' | 'ic' | 'asc' | 'dsc'
  final String aspect; // v1 は 'conjunction' 固定
  final double distanceKm;

  const CandidateNearLine({
    required this.planet,
    required this.angle,
    required this.aspect,
    required this.distanceKm,
  });

  Map<String, dynamic> toJson() => {
        'planet': planet,
        'angle': angle,
        'aspect': aspect,
        'distanceKm': distanceKm.round(),
      };

  /// 履歴保存 (consultation_record) から復元する。
  factory CandidateNearLine.fromJson(Map<String, dynamic> j) =>
      CandidateNearLine(
        planet: j['planet'] as String? ?? '',
        angle: j['angle'] as String? ?? '',
        aspect: j['aspect'] as String? ?? 'conjunction',
        distanceKm: (j['distanceKm'] as num?)?.toDouble() ?? 0.0,
      );
}

/// 候補地点。Stage 3 AI プロンプトに渡す JSON の Dart 表現。
class CandidateLocation {
  final String nameJP;
  final String nameEN;
  final double lat;
  final double lng;
  final String country;
  final String region;
  final int population;
  final List<CandidateNearLine> nearLines;

  /// daily モード用: 現在地からの方角ラベル (N/NE/E/SE/S/SW/W/NW)。
  /// それ以外のモードでは null。
  final String? bearing;

  const CandidateLocation({
    required this.nameJP,
    required this.nameEN,
    required this.lat,
    required this.lng,
    required this.country,
    required this.region,
    required this.population,
    required this.nearLines,
    this.bearing,
  });

  Map<String, dynamic> toJson() => {
        'name': nameJP,
        'nameEN': nameEN,
        'lat': lat,
        'lng': lng,
        'country': country,
        'region': region,
        'population': population,
        if (bearing != null) 'bearing': bearing,
        'nearLines': nearLines.map((l) => l.toJson()).toList(),
      };

  /// 履歴保存 (consultation_record) から復元する。
  factory CandidateLocation.fromJson(Map<String, dynamic> j) =>
      CandidateLocation(
        nameJP: j['name'] as String? ?? j['nameJP'] as String? ?? '',
        nameEN: j['nameEN'] as String? ?? '',
        lat: (j['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (j['lng'] as num?)?.toDouble() ?? 0.0,
        country: j['country'] as String? ?? '',
        region: j['region'] as String? ?? '',
        population: (j['population'] as num?)?.toInt() ?? 0,
        bearing: j['bearing'] as String?,
        nearLines: (j['nearLines'] as List?)
                ?.map((e) =>
                    CandidateNearLine.fromJson(e as Map<String, dynamic>))
                .toList(growable: false) ??
            const [],
      );
}

/// テーマ → 関係惑星セット (astro_lines.dart の astroLineFortunePlanets を流用)。
Set<String> themePlanets(String theme) =>
    al.astroLineFortunePlanets[theme] ?? const <String>{};

/// 全 AstroLine から theme 該当の conjunction 本線のみを抽出 (v1)。
///
/// 例: theme='love' (venus/mars/moon) なら、3 惑星 × 4 angle = 12 本が候補。
/// (フレームは呼出側で選択済の前提: natal / transit / progressed / solarArc。)
List<al.AstroLine> filterThemeLines(
  List<al.AstroLine> all,
  String theme,
) {
  final planets = themePlanets(theme);
  if (planets.isEmpty) return const [];
  return all
      .where((l) => l.aspect == 'conjunction' && planets.contains(l.planet))
      .toList(growable: false);
}

// ────────────────────────────────────────────────────────────
// 候補生成 — 4 ケース
// ────────────────────────────────────────────────────────────

/// (1) 具体地点候補。1 件返す。
///
/// 既存 map_screen の `_findNearbyAstroLines` 相当を Haversine 距離ベースで
/// 簡略実装 (consultation は km スケールなので画面 pixel 距離は不要)。
CandidateLocation candidateForSpecific({
  required LatLng target,
  required String nameJP,
  required String nameEN,
  required String country,
  required String region,
  required List<al.AstroLine> themeLines,
  int population = 0,
  int maxNearLines = 5,
}) {
  return CandidateLocation(
    nameJP: nameJP,
    nameEN: nameEN,
    lat: target.latitude,
    lng: target.longitude,
    country: country,
    region: region,
    population: population,
    nearLines: _nearestLinesFor(target, themeLines, top: maxNearLines),
  );
}

/// (2) 範囲指定候補。3 件。
///
/// 都市プールを bbox (4 値) または countries (国コードセット) でフィルタ後、
/// theme 線への近接距離でランキング。除外名 (リフレッシュ用) も適用。
List<CandidateLocation> candidatesForRegion({
  required List<al.AstroLine> themeLines,
  double? minLat,
  double? maxLat,
  double? minLng,
  double? maxLng,
  Set<String>? countries,
  List<String> excludeNames = const [],
  int count = 3,
}) {
  final pool = worldCities.where((c) {
    if (countries != null && !countries.contains(c.country)) return false;
    if (minLat != null && c.lat < minLat) return false;
    if (maxLat != null && c.lat > maxLat) return false;
    if (minLng != null && c.lng < minLng) return false;
    if (maxLng != null && c.lng > maxLng) return false;
    return true;
  });
  return _rankCitiesByLineProximity(
    pool: pool,
    themeLines: themeLines,
    excludeNames: excludeNames,
    count: count,
  );
}

/// (3) 世界全体候補。3 件。人口バイアスを軽くかけて知名度の高い都市を優先。
List<CandidateLocation> candidatesForWorld({
  required List<al.AstroLine> themeLines,
  List<String> excludeNames = const [],
  int count = 3,
}) {
  return _rankCitiesByLineProximity(
    pool: worldCities,
    themeLines: themeLines,
    excludeNames: excludeNames,
    count: count,
    populationWeight: 0.6,
  );
}

/// (4) おでかけ候補。3 件。
///
/// 現在地から 8 方位 (N/NE/E/SE/S/SW/W/NW) に [radiusKm] 進んだ仮想点を作り、
/// 各方位の theme 線エネルギー (= 最寄り線までの距離) を測定。距離が小さい
/// 方位 (= 線が近い) ほどスコアが高い。上位 [count] 方位を候補化。
///
/// 候補名は「<方角>の方角」、bearing フィールドに方位コードが入る。
/// 都市名ではないので、UI 側で方角インジケータ + 距離表示にする想定。
List<CandidateLocation> candidatesForDaily({
  required LatLng currentLocation,
  required List<al.AstroLine> themeLines,
  double radiusKm = 50.0,
  List<String> excludeNames = const [],
  int count = 3,
}) {
  if (themeLines.isEmpty) return const [];
  const bearings = <_BearingDef>[
    _BearingDef('N', 0.0, '北'),
    _BearingDef('NE', 45.0, '北東'),
    _BearingDef('E', 90.0, '東'),
    _BearingDef('SE', 135.0, '南東'),
    _BearingDef('S', 180.0, '南'),
    _BearingDef('SW', 225.0, '南西'),
    _BearingDef('W', 270.0, '西'),
    _BearingDef('NW', 315.0, '北西'),
  ];
  final excluded = excludeNames.toSet();
  final scored = <_ScoredBearing>[];
  for (final b in bearings) {
    if (excluded.contains(b.code) || excluded.contains(b.labelJP)) continue;
    final pt = _offsetByBearing(currentLocation, b.bearingDeg, radiusKm);
    final near = _nearestLinesFor(pt, themeLines, top: 5);
    if (near.isEmpty) continue;
    scored.add(_ScoredBearing(b, pt, near));
  }
  scored.sort(
    (a, b) =>
        a.nearLines.first.distanceKm.compareTo(b.nearLines.first.distanceKm),
  );
  return scored.take(count).map((s) {
    final radiusLabel = radiusKm.round();
    return CandidateLocation(
      nameJP: '${s.def.labelJP}の方角',
      nameEN: '${s.def.code} bearing',
      lat: s.point.latitude,
      lng: s.point.longitude,
      country: '',
      region: '半径${radiusLabel}km',
      population: 0,
      nearLines: s.nearLines,
      bearing: s.def.code,
    );
  }).toList(growable: false);
}

// ────────────────────────────────────────────────────────────
// 内部ヘルパー
// ────────────────────────────────────────────────────────────

/// 点 [point] から [themeLines] の各線への最短距離を計算し、近い順 [top] 本を返す。
List<CandidateNearLine> _nearestLinesFor(
  LatLng point,
  List<al.AstroLine> themeLines, {
  int top = 5,
}) {
  if (themeLines.isEmpty) return const [];
  final ranked = <(al.AstroLine, double)>[];
  for (final line in themeLines) {
    final d = al.minDistanceKmToLine(point, line);
    ranked.add((line, d));
  }
  ranked.sort((a, b) => a.$2.compareTo(b.$2));
  final cut = ranked.take(top);
  return cut
      .map(
        (r) => CandidateNearLine(
          planet: r.$1.planet,
          angle: r.$1.angle,
          aspect: r.$1.aspect,
          distanceKm: r.$2,
        ),
      )
      .toList(growable: false);
}

class _ScoredCity {
  final CityEntry city;
  final List<CandidateNearLine> nearLines;
  final double score;
  const _ScoredCity(this.city, this.nearLines, this.score);
}

/// 都市プールを theme 線近接距離 + 人口バイアスでスコアリングして上位を返す。
///
/// [populationWeight] 0..1:
///   0   = 距離のみ (範囲指定モード向け、知名度バイアス無し)
///   0.6 = 中程度の人口ブースト (世界全体モード向け、メガシティ優遇)
List<CandidateLocation> _rankCitiesByLineProximity({
  required Iterable<CityEntry> pool,
  required List<al.AstroLine> themeLines,
  required List<String> excludeNames,
  int count = 3,
  int maxNearLines = 5,
  double populationWeight = 0.0,
}) {
  if (themeLines.isEmpty) return const [];
  final excluded = excludeNames.toSet();
  final scored = <_ScoredCity>[];
  for (final city in pool) {
    if (excluded.contains(city.nameJP) || excluded.contains(city.nameEN)) {
      continue;
    }
    final pt = LatLng(city.lat, city.lng);
    final near = _nearestLinesFor(pt, themeLines, top: maxNearLines);
    if (near.isEmpty) continue;
    final lineScore = near.first.distanceKm;
    // 人口ブースト: log10(pop)/7.5 を 0..0.5 に clamp して掛ける
    // (population 1M ≈ 0.13、10M ≈ 0.20)
    final popBoost = (log(max(1, city.population)) / log(10) / 7.5).clamp(
      0.0,
      0.5,
    );
    final score = lineScore * (1.0 - populationWeight * popBoost);
    scored.add(_ScoredCity(city, near, score));
  }
  scored.sort((a, b) => a.score.compareTo(b.score));
  return scored
      .take(count)
      .map(
        (s) => CandidateLocation(
          nameJP: s.city.nameJP,
          nameEN: s.city.nameEN,
          lat: s.city.lat,
          lng: s.city.lng,
          country: s.city.country,
          region: s.city.region,
          population: s.city.population,
          nearLines: s.nearLines,
        ),
      )
      .toList(growable: false);
}

class _BearingDef {
  final String code;
  final double bearingDeg;
  final String labelJP;
  const _BearingDef(this.code, this.bearingDeg, this.labelJP);
}

class _ScoredBearing {
  final _BearingDef def;
  final LatLng point;
  final List<CandidateNearLine> nearLines;
  const _ScoredBearing(this.def, this.point, this.nearLines);
}

/// 球面で [origin] から方位 [bearingDeg] (0=N, 時計回り) に [distanceKm] 進んだ点。
/// Spherical law of cosines、km スケールで誤差 1% 以下。
LatLng _offsetByBearing(LatLng origin, double bearingDeg, double distanceKm) {
  const earthR = 6371.0;
  final br = bearingDeg * pi / 180;
  final lat1 = origin.latitude * pi / 180;
  final lng1 = origin.longitude * pi / 180;
  final d = distanceKm / earthR;
  final lat2 = asin(
    sin(lat1) * cos(d) + cos(lat1) * sin(d) * cos(br),
  );
  final lng2 = lng1 +
      atan2(
        sin(br) * sin(d) * cos(lat1),
        cos(d) - sin(lat1) * sin(lat2),
      );
  return LatLng(
    lat2 * 180 / pi,
    ((lng2 * 180 / pi + 540) % 360) - 180,
  );
}
