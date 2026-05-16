// Smoke test: ConstellationShareCardPage (Free 機能、柱 3)
//
// Share の実 I/O (SharePlus / path_provider) は test で再現しないので、
// レンダリングと基本 UI 要素の存在のみを確認する。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:solara/models/daily_reading.dart';
import 'package:solara/models/galaxy_cycle.dart';
import 'package:solara/screens/galaxy/constellation_share_card_page.dart';

GalaxyCycle _sampleCycle() => GalaxyCycle(
      id: 'test-cycle',
      cycleStart: DateTime.utc(2026, 4, 7),
      cycleEnd: DateTime.utc(2026, 5, 6),
      readings: const <DailyReading>[],
      seedCardId: 7,
      nameEN: 'The Crimson Spear',
      nameJP: '紅の槍',
      dots: const [
        ConstellationDot(x: .3, y: .4, dayIndex: 0, cardId: 7, isMajor: true),
        ConstellationDot(x: .6, y: .5, dayIndex: 1, cardId: 5, isMajor: true),
        ConstellationDot(x: .4, y: .7, dayIndex: 2, cardId: 9, isMajor: false),
      ],
      rarity: 4,
      rarityLabel: 'Legendary',
      adjIdx: 0,
      nounIdx: 15,
    );

void main() {
  testWidgets('ConstellationShareCardPage 基本レンダリング', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConstellationShareCardPage(cycle: _sampleCycle()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('星座を共有'), findsOneWidget);
    expect(find.text('S O L A R A'), findsOneWidget);
    expect(find.text('— Your Constellation —'), findsOneWidget);
    expect(find.text('紅の槍'), findsOneWidget);
    // EN ラベル ("The " 除去後)
    expect(find.text('Crimson Spear'), findsOneWidget);
    expect(find.text('✦ 星座カードを共有する'), findsOneWidget);
  });

  testWidgets('nameJP 空でも nameEN で表示できる (フォールバック)', (tester) async {
    final cycle = GalaxyCycle(
      id: 'en-only',
      cycleStart: DateTime.utc(2026, 1, 1),
      cycleEnd: DateTime.utc(2026, 1, 28),
      readings: const <DailyReading>[],
      seedCardId: 0,
      nameEN: 'The Silver Crescent',
      nameJP: '',
      dots: const [
        ConstellationDot(x: .5, y: .5, dayIndex: 0, cardId: 0, isMajor: true),
      ],
      rarity: 2,
      rarityLabel: 'Uncommon',
      adjIdx: 0,
      nounIdx: 4,
    );

    await tester.pumpWidget(
      MaterialApp(home: ConstellationShareCardPage(cycle: cycle)),
    );
    await tester.pumpAndSettle();

    // nameJP 空 → nameEN ("The " 除去後) が JP 位置にもフォールバックして出る。
    // FittedBox 内で同じテキストが 2 箇所描画される可能性があるため findsWidgets。
    expect(find.text('Silver Crescent'), findsWidgets);
  });
}
