import 'dart:math';
import 'package:flutter/material.dart';

/// Custom SVG-equivalent icons for Solara nav bar.
/// Matches shared/icons.js exactly.

class SolaraNavIcons {
  SolaraNavIcons._();

  /// Map icon: circle + cross-hairs + diamond center
  static Widget map({double size = 24, Color color = Colors.white}) =>
      CustomPaint(size: Size(size, size), painter: _MapIconPainter(color));

  /// Horo icon: concentric circles + cross lines + center dot
  static Widget horo({double size = 24, Color color = Colors.white}) =>
      CustomPaint(size: Size(size, size), painter: _HoroIconPainter(color));

  /// Tarot icon: card rectangle + star
  static Widget tarot({double size = 24, Color color = Colors.white}) =>
      CustomPaint(size: Size(size, size), painter: _TarotIconPainter(color));

  /// Galaxy icon: elliptical orbits + spiral arms + center dot + small stars
  static Widget galaxy({double size = 24, Color color = Colors.white}) =>
      CustomPaint(size: Size(size, size), painter: _GalaxyIconPainter(color));

  /// Sanctuary icon: temple/house shape + door + circle
  static Widget sanctuary({double size = 24, Color color = Colors.white}) =>
      CustomPaint(size: Size(size, size), painter: _SanctuaryIconPainter(color));
}

// ── Map: circle + cross-hairs + diamond ──
class _MapIconPainter extends CustomPainter {
  final Color color;
  _MapIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final stroke = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5 * s..strokeCap = StrokeCap.round;
    final fill = Paint()..color = color.withAlpha(217)..style = PaintingStyle.fill; // opacity 0.85

