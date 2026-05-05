import 'dart:math';

import 'astro_math.dart';

/// ============================================================
/// Solara Astro Houses — Phase M2 真のアストロカートグラフィー
///
/// Worker (worker/src/astro.js: calcHousesPlacidus / calcAscendant /
/// calcMC) と同等のロジックを Dart 側で完結させる。Worker 呼出ゼロで
/// タップ即応 (<50ms) を実現する。
///
/// natal 惑星の黄経は出生地ベースのまま不変。
/// ASC / MC / 12 cusp だけ任意座標で再計算する古典的リロケーション。
///
/// 設計: project_solara_astrocartography_m2.md 論点2 (2-④ 確定)
/// ============================================================

double _toRad(double d) => d * pi / 180;
double _toDeg(double r) => r * 180 / pi;

double _clamp(double v, double lo, double hi) =>
    v < lo ? lo : (v > hi ? hi : v);

/// J2000 平均黄道傾斜。±50年で誤差 <0.007° なので Solara では定数で十分。
const double _obliquityDeg = 23.4393;

/// 任意座標で再計算した ASC / MC / 12 ハウス cusps。
class HousesResult {
  final double asc;
  final double mc;
  final double dsc;
  final double ic;
  final List<double> houses;
  final String system; // 'placidus' | 'equal' | 'whole_sign'

  HousesResult({
    required this.asc,
    required this.mc,
    required this.dsc,
    required this.ic,
    required this.houses,
    required this.system,
  });
}

/// natalMc + natalLng (chart fetch時の lng) から LST を逆算し、
/// 任意の (tapLat, tapLng) でハウスを再計算する。
///
/// LST 復元戦略:
///   RA(MC) = LST  (子午線の赤経 = LST、定義より)
///   Worker calcMC: MC = atan2(sin(LST), cos(LST)·cos(ε))
///   逆算: LST = atan2(sin(MC)·cos(ε), cos(MC))
/// 同一 UTC 瞬間における経度差: LST_tap = LST_home + (tapLng - natalLng)
///
/// この戦略により birthDate/birthTime/tz から UTC を再構築する必要がなく、
/// IANA TZ や DST 補正の問題を完全に回避できる。
HousesResult calcHousesRelocate({
  required double natalMc,
  required double natalLng,
  required double tapLat,
  required double tapLng,
  String houseSystem = 'placidus',
}) {
  final lstHome = _recoverLstFromMc(natalMc);
  final lstTap = normalize360(lstHome + (tapLng - natalLng));
  return _housesFromLst(
    lstDeg: lstTap,
    lat: tapLat,
    houseSystem: houseSystem,
  );
}

/// LST + lat から ASC/MC/houses を組み立てる内部実装。
HousesResult _housesFromLst({
  required double lstDeg,
  required double lat,
  required String houseSystem,
}) {
  final asc = _calcAscendant(lstDeg, lat, _obliquityDeg);
  final mc = _calcMc(lstDeg, _obliquityDeg);
  final dsc = normalize360(asc + 180);
  final ic = normalize360(mc + 180);

  late List<double> houses;
  late String system;
  if (houseSystem == 'whole_sign') {
    final start = (asc / 30).floor() * 30.0;
    houses = List<double>.generate(12, (i) => normalize360(start + i * 30.0));
    system = 'whole_sign';
  } else if (lat.abs() > 66) {
    // 極域: Placidus が不能 → Equal house にフォールバック
    houses = List<double>.generate(12, (i) => normalize360(asc + i * 30.0));
    system = 'equal';
  } else {
    houses = _placidusCusps(mc, asc, lat);
    system = 'placidus';
  }

  return HousesResult(
    asc: asc,
    mc: mc,
    dsc: dsc,
    ic: ic,
    houses: houses,
    system: system,
  );
}

/// MC ecliptic → RA(MC)=LST の逆変換 (Worker calcHousesPlacidus 内 ramc と同形)。
double _recoverLstFromMc(double mcDeg) {
  final mcR = _toRad(mcDeg);
  final cosEps = cos(_toRad(_obliquityDeg));
  return normalize360(_toDeg(atan2(sin(mcR) * cosEps, cos(mcR))));
}

