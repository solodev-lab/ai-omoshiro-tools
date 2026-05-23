// Widget test: ConsultationInputScreen + ConsultationResultScreen の
// 基本レンダリング + ユーザー入力フロー + モック API 連携。
//
// Worker は呼ばない (fetchOverride で差替)。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:solara/screens/consultation/consultation_input_screen.dart';
import 'package:solara/screens/consultation/consultation_result_screen.dart';
import 'package:solara/utils/astro_lines.dart' as al;
import 'package:solara/utils/consultation_api.dart';
import 'package:solara/utils/consultation_engine.dart';
import 'package:solara/utils/pro_status.dart';

List<al.AstroLine> _buildSyntheticLines() {
  // Venus MC (139.7E、Tokyo 直上)
  final venusMc = al.AstroLine(
    planet: 'venus',
    angle: 'mc',
    aspect: 'conjunction',
    frame: al.AstroFrame.natal,
    segments: [
      [for (double lat = -60; lat <= 60; lat += 5) LatLng(lat, 139.7)],
    ],
  );
  // Mars ASC (2.3E、Paris)
  final marsAsc = al.AstroLine(
    planet: 'mars',
    angle: 'asc',
    aspect: 'conjunction',
    frame: al.AstroFrame.natal,
    segments: [
      [for (double lat = -60; lat <= 60; lat += 5) LatLng(lat, 2.3)],
    ],
  );
  // Moon DSC (-157.8、Honolulu)
  final moonDsc = al.AstroLine(
    planet: 'moon',
    angle: 'dsc',
    aspect: 'conjunction',
    frame: al.AstroFrame.natal,
    segments: [
      [for (double lat = -60; lat <= 60; lat += 5) LatLng(lat, -157.8)],
    ],
  );
  return [venusMc, marsAsc, moonDsc];
}

