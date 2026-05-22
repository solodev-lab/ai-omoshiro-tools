// Consultation API — POST /astro/consultation (Stage 3)
//
// 設計: apps/solara/docs/pro_candidates.md §7.2 Stage 3
// Worker 側: apps/solara/worker/src/consultation.js
//
// Stage 2 (consultation_engine.dart) が組み立てた候補リストを送信し、
// Stella の解釈 (intro / candidates[].narrative / outro) を受け取る。

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'consultation_engine.dart' show CandidateLocation;
import 'app_attest_client.dart';
import 'solara_api.dart'
    show solaraConsultationUrl, solaraConsultationCreditsUrl;

/// API レスポンス内の候補別 Stella の解釈。
class ConsultationCandidateReading {
  final String name;
  final List<String> energyLabels;
  final String narrative;

  const ConsultationCandidateReading({
    required this.name,
    required this.energyLabels,
    required this.narrative,
  });

  factory ConsultationCandidateReading.fromJson(Map<String, dynamic> j) =>
      ConsultationCandidateReading(
        name: j['name'] as String? ?? '',
        energyLabels: (j['energyLabels'] as List?)
                ?.map((e) => e.toString())
                .toList(growable: false) ??
            const [],
        narrative: j['narrative'] as String? ?? '',
      );

  /// 履歴保存 (consultation_record) 用シリアライズ。
  Map<String, dynamic> toJson() => {
        'name': name,
        'energyLabels': energyLabels,
        'narrative': narrative,
      };
}

/// API レスポンス全体。
class ConsultationReading {
  final String intro;
  final List<ConsultationCandidateReading> candidates;
  final String outro;
  final String model;

  /// Stella が届かない時の静的 fallback の場合 true。クライアント UI で
  /// 「Stella の声が届きませんでした」バナー等を表示する。
  final bool fallback;

  const ConsultationReading({
    required this.intro,
    required this.candidates,
    required this.outro,
    required this.model,
    required this.fallback,
  });

  factory ConsultationReading.fromJson(Map<String, dynamic> j) =>
      ConsultationReading(
        intro: j['intro'] as String? ?? '',
        candidates: (j['candidates'] as List?)
                ?.map((e) => ConsultationCandidateReading.fromJson(
                      e as Map<String, dynamic>,
                    ))
                .toList(growable: false) ??
            const [],
        outro: j['outro'] as String? ?? '',
        model: j['model'] as String? ?? '',
        fallback: j['fallback'] == true,
      );

  /// 履歴保存 (consultation_record) 用シリアライズ。
  Map<String, dynamic> toJson() => {
        'intro': intro,
        'candidates': candidates.map((c) => c.toJson()).toList(),
        'outro': outro,
        'model': model,
        'fallback': fallback,
      };
}

/// Free 試食クレジット切れ等で Worker が 402 を返したときのブロック理由。
/// 設計: project_solara_stella_free_credits.md。
enum ConsultationBlock {
  /// 今週の無料 Stella 相談を使い切った (Pro で無制限)。
  creditExhausted,

  /// このモードは無料試食の対象外 (CONSULTATION_FREE_MODES に含まれない)。
  proOnlyMode,

  /// 候補の出し直しは Pro 限定 (Free は 1 回の結果セットのみ)。
  proOnlyRefresh,

  /// 上記以外の 402 (将来追加コード)。フォールバックでペイウォールへ。
  unknown,
}

/// fetchConsultation の戻り値。成功 / ペイウォールブロック / 接続失敗 を区別する。
class ConsultationResult {
  /// 成功時のみ非 null。
  final ConsultationReading? reading;

  /// 402 paywall ブロック時のみ非 null。
  final ConsultationBlock? block;

  /// 成功時、Free ユーザーの今週の残り無料回数 (Pro は null)。
  final int? freeCreditsRemaining;

  /// 成功時、Free 週あたり上限 (Pro は null)。
  final int? freeCreditsLimit;

  /// 成功時、購入クレジット残高 (Pro は null)。
  final int? purchasedBalance;

  const ConsultationResult({
    this.reading,
    this.block,
    this.freeCreditsRemaining,
    this.freeCreditsLimit,
    this.purchasedBalance,
  });

  bool get isSuccess => reading != null;
  bool get isBlocked => block != null;

  /// reading も block も無い = クライアント側接続/解析失敗。
  bool get isNetworkError => reading == null && block == null;
}

ConsultationBlock _blockFromCode(String? code) {
  switch (code) {
    case 'consultation_credit_exhausted':
      return ConsultationBlock.creditExhausted;
    case 'consultation_pro_only_mode':
      return ConsultationBlock.proOnlyMode;
    case 'consultation_pro_only_refresh':
      return ConsultationBlock.proOnlyRefresh;
    default:
      return ConsultationBlock.unknown;
  }
}

