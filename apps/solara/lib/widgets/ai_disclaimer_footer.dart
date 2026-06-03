import 'package:flutter/material.dart';

import '../utils/solara_i18n.dart';

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
      child: Text(
        tr('disclaimer.ai'),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF666060),
          fontSize: 10,
          height: 1.5,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Stella の出力は「解釈の 1 つ」であることを伝える注記 (画面ごとに文面が異なる)。
/// 配置順: AiReportButton (不適切な内容を報告) → 本注記 → [AiDisclaimerFooter] (AI 生成・娯楽目的)。
/// AiDisclaimerFooter より少し読ませる必要があるので、わずかに明るめ・大きめにする。
class StellaInterpretationNote extends StatelessWidget {
  final String text;
  final EdgeInsets padding;
  const StellaInterpretationNote({
    super.key,
    required this.text,
    this.padding = const EdgeInsets.fromLTRB(12, 6, 12, 2),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF8C8680),
          fontSize: 10.5,
          height: 1.6,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