ConsultationReading _mockReading(List<CandidateLocation> cands) {
  return ConsultationReading(
    intro: 'モック intro: ${cands.length} 候補。',
    candidates: [
      for (final c in cands)
        ConsultationCandidateReading(
          name: c.nameJP,
          energyLabels: ['金星 MC・愛の軸', '月 DSC・対人の流れ'],
          narrative: '${c.nameJP} のモック narrative。テスト目的の text。',
        ),
    ],
    outro: '候補は世界の全部ではありません。',
    model: 'mock-test',
    fallback: false,
  );
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await ProStatus.instance.resetForTest(isPro: false);
  });

  testWidgets('Input screen renders all required sections', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConsultationInputScreen(
          astroLines: _buildSyntheticLines(),
          currentLocation: LatLng(35.6580, 139.7016),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // セクション見出し (2026-05-16: 「どの距離感で？」→「どんな場面で？」、
    // 自由記述の下に「こんな相談ができそう」セクション追加)
    expect(find.text('何のテーマで観たい？'), findsOneWidget);
    expect(find.text('どんな場面で？'), findsOneWidget);
    // 初期選択なし方針 (2026-05-23): 場面を選ぶまで「範囲は？」は非表示
    expect(find.text('範囲は？'), findsNothing);
    expect(find.text('自由記述（任意）'), findsOneWidget);
    expect(find.text('こんな相談ができそう'), findsOneWidget);

    // テーマ 6 チップ
    expect(find.text('恋愛・関係'), findsOneWidget);
    expect(find.text('豊かさ・お金'), findsOneWidget);
    expect(find.text('仕事・キャリア'), findsOneWidget);
    expect(find.text('対話・学び'), findsOneWidget);
    expect(find.text('癒し・休息'), findsOneWidget);
    expect(find.text('変化・新たな出発'), findsOneWidget);

    // モード 3 択
    expect(find.text('移住'), findsOneWidget);
    expect(find.text('旅行'), findsOneWidget);
    expect(find.text('おでかけ'), findsOneWidget);

    // 場面を選ぶと「範囲は？」セクションが現れる
    await tester.tap(find.text('移住'));
    await tester.pumpAndSettle();
    expect(find.text('範囲は？'), findsOneWidget);

    // 提出ボタン
    expect(find.text('相談を始める'), findsOneWidget);
  });

  testWidgets('Submit button is disabled until theme + mode + scope selected',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConsultationInputScreen(
          astroLines: _buildSyntheticLines(),
          currentLocation: LatLng(35.6580, 139.7016),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final submitBtn = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '相談を始める'),
    );
    expect(submitBtn.onPressed, isNull,
        reason: 'テーマ未選択時は disable');

    // 「恋愛・関係」をタップ (テーマだけでは不足: 初期選択なし方針)
    await tester.tap(find.text('恋愛・関係'));
    await tester.pumpAndSettle();
    final submitBtnTheme = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '相談を始める'),
    );
    expect(submitBtnTheme.onPressed, isNull,
        reason: 'テーマだけでは不足 (場面・範囲も必要)');

    // 場面「移住」+ 範囲「世界全体」を選ぶと enable
    await tester.tap(find.text('移住'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('世界全体'));
    await tester.pumpAndSettle();
    final submitBtn2 = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '相談を始める'),
    );
    expect(submitBtn2.onPressed, isNotNull,
        reason: 'テーマ+場面+範囲 が揃えば enable');
  });

  testWidgets(
      'Daily mode shows scope row with daily-specific choices (specific/bearings/region)',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConsultationInputScreen(
          astroLines: _buildSyntheticLines(),
          currentLocation: LatLng(35.6580, 139.7016),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 初期選択なし: 場面を選ぶまで範囲は非表示
    expect(find.text('範囲は？'), findsNothing);

    // 「移住」を選ぶと非 daily 用の範囲 (世界全体あり・方角ベースなし)
    await tester.tap(find.text('移住'));
    await tester.pumpAndSettle();
    expect(find.text('範囲は？'), findsOneWidget);
    expect(find.text('世界全体'), findsOneWidget);
    expect(find.text('方角ベース'), findsNothing);

    // 「おでかけ」をタップ
    await tester.tap(find.text('おでかけ'));
    await tester.pumpAndSettle();

    // 範囲は？ セクションは残るが、選択肢が daily 用に切替わる:
    //   具体地点 / 方角ベース / 範囲指定 (世界全体は外れる)
    expect(find.text('範囲は？'), findsOneWidget);
    expect(find.text('世界全体'), findsNothing);
    expect(find.text('方角ベース'), findsOneWidget);
    expect(find.text('具体地点'), findsOneWidget);
    expect(find.text('範囲指定'), findsOneWidget);
  });

  testWidgets(
      'Specific scope without preset shows inline picker and gates submit until point chosen',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConsultationInputScreen(
          astroLines: _buildSyntheticLines(),
          // currentLocation はあえて null。Daily Transit 目的起点で具体地点を
          // 選ぶフローを模擬する。
        ),
      ),
    );
    await tester.pumpAndSettle();

    // テーマを選んでも、specific スコープにすると地点未選択で submit 不可になる。
    await tester.tap(find.text('恋愛・関係'));
    await tester.pumpAndSettle();

    // 場面 (旅行) を選んで範囲セクションを出す (初期選択なし方針)
    await tester.tap(find.text('旅行'));
    await tester.pumpAndSettle();

    // 「具体地点」スコープを選択
    await tester.tap(find.text('具体地点'));
    await tester.pumpAndSettle();

    // 「地点を選ぶ」 inline picker セクションが出る
    expect(find.text('地点を選ぶ'), findsOneWidget);
    // 「地図で選ぶ」 ボタン (B picker への push)
    expect(find.widgetWithText(OutlinedButton, '地図で選ぶ'), findsOneWidget);
    // 検索フィールド
    expect(find.text('住所 / 店名で検索'), findsOneWidget);

    // 地点未選択なので submit 不可
    final submitBtn = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '相談を始める'),
    );
    expect(submitBtn.onPressed, isNull,
        reason: 'specific スコープ + 地点未選択は submit 不可');
  });

  testWidgets('Inline picker is NOT shown when presetTarget is provided',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConsultationInputScreen(
          astroLines: _buildSyntheticLines(),
          presetTarget: const ConsultationPresetTarget(
            position: LatLng(35.0, 135.7),
            nameJP: '京都',
            nameEN: 'Kyoto',
            country: 'JP',
            region: '京都府',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // preset があるので picker は出ず、preset カード (✓ ... を見ます) が出る
    expect(find.text('地点を選ぶ'), findsNothing);
    expect(find.textContaining('京都'), findsWidgets);
    expect(find.textContaining('を見ます'), findsOneWidget);
  });

  testWidgets(
      'Free user sees start popup (残数/補充/購入ボタン) on 相談を始める',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConsultationInputScreen(
          astroLines: _buildSyntheticLines(),
          currentLocation: LatLng(35.6580, 139.7016),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // テーマ + 場面 + 範囲 を選んで submit を有効化
    await tester.tap(find.text('恋愛・関係'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('移住'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('世界全体'));
    await tester.pumpAndSettle();

    // 「相談を始める」(送信バー) → 開始ポップアップが出る (Free のみ)
    await tester.tap(find.widgetWithText(ElevatedButton, '相談を始める'));
    await tester.pumpAndSettle();

    // ポップアップの固有要素を確認
    expect(find.text('無料相談を使います'), findsOneWidget);
    // 「毎週月曜日に補充」は残数バッジと案内文の 2 箇所に出る
    expect(find.textContaining('毎週月曜日に補充'), findsWidgets);
    expect(find.text('次回以降表示しない'), findsOneWidget);
    expect(find.text('クレジットを購入'), findsOneWidget);
    // 続行ボタンとして popup 内にも「相談を始める」がある (送信バーと合わせ 2 つ)
    expect(find.text('相談を始める'), findsNWidgets(2));
  });

  testWidgets('Result screen shows mock reading and PageView (Pro: refresh visible)',
      (tester) async {
    // 出し直しは Pro 限定なので Pro に設定
    await ProStatus.instance.resetForTest(isPro: true);
    final lines = filterThemeLines(_buildSyntheticLines(), 'love');
    final cands = candidatesForWorld(themeLines: lines, count: 3);
    expect(cands.length, 3);

    await tester.pumpWidget(
      MaterialApp(
        home: ConsultationResultScreen(
          theme: 'love',
          mode: 'travel',
          scope: 'world',
          initialCandidates: cands,
          regenerateCandidates: (excl) async => cands,
          fetchOverride: ({
            required theme,
            required mode,
            required scope,
            required candidates,
            String freeText = '',
            List<String> excluded = const [],
          }) async =>
              ConsultationResult(reading: _mockReading(candidates)),
        ),
      ),
    );
    // 非同期完了まで pump
    await tester.pumpAndSettle();
    expect(find.text('Stella が読み解いています…'), findsNothing);
    // intro/outro は本文から外し、タイトルタップのポップアップに移動 (2026-05-23)
    expect(find.textContaining('モック intro'), findsNothing);
    expect(find.textContaining('世界の全部ではありません'), findsNothing);

    // 最初の候補名が出ている
    expect(find.text(cands.first.nameJP), findsOneWidget);

    // refresh ボタンがある (Pro かつ regenerateCandidates が非 null)
    expect(find.text('もう一度候補を出す'), findsOneWidget);

    // タイトルタップで「この読み解きについて」ポップアップ → intro+outro が出る
    await tester.tap(find.text('相談の結果'));
    await tester.pumpAndSettle();
    expect(find.text('この読み解きについて'), findsOneWidget);
    expect(find.textContaining('モック intro'), findsOneWidget);
    expect(find.textContaining('世界の全部ではありません'), findsOneWidget);
  });

  testWidgets('Result screen shows refresh for Free + 残量バナー (出し直しもクレジット消費)',
      (tester) async {
    // Free でも出し直しボタンは出る (1 クレジット消費)
    final lines = filterThemeLines(_buildSyntheticLines(), 'love');
    final cands = candidatesForWorld(themeLines: lines, count: 3);

    await tester.pumpWidget(
      MaterialApp(
        home: ConsultationResultScreen(
          theme: 'love',
          mode: 'travel',
          scope: 'world',
          initialCandidates: cands,
          regenerateCandidates: (excl) async => cands,
          fetchOverride: ({
            required theme,
            required mode,
            required scope,
            required candidates,
            String freeText = '',
            List<String> excluded = const [],
          }) async =>
              ConsultationResult(
            reading: _mockReading(candidates),
            freeCreditsRemaining: 2,
            freeCreditsLimit: 3,
            purchasedBalance: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 出し直しボタンは Free でも出る
    expect(find.text('もう一度候補を出す'), findsOneWidget);
    // 残量バナーが出る
    expect(find.textContaining('今週の無料相談 あと2回'), findsOneWidget);
  });

  testWidgets('Result screen banner shows purchased balance',
      (tester) async {
    final lines = filterThemeLines(_buildSyntheticLines(), 'love');
    final cands = candidatesForWorld(themeLines: lines, count: 3);

    await tester.pumpWidget(
      MaterialApp(
        home: ConsultationResultScreen(
          theme: 'love',
          mode: 'travel',
          scope: 'world',
          initialCandidates: cands,
          fetchOverride: ({
            required theme,
            required mode,
            required scope,
            required candidates,
            String freeText = '',
            List<String> excluded = const [],
          }) async =>
              ConsultationResult(
            reading: _mockReading(candidates),
            freeCreditsRemaining: 0,
            freeCreditsLimit: 3,
            purchasedBalance: 7,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('購入残高 7回'), findsOneWidget);
  });

  testWidgets('Result screen shows credit purchase + Pro box when exhausted',
      (tester) async {
    final lines = filterThemeLines(_buildSyntheticLines(), 'love');
    final cands = candidatesForWorld(themeLines: lines, count: 3);

    await tester.pumpWidget(
      MaterialApp(
        home: ConsultationResultScreen(
          theme: 'love',
          mode: 'travel',
          scope: 'world',
          initialCandidates: cands,
          fetchOverride: ({
            required theme,
            required mode,
            required scope,
            required candidates,
            String freeText = '',
            List<String> excluded = const [],
          }) async =>
              const ConsultationResult(block: ConsultationBlock.creditExhausted),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('相談クレジットを使い切りました'), findsOneWidget);
    expect(find.text('追加クレジットを購入'), findsOneWidget);
    expect(find.text('✦ Cosmic Pro で無制限にする'), findsOneWidget);
  });

  testWidgets('Result screen shows fallback banner when API returns fallback',
      (tester) async {
    final lines = filterThemeLines(_buildSyntheticLines(), 'love');
    final cands = candidatesForWorld(themeLines: lines, count: 3);

    await tester.pumpWidget(
      MaterialApp(
        home: ConsultationResultScreen(
          theme: 'love',
          mode: 'travel',
          scope: 'world',
          initialCandidates: cands,
          fetchOverride: ({
            required theme,
            required mode,
            required scope,
            required candidates,
            String freeText = '',
            List<String> excluded = const [],
          }) async =>
              const ConsultationResult(
            reading: ConsultationReading(
              intro: 'fallback intro',
              candidates: [],
              outro: 'fallback outro',
              model: 'fallback',
              fallback: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Stella の声が届きませんでした (静的表示)'), findsOneWidget);
  });

  testWidgets('Result screen shows error UI on network failure',
      (tester) async {
    final lines = filterThemeLines(_buildSyntheticLines(), 'love');
    final cands = candidatesForWorld(themeLines: lines, count: 3);

    await tester.pumpWidget(
      MaterialApp(
        home: ConsultationResultScreen(
          theme: 'love',
          mode: 'travel',
          scope: 'world',
          initialCandidates: cands,
          fetchOverride: ({
            required theme,
            required mode,
            required scope,
            required candidates,
            String freeText = '',
            List<String> excluded = const [],
          }) async =>
              const ConsultationResult(), // reading も block も無し = 接続失敗
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('接続に届きませんでした。もう一度試せます。'), findsOneWidget);
    expect(find.text('もう一度試す'), findsOneWidget);
  });
}
