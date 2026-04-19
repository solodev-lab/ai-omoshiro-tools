import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'horo_antique_icons.dart';
import 'horo_astro_glyphs.dart';
import 'horo_constants.dart';

// ─── 星座画像のファイル名 ───
const List<String> horoZodiacFiles = [
  'aries', 'taurus', 'gemini', 'cancer', 'leo', 'virgo',
  'libra', 'scorpio', 'sagittarius', 'capricorn', 'aquarius', 'pisces',
];

/// 惑星ベクターグリフ (チャートと同じデザイン)
/// angle(asc/mc/dsc/ic) のキーの場合はAntique記号で代用
class PlanetVectorIcon extends StatelessWidget {
  final String planetKey;
  final double size;
  final Color color;
  const PlanetVectorIcon({
    super.key, required this.planetKey,
    this.size = 18, this.color = const Color(0xFFFFD370),
  });
  @override
  Widget build(BuildContext context) {
    // Angle keys (asc/mc/dsc/ic) → 文字ラベルとして描画
    if (const {'asc','mc','dsc','ic'}.contains(planetKey)) {
      return SizedBox(
        width: size, height: size,
        child: Center(child: Text(
          planetKey.substring(0, 1).toUpperCase(),
          style: GoogleFonts.cinzel(
            fontSize: size * 0.75, fontWeight: FontWeight.w700,
            color: color, letterSpacing: 0.5),
        )),
      );
    }
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(painter: _PlanetGlyphPainter(planetKey, color)),
    );
  }
}

class _PlanetGlyphPainter extends CustomPainter {
  final String planetKey;
  final Color color;
  _PlanetGlyphPainter(this.planetKey, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    final matrix = Float64List.fromList([
      scale, 0, 0, 0,
      0, scale, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1,
    ]);
    final path = planetGlyph(planetKey).transform(matrix);
    canvas.drawPath(path, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
  }
  @override
  bool shouldRepaint(covariant _PlanetGlyphPainter old) =>
      old.planetKey != planetKey || old.color != color;
}

/// 星座画像シンボル (assets/zodiac-symbols/*.webp + 黒透過)
class ZodiacImageIcon extends StatelessWidget {
  final int signIdx;
  final double size;
  const ZodiacImageIcon({super.key, required this.signIdx, this.size = 18});
  @override
  Widget build(BuildContext context) {
    final i = signIdx.clamp(0, 11);
    return SizedBox(
      width: size, height: size,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          1.70, 5.72, 0.58, 0, 0, // 純黒のみ透明
        ]),
        child: Image.asset(
          'assets/zodiac-symbols/${horoZodiacFiles[i]}.webp',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Helper: antique-style panel header row (icon + label).
Widget horoAntiqueHeader(AntiqueIcon icon, String label, {double iconSize = 18}) {
  return Row(children: [
    AntiqueGlyph(icon: icon, size: iconSize, color: const Color(0xFFF6BD60)),
    const SizedBox(width: 8),
    Text(label, style: GoogleFonts.cinzel(
      fontSize: 13, color: const Color(0xFFF6BD60),
      letterSpacing: 2.5, fontWeight: FontWeight.w600)),
  ]);
}

/// Helper: 名前解決 (planet/angle両対応)
String horoPlanetOrAngleName(String key) =>
    planetNamesJP[key] ?? angleNamesJP[key] ?? key.toUpperCase();

/// アクティブパターン (detectPatterns の結果) 1件を一意に識別するキー。
/// 同じタイプでも惑星組合せが違うパターンは別キーになる。
String horoActivePatternKey(String type, Map<String, dynamic> pattern) {
  final planets = (pattern['planets'] as List).cast<String>();
  final sources = (pattern['sources'] as List?)?.cast<String>()
      ?? List.filled(planets.length, 'N');
  final pairs = List<String>.generate(
    planets.length, (i) => '${sources[i]}${planets[i]}')..sort();
  return 'active_${type}_${pairs.join('_')}';
}

/// 予測 (predictPatternCompletions の結果) 1件を一意に識別するキー。
String horoPredictionKey(Map<String, dynamic> pred) {
  final type = pred['type'] as String;
  final natalPair = (pred['natalPair'] as List).cast<String>();
  final tBody = pred['transitBody'] as String;
  final days = pred['daysUntil'] as int;
  return 'pred_${type}_${natalPair[0]}_${natalPair[1]}_${tBody}_$days';
}

// ══════════════════════════════════════════════════════════════
// Antique checkmark (for aspect list ON/OFF toggle)
// Active: 金の円輪 + 中にチェックマーク (グロー付き)
// Off:    薄い円輪のみ
// ══════════════════════════════════════════════════════════════
class HoroAspectCheckmark extends StatelessWidget {
  final bool active;
  final Color color;
  const HoroAspectCheckmark({super.key, required this.active, required this.color});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20, height: 20,
      child: CustomPaint(painter: _CheckmarkPainter(active: active, color: color)),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final bool active;
  final Color color;
  _CheckmarkPainter({required this.active, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 1;
    final c = Offset(cx, cy);
    final ringColor = active ? color : const Color(0xFF555555);

    // Outer ring (double hairline for antique feel)
    if (active) {
      canvas.drawCircle(c, r, Paint()
        ..color = color.withAlpha(100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5));
    }
    canvas.drawCircle(c, r, Paint()
      ..color = ringColor.withAlpha(active ? 220 : 120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0);
    canvas.drawCircle(c, r - 2, Paint()
      ..color = ringColor.withAlpha(active ? 110 : 50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5);

    // Checkmark stroke (only when active) — elegant serif flick
    if (active) {
      final path = Path()
        ..moveTo(cx - r * 0.45, cy - r * 0.02)
        ..lineTo(cx - r * 0.10, cy + r * 0.35)
        ..lineTo(cx + r * 0.55, cy - r * 0.45);
      // glow
      canvas.drawPath(path, Paint()
        ..color = color.withAlpha(150)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0));
      // main stroke
      canvas.drawPath(path, Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round);
    }
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter old) =>
      old.active != active || old.color != color;
}

// ══════════════════════════════════════════════════════════════
// Close (×) painter — antique thin strokes with subtle glow
// ══════════════════════════════════════════════════════════════
class HoroCloseXPainter extends CustomPainter {
  final Color color;
  HoroCloseXPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final inset = w * 0.2;
    final p1a = Offset(inset, inset);
    final p1b = Offset(w - inset, w - inset);
    final p2a = Offset(w - inset, inset);
    final p2b = Offset(inset, w - inset);

    final glow = Paint()
      ..color = color.withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(p1a, p1b, glow);
    canvas.drawLine(p2a, p2b, glow);
    canvas.drawLine(p1a, p1b, stroke);
    canvas.drawLine(p2a, p2b, stroke);
  }

  @override
  bool shouldRepaint(covariant HoroCloseXPainter old) => old.color != color;
}
