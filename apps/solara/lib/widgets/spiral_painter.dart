import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/solara_colors.dart';

class SpiralPainter extends CustomPainter {
  final int activeDays;
  final int totalDays;

  SpiralPainter({
    this.activeDays = 12,
    this.totalDays = 28,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) * 0.42;

    // Draw spiral line
    final linePaint = Paint()
      ..color = SolaraColors.spiralLine
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final path = Path();
    const totalTurns = 3.0;
    const pointsPerTurn = 100;
    final totalPoints = (totalTurns * pointsPerTurn).toInt();

    for (int i = 0; i <= totalPoints; i++) {
      final t = i / totalPoints;
      final angle = t * totalTurns * 2 * pi;
      final r = t * maxRadius;
      final x = center.dx + r * cos(angle - pi / 2);
      final y = center.dy + r * sin(angle - pi / 2);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    // Draw day dots
    for (int day = 0; day < totalDays; day++) {
      final t = (day + 1) / totalDays;
      final scaledT = t * 0.95;
      final angle = scaledT * totalTurns * 2 * pi;
      final r = scaledT * maxRadius;
      final x = center.dx + r * cos(angle - pi / 2);
      final y = center.dy + r * sin(angle - pi / 2);

      final isActive = day < activeDays;

      if (isActive) {
        // Glow
        final glowPaint = Paint()
          ..color = SolaraColors.spiralDotActive.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
        canvas.drawCircle(Offset(x, y), 12.0, glowPaint);

        // Dot
        final dotPaint = Paint()
          ..color = SolaraColors.spiralDotActive
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 4.0, dotPaint);
      } else {
        final dotPaint = Paint()
          ..color = SolaraColors.spiralDotInactive
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 3.0, dotPaint);
      }
    }

    // Center glow (Stella's presence)
    final stellaGlow = Paint()
      ..color = SolaraColors.solaraGold.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawCircle(center, 20, stellaGlow);

    final stellaCore = Paint()
      ..color = SolaraColors.solaraGold.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, 6, stellaCore);
  }

  @override
  bool shouldRepaint(covariant SpiralPainter oldDelegate) {
    return oldDelegate.activeDays != activeDays;
  }
}
