import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../utils/solara_api.dart' show solaraWorkerBase;
import 'map_constants.dart';

/// ============================================================
/// Solara Astro — CF Worker API 経由の天体計算
/// Worker: /astro/chart (POST)
/// 方針: project_flutter_native.md 2026-04-07確定
///   サーバーサイド計算（CF Worker + astronomy-engine.js）
/// ============================================================

// Worker URL は solara_api.dart の solaraWorkerBase（単一情報源）から合成
const _astroApiUrl = '$solaraWorkerBase/astro/chart';

/// CF Worker /astro/chart のレスポンス
class ChartResult {
  final Map<String, double> natal;      // 10天体の黄経
  final Map<String, double>? transit;   // トランジット天体
  final Map<String, double>? progressed;// プログレス天体
  final double asc, mc, dsc, ic;
  final List<double> houses;
  final List<Map<String, dynamic>> aspects;
  final Map<String, List<dynamic>> patterns;

  ChartResult({
    required this.natal, this.transit, this.progressed,
    required this.asc, required this.mc, required this.dsc, required this.ic,
    required this.houses, required this.aspects, required this.patterns,
  });

  factory ChartResult.fromJson(Map<String, dynamic> json) {
    return ChartResult(
      natal: (json['natal'] as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toDouble())),
      transit: json['transit'] != null
        ? (json['transit'] as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toDouble()))
        : null,
      progressed: json['progressed'] != null
        ? (json['progressed'] as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toDouble()))
        : null,
      asc: (json['asc'] as num).toDouble(),
      mc: (json['mc'] as num).toDouble(),
      dsc: (json['dsc'] as num).toDouble(),
      ic: (json['ic'] as num).toDouble(),
      houses: (json['houses'] as List).map((h) => (h as num).toDouble()).toList(),
      aspects: (json['aspects'] as List).map((a) => a as Map<String, dynamic>).toList(),
      patterns: (json['patterns'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as List<dynamic>)),
    );
  }
}

/// CF Worker にチャートを要求
/// birthTzName (IANA TZ名, C案) が指定された場合はそれを優先し、
/// 未指定なら birthTz (UTCオフセット整数) にfallback。
/// targetDate が指定されると、その日時 (UTC) の transit/progressed を計算する。
/// 未指定時は現在時刻を使用。
///
/// relocateLat / relocateLng が指定された場合、Worker 側で natal惑星位置は
/// 出生地ベースのまま、ASC/MC/houses だけ relocate座標で再計算する
/// （古典的リロケーションチャート）。
/// 0/0 や null は未指定扱い → 出生地でハウス計算。
Future<ChartResult?> fetchChart({
  required String birthDate,
  required String birthTime,
  required double birthLat,
  required double birthLng,
  int birthTz = 9,
  String? birthTzName,
  String mode = 'both', // 'natal' | 'transit' | 'progressed' | 'both'
  String houseSystem = 'placidus',
  DateTime? targetDate,
  double? relocateLat,
  double? relocateLng,
}) async {
  try {
    final t = (targetDate ?? DateTime.now()).toUtc();
    final body = <String, dynamic>{
      'birthDate': birthDate,
      'birthTime': birthTime,
      'birthTz': birthTz,
      'birthLat': birthLat,
      'birthLng': birthLng,
      'mode': mode,
      'transitDate': t.toIso8601String(),
      'houseSystem': houseSystem,
    };
    if (birthTzName != null && birthTzName.isNotEmpty) {
      body['birthTzName'] = birthTzName;
    }
    // リロケーション: 0/0 や null は無視（出生地でハウス計算）
    if (relocateLat != null && relocateLng != null &&
        !(relocateLat == 0 && relocateLng == 0)) {
      body['relocateLat'] = relocateLat;
      body['relocateLng'] = relocateLng;
    }
    final resp = await http.post(
      Uri.parse(_astroApiUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    ).timeout(const Duration(seconds: 10));

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as Map<String, dynamic>;
      return ChartResult.fromJson(data);
    }
  } catch (e) {
    // API失敗時はnullを返す（オフライン or Worker未デプロイ）
  }
  return null;
}

/// ============================================================
/// scoreAll — HTML index.html L1636-L1704 のロジック
/// ChartResult からMap画面用の16方位スコアを計算
/// ============================================================

