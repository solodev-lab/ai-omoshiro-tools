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
  DateTime? formedAt,
}) {
  return GalaxyCycle(
    id: id,
    cycleStart: start,
    cycleEnd: start.add(const Duration(days: 28)),
    formedAt: formedAt,
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

    // ───────────────────────────────────────────────────
    // 回帰防止 (2026-05-19):
    // 「debug で過去サイクルを後から作ると、 cycleStart は古くなるが
    //  実際に刻星化したのは今 → newestFirst で先頭に来てほしい」事象。
    // ソートは cycleStart ではなく effectiveFormedAt (= formedAt 優先、
    // 無ければ id を ms としてパース、それも無ければ cycleStart) で
    // 行うことを確認する。
    // ───────────────────────────────────────────────────
    test('sort は formedAt 優先 (cycleStart が古くても formedAt が新しいと先頭)', () {
      final old = _cycle(
        id: 'old-id',
        start: DateTime.utc(2020, 1, 1),
        nameEN: 'Old',
        nameJP: '旧',
        rarity: 3,
        formedAt: DateTime.utc(2026, 5, 19, 10), // 刻星化は最近
      );
      final mid = _cycle(
        id: 'mid-id',
        start: DateTime.utc(2026, 1, 1),
        nameEN: 'Mid',
        nameJP: '中',
        rarity: 3,
        formedAt: DateTime.utc(2026, 5, 19, 9), // 1時間前
      );
      final older = _cycle(
        id: 'older-id',
        start: DateTime.utc(2026, 4, 1), // cycleStart は new だが
        nameEN: 'Older',
        nameJP: '古',
        rarity: 3,
        formedAt: DateTime.utc(2026, 5, 19, 8), // formedAt は 2 時間前
      );
      const f = GalaxyArchiveFilter();
      final r = f.apply([older, mid, old]);
      expect(r.map((c) => c.id), ['old-id', 'mid-id', 'older-id'],
          reason: '新しい順: formedAt 降順 (cycleStart は無視される)');
    });

    test('formedAt が null でも id (ms) で順序が保たれる', () {
      // id = millisecondsSinceEpoch.toString() の旧データ想定
      final t1 = DateTime.utc(2026, 5, 1).millisecondsSinceEpoch;
      final t2 = DateTime.utc(2026, 5, 10).millisecondsSinceEpoch;
      final t3 = DateTime.utc(2026, 5, 19).millisecondsSinceEpoch;
      final older = _cycle(
        id: '$t1', start: DateTime.utc(2020, 1, 1),
        nameEN: 'A', nameJP: 'a', rarity: 1,
      );
      final mid = _cycle(
        id: '$t2', start: DateTime.utc(2020, 1, 1),
        nameEN: 'B', nameJP: 'b', rarity: 1,
      );
      final latest = _cycle(
        id: '$t3', start: DateTime.utc(2020, 1, 1),
        nameEN: 'C', nameJP: 'c', rarity: 1,
      );
      const f = GalaxyArchiveFilter();
      final r = f.apply([older, mid, latest]);
      expect(r.map((c) => c.id), ['$t3', '$t2', '$t1'],
          reason: '旧データ: formedAt 無し → id を ms としてパース');
    });

    test('id も ms でない旧データは cycleStart にフォールバック', () {
      final a2 = _cycle(
        id: 'non-numeric-id',
        start: DateTime.utc(2026, 1, 1),
        nameEN: 'A', nameJP: 'a', rarity: 1,
      );
      final b2 = _cycle(
        id: 'another-non-numeric',
        start: DateTime.utc(2026, 3, 1),
        nameEN: 'B', nameJP: 'b', rarity: 1,
      );
      const f = GalaxyArchiveFilter();
      final r = f.apply([a2, b2]);
      expect(r.map((c) => c.id),
          ['another-non-numeric', 'non-numeric-id'],
          reason: 'フォールバック: cycleStart 降順');
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
