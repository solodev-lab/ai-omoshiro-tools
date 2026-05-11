// ============================================================
// Solara Daily Transits API
//
// F1 (2026-04-29): 拠点 (自宅・職場等) における今日のトランジット惑星
// アングル通過時刻を取得する。
//
// Worker: /astro/daily-transits (POST)
// 設計: project_solara_design_philosophy.md
// ============================================================
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'solara_api.dart' show solaraWorkerBase;

const _dailyTransitsUrl = '$solaraWorkerBase/astro/daily-transits';

/// V2: その瞬間にトランジット惑星が natal 惑星と作るアスペクト。
class TransitAspect {
  /// 'sun' | 'moon' | 'mercury' | ... (natal planet key)
  final String natalPlanet;

  /// 'conjunction' | 'sextile' | 'square' | 'trine' | 'opposition'
  final String type;

  /// 'soft' | 'hard' | 'neutral' (Solara 設計思想の独立2軸の元)
  final String quality;

  /// 完全角度からの誤差（度）
  final double orb;

  const TransitAspect({
    required this.natalPlanet,
    required this.type,
    required this.quality,
    required this.orb,
  });

  factory TransitAspect.fromJson(Map<String, dynamic> j) => TransitAspect(
        natalPlanet: j['natalPlanet'] as String,
        type: j['type'] as String,
        quality: j['quality'] as String,
        orb: (j['orb'] as num).toDouble(),
      );
}

/// 1イベント = ある惑星が4アングル(ASC/MC/DSC/IC)のどれか1つを通過した瞬間。
class TransitEvent {
  /// 'ASC' | 'MC' | 'DSC' | 'IC'
  final String angle;

  /// UTC ISO 8601 時刻
  final DateTime time;

  /// その瞬間の惑星の高度 (度)。ASC/DSC = 0、MC = 高度最大、IC = 負値最大。
  final double altitude;

  /// その瞬間の惑星の方位角 (度、北=0、東=90)。
  final double azimuth;

  /// V2: その時刻のトランジット惑星 → natal 惑星アスペクト（タイト順）。
  /// natal 未指定時は空。
  final List<TransitAspect> aspects;

  const TransitEvent({
    required this.angle,
    required this.time,
    required this.altitude,
    required this.azimuth,
    this.aspects = const [],
  });

