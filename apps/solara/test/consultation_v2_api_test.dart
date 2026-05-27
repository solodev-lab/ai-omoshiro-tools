// consultation_v2_api.dart — リクエスト契約 + レスポンス解析のユニットテスト。
//
// Phase 4 (Flutter API 層)。Worker /protected/astro/consultation2 の契約
// (apps/solara/worker/src/{consultation_engine,consultation_v2}.js) に
// Flutter 側のシリアライズ/デシリアライズが一致することを検証する。

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:solara/utils/consultation_api.dart' show ConsultationBlock;
import 'package:solara/utils/consultation_v2_api.dart';
import 'package:solara/utils/solara_storage.dart' show SolaraProfile;

http.Client _jsonClient(Map<String, dynamic> body, {int status = 200}) {
  return MockClient((_) async => http.Response.bytes(
        utf8.encode(json.encode(body)),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ));
}

ConsultationRequest _baseRequest({
  String? birthTime = '08:30',
  bool birthTimeUnknown = false,
  ConsultationWhen? when,
  ConsultationScope? scope,
  String withWhom = '',
  String wish = '',
  bool isFirst = true,
  List<String> excluded = const [],
}) {
  return ConsultationRequest(
    birthDate: '1990-04-12',
    birthTime: birthTime,
    birthTimeUnknown: birthTimeUnknown,
    birthLat: 35.68,
    birthLng: 139.76,
    birthTz: 9,
    birthTzName: 'Asia/Tokyo',
    homeLat: 35.17,
    homeLng: 136.88,
    theme: 'love',
    mode: 'travel',
    when: when,
    scope: scope,
    withWhom: withWhom,
    wish: wish,
    isFirst: isFirst,
    excluded: excluded,
  );
}