/// /astro/consultation を呼んで Stella の解釈を取得する。
///
/// [theme]      テーマキー (consultationThemes のいずれか)
/// [mode]       'migration' | 'travel' | 'daily'
/// [scope]      'specific' | 'region' | 'world' | 'bearings'
/// [candidates] Stage 2 で生成した 1〜3 件
/// [freeText]   任意。相談者の自由記述
/// [excluded]   リフレッシュ時に既出候補名を除外する場合 (narrative で名前を引用しない指示)
///
/// 戻り: [ConsultationResult] (成功 / 402 paywall ブロック / 接続失敗)。
/// ※ Worker 側で Stella が届かなくても static fallback が 200 で返るので、
///   isNetworkError は「クライアント側で接続自体失敗」のケースのみ。
Future<ConsultationResult> fetchConsultation({
  required String theme,
  required String mode,
  required String scope,
  required List<CandidateLocation> candidates,
  String freeText = '',
  List<String> excluded = const [],
  String lang = 'ja',
  Duration timeout = const Duration(seconds: 60),
  http.Client? client,
}) async {
  final c = client ?? http.Client();
  try {
    final body = <String, dynamic>{
      'theme': theme,
      'mode': mode,
      'scope': scope,
      'candidates': candidates.map((e) => e.toJson()).toList(),
      if (freeText.isNotEmpty) 'freeText': freeText,
      if (excluded.isNotEmpty) 'excluded': excluded,
      'lang': lang,
    };
    // 設計 v2.2: __appUserId を body に merge (Worker 側 RevenueCat 連動 Pro 判定)
    final merged = AppAttestClient.withAppUserIdMerged(body);
    // 設計 v1.8 §16.2: bytes を確定して両側で同一 SHA-256 を保証
    final bodyString = json.encode(merged);
    final bodyBytes = utf8.encode(bodyString);
    final headers = <String, String>{'Content-Type': 'application/json'};
    // App Attest assertion header 注入 (bypass モードでは no-op)
    await AppAttestClient.instance.addHeaders(headers, bodyBytes);
    final res = await c
        .post(
          Uri.parse(solaraConsultationUrl),
          headers: headers,
          body: bodyBytes, // String ではなく bytes (addHeaders と同一参照)
        )
        .timeout(timeout);
    if (res.statusCode == 200) {
      final map = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return ConsultationResult(
        reading: ConsultationReading.fromJson(map),
        freeCreditsRemaining: (map['freeCreditsRemaining'] as num?)?.toInt(),
        freeCreditsLimit: (map['freeCreditsLimit'] as num?)?.toInt(),
        purchasedBalance: (map['purchasedBalance'] as num?)?.toInt(),
      );
    }
    // 402 = Free 試食ゲートでブロック (paywall 誘導)。
    if (res.statusCode == 402) {
      String? code;
      try {
        final map = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        code = map['error'] as String?;
      } catch (_) {
        code = null;
      }
      return ConsultationResult(block: _blockFromCode(code));
    }
  } catch (_) {
    // network / decode error → isNetworkError
  } finally {
    if (client == null) c.close();
  }
  return const ConsultationResult();
}

/// Stella 相談クレジットの現在状況 (無料週次残 + 購入残高)。
class ConsultationCreditStatus {
  /// Pro なら true (無制限、各回数は null)。
  final bool pro;
  final int? freeRemaining;
  final int? freeLimit;
  final int? purchasedBalance;

  const ConsultationCreditStatus({
    required this.pro,
    this.freeRemaining,
    this.freeLimit,
    this.purchasedBalance,
  });

  /// 何かしら相談できる残数があるか (Pro は常に true)。
  bool get hasAny =>
      pro || (freeRemaining ?? 0) > 0 || (purchasedBalance ?? 0) > 0;

  factory ConsultationCreditStatus.fromJson(Map<String, dynamic> j) =>
      ConsultationCreditStatus(
        pro: j['pro'] == true,
        freeRemaining: (j['freeRemaining'] as num?)?.toInt(),
        freeLimit: (j['freeLimit'] as num?)?.toInt(),
        purchasedBalance: (j['purchasedBalance'] as num?)?.toInt(),
      );
}

/// `/protected/consultation/credits` を呼んで現在のクレジット状況を取得する。
/// 失敗時 null (UI 側は表示を控える)。
Future<ConsultationCreditStatus?> fetchConsultationCredits({
  Duration timeout = const Duration(seconds: 15),
  http.Client? client,
}) async {
  final c = client ?? http.Client();
  try {
    final merged = AppAttestClient.withAppUserIdMerged(<String, dynamic>{});
    final bodyBytes = utf8.encode(json.encode(merged));
    final headers = <String, String>{'Content-Type': 'application/json'};
    await AppAttestClient.instance.addHeaders(headers, bodyBytes);
    final res = await c
        .post(
          Uri.parse(solaraConsultationCreditsUrl),
          headers: headers,
          body: bodyBytes,
        )
        .timeout(timeout);
    if (res.statusCode == 200) {
      return ConsultationCreditStatus.fromJson(
        json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>,
      );
    }
  } catch (_) {
    // network error → null
  } finally {
    if (client == null) c.close();
  }
  return null;
}