double _norm360(double d) { d = d % 360; return d < 0 ? d + 360 : d; }
double _angDist(double a, double b) { final d = (_norm360(a) - _norm360(b)).abs(); return d > 180 ? 360 - d : d; }
double _cosFall(double dist, double spread) {
  if (dist >= spread) return 0;
  return (1 + cos(pi * dist / spread)) / 2;
}

const _spread = 22.5;

final _dir16Ang = <String, double>{
  for (int i = 0; i < dir16.length; i++) dir16[i]: i * 22.5,
};

/// Map画面用アスペクト定義（HTML: index.html ASPECTS — Horo画面とはorb値が異なる）
const _mapAspects = [
  {'name':'conjunction','angle':0.0,'orb':8.0,'quality':'neutral','weight':0.6},
  {'name':'sextile','angle':60.0,'orb':4.0,'quality':'soft','weight':0.8},
  {'name':'square','angle':90.0,'orb':5.0,'quality':'hard','weight':1.0},
  {'name':'trine','angle':120.0,'orb':5.0,'quality':'soft','weight':1.0},
  {'name':'quincunx','angle':150.0,'orb':3.0,'quality':'tense','weight':0.4},
  {'name':'opposition','angle':180.0,'orb':6.0,'quality':'hard','weight':0.8},
];

/// weight を quality に応じて (Soft, Hard) に分配する
/// - soft → 全額Soft
/// - hard / tense → 全額Hard
/// - neutral → Soft/Hard に半々
(double, double) _qSplit(String q, double w) {
  if (q == 'hard' || q == 'tense') return (0.0, w);
  if (q == 'soft') return (w, 0.0);
  return (w / 2, w / 2);
}

const _fortunePairs = <String, List<List<String>>>{
  'healing': [['moon','neptune'],['moon','venus'],['sun','neptune']],
  'money':   [['jupiter','venus'],['jupiter','sun'],['venus','sun']],
  'love':    [['venus','mars'],['venus','moon'],['mars','moon']],
  'work':    [['saturn','sun'],['saturn','mars'],['jupiter','sun'],['jupiter','mars']],
  'communication': [['mercury','sun'],['mercury','venus'],['mercury','moon']],
};

const _angleBonus = {'_asc': 1.5, '_dsc': 1.5, '_mc': 1.3, '_ic': 1.3};

Map<String, double> _emptyComp() => {'tSoft': 0, 'tHard': 0, 'pSoft': 0, 'pHard': 0};

List<Map<String, dynamic>> _findAspects(
  Map<String, double> map1, Map<String, double>? map2, double wMult, String prefix,
) {
  final results = <Map<String, dynamic>>[];
  final same = prefix.isEmpty;
  final k1 = map1.keys.toList(), k2 = (map2 ?? map1).keys.toList();
  for (int i = 0; i < k1.length; i++) {
    final jStart = same ? i + 1 : 0;
    for (int j = jStart; j < k2.length; j++) {
      if (same && i == j) continue;
      final p1 = k1[i], p2 = k2[j];
      final diff = _angDist(map1[p1]!, same ? map1[p2]! : map2![p2]!);
      for (final a in _mapAspects) {
        if ((diff - (a['angle'] as double)).abs() <= (a['orb'] as double)) {
          results.add({'p1': p1, 'p2': '$prefix$p2', 'type': a['name'], 'quality': a['quality'], 'weight': (a['weight'] as double) * wMult});
          break;
        }
      }
    }
  }
  return results;
}

class ScoreResult {
  final Map<String, double> sScores;
  final Map<String, Map<String, double>> sComp;
  final Map<String, String?> sFortune;
  final Map<String, String> pDir;
  final Map<String, Map<String, double>> fScores;
  final Map<String, Map<String, Map<String, double>>> fComp;

  ScoreResult({
    required this.sScores, required this.sComp, required this.sFortune,
    required this.pDir, required this.fScores, required this.fComp,
  });
}

