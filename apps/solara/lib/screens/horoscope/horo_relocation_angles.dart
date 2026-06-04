// 拠点(リロケーション) — アングル近接 (A案・度数距離) の計算 + 静的フォールバック文。
//
// 設計 (2026-06-02, feature_inventory §0.2.53):
//   引っ越しても惑星の黄経は動かないが、ハウスのカスプ(= アングル ASC/MC/DSC/IC)は緯度経度で
//   ずれる。各惑星から「最も近いアングルへの度数距離」を 出生地チャート vs 現住所チャート で
//   比較し、近づいた/遠ざかったを連続量で捉える。ハウスが変わらなくても必ず変化が出る
//   (= 旧ハウス差分版の「変化なし」だらけ問題が原理的に消える)。
//   占星術の正統: アングルに近い惑星 (angular planet) ほど強く働く。ASC/MC 変化の印象とも一貫。
//   B案(ライン近接・地理km)と違い「図の度数空間」で測るため「地球の裏のライン」問題は起きない。
//
//   解説本文は Worker /relocation (Gemini, thinkingBudget:0・全員無料) で動的生成する。
//   本ファイルは ① 幾何計算 ② Gemini へ渡す構造化ファクト ③ 取得前/失敗時の静的フォールバック文。
//   吉凶禁止 (強まる/やわらぐ・前に出る/落ち着く の中立表現のみ。good/bad/lucky を使わない)。

import '../../utils/astro_houses.dart' show assignPlanetHouse;
import '../../utils/solara_i18n.dart';

/// 対象10天体 (表示順の素): 個人天体 → 社会天体 → トランスサタニアン。
const List<String> relocationAnglePlanets = [
  'sun', 'moon', 'mercury', 'venus', 'mars',
  'jupiter', 'saturn', 'uranus', 'neptune', 'pluto',
];

/// アングル → 領域 (ASC/MC/DSC/IC)。カード見出しのラベルに使う。
const Map<String, String> relocationAngleDomain = {
  'asc': '自己・第一印象',
  'mc': '社会的な立場・キャリア',
  'dsc': '対人・パートナーシップ',
  'ic': '家庭・心の拠り所',
};
const Map<String, String> _relocationAngleDomainEN = {
  'asc': 'self and first impression',
  'mc': 'social standing and career',
  'dsc': 'relationships and partnership',
  'ic': 'home and inner anchor',
};

/// アングルキー → ロケール別の領域ラベル (ja / en)。
String relocationAngleDomainLabel(String angle) => isEnLocale()
    ? (_relocationAngleDomainEN[angle] ?? '')
    : (relocationAngleDomain[angle] ?? '');

/// これ未満の度数差は「ほぼ変化なし」(same) とみなす。
const double _kSameDeg = 0.15;

/// 全惑星の最大度数差がこれ未満なら「ほぼ同じ場所」ヒントを出す。
const double kSamePlaceMaxDeg = 0.05;

/// 2つの黄経 (度) の最短角距離 (0..180)。
double _angularDist(double a, double b) {
  var d = (a - b).abs() % 360;
  if (d > 180) d = 360 - d;
  return d;
}

/// 1惑星のアングル近接デルタ。
class RelocationAngleDelta {
  final String planet;       // 'sun' 等 (10天体のいずれか)
  final int? natalHouse;     // 出生地ハウス 1-12 (houses 無しなら null)
  final int? reloHouse;      // 現住所ハウス 1-12 (同上)
  final String nearestAngle; // 現住所で最も近いアングル 'asc'|'mc'|'dsc'|'ic'
  final double natalDeg;     // 出生地での「そのアングル」への度数距離
  final double reloDeg;      // 現住所での「そのアングル」への度数距離

  const RelocationAngleDelta({
    required this.planet,
    required this.natalHouse,
    required this.reloHouse,
    required this.nearestAngle,
    required this.natalDeg,
    required this.reloDeg,
  });

  /// 負 = 現住所の方が軸に近い (近づいた) / 正 = 遠ざかった。
  double get deltaDeg => reloDeg - natalDeg;

  bool get houseChanged =>
      natalHouse != null && reloHouse != null && natalHouse != reloHouse;

  /// 'closer' | 'farther' | 'same'
  String get direction {
    if (deltaDeg < -_kSameDeg) return 'closer';
    if (deltaDeg > _kSameDeg) return 'farther';
    return 'same';
  }

