import 'dart:math';
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
// Antique decorative icons for horoscope bottom sheet & panels
// All paths in 24×24 unit box, golden stroke/fill aesthetic
// ══════════════════════════════════════════════════════════════

enum AntiqueIcon {
  birth,         // ✧ 誕生 — birth star (4-point diamond + center dot)
  transit,       // ☾ 経過 — crescent moon
  progressed,    // ⚝ 進行 — compass star
  planets,       // ☉ 天体 — sun with rays
  filter,        // ⚹ 絞込 — 6-arm asterisk
  aspects,       // △ 相 — triangle with flourish
  pattern,       // ✦ — 8-point star
  reading,       // ✦ — ornate star + crescent
  settings,      // ✧ settings — flourish key
  cycle,         // 🌀 cycle — circular arrow (lunar cycle)
}

/// Widget to render an antique icon at given size and color.
class AntiqueGlyph extends StatelessWidget {
  final AntiqueIcon icon;
  final double size;
  final Color color;
  final bool glow;
  const AntiqueGlyph({
    super.key,
    required this.icon,
    this.size = 14,
    this.color = const Color(0xFFF6BD60),
    this.glow = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(
        painter: _AntiqueIconPainter(icon: icon, color: color, glow: glow),
      ),
    );
  }
}

class _AntiqueIconPainter extends CustomPainter {
  final AntiqueIcon icon;
  final Color color;
  final bool glow;
  _AntiqueIconPainter({required this.icon, required this.color, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()..color = color;

    final glowPaint = Paint()
      ..color = color.withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);

    final path = _buildPath(icon);

    if (glow) canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, stroke);

    // Draw additional small fills (center dots etc.)
    final fills = _buildFills(icon);
    for (final f in fills) {
      canvas.drawCircle(f.$1, f.$2, fill);
    }

