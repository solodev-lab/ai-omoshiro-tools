// Unit test: SolaraStorage.updateCompletedCycleReadingSynchronicity (2026-05-19)
//
// 過去サイクル (GalaxyCycle.readings) 内の reading の synchronicity (自由メモ)
// を編集する storage メソッドの動作確認。

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:solara/models/daily_reading.dart';
import 'package:solara/models/galaxy_cycle.dart';
import 'package:solara/utils/solara_storage.dart';

GalaxyCycle _cycle({
  required String id,
  required String date1,
  required String date2,
}) {
  return GalaxyCycle(
    id: id,
    cycleStart: DateTime.utc(2026, 1, 1),
    cycleEnd: DateTime.utc(2026, 1, 29),
    readings: [
      DailyReading(
        date: date1,
        cardId: 0,
        isMajor: true,
        moonPhase: 0.0,
        synchronicity: '',
      ),
      DailyReading(
        date: date2,
        cardId: 1,
        isMajor: true,
        moonPhase: 1.0,
        synchronicity: 'prev memo',
      ),
    ],
    seedCardId: 0,
    nameEN: 'Test',
    nameJP: 'テスト',
    dots: const [],
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('updateCompletedCycleReadingSynchronicity', () {
    test('該当 cycle / reading にメモを書き込める', () async {
      await SolaraStorage.saveCompletedCycle(
        _cycle(id: 'c1', date1: '2026-01-05', date2: '2026-01-10'),
      );
      await SolaraStorage.updateCompletedCycleReadingSynchronicity(
        'c1',
        '2026-01-05',
        '気づきメモ',
      );
      final cycles = await SolaraStorage.loadCompletedCycles();
      expect(cycles.length, 1);
      final r1 = cycles.first.readings.firstWhere((r) => r.date == '2026-01-05');
      expect(r1.synchronicity, '気づきメモ');
      // 他の reading は触られない
      final r2 = cycles.first.readings.firstWhere((r) => r.date == '2026-01-10');
      expect(r2.synchronicity, 'prev memo');
    });

    test('複数 cycle の中から正しい cycle が選ばれる', () async {
      await SolaraStorage.saveCompletedCycle(
        _cycle(id: 'c1', date1: '2026-01-05', date2: '2026-01-10'),
      );
      await SolaraStorage.saveCompletedCycle(
        _cycle(id: 'c2', date1: '2026-02-05', date2: '2026-02-10'),
      );
      await SolaraStorage.updateCompletedCycleReadingSynchronicity(
        'c2',
        '2026-02-05',
        'c2 memo',
      );
      final cycles = await SolaraStorage.loadCompletedCycles();
      final c1 =
          cycles.firstWhere((c) => c.id == 'c1');
      final c2 =
          cycles.firstWhere((c) => c.id == 'c2');
      expect(
        c1.readings.firstWhere((r) => r.date == '2026-01-05').synchronicity,
        '',
        reason: 'c1 は触られない',
      );
      expect(
        c2.readings.firstWhere((r) => r.date == '2026-02-05').synchronicity,
        'c2 memo',
      );
    });

    test('未一致 cycleId は no-op', () async {
      await SolaraStorage.saveCompletedCycle(
        _cycle(id: 'c1', date1: '2026-01-05', date2: '2026-01-10'),
      );
      await SolaraStorage.updateCompletedCycleReadingSynchronicity(
        'no-such',
        '2026-01-05',
        'should be ignored',
      );
      final cycles = await SolaraStorage.loadCompletedCycles();
      expect(cycles.length, 1);
      expect(
        cycles.first.readings.first.synchronicity,
        '',
        reason: '元のメモのまま',
      );
    });

    test('未一致 readingDate は no-op', () async {
      await SolaraStorage.saveCompletedCycle(
        _cycle(id: 'c1', date1: '2026-01-05', date2: '2026-01-10'),
      );
      await SolaraStorage.updateCompletedCycleReadingSynchronicity(
        'c1',
        '2026-99-99',
        'should be ignored',
      );
      final cycles = await SolaraStorage.loadCompletedCycles();
      // 既存メモは変わらない
      final r2 = cycles.first.readings
          .firstWhere((r) => r.date == '2026-01-10');
      expect(r2.synchronicity, 'prev memo');
    });

    test('空文字でメモをクリアできる', () async {
      await SolaraStorage.saveCompletedCycle(
        _cycle(id: 'c1', date1: '2026-01-05', date2: '2026-01-10'),
      );
      await SolaraStorage.updateCompletedCycleReadingSynchronicity(
        'c1',
        '2026-01-10',
        '',
      );
      final cycles = await SolaraStorage.loadCompletedCycles();
      expect(
        cycles.first.readings.firstWhere((r) => r.date == '2026-01-10').synchronicity,
        '',
      );
    });
  });
}
