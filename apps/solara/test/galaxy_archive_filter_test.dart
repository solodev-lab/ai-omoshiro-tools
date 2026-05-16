// Unit test: GalaxyArchiveFilter — C2 (柱 3)
//
// 検索 / レアリティ / ソートの絞込ロジックのみを検証する。
// UI 部分 (ProUnlockDialog 連動) は別途 widget test で扱う。

import 'package:flutter_test/flutter_test.dart';

import 'package:solara/models/daily_reading.dart';
import 'package:solara/models/galaxy_cycle.dart';
import 'package:solara/screens/galaxy/galaxy_archive_filter.dart';

GalaxyCycle _cycle({
  required String id,
  required DateTime start,
  required String nameEN,
  required String nameJP,
  required int rarity,
}) {
  return GalaxyCycle(
    id: id,
    cycleStart: start,
    cycleEnd: start.add(const Duration(days: 28)),
    readings: const <DailyReading>[],
    seedCardId: 0,
    nameEN: nameEN,
    nameJP: nameJP,
    dots: const [],
    rarity: rarity,
    rarityLabel: 'Common',
    adjIdx: 0,
    nounIdx: 0,
  );
}

void main() {
  final a = _cycle(
    id: 'a',
    start: DateTime.utc(2026, 1, 1),
    nameEN: 'Dragon Wing',
    nameJP: '翼のドラゴン',
    rarity: 5,
  );
  final b = _cycle(
    id: 'b',
    start: DateTime.utc(2026, 2, 1),
    nameEN: 'Silent River',
    nameJP: '静かな川',
    rarity: 3,
  );
  final c = _cycle(
    id: 'c',
    start: DateTime.utc(2026, 3, 1),
    nameEN: 'Crimson Spear',
    nameJP: '紅の槍',
    rarity: 1,
  );
  final all = [a, b, c];

  group('GalaxyArchiveFilter.apply', () {
    test('default (空) は全件を新しい順で返す', () {
      const f = GalaxyArchiveFilter();
      final r = f.apply(all);
      expect(r.length, 3);
      expect(r.first.id, 'c'); // 2026-03
      expect(r.last.id, 'a'); // 2026-01
    });

    test('query は EN/JP の部分一致 (大小文字無視)', () {
      const f1 = GalaxyArchiveFilter(query: 'dragon');
      expect(f1.apply(all).map((c) => c.id), ['a']);

      const f2 = GalaxyArchiveFilter(query: 'のドラゴン');
      expect(f2.apply(all).map((c) => c.id), ['a']);

      const f3 = GalaxyArchiveFilter(query: 'no-match');
      expect(f3.apply(all), isEmpty);
    });

    test('rarities 集合で絞込', () {
      const f = GalaxyArchiveFilter(rarities: {5, 3});
      final r = f.apply(all);
      expect(r.length, 2);
      expect(r.map((c) => c.id).toSet(), {'a', 'b'});
    });

    test('sort: oldestFirst', () {
      const f = GalaxyArchiveFilter(sort: GalaxyArchiveSort.oldestFirst);
      expect(f.apply(all).map((c) => c.id), ['a', 'b', 'c']);
    });

    test('sort: rarityHighFirst', () {
      const f = GalaxyArchiveFilter(sort: GalaxyArchiveSort.rarityHighFirst);
      expect(f.apply(all).map((c) => c.id), ['a', 'b', 'c']);
    });

    test('query + rarities + sort 複合', () {
      const f = GalaxyArchiveFilter(
        query: 'river',
        rarities: {3},
        sort: GalaxyArchiveSort.oldestFirst,
      );
      expect(f.apply(all).map((c) => c.id), ['b']);
    });

    test('isActive: default は false', () {
      expect(const GalaxyArchiveFilter().isActive, isFalse);
      expect(const GalaxyArchiveFilter(query: 'x').isActive, isTrue);
      expect(const GalaxyArchiveFilter(rarities: {5}).isActive, isTrue);
      expect(
        const GalaxyArchiveFilter(sort: GalaxyArchiveSort.oldestFirst)
            .isActive,
        isTrue,
      );
    });

    test('copyWith は他フィールドを保持', () {
      const f = GalaxyArchiveFilter(query: 'a', rarities: {1});
      final f2 = f.copyWith(sort: GalaxyArchiveSort.rarityHighFirst);
      expect(f2.query, 'a');
      expect(f2.rarities, {1});
      expect(f2.sort, GalaxyArchiveSort.rarityHighFirst);
    });
  });
}
