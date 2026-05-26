// Unit test: DailyReading.category フィールド (2026-05-26 Tarot 1日1回統一改修)
//
// 検証ポイント:
//   - category を含む保存/復元
//   - category=null (全体運) も含む
//   - 旧データ (category 無し) の互換性

import 'package:flutter_test/flutter_test.dart';

import 'package:solara/models/daily_reading.dart';

void main() {
  group('DailyReading category field', () {
    test('category=null は toJson に含まれない (旧データ互換)', () {
      final r = DailyReading(
        date: '2026-05-26',
        cardId: 7,
        isMajor: true,
        moonPhase: 12.5,
      );
      final j = r.toJson();
      expect(j.containsKey('category'), isFalse);
    });

    test('category=空文字 は toJson に含まれない', () {
      final r = DailyReading(
        date: '2026-05-26',
        cardId: 7,
        isMajor: true,
        moonPhase: 12.5,
        category: '',
      );
      final j = r.toJson();
      expect(j.containsKey('category'), isFalse);
    });

    test('category="love" は toJson に含まれる', () {
      final r = DailyReading(
        date: '2026-05-26',
        cardId: 7,
        isMajor: true,
        moonPhase: 12.5,
        category: 'love',
      );
      final j = r.toJson();
      expect(j['category'], 'love');
    });

    test('round-trip: 保存 → 復元で category が一致', () {
      final original = DailyReading(
        date: '2026-05-26',
        cardId: 22,
        isMajor: false,
        moonPhase: 14.0,
        reversed: true,
        reading: 'テスト読み',
        category: 'money',
      );
      final restored = DailyReading.fromJson(original.toJson());
      expect(restored.category, 'money');
      expect(restored.date, '2026-05-26');
      expect(restored.cardId, 22);
      expect(restored.reversed, isTrue);
      expect(restored.reading, 'テスト読み');
    });

    test('旧 JSON (category キーなし) の復元 → category=null', () {
      final j = {
        'date': '2026-05-20',
        'cardId': 0,
        'isMajor': true,
        'moonPhase': 0.5,
        'reversed': false,
        'reading': '',
        'synchronicity': '',
      };
      final r = DailyReading.fromJson(j);
      expect(r.category, isNull);
    });

    test('全 6 カテゴリ値で round-trip 動作する', () {
      for (final c in ['love', 'money', 'work', 'communication', 'healing', 'newStart']) {
        final r = DailyReading(
          date: '2026-05-26',
          cardId: 1,
          isMajor: true,
          moonPhase: 0,
          category: c,
        );
        final restored = DailyReading.fromJson(r.toJson());
        expect(restored.category, c, reason: 'category=$c の round-trip 失敗');
      }
    });
  });
}