  /// Worker /relocation へ渡す構造化ファクト (Gemini はこれを文章化するだけ)。
  Map<String, dynamic> toPayload() => {
        'planet': planet,
        if (natalHouse != null) 'natalHouse': natalHouse,
        if (reloHouse != null) 'reloHouse': reloHouse,
        'nearestAngle': nearestAngle,
        'deltaDeg': double.parse(deltaDeg.toStringAsFixed(2)),
        'direction': direction,
      };
}

/// アングル自身の星座変化 (ASC/MC/DSC/IC)。引越の印象的なヘッドライン。
class RelocationAngleSignChange {
  final String angle; // 'asc'|'mc'|'dsc'|'ic'
  final int fromSign; // 0-11
  final int toSign;   // 0-11

  const RelocationAngleSignChange({
    required this.angle,
    required this.fromSign,
    required this.toSign,
  });

  Map<String, dynamic> toPayload() =>
      {'angle': angle, 'fromSign': fromSign, 'toSign': toSign};
}

/// 出生地/現住所のチャート (ハウスカスプ12・ASC・MC) と惑星黄経から、10天体の
/// アングル近接デルタを計算。並びは ① ハウス移動あり優先 → ② 現住所で軸に近い順。
///
/// 各惑星について「現住所で最も近いアングル」を選び、その同じアングルへの距離を
/// 出生地でも測って差分を取る (= その地で効いている軸に対する、生地からの変化)。
List<RelocationAngleDelta> computeRelocationAngleDeltas({
  required Map<String, double> natalPlanets,
  required List<double> natalHouses,
  required List<double> relocateHouses,
  required double natalAsc,
  required double natalMc,
  required double relocateAsc,
  required double relocateMc,
}) {
  final natalAngles = <String, double>{
    'asc': natalAsc % 360,
    'mc': natalMc % 360,
    'dsc': (natalAsc + 180) % 360,
    'ic': (natalMc + 180) % 360,
  };
  final reloAngles = <String, double>{
    'asc': relocateAsc % 360,
    'mc': relocateMc % 360,
    'dsc': (relocateAsc + 180) % 360,
    'ic': (relocateMc + 180) % 360,
  };
  final hasHouses = natalHouses.length == 12 && relocateHouses.length == 12;

  final out = <RelocationAngleDelta>[];
  for (final p in relocationAnglePlanets) {
    final lon = natalPlanets[p];
    if (lon == null) continue;
    // 現住所で最も近いアングルを選ぶ。
    var nearest = 'asc';
    var bestReloDeg = 999.0;
    reloAngles.forEach((a, deg) {
      final d = _angularDist(lon, deg);
      if (d < bestReloDeg) {
        bestReloDeg = d;
        nearest = a;
      }
    });
    final natalDeg = _angularDist(lon, natalAngles[nearest]!);
    out.add(RelocationAngleDelta(
      planet: p,
      natalHouse: hasHouses ? assignPlanetHouse(lon, natalHouses) : null,
      reloHouse: hasHouses ? assignPlanetHouse(lon, relocateHouses) : null,
      nearestAngle: nearest,
      natalDeg: natalDeg,
      reloDeg: bestReloDeg,
    ));
  }

  out.sort((a, b) {
    if (a.houseChanged != b.houseChanged) return a.houseChanged ? -1 : 1;
    return a.reloDeg.compareTo(b.reloDeg);
  });
  return out;
}

/// ASC/MC/DSC/IC の星座が出生地→現住所で変わったものだけ返す。
List<RelocationAngleSignChange> computeRelocationAngleSignChanges({
  required double natalAsc,
  required double natalMc,
  required double relocateAsc,
  required double relocateMc,
}) {
  final pairs = <String, List<double>>{
    'asc': [natalAsc % 360, relocateAsc % 360],
    'mc': [natalMc % 360, relocateMc % 360],
    'dsc': [(natalAsc + 180) % 360, (relocateAsc + 180) % 360],
    'ic': [(natalMc + 180) % 360, (relocateMc + 180) % 360],
  };
  final out = <RelocationAngleSignChange>[];
  pairs.forEach((a, v) {
    final from = (v[0] / 30).floor() % 12;
    final to = (v[1] / 30).floor() % 12;
    if (from != to) {
      out.add(RelocationAngleSignChange(angle: a, fromSign: from, toSign: to));
    }
  });
  return out;
}
