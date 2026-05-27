// Consultation V2 API — POST /protected/astro/consultation2
//
// 設計: project_solara_consultation_full_integration.md (全要素統合)
// Worker 側: apps/solara/worker/src/{consultation_engine,consultation_v2}.js
//
// 新方式: client は「誕生データ + 自宅座標 + 5問の答え + preset」(約1KB) だけ送り、
// Worker がチャート/線/sectorEnergy/候補多様性/リロケハウスを全部計算して
// Stella の言葉 (候補 1 つ + エビデンス + 初回のみ内的季節/intro/outro) を返す。
// 1 クレジット = 1 候補。「別の候補地」は excluded を足した再呼び出し (= +1 クレジット)。
//
// 旧 consultation_api.dart (client が候補を組む方式) は deployed app 用に温存。
//
// HARD500 回避のため part 分割: リクエストモデルは consultation_v2_request.dart。

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_attest_client.dart';
import 'consultation_api.dart' show ConsultationBlock, consultationBlockFromCode;
import 'solara_api.dart' show solaraConsultation2Url;
import 'solara_storage.dart' show SolaraProfile;

part 'consultation_v2_request.dart';

// ════════════════════════════════════════════════════════════
// レスポンスモデル
// ════════════════════════════════════════════════════════════

/// 時間帯リズムの 1 項目 (旅行の朝昼夜)。
class ConsultationTimeWindowItem {
  final String bucket; // 'morning' | 'noon' | 'evening' | ...
  final String label; // 日本語ラベル (朝/昼/夜 等)

  const ConsultationTimeWindowItem({required this.bucket, required this.label});

  factory ConsultationTimeWindowItem.fromJson(Map<String, dynamic> j) =>
      ConsultationTimeWindowItem(
        bucket: j['bucket'] as String? ?? '',
        label: j['label'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'bucket': bucket, 'label': label};
}

/// 時間帯 (現地の時間帯のみ・時計表示なし)。
/// single = おでかけ/移住なし、rhythm = 旅行の朝昼夜リズム。
class ConsultationTimeWindow {
  final String kind; // 'single' | 'rhythm'
  final String? bucket; // single
  final String? label; // single
  final List<ConsultationTimeWindowItem> items; // rhythm

  const ConsultationTimeWindow({
    required this.kind,
    this.bucket,
    this.label,
    this.items = const [],
  });

  static ConsultationTimeWindow? fromJsonOrNull(dynamic j) {
    if (j is! Map) return null;
    final m = j.cast<String, dynamic>();
    final kind = m['kind'] as String? ?? '';
    if (kind == 'rhythm') {
      return ConsultationTimeWindow(
        kind: kind,
        items: (m['items'] as List?)
                ?.map((e) => ConsultationTimeWindowItem.fromJson(
                      (e as Map).cast<String, dynamic>(),
                    ))
                .toList(growable: false) ??
            const [],
      );
    }
    if (kind == 'single') {
      return ConsultationTimeWindow(
        kind: kind,
        bucket: m['bucket'] as String?,
        label: m['label'] as String?,
      );
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'kind': kind,
        if (bucket != null) 'bucket': bucket,
        if (label != null) 'label': label,
        if (items.isNotEmpty) 'items': items.map((e) => e.toJson()).toList(),
      };
}

/// エビデンスの距離行 (玄人向けに km を出す。本文には出さない)。
class ConsultationEvidenceKm {
  final String factor;
  final int km;

  const ConsultationEvidenceKm({required this.factor, required this.km});

