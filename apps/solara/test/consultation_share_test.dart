// Widget / unit test: Phase 2-5 シェアエクスポート
//
// 検証範囲:
//   - formatConsultationAsText: ConsultationReading → plain text 整形が
//     intro / candidates / outro / メタ / ハッシュタグ全部入りで返す
//   - formatConsultationCaption: 画像同梱用の短いキャプション整形
//   - ConsultationResultScreen: AppBar に share アイコンが表示される

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:solara/screens/consultation/consultation_result_screen.dart';
import 'package:solara/utils/consultation_api.dart';
import 'package:solara/utils/consultation_engine.dart';
import 'package:solara/utils/consultation_share.dart';

ConsultationReading _sampleReading() {
  return const ConsultationReading(
    intro: 'モック intro テキスト',
    candidates: [
      ConsultationCandidateReading(
        name: '京都',
        energyLabels: ['金星 MC・愛と調和の軸', '月 DSC・対人の流れ'],
        narrative: '京都のモック narrative 本文',
      ),
      ConsultationCandidateReading(
        name: '札幌',
        energyLabels: ['火星 ASC・突破の身体性'],
        narrative: '札幌のモック narrative 本文',
      ),
    ],
    outro: '見えていない最高がある — outro テキスト',
    model: 'gemini-2.5-flash',
    fallback: false,
  );
}

CandidateLocation _sampleCand(String name) => CandidateLocation(
      nameJP: name,
      nameEN: name,
      lat: 35.0,
      lng: 135.0,
      country: 'JP',
      region: '',
      population: 0,
      nearLines: const [
        CandidateNearLine(
          planet: 'venus',
          angle: 'mc',
          aspect: 'conjunction',
          distanceKm: 10,
        ),
      ],
    );

void main() {
  group('formatConsultationAsText', () {
    test('intro / 各候補 / outro / メタ / ハッシュタグが全部入る', () {
      final text = formatConsultationAsText(
        theme: 'love',
        mode: 'travel',
        scope: 'world',
        freeText: '近くの人とのつながりを深めたい',
        reading: _sampleReading(),
      );

      expect(text, contains('Solara · Stella による相談'));
      expect(text, contains('恋愛・関係'));
      expect(text, contains('旅行'));
      expect(text, contains('世界全体'));
      expect(text, contains('近くの人とのつながりを深めたい'));
      expect(text, contains('モック intro テキスト'));
      expect(text, contains('京都'));
      expect(text, contains('札幌'));
      expect(text, contains('金星 MC・愛と調和の軸'));
      expect(text, contains('京都のモック narrative 本文'));
      expect(text, contains('札幌のモック narrative 本文'));
      expect(text, contains('見えていない最高がある'));
      expect(text, contains('#Solara'));
      expect(text, contains('#Stella'));
    });

    test('freeText 空のときは自由記述行を出さない', () {
      final text = formatConsultationAsText(
        theme: 'love',
        mode: 'travel',
        scope: 'world',
        freeText: '',
        reading: _sampleReading(),
      );
      expect(text, isNot(contains('自由記述:')));
    });

    test('未知の theme/mode/scope はキーをそのまま出す (fallback)', () {
      final text = formatConsultationAsText(
        theme: 'unknown',
        mode: 'unknown',
        scope: 'unknown',
        freeText: '',
        reading: _sampleReading(),
      );
      expect(text, contains('テーマ: unknown'));
      expect(text, contains('モード: unknown'));
      expect(text, contains('範囲: unknown'));
    });

    test('candidates 空でも intro/outro/ハッシュタグは出る', () {
      const empty = ConsultationReading(
        intro: 'intro only',
        candidates: [],
        outro: 'outro only',
        model: 'm',
        fallback: false,
      );
      final text = formatConsultationAsText(
        theme: 'love',
        mode: 'travel',
        scope: 'world',
        freeText: '',
        reading: empty,
      );
      expect(text, contains('intro only'));
      expect(text, contains('outro only'));
      expect(text, contains('#Solara'));
    });
  });

  group('formatConsultationCaption', () {
    test('テーマ + 候補名 + ハッシュタグが入る (画像同梱用の短文)', () {
      final caption = formatConsultationCaption(
        theme: 'love',
        reading: _sampleReading(),
      );
      expect(caption, contains('恋愛・関係'));
      expect(caption, contains('Stella'));
      expect(caption, contains('京都'));
      expect(caption, contains('札幌'));
      expect(caption, contains('#Solara'));
    });

    test('candidates 空でも崩れずに返す', () {
      const empty = ConsultationReading(
        intro: '',
        candidates: [],
        outro: '',
        model: '',
        fallback: false,
      );
      final caption = formatConsultationCaption(theme: 'love', reading: empty);
      expect(caption, contains('恋愛・関係'));
      expect(caption, isNot(contains('候補:')));
    });
  });

  group('ConsultationResultScreen share action', () {
    testWidgets('結果ロード完了後、AppBar の share アイコンが活性化する',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConsultationResultScreen(
            theme: 'love',
            mode: 'travel',
            scope: 'world',
            initialCandidates: [_sampleCand('京都')],
            fetchOverride: ({
              required theme,
              required mode,
              required scope,
              required candidates,
              String freeText = '',
              List<String> excluded = const [],
            }) async =>
                _sampleReading(),
            autoSave: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final shareIconBtnFinder = find.ancestor(
        of: find.byIcon(Icons.ios_share),
        matching: find.byType(IconButton),
      );
      expect(shareIconBtnFinder, findsOneWidget);
      final iconBtn = tester.widget<IconButton>(shareIconBtnFinder);
      expect(iconBtn.onPressed, isNotNull, reason: 'reading ロード後は活性化');
    });

    testWidgets('share アイコンタップで bottom sheet が出る (テキスト / 画像 2 択)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConsultationResultScreen(
            theme: 'love',
            mode: 'travel',
            scope: 'world',
            initialCandidates: [_sampleCand('京都')],
            fetchOverride: ({
              required theme,
              required mode,
              required scope,
              required candidates,
              String freeText = '',
              List<String> excluded = const [],
            }) async =>
                _sampleReading(),
            autoSave: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final shareIconBtnFinder = find.ancestor(
        of: find.byIcon(Icons.ios_share),
        matching: find.byType(IconButton),
      );
      await tester.tap(shareIconBtnFinder);
      await tester.pumpAndSettle();

      expect(find.text('テキストをコピー'), findsOneWidget);
      expect(find.text('画像で共有'), findsOneWidget);
    });
  });
}