    canvas.restore();
  }

  Path _buildPath(AntiqueIcon i) {
    switch (i) {
      case AntiqueIcon.birth: return _birthStar();
      case AntiqueIcon.transit: return _crescent();
      case AntiqueIcon.progressed: return _compassStar();
      case AntiqueIcon.planets: return _sunRays();
      case AntiqueIcon.filter: return _asterisk();
      case AntiqueIcon.aspects: return _triangleOrnate();
      case AntiqueIcon.pattern: return _eightPointStar();
      case AntiqueIcon.reading: return _ornateStarCrescent();
      case AntiqueIcon.settings: return _flourishKey();
      case AntiqueIcon.cycle: return _cycleSpiral();
    }
  }

  List<(Offset, double)> _buildFills(AntiqueIcon i) {
    switch (i) {
      case AntiqueIcon.birth: return [(const Offset(12, 12), 1.4)];
      case AntiqueIcon.planets: return [(const Offset(12, 12), 1.6)];
      case AntiqueIcon.filter: return [(const Offset(12, 12), 1.2)];
      case AntiqueIcon.pattern: return [(const Offset(12, 12), 1.0)];
      case AntiqueIcon.reading: return [(const Offset(12, 12), 0.9)];
      default: return const [];
    }
  }

  // ─────────── Icon paths ───────────

  /// ✧ Birth — 4-point diamond star
  Path _birthStar() {
    return Path()
      ..moveTo(12, 2)
      ..lineTo(14, 12)
      ..lineTo(22, 12)
      ..lineTo(14, 12)
      ..lineTo(12, 22)
      ..lineTo(10, 12)
      ..lineTo(2, 12)
      ..lineTo(10, 12)
      ..close()
      // small diagonal rays
      ..moveTo(6, 6)
      ..lineTo(9, 9)
      ..moveTo(18, 6)
      ..lineTo(15, 9)
      ..moveTo(6, 18)
      ..lineTo(9, 15)
      ..moveTo(18, 18)
      ..lineTo(15, 15);
  }

  /// ☾ Crescent moon with small accompanying star
  Path _crescent() {
    return Path()
      ..moveTo(18, 4)
      ..cubicTo(11, 4, 6, 8, 6, 12)
      ..cubicTo(6, 16, 11, 20, 18, 20)
      ..cubicTo(13, 18, 10, 15, 10, 12)
      ..cubicTo(10, 9, 13, 6, 18, 4)
      // tiny star at top-right
      ..moveTo(20, 6)
      ..lineTo(20, 10)
      ..moveTo(18, 8)
      ..lineTo(22, 8);
  }

  /// ⚝ 6-point compass star (two overlapping triangles)
  Path _compassStar() {
    final path = Path();
    // Triangle up
    for (int i = 0; i < 3; i++) {
      final a = i * 2 * pi / 3 - pi / 2;
      final p = Offset(12 + 9 * cos(a), 12 + 9 * sin(a));
      if (i == 0) { path.moveTo(p.dx, p.dy); } else { path.lineTo(p.dx, p.dy); }
    }
    path.close();
    // Triangle down
    for (int i = 0; i < 3; i++) {
      final a = i * 2 * pi / 3 + pi / 2;
      final p = Offset(12 + 9 * cos(a), 12 + 9 * sin(a));
      if (i == 0) { path.moveTo(p.dx, p.dy); } else { path.lineTo(p.dx, p.dy); }
    }
    path.close();
    return path;
  }

  /// ☉ Sun with 8 rays
  Path _sunRays() {
    final path = Path()
      ..addOval(const Rect.fromLTWH(7, 7, 10, 10));
    // 8 short rays
    for (int i = 0; i < 8; i++) {
      final a = i * pi / 4;
      final inner = Offset(12 + 9 * cos(a), 12 + 9 * sin(a));
      final outer = Offset(12 + 12 * cos(a), 12 + 12 * sin(a));
      path.moveTo(inner.dx, inner.dy);
      path.lineTo(outer.dx, outer.dy);
    }
    return path;
  }

  /// ⚹ 6-arm asterisk (alchemy-style)
  Path _asterisk() {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final a = i * pi / 3;
      path.moveTo(12 + 3 * cos(a), 12 + 3 * sin(a));
      path.lineTo(12 + 10 * cos(a), 12 + 10 * sin(a));
      // arrowhead tips
      final tipA = a + pi * 0.85;
      final tipB = a - pi * 0.85;
      final tip = Offset(12 + 10 * cos(a), 12 + 10 * sin(a));
      path.moveTo(tip.dx, tip.dy);
      path.lineTo(tip.dx + 2 * cos(tipA), tip.dy + 2 * sin(tipA));
      path.moveTo(tip.dx, tip.dy);
      path.lineTo(tip.dx + 2 * cos(tipB), tip.dy + 2 * sin(tipB));
    }
    return path;
  }

  /// △ Ornate triangle (alchemy fire with flourish)
  Path _triangleOrnate() {
    return Path()
      // Main triangle
      ..moveTo(12, 3)
      ..lineTo(22, 20)
      ..lineTo(2, 20)
      ..close()
      // Inner small triangle (doubled line)
      ..moveTo(12, 8)
      ..lineTo(18, 18)
      ..lineTo(6, 18)
      ..close()
      // Top decorative dots
      ..addOval(const Rect.fromLTWH(11, 1.5, 2, 2));
  }

  /// ✦ 8-point star (pattern)
  Path _eightPointStar() {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final a = i * pi / 4 - pi / 2;
      final r = (i % 2 == 0) ? 11.0 : 4.5;
      final p = Offset(12 + r * cos(a), 12 + r * sin(a));
      if (i == 0) { path.moveTo(p.dx, p.dy); } else { path.lineTo(p.dx, p.dy); }
    }
    path.close();
    return path;
  }

  /// ✦ Ornate star with crescent (reading)
  Path _ornateStarCrescent() {
    final path = Path();
    // 5-point star
    for (int i = 0; i < 5; i++) {
      final a = i * 2 * pi / 5 - pi / 2;
      final inner = i * 2 * pi / 5 - pi / 2 + pi / 5;
      final pOut = Offset(12 + 9 * cos(a), 12 + 9 * sin(a));
      final pIn = Offset(12 + 3.8 * cos(inner), 12 + 3.8 * sin(inner));
      if (i == 0) { path.moveTo(pOut.dx, pOut.dy); } else { path.lineTo(pOut.dx, pOut.dy); }
      path.lineTo(pIn.dx, pIn.dy);
    }
    path.close();
    return path;
  }

  /// Lunar cycle — circular arc with arrowhead + center dot (cycle/recurrence)
  Path _cycleSpiral() {
    return Path()
      // 3/4 circle (leaving gap at top)
      ..moveTo(17, 6)
      ..cubicTo(14, 2, 6, 4, 4, 11)
      ..cubicTo(3, 18, 10, 22, 16, 20)
      ..cubicTo(20, 18, 21, 14, 19, 10)
      // Arrowhead at start (top, pointing inward)
      ..moveTo(17, 6)
      ..lineTo(13, 5)
      ..moveTo(17, 6)
      ..lineTo(17, 10)
      // Inner small crescent (lunar hint)
      ..moveTo(14, 11)
      ..cubicTo(12, 11, 10, 13, 10, 15)
      ..cubicTo(10, 17, 12, 17, 14, 16)
      ..cubicTo(12, 16, 11, 15, 11, 14)
      ..cubicTo(11, 13, 12, 12, 14, 11);
  }

  /// Settings key flourish
  Path _flourishKey() {
    return Path()
      // circular ring
      ..addOval(const Rect.fromLTWH(4, 7, 10, 10))
      // key shaft
      ..moveTo(14, 12)
      ..lineTo(22, 12)
      // key teeth
      ..moveTo(18, 12)
      ..lineTo(18, 15)
      ..moveTo(21, 12)
      ..lineTo(21, 14);
  }

  @override
  bool shouldRepaint(covariant _AntiqueIconPainter old) =>
      old.icon != icon || old.color != color || old.glow != glow;
}