    // Circle r=9
    canvas.drawCircle(Offset(12 * s, 12 * s), 9 * s, stroke);
    // Cross-hairs
    canvas.drawLine(Offset(12 * s, 3 * s), Offset(12 * s, 6 * s), stroke);
    canvas.drawLine(Offset(12 * s, 18 * s), Offset(12 * s, 21 * s), stroke);
    canvas.drawLine(Offset(3 * s, 12 * s), Offset(6 * s, 12 * s), stroke);
    canvas.drawLine(Offset(18 * s, 12 * s), Offset(21 * s, 12 * s), stroke);
    // Diamond (compass rose)
    final path = Path()
      ..moveTo(12 * s, 8 * s)
      ..lineTo(13.5 * s, 11.5 * s)
      ..lineTo(17 * s, 12 * s)
      ..lineTo(13.5 * s, 13.5 * s)
      ..lineTo(12 * s, 17 * s)
      ..lineTo(10.5 * s, 13.5 * s)
      ..lineTo(7 * s, 12 * s)
      ..lineTo(10.5 * s, 11.5 * s)
      ..close();
    canvas.drawPath(path, fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Horo: concentric circles + cross + center dot ──
class _HoroIconPainter extends CustomPainter {
  final Color color;
  _HoroIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final stroke = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5 * s..strokeCap = StrokeCap.round;
    final fill = Paint()..color = color..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(12 * s, 12 * s), 9 * s, stroke);
    canvas.drawCircle(Offset(12 * s, 12 * s), 5 * s, stroke);
    canvas.drawCircle(Offset(12 * s, 12 * s), 1.5 * s, fill);
    // Cross lines
    canvas.drawLine(Offset(12 * s, 3 * s), Offset(12 * s, 7 * s), stroke);
    canvas.drawLine(Offset(12 * s, 17 * s), Offset(12 * s, 21 * s), stroke);
    canvas.drawLine(Offset(3 * s, 12 * s), Offset(7 * s, 12 * s), stroke);
    canvas.drawLine(Offset(17 * s, 12 * s), Offset(21 * s, 12 * s), stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Tarot: card + star ──
class _TarotIconPainter extends CustomPainter {
  final Color color;
  _TarotIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final stroke = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5 * s
      ..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;

    // Rounded rect: x=5 y=2 w=14 h=20 rx=2
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(5 * s, 2 * s, 14 * s, 20 * s), Radius.circular(2 * s)),
      stroke,
    );
    // Star: M12,6 L13.5,9 L17,9.5 L14.5,12 L15,15.5 L12,14 L9,15.5 L9.5,12 L7,9.5 L10.5,9 Z
    final star = Path()
      ..moveTo(12 * s, 6 * s)
      ..lineTo(13.5 * s, 9 * s)
      ..lineTo(17 * s, 9.5 * s)
      ..lineTo(14.5 * s, 12 * s)
      ..lineTo(15 * s, 15.5 * s)
      ..lineTo(12 * s, 14 * s)
      ..lineTo(9 * s, 15.5 * s)
      ..lineTo(9.5 * s, 12 * s)
      ..lineTo(7 * s, 9.5 * s)
      ..lineTo(10.5 * s, 9 * s)
      ..close();
    canvas.drawPath(star, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Galaxy: ellipses + spiral arms + dots ──
class _GalaxyIconPainter extends CustomPainter {
  final Color color;
  _GalaxyIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final cx = 12 * s, cy = 12 * s;

    // Rotated ellipses (orbit rings)
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-25 * pi / 180);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 20 * s, height: 8 * s),
      Paint()..color = color.withAlpha(77)..style = PaintingStyle.stroke..strokeWidth = 0.8 * s,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 14 * s, height: 6 * s),
      Paint()..color = color.withAlpha(128)..style = PaintingStyle.stroke..strokeWidth = 1 * s,
    );
    canvas.restore();

    // Spiral arms
    final armStroke = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.2 * s..strokeCap = StrokeCap.round;
    // Right arm
    final p1 = Path()..moveTo(cx, cy);
    p1.quadraticBezierTo(14 * s, 10.5 * s, 19 * s, 10 * s);
    canvas.drawPath(p1, armStroke);
    // Left arm
    final p2 = Path()..moveTo(cx, cy);
    p2.quadraticBezierTo(10 * s, 13.5 * s, 5 * s, 14 * s);
    canvas.drawPath(p2, armStroke);
    // Top arm
    final p3 = Path()..moveTo(cx, cy);
    p3.quadraticBezierTo(11 * s, 10 * s, 12.5 * s, 5.5 * s);
    canvas.drawPath(p3, Paint()..color = color.withAlpha(179)..style = PaintingStyle.stroke..strokeWidth = 1 * s..strokeCap = StrokeCap.round);
    // Bottom arm
    final p4 = Path()..moveTo(cx, cy);
    p4.quadraticBezierTo(13 * s, 14 * s, 11.5 * s, 18.5 * s);
    canvas.drawPath(p4, Paint()..color = color.withAlpha(179)..style = PaintingStyle.stroke..strokeWidth = 1 * s..strokeCap = StrokeCap.round);

    // Center glow
    canvas.drawCircle(Offset(cx, cy), 3 * s, Paint()..color = color.withAlpha(38)..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(cx, cy), 1.8 * s, Paint()..color = color..style = PaintingStyle.fill);

    // Small stars
    final dotPaint = Paint()..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(17 * s, 9 * s), 0.5 * s, dotPaint..color = color.withAlpha(128));
    canvas.drawCircle(Offset(7 * s, 15 * s), 0.5 * s, dotPaint..color = color.withAlpha(102));
    canvas.drawCircle(Offset(15 * s, 15 * s), 0.4 * s, dotPaint..color = color.withAlpha(77));
    canvas.drawCircle(Offset(9 * s, 8 * s), 0.4 * s, dotPaint..color = color.withAlpha(89));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Sanctuary: temple with door + circle window ──
class _SanctuaryIconPainter extends CustomPainter {
  final Color color;
  _SanctuaryIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final stroke = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5 * s
      ..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;

    // Ground line
    canvas.drawLine(Offset(3 * s, 21 * s), Offset(21 * s, 21 * s), stroke);
    // House body: M5,21 V9 L12,4 L19,9 V21
    final house = Path()
      ..moveTo(5 * s, 21 * s)
      ..lineTo(5 * s, 9 * s)
      ..lineTo(12 * s, 4 * s)
      ..lineTo(19 * s, 9 * s)
      ..lineTo(19 * s, 21 * s);
    canvas.drawPath(house, stroke);
    // Door
    canvas.drawLine(Offset(9 * s, 21 * s), Offset(9 * s, 15 * s), stroke);
    canvas.drawLine(Offset(15 * s, 21 * s), Offset(15 * s, 15 * s), stroke);
    canvas.drawLine(Offset(9 * s, 15 * s), Offset(15 * s, 15 * s), stroke);
    // Circle window
    canvas.drawCircle(Offset(12 * s, 10 * s), 1.5 * s, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
