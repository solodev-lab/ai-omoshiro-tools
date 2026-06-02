// Unit test: ConsultationReturn のプロセス死復元 (toJson/fromJson ラウンドトリップ)。
//
// 「相談結果に戻る」チップの live 状態 (ConsultationReturn singleton) は、
// 低 RAM 端末で Google マップ等の外部アプリ往復中に OS が Solara を kill すると
// 消える。コールド起動時に restore snapshot から復活させるため、
// ConsultationResumeState を JSON に往復させられることを固定する。
//
// 手書きの fromJson (ConsultationRequest / When / Scope / Point /
// ConsultationV2Reading.toJson) が toJson と正しく対になっているかを検証する。

import 'package:flutter_test/flutter_test.dart';
import 'package:solara/utils/consultation_return.dart';
import 'package:solara/utils/consultation_v2_api.dart';

ConsultationResumeState _sample() {
  final request = ConsultationRequest(
    birthDate: '1990-03-15',
    birthTime: '08:30',
    birthTimeUnknown: false,
    birthLat: 35.18,
    birthLng: 136.91,
    birthTz: 9,
    birthTzName: 'Asia/Tokyo',
    homeLat: 35.17,
    homeLng: 136.88,
    theme: 'love',
    mode: 'travel',
    when: ConsultationWhen.range('2026-07-01', '2026-07-05'),
    scope: ConsultationScope.point(const ConsultationPoint(
      lat: 34.69,
      lng: 135.50,
      name: 'JR大阪駅',
      placeType: 'train_station',
      placeKind: 'named',
    )),
    withWhom: 'パートナー',
    wish: '関係を深めたい',
    isFirst: false,
    excluded: const ['京都', '神戸'],
    avoid: const ['奈良'],
  );

  const candidate = ConsultationV2Candidate(
    name: '大阪',
    nameEN: 'Osaka',
    lat: 34.69,
    lng: 135.50,
    country: '日本',
    region: '近畿',
    directionFromHome: '西',
    directionCode: 'W',
    distanceKm: 137,
    characterHeadline: '出会いが弾む賑わいの地',
    energyLabels: ['金星 アングル・社交的', '木星 拡大'],
    narrative: 'ここでは…',
  );

  final reading = ConsultationV2Reading(
    isFirst: true,
    candidate: candidate,
    evidence: const ConsultationEvidence(),
    innerSeason: '芽吹きの季節',
    intro: 'はじめに',
    outro: 'おわりに',
    remainingAfter: 2,
    single: false,
    fallbackHonest: true,
    sparse: true,
    nearbyCount: 4,
    model: 'gemini',
    fallback: false,
  );

  return ConsultationResumeState(
    request: request,
    readings: [reading],
    avoid: const ['奈良'],
    recordSavedAt: DateTime.utc(2026, 6, 2, 1, 30),
    pageIndex: 1,
    scopeDetail: 'JR大阪駅',
  );
}

void main() {
  group('ConsultationResumeState JSON ラウンドトリップ', () {
    test('request / readings / avoid / メタ情報が往復で保持される', () {
      final restored =
          ConsultationResumeState.fromJson(_sample().toJson());

      // スカラー・メタ
      expect(restored.pageIndex, 1);
      expect(restored.scopeDetail, 'JR大阪駅');
      expect(restored.avoid, ['奈良']);
      expect(restored.recordSavedAt, DateTime.utc(2026, 6, 2, 1, 30));

      // request (誕生 / 自宅 / 5 問 / ページング)
      final r = restored.request;
      expect(r.birthDate, '1990-03-15');
      expect(r.birthTime, '08:30');
      expect(r.birthTimeUnknown, isFalse);
      expect(r.birthLat, closeTo(35.18, 1e-9));
      expect(r.birthTzName, 'Asia/Tokyo');
      expect(r.homeLat, closeTo(35.17, 1e-9));
      expect(r.theme, 'love');
      expect(r.mode, 'travel');
      expect(r.withWhom, 'パートナー');
      expect(r.wish, '関係を深めたい');
      expect(r.isFirst, isFalse); // 「別の候補地」継続に必須
      expect(r.excluded, ['京都', '神戸']);
      expect(r.avoid, ['奈良']);

      // when (range)
      expect(r.when?.kind, 'range');
      expect(r.when?.start, '2026-07-01');
      expect(r.when?.end, '2026-07-05');

      // scope (point + 具体地点メタ)
      expect(r.scope?.kind, 'point');
      expect(r.scope?.point?.name, 'JR大阪駅');
      expect(r.scope?.point?.placeType, 'train_station');
      expect(r.scope?.point?.placeKind, 'named');
      expect(r.scope?.point?.lat, closeTo(34.69, 1e-9));

      // readings (candidate + メタ)
      expect(restored.readings, hasLength(1));
      final rd = restored.readings.first;
      expect(rd.candidate.name, '大阪');
      expect(rd.candidate.energyLabels, ['金星 アングル・社交的', '木星 拡大']);
      expect(rd.candidate.characterHeadline, '出会いが弾む賑わいの地');
      expect(rd.innerSeason, '芽吹きの季節');
      expect(rd.remainingAfter, 2);
      expect(rd.fallbackHonest, isTrue);
      expect(rd.sparse, isTrue); // meta.sparse 経由
      expect(rd.nearbyCount, 4); // meta.nearbyCount 経由
      expect(rd.model, 'gemini');
    });

    test('ConsultationReturn capture → restore で pending が復活する', () {
      final cr = ConsultationReturn.instance;
      cr.clear();
      expect(cr.hasPending, isFalse);
      expect(cr.captureRestore(), isNull);

      cr.stash(_sample());
      final snap = cr.captureRestore();
      expect(snap, isNotNull);

      // プロセス死を模す: singleton を空にしてから snapshot で復元。
      cr.clear();
      expect(cr.hasPending, isFalse);

      cr.restoreFrom(snap!);
      expect(cr.hasPending, isTrue);
      expect(cr.pending?.pageIndex, 1);
      expect(cr.pending?.request.theme, 'love');
      expect(cr.pending?.readings.first.candidate.name, '大阪');
      cr.clear();
    });

    test('壊れた snapshot は握り潰して pending を出さない', () {
      final cr = ConsultationReturn.instance;
      cr.clear();
      cr.restoreFrom({'request': 'broken'}); // request が Map でない
      expect(cr.hasPending, isFalse);
    });
  });
}
