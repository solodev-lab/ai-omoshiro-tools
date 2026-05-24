// Consultation Record — 自動保存 + 履歴 (V2: 全要素統合)
//
// 設計: project_solara_consultation_full_integration.md
//
// 1 件の相談 = 入力メタ (theme/mode/scope/withWhom/wish) + 枠 (innerSeason/
// intro/outro) + 蓄積した候補群 (1 枚ずつ「別の候補地」で増える) + 各候補の
// エビデンスを 1 つにまとめた永続化単位。
//
// 柱 3 の原則: Free でも自分の記録を永久に失わない。
// 検索・フィルタ等の「記録を使う道具」は Pro 機能。

import 'consultation_v2_api.dart';

class ConsultationRecord {
  /// 一意 ID (保存時刻のミリ秒 epoch を文字列化)。
  final String id;

  /// 保存時刻 (UTC、JSON では ISO8601)。
  final DateTime savedAt;

  // 入力メタ
  final String theme;
  final String mode;

  /// scope の種別 ('point'|'bearing'|'radius'|'region'|'country'|'world')。
  final String scopeKind;

  /// scope に付随する詳細ラベル (region グループ名 / 具体地点名 等)。なければ null。
  final String? scopeDetail;

  /// だれと / 願い (語りのレンズ・自由記述)。
  final String withWhom;
  final String wish;

  // 枠 (初回の Stella 出力。3 候補共通)
  final String innerSeason;
  final String intro;
  final String outro;

  /// 蓄積した候補群 (1 枚目 = 一番強い見出し、以降「別の候補地」で増える)。
  final List<ConsultationV2Candidate> candidates;

  /// 各候補のエビデンス (candidates と並行)。
  final List<ConsultationEvidence> evidences;

  /// 静的 fallback だったか。
  final bool fallback;

  /// お気に入り登録フラグ。
  final bool favorite;

  const ConsultationRecord({
    required this.id,
    required this.savedAt,
    required this.theme,
    required this.mode,
    required this.scopeKind,
    this.scopeDetail,
    this.withWhom = '',
    this.wish = '',
    this.innerSeason = '',
    this.intro = '',
    this.outro = '',
    required this.candidates,
    required this.evidences,
    this.fallback = false,
    this.favorite = false,
  });

  /// お気に入りフラグ等を差し替えた複製を返す。
  ConsultationRecord copyWith({bool? favorite}) => ConsultationRecord(
        id: id,
        savedAt: savedAt,
        theme: theme,
        mode: mode,
        scopeKind: scopeKind,
        scopeDetail: scopeDetail,
        withWhom: withWhom,
        wish: wish,
        innerSeason: innerSeason,
        intro: intro,
        outro: outro,
        candidates: candidates,
        evidences: evidences,
        fallback: fallback,
        favorite: favorite ?? this.favorite,
      );

  /// 結果画面が蓄積した reading 群からレコードを生成 (id は savedAt から自動採番)。
  factory ConsultationRecord.fromReadings({
    required String theme,
    required String mode,
    required String scopeKind,
    String? scopeDetail,
    String withWhom = '',
    String wish = '',
    required List<ConsultationV2Reading> readings,
    DateTime? savedAt,
  }) {
    final now = savedAt ?? DateTime.now().toUtc();
    final first = readings.isNotEmpty ? readings.first : null;
    return ConsultationRecord(
      id: now.millisecondsSinceEpoch.toString(),
      savedAt: now,
      theme: theme,
      mode: mode,
      scopeKind: scopeKind,
      scopeDetail: scopeDetail,
      withWhom: withWhom,
      wish: wish,
      innerSeason: first?.innerSeason ?? '',
      intro: first?.intro ?? '',
      outro: first?.outro ?? '',
      candidates: readings.map((r) => r.candidate).toList(growable: false),
      evidences: readings.map((r) => r.evidence).toList(growable: false),
      fallback: first?.fallback ?? false,
    );
  }

  /// 読み込み専用表示 (履歴詳細) のために reading 群を再構成する。
  List<ConsultationV2Reading> toReadings() {
    final out = <ConsultationV2Reading>[];
    for (var i = 0; i < candidates.length; i++) {
      final ev =
          i < evidences.length ? evidences[i] : const ConsultationEvidence();
      out.add(ConsultationV2Reading(
        isFirst: i == 0,
        candidate: candidates[i],
        evidence: ev,
        timeWindow: candidates[i].timeWindow,
        innerSeason: i == 0 ? innerSeason : '',
        intro: i == 0 ? intro : '',
        outro: i == 0 ? outro : '',
        fallback: fallback,
      ));
    }
    return out;
  }

  /// 履歴カード等の見出し用候補名 (方角は「○の方角」、座標のみは「この地点」)。
  static String displayName(ConsultationV2Candidate c) {
    if (c.bearing != null && c.bearing!.isNotEmpty) {
      return '${c.name ?? c.bearing}の方角';
    }
    if (c.name != null && c.name!.isNotEmpty) return c.name!;
    return 'この地点';
  }

  String get firstCandidateLabel {
    if (candidates.isEmpty) return '—';
    final name = displayName(candidates.first);
    if (candidates.length == 1) return name;
    return '$name ほか ${candidates.length - 1} 件';
  }

  Map<String, dynamic> toJson() => {
        'v': 2,
        'id': id,
        'savedAt': savedAt.toIso8601String(),
        'theme': theme,
        'mode': mode,
        'scopeKind': scopeKind,
        if (scopeDetail != null) 'scopeDetail': scopeDetail,
        if (withWhom.isNotEmpty) 'withWhom': withWhom,
        if (wish.isNotEmpty) 'wish': wish,
        if (innerSeason.isNotEmpty) 'innerSeason': innerSeason,
        if (intro.isNotEmpty) 'intro': intro,
        if (outro.isNotEmpty) 'outro': outro,
        'candidates': candidates.map((c) => c.toJson()).toList(),
        'evidences': evidences.map((e) => e.toJson()).toList(),
        'fallback': fallback,
        if (favorite) 'favorite': true,
      };

  factory ConsultationRecord.fromJson(Map<String, dynamic> j) {
    return ConsultationRecord(
      id: j['id'] as String? ?? '0',
      savedAt: DateTime.tryParse(j['savedAt'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      theme: j['theme'] as String? ?? '',
      mode: j['mode'] as String? ?? '',
      scopeKind: j['scopeKind'] as String? ?? 'world',
      scopeDetail: j['scopeDetail'] as String?,
      withWhom: j['withWhom'] as String? ?? '',
      wish: j['wish'] as String? ?? '',
      innerSeason: j['innerSeason'] as String? ?? '',
      intro: j['intro'] as String? ?? '',
      outro: j['outro'] as String? ?? '',
      candidates: (j['candidates'] as List?)
              ?.map((e) => ConsultationV2Candidate.fromJson(
                    (e as Map).cast<String, dynamic>(),
                  ))
              .toList(growable: false) ??
          const [],
      evidences: (j['evidences'] as List?)
              ?.map((e) => ConsultationEvidence.fromJson(
                    (e as Map).cast<String, dynamic>(),
                  ))
              .toList(growable: false) ??
          const [],
      fallback: j['fallback'] == true,
      favorite: j['favorite'] == true,
    );
  }
}
