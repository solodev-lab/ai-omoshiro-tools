import 'package:flutter/material.dart';

/// HTML: .stella { bottom:90px; left:20px; right:20px;
///   background:rgba(15,15,30,.75); border-radius:16px; padding:16px 20px; }
///
/// 日本語フォントは solara_theme.dart のテーマ fontFamilyFallback 経由で
/// Noto Sans JP が自動適用される（個別指定不要）。
class Stella extends StatelessWidget {
  const Stella({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xBF0F0F1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          const Text('✨ Stella', style: TextStyle(
            fontSize: 10, letterSpacing: 2, color: Color(0xFF6B5CE7))),
          const Spacer(),
          const Text('▼', style: TextStyle(fontSize: 8, color: Color(0xFF555555))),
        ]),
        const SizedBox(height: 4),
        // Text.rich は DefaultTextStyle を継承するので theme の Noto Sans JP fallback が効く。
        // RichText を使うと継承されず日本語フォールバックが無効になる点に注意。
        const Text.rich(TextSpan(
          style: TextStyle(fontSize: 13, color: Color(0xFFEAEAEA), height: 1.6),
          children: [
            TextSpan(text: '『再会の喜び』', style: TextStyle(color: Color(0xFFC9A84C), fontWeight: FontWeight.w600)),
            TextSpan(text: 'が今日の種。北東の風が、懐かしい誰かとの縁を運んでくるよ。'),
          ],
        )),
      ]),
    );
  }
}

/// Stella minimized state
class StellaMinimized extends StatelessWidget {
  const StellaMinimized({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xBF0F0F1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Text('✨ Stella', style: TextStyle(fontSize: 9, letterSpacing: 1, color: Color(0xFF6B5CE7))),
        SizedBox(width: 6),
        Text('▲', style: TextStyle(fontSize: 8, color: Color(0xFF555555))),
      ]),
    );
  }
}
