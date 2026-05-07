import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/info_popup.dart';
import 'horo_antique_icons.dart';
import 'horo_aspect_description.dart';
import 'horo_desc_section.dart';
import 'horo_constants.dart';
import 'horo_panel_shared.dart';

// ══════════════════════════════════════════════════
// Aspect List
// HTML: aspect-lists-row in analysis-body
// ══════════════════════════════════════════════════

class HoroAspectList extends StatelessWidget {
  final List<Map<String, dynamic>> filteredAspects;
  final Set<String> hiddenAspects;
  final ValueChanged<String> onToggleAspect;
  const HoroAspectList({super.key, required this.filteredAspects, required this.hiddenAspects, required this.onToggleAspect});

  void _showAspectDescription(BuildContext context, Map<String, dynamic> a) {
    final p1 = a['p1'] as String;
    final p2 = a['p2'] as String;
    final type = a['type'] as String;
    final color = a['color'] as Color;
    final diff = a['diff'] as double;
    final desc = buildAspectDescription(p1, p2, type);

    // 2026-05-07: showModalBottomSheet → showInfoPopup へ統一移行。
    // 右上 × / 全文スクロール / 外タップ閉じが Shell 側で自動提供される。
    showInfoPopup(
      context: context,
      borderColor: color.withAlpha(120),
      child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row: planet × planet with icons
          Row(children: [
            PlanetVectorIcon(planetKey: p1, size: 22),
            const SizedBox(width: 6),
            Text(horoPlanetOrAngleName(p1), style: GoogleFonts.cinzel(
              fontSize: 17, color: const Color(0xFFE8E0D0),
              fontWeight: FontWeight.w600)),
            const SizedBox(width: 10),
            Text('×', style: TextStyle(fontSize: 17,
              color: color.withAlpha(200))),
            const SizedBox(width: 10),
            PlanetVectorIcon(planetKey: p2, size: 22),
            const SizedBox(width: 6),
            Text(horoPlanetOrAngleName(p2), style: GoogleFonts.cinzel(
              fontSize: 17, color: const Color(0xFFE8E0D0),
              fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 14),
          // Aspect badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withAlpha(90)),
            ),
            child: Text(desc['aspect'] ?? '',
              style: TextStyle(fontSize: 14, color: color,
                fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 6),
          Text('オーブ ${diff.toStringAsFixed(2)}°',
            style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
          const SizedBox(height: 18),
          // Quality summary
          HoroDescSection('性質', desc['summary'] ?? '', color),
          const SizedBox(height: 14),
          // Theme
          HoroDescSection('テーマ', desc['theme'] ?? '', const Color(0xFFF6BD60)),
          const SizedBox(height: 14),
          // Reading
          HoroDescSection('読み解き', desc['reading'] ?? '', const Color(0xFFF6BD60)),
        ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (filteredAspects.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('アスペクトなし', style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      horoAntiqueHeader(AntiqueIcon.aspects, 'ASPECTS (${filteredAspects.length})'),
      const Padding(
        padding: EdgeInsets.only(top: 2, bottom: 6),
        child: Text('左チェック＝ON/OFF切替 ／ 右ラベル＝解説を開く',
          style: TextStyle(fontSize: 11, color: Color(0x80888888), fontStyle: FontStyle.italic)),
      ),
      ...filteredAspects.take(15).map((a) {
        final key = '${a['type']}_${a['p1']}_${a['p2']}';
        final isHidden = hiddenAspects.contains(key);
        final isDimmed = a['dimmed'] as bool? ?? false;
        final isOff = isHidden || isDimmed;
        final aspColor = a['color'] as Color;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0x08FFFFFF))),
          ),
          child: Row(children: [
            // Antique checkmark toggle (tap = ON/OFF)
            GestureDetector(
              onTap: () => onToggleAspect(key),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: HoroAspectCheckmark(active: !isOff, color: aspColor),
              ),
            ),
            const SizedBox(width: 4),
            // Row body (dimmed when off) — NOT tappable; only badge is.
            // 2026-05-04 overflow 修正:
            //   - 惑星名 Text を Flexible + ellipsis で縮め可能に
            //   - Aspect badge から日本語名削除 (symbol + 度数のみ) → 詳細はタップで dialog
            Expanded(child: Opacity(
              opacity: isOff ? 0.25 : 1.0,
              child: Row(children: [
                PlanetVectorIcon(planetKey: a['p1'] as String, size: 16),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(horoPlanetOrAngleName(a['p1'] as String),
                    style: const TextStyle(color: Color(0xFFE8E0D0), fontSize: 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Text(' — ', style: TextStyle(color: aspColor.withAlpha(180), fontSize: 13)),
                PlanetVectorIcon(planetKey: a['p2'] as String, size: 16),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(horoPlanetOrAngleName(a['p2'] as String),
                    style: const TextStyle(color: Color(0xFFE8E0D0), fontSize: 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 6),
                Text('${(a['diff'] as double).toStringAsFixed(1)}°',
                  style: const TextStyle(color: Color(0xFF888888), fontSize: 13)),
                const SizedBox(width: 4),
                // Aspect badge (tap = show description)
                GestureDetector(
                  onTap: () => _showAspectDescription(context, a),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: aspColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: aspColor.withAlpha(80)),
                    ),
                    child: Text(
                      '${aspectSymbol[a['type']] ?? ''} ${(a['aspectAngle'] as double?)?.toInt() ?? 0}°',
                      style: TextStyle(color: aspColor, fontSize: 11)),
                  ),
                ),
              ]),
            )),
          ]),
        );
      }),
      if (filteredAspects.length > 15)
        Padding(padding: const EdgeInsets.only(top: 4),
          child: Text('... 他${filteredAspects.length - 15}件',
            style: const TextStyle(color: Color(0x99888888), fontSize: 13))),
    ]);
  }
}
