// Widget / unit test: シェアエクスポート (V2)
//
// 検証範囲:
//   - formatConsultationAsText: 候補群 + 枠 → plain text 整形
//   - formatConsultationCaption: 画像同梱用の短いキャプション整形
//   - ConsultationResultScreen: AppBar の share アイコン (Pro ゲート含む)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:solara/screens/consultation/consultation_result_screen.dart';
import 'package:solara/utils/consultation_share.dart';
import 'package:solara/utils/consultation_v2_api.dart';
import 'package:solara/utils/pro_status.dart';

List<ConsultationV2Candidate> _candidates() => const [
      ConsultationV2Candidate(
        name: '京都',
        lat: 35,
        lng: 135.7,
        characterHeadline: '愛の軸が立つ場',
        energyLabels: ['金星 MC・愛と調和の軸', '月 DSC・対人の流れ'],
        narrative: '京都のモック narrative 本文',
      ),
      ConsultationV2Candidate(
        name: '札幌',
        lat: 43,
        lng: 141,
        characterHeadline: '突破の場',
        energyLabels: ['火星 ASC・突破の身体性'],
        narrative: '札幌のモック narrative 本文',
      ),
    ];

const _evidences = <ConsultationEvidence>[
  ConsultationEvidence(factors: ['金星MC合']),
  ConsultationEvidence(factors: ['火星ASCトライン']),
];

ConsultationRequest _req() => const ConsultationRequest(
      birthDate: '1990-01-01',
      birthTime: '12:00',
      birthTimeUnknown: false,
      birthLat: 0,
      birthLng: 0,
      birthTz: 9,
      birthTzName: null,
      homeLat: 0,
      homeLng: 0,
      theme: 'love',
      mode: 'travel',
    );

ConsultationV2Result _result() => ConsultationV2Result(
      reading: ConsultationV2Reading(
        isFirst: true,
        candidate: _candidates().first,
        evidence: _evidences.first,
        innerSeason: 'モック季節',
        intro: 'モック intro テキスト',
        outro: '見えていない最高がある',
        remainingAfter: 0,
      ),
    );

void main() {
  group('formatConsultationAsText', () {
    test('枠 / 各候補 / メタ / ハッシュタグが入る', () {
      final text = formatConsultationAsText(
        theme: 'love',
        mode: 'travel',
        scopeKind: 'world',
        withWhom: '妻と',
        wish: '近くの人とのつながりを深めたい',
        innerSeason: 'モック季節',
        intro: 'モック intro テキスト',
        outro: '見えていない最高がある',
        candidates: _candidates(),
        evidences: _evidences,
      );
      expect(text, contains('Solara · Stella による相談'));
      expect(text, contains('恋愛・関係'));
      expect(text, contains('旅行'));
      expect(text, contains('世界全体'));
      expect(text, contains('だれと: 妻と'));
      expect(text, contains('近くの人とのつながりを深めたい'));
      expect(text, contains('モック intro テキスト'));
      expect(text, contains('京都'));
      expect(text, contains('札幌'));
      expect(text, contains('金星 MC・愛と調和の軸'));
      expect(text, contains('京都のモック narrative 本文'));
      expect(text, contains('見えていない最高がある'));
      expect(text, contains('#Solara'));
      expect(text, contains('#Stella'));
    });

    test('withWhom/wish 空のときは行を出さない', () {
      final text = formatConsultationAsText(
        theme: 'love',
        mode: 'travel',
        scopeKind: 'world',
        candidates: _candidates(),
        evidences: _evidences,
      );
      expect(text, isNot(contains('だれと:')));
      expect(text, isNot(contains('願い:')));
    });

    test('未知の theme/mode/scope はキーをそのまま出す', () {
      final text = formatConsultationAsText(
        theme: 'unknown',
        mode: 'unknown',
        scopeKind: 'unknown',
        candidates: _candidates(),
        evidences: _evidences,
      );
      expect(text, contains('テーマ: unknown'));
      expect(text, contains('場面: unknown'));
      expect(text, contains('範囲: unknown'));
    });
  });

  group('formatConsultationCaption', () {
    test('テーマ + 候補名 + ハッシュタグ', () {
      final caption =
          formatConsultationCaption(theme: 'love', candidates: _candidates());
      expect(caption, contains('恋愛・関係'));
      expect(caption, contains('Stella'));
      expect(caption, contains('京都'));
      expect(caption, contains('札幌'));
      expect(caption, contains('#Solara'));
    });

    test('candidates 空でも崩れない', () {
      final caption =
          formatConsultationCaption(theme: 'love', candidates: const []);
      expect(caption, contains('恋愛・関係'));
      expect(caption, isNot(contains('候補:')));
    });
  });

  group('ConsultationResultScreen share action', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ProStatus.instance.resetForTest(isPro: true);
    });

    testWidgets('結果ロード後 share アイコンが活性化', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ConsultationResultScreen(
          request: _req(),
          fetchOverride: (req) async => _result(),
        ),
      ));
      await tester.pumpAndSettle();

      final finder = find.ancestor(
        of: find.byIcon(Icons.ios_share),
        matching: find.byType(IconButton),
      );
      expect(finder, findsOneWidget);
      expect(tester.widget<IconButton>(finder).onPressed, isNotNull);
    });

    testWidgets('share タップで bottom sheet (テキスト/画像)', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ConsultationResultScreen(
          request: _req(),
          fetchOverride: (req) async => _result(),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.ancestor(
        of: find.byIcon(Icons.ios_share),
        matching: find.byType(IconButton),
      ));
      await tester.pumpAndSettle();
      expect(find.text('テキストをコピー'), findsOneWidget);
      expect(find.text('画像で共有'), findsOneWidget);
    });
  });

  group('ConsultationResultScreen share Pro gate', () {
    testWidgets('Free は share タップで Pro 案内 (sheet は出ない)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await ProStatus.instance.resetForTest(isPro: false);

      await tester.pumpWidget(MaterialApp(
        home: ConsultationResultScreen(
          request: _req(),
          fetchOverride: (req) async => _result(),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.ancestor(
        of: find.byIcon(Icons.ios_share),
        matching: find.byType(IconButton),
      ));
      await tester.pumpAndSettle();

      expect(find.text('✦ Cosmic Pro'), findsOneWidget);
      expect(find.text('テキストをコピー'), findsNothing);
      expect(find.text('画像で共有'), findsNothing);
    });
  });
}
