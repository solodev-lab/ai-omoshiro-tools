// Unit test: 軽量 i18n (solara_i18n.dart)。
// EN 表示は AppLocale override == 'en' のときだけ (system 連動はしない=テスト安定)。

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:solara/utils/app_locale.dart';
import 'package:solara/utils/solara_i18n.dart';

void main() {
  // 他テストへ override が漏れないよう毎回リセット。
  tearDown(() => AppLocale.instance.notifier.value = null);

  test('override 未設定 (default) は日本語', () {
    AppLocale.instance.notifier.value = null;
    expect(isEnLocale(), isFalse);
    expect(categoryLabel('all'), '総合');
    expect(categoryLabel('money'), '豊かさ');
    expect(categoryLabel('communication'), '話す');
    expect(categoryLabel('career'), '仕事'); // work/career → 同一概念
    expect(tr('category.overall'), '総合');
    expect(tr('disclaimer.ai'), startsWith('✦ AI 生成'));
  });

  test('override=en で英語', () {
    AppLocale.instance.notifier.value = const Locale('en');
    expect(isEnLocale(), isTrue);
    expect(categoryLabel('all'), 'Overall');
    expect(categoryLabel('money'), 'Abundance'); // 🔴 Money/Wealth ではない
    expect(categoryLabel('communication'), 'Talk');
    expect(categoryLabel('career'), 'Work');
    expect(tr('category.overall'), 'Overall');
    expect(tr('disclaimer.ai'), startsWith('✦ AI-generated'));
  });

  test('未登録キー / 未知 id はそのまま返す', () {
    expect(tr('nope.does.not.exist'), 'nope.does.not.exist');
    expect(categoryLabel('unknownId'), 'unknownId');
  });
}