/// ChartResult → Map画面用16方位スコア
ScoreResult scoreAll(ChartResult chart) {
  final natalWithAngles = Map<String, double>.from(chart.natal);
  natalWithAngles['_asc'] = chart.asc;
  natalWithAngles['_mc'] = chart.mc;
  natalWithAngles['_dsc'] = chart.dsc;
  natalWithAngles['_ic'] = chart.ic;

  final tA = chart.transit ?? chart.natal;
  final nA = natalWithAngles;
  final pA = chart.progressed ?? chart.natal;

  final tt = _findAspects(tA, null, 1.0, '');
  final tn = _findAspects(tA, nA, 0.6, 'N:');
  final pn = _findAspects(pA, nA, 0.5, 'N:');
  final tp = _findAspects(tA, pA, 0.4, 'P:');

  final tComp = <String, Map<String, double>>{for (final k in tA.keys) k: _emptyComp()};
  final pComp = <String, Map<String, double>>{for (final k in pA.keys) k: _emptyComp()};

  double getAB(String p2key) {
    final ak = p2key.replaceAll('N:', '').replaceAll('P:', '');
    return _angleBonus[ak] ?? 1.0;
  }

  void addT(String planet, String q, double amt) {
    if (!tComp.containsKey(planet)) return;
    final (s, h) = _qSplit(q, amt);
    tComp[planet]!['tSoft'] = tComp[planet]!['tSoft']! + s;
    tComp[planet]!['tHard'] = tComp[planet]!['tHard']! + h;
  }
  void addP(String planet, String q, double amt) {
    if (!pComp.containsKey(planet)) return;
    final (s, h) = _qSplit(q, amt);
    pComp[planet]!['pSoft'] = pComp[planet]!['pSoft']! + s;
    pComp[planet]!['pHard'] = pComp[planet]!['pHard']! + h;
  }

  for (final a in tt) {
    final q = a['quality'] as String;
    final w = a['weight'] as double;
    addT(a['p1'] as String, q, w);
    addT(a['p2'] as String, q, w);
  }
  for (final a in tn) {
    addT(a['p1'] as String, a['quality'] as String, (a['weight'] as double) * getAB(a['p2'] as String));
  }
  for (final a in pn) {
    addP(a['p1'] as String, a['quality'] as String, (a['weight'] as double) * getAB(a['p2'] as String));
  }
  for (final a in tp) {
    final q = a['quality'] as String;
    final w = a['weight'] as double;
    addT(a['p1'] as String, q, w);
    addP((a['p2'] as String).replaceFirst('P:', ''), q, w);
  }

  // Spread to 16 directions
  final sComp = <String, Map<String, double>>{for (final d in dir16) d: _emptyComp()};
  final sScores = <String, double>{for (final d in dir16) d: 0};
  bool isAngle(String k) => k.startsWith('_');

  for (final e in tA.entries) {
    final c = tComp[e.key]!;
    for (final d in dir16) {
      final f = _cosFall(_angDist(e.value, _dir16Ang[d]!), _spread);
      sComp[d]!['tSoft'] = sComp[d]!['tSoft']! + c['tSoft']! * f;
      sComp[d]!['tHard'] = sComp[d]!['tHard']! + c['tHard']! * f;
    }
  }
  for (final e in pA.entries) {
    if (isAngle(e.key)) continue;
    final c = pComp[e.key]!;
    for (final d in dir16) {
      final f = _cosFall(_angDist(e.value, _dir16Ang[d]!), _spread);
      sComp[d]!['pSoft'] = sComp[d]!['pSoft']! + c['pSoft']! * f;
      sComp[d]!['pHard'] = sComp[d]!['pHard']! + c['pHard']! * f;
    }
  }
  for (final d in dir16) {
    final c = sComp[d]!;
    sScores[d] = c['tSoft']! + c['tHard']! + c['pSoft']! + c['pHard']!;
  }

  // Planet directions
  final pDir = <String, String>{};
  for (final e in tA.entries) {
    if (isAngle(e.key)) continue;
    String best = 'N'; double bd = 999;
    for (final d in dir16) {
      final dd = _angDist(e.value, _dir16Ang[d]!);
      if (dd < bd) { bd = dd; best = d; }
    }
    pDir[e.key] = best;
  }

  // Fortune per category
  final fScores = <String, Map<String, double>>{};
  final fComp = <String, Map<String, Map<String, double>>>{};
  for (final cat in _fortunePairs.keys) {
    fScores[cat] = {for (final d in dir16) d: 0};
    fComp[cat] = {for (final d in dir16) d: _emptyComp()};
    final pairs = _fortunePairs[cat]!;
    final cp = <String>{};
    for (final pr in pairs) { for (final p in pr) { cp.add(p); } }
    final ctc = <String, Map<String, double>>{for (final p in cp) p: _emptyComp()};
    final cpc = <String, Map<String, double>>{for (final p in cp) p: _emptyComp()};

    void addCT(String planet, String q, double amt) {
      if (!ctc.containsKey(planet)) return;
      final (s, h) = _qSplit(q, amt);
      ctc[planet]!['tSoft'] = ctc[planet]!['tSoft']! + s;
      ctc[planet]!['tHard'] = ctc[planet]!['tHard']! + h;
    }
    void addCP(String planet, String q, double amt) {
      if (!cpc.containsKey(planet)) return;
      final (s, h) = _qSplit(q, amt);
      cpc[planet]!['pSoft'] = cpc[planet]!['pSoft']! + s;
      cpc[planet]!['pHard'] = cpc[planet]!['pHard']! + h;
    }

    for (final a in tt) {
      final i1 = cp.contains(a['p1']), i2 = cp.contains(a['p2']);
      if (!i1 && !i2) continue;
      final pm = pairs.any((pr) =>
        (a['p1'] == pr[0] && a['p2'] == pr[1]) || (a['p1'] == pr[1] && a['p2'] == pr[0])
      ) ? 2.0 : 0.5;
      final amt = (a['weight'] as double) * pm;
      final q = a['quality'] as String;
      if (i1) addCT(a['p1'] as String, q, amt);
      if (i2) addCT(a['p2'] as String, q, amt);
    }
    for (final a in tn) {
      if (!cp.contains(a['p1'])) continue;
      addCT(a['p1'] as String, a['quality'] as String, (a['weight'] as double) * 0.5);
    }
    for (final a in pn) {
      if (!cp.contains(a['p1'])) continue;
      addCP(a['p1'] as String, a['quality'] as String, (a['weight'] as double) * 0.5);
    }
    for (final a in tp) {
      final p1 = a['p1'] as String;
      final p2 = (a['p2'] as String).replaceFirst('P:', '');
      final amt = (a['weight'] as double) * 0.5;
      final q = a['quality'] as String;
      if (cp.contains(p1)) addCT(p1, q, amt);
      if (cp.contains(p2)) addCP(p2, q, amt);
    }

    for (final p in cp) {
      if (tA.containsKey(p)) {
        final c = ctc[p]!;
        for (final d in dir16) {
          final f = _cosFall(_angDist(tA[p]!, _dir16Ang[d]!), _spread);
          fComp[cat]![d]!['tSoft'] = fComp[cat]![d]!['tSoft']! + c['tSoft']! * f;
          fComp[cat]![d]!['tHard'] = fComp[cat]![d]!['tHard']! + c['tHard']! * f;
        }
      }
      if (pA.containsKey(p)) {
        final c = cpc[p] ?? _emptyComp();
        for (final d in dir16) {
          final f = _cosFall(_angDist(pA[p]!, _dir16Ang[d]!), _spread);
          fComp[cat]![d]!['pSoft'] = fComp[cat]![d]!['pSoft']! + c['pSoft']! * f;
          fComp[cat]![d]!['pHard'] = fComp[cat]![d]!['pHard']! + c['pHard']! * f;
        }
      }
    }
    for (final d in dir16) {
      final c = fComp[cat]![d]!;
      fScores[cat]![d] = c['tSoft']! + c['tHard']! + c['pSoft']! + c['pHard']!;
    }
  }

  // Dominant fortune
  final sFortune = <String, String?>{};
  for (final d in dir16) {
    String? best; double bv = -1;
    for (final cat in _fortunePairs.keys) {
      if (fScores[cat]![d]! > bv) { bv = fScores[cat]![d]!; best = cat; }
    }
    sFortune[d] = bv > 0.01 ? best : null;
  }

  return ScoreResult(
    sScores: sScores, sComp: sComp, sFortune: sFortune,
    pDir: pDir, fScores: fScores, fComp: fComp,
  );
}
