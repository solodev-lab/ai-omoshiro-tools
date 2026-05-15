// Consultation Record — Phase 2-4 自動保存 + 履歴
//
// 設計: apps/solara/docs/pro_candidates.md §7.2 Stage 4 + §7.3 柱3
//
// 1 件の相談 = 入力 (theme/mode/scope/freeText/候補) + 出力 (Stella reading)
// + メタ (id, savedAt) を 1 つにまとめた永続化単位。
//
// 柱 3 の原則: Free でも自分の記録を永久に失わない。
// 検索・フィルタ等の「記録を使う道具」は Pro 機能。

import 'consultation_api.dart';
import 'consultation_engine.dart';

class ConsultationRecord {
  /// 一意 ID (保存時刻のミリ秒 epoch を文字列化、衝突対策に suffix 不要)。
  final String id;

  /// 保存時刻 (UTC、JSON では ISO8601)。
  final DateTime savedAt;

  // 入力 (Stage 1)
  final String theme;
  final String mode;
  final String scope;
  final String freeText;

  // Stage 2 出力 (Stella に渡した候補)
  final List<CandidateLocation> candidates;

  // Stage 3 出力 (Stella の reading or 静的 fallback)
  final ConsultationReading reading;

  const ConsultationRecord({
    required this.id,
    required this.savedAt,
    required this.theme,
    required this.mode,
    required this.scope,
    required this.freeText,
    required this.candidates,
    required this.reading,
  });

  /// 新規レコード生成 (id は savedAt から自動採番)。
  factory ConsultationRecord.create({
    required String theme,
    required String mode,
    required String scope,
    required String freeText,
    required List<CandidateLocation> candidates,
    required ConsultationReading reading,
    DateTime? savedAt,
  }) {
    final now = savedAt ?? DateTime.now().toUtc();
    return ConsultationRecord(
      id: now.millisecondsSinceEpoch.toString(),
      savedAt: now,
      theme: theme,
      mode: mode,
      scope: scope,
      freeText: freeText,
      candidates: candidates,
      reading: reading,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'savedAt': savedAt.toIso8601String(),
        'theme': theme,
        'mode': mode,
        'scope': scope,
        'freeText': freeText,
        'candidates': candidates.map((c) => c.toJson()).toList(),
        'reading': reading.toJson(),
      };

  factory ConsultationRecord.fromJson(Map<String, dynamic> j) {
    return ConsultationRecord(
      id: j['id'] as String? ?? '0',
      savedAt:
          DateTime.tryParse(j['savedAt'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      theme: j['theme'] as String? ?? '',
      mode: j['mode'] as String? ?? '',
      scope: j['scope'] as String? ?? '',
      freeText: j['freeText'] as String? ?? '',
      candidates: (j['candidates'] as List?)
              ?.map((e) =>
                  CandidateLocation.fromJson(e as Map<String, dynamic>))
              .toList(growable: false) ??
          const [],
      reading: ConsultationReading.fromJson(
        (j['reading'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }
}
