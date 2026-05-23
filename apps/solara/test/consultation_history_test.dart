// Widget test: ConsultationHistoryScreen + 自動保存 (V2)
//
// Worker は呼ばない (fetchOverride + loadOverride で差替)。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:solara/screens/consultation/consultation_history_screen.dart';
import 'package:solara/screens/consultation/consultation_result_screen.dart';
import 'package:solara/utils/consultation_record.dart';
import 'package:solara/utils/consultation_v2_api.dart';
import 'package:solara/utils/solara_storage.dart';

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

ConsultationV2Result _mockResult(String name) => ConsultationV2Result(
      reading: ConsultationV2Reading(
        isFirst: true,
        candidate: ConsultationV2Candidate(
          name: name,
          lat: 35,
          lng: 135,
          characterHeadline: '見出し',
          energyLabels: const ['金星 MC・愛の軸'],
          narrative: '$name のモック narrative',
        ),
        evidence: const ConsultationEvidence(factors: ['金星MC合']),
        innerSeason: 'モック季節',
        intro: 'モック intro',
        outro: '世界の全部ではありません',
        remainingAfter: 0,
      ),
    );

ConsultationRecord _sampleRecord({
  String id = '1',
  String theme = 'love',
  String firstName = '京都',
  String country = 'JP',
  String region = '京都府',
  String scopeKind = 'point',
  String? scopeDetail,
  DateTime? savedAt,
}) {
  final cand = ConsultationV2Candidate(
    name: firstName,
    nameEN: 'Kyoto',
    lat: 35.0,
    lng: 135.7,
    country: country,
    region: region,
    characterHeadline: '愛の軸が立つ場',
    energyLabels: const ['金星 MC・愛の軸'],
    narrative: '$firstName のテスト narrative',
    timeWindow:
        const ConsultationTimeWindow(kind: 'single', bucket: 'evening', label: '夜'),
  );
  return ConsultationRecord(
    id: id,
    savedAt: savedAt ?? DateTime.utc(2026, 5, 15, 10),
    theme: theme,
    mode: 'travel',
    scopeKind: scopeKind,
    scopeDetail: scopeDetail,
    innerSeason: 'テスト季節',
    intro: 'テスト intro',
    outro: '世界の全部ではありません',
    candidates: [cand],
    evidences: const [ConsultationEvidence(factors: ['金星MC合'])],
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ConsultationRecord JSON roundtrip', () {
    test('encode → decode が同じ内容を返す', () {
      final original = _sampleRecord();
      final restored = ConsultationRecord.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.theme, original.theme);
      expect(restored.mode, original.mode);
      expect(restored.scopeKind, original.scopeKind);
      expect(restored.candidates.length, 1);
      expect(restored.candidates.first.name, '京都');
      expect(restored.intro, 'テスト intro');
      expect(restored.candidates.first.narrative, '京都 のテスト narrative');
      expect(restored.evidences.first.factors, contains('金星MC合'));
    });

    test('scopeDetail roundtrip + legacy 欠落は null', () {
      final original = _sampleRecord(scopeKind: 'region', scopeDetail: '北米');
      expect(ConsultationRecord.fromJson(original.toJson()).scopeDetail, '北米');
      final legacy = Map<String, dynamic>.from(original.toJson())
        ..remove('scopeDetail');
      expect(ConsultationRecord.fromJson(legacy).scopeDetail, isNull);
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
      await SolaraStorage.addConsultationRecord(
          _sampleRecord(id: 'old', savedAt: DateTime.utc(2026, 5, 10)));
      await SolaraStorage.addConsultationRecord(
          _sampleRecord(id: 'new', savedAt: DateTime.utc(2026, 5, 15)));
      final loaded = await SolaraStorage.loadConsultationHistory();
      expect(loaded.length, 2);
      expect(loaded.first.id, 'new');
      expect(loaded.last.id, 'old');
    });

    testWidgets('delete で 1 件消える', (tester) async {
      await SolaraStorage.addConsultationRecord(_sampleRecord(id: 'a'));
      await SolaraStorage.addConsultationRecord(
          _sampleRecord(id: 'b', savedAt: DateTime.utc(2026, 5, 16)));
      await SolaraStorage.deleteConsultationRecord('a');
      final loaded = await SolaraStorage.loadConsultationHistory();
      expect(loaded.length, 1);
      expect(loaded.first.id, 'b');
    });

    testWidgets('clear で全件消える', (tester) async {
      await SolaraStorage.addConsultationRecord(_sampleRecord(id: '1'));
      await SolaraStorage.addConsultationRecord(_sampleRecord(id: '2'));
      await SolaraStorage.clearConsultationHistory();
      expect(await SolaraStorage.loadConsultationHistory(), isEmpty);
    });
  });

  testWidgets('Result screen auto-saves on fetch success', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ConsultationResultScreen(
        request: _req(),
        fetchOverride: (req) async => _mockResult('テスト都市'),
      ),
    ));
    await tester.pumpAndSettle();

    final saved = await SolaraStorage.loadConsultationHistory();
    expect(saved.length, 1);
    expect(saved.first.theme, 'love');
    expect(saved.first.candidates.first.name, 'テスト都市');
  });

  testWidgets('History mode (.fromRecord) は保存しない', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ConsultationResultScreen.fromRecord(record: _sampleRecord()),
    ));
    await tester.pumpAndSettle();
    expect(await SolaraStorage.loadConsultationHistory(), isEmpty);
  });

  testWidgets('History screen renders empty state', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: ConsultationHistoryScreen()));
    await tester.pumpAndSettle();
    expect(find.text('まだ相談履歴はありません'), findsOneWidget);
  });

  testWidgets('History screen lists records with theme prefix + icons',
      (tester) async {
    final rec1 = _sampleRecord(id: '1', firstName: '京都');
    final rec2 = _sampleRecord(
      id: '2',
      theme: 'work',
      firstName: '札幌',
      savedAt: DateTime.utc(2026, 5, 16),
    );
    await tester.pumpWidget(MaterialApp(
      home: ConsultationHistoryScreen(loadOverride: () async => [rec2, rec1]),
    ));
    await tester.pumpAndSettle();

    expect(find.text('札幌'), findsOneWidget);
    expect(find.text('京都'), findsOneWidget);
    expect(find.text('恋愛'), findsOneWidget);
    expect(find.text('仕事'), findsOneWidget);
    expect(find.text('恋愛・関係'), findsNothing);
    // mode='travel' / scopeKind='point'
    expect(find.byIcon(Icons.flight_outlined), findsNWidgets(2));
    expect(find.byIcon(Icons.location_on_outlined), findsNWidgets(2));
  });

  testWidgets('History card shows region scopeDetail', (tester) async {
    final rec = _sampleRecord(scopeKind: 'region', scopeDetail: '日本');
    await tester.pumpWidget(MaterialApp(
      home: ConsultationHistoryScreen(loadOverride: () async => [rec]),
    ));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.crop_din_outlined), findsOneWidget);
    expect(find.text('日本'), findsOneWidget);
  });

  testWidgets('History card shows point address (region/country)',
      (tester) async {
    final rec = _sampleRecord(scopeKind: 'point', country: 'JP', region: '京都府');
    await tester.pumpWidget(MaterialApp(
      home: ConsultationHistoryScreen(loadOverride: () async => [rec]),
    ));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    expect(find.text('京都府 / JP'), findsOneWidget);
  });

  testWidgets('History tap opens result in read-only mode', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ConsultationHistoryScreen(
          loadOverride: () async => [_sampleRecord()]),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('京都'));
    await tester.pumpAndSettle();

    expect(find.text('相談の結果'), findsOneWidget);
    await tester.tap(find.text('相談の結果'));
    await tester.pumpAndSettle();
    expect(find.textContaining('テスト intro'), findsOneWidget);
  });
}
