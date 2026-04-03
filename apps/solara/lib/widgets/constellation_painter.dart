import 'dart:math';
import 'package:flutter/material.dart';
import '../models/galaxy_cycle.dart';
import '../theme/solara_colors.dart';
import '../utils/tarot_data.dart';

/// Full-size constellation painter for replay overlay.
/// Supports progressive drawing via [progress] (0.0-1.0).
class ConstellationPainter extends CustomPainter {
  final GalaxyCycle cycle;
  final double progress; // 0.0 = nothing, 1.0 = fully drawn
  final Color? overrideColor;

  ConstellationPainter({
    required this.cycle,
    this.progress = 1.0,
    this.overrideColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (cycle.dots.isEmpty) return;

    final color = overrideColor ?? _seedCardColor();
    final dots = cycle.dots
        .map((d) => Offset(d.x * size.width, d.y * size.height))
        .toList();

    // Draw spline
    final spline = _catmullRom(dots);
    if (spline.isNotEmpty) {
      final drawCount = (spline.length * progress).round();
      if (drawCount > 1) {
        final path = Path()..moveTo(spline[0].dx, spline[0].dy);
        for (int i = 1; i < drawCount; i++) {
          path.lineTo(spline[i].dx, spline[i].dy);
        }

        // Shadow glow
        canvas.drawPath(
          path,
          Paint()
            ..color = color.withValues(alpha: 0.4)
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
        );

        // Main line
        canvas.drawPath(
          path,
          Paint()
            ..color = color.withValues(alpha: 0.8)
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // Draw dots
    final dotProgress = progress.clamp(0.0, 1.0);
    final visibleDots = (cycle.dots.length * dotProgress).round();
    for (int i = 0; i < visibleDots && i < cycle.dots.length; i++) {
      final cd = cycle.dots[i];
      final pos = dots[i];
      final isMajor = cd.isMajor;
      final dotR = isMajor ? 4.0 : 2.5;
      final dotColor = _dotColor(cd);

      // Glow
      canvas.drawCircle(
        pos,
        dotR * 2,
        Paint()
          ..color = dotColor.withValues(alpha: 0.3)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, dotR * 2),
      );
      // Core
      canvas.drawCircle(
        pos,
        dotR,
        Paint()..color = dotColor.withValues(alpha: 0.9),
      );
    }
  }

  Color _seedCardColor() {
    if (cycle.seedCardId < TarotData.allCards.length) {
      final card = TarotData.getCard(cycle.seedCardId);
      if (card.isMajor) return SolaraColors.planetColor(card.planet ?? 'sun');
      return SolaraColors.elementColor(card.element);
    }
    return SolaraColors.solaraGold;
  }

  Color _dotColor(ConstellationDot cd) {
    if (cd.cardId < TarotData.allCards.length) {
      final card = TarotData.getCard(cd.cardId);
      if (card.isMajor) return SolaraColors.planetColor(card.planet ?? 'sun');
      return SolaraColors.elementColor(card.element);
    }
    return SolaraColors.solaraGold;
  }

  /// Catmull-Rom spline interpolation.
  /// Ported from galaxy.html catmullRom().
  static List<Offset> _catmullRom(List<Offset> pts) {
    if (pts.length < 2) return pts;
    final result = <Offset>[];
    for (int i = 0; i < pts.length - 1; i++) {
      final p0 = pts[max(0, i - 1)];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = pts[min(pts.length - 1, i + 2)];

      for (int s = 0; s <= 16; s++) {
        final t = s / 16;
        final t2 = t * t;
        final t3 = t2 * t;
        result.add(Offset(
          0.5 *
              ((2 * p1.dx) +
                  (-p0.dx + p2.dx) * t +
                  (2 * p0.dx - 5 * p1.dx + 4 * p2.dx - p3.dx) * t2 +
                  (-p0.dx + 3 * p1.dx - 3 * p2.dx + p3.dx) * t3),
          0.5 *
              ((2 * p1.dy) +
                  (-p0.dy + p2.dy) * t +
                  (2 * p0.dy - 5 * p1.dy + 4 * p2.dy - p3.dy) * t2 +
                  (-p0.dy + 3 * p1.dy - 3 * p2.dy + p3.dy) * t3),
        ));
      }
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant ConstellationPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.cycle != cycle;
  }
}

/// Small constellation painter for Star Atlas grid cards.
class MiniConstellationPainter extends CustomPainter {
  final GalaxyCycle cycle;

  MiniConstellationPainter({required this.cycle});

  @override
  void paint(Canvas canvas, Size size) {
    if (cycle.dots.isEmpty) return;

    final color = _seedCardColor();
    final dots = cycle.dots
        .map((d) => Offset(d.x * size.width, d.y * size.height))
        .toList();

    // Draw spline
    final spline = ConstellationPainter._catmullRom(dots);
    if (spline.length > 1) {
      final path = Path()..moveTo(spline[0].dx, spline[0].dy);
      for (int i = 1; i < spline.length; i++) {
        path.lineTo(spline[i].dx, spline[i].dy);
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.6)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke,
      );
    }

    // Draw dots
    for (int i = 0; i < cycle.dots.length; i++) {
      final isMajor = cycle.dots[i].isMajor;
      canvas.drawCircle(
        dots[i],
        isMajor ? 2.5 : 1.5,
        Paint()..color = color.withValues(alpha: isMajor ? 0.8 : 0.5),
      );
    }
  }

  Color _seedCardColor() {
    if (cycle.seedCardId < TarotData.allCards.length) {
      final card = TarotData.getCard(cycle.seedCardId);
      if (card.isMajor) return SolaraColors.planetColor(card.planet ?? 'sun');
      return SolaraColors.elementColor(card.element);
    }
    return SolaraColors.solaraGold;
  }

  @override
  bool shouldRepaint(covariant MiniConstellationPainter oldDelegate) =>
      oldDelegate.cycle != cycle;
}
