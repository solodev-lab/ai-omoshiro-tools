import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/astro_glossary.dart';
import 'glass_panel.dart';

/// ============================================================
/// AstroTermLabel — Phase M2 論点4 (β案)
///
/// 占星術専門用語ラベル + i アイコン。タップで用語解説を
/// グラスモーフィズム popup で表示する。
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
    if (entry == null) return child; // 辞書未登録ならそのまま表示

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ラベルだけタップ → 用語解説（タップ領域は文字部分相当）
        GestureDetector(
          onTap: () => _showGlossary(context, entry),
          behavior: HitTestBehavior.opaque,
          child: child,
        ),
        SizedBox(width: spacing),
        // i アイコン本体: 周囲 8px パディングでタップ領域 32×32px を確保
        GestureDetector(
          onTap: () => _showGlossary(context, entry),
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

  void _showGlossary(BuildContext context, AstroGlossaryEntry entry) {
    showDialog<void>(
      context: context,
      barrierColor: const Color(0x99000000),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
        child: GlassPanel(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.title,
                        style: GoogleFonts.notoSansJp(
                          fontSize: 14,
                          color: const Color(0xFFC9A84C),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  entry.summary,
                  style: GoogleFonts.notoSansJp(
                    fontSize: 11,
                    color: const Color(0xFFAAAAAA),
                    height: 1.5,
                    letterSpacing: 0.3,
                  ),
                ),
                const Divider(color: Color(0x22FFFFFF), height: 18),
                Text(
                  entry.detail,
                  style: GoogleFonts.notoSansJp(
                    fontSize: 12,
                    color: const Color(0xFFE8E0D0),
                    height: 1.7,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
