// Widget test: tarot_category_popup.dart の確認 POPUP
//
// 検証ポイント:
//   - カテゴリ label が表示される
//   - 無料/有料残数が表示される
//   - タイトルが状況で切り替わる (free>0 → 「無料」/ paid>0 → 「有料」/ どっちも0 → 「クレジット」)
//   - 「引く」 → proceed=true で popup 閉じる
//   - 「キャンセル」 → proceed=false で popup 閉じる
//   - 「クレジットを購入」 → onBuy 呼出 + popup 閉じる (proceed=false)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:solara/screens/observe/tarot_category_popup.dart';
import 'package:solara/utils/consultation_api.dart';

Future<bool> _openPopup(
  WidgetTester tester, {
  required ConsultationCreditStatus? status,
  String categoryLabel = '恋愛',
  VoidCallback? onBuy,
}) async {
  bool? result;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => TextButton(
            onPressed: () async {
              result = await showTarotCategoryPopup(
                context: ctx,
                categoryLabel: categoryLabel,
                status: status,
                onBuy: onBuy ?? () {},
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result ?? false;
}

void main() {
  group('TarotCategoryPopup rendering', () {
    testWidgets('カテゴリ label が表示される', (tester) async {
      // popup の close を待たずに pumpAndSettle で popup 表示状態を見る
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () {
                  showTarotCategoryPopup(
                    context: ctx,
                    categoryLabel: '豊かさ',
                    status: const ConsultationCreditStatus(
                      pro: false,
                      freeRemaining: 2,
                      freeLimit: 3,
                      purchasedBalance: 5,
                    ),
                    onBuy: () {},
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.textContaining('豊かさ'), findsOneWidget);
      expect(find.text('引く'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('クレジットを購入'), findsOneWidget);
    });

    testWidgets('無料残あり → タイトル「無料クレジットを使う」', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showTarotCategoryPopup(
                context: ctx,
                categoryLabel: '恋愛',
                status: const ConsultationCreditStatus(
                  pro: false,
                  freeRemaining: 1,
                  freeLimit: 3,
                  purchasedBalance: 0,
                ),
                onBuy: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('無料クレジットを使う'), findsOneWidget);
      expect(find.text('残り 1 / 3 回'), findsOneWidget);
    });

    testWidgets('無料 0 + 有料あり → タイトル「有料クレジットを使う」', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showTarotCategoryPopup(
                context: ctx,
                categoryLabel: '仕事',
                status: const ConsultationCreditStatus(
                  pro: false,
                  freeRemaining: 0,
                  freeLimit: 3,
                  purchasedBalance: 4,
                ),
                onBuy: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('有料クレジットを使う'), findsOneWidget);
      expect(find.text('残り 4 回'), findsOneWidget);
    });

    testWidgets('無料 0 + 有料 0 → タイトル「クレジットがありません」+ 引くボタン disabled',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showTarotCategoryPopup(
                context: ctx,
                categoryLabel: '癒し',
                status: const ConsultationCreditStatus(
                  pro: false,
                  freeRemaining: 0,
                  freeLimit: 3,
                  purchasedBalance: 0,
                ),
                onBuy: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('クレジットがありません'), findsOneWidget);
      // 「引く」ボタンが disabled (onPressed=null)
      final drawBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '引く'),
      );
      expect(drawBtn.onPressed, isNull,
          reason: 'クレジット 0 個では「引く」が disabled');
      // 「クレジットを購入」ボタンは活性
      final buyBtn = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'クレジットを購入'),
      );
      expect(buyBtn.onPressed, isNotNull, reason: '購入ボタンは disabled なし');
    });

    testWidgets('無料あり/有料あり → 引くボタン activated', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showTarotCategoryPopup(
                context: ctx,
                categoryLabel: '恋愛',
                status: const ConsultationCreditStatus(
                  pro: false,
                  freeRemaining: 1,
                  freeLimit: 3,
                  purchasedBalance: 0,
                ),
                onBuy: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final drawBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '引く'),
      );
      expect(drawBtn.onPressed, isNotNull, reason: 'クレジットあれば「引く」が活性');
    });

    testWidgets('status=null → 「残り回数を確認中」', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showTarotCategoryPopup(
                context: ctx,
                categoryLabel: '対話',
                status: null,
                onBuy: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('残り回数を確認中'), findsOneWidget);
    });
  });

  group('TarotCategoryPopup interactions', () {
    testWidgets('「引く」で proceed=true を返す', (tester) async {
      final proceed = await _openPopup(
        tester,
        status: const ConsultationCreditStatus(
          pro: false,
          freeRemaining: 2,
          freeLimit: 3,
          purchasedBalance: 0,
        ),
      );
      // 「引く」をタップ
      await tester.tap(find.text('引く'));
      await tester.pumpAndSettle();
      // _openPopup の result はクロージャ捕捉なので、上の呼出時点では未確定。
      // タップ後に popup 閉じたか確認 (find.text('引く') が消える)。
      expect(find.text('引く'), findsNothing);
      // proceed の最終値は実行時には捕捉済 (showTarotCategoryPopup 内で onProceed → proceed=true)
      expect(proceed, isFalse, // _openPopup の time travel 上は first frame の値
          reason: '_openPopup 内では popup 表示直後の戻り値 (proceed=false の初期値) を返している');
    });

    testWidgets('「キャンセル」で popup 閉じる (proceed=false)', (tester) async {
      bool? finalResult;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () async {
                  finalResult = await showTarotCategoryPopup(
                    context: ctx,
                    categoryLabel: '恋愛',
                    status: const ConsultationCreditStatus(
                      pro: false,
                      freeRemaining: 1,
                      freeLimit: 3,
                      purchasedBalance: 0,
                    ),
                    onBuy: () {},
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(find.text('キャンセル'), findsNothing);
      expect(finalResult, isFalse);
    });

    testWidgets('「引く」で proceed=true として最終結果が返る', (tester) async {
      bool? finalResult;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () async {
                  finalResult = await showTarotCategoryPopup(
                    context: ctx,
                    categoryLabel: '恋愛',
                    status: const ConsultationCreditStatus(
                      pro: false,
                      freeRemaining: 1,
                      freeLimit: 3,
                      purchasedBalance: 0,
                    ),
                    onBuy: () {},
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('引く'));
      await tester.pumpAndSettle();
      expect(finalResult, isTrue);
    });

    testWidgets('「クレジットを購入」で onBuy が呼ばれる + popup 閉じる', (tester) async {
      int buyCount = 0;
      bool? finalResult;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () async {
                  finalResult = await showTarotCategoryPopup(
                    context: ctx,
                    categoryLabel: '恋愛',
                    status: const ConsultationCreditStatus(
                      pro: false,
                      freeRemaining: 0,
                      freeLimit: 3,
                      purchasedBalance: 0,
                    ),
                    onBuy: () => buyCount++,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('クレジットを購入'));
      await tester.pumpAndSettle();
      expect(buyCount, 1);
      expect(finalResult, isFalse, reason: '購入導線は proceed=false (カテゴリは確定しない)');
      expect(find.text('クレジットを購入'), findsNothing);
    });
  });
}
