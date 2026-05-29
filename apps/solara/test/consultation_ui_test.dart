// Widget test: ConsultationInputScreen + ConsultationResultScreen (V2)。
//
// Worker は呼ばない (fetchOverride で差替)。入力は SolaraProfile (mock) から
// ConsultationRequest を組む。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:solara/screens/consultation/consultation_input_screen.dart';
import 'package:solara/screens/consultation/consultation_result_screen.dart';
import 'package:solara/utils/consultation_api.dart';
import 'package:solara/utils/consultation_v2_api.dart';
import 'package:solara/utils/pro_status.dart';
import 'package:solara/utils/solara_storage.dart';

const _profile = SolaraProfile(
  name: 'Test',
  birthDate: '1990-04-12',
  birthTime: '08:30',
  birthPlace: 'Tokyo',
  birthLat: 35.68,
  birthLng: 139.76,
  birthTz: 9,
  birthTzName: 'Asia/Tokyo',
  homeName: 'Home',
  homeLat: 35.17,
  homeLng: 136.88,
);

ConsultationRequest _req() => ConsultationRequest.fromProfile(
      _profile,
      theme: 'love',
      mode: 'travel',
    );

ConsultationV2Reading _reading({
  bool isFirst = true,
  String name = '京都',
  int remainingAfter = 2,
  bool fallback = false,
}) {
  return ConsultationV2Reading(
    isFirst: isFirst,
    candidate: ConsultationV2Candidate(
      name: name,
      lat: 35,
      lng: 135,
      characterHeadline: '愛の軸が立つ場',
      energyLabels: const ['金星 MC・愛の軸'],
      narrative: '$name のモック narrative。テスト用の text。',
      timeWindow:
          const ConsultationTimeWindow(kind: 'single', bucket: 'evening', label: '夜'),
    ),
    evidence: const ConsultationEvidence(
      factors: ['金星MC合', '進行の月: 蟹座4室'],
      km: [ConsultationEvidenceKm(factor: '金星MC合', km: 120)],
    ),
    innerSeason: isFirst ? '今のあなたは根に意識が向かう内的な季節です' : '',
    intro: isFirst ? 'モック intro の前置き' : '',
    outro: isFirst ? '候補は世界の全部ではありません' : '',
    remainingAfter: remainingAfter,
    fallback: fallback,
    timeWindow:
        const ConsultationTimeWindow(kind: 'single', bucket: 'evening', label: '夜'),
  );
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await ProStatus.instance.resetForTest(isPro: false);
    await SolaraStorage.saveProfile(_profile);
  });

  // ── 入力画面 ──────────────────────────────────────────

  testWidgets('Input: 場面を選ぶと いつ/どこで が現れる', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ConsultationInputScreen(currentLocation: LatLng(35.17, 136.88)),
    ));
    await tester.pumpAndSettle();

    expect(find.text('どんな場面で？'), findsOneWidget);
    expect(find.text('何のテーマで観たい？'), findsOneWidget);
    expect(find.text('いつ？'), findsNothing);
    expect(find.text('どこで？'), findsNothing);

    // モード 3 択
    expect(find.textContaining('おでかけ'), findsOneWidget);
    expect(find.text('旅行'), findsOneWidget);
    expect(find.text('移住'), findsOneWidget);

    await tester.tap(find.text('移住'));
    await tester.pumpAndSettle();
    expect(find.text('いつ？'), findsOneWidget);
    expect(find.text('どこで？'), findsOneWidget);
    expect(find.text('相談を始める'), findsOneWidget);
  });

  testWidgets('Input: テーマ+場面+範囲 で submit が有効化', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ConsultationInputScreen(currentLocation: LatLng(35.17, 136.88)),
    ));
    await tester.pumpAndSettle();

    ElevatedButton btn() => tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '相談を始める'));
    expect(btn().onPressed, isNull);

    await tester.tap(find.text('恋愛・関係'));
    await tester.pumpAndSettle();
    expect(btn().onPressed, isNull, reason: 'テーマだけでは不足');

    await tester.tap(find.text('移住'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('世界全体'));
    await tester.pumpAndSettle();
    expect(btn().onPressed, isNotNull, reason: 'テーマ+場面+範囲で有効');
  });

  testWidgets('Input: 場面で scope 選択肢が変わる', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ConsultationInputScreen(currentLocation: LatLng(35.17, 136.88)),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('移住'));
    await tester.pumpAndSettle();
    expect(find.text('世界全体'), findsOneWidget);
    expect(find.text('自国内'), findsOneWidget);
    expect(find.text('方角'), findsNothing);

    await tester.tap(find.textContaining('おでかけ'));
    await tester.pumpAndSettle();
    expect(find.text('方角'), findsOneWidget);
    expect(find.text('現住所から半径'), findsOneWidget);
    expect(find.text('世界全体'), findsNothing);
  });

  testWidgets('Input: 具体地点(preset無し)で picker が出て地点未選択は submit 不可',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ConsultationInputScreen(currentLocation: LatLng(35.17, 136.88)),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('恋愛・関係'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('旅行'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('具体地点'));
    await tester.pumpAndSettle();

    expect(find.text('地点を選ぶ'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '地図で選ぶ'), findsOneWidget);

    final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '相談を始める'));
    expect(btn.onPressed, isNull, reason: '具体地点 + 地点未選択は submit 不可');
  });

  testWidgets('Input: preset があると picker は出ず preset カードが出る',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ConsultationInputScreen(
        presetTarget: const ConsultationPresetTarget(
          position: LatLng(35.0, 135.7),
          nameJP: '京都',
          nameEN: 'Kyoto',
          country: 'JP',
          region: '京都府',
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // §0.2.15: preset でも初期は mode/scope 未選択。おでかけ→具体地点 を選ぶと、
    // picker ではなく preset カードが出る。
    await tester.tap(find.textContaining('おでかけ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('具体地点'));
    await tester.pumpAndSettle();

    expect(find.text('地点を選ぶ'), findsNothing);
    expect(find.textContaining('を見ます'), findsOneWidget);
  });

  // ── 結果画面 ──────────────────────────────────────────

  testWidgets('Result: 候補+特徴見出し+内的季節+別の候補地ボタン', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ConsultationResultScreen(
        request: _req(),
        fetchOverride: (req) async => ConsultationV2Result(reading: _reading()),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Stella が読み解いています…'), findsNothing);
    expect(find.text('京都'), findsOneWidget);
    expect(find.text('愛の軸が立つ場'), findsOneWidget);
    // 2026-05-26: 「内的季節」常設バナーは結果画面上部から撤去。
    // 文章は AppBar タイトルタップの「この読み解きについて」popup に残る。
    expect(find.text('別の候補地を見る'), findsOneWidget); // remainingAfter>0

    // タイトルタップで「この読み解きについて」(intro/outro/evidence + 内的季節)
    await tester.tap(find.text('相談の結果'));
    await tester.pumpAndSettle();
    expect(find.text('この読み解きについて'), findsOneWidget);
    expect(find.textContaining('内的な季節'), findsOneWidget); // popup 内に残る
    expect(find.textContaining('モック intro'), findsOneWidget);
    expect(find.textContaining('世界の全部ではありません'), findsOneWidget);
    expect(find.textContaining('金星MC合'), findsWidgets);
  });

  // 2026-05-26: 「Result: Free 残量バナー」「Result: 購入残高バナー」テストは撤去。
  // クレジット残バナーは結果画面から撤去し、Sanctuary 上部 + 入力画面の
  // 開始ポップアップに集約したため、ここで検証する対象がなくなった。

  testWidgets('Result: クレジット切れ 402 で購入+Pro ボックス', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ConsultationResultScreen(
        request: _req(),
        fetchOverride: (req) async =>
            const ConsultationV2Result(block: ConsultationBlock.creditExhausted),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('相談クレジットを使い切りました'), findsOneWidget);
    expect(find.text('追加クレジットを購入'), findsOneWidget);
    expect(find.text('✦ Cosmic Pro で無制限にする'), findsOneWidget);
  });

  testWidgets('Result: fallback チップ', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ConsultationResultScreen(
        request: _req(),
        fetchOverride: (req) async =>
            ConsultationV2Result(reading: _reading(fallback: true)),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Stella の声が届きませんでした (静的表示)'), findsOneWidget);
  });

  testWidgets('Result: 接続失敗で error UI', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ConsultationResultScreen(
        request: _req(),
        fetchOverride: (req) async => const ConsultationV2Result(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('接続に届きませんでした。もう一度試せます。'), findsOneWidget);
    expect(find.text('もう一度試す'), findsOneWidget);
  });

  testWidgets('Result: 「別の候補地」で 2 枚目を append しスワイプ', (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: ConsultationResultScreen(
        request: _req(),
        fetchOverride: (req) async {
          calls++;
          if (req.isFirst) return ConsultationV2Result(reading: _reading(name: '京都'));
          return ConsultationV2Result(
              reading: _reading(isFirst: false, name: '大阪', remainingAfter: 0));
        },
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('京都'), findsOneWidget);

    await tester.tap(find.text('別の候補地を見る'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('大阪'), findsOneWidget); // 2 枚目に遷移
    // remainingAfter=0 なのでボタンは消える
    expect(find.text('別の候補地を見る'), findsNothing);
  });

  // C-1 (Phase B 反映): 出し尽くし(案Y)で代替提案パネル + クレジット非消費の明示。
  testWidgets('Result: 出し尽くし(案Y)で代替提案 + 非消費の明示', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ConsultationResultScreen(
        request: _req(),
        fetchOverride: (req) async {
          if (req.isFirst) {
            return ConsultationV2Result(reading: _reading(name: '京都', remainingAfter: 1));
          }
          return const ConsultationV2Result(
            exhausted: true,
            exhaustedReason: 'allQuiet',
            suggestions: ['widenRadius', 'world'],
          );
        },
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('別の候補地を見る'));
    await tester.pumpAndSettle();

    expect(find.text('半径を広げてみる'), findsOneWidget);
    expect(find.text('世界全体に広げる'), findsOneWidget);
    expect(find.textContaining('クレジットを消費していません'), findsOneWidget);
    expect(find.text('別の候補地を見る'), findsNothing); // 出し尽くしたのでボタンは消える
  });

  // C-1 (Phase B 反映): 実在の町は字幕に方角・距離、生の国コード「JP」は出さない。
  testWidgets('Result: 実在の町は字幕に方角・距離、生の国コードは出さない', (tester) async {
    final townReading = ConsultationV2Reading(
      isFirst: true,
      candidate: const ConsultationV2Candidate(
        name: '鎌倉',
        lat: 35.31,
        lng: 139.55,
        country: 'JP',
        region: '神奈川県',
        directionFromHome: '南西',
        directionCode: 'SW',
        distanceKm: 30,
        characterHeadline: '愛の軸が立つ場',
        energyLabels: ['金星 MC・愛の軸'],
        narrative: '鎌倉のモック narrative。',
      ),
      evidence: const ConsultationEvidence(factors: ['金星MC合']),
      remainingAfter: 0,
    );
    await tester.pumpWidget(MaterialApp(
      home: ConsultationResultScreen(
        request: _req(),
        fetchOverride: (req) async => ConsultationV2Result(reading: townReading),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('鎌倉'), findsOneWidget);
    expect(find.textContaining('神奈川県'), findsOneWidget); // 県名
    expect(find.textContaining('南西'), findsOneWidget); // 方角
    expect(find.textContaining('約30km'), findsOneWidget); // 距離
    expect(find.textContaining('· JP'), findsNothing); // 生の国コードは出さない
  });
}
