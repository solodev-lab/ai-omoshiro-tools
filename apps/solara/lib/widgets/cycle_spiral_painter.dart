import 'dart:math';
import 'package:flutter/material.dart';
import '../models/daily_reading.dart';
import '../theme/solara_colors.dart';
import '../utils/moon_phase.dart';
import '../utils/tarot_data.dart';

/// HTML: galaxy.html renderSpiral3D() — 3-layer spiral painter
///   Layer 1: Ghost spiral path (faded reference line)
///   Layer 2: Spiral anchor dots (all days on spiral)
///   Layer 3: Reading dots at Golden Angle positions (anamorphic 55° camera)
///   + Connection threads between Layer 2 → Layer 3
class CycleSpiralPainter extends CustomPainter {
  final List<DailyReading?> days;
  final int currentDayIndex; // 0-based
  final int totalDays;
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

  // HTML: BREATH_PHASES/PERIODS — deterministic per-dot
  static final List<double> _breathPhases =
      List.generate(32, (i) => i * 0.71 + sin(i * 1.3) * 2.2);
  static final List<double> _breathPeriods =
      List.generate(32, (i) => 2.0 + (sin(i * 0.9)).abs() * 2.0);

  static const double _zSpan = 55;
  static const double _totalTurns = 4.2;
  static const double _pathTurns = 4.6;
  static const double _goldenAngle = 137.508 * pi / 180;
  static const double _camAngle55 = 55 * pi / 180;

  /// Hit-testing positions (Layer 3 GA positions for reading dots)
  List<Offset> dotScreenPositions = [];
  List<double> dotScreenScales = [];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.44;
    final fov = 360 * zoom;
    final b = min(size.width, size.height) * 0.057;
    final activeDays = currentDayIndex + 1;
    final now = breathPhase; // seconds

    // ═══ Layer 1: Ghost spiral path ═══
    _drawGhostPath(canvas, cx, cy, fov, b, size);

    // ═══ Layer 2: Spiral anchor dots ═══
    final spiralDots = <_SpiralDot>[];
    for (int d = 1; d <= totalDays; d++) {
      final t = d / totalDays;
      final theta = t * pi * _totalTurns;
      final r = b * theta;
      final raw = _Vec3(
        r * cos(theta - pi / 2),
        r * sin(theta - pi / 2),
        t * _zSpan - _zSpan / 2,
      );
      final rv = _rot3D(raw.x, raw.y, raw.z);
      final p = _proj3D(rv.x, rv.y, rv.z, fov, cx, cy);
      spiralDots.add(_SpiralDot(x: p.x, y: p.y, s: p.s, d: d, rz: rv.z));
    }

    // Draw spiral anchor dots (Layer 2)
    for (final sp in spiralDots) {
      final sc = max(0.5, sp.s);
      final dayIdx = sp.d - 1;
      final active = sp.d <= activeDays;
      final reading = dayIdx < days.length ? days[dayIdx] : null;

      if (!active) {
        // HTML: future day — very faint white dot
        canvas.drawCircle(Offset(sp.x, sp.y), 2.0 * sc,
          Paint()..color = Color.fromRGBO(255, 255, 255, 0.20 * sc));
      } else if (reading == null) {
        // HTML: active but no card — gray dot
        canvas.drawCircle(Offset(sp.x, sp.y), 2 * sc,
          Paint()..color = Color.fromRGBO(120, 120, 120, 0.60 * sc));
      } else {
        // HTML: has reading — tiny white anchor
        canvas.drawCircle(Offset(sp.x, sp.y), 1.5 * sc,
          Paint()..color = Color.fromRGBO(255, 255, 255, 0.20 * sc));
      }
    }

    // ═══ Pre-compute Golden Angle positions ═══
    final gaPositions = <int, _GAPos>{};
    int readingIdx = 0;
    final rng = _Mulberry32(42);
    for (int d = 0; d < totalDays; d++) {
      final reading = d < days.length ? days[d] : null;
      if (reading == null) continue;
      final angle = reading.cardId * _goldenAngle;
      final radius = 0.15 + (readingIdx / max(1, activeDays)) * 0.28;
      final x = 0.5 + radius * cos(angle);
      final y = 0.5 + radius * sin(angle);
      final zLayer = (reading.cardId % 3) - 1;
      final zJitter = (rng.next() - 0.5) * 0.4;
      gaPositions[d] = _GAPos(
        gaX: x.clamp(0.08, 0.92),
        gaY: y.clamp(0.08, 0.92),
        gaZ: (zLayer + zJitter).clamp(-1.0, 1.0),
      );
      readingIdx++;
    }

