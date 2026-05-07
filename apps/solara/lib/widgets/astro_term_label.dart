import 'package:flutter/material.dart';

import '../utils/astro_glossary.dart';

/// ============================================================
/// AstroTermLabel — Phase M2 論点4 (β案)
///
/// 占星術専門用語ラベル + i アイコン。タップで用語解説を popup 表示。
///
/// 2026-05-07: popup 実装は [showAstroGlossaryDialog] (utils/astro_glossary.dart)
/// に集約。本 widget は trigger 役のみ持つ。
///
/// 使用例:
///   AstroTermLabel(
///     termKey: 'asc',
///     child: Text('ASC', style: ...),
///   )
/// ============================================================
class AstroTermLabel extends StatelessWidget {
  /// astroGlossary の key (例: 'asc', 'mc', 'house_7', 'relocation')
  final String termKey;

  /// 表示する子ウィジェット (テキスト等)
  final Widget child;

  /// i アイコンサイズ
  final double iconSize;

  /// アイコン色
  final Color? iconColor;

  /// アイコンと child の間隔
  final double spacing;

  // 2026-04-29: タップ領域を確保するため iconSize 11→16 のデフォルトに引き上げ。
  // 周囲に EdgeInsets.all(8) を入れて 32×32px のタップ領域を確保。
  const AstroTermLabel({
    super.key,
    required this.termKey,
    required this.child,
    this.iconSize = 16,
    this.iconColor,
    this.spacing = 3,
  });

  @override
  Widget build(BuildContext context) {
    final entry = astroGlossary[termKey];
    if (entry == null) return child; // 辞書未登録なら i アイコンも出さない

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ラベル本体タップ → 用語解説 popup
        GestureDetector(
          onTap: () => showAstroGlossaryDialog(context, termKey),
          behavior: HitTestBehavior.opaque,
          child: child,
        ),
        SizedBox(width: spacing),
        // i アイコン本体: 周囲 8px パディングでタップ領域 32×32px を確保
        GestureDetector(
          onTap: () => showAstroGlossaryDialog(context, termKey),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.info_outline,
              size: iconSize,
              color: iconColor ?? const Color(0xCCAAAAAA),
            ),
          ),
        ),
      ],
    );
  }
}