  factory TransitEvent.fromJson(Map<String, dynamic> j) => TransitEvent(
        angle: j['angle'] as String,
        time: DateTime.parse(j['time'] as String),
        altitude: (j['altitude'] as num).toDouble(),
        azimuth: (j['azimuth'] as num).toDouble(),
        aspects: (j['aspects'] as List?)
                ?.map((a) => TransitAspect.fromJson(a as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

/// 1惑星 × 1日分の通過イベント (最大4個: ASC/MC/DSC/IC)。
/// 極夜・極昼で ASC/DSC が無い場合や、計算失敗で一部欠ける場合がある。
class PlanetDailyTransits {
  /// 'sun' | 'moon' | 'mercury' | ...
  final String planet;

  /// 時刻順にソートされたイベント列
  final List<TransitEvent> events;

  const PlanetDailyTransits({required this.planet, required this.events});

  factory PlanetDailyTransits.fromJson(Map<String, dynamic> j) =>
      PlanetDailyTransits(
        planet: j['planet'] as String,
        events: (j['events'] as List)
            .map((e) => TransitEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// 緯度帯ヒット惑星 (Lewis 流の緯度効果)。
/// 観測時刻における赤緯 ≈ 観測者緯度 (zenith) または -観測者緯度 (nadir) の惑星。
class LatitudeBandHit {
  final String planet;
  /// 観測時刻の惑星赤緯 (度、北緯 + / 南緯 -)
  final double dec;
  /// 観測者緯度との差の絶対値 (zenith なら |dec - lat|、nadir なら |dec + lat|)
  final double delta;
  const LatitudeBandHit({
    required this.planet,
    required this.dec,
    required this.delta,
  });
  factory LatitudeBandHit.fromJson(Map<String, dynamic> j) => LatitudeBandHit(
        planet: j['planet'] as String,
        dec: (j['dec'] as num).toDouble(),
        delta: (j['delta'] as num).toDouble(),
      );
}

/// 観測時刻における緯度帯セクション (zenith / nadir のヒット惑星 + オーブ)。
class LatitudeBand {
  final double observerLat;
  final double orb;
  final List<LatitudeBandHit> zenith;
  final List<LatitudeBandHit> nadir;
  const LatitudeBand({
    required this.observerLat,
    required this.orb,
    required this.zenith,
    required this.nadir,
  });
  factory LatitudeBand.fromJson(Map<String, dynamic> j) => LatitudeBand(
        observerLat: (j['observerLat'] as num).toDouble(),
        orb: (j['orb'] as num).toDouble(),
        zenith: ((j['zenith'] as List?) ?? const [])
            .map((e) => LatitudeBandHit.fromJson(e as Map<String, dynamic>))
            .toList(),
        nadir: ((j['nadir'] as List?) ?? const [])
            .map((e) => LatitudeBandHit.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// /astro/daily-transits の完全レスポンス。
class DailyTransitsResult {
  /// 計算対象日 (yyyy-MM-dd, UTC)
  final String date;

  /// 観測点 (lat, lng)
  final double lat;
  final double lng;

  /// 10惑星分の通過イベント
  final List<PlanetDailyTransits> transits;

  /// L3 Lewis: 観測時刻における緯度帯ヒット (赤緯 ≈ ±観測者緯度 の惑星)。
  /// worker 古バージョン互換のため nullable。
  final LatitudeBand? latitudeBand;

  const DailyTransitsResult({
    required this.date,
    required this.lat,
    required this.lng,
    required this.transits,
    this.latitudeBand,
  });

  factory DailyTransitsResult.fromJson(Map<String, dynamic> j) {
    final loc = j['location'] as Map<String, dynamic>;
    return DailyTransitsResult(
      date: j['date'] as String,
      lat: (loc['lat'] as num).toDouble(),
      lng: (loc['lng'] as num).toDouble(),
      transits: (j['transits'] as List)
          .map((t) => PlanetDailyTransits.fromJson(t as Map<String, dynamic>))
          .toList(),
      latitudeBand: j['latitudeBand'] != null
          ? LatitudeBand.fromJson(j['latitudeBand'] as Map<String, dynamic>)
          : null,
    );
  }

  /// 全惑星の全イベントを時刻順にフラット化したリストを返す。
  /// UI で「タイムライン」として並べる用途。
  List<({String planet, TransitEvent event})> flatTimeline() {
    final list = <({String planet, TransitEvent event})>[];
    for (final t in transits) {
      for (final e in t.events) {
        list.add((planet: t.planet, event: e));
      }
    }
    list.sort((a, b) => a.event.time.compareTo(b.event.time));
    return list;
  }
}

/// 拠点における今日のトランジット通過時刻を取得する。
///
/// [startTime] を渡すとその瞬間から24h を走査する（local-day 境界に最適）。
/// [date] (yyyy-MM-dd) は startTime 未指定時のフォールバック。
/// 両方 null なら Worker 側で today (UTC) が使われる。
/// [natal] (黄経マップ) を渡すと V2 機能としてアスペクトも併記される。
/// [orbs] (アスペクト種別 → orb °) で Sanctuary 設定の orb を反映できる。
/// API 失敗時は null を返す（オフライン or Worker エラー）。
Future<DailyTransitsResult?> fetchDailyTransits({
  required double lat,
  required double lng,
  DateTime? startTime,
  String? date,
  Map<String, double>? natal,
  Map<String, double>? orbs,
}) async {
  try {
    final body = <String, dynamic>{'lat': lat, 'lng': lng};
    if (startTime != null) {
      body['startTimeIso'] = startTime.toUtc().toIso8601String();
    } else if (date != null) {
      body['date'] = date;
    }
    if (natal != null && natal.isNotEmpty) body['natal'] = natal;
    if (orbs != null && orbs.isNotEmpty) body['orbs'] = orbs;
    final resp = await http
        .post(
          Uri.parse(_dailyTransitsUrl),
          headers: const {'Content-Type': 'application/json'},
          body: json.encode(body),
        )
        .timeout(const Duration(seconds: 10));

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as Map<String, dynamic>;
      return DailyTransitsResult.fromJson(data);
    }
  } catch (_) {
    // ネットワーク失敗は静かに null を返す
  }
  return null;
}