    // ═══ Layer 3: Project GA positions through anamorphic 55° camera ═══
    final gaDots = <_GADot>[];
    dotScreenPositions = List.filled(totalDays, Offset.zero);
    dotScreenScales = List.filled(totalDays, 1.0);

    for (final entry in gaPositions.entries) {
      final d = entry.key; // 0-based
      if (d >= activeDays) continue;
      final ga = entry.value;
      final p = _projectGA3D(ga.gaX, ga.gaY, ga.gaZ, size.width, size.height, cx, cy, fov);
      gaDots.add(_GADot(x: p.x, y: p.y, s: p.s, rz: p.rz, dayIdx: d));
      dotScreenPositions[d] = Offset(p.x, p.y);
      dotScreenScales[d] = p.s;
    }

    // Sort by z for depth ordering (back to front)
    gaDots.sort((a, b) => a.rz.compareTo(b.rz));

    // ═══ Connection threads: spiral anchor → GA position ═══
    final threadPaint = Paint()
      ..color = const Color.fromRGBO(249, 217, 118, 0.15)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    for (final gd in gaDots) {
      if (gd.dayIdx >= spiralDots.length) continue;
      final sp = spiralDots[gd.dayIdx];
      // HTML: setLineDash([3, 6]) — approximate with path
      canvas.drawLine(Offset(sp.x, sp.y), Offset(gd.x, gd.y), threadPaint);
    }

    // ═══ Draw reading dots at GA positions ═══
    for (final gd in gaDots) {
      _drawGADot(canvas, gd, now);
    }

