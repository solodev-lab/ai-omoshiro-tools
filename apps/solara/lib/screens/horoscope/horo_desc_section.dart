import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// アスペクト/パターン解説の「ラベル + 本文」セクション。
///
/// horo_aspect_list.dart の `_descSection` と horo_prediction_panel.dart の
/// `_patternDescSection` が別名・完全同一実装で重複していたため集約 (2026-05-04)。
///
/// 注: `screens/map/map_aspect_chip.dart:203` にも類似の `_descSection` が
/// 存在するが、フォント (Cinzel 不使用) が違うため別 widget のまま残す。
///
/// Positional 引数で旧 `_descSection(label, body, accent)` 形式と互換。
class HoroDescSection extends StatelessWidget {
  final String label;
  final String body;
  final Color accent;

  const HoroDescSection(this.label, this.body, this.accent, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.cinzel(
        fontSize: 12, color: accent.withAlpha(220),
        letterSpacing: 2.0, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(body, style: const TextStyle(
        fontSize: 15, color: Color(0xE6E8E0D0), height: 1.7)),
    ]);
  }
}
