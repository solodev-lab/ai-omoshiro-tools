import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';

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
            Text(
              t.titleHow.title,
              style: const TextStyle(
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
              title: t.titleHow.s1Title,
              body: t.titleHow.s1Body,
              gold: gold,
              bodyColor: body,
            ),
            const SizedBox(height: 14),

            // 2. 5軸
            _section(
              num: '2',
              title: t.titleHow.s2Title,
              body: t.titleHow.s2Body,
              gold: gold,
              bodyColor: body,
            ),
            const SizedBox(height: 14),

            // 3. コート
            _section(
              num: '3',
              title: t.titleHow.s3Title,
              body: t.titleHow.s3Body,
              gold: gold,
              bodyColor: body,
            ),
            const SizedBox(height: 14),

            // 4. クラス
            _section(
              num: '4',
              title: t.titleHow.s4Title,
              body: t.titleHow.s4Body,
              gold: gold,
              bodyColor: body,
            ),
            const SizedBox(height: 14),

            // 5. Light/Shadow
            _section(
              num: '5',
              title: t.titleHow.s5Title,
              body: t.titleHow.s5Body,
              gold: gold,
              bodyColor: body,
            ),
            const SizedBox(height: 14),

            // 6. 同点処理 — 占星術シード
            _section(
              num: '6',
              title: t.titleHow.s6Title,
              body: t.titleHow.s6Body,
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
              child: Text(
                t.titleHow.footer,
                style: const TextStyle(
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
