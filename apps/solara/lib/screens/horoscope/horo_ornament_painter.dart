import 'dart:math';
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
// Horo Ornament Painter — antique gold filigree frame around chart
// Renaissance astrological manuscript aesthetic
// ══════════════════════════════════════════════════════════════

class HoroOrnamentPainter extends CustomPainter {
  /// Breathing animation value 0.0 - 1.0
  final double breath;
  /// Ascendant longitude (degrees) — used to rotate zodiac-boundary star markers
  final double asc;
  const HoroOrnamentPainter({this.breath = 0.5, this.asc = 0});

  /// HTML/chart-painter と同じ変換 — ASC は画面下(180°)に来る
  double _lonToAngle(double lon) => (asc - lon + 180) * pi / 180;

  static const _gold = Color(0xFFC9A84C);
  static const _goldBright = Color(0xFFF6BD60);
  static const _copper = Color(0xFFB8764A);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final scale = size.width / 600;
    final center = Offset(cx, cy);

    // Fixed at brightest — no breathing on ornament frame
    const glowIntensity = 1.0;

    // ── Outer decorative ring ──
    // Thin double ring with golden gradient
    _drawDecorativeRing(canvas, center, r - 2 * scale, scale, glowIntensity);

    // ── 12 star markers at sign boundaries ──
    _drawStarMarkers(canvas, center, r - 10 * scale, scale, glowIntensity);

    // (corner flourishes removed — conflicted with A/D/M/I labels)

    // ── Inner halo glow ──
    _drawInnerHalo(canvas, center, r - 20 * scale, scale, glowIntensity);
  }

  void _drawDecorativeRing(Canvas canvas, Offset center, double r, double scale, double g) {
    // Outer thin ring with copper tint
    canvas.drawCircle(center, r, Paint()
      ..color = _copper.withAlpha((0.55 * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale);

    // Inner gold ring with breathing glow
    canvas.drawCircle(center, r - 4 * scale, Paint()
      ..color = _gold.withAlpha((0.7 * g * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 * scale);

    // Outer glow aura
    canvas.drawCircle(center, r - 2 * scale, Paint()
      ..color = _goldBright.withAlpha((0.15 * g * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6 * scale
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * scale));

    // Hairline tick ring
    for (int i = 0; i < 360; i += 2) {
      final a = i * pi / 180;
      final len = (i % 30 == 0) ? 6.0 : (i % 10 == 0) ? 3.5 : 1.5;
      final p1 = Offset(center.dx + (r - 1 * scale) * cos(a), center.dy + (r - 1 * scale) * sin(a));
      final p2 = Offset(
        center.dx + (r - (1 + len) * scale) * cos(a),
        center.dy + (r - (1 + len) * scale) * sin(a));
      canvas.drawLine(p1, p2, Paint()
        ..color = _gold.withAlpha((0.35 * g * 255).round())
        ..strokeWidth = 0.5 * scale);
    }
  }

  void _drawStarMarkers(Canvas canvas, Offset center, double r, double scale, double g) {
    // 12 six-point stars at zodiac sign boundaries (ASC-aligned, rotates with chart)
    for (int i = 0; i < 12; i++) {
      final signLon = (i * 30).toDouble();
      final a = _lonToAngle(signLon);
      final px = center.dx + r * cos(a);
      final py = center.dy + r * sin(a);
      _drawSixPointStar(canvas, Offset(px, py), 3.5 * scale, g);
    }
  }

  void _drawSixPointStar(Canvas canvas, Offset c, double size, double g) {
    // Two overlapping triangles (Star of David style)
    final path = Path();
    for (int tri = 0; tri < 2; tri++) {
      final rot = tri * pi / 3;
      for (int i = 0; i < 3; i++) {
        final a = rot + i * 2 * pi / 3 - pi / 2;
        final p = Offset(c.dx + size * cos(a), c.dy + size * sin(a));
        if (i == 0) { path.moveTo(p.dx, p.dy); } else { path.lineTo(p.dx, p.dy); }
      }
      path.close();
    }
    // Glow
    canvas.drawPath(path, Paint()
      ..color = _goldBright.withAlpha((0.5 * g * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    // Stroke
    canvas.drawPath(path, Paint()
      ..color = _goldBright.withAlpha((0.9 * g * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
    // Center dot
    canvas.drawCircle(c, 1.2, Paint()
      ..color = _goldBright.withAlpha((0.9 * g * 255).round()));
  }

  void _drawInnerHalo(Canvas canvas, Offset center, double r,
      double scale, double g) {
    // Subtle inner halo — golden glow radiating inward
    final rect = Rect.fromCircle(center: center, radius: r);
    final shader = RadialGradient(
      colors: [
        _goldBright.withAlpha((0.08 * g * 255).round()),
        _gold.withAlpha(0),
      ],
      stops: const [0.85, 1.0],
    ).createShader(rect);
    canvas.drawCircle(center, r, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant HoroOrnamentPainter old) =>
      old.breath != breath || old.asc != asc;
}