void main() {
  group('ConsultationRequest.toJson — 契約', () {
    test('birth: 時刻ありは time を含み timeUnknown=false', () {
      final j = _baseRequest().toJson();
      final birth = j['birth'] as Map<String, dynamic>;
      expect(birth['date'], '1990-04-12');
      expect(birth['time'], '08:30');
      expect(birth['timeUnknown'], false);
      expect(birth['lat'], 35.68);
      expect(birth['tz'], 9);
      expect(birth['tzName'], 'Asia/Tokyo');
    });

    test('birth: 時刻不明は time キーを省略し timeUnknown=true', () {
      final j = _baseRequest(birthTime: null, birthTimeUnknown: true).toJson();
      final birth = j['birth'] as Map<String, dynamic>;
      expect(birth.containsKey('time'), isFalse);
      expect(birth['timeUnknown'], true);
    });

    test('home は lat/lng のみ', () {
      final home = _baseRequest().toJson()['home'] as Map<String, dynamic>;
      expect(home.keys.toSet(), {'lat', 'lng'});
      expect(home['lat'], 35.17);
    });

    test('when=null は when キーを省略', () {
      expect(_baseRequest().toJson().containsKey('when'), isFalse);
    });

    test('when.onDate → {kind:date, date}', () {
      final w = _baseRequest(when: ConsultationWhen.onDate('2026-08-01'))
          .toJson()['when'] as Map<String, dynamic>;
      expect(w['kind'], 'date');
      expect(w['date'], '2026-08-01');
      expect(w.containsKey('start'), isFalse);
    });

    test('when.range → {kind:range, start, end}', () {
      final w = _baseRequest(
        when: ConsultationWhen.range('2026-08-01', '2026-08-10'),
      ).toJson()['when'] as Map<String, dynamic>;
      expect(w['kind'], 'range');
      expect(w['start'], '2026-08-01');
      expect(w['end'], '2026-08-10');
    });

    test('when.horizon → kind のみ (移住ホライズン)', () {
      final w = _baseRequest(when: ConsultationWhen.horizon('within1yr'))
          .toJson()['when'] as Map<String, dynamic>;
      expect(w['kind'], 'within1yr');
      expect(w.containsKey('date'), isFalse);
    });

    test('scope.point は座標 + 任意の name/placeType', () {
      final s = _baseRequest(
        scope: ConsultationScope.point(const ConsultationPoint(
          lat: 35.0,
          lng: 135.0,
          name: '喫茶ソラ',
          placeType: 'cafe',
        )),
      ).toJson()['scope'] as Map<String, dynamic>;
      expect(s['kind'], 'point');
      final p = s['point'] as Map<String, dynamic>;
      expect(p['lat'], 35.0);
      expect(p['name'], '喫茶ソラ');
      expect(p['placeType'], 'cafe');
    });

    test('scope.point 座標のみは name/placeType を省略', () {
      final s = _baseRequest(
        scope: ConsultationScope.point(
            const ConsultationPoint(lat: 1.0, lng: 2.0)),
      ).toJson()['scope'] as Map<String, dynamic>;
      final p = s['point'] as Map<String, dynamic>;
      expect(p.keys.toSet(), {'lat', 'lng'});
    });

    test('scope.world / radius / region', () {
      expect(
        (_baseRequest(scope: ConsultationScope.world()).toJson()['scope']
            as Map)['kind'],
        'world',
      );
      final r = _baseRequest(scope: ConsultationScope.radius(300))
          .toJson()['scope'] as Map<String, dynamic>;
      expect(r['kind'], 'radius');
      expect(r['radiusKm'], 300);
      final reg = _baseRequest(scope: ConsultationScope.region('日本'))
          .toJson()['scope'] as Map<String, dynamic>;
      expect(reg['regionGroup'], '日本');
    });

    test('withWhom/wish は空なら省略、非空なら含む', () {
      expect(_baseRequest().toJson().containsKey('withWhom'), isFalse);
      expect(_baseRequest().toJson().containsKey('wish'), isFalse);
      final j = _baseRequest(withWhom: '妻と', wish: '穏やかに過ごしたい').toJson();
      expect(j['withWhom'], '妻と');
      expect(j['wish'], '穏やかに過ごしたい');
    });

    test('excluded は空なら省略、非空なら含む / isFirst は常に含む', () {
      final j0 = _baseRequest().toJson();
      expect(j0.containsKey('excluded'), isFalse);
      expect(j0['isFirst'], true);
      final j1 = _baseRequest(excluded: ['東京'], isFirst: false).toJson();
      expect(j1['excluded'], ['東京']);
      expect(j1['isFirst'], false);
    });

    test('fromProfile: 時刻なしプロフィールは timeUnknown を導出', () {
      const profile = SolaraProfile(
        birthDate: '1988-12-01',
        birthTime: '',
        birthTimeUnknown: false, // time 空でも unknown 扱いになること
        birthLat: 34.0,
        birthLng: 135.0,
        birthTz: 9,
        homeLat: 35.0,
        homeLng: 139.0,
      );
      final req = ConsultationRequest.fromProfile(
        profile,
        theme: 'work',
        mode: 'migration',
      );
      expect(req.birthTimeUnknown, isTrue);
      expect(req.birthTime, isNull);
      final birth = req.toJson()['birth'] as Map<String, dynamic>;
      expect(birth.containsKey('time'), isFalse);
      expect(birth['timeUnknown'], true);
    });

    test('copyWith: excluded/isFirst だけ差し替え (別の候補地)', () {
      final first = _baseRequest();
      final next = first.copyWith(isFirst: false, excluded: ['京都']);
      expect(next.isFirst, isFalse);
      expect(next.excluded, ['京都']);
      expect(next.theme, first.theme);
      expect(next.when, first.when);
    });
  });

  group('fetchConsultationV2 — レスポンス解析', () {
    test('200 成功: 候補 + エビデンス + 初回枠 + 残数を解析', () async {
      final client = _jsonClient({
        'isFirst': true,
        'innerSeason': '今のあなたは根に意識が向かう内的な季節',
        'intro': '導入の言葉',
        'outro': '締めの言葉',
        'candidate': {
          'name': '京都',
          'nameEN': 'Kyoto',
          'lat': 35.01,
          'lng': 135.76,
          'country': 'JP',
          'region': '近畿',
          'characterHeadline': '愛の軸が立つ場',
          'energyLabels': ['金星 MC・愛と調和の軸', '火星 ASC・突破の身体性'],
          'narrative': 'この土地には金星のエネルギーが流れている。',
          'timeWindow': {'kind': 'single', 'bucket': 'evening', 'label': '夜'},
        },
        'evidence': {
          'factors': ['金星MC合', '進行の月: 蟹座4室'],
          'km': [
            {'factor': '金星MC合', 'km': 120}
          ],
          'note': null,
        },
        'remainingAfter': 2,
        'single': false,
        'fallbackHonest': false,
        'timeWindow': {'kind': 'single', 'bucket': 'evening', 'label': '夜'},
        'model': 'gemini-2.5-flash',
        'freeCreditsRemaining': 2,
        'freeCreditsLimit': 3,
        'purchasedBalance': 0,
      });
      final res = await fetchConsultationV2(_baseRequest(), client: client);
      expect(res.isSuccess, isTrue);
      expect(res.isExhausted, isFalse);
      final r = res.reading!;
      expect(r.isFirst, isTrue);
      expect(r.innerSeason, contains('内的な季節'));
      expect(r.intro, '導入の言葉');
      expect(r.candidate.name, '京都');
      expect(r.candidate.characterHeadline, '愛の軸が立つ場');
      expect(r.candidate.energyLabels.length, 2);
      expect(r.candidate.timeWindow?.kind, 'single');
      expect(r.candidate.timeWindow?.label, '夜');
      expect(r.evidence.factors, contains('金星MC合'));
      expect(r.evidence.km.first.km, 120);
      expect(r.evidence.note, isNull);
      expect(r.remainingAfter, 2);
      expect(r.fallback, isFalse);
      expect(res.freeCreditsRemaining, 2);
      expect(res.freeCreditsLimit, 3);
    });

    test('200 exhausted: これ以上候補なし', () async {
      final client = _jsonClient({
        'exhausted': true,
        'remainingAfter': 0,
        'meta': {'mode': 'travel'},
        'freeCreditsRemaining': 1,
        'freeCreditsLimit': 3,
      });
      final res = await fetchConsultationV2(
        _baseRequest(isFirst: false, excluded: ['京都', '大阪']),
        client: client,
      );
      expect(res.isExhausted, isTrue);
      expect(res.isSuccess, isFalse);
      expect(res.isNetworkError, isFalse);
      expect(res.freeCreditsRemaining, 1);
    });

    test('200 rhythm timeWindow (旅行の朝昼夜) を解析', () async {
      final client = _jsonClient({
        'isFirst': false,
        'candidate': {
          'lat': 1.0,
          'lng': 2.0,
          'characterHeadline': 'h',
          'energyLabels': [],
          'narrative': 'n',
          'timeWindow': {
            'kind': 'rhythm',
            'items': [
              {'bucket': 'morning', 'label': '朝'},
              {'bucket': 'evening', 'label': '夜'},
            ],
          },
        },
        'evidence': {'factors': [], 'km': []},
        'remainingAfter': 0,
        'model': 'm',
      });
      final res = await fetchConsultationV2(_baseRequest(), client: client);
      final tw = res.reading!.candidate.timeWindow!;
      expect(tw.kind, 'rhythm');
      expect(tw.items.length, 2);
      expect(tw.items.first.label, '朝');
    });

    test('200 静的 fallback (fallback=true) も成功として扱う', () async {
      final client = _jsonClient({
        'isFirst': true,
        'candidate': {
          'lat': 1.0,
          'lng': 2.0,
          'characterHeadline': '静かな場',
          'energyLabels': [],
          'narrative': 'n',
        },
        'evidence': {'factors': [], 'km': []},
        'remainingAfter': 0,
        'fallback': true,
        'model': 'fallback',
      });
      final res = await fetchConsultationV2(_baseRequest(), client: client);
      expect(res.isSuccess, isTrue);
      expect(res.reading!.fallback, isTrue);
    });

    test('402: error コードをブロック理由にマップ', () async {
      final client = _jsonClient(
        {'error': 'consultation_credit_exhausted'},
        status: 402,
      );
      final res = await fetchConsultationV2(_baseRequest(), client: client);
      expect(res.isBlocked, isTrue);
      expect(res.block, ConsultationBlock.creditExhausted);
      expect(res.isNetworkError, isFalse);
    });

    test('402: 未知コードは unknown', () async {
      final client = _jsonClient({'error': 'something_new'}, status: 402);
      final res = await fetchConsultationV2(_baseRequest(), client: client);
      expect(res.block, ConsultationBlock.unknown);
    });

    test('402: consultation_pro_weekly_exhausted を proWeeklyExhausted にマップ',
        () async {
      final client = _jsonClient(
        {
          'error': 'consultation_pro_weekly_exhausted',
          'proRemaining': 0,
          'proLimit': 100,
          'weekBucket': '2026-W22',
        },
        status: 402,
      );
      final res = await fetchConsultationV2(_baseRequest(), client: client);
      expect(res.isBlocked, isTrue);
      expect(res.block, ConsultationBlock.proWeeklyExhausted);
    });

    test('200 Pro 成功: proCreditsRemaining/proCreditsLimit を解析', () async {
      final client = _jsonClient({
        'isFirst': true,
        'candidate': {
          'lat': 1.0,
          'lng': 2.0,
          'characterHeadline': 'h',
          'energyLabels': [],
          'narrative': 'n',
        },
        'evidence': {'factors': [], 'km': []},
        'remainingAfter': 0,
        'model': 'm',
        // Pro レスポンス: freeCredits* は null、proCredits* に値
        'isPro': true,
        'freeCreditsRemaining': null,
        'freeCreditsLimit': null,
        'proCreditsRemaining': 87,
        'proCreditsLimit': 100,
        'weekBucket': '2026-W22',
        'purchasedBalance': 4,
      });
      final res = await fetchConsultationV2(_baseRequest(), client: client);
      expect(res.isSuccess, isTrue);
      expect(res.proCreditsRemaining, 87);
      expect(res.proCreditsLimit, 100);
      expect(res.purchasedBalance, 4);
      expect(res.freeCreditsRemaining, isNull);
      expect(res.freeCreditsLimit, isNull);
    });

    test('500: ネットワーク/サーバーエラーは isNetworkError', () async {
      final client = MockClient((_) async => http.Response('boom', 500));
      final res = await fetchConsultationV2(_baseRequest(), client: client);
      expect(res.isNetworkError, isTrue);
      expect(res.isSuccess, isFalse);
      expect(res.isBlocked, isFalse);
    });

    test('リクエスト body に birth/theme/mode が載る', () async {
      Map<String, dynamic>? sent;
      final client = MockClient((req) async {
        sent = json.decode(req.body) as Map<String, dynamic>;
        return http.Response.bytes(
          utf8.encode(json.encode({
            'isFirst': true,
            'candidate': {
              'lat': 0,
              'lng': 0,
              'characterHeadline': '',
              'energyLabels': [],
              'narrative': ''
            },
            'evidence': {'factors': [], 'km': []},
            'remainingAfter': 0,
            'model': 'm',
          })),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      await fetchConsultationV2(
        _baseRequest(when: ConsultationWhen.onDate('2026-08-01')),
        client: client,
      );
      expect(sent, isNotNull);
      expect(sent!['theme'], 'love');
      expect(sent!['mode'], 'travel');
      expect((sent!['birth'] as Map)['date'], '1990-04-12');
      expect((sent!['when'] as Map)['date'], '2026-08-01');
    });
  });
}
