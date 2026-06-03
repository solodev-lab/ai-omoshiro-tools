// Unit test: 月の儀式ストーリー多言語 (cycle_story_texts.dart)。
// 各言語の区切り数が JP と一致すること (overlay がページ数で破綻しない) +
// {chosen}/$totalDays の差し込みが効くこと + 未対応 locale が EN フォールバックすること。

import 'package:flutter_test/flutter_test.dart';
import 'package:solara/utils/cycle_story_texts.dart';

void main() {
  const langs = ['ja', 'en', 'es', 'pt', 'fr', 'de', 'ko'];

  test('全言語: 新月/満月/刻星化の区切り数が JP と一致 (5/4/8)', () {
    expect(CycleStoryTexts.getNewMoon('ja').length, 5);
    expect(CycleStoryTexts.getFullMoon('ja', 'x').length, 4);
    expect(CycleStoryTexts.getCatasterism('ja', 30, 'x').length, 8);
    for (final l in langs) {
      expect(CycleStoryTexts.getNewMoon(l).length, 5, reason: 'newMoon $l');
      expect(CycleStoryTexts.getFullMoon(l, 'x').length, 4, reason: 'fullMoon $l');
      expect(CycleStoryTexts.getCatasterism(l, 30, 'x').length, 8, reason: 'catasterism $l');
    }
  });

  test('全言語: {chosen} が差し込まれ、プレースホルダが残らない', () {
    for (final l in langs) {
      final fm = CycleStoryTexts.getFullMoon(l, 'MYWISH');
      expect(fm.any((t) => t.contains('MYWISH')), isTrue, reason: 'fullMoon $l');
      expect(fm.every((t) => !t.contains('{chosen}')), isTrue, reason: 'fullMoon 残り $l');
      final cat = CycleStoryTexts.getCatasterism(l, 30, 'MYWISH');
      expect(cat.any((t) => t.contains('MYWISH')), isTrue, reason: 'catasterism $l');
      expect(cat.every((t) => !t.contains('{chosen}')), isTrue, reason: 'catasterism 残り $l');
    }
  });

  test('全言語: catasterism に totalDays が反映される', () {
    for (final l in langs) {
      expect(CycleStoryTexts.getCatasterism(l, 42, 'x').any((t) => t.contains('42')),
          isTrue, reason: 'totalDays $l');
    }
  });

  test('未対応 locale は EN にフォールバック', () {
    expect(CycleStoryTexts.getNewMoon('it'), CycleStoryTexts.newMoonEN);
    expect(CycleStoryTexts.getNewMoon('zh_CN'), CycleStoryTexts.newMoonEN);
  });
}
