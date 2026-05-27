// AI 出力ユーザー報告 API クライアント (Google Generative AI Apps Policy 対応)。
//
// 設計根拠: apps/solara/docs/store_compliance.md §3.1
//
// Worker 側 endpoint (`POST /protected/report-ai-output`) は CF Logs に
// console.warn で出力するのみ。永続保存はしない (オーナー判断 2026-05-28)。
// 詳細は worker/src/ai_report.js を参照。
//
// UI 側 (widgets/ai_report_button.dart) からの呼出専用。失敗してもユーザー体験は
// 致命的ではないため、bool で成否を返すのみ (例外は捕捉して false)。
//
// `/protected/*` 呼び出しは AppAttestClient.postProtected 経由 (設計 v2.1)。
// middleware が log_only モードなら bypass、enforced モードなら attestation 必須。
import 'dart:convert' show json;
import 'app_attest_client.dart';
import 'solara_api.dart' show solaraAiReportUrl;

class AiReportApi {
  /// AI 出力を運営に報告する。
  ///
  /// - [feature]    : 'tarot' / 'consultation' / 'fortune' の 3 種を想定。
  ///                  Worker 側で文字数 cap (32) のみ、enum validation はしない。
  /// - [reason]     : UI 固定 enum: inappropriate / misinformation / ethics /
  ///                  quality / hallucination / uncomfortable / other
  /// - [outputText] : 報告された AI 出力本文。Worker 側で 2000 字に切られる。
  /// - [freeText]   : 任意の自由記述。Worker 側で 500 字に切られる。
  ///
  /// 戻り値: 成功時 true、ネットワーク/parse/attestation 失敗時 false。
  static Future<bool> reportAiOutput({
    required String feature,
    required String reason,
    required String outputText,
    String? freeText,
  }) async {
    try {
      final res = await AppAttestClient.instance.postProtected(
        solaraAiReportUrl,
        payload: <String, dynamic>{
          'feature': feature,
          'reason': reason,
          'outputText': outputText,
          if (freeText != null && freeText.isNotEmpty) 'freeText': freeText,
        },
      );
      if (res.statusCode != 200) return false;
      final body = json.decode(res.body) as Map<String, dynamic>;
      return body['ok'] == true;
    } catch (_) {
      return false;
    }
  }
}
