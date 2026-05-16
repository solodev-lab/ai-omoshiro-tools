// Unit test: galaxy_cycle_export — C5 (柱 3)

import 'package:flutter_test/flutter_test.dart';

import 'package:solara/models/daily_reading.dart';
import 'package:solara/models/galaxy_cycle.dart';
import 'package:solara/models/lunar_intention.dart';
import 'package:solara/utils/galaxy_cycle_export.dart';

GalaxyCycle _cycle() => GalaxyCycle(
      id: 'cycle-1',
      cycleStart: DateTime.utc(2026, 4, 7),
      cycleEnd: DateTime.utc(2026, 5, 6),
      readings: const <DailyReading>[],
      seedCardId: 7,
      nameEN: 'The Lantern Bearer',
      nameJP: '燈火を掲ぐ者',
      dots: const [
        ConstellationDot(x: .1, y: .2, dayIndex: 0, cardId: 7, isMajor: true),
        ConstellationDot(x: .3, y: .4, dayIndex: 1, cardId: 5, isMajor: false),
      ],
      rarity: 4,
      rarityLabel: 'Legendary',
      adjIdx: 2,
      nounIdx: 3,
    );

void main() {
  group('formatGalaxyCycleAsMarkdown', () {
    test('cycle 単独でも整形できる', () {
      final md = formatGalaxyCycleAsMarkdown(cycle: _cycle());
      expect(md, contains('# ✦ 燈火を掲ぐ者'));
      expect(md, contains('_The Lantern Bearer_'));
      expect(md, contains('2026-04-07 〜 2026-05-06'));
      expect(md, contains('Legendary (4/5)'));
      expect(md, contains('2 stars / 1 anchors'));
      expect(md, contains('Solara · Galaxy Archive'));
      expect(md, contains('#Solara'));
    });

    test('intention が併記されると新月の意図・刻星化が出る', () {
      final intention = LunarIntention(
        cycleId: '2026-04',
        chosenText: 'release control',
        chosenTextJP: '手を緩める',
        chosenAt: DateTime.utc(2026, 4, 7),
        newMoonSign: 'Aries',
        midpoint: MidpointCheck(
          checkedAt: DateTime.utc(2026, 4, 21),
          rating: 2,
        ),
        catasterism: CatasterismResult(
          assessedAt: DateTime.utc(2026, 5, 6),
          released: true,
        ),
      );
      final md = formatGalaxyCycleAsMarkdown(
        cycle: _cycle(),
        intention: intention,
      );
      expect(md, contains('## 新月の意図'));
      expect(md, contains('手を緩める'));
      expect(md, contains('### 満月の中間チェック'));
      expect(md, contains('### 刻星化セルフアセスメント'));
      expect(md, contains('手放せた'));
    });

    test('intention chosenTextJP が空でも chosenText が出る', () {
      final intention = LunarIntention(
        cycleId: '2026-04',
        chosenText: 'release control',
        chosenTextJP: '',
        chosenAt: DateTime.utc(2026, 4, 7),
        newMoonSign: 'Aries',
      );
      final md = formatGalaxyCycleAsMarkdown(
        cycle: _cycle(),
        intention: intention,
      );
      expect(md, contains('release control'));
    });
  });

  group('formatGalaxyCycleCaption', () {
    test('短いキャプションを返す', () {
      final cap = formatGalaxyCycleCaption(_cycle());
      expect(cap, contains('燈火を掲ぐ者'));
      expect(cap, contains('Legendary'));
      expect(cap, contains('2 stars'));
      expect(cap, contains('#Solara'));
    });
  });
}
