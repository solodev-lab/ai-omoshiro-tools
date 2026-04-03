import 'dart:math';
import 'package:flutter/material.dart';
import '../models/daily_reading.dart';
import '../theme/solara_colors.dart';
import '../utils/moon_phase.dart';
import '../utils/tarot_data.dart';

/// 3D spiral painter for the Galaxy Cycle tab.
/// Renders day dots with planet/element colors, moon phase sizing,
/// and breathing animation.
class CycleSpiralPainter extends CustomPainter {
  final List<DailyReading?> days; // one per day, null = no reading
  final int currentDayIndex; // 0-based day in cycle
  final int totalDays; // 29 or 30
  final double rotX;
  final double rotY;
  final double zoom;
  final double breathPhase; // animation time in seconds
  final DateTime cycleStart;

  CycleSpiralPainter({
    required this.days,
    required this.currentDayIndex,
    required this.totalDays,
    required this.rotX,
    required this.rotY,
    required this.zoom,
    required this.breathPhase,
    required this.cycleStart,
  });

  // Breathing phases per dot (deterministic, matching mockup)
  static final List<double> _breathPhases =
      List.generate(32, (i) => i * 0.71 + sin(i * 1.3) * 2.2);
  static final List<double> _breathPeriods =
      List.generate(32, (i) => 2.0 + (sin(i * 0.9)).abs() * 2.0);

  static const double _zSpan = 55;
  static const double _totalTurns = 4.2;
  static const double _pathTurns = 4.6;

  /// Store last computed dot screen positions for hit-testing.
  List<Offset> dotScreenPositions = [];
  List<double> dotScreenScales = [];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.44;
    final fov = 360 * zoom;
    final b = min(size.width, size.height) * 0.057;

    // Draw ghost spiral path
    _drawGhostPath(canvas, cx, cy, fov, b);

    // Calculate and draw dots
    final dots = <_DotInfo>[];
    dotScreenPositions = List.filled(totalDays, Offset.zero);
    dotScreenScales = List.filled(totalDays, 1.0);

    for (int d = 1; d <= totalDays; d++) {
      final t = d / totalDays;
      final theta = t * pi * _totalTurns;
      final r = b * theta;
      final rawX = r * cos(theta - pi / 2);
      final rawY = r * sin(theta - pi / 2);
      final rawZ = t * _zSpan - _zSpan / 2;

      final rotated = _rot3D(rawX, rawY, rawZ);
      final projected = _proj3D(rotated.x, rotated.y, rotated.z, fov, cx, cy);

      final dayIndex = d - 1;
      dotScreenPositions[dayIndex] = Offset(projected.x, projected.y);
      dotScreenScales[dayIndex] = projected.s;

      dots.add(_DotInfo(
        x: projected.x,
        y: projected.y,
        scale: projected.s,
        dayIndex: dayIndex,
        rz: rotated.z,
      ));
    }

    // Sort by z for proper depth ordering (back to front)
    dots.sort((a, b) => a.rz.compareTo(b.rz));

    for (final dot in dots) {
      _drawDot(canvas, dot, size);
    }