/// ASC = atan2(-cos(LST), sin(ε)·tan(lat) + cos(ε)·sin(LST)) [+180°]
double _calcAscendant(double lstDeg, double lat, double obliquityDeg) {
  final lstR = _toRad(lstDeg);
  final epsR = _toRad(obliquityDeg);
  final latR = _toRad(lat);
  return normalize360(
    _toDeg(atan2(
      -cos(lstR),
      sin(epsR) * tan(latR) + cos(epsR) * sin(lstR),
    )) +
        180,
  );
}

/// MC = atan2(sin(LST), cos(LST)·cos(ε))
double _calcMc(double lstDeg, double obliquityDeg) {
  final lstR = _toRad(lstDeg);
  final epsR = _toRad(obliquityDeg);
  return normalize360(
    _toDeg(atan2(sin(lstR), cos(lstR) * cos(epsR))),
  );
}

/// Placidus 12-cusp 反復計算 (Worker calcHousesPlacidus L94-137 を Dart 移植)。
/// 極域 (|lat|>66) では呼ばないこと。
List<double> _placidusCusps(double mc, double asc, double lat) {
  final epsR = _toRad(_obliquityDeg);
  final cosEps = cos(epsR);
  final sinEps = sin(epsR);
  final tanLat = tan(_toRad(lat));
  final houses = List<double>.filled(12, 0.0);
  houses[0] = asc;
  houses[9] = mc;
  houses[6] = normalize360(asc + 180);
  houses[3] = normalize360(mc + 180);

  final mcR = _toRad(mc);
  final ramc = normalize360(_toDeg(atan2(sin(mcR) * cosEps, cos(mcR))));

  double cusp(int house) {
    double lon = (house <= 12)
        ? normalize360(mc + (house - 10) * 30.0)
        : normalize360(asc + (house - 1) * 30.0);
    for (int iter = 0; iter < 50; iter++) {
      final sinDecl = _clamp(sin(_toRad(lon)) * sinEps, -1, 1);
      final decl = asin(sinDecl);
      final adArg = _clamp(tanLat * tan(decl), -1, 1);
      final ad = _toDeg(asin(adArg));
      double targetRA;
      if (house == 11) {
        targetRA = ramc + (90 + ad) / 3;
      } else if (house == 12) {
        targetRA = ramc + 2 * (90 + ad) / 3;
      } else if (house == 2) {
        targetRA = ramc - 240 + 2 * ad / 3;
      } else {
        targetRA = ramc - 210 + ad / 3;
      }
      final raR = _toRad(targetRA);
      final newLon = normalize360(_toDeg(atan2(sin(raR), cos(raR) * cosEps)));
      final delta = (newLon - lon).abs();
      if (delta < 0.001 || delta > 359.999) break;
      lon = newLon;
    }
    return lon;
  }

  houses[10] = cusp(11);
  houses[11] = cusp(12);
  houses[1] = cusp(2);
  houses[2] = cusp(3);
  houses[4] = normalize360(houses[10] + 180);
  houses[5] = normalize360(houses[11] + 180);
  houses[7] = normalize360(houses[1] + 180);
  houses[8] = normalize360(houses[2] + 180);
  return houses;
}

/// 黄経 [planetLon] が houses (12 cusps) のどのハウスに入るか判定 (1-12)。
/// houses 不正時は null。 horoscope_screen の _planetHouse と同ロジック。
int? assignPlanetHouse(double planetLon, List<double> houses) {
  if (houses.length != 12) return null;
  final lon = planetLon % 360;
  for (int i = 0; i < 12; i++) {
    final cusp = houses[i] % 360;
    final next = houses[(i + 1) % 12] % 360;
    final inHouse = (cusp <= next)
        ? (lon >= cusp && lon < next)
        : (lon >= cusp || lon < next); // wrap (例: cusp=350, next=20)
    if (inHouse) return i + 1;
  }
  return null;
}
