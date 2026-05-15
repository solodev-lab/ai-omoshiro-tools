// Widget test: ConsultationHistoryScreen + 自動保存 (Phase 2-4)
//
// Worker は呼ばない (fetchOverride + loadOverride/deleteOverride で差替)。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:solara/screens/consultation/consultation_history_screen.dart';
import 'package:solara/screens/consultation/consultation_result_screen.dart';
import 'package:solara/utils/consultation_api.dart';
import 'package:solara/utils/consultation_engine.dart';
import 'package:solara/utils/consultation_record.dart';
import 'package:solara/utils/solara_storage.dart';

ConsultationReading _mockReading(List<CandidateLocation> cands) {
  return ConsultationReading(
    intro: 'モック intro',
    candidates: [
      for (final c in cands)
        ConsultationCandidateReading(
          name: c.nameJP,
          energyLabels: const ['金星 MC・愛の軸'],
          narrative: '${c.nameJP} のモック narrative',
        ),
    ],
    outro: '世界の全部ではありません',
    model: 'mock',
    fallback: false,
  );
}

ConsultationRecord _sampleRecord({
  String id = '1',
  String theme = 'love',
  String firstName = '京都',
  String country = 'JP',
  String region = '京都府',
  String scope = 'specific',
  String? scopeDetail,
  DateTime? savedAt,
}) {
  final cand = CandidateLocation(
    nameJP: firstName,
    nameEN: 'Kyoto',
    lat: 35.0,
    lng: 135.7,
    country: country,
    region: region,
    population: 1463000,
    nearLines: const [
      CandidateNearLine(
        planet: 'venus',
        angle: 'mc',
        aspect: 'conjunction',
        distanceKm: 12,
      ),
    ],
  );
  final reading = ConsultationReading(
    intro: 'テスト intro',
    candidates: [
      ConsultationCandidateReading(
        name: firstName,
        energyLabels: const ['金星 MC・愛の軸'],
        narrative: '$firstName のテスト narrative',
      ),
    ],
    outro: '世界の全部ではありません',
    model: 'mock',
    fallback: false,
  );
  return ConsultationRecord(
    id: id,
    savedAt: savedAt ?? DateTime.utc(2026, 5, 15, 10),
    theme: theme,
    mode: 'travel',
    scope: scope,
    scopeDetail: scopeDetail,
    freeText: '',
    candidates: [cand],
    reading: reading,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ConsultationRecord JSON roundtrip', () {
    test('encode → decode が同じ内容を返す', () {
      final original = _sampleRecord();
      final json = original.toJson();
      final restored = ConsultationRecord.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.theme, original.theme);
      expect(restored.mode, original.mode);
      expect(restored.scope, original.scope);
      expect(restored.candidates.length, original.candidates.length);
      expect(restored.candidates.first.nameJP, original.candidates.first.nameJP);
      expect(restored.reading.intro, original.reading.intro);
      expect(restored.reading.candidates.first.narrative,
          original.reading.candidates.first.narrative);
    });
  });

  group('SolaraStorage consultation history', () {
    testWidgets('add → load で 1 件取れる', (tester) async {
      final rec = _sampleRecord();
      await SolaraStorage.addConsultationRecord(rec);
      final loaded = await SolaraStorage.loadConsultationHistory();
      expect(loaded.length, 1);
      expect(loaded.first.id, rec.id);
    });

    testWidgets('複数件追加で新しい順に並ぶ', (tester) async {
      final old = _sampleRecord(
        id: 'old',
        savedAt: DateTime.utc(2026, 5, 10),
      );
      final newer = _sampleRecord(
        id: 'new',
        savedAt: DateTime.utc(2026, 5, 15),
      );
      await SolaraStorage.addConsultationRecord(old);
      await SolaraStorage.addConsultationRecord(newer);
      final loaded = await SolaraStorage.loadConsultationHistory();
      expect(loaded.length, 2);
      expect(loaded.first.id, 'new');
      expect(loaded.last.id, 'old');
    });

    testWidgets('delete で 1 件消える', (tester) async {
      final a = _sampleRecord(id: 'a');
      final b = _sampleRecord(
        id: 'b',
        savedAt: DateTime.utc(2026, 5, 16),
      );
      await SolaraStorage.addConsultationRecord(a);
      await SolaraStorage.addConsultationRecord(b);
      await SolaraStorage.deleteConsultationRecord('a');
      final loaded = await SolaraStorage.loadConsultationHistory();
      expect(loaded.length, 1);
      expect(loaded.first.id, 'b');
    });

    testWidgets('clear で全件消える', (tester) async {
      await SolaraStorage.addConsultationRecord(_sampleRecord(id: '1'));
      await SolaraStorage.addConsultationRecord(_sampleRecord(id: '2'));
      await SolaraStorage.clearConsultationHistory();
      final loaded = await SolaraStorage.loadConsultationHistory();
      expect(loaded, isEmpty);
    });
  });

  testWidgets('Result screen auto-saves on fetch success', (tester) async {
    final cand = CandidateLocation(
      nameJP: 'テスト都市',
      nameEN: 'Test City',
      lat: 35.0,
      lng: 135.0,
      country: 'JP',
      region: 'テスト',
      population: 100000,
      nearLines: const [
        CandidateNearLine(
          planet: 'venus',
          angle: 'mc',
          aspect: 'conjunction',
          distanceKm: 5,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ConsultationResultScreen(
          theme: 'love',
          mode: 'travel',
          scope: 'world',
          initialCandidates: [cand],
          fetchOverride: ({
            required theme,
            required mode,
            required scope,
            required candidates,
            String freeText = '',
            List<String> excluded = const [],
          }) async =>
              _mockReading(candidates),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 保存されている
    final saved = await SolaraStorage.loadConsultationHistory();
    expect(saved.length, 1);
    expect(saved.first.theme, 'love');
    expect(saved.first.candidates.first.nameJP, 'テスト都市');
  });

  testWidgets('Result screen does NOT save when autoSave=false (history mode)',
      (tester) async {
    final cand = CandidateLocation(
      nameJP: 'テスト',
      nameEN: 'Test',
      lat: 35,
      lng: 135,
      country: 'JP',
      region: '',
      population: 0,
      nearLines: const [],
    );
    final reading = _mockReading([cand]);

    await tester.pumpWidget(
      MaterialApp(
        home: ConsultationResultScreen(
          theme: 'love',
          mode: 'travel',
          scope: 'world',
          initialCandidates: [cand],
          initialReading: reading,
          autoSave: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final saved = await SolaraStorage.loadConsultationHistory();
    expect(saved, isEmpty,
        reason: '履歴モード (initialReading + autoSave:false) は保存しない');
  });

  testWidgets('History screen renders empty state when no records',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ConsultationHistoryScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('まだ相談履歴はありません'), findsOneWidget);
  });

  testWidgets('History screen lists records with theme prefix + mode/scope icons',
      (tester) async {
    final rec1 = _sampleRecord(id: '1', firstName: '京都');
    final rec2 = _sampleRecord(
      id: '2',
      theme: 'work',
      firstName: '札幌',
      savedAt: DateTime.utc(2026, 5, 16),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ConsultationHistoryScreen(
          loadOverride: () async => [rec2, rec1],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 新しい順 (rec2 = 札幌 が上)
    expect(find.text('札幌'), findsOneWidget);
    expect(find.text('京都'), findsOneWidget);

    // テーマ chip は「・」の前の prefix だけ表示 (履歴画面ローカル仕様)
    expect(find.text('恋愛'), findsOneWidget);
    expect(find.text('仕事'), findsOneWidget);
    // 「・」を含むフルラベルは表示されない (履歴画面の compact 表示)
    expect(find.text('恋愛・関係'), findsNothing);
    expect(find.text('仕事・キャリア'), findsNothing);

    // モード/スコープはアイコン化されている (mode='travel' / scope='specific')
    expect(find.byIcon(Icons.flight_outlined), findsNWidgets(2));
    expect(find.byIcon(Icons.location_on_outlined), findsNWidgets(2));
  });

  testWidgets('History card shows region scopeDetail next to scope icon',
      (tester) async {
    final rec = _sampleRecord(
      scope: 'region',
      scopeDetail: '日本',
      // region scope では候補は複数だが、テストでは 1 件で十分。
      // scopeDetail のラベル表示を確認するのが主目的。
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ConsultationHistoryScreen(
          loadOverride: () async => [rec],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.crop_din_outlined), findsOneWidget);
    expect(find.text('日本'), findsOneWidget);
  });

  testWidgets('History card shows specific address (region/country) next to scope icon',
      (tester) async {
    final rec = _sampleRecord(
      scope: 'specific',
      country: 'JP',
      region: '京都府',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ConsultationHistoryScreen(
          loadOverride: () async => [rec],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    // candidates[0].region と country が " / " 区切りで表示される
    expect(find.text('京都府 / JP'), findsOneWidget);
  });

  test('ConsultationRecord scopeDetail JSON roundtrip', () {
    final original = _sampleRecord(scope: 'region', scopeDetail: '北米');
    final restored = ConsultationRecord.fromJson(original.toJson());
    expect(restored.scopeDetail, '北米');

    // 旧データ互換: scopeDetail を含まない JSON は null で復元
    final legacyJson = Map<String, dynamic>.from(original.toJson())
      ..remove('scopeDetail');
    final legacy = ConsultationRecord.fromJson(legacyJson);
    expect(legacy.scopeDetail, isNull);
  });

  testWidgets('History screen tap opens result screen in read-only mode',
      (tester) async {
    final rec = _sampleRecord();

    await tester.pumpWidget(
      MaterialApp(
        home: ConsultationHistoryScreen(
          loadOverride: () async => [rec],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 行タップ
    await tester.tap(find.text('京都'));
    await tester.pumpAndSettle();

    // ConsultationResultScreen が開いた
    expect(find.text('相談の結果'), findsOneWidget);
    expect(find.textContaining('テスト intro'), findsOneWidget);
  });
}