    // Center Stella glow
    _drawStellaCore(canvas, cx, cy);
  }

  void _drawGhostPath(
      Canvas canvas, double cx, double cy, double fov, double b) {
    final path = Path();
    const steps = 500;

    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final theta = t * pi * _pathTurns;
      final r = b * theta;
      final rawX = r * cos(theta - pi / 2);
      final rawY = r * sin(theta - pi / 2);
      final rawZ = t * _zSpan - _zSpan / 2;

      final rotated = _rot3D(rawX, rawY, rawZ);
      final projected = _proj3D(rotated.x, rotated.y, rotated.z, fov, cx, cy);

      if (i == 0) {
        path.moveTo(projected.x, projected.y);
      } else {
        path.lineTo(projected.x, projected.y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = SolaraColors.spiralLine
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawDot(Canvas canvas, _DotInfo dot, Size size) {
    final dayIndex = dot.dayIndex;
    final reading = dayIndex < days.length ? days[dayIndex] : null;
    final dayDate = cycleStart.add(Duration(days: dayIndex));
    final isFullMoonDay = MoonPhase.isFullMoon(dayDate);
    final isNewMoonDay = MoonPhase.isNewMoon(dayDate);
    final isCurrent = dayIndex == currentDayIndex;
    final screenScale = dot.scale.clamp(0.3, 2.0);

    // Breathing
    final bPhase = dayIndex < _breathPhases.length
        ? _breathPhases[dayIndex]
        : dayIndex * 0.71;
    final bPeriod = dayIndex < _breathPeriods.length
        ? _breathPeriods[dayIndex]
        : 3.0;
    final breath = 0.7 + 0.3 * sin(breathPhase / bPeriod + bPhase);

    // Determine color, size, glow
    Color dotColor;
    double baseRadius;
    double glowRadius;
    double glowAlpha;

    if (reading != null) {
      final card = TarotData.getCard(reading.cardId);
      if (card.isMajor) {
        dotColor = SolaraColors.planetColor(card.planet ?? 'sun');
        baseRadius = 8.0;
        glowRadius = 12.0;
        glowAlpha = 0.35;
      } else {
        dotColor = SolaraColors.elementColor(card.element);
        baseRadius = 4.0;
        glowRadius = 6.0;
        glowAlpha = 0.25;
      }
    } else {
      dotColor = SolaraColors.spiralDotDim;
      baseRadius = 2.0;
      glowRadius = 0;
      glowAlpha = 0;
    }

    // Moon phase modifiers
    double moonMultiplier = 1.0;
    if (isFullMoonDay) {
      moonMultiplier = 1.5;
    } else if (isNewMoonDay) {
      moonMultiplier = 0.75;
      if (reading == null) dotColor = SolaraColors.newMoonCore;
    }

    // Current day highlight
    if (isCurrent && reading != null) {
      baseRadius = max(baseRadius, 6.5);
    }

    final finalRadius = baseRadius * moonMultiplier * screenScale;
    final finalGlowR = glowRadius * moonMultiplier * screenScale;

    // Draw glow
    if (glowAlpha > 0) {
      final gPaint = Paint()
        ..color = dotColor.withValues(alpha: glowAlpha * breath * screenScale)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, finalGlowR);
      canvas.drawCircle(Offset(dot.x, dot.y), finalGlowR, gPaint);
    }

    // Draw dot core
    canvas.drawCircle(
      Offset(dot.x, dot.y),
      finalRadius,
      Paint()..color = dotColor.withValues(alpha: (0.8 * breath).clamp(0, 1)),
    );

    // Ring effect: full moon always, others 5% deterministic random
    final hasRandomRing = !isFullMoonDay &&
        !isNewMoonDay &&
        reading != null &&
        Random(dayIndex * 31 + totalDays * 7).nextDouble() < 0.05;

    if (isFullMoonDay || hasRandomRing) {
      final ringAlpha = isFullMoonDay ? 0.5 : 0.3;
      final ringGlowAlpha = isFullMoonDay ? 0.15 : 0.08;
      final ringGlowSize = isFullMoonDay ? 18.0 : 10.0;

      canvas.drawCircle(
        Offset(dot.x, dot.y),
        finalRadius + 3 * screenScale,
        Paint()
          ..color = SolaraColors.fullMoonRing.withValues(alpha: ringAlpha * breath)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 * screenScale,
      );
      // Radial glow
      final rgPaint = Paint()
        ..color = SolaraColors.fullMoonRing.withValues(alpha: ringGlowAlpha * breath)
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, ringGlowSize * screenScale);
      canvas.drawCircle(Offset(dot.x, dot.y), finalRadius * 1.8, rgPaint);
    }

    // New moon core
    if (isNewMoonDay) {
      canvas.drawCircle(
        Offset(dot.x, dot.y),
        finalRadius * 0.5,
        Paint()..color = SolaraColors.newMoonCore.withValues(alpha: 0.8),
      );
    }
  }

  void _drawStellaCore(Canvas canvas, double cx, double cy) {
    // Outer glow
    canvas.drawCircle(
      Offset(cx, cy),
      20,
      Paint()
        ..color = SolaraColors.solaraGold.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
    // Inner core
    canvas.drawCircle(
      Offset(cx, cy),
      6,
      Paint()
        ..color = SolaraColors.solaraGold.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  // --- 3D math (ported from galaxy.html) ---

  ({double x, double y, double z}) _rot3D(double x, double y, double z) {
    final y1 = y * cos(rotX) - z * sin(rotX);
    final z1 = y * sin(rotX) + z * cos(rotX);
    final x2 = x * cos(rotY) + z1 * sin(rotY);
    final z2 = -x * sin(rotY) + z1 * cos(rotY);
    return (x: x2, y: y1, z: z2);
  }

  ({double x, double y, double s}) _proj3D(
      double x, double y, double z, double fov, double cx, double cy) {
    final s = fov / (fov + z + 260);
    return (x: cx + x * s, y: cy + y * s, s: s);
  }

  /// Find nearest dot to a tap point. Returns dayIndex or -1.
  int hitTestDot(Offset tapPoint, {double threshold = 28}) {
    int nearest = -1;
    double nearestDist = threshold;
    for (int i = 0; i < dotScreenPositions.length; i++) {
      final d = (tapPoint - dotScreenPositions[i]).distance;
      if (d < nearestDist) {
        nearestDist = d;
        nearest = i;
      }
    }
    return nearest;
  }

  @override
  bool shouldRepaint(covariant CycleSpiralPainter oldDelegate) {
    return oldDelegate.breathPhase != breathPhase ||
        oldDelegate.rotX != rotX ||
        oldDelegate.rotY != rotY ||
        oldDelegate.zoom != zoom ||
        oldDelegate.currentDayIndex != currentDayIndex ||
        oldDelegate.days != days;
  }
}

class _DotInfo {
  final double x, y, scale, rz;
  final int dayIndex;
  const _DotInfo({
    required this.x,
    required this.y,
    required this.scale,
    required this.dayIndex,
    required this.rz,
  });
}