  factory ConsultationEvidenceKm.fromJson(Map<String, dynamic> j) =>
      ConsultationEvidenceKm(
        factor: j['factor'] as String? ?? '',
        km: (j['km'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {'factor': factor, 'km': km};
}

/// エビデンス (占星術ファクターのみ。重み・選び方・プロンプトは出さない)。
class ConsultationEvidence {
  final List<String> factors;
  final List<ConsultationEvidenceKm> km;

  /// 出生時刻不明 (移住) のときの注記。それ以外は null。
  final String? note;

  const ConsultationEvidence({
    this.factors = const [],
    this.km = const [],
    this.note,
  });

  factory ConsultationEvidence.fromJson(Map<String, dynamic> j) =>
      ConsultationEvidence(
        factors: (j['factors'] as List?)
                ?.map((e) => e.toString())
                .toList(growable: false) ??
            const [],
        km: (j['km'] as List?)
                ?.map((e) => ConsultationEvidenceKm.fromJson(
                      (e as Map).cast<String, dynamic>(),
                    ))
                .toList(growable: false) ??
            const [],
        note: j['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'factors': factors,
        'km': km.map((e) => e.toJson()).toList(),
        if (note != null) 'note': note,
      };
}

/// 1 候補地の Stella の読み (構造データ + ナレーション)。
class ConsultationV2Candidate {
  final String? name;
  final String? nameEN;
  final String? bearing; // daily 方角 (N/NE/...)、それ以外 null
  final String? placeType; // 具体地点で店舗種類があれば
  final double lat;
  final double lng;
  final String? country;
  final String? region;
  final String characterHeadline; // 特徴ヘッドライン (15字目安)
  final List<String> energyLabels; // 「惑星 アングル・性格」
  final String narrative;
  final ConsultationTimeWindow? timeWindow;

  const ConsultationV2Candidate({
    this.name,
    this.nameEN,
    this.bearing,
    this.placeType,
    required this.lat,
    required this.lng,
    this.country,
    this.region,
    required this.characterHeadline,
    required this.energyLabels,
    required this.narrative,
    this.timeWindow,
  });

  factory ConsultationV2Candidate.fromJson(Map<String, dynamic> j) =>
      ConsultationV2Candidate(
        name: j['name'] as String?,
        nameEN: j['nameEN'] as String?,
        bearing: j['bearing'] as String?,
        placeType: j['placeType'] as String?,
        lat: (j['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (j['lng'] as num?)?.toDouble() ?? 0.0,
        country: j['country'] as String?,
        region: j['region'] as String?,
        characterHeadline: j['characterHeadline'] as String? ?? '',
        energyLabels: (j['energyLabels'] as List?)
                ?.map((e) => e.toString())
                .toList(growable: false) ??
            const [],
        narrative: j['narrative'] as String? ?? '',
        timeWindow: ConsultationTimeWindow.fromJsonOrNull(j['timeWindow']),
      );

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (nameEN != null) 'nameEN': nameEN,
        if (bearing != null) 'bearing': bearing,
        if (placeType != null) 'placeType': placeType,
        'lat': lat,
        'lng': lng,
        if (country != null) 'country': country,
        if (region != null) 'region': region,
        'characterHeadline': characterHeadline,
        'energyLabels': energyLabels,
        'narrative': narrative,
        if (timeWindow != null) 'timeWindow': timeWindow!.toJson(),
      };
}

/// 相談 V2 レスポンス全体 (成功時)。
class ConsultationV2Reading {
  final bool isFirst;
  final ConsultationV2Candidate candidate;
  final ConsultationEvidence evidence;
  final ConsultationTimeWindow? timeWindow;

  /// 初回のみ非空 (isFirst=false のときは空文字)。
  final String innerSeason;
  final String intro;
  final String outro;

  /// 「別の候補地」で残り出せる候補数。
  final int remainingAfter;

  /// 候補が 1 件しか無かった (正直に強さ順、多様性で水増ししていない)。
  final bool single;

  /// テーマ該当の強い線が近距離に無い「静かな場」(捏造で持ち上げていない)。
  final bool fallbackHonest;

  final String model;

  /// Stella が届かず静的 fallback になった場合 true。
  final bool fallback;

  const ConsultationV2Reading({
    required this.isFirst,
    required this.candidate,
    required this.evidence,
    this.timeWindow,
    this.innerSeason = '',
    this.intro = '',
    this.outro = '',
    this.remainingAfter = 0,
    this.single = false,
    this.fallbackHonest = false,
    this.model = '',
    this.fallback = false,
  });

  factory ConsultationV2Reading.fromJson(Map<String, dynamic> j) =>
      ConsultationV2Reading(
        isFirst: j['isFirst'] == true,
        candidate: ConsultationV2Candidate.fromJson(
          (j['candidate'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        evidence: ConsultationEvidence.fromJson(
          (j['evidence'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        timeWindow: ConsultationTimeWindow.fromJsonOrNull(j['timeWindow']),
        innerSeason: j['innerSeason'] as String? ?? '',
        intro: j['intro'] as String? ?? '',
        outro: j['outro'] as String? ?? '',
        remainingAfter: (j['remainingAfter'] as num?)?.toInt() ?? 0,
        single: j['single'] == true,
        fallbackHonest: j['fallbackHonest'] == true,
        model: j['model'] as String? ?? '',
        fallback: j['fallback'] == true,
      );
}

/// fetchConsultationV2 の戻り値。
/// 成功 / 候補出し尽くし (exhausted) / 402 ペイウォール / 接続失敗 を区別する。
class ConsultationV2Result {
  /// 成功時のみ非 null。
  final ConsultationV2Reading? reading;

  /// 402 paywall ブロック時のみ非 null。
  final ConsultationBlock? block;

  /// excluded で候補を出し尽くした (これ以上「別の候補地」が無い)。
  final bool exhausted;

  /// 非 Pro: 今週の残り無料回数 (Pro は null)。
  final int? freeCreditsRemaining;
  final int? freeCreditsLimit;

  /// Pro: 今週の残り回数 (非 Pro は null、2026-05-27 追加)。
  /// CONSULTATION_PRO_WEEKLY (default 100) - proUsed。
  final int? proCreditsRemaining;
  final int? proCreditsLimit;

  /// Pro/非 Pro 共通の購入クレジット残高。
  final int? purchasedBalance;

  const ConsultationV2Result({
    this.reading,
    this.block,
    this.exhausted = false,
    this.freeCreditsRemaining,
    this.freeCreditsLimit,
    this.proCreditsRemaining,
    this.proCreditsLimit,
    this.purchasedBalance,
  });

  bool get isSuccess => reading != null;
  bool get isBlocked => block != null;
  bool get isExhausted => exhausted;

  /// reading も block も exhausted も無い = クライアント側接続/解析失敗。
  bool get isNetworkError => reading == null && block == null && !exhausted;
}

/// /protected/astro/consultation2 を呼んで Stella の読み (候補 1 つ) を取得する。
///
/// 戻り: [ConsultationV2Result]
///   - 成功 (候補あり): reading != null
///   - 出し尽くし: exhausted == true
///   - 402 paywall: block != null
///   - 接続/解析失敗: isNetworkError == true
/// ※ Worker 側は Stella 不通でも静的 fallback を 200 で返す (reading.fallback=true)。
Future<ConsultationV2Result> fetchConsultationV2(
  ConsultationRequest request, {
  Duration timeout = const Duration(seconds: 60),
  http.Client? client,
}) async {
  final c = client ?? http.Client();
  try {
    // __appUserId を body に merge (Worker 側 RevenueCat 連動 Pro 判定)
    final merged = AppAttestClient.withAppUserIdMerged(request.toJson());
    // bytes を確定して両側で同一 SHA-256 を保証 (App Attest 設計 v1.8 §16.2)
    final bodyBytes = utf8.encode(json.encode(merged));
    final headers = <String, String>{'Content-Type': 'application/json'};
    await AppAttestClient.instance.addHeaders(headers, bodyBytes);
    final res = await c
        .post(
          Uri.parse(solaraConsultation2Url),
          headers: headers,
          body: bodyBytes,
        )
        .timeout(timeout);
    if (res.statusCode == 200) {
      final map =
          json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final freeRemaining = (map['freeCreditsRemaining'] as num?)?.toInt();
      final freeLimit = (map['freeCreditsLimit'] as num?)?.toInt();
      final proRemaining = (map['proCreditsRemaining'] as num?)?.toInt();
      final proLimit = (map['proCreditsLimit'] as num?)?.toInt();
      final purchased = (map['purchasedBalance'] as num?)?.toInt();
      if (map['exhausted'] == true) {
        return ConsultationV2Result(
          exhausted: true,
          freeCreditsRemaining: freeRemaining,
          freeCreditsLimit: freeLimit,
          proCreditsRemaining: proRemaining,
          proCreditsLimit: proLimit,
          purchasedBalance: purchased,
        );
      }
      return ConsultationV2Result(
        reading: ConsultationV2Reading.fromJson(map),
        freeCreditsRemaining: freeRemaining,
        freeCreditsLimit: freeLimit,
        proCreditsRemaining: proRemaining,
        proCreditsLimit: proLimit,
        purchasedBalance: purchased,
      );
    }
    if (res.statusCode == 402 || res.statusCode == 425) {
      // 402: paywall (credit_exhausted / pro_only_mode 等)
      // 425: pro_sync_pending (クライアント主張 Pro × DO 非 Pro、購入消費せず安全停止)
      String? code;
      try {
        final map =
            json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        code = map['error'] as String?;
      } catch (_) {
        code = null;
      }
      return ConsultationV2Result(block: consultationBlockFromCode(code));
    }
  } catch (_) {
    // network / decode error → isNetworkError
  } finally {
    if (client == null) c.close();
  }
  return const ConsultationV2Result();
}
