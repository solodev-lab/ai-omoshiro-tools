// ══════════════════════════════════════════════════════════════════
// Overflow ストレステスト (横/縦 両方)
//
// 目的: 「ユーザーにレイアウト崩れ (文字の見切れ・重なり) を見せない」。
//   RenderFlex の overflow は debug では黄黒の縞表示として出るが、これは
//   test では takeException() で捕捉できる例外として報告される (縦/横どちらも)。
//   → 狭い端末 (320dp) × 大フォント (アプリのクランプ上限 1.5x) で案内系 Widget を
//     pump し、overflow 例外がゼロであることを保証する。
//
// 対象: 一度しか出ない / クレジット / サインイン / 達成 等の「手で検証しづらい」案内系。
//   widget を直接 pump できるもの (parameterized) を網羅する。今後ここに足していく。
//
// 注意: flutter_test の既定フォントは全文字が 1em 角 (Ahem 系) なので、実フォントより
//   横幅が出る = 本番より厳しめ = 安全側の検出になる。
// ══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:solara/screens/map/map_welcome_banner.dart';
import 'package:solara/widgets/no_profile_guide.dart';
import 'package:solara/screens/observe/tarot_category_popup.dart';
import 'package:solara/utils/consultation_api.dart';

/// アプリ実機で起こりうる最悪条件 (狭端末 × 大フォント) を再現して [child] を pump する。
/// textScaler は MaterialApp.builder で全体 (= dialog/overlay も) に適用する。
Future<void> _pumpStressed(
  WidgetTester tester,
  Widget child, {
  double width = 320,
  double height = 640,
  double textScale = 1.5,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    builder: (context, w) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: w!,
    ),
    home: Scaffold(body: child),
  ));
  await tester.pumpAndSettle();
}

void main() {
  // アプリは main.dart で textScale を最大 1.5x にクランプしているので、
  // ユーザーが実際に到達しうる最悪値は 1.5。1.0 も併せて回す。
  const scales = <double>[1.0, 1.5];

  group('案内系 inline widget の overflow 耐性 (狭端末×大フォント)', () {
    for (final s in scales) {
      testWidgets('MapWelcomeBanner 全モード @textScale=$s', (tester) async {
        for (final mode in WelcomeBannerMode.values) {
          await _pumpStressed(
            tester,
            MapWelcomeBanner(mode: mode, onCta: () {}, onDismiss: () {}),
            textScale: s,
          );
          expect(tester.takeException(), isNull,
              reason: 'MapWelcomeBanner mode=$mode textScale=$s で overflow');
        }
      });

      testWidgets('NoProfileGuide @textScale=$s', (tester) async {
        await _pumpStressed(tester, const NoProfileGuide(), textScale: s);
        expect(tester.takeException(), isNull,
            reason: 'NoProfileGuide textScale=$s で overflow');
      });
    }
  });

  group('案内系 popup の overflow 耐性 (狭端末×大フォント)', () {
    // 残数の組み合わせで文言が変わる (無料/有料/Pro/確認中) ので代表ケースを回す。
    const statuses = <ConsultationCreditStatus?>[
      ConsultationCreditStatus(
          pro: false, freeRemaining: 2, freeLimit: 3, purchasedBalance: 5),
      ConsultationCreditStatus(
          pro: false, freeRemaining: 0, freeLimit: 3, purchasedBalance: 0),
      ConsultationCreditStatus(
          pro: true, freeRemaining: 0, freeLimit: 0, purchasedBalance: 0),
      null,
    ];
    for (final s in scales) {
      testWidgets('TarotCategoryPopup 代表ケース @textScale=$s', (tester) async {
        for (final status in statuses) {
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(MaterialApp(
            builder: (context, w) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(s),
              ),
              child: w!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (ctx) => TextButton(
                  onPressed: () => showTarotCategoryPopup(
                    context: ctx,
                    categoryLabel: '人間関係・恋愛',
                    status: status,
                    onBuy: () {},
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ));
          await tester.tap(find.text('open'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'TarotCategoryPopup status=$status textScale=$s で overflow');
          // 次のケースのため popup を閉じる
          await tester.tapAt(const Offset(5, 5));
          await tester.pumpAndSettle();
          tester.takeException();
        }
      });
    }
  });
}
