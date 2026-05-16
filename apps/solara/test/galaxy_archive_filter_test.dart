// Unit test: GalaxyArchiveFilter — C2 (柱 3)
//
// 検索 / レアリティ / ソートの絞込ロジックと、
// レアリティチップの単一選択挙動 (2026-05-17 回帰防止) を検証する。

import 'package:flutter/material.dart';
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

  // ──────────────────────────────────────────────────────────────
  // Filter bar widget: rarity multi-select チップの挙動
  // ──────────────────────────────────────────────────────────────

  group('GalaxyArchiveFilterBar — rarity multi-select', () {
    testWidgets('★5 タップ → rarities={5}', (tester) async {
      var captured = const GalaxyArchiveFilter();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GalaxyArchiveFilterBar(
              filter: captured,
              isPro: true,
              onChanged: (f) => captured = f,
            ),
          ),
        ),
      );
      await tester.tap(find.text('★5'));
      await tester.pump();
      expect(captured.rarities, {5});
    });

    testWidgets('★5 → ★3 タップ → rarities={3, 5} (multi-select)',
        (tester) async {
      var captured = const GalaxyArchiveFilter();
      Widget build() => MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (ctx, setState) => GalaxyArchiveFilterBar(
                  filter: captured,
                  isPro: true,
                  onChanged: (f) => setState(() => captured = f),
                ),
              ),
            ),
          );
      await tester.pumpWidget(build());
      await tester.tap(find.text('★5'));
      await tester.pump();
      expect(captured.rarities, {5});

      await tester.tap(find.text('★3'));
      await tester.pump();
      expect(captured.rarities, {3, 5},
          reason: 'multi-select: ★5 を残したまま ★3 を追加');
    });

    testWidgets('選択済みチップ再タップ → 外れる (toggle off)', (tester) async {
      var captured = const GalaxyArchiveFilter(rarities: {3, 5});
      Widget build() => MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (ctx, setState) => GalaxyArchiveFilterBar(
                  filter: captured,
                  isPro: true,
                  onChanged: (f) => setState(() => captured = f),
                ),
              ),
            ),
          );
      await tester.pumpWidget(build());
      await tester.tap(find.text('★3'));
      await tester.pump();
      expect(captured.rarities, {5},
          reason: '★3 を外した後は ★5 だけ残る');
    });

    testWidgets('Free 状態ではタップが無効 (Pro Unlock dialog 表示)', (tester) async {
      var captured = const GalaxyArchiveFilter();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GalaxyArchiveFilterBar(
              filter: captured,
              isPro: false,
              onChanged: (f) => captured = f,
            ),
          ),
        ),
      );
      await tester.tap(find.text('★5'));
      await tester.pumpAndSettle();
      // Pro Unlock dialog が出るので onChanged は呼ばれない
      expect(captured.rarities, isEmpty);
      expect(find.text('✦ Cosmic Pro'), findsOneWidget);
    });

    // ───────────────────────────────────────────────────
    // 報告された事象の回帰防止 (2026-05-17):
    // 「★5 だけタップしたのに rarity 3 のサイクルが表示される」
    // → apply の rarity フィルタは単純な Set.contains。
    //   apply 単体で原因が無いことを明示的に確認する。
    // ───────────────────────────────────────────────────
    test('rarities={5} 適用 → rarity 3 のサイクルは絶対に含まれない', () {
      const filter = GalaxyArchiveFilter(rarities: {5});
      final result = filter.apply([a, b, c]); // a=5, b=3, c=1
      expect(result.length, 1);
      expect(result.first.rarity, 5);
      expect(result.where((c) => c.rarity == 3), isEmpty);
    });
  });
}
