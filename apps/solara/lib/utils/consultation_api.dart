// Consultation API — クレジット系 (V2 と共有)
//
// 設計: project_solara_stella_free_credits.md
//
// 相談の本体 (候補生成 + Stella ナレーション) は V2 (consultation_v2_api.dart) に
// 移行済み。本ファイルには V2 でも使うクレジット系のみ残す:
//   - ConsultationBlock (402 paywall 理由) + consultationBlockFromCode
//   - ConsultationCreditStatus + fetchConsultationCredits

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'app_attest_client.dart';
import 'solara_api.dart' show solaraConsultationCreditsUrl;

/// クレジット残高変化のグローバル通知（singleton）。
///
/// - 購入完了（Webhook 反映後）/ 相談実行成功後 / タロットカテゴリ消費後など、
///   サーバー側残高が動いた可能性がある時に `notifyChanged()` を呼ぶ。
/// - Sanctuary / 入力画面の Start popup などが addListener して即時 refetch する。
/// - これにより複数画面に分散したクレジット表示の更新ラグを解消する。
class ConsultationCreditEvents extends ChangeNotifier {
  ConsultationCreditEvents._();
  static final ConsultationCreditEvents instance = ConsultationCreditEvents._();
  void notifyChanged() => notifyListeners();
}

/// Free 試食クレジット切れ等で Worker が 402 を返したときのブロック理由。
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

/// 402 paywall レスポンスの `error` コード → [ConsultationBlock]。
/// V2 (consultation_v2_api.dart) からも再利用する。
ConsultationBlock consultationBlockFromCode(String? code) {
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
