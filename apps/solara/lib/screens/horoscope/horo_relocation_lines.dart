// 拠点(リロケーション) — ライン近接デルタの計算 + 静的意味文の合成。
//
// 設計 (2026-06-02, feature_inventory §0.2.52):
//   出生地と現住所では緯度経度が違う → 各惑星ラインへの距離が必ず変わる。
//   「ハウスが変わったか」(近距離では大抵変化なし) ではなく、
//   「どの惑星ラインに近づいた / 遠ざかったか」を主役にする。「変化なし」が原理的に消える。
//
//   全て静的: astro_lines.dart の buildAstroLines + minDistanceKmToLine で距離を出し、
//   惑星の性質 × アングルの領域 × 方向 × 度合い を定型文に合成する (Gemini 不使用 = ¥0)。
//   占星術の吉凶禁止に沿い「強まる / やわらぐ」の中立表現のみ (good/bad/lucky を使わない)。
//
// 範囲: 7惑星 (太陽/月/水星/金星/火星/木星/土星) × 4アングル (MC/IC/ASC/DSC) = 28本 (本線のみ)。
//   外惑星(天王星/海王星/冥王星)とアスペクト線は重い/抽象的なため初版では除外。

import 'package:latlong2/latlong.dart';

import '../../utils/astro_lines.dart' show buildAstroLines, minDistanceKmToLine;
import 'horo_constants.dart' show planetNamesJP;

/// ライン近接デルタの対象惑星 (表示順)。
const List<String> relocationLinePlanets = [
  'sun', 'moon', 'mercury', 'venus', 'mars', 'jupiter', 'saturn',
];

/// 惑星の性質 (中立表現)。ライン文・ハウス変化文の合成に使う。
const Map<String, String> relocationPlanetNature = {
  'sun': '自己表現と人生の主軸',
  'moon': '感情と心の基盤',
  'mercury': '思考と対話',
  'venus': '愛・調和・楽しみ',
  'mars': '情熱と行動力',
  'jupiter': '拡大とおおらかさ',
  'saturn': '構築と責任',
};

/// アングルの領域 (map_relocation_popup の _angleShortJp と整合)。
const Map<String, String> relocationAngleDomain = {
  'mc': '社会的な立場・キャリア',
  'ic': '家庭・心の拠り所',
  'asc': '自我・第一印象',
  'dsc': '対人・パートナーシップ',
};

/// ハウスの領域 (ハウス変化コメント用)。
const Map<int, String> relocationHouseDomain = {
  1: '自己・第一印象', 2: '所有・才能・収入', 3: '対話・学び・近距離', 4: '家庭・心の拠り所',
  5: '恋愛・創造・楽しみ', 6: '日常・健康・役割', 7: 'パートナーシップ', 8: '共有・深い変容',
  9: '探求・遠方・学問', 10: 'キャリア・社会的立場', 11: '仲間・ネットワーク', 12: '内面・癒し・秘密',
};

/// 1本のラインについて、出生地→現住所での距離変化。
class RelocationLineDelta {
  final String planet; // 'venus' 等 (7惑星のいずれか)
  final String angle;  // 'mc' | 'ic' | 'asc' | 'dsc'
  final double birthKm; // 出生地からその線への最短距離
  final double homeKm;  // 現住所からその線への最短距離

  const RelocationLineDelta({
    required this.planet,
    required this.angle,
    required this.birthKm,
    required this.homeKm,
  });

  /// 負 = 現住所の方が近い (近づいた) / 正 = 遠ざかった。
  double get deltaKm => homeKm - birthKm;
  bool get closer => deltaKm < 0;
}

/// 出生地・現住所の座標から、7惑星×4アングル=28本の距離デルタを計算し
/// **現住所から近い順 (homeKm 昇順)** に並べて返す。
///
/// ⚠️ |delta| (変化量) で並べてはいけない: 近距離移動では全ラインが一律に ~移動距離分
/// 変わるだけで、地球の裏側の無関係なラインが上位に来てしまう (2026-06-02 実例で判明)。
/// 「現住所で近い (=その地で効いている) ライン」を出すのが正。近/遠の差は副情報。
///
/// 計算は astro_lines.dart に委譲 (buildAstroLines で線生成 → minDistanceKmToLine)。
/// buildAstroLines は 120本 (アスペクト含む) を返すので conjunction + 7惑星に絞る。
List<RelocationLineDelta> computeRelocationLineDeltas({
  required Map<String, double> natalPlanets,
  required double natalMc,
  required double birthLat,
  required double birthLng,
  required double homeLat,
  required double homeLng,
}) {
  final lines = buildAstroLines(
    natal: natalPlanets,
    baselineMc: natalMc,
    baselineLng: birthLng,
  );
  final birth = LatLng(birthLat, birthLng);
  final home = LatLng(homeLat, homeLng);
  final out = <RelocationLineDelta>[];
  for (final line in lines) {
    if (line.aspect != 'conjunction') continue;
    if (!relocationPlanetNature.containsKey(line.planet)) continue;
    out.add(RelocationLineDelta(
      planet: line.planet,
      angle: line.angle,
      birthKm: minDistanceKmToLine(birth, line),
      homeKm: minDistanceKmToLine(home, line),
    ));
  }
  out.sort((a, b) => a.homeKm.compareTo(b.homeKm)); // 現住所から近い順
  return out;
}

/// |delta| (km) を 3 段階の副詞に。閾値は実機チューニング可。
String relocationMagnitudeAdverb(double absKm) {
  if (absKm < 150) return 'わずかに';
  if (absKm < 600) return 'はっきりと';
  return '大きく';
}

/// ライン近接デルタの 1 文 (中立表現)。
String relocationLineDeltaSentence(RelocationLineDelta d) {
  final planet = planetNamesJP[d.planet] ?? d.planet;
  final nature = relocationPlanetNature[d.planet] ?? '';
  final domain = relocationAngleDomain[d.angle] ?? '';
  final angle = d.angle.toUpperCase();
  final adv = relocationMagnitudeAdverb(d.deltaKm.abs());
  if (d.closer) {
    return '$planetの$angleラインに$adv近づきました。'
        '$domainにおける$natureが、この地で強まるでしょう。';
  }
  return '$planetの$angleラインから$adv遠ざかりました。'
      '$domainにおける$natureは、この地でやわらいで感じられるでしょう。';
}

/// ハウス変化の 1 文 (変化があった惑星のみ・中立表現)。
String relocationHouseChangeComment(String planet, int fromHouse, int toHouse) {
  final p = planetNamesJP[planet] ?? planet;
  final nature = relocationPlanetNature[planet] ?? '';
  final from = relocationHouseDomain[fromHouse] ?? '${fromHouse}H';
  final to = relocationHouseDomain[toHouse] ?? '${toHouse}H';
  return '$pの領域が「$from」から「$to」へ移ります。'
      'この地では$natureの置き所が$toに向かいます。';
}
