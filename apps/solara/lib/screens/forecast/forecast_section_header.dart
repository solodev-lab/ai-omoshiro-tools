import 'package:flutter/material.dart';

/// Forecast 画面のモダンなセクション見出し。
/// 旧「▸ ラベル」の代わりに、左に金色のアクセントバー + ラベルを置く。
/// [onInfo] があれば ⓘ ボタン、[trailing] があれば右端に表示する。
class ForecastSectionHeader extends StatelessWidget {
  final String label;
  final VoidCallback? onInfo;
  final Widget? trailing;

  const ForecastSectionHeader({
    super.key,
    required this.label,
    this.onInfo,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      // 金色のアクセントバー (▸ の代わり)。
      Container(
        width: 3,
        height: 15,
        decoration: BoxDecoration(
          color: const Color(0xFFC9A84C),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      // ラベル + ⓘ を 1 グループにして Expanded で左側いっぱいに広げる。
      // ⓘ は「文字の直後」に付き、ラベルは折返さず最後まで表示される
      // (旧実装は Flexible(label) と Spacer() がフリースペースを 50/50 で
      //  奪い合い、英語の長い見出しが "Highlights To…" に見切れていた)。
      Expanded(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFEAD9A8),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            if (onInfo != null)
              GestureDetector(
                onTap: onInfo,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(Icons.info_outline,
                      size: 14, color: Color(0xCCAAAAAA)),
                ),
              ),
          ],
        ),
      ),
      // trailing (例: 年表示) は右端へ。Expanded が間を埋めるので Spacer 不要。
      ?trailing,
    ]);
  }
}
