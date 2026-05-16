// Unit + widget test: ProStatus singleton + showProUnlockDialog
//
// Phase 2-6a Pro ゲート配線の最小検証。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:solara/utils/pro_status.dart';
import 'package:solara/widgets/pro_unlock_dialog.dart';

void main() {
  group('ProStatus singleton', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('default は false (load 前は false)', () async {
      await ProStatus.instance.resetForTest(isPro: false);
      expect(ProStatus.instance.isPro, isFalse);
      expect(ProStatus.instance.loaded, isTrue);
    });

    test('setPro(true) で isPro が反転 + listener が発火', () async {
      await ProStatus.instance.resetForTest(isPro: false);
      int notifyCount = 0;
      void listener() => notifyCount++;
      ProStatus.instance.addListener(listener);

      await ProStatus.instance.setPro(true);
      expect(ProStatus.instance.isPro, isTrue);
      expect(notifyCount, 1);

      await ProStatus.instance.setPro(false);
      expect(ProStatus.instance.isPro, isFalse);
      expect(notifyCount, 2);

      ProStatus.instance.removeListener(listener);
    });

    test('SharedPreferences に永続化される', () async {
      await ProStatus.instance.resetForTest(isPro: false);
      await ProStatus.instance.setPro(true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('solara_is_pro'), isTrue);
    });
  });

  group('showProUnlockDialog', () {
    testWidgets('feature + description が表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => showProUnlockDialog(
                  ctx,
                  featureLabel: 'テスト機能',
                  description: 'これはテスト用の説明です。',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('✦ Cosmic Pro'), findsOneWidget);
      expect(find.textContaining('テスト機能'), findsOneWidget);
      expect(find.textContaining('Pro 機能'), findsOneWidget);
      expect(find.textContaining('これはテスト用の説明'), findsOneWidget);
      expect(find.text('閉じる'), findsOneWidget);
      // Phase 2-6b: アップグレードボタンは enabled (PaywallScreen を push)
      final upgradeBtn = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Pro にアップグレード'),
      );
      expect(upgradeBtn.onPressed, isNotNull, reason: '課金導線は Phase 2-6b で配線済');
    });

    testWidgets('「閉じる」をタップするとダイアログが消える', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => showProUnlockDialog(
                  ctx,
                  featureLabel: 'テスト機能',
                  description: 'これはテスト用の説明です。',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('✦ Cosmic Pro'), findsOneWidget);

      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();
      expect(find.text('✦ Cosmic Pro'), findsNothing);
    });
  });
}
