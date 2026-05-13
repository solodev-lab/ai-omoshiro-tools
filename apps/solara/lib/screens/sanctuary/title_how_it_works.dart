import 'package:flutter/material.dart';

/// 称号システムの仕組み説明 popup の中身。
///
/// `showInfoPopup(child: const TitleHowItWorksContent())` の形で使用。
/// Shell 側で × ボタンと外枠を提供するため、本ウィジェット自身は
/// 中身 (見出し + 6 ステップ + フッターメモ) のみを返す。
///
/// 元は sanctuary_title_diagnosis.dart 内の private class `_HowItWorksContent`
/// として実装されていたが、行数肥大化 (1568 行) のため分離。
class TitleHowItWorksContent extends StatelessWidget {
  const TitleHowItWorksContent({super.key});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFF9D976);
    const body = Color(0xFFEAEAEA);
    const sub = Color(0xCCACACAC);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // タイトル
            const Text(
              '✦ 称号の仕組み',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: gold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 14),

            // 1. 一言
            _section(
              num: '1',
              title: '生年月日 → 一言',
              body:
                  '太陽星座 × 月星座の組み合わせから、144通りの「一言の称号」が決まります。\n'
                  'これはあなた固有のもの。診断では変わりません。',
              gold: gold,
              bodyColor: body,
            ),
            const SizedBox(height: 14),

            // 2. 5軸
            _section(
              num: '2',
              title: '28問の選択 → 5軸スコア',
              body:
                  'PART 1 (日常) と PART 2 (運命) の問いに、直感でカードを選ぶと、'
                  '5つの軸 (パワー・マインド・スピリット・シャドー・ハート) に'
                  '点数が加算されます。\n'
                  '最高得点の軸があなたの「気質」になります。',
              gold: gold,
              bodyColor: body,
            ),
            const SizedBox(height: 14),

            // 3. コート
            _section(
              num: '3',
              title: 'PART 3 → コート (役職)',
              body:
                  '4問のコートカードで、page・knight・queen・king のうち'
                  '2回以上選んだものがあなたのコートに。'
                  'バラバラなら mixed (混合) になります。',
              gold: gold,
              bodyColor: body,
            ),
            const SizedBox(height: 14),

            // 4. クラス
            _section(
              num: '4',
              title: '軸 × コート → 25クラス',
              body:
                  '5軸 × 5コート = 25種類のクラス (騎士・賢者・占星術師・忍者…) '
                  'から、あなたに合うクラスが1つ決まります。',
              gold: gold,
              bodyColor: body,
            ),
            const SizedBox(height: 14),

            // 5. Light/Shadow
            _section(
              num: '5',
              title: 'Light面 / Shadow面',
              body:
                  '結果画面はタップすると、表 (Light=光) と裏 (Shadow=影) を'
                  '切替できます。\n'
                  '光は長所、影はユーモア混じりの「あるある」です。',
              gold: gold,
              bodyColor: body,
            ),
            const SizedBox(height: 14),

            // 6. 同点処理 — 占星術シード
            _section(
              num: '6',
              title: '同点処理 — 占星術シード',
              body:
                  '軸やコートが同点になったとき、太陽星座 × 月星座'
                  ' (144通り) から1つに決めます。\n'
                  '判定の主役はあなたが選んだカードそのもの。違うカードを'
                  '選べば違う結果が出ます。\n'
                  '占星術シードは「審判が困ったときの最後の判定基準」のポジションです。',
              gold: gold,
              bodyColor: body,
            ),
            const SizedBox(height: 18),

            // フッターメモ
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x14F9D976),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x33F9D976)),
              ),
              child: const Text(
                '※ いつでももう一度診断できます。気質はその日の気分で動くもの。'
                '「いまの自分」を映す鏡として楽しんでください。',
                style: TextStyle(
                  fontSize: 12,
                  color: sub,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({
    required String num,
    required String title,
    required String body,
    required Color gold,
    required Color bodyColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: gold, width: 1),
              ),
              child: Text(
                num,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: gold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: gold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: Text(
            body,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: bodyColor,
            ),
          ),
        ),
      ],
    );
  }
}
