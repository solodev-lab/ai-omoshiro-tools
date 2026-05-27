import 'package:flutter/material.dart';

/// AI 出力 disclaimer フッター (Apple 4.0 + Google Misleading Claims policy 対応)。
///
/// 設計根拠: apps/solara/docs/store_compliance.md §5.1 / §5.2 B
///
/// AI 生成の占い結果すべての直下に常時表示する 1 行 disclaimer。
/// AiReportButton の直下に並べる (=「報告できる」+「これはエンタメ」の 2 段構え)。
/// Google Play 審査の Misleading Claims 検査 + Apple 4.0 (User Interface) 検査の
/// 両方の予防線になる。文言は短く、UI を邪魔しない控えめサイズ・グレー文字。
///
/// Web の terms.html / プライバシーポリシーには長文の disclaimer があるが、
/// アプリ画面で見える必要があるため、各 AI 結果画面に直接配置する。
class AiDisclaimerFooter extends StatelessWidget {
  final EdgeInsets padding;
  const AiDisclaimerFooter({
    super.key,
    this.padding = const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: const Text(
        '✦ AI 生成・娯楽目的。医療・法律・金融等の専門的な助言ではありません。',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF666060),
          fontSize: 10,
          height: 1.5,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
