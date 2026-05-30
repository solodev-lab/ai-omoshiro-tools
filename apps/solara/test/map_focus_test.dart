// Unit test: mapFocusDate — 相談結果🗺ボタンが Map に渡す日付の導出ルール。
//
// 要件(オーナー): おでかけ/イベント=指定日(+時間帯)、旅行=初日、移住=時期の代表日。

import 'package:flutter_test/flutter_test.dart';
import 'package:solara/utils/map_focus.dart';

void main() {
  group('mapFocusDate', () {
    test('おでかけ: 指定日 + 時間帯(夕方=17時)', () {
      expect(
        mapFocusDate(kind: 'date', date: '2026-08-10', timeBand: 'evening'),
        DateTime(2026, 8, 10, 17),
      );
    });

    test('おでかけ: 時間帯ごとの代表時刻', () {
      expect(mapFocusDate(kind: 'date', date: '2026-08-10', timeBand: 'morning'),
          DateTime(2026, 8, 10, 8));
      expect(mapFocusDate(kind: 'date', date: '2026-08-10', timeBand: 'night'),
          DateTime(2026, 8, 10, 21));
    });

    test('おでかけ: 時間帯なしは0時', () {
      expect(mapFocusDate(kind: 'date', date: '2026-08-10'),
          DateTime(2026, 8, 10));
    });

    test('旅行: range は初日 (start)', () {
      expect(mapFocusDate(kind: 'range', start: '2026-07-01', timeBand: null),
          DateTime(2026, 7, 1));
    });

    test('移住: 半年内 = now+3ヶ月 (now 注入)', () {
      expect(mapFocusDate(kind: 'within6mo', now: DateTime(2026, 1, 15)),
          DateTime(2026, 4, 15));
    });

    test('移住: 5年+ = now+36ヶ月', () {
      expect(mapFocusDate(kind: 'in5yrPlus', now: DateTime(2026, 1, 15)),
          DateTime(2029, 1, 15));
    });

    test('未指定 (today/undecided/null) は null = 今日', () {
      expect(mapFocusDate(kind: 'today'), isNull);
      expect(mapFocusDate(kind: null), isNull);
      expect(mapFocusDate(kind: 'undecided'), isNull);
    });
  });
}