    // ═══ Center Stella glow ═══
    _drawStellaCore(canvas, cx, cy);
  }

  // ═══ Layer 1: Ghost spiral path with fade ═══
  void _drawGhostPath(Canvas canvas, double cx, double cy, double fov, double b, Size size) {
    const steps = 500;
    final pts = <({double x, double y, double s})>[];

    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final theta = t * pi * _pathTurns;
      final r = b * theta;
      final rv = _rot3D(
        r * cos(theta - pi / 2),
        r * sin(theta - pi / 2),
        t * _zSpan - _zSpan / 2,
      );
      pts.add(_proj3D(rv.x, rv.y, rv.z, fov, cx, cy));
    }

    // HTML: per-segment fade = 1 - pow(i/len, 1.5)
    for (int i = 1; i < pts.length; i++) {
      final fade = 1 - pow(i / pts.length, 1.5).toDouble();
      if (fade < 0.01) continue;
      final a = max(0.10, 0.50 * pts[i].s * fade);
      final lw = max(0.8, 1.4 * pts[i].s * fade);
      canvas.drawLine(
        Offset(pts[i - 1].x, pts[i - 1].y),
        Offset(pts[i].x, pts[i].y),
        Paint()
          ..color = Color.fromRGBO(192, 200, 224, a)
          ..strokeWidth = lw,
      );
    }
  }

  // ═══ Draw a single reading dot at its GA position ═══
  void _drawGADot(Canvas canvas, _GADot gd, double now) {
    final dayIdx = gd.dayIdx;
    final reading = dayIdx < days.length ? days[dayIdx] : null;
    if (reading == null) return;

    final card = TarotData.getCard(reading.cardId);
    final dayDate = cycleStart.add(Duration(days: dayIdx));
    final isFullMoon = MoonPhase.isFullMoon(dayDate);
    final isNewMoon = MoonPhase.isNewMoon(dayDate);
    final isCurrent = dayIdx == currentDayIndex;
    final sc = max(0.5, gd.s);

    // Breathing
    final bPhase = dayIdx < _breathPhases.length ? _breathPhases[dayIdx] : dayIdx * 0.71;
    final bPeriod = dayIdx < _breathPeriods.length ? _breathPeriods[dayIdx] : 3.0;
    final breath = 0.7 + 0.3 * sin(now / bPeriod + bPhase);

    // Color from card
    final Color col;
    if (card.isMajor) {
      col = SolaraColors.planetColor(card.planet ?? 'sun');
    } else {
      col = SolaraColors.elementColor(card.element);
    }

    // Size
    double baseSize = card.isMajor ? 8.0 : 4.0;
    double glowBlur = card.isMajor ? 12.0 : 6.0;
    if (isFullMoon) baseSize *= 1.5;
    if (isNewMoon) baseSize *= 0.75;
    if (isCurrent) baseSize = max(baseSize, 6.5);
    final dotR = max(2.5, baseSize) * sc * breath;

    // Glow — brightened
    final gR = glowBlur * sc;
    canvas.drawCircle(
      Offset(gd.x, gd.y), gR,
      Paint()
        ..color = col.withValues(alpha: 0.55 * breath * sc)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, gR),
    );

    // Core — brightened
    if (isNewMoon) {
      // HTML: dark core + purple stroke ring
      canvas.drawCircle(Offset(gd.x, gd.y), dotR,
        Paint()..color = const Color(0xFF2A0030));
      canvas.drawCircle(Offset(gd.x, gd.y), dotR + 1,
        Paint()
          ..color = const Color(0x669B6BFF) // rgba(155,107,255,0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8);
    } else {
      canvas.drawCircle(Offset(gd.x, gd.y), dotR,
        Paint()..color = col.withValues(alpha: 1.0));
    }

    // Full moon ring + radial glow
    if (isFullMoon) {
      // HTML: dotR + 4*sc, strokeStyle rgba(255,240,192, 0.5*sc), lineWidth 2
      canvas.drawCircle(Offset(gd.x, gd.y), dotR + 4 * sc,
        Paint()
          ..color = Color.fromRGBO(255, 240, 192, 0.5 * sc)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
      // Radial glow
      canvas.drawCircle(Offset(gd.x, gd.y), dotR + 12 * sc,
        Paint()
          ..color = const Color.fromRGBO(255, 240, 192, 0.15)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 18 * sc));
    }

    // Current day ring
    if (isCurrent) {
      // HTML: 11*sc radius, rgba(249,217,118, 0.5*sc), lineWidth 1.5
      canvas.drawCircle(Offset(gd.x, gd.y), 11 * sc,
        Paint()
          ..color = Color.fromRGBO(249, 217, 118, 0.5 * sc)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    }

    // 5% random ring
    if (!isFullMoon && !isNewMoon && ((dayIdx + 1) * 31 + totalDays * 7) % 100 < 5) {
      canvas.drawCircle(Offset(gd.x, gd.y), dotR + 3 * sc,
        Paint()
          ..color = col.withValues(alpha: 0.3 * sc)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    }
  }

  void _drawStellaCore(Canvas canvas, double cx, double cy) {
    // Stella core — brightened
    canvas.drawCircle(Offset(cx, cy), 24,
      Paint()
        ..color = SolaraColors.solaraGold.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28));
    canvas.drawCircle(Offset(cx, cy), 8,
      Paint()
        ..color = SolaraColors.solaraGold.withValues(alpha: 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
  }

  // ═══ 3D math (HTML: rot3D, proj3D, projectGA3D) ═══

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

  /// HTML: projectGA3D — anamorphic 55° camera projection for Golden Angle positions
  ({double x, double y, double s, double rz}) _projectGA3D(
      double nx, double ny, double nz,
      double w, double h, double cx, double cy, double fov) {
    final zWorld = nz * 80;
    final cosA = cos(_camAngle55);
    final sinA = sin(_camAngle55);
    final xWorld = (nx - 0.5) * w * 0.85;
    final yWorld = (ny - 0.5) * h * 0.7;
    final yTilt = yWorld * cosA - zWorld * sinA;
    final zTilt = yWorld * sinA + zWorld * cosA;
    final rv = _rot3D(xWorld, yTilt, zTilt);
    final s = fov / (fov + rv.z + 260);
    return (x: cx + rv.x * s, y: cy + rv.y * s, s: s, rz: rv.z);
  }

  /// Hit-test for tap on GA dots. Returns dayIndex or -1.
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

// ═══ Helper types ═══

class _Vec3 {
  final double x, y, z;
  const _Vec3(this.x, this.y, this.z);
}

class _SpiralDot {
  final double x, y, s, rz;
  final int d; // 1-based day
  const _SpiralDot({required this.x, required this.y, required this.s, required this.d, required this.rz});
}

class _GAPos {
  final double gaX, gaY, gaZ;
  const _GAPos({required this.gaX, required this.gaY, required this.gaZ});
}

class _GADot {
  final double x, y, s, rz;
  final int dayIdx; // 0-based
  const _GADot({required this.x, required this.y, required this.s, required this.rz, required this.dayIdx});
}

/// HTML: mulberry32 PRNG — deterministic seeded random for z-jitter
class _Mulberry32 {
  int _state;
  _Mulberry32(this._state);
  double next() {
    _state += 0x6D2B79F5;
    int t = _state;
    t = (t ^ (t >> 15)) * (t | 1);
    t ^= t + (t ^ (t >> 7)) * (t | 61);
    return ((t ^ (t >> 14)) & 0x7FFFFFFF) / 0x7FFFFFFF;
  }
}
