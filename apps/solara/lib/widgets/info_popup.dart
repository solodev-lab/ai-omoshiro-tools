import 'package:flutter/material.dart';

import '../theme/solara_colors.dart';

// ============================================================
// showInfoPopup — 説明ポップアップ統一ヘルパー (2026-05-07 確定)
//
// 目的: ACG / Horo / Map / Cycle 各画面の説明 popup を全て同じ動作に統一する。
//   - 用語解説 (i ボタン)
//   - aspect / pattern / direction energy など「タップで詳細」系
//   全て本ヘルパー経由で表示する。
//
// 統一仕様:
//   - 右上 × ボタン (Stack で固定配置)
//   - 本文は常に SingleChildScrollView でスクロール可能
//   - 外タップ (barrier) で閉じる (barrierDismissible: true)
//   - GlassPanel 互換の見た目 (dark glass + border)
//   - 高さは画面高 - 120px を上限
//
// 使い方:
//   showInfoPopup(
//     context: context,
//     borderColor: aspectColor,    // optional (aspect の quality 色など)
//     child: Column(...内容...),
//   );
//
// child 内で × ボタンを書かないこと。Shell 側が右上に配置する。
// child の右側には × ボタン分の余白 (26px) が自動で確保される。
// ============================================================

/// 説明ポップアップを表示する共通ヘルパー。
///
/// 重複防止のため、新規 popup 表示は必ず本関数を経由すること。
/// 既存の AlertDialog / showModalBottomSheet を popup 用途に新規追加してはならない
/// (時刻ピッカー / 入力ダイアログ / 削除確認 等の機能ダイアログは対象外)。
Future<void> showInfoPopup({
  required BuildContext context,
  required Widget child,
  Color? borderColor,
  double maxWidth = 380,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0x99000000),
    barrierDismissible: true,
    builder: (ctx) {
      final screenH = MediaQuery.of(ctx).size.height;
      final maxH = (screenH - 120).clamp(200.0, double.infinity);
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxH),
          child: _InfoPopupShell(
            borderColor: borderColor,
            child: child,
          ),
        ),
      );
    },
  );
}

class _InfoPopupShell extends StatelessWidget {
  final Color? borderColor;
  final Widget child;
  const _InfoPopupShell({this.borderColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xE60A0A14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? SolaraColors.glassBorder,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Stack(
        children: [
          // 本文 (× ボタンの分だけ右に余白)
          Padding(
            padding: const EdgeInsets.only(right: 26),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: child,
            ),
          ),
          // 右上 × ボタン
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: Color(0xFFAAAAAA),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
