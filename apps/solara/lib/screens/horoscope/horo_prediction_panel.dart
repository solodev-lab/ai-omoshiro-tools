import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'horo_antique_icons.dart';
import 'horo_aspect_description.dart';
import 'horo_constants.dart';
import 'horo_panel_shared.dart';

// ══════════════════════════════════════════════════
// Pattern Prediction Panel
// HTML: renderPredictions()
// ══════════════════════════════════════════════════

/// Prediction panel widget
///
/// `hiddenPatterns` にキーが含まれるアクティブパターン／予測は OFF 表示。
/// キー生成は [horoActivePatternKey] と [horoPredictionKey] を使用。
class HoroPredictionPanel extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> activePatterns;
  final List<Map<String, dynamic>> predictions;
  final Set<String> hiddenPatterns;
  /// トグル対象のキー (horoActivePatternKey or horoPredictionKey)
  final ValueChanged<String> onPatternToggle;
  const HoroPredictionPanel({
    super.key,
    required this.activePatterns,
    required this.predictions,
    required this.hiddenPatterns,
    required this.onPatternToggle,
  });

  @override
  Widget build(BuildContext context) {
    final hasActive = activePatterns.values.any((l) => l.isNotEmpty);
    if (!hasActive && predictions.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      horoAntiqueHeader(AntiqueIcon.pattern, 'PATTERN PREDICTIONS'),
      const Padding(
        padding: EdgeInsets.only(top: 2, bottom: 6),
        child: Text('左チェック＝ON/OFF切替 ／ 右ラベル＝解説を開く',
          style: TextStyle(fontSize: 11, color: Color(0x80888888), fontStyle: FontStyle.italic)),
      ),

      // Active patterns
      for (final type in ['grandtrine', 'tsquare', 'yod'])
        for (final p in activePatterns[type] ?? [])
          _activeItem(context, type, p),

      // Upcoming predictions
      for (final pred in predictions)
        _predictionItem(context, pred),
    ]);
  }

  void _showPatternDescription(BuildContext context, String type, Color color) {
    final data = patternDescriptions[type];
    if (data == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xF00C0C16),
      barrierColor: Colors.black54,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 4,
          bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: SizedBox(
                    width: 22, height: 22,
                    child: CustomPaint(
                      painter: HoroCloseXPainter(
                        color: const Color(0xFFC9A84C).withAlpha(220)),
                    ),
                  ),
                ),
              ),
            ),
            // Title
            Row(children: [
              AntiqueGlyph(icon: AntiqueIcon.pattern, size: 22, color: color),
              const SizedBox(width: 8),
              Text(data['title'] ?? type, style: GoogleFonts.cinzel(
                fontSize: 18, color: const Color(0xFFE8E0D0),
                fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 12),
            // Quality badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withAlpha(90)),
              ),
              child: Text(data['quality'] ?? '',
                style: TextStyle(fontSize: 14, color: color,
                  fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 18),
            _patternDescSection('配置の特徴', data['summary'] ?? '', color),
            const SizedBox(height: 14),
            _patternDescSection('ネイタル成立時 (N)', data['N'] ?? '',
              const Color(0xFFFFD370)),
            const SizedBox(height: 14),
            _patternDescSection('トランジット活性時 (T)', data['T'] ?? '',
              const Color(0xFF6BB5FF)),
            const SizedBox(height: 14),
            _patternDescSection('プログレス成立時 (P)', data['P'] ?? '',
              const Color(0xFFB088FF)),
          ]),
      ),
    );
  }

  Widget _patternDescSection(String label, String body, Color accent) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.cinzel(
        fontSize: 12, color: accent.withAlpha(220),
        letterSpacing: 2.0, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(body, style: const TextStyle(
        fontSize: 15, color: Color(0xE6E8E0D0), height: 1.7)),
    ]);
  }

  Widget _activeItem(BuildContext context, String type, Map<String, dynamic> pattern) {
    final style = patternStyles[type]!;
    final color = Color(style['color'] as int);
    final pKeys = pattern['planets'] as List<String>;
    final sources = pattern['sources'] as List<String>? ?? List.filled(pKeys.length, 'N');
    final itemKey = horoActivePatternKey(type, pattern);
    final visible = !hiddenPatterns.contains(itemKey);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x08FFFFFF)))),
      child: Row(children: [
        // Checkmark toggle
        GestureDetector(
          onTap: () => onPatternToggle(itemKey),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: HoroAspectCheckmark(active: visible, color: color),
          ),
        ),
        const SizedBox(width: 4),
        // Body (dimmed when off)
        Expanded(child: Opacity(
          opacity: visible ? 1.0 : 0.25,
          child: Row(children: [
            // Planets with source prefix
            ...List.generate(pKeys.length, (i) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(sources[i], style: const TextStyle(fontSize: 13, color: Color(0xFFAAAAAA))),
                PlanetVectorIcon(planetKey: pKeys[i], size: 16),
              ]),
            )),
            const Spacer(),
            // Pattern name badge (tap = modal)
            GestureDetector(
              onTap: () => _showPatternDescription(context, type, color),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withAlpha(80)),
                ),
                child: Text(style['labelJP'] as String,
                  style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 4),
            const Text('成立中', style: TextStyle(fontSize: 11, color: Color(0xFFC9A84C))),
          ]),
        )),
      ]),
    );
  }

  Widget _predictionItem(BuildContext context, Map<String, dynamic> pred) {
    final type = pred['type'] as String;
    final style = patternStyles[type]!;
    final color = Color(style['color'] as int);
    final days = pred['daysUntil'] as int;
    final date = (pred['dateEstimate'] as DateTime).toLocal();
    final timeLabel = days < 1 ? 'まもなく' : '${days}日後';
    final dateStr = '${date.month}/${date.day}';
    final p1 = pred['natalPair'][0] as String;
    final p2 = pred['natalPair'][1] as String;
    final tBody = pred['transitBody'] as String;
    final src = pred['source'] as String? ?? 'T';
    final itemKey = horoPredictionKey(pred);
    final visible = !hiddenPatterns.contains(itemKey);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x08FFFFFF)))),
      child: Row(children: [
        // Checkmark toggle
        GestureDetector(
          onTap: () => onPatternToggle(itemKey),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: HoroAspectCheckmark(active: visible, color: color),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(child: Opacity(
          opacity: visible ? 1.0 : 0.25,
          child: Row(children: [
            // N p1 - N p2 + src tBody
            const Text('N', style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC))),
            PlanetVectorIcon(planetKey: p1, size: 14),
            const Text('-N', style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC))),
            PlanetVectorIcon(planetKey: p2, size: 14),
            const Text(' + ', style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC))),
            Text(src, style: const TextStyle(fontSize: 12, color: Color(0xFFCCCCCC))),
            PlanetVectorIcon(planetKey: tBody, size: 14),
            const Spacer(),
            // Pattern name badge (tap = modal)
            GestureDetector(
              onTap: () => _showPatternDescription(context, type, color),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withAlpha(80)),
                ),
                child: Text(style['labelJP'] as String,
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 4),
            // Predicted date / countdown
            Column(crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min, children: [
              Text(timeLabel, style: const TextStyle(fontSize: 12, color: Color(0xFFF6BD60))),
              Text(dateStr, style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
            ]),
          ]),
        )),
      ]),
    );
  }
}
