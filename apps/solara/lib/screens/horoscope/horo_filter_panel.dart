import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'horo_antique_icons.dart';
import 'horo_panel_shared.dart';

// ══════════════════════════════════════════════════
// Filter Panel
// HTML: .filter-section, .filter-chips, .filter-chip
// ══════════════════════════════════════════════════

class HoroFilterPanel extends StatelessWidget {
  final Map<String, bool> qualityFilters;
  final Map<String, bool> pgroupFilters;
  final String? fortuneFilter;
  final VoidCallback onReset;
  final void Function(String key, bool value) onQualityChanged;
  final void Function(String key, bool value) onPgroupChanged;
  final ValueChanged<String?> onFortuneChanged;

  const HoroFilterPanel({
    super.key,
    required this.qualityFilters,
    required this.pgroupFilters,
    required this.fortuneFilter,
    required this.onReset,
    required this.onQualityChanged,
    required this.onPgroupChanged,
    required this.onFortuneChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        horoAntiqueHeader(AntiqueIcon.filter, 'ASPECT FILTER'),
        GestureDetector(
          onTap: onReset,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            child: Text('RESET', style: GoogleFonts.cinzel(
              fontSize: 11, color: const Color(0xFF888888),
              letterSpacing: 2.0, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
      const SizedBox(height: 10),

      // A: Aspect Quality
      _filterSection('A', 'アスペクト性質', [
        _filterChip('ソフト（調和）', 'soft', const Color(0xFFC9A84C), qualityFilters['soft']!, (v) => onQualityChanged('soft', v)),
        _filterChip('ハード（緊張）', 'hard', const Color(0xFF6B5CE7), qualityFilters['hard']!, (v) => onQualityChanged('hard', v)),
        _filterChip('中立', 'neutral', const Color(0xFF26D0CE), qualityFilters['neutral']!, (v) => onQualityChanged('neutral', v)),
      ]),

      // B: Fortune Category
      _filterSection('B', '運勢カテゴリ', [
        _exclusiveChip('癒し', 'healing', const Color(0xFF26D0CE)),
        _exclusiveChip('金運', 'money', const Color(0xFFFFD370)),
        _exclusiveChip('恋愛運', 'love', const Color(0xFFFF6B9D)),
        _exclusiveChip('仕事運', 'career', const Color(0xFFFF8C42)),
        _exclusiveChip('コミュニケーション', 'communication', const Color(0xFF6BB5FF)),
      ]),

      // C: Planet Group
      _filterSection('C', '惑星グループ', [
        _filterChip('個人天体', 'personal', const Color(0xFFFFD370), pgroupFilters['personal']!, (v) => onPgroupChanged('personal', v)),
        _filterChip('社会天体', 'social', const Color(0xFF6BB5FF), pgroupFilters['social']!, (v) => onPgroupChanged('social', v)),
        _filterChip('世代天体', 'generational', const Color(0xFFB088FF), pgroupFilters['generational']!, (v) => onPgroupChanged('generational', v)),
      ]),
    ]);
  }

  Widget _filterSection(String badge, String title, List<Widget> chips) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0DFFFFFF))),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(badge, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFFAAAAAA))),
          ),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(fontSize: 10, color: Color(0xFF888888), letterSpacing: 1.5)),
        ]),
        const SizedBox(height: 6),
        Wrap(spacing: 4, runSpacing: 4, children: chips),
      ]),
    );
  }

  Widget _filterChip(String label, String key, Color color, bool active, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!active),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? color : const Color(0x1AFFFFFF)),
          color: active ? color.withAlpha(20) : const Color(0x08FFFFFF),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, color: active ? color : const Color(0xFF888888))),
      ),
    );
  }

  Widget _exclusiveChip(String label, String key, Color color) {
    final active = fortuneFilter == key;
    return GestureDetector(
      onTap: () => onFortuneChanged(active ? null : key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? color : const Color(0x1AFFFFFF)),
          color: active ? color.withAlpha(20) : const Color(0x08FFFFFF),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, color: active ? color : const Color(0xFF888888))),
      ),
    );
  }
}
