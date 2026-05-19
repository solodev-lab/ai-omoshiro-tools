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
import 'solara_api.dart' show solaraConsultationUrl;

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

/// /astro/consultation を呼んで Stella の解釈を取得する。
///
/// [theme]      テーマキー (consultationThemes のいずれか)
/// [mode]       'migration' | 'travel' | 'daily'
/// [scope]      'specific' | 'region' | 'world' | 'bearings'
/// [candidates] Stage 2 で生成した 1〜3 件
/// [freeText]   任意。相談者の自由記述
/// [excluded]   リフレッシュ時に既出候補名を除外する場合 (narrative で名前を引用しない指示)
///
/// 戻り: 成功時 [ConsultationReading]、ネットワーク/解析失敗時 null。
/// ※ Worker 側で Stella が届かなくても static fallback が返るので、null は
///   「クライアント側で接続自体失敗」のケースのみ。
Future<ConsultationReading?> fetchConsultation({
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
    // 設計 v1.8 §16.2: bytes を確定して両側で同一 SHA-256 を保証
    final bodyString = json.encode(body);
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
      return ConsultationReading.fromJson(
        json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>,
      );
    }
  } catch (_) {
    // network / decode error → null fallback
  } finally {
    if (client == null) c.close();
  }
  return null;
}
