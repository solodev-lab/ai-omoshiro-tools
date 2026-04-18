import 'dart:math';
import 'dart:ui' as ui;
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
  final int bgSeed; // random seed for background stars (changes each session)

  CycleSpiralPainter({
    required this.days,
    required this.currentDayIndex,
    required this.totalDays,
    required this.rotX,
    required this.rotY,
    required this.zoom,
    required this.breathPhase,
    required this.cycleStart,
    required this.bgSeed,
  });

  // HTML: BREATH_PHASES/PERIODS — deterministic per-dot
  static final List<double> _breathPhases =
      List.generate(32, (i) => i * 0.71 + sin(i * 1.3) * 2.2);
  static final List<double> _breathPeriods =
      List.generate(32, (i) => 2.0 + (sin(i * 0.9)).abs() * 2.0);

  static const double _zSpan = 130;
  static const double _totalTurns = 4.2;
  static const double _pathTurns = 4.6;
  /// Hit-testing positions for reading dots on spiral
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

    // ═══ Layer 0: Background stars ═══
    _drawBackgroundStars(canvas, size, now);

    // ═══ Layer 1: Ghost spiral path ═══
    _drawGhostPath(canvas, cx, cy, fov, b, size);

    // ═══ Layer 2: Spiral dots — stars plotted ON the spiral (HTML-style) ═══
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

    // Build hit-test positions
    dotScreenPositions = List.filled(totalDays, Offset.zero);
    dotScreenScales = List.filled(totalDays, 1.0);

    // Sort by z for depth ordering (back to front)
    spiralDots.sort((a, b2) => b2.rz.compareTo(a.rz));

    for (final sp in spiralDots) {
      final dayIdx = sp.d - 1;
      final active = sp.d <= activeDays;
      final reading = dayIdx < days.length ? days[dayIdx] : null;

      if (!active) {
        // Future day — ghost dot
        final sc = max(0.15, sp.s);
        canvas.drawCircle(Offset(sp.x, sp.y), 2.0 * sc,
          Paint()..color = Color.fromRGBO(255, 255, 255, 0.10 * sc));
      } else if (reading == null) {
        // Active but no card — gray dot
        final sc = max(0.15, sp.s);
        canvas.drawCircle(Offset(sp.x, sp.y), 2 * sc,
          Paint()..color = Color.fromRGBO(120, 120, 120, 0.60 * sc));
      } else {
        // Has reading — draw full star at spiral position
        final gd = _GADot(x: sp.x, y: sp.y, s: sp.s, rz: sp.rz, dayIdx: dayIdx);
        _drawGADot(canvas, gd, now);
        dotScreenPositions[dayIdx] = Offset(sp.x, sp.y);
        dotScreenScales[dayIdx] = sp.s;
      }
    }

    // ═══ Center Stella glow ═══
    _drawStellaCore(canvas, cx, cy);
  }

  // ═══ Layer 0: Background stars — 繊細な宝石のような輝き ═══
  // 3層構造: ソフトハロー + 鋭い核 + 輝きの十字光条 (明るい星のみ)
  void _drawBackgroundStars(Canvas canvas, Size size, double now) {
    final rng = _Mulberry32(bgSeed);
    const count = 30;
    for (int i = 0; i < count; i++) {
      final x = rng.next() * size.width;
      final y = rng.next() * size.height;
      final coreR = 0.4 + rng.next() * 0.6; // 核: 0.4~1.0px 小さめ
      final dur = 3.5 + rng.next() * 5.5;
      final delay = rng.next() * dur;
      final baseOp = 0.10 + rng.next() * 0.20;
      final peakOp = 0.65 + rng.next() * 0.25; // 星毎に異なるピーク輝度
      final t = (sin((now + delay) / dur * 2 * pi) + 1) / 2;
      // 非線形 twinkle (より鋭いピークに)
      final twinkle = pow(t, 0.6).toDouble();
      final alpha = (baseOp + (peakOp - baseOp) * twinkle).clamp(0.0, 1.0);

      // 星の色: 95%白、5%暖色・冷色にバリエーション
      final tint = rng.next();
      final starColor = tint < 0.85
          ? const Color(0xFFFFFEF8)          // 僅かに暖白
          : tint < 0.93
              ? const Color(0xFFFFE4B8)      // 淡い金 (珍しい)
              : const Color(0xFFD8E4FF);     // 淡い青 (珍しい)

      final center = Offset(x, y);

      // ① ソフトハロー (ぼかし)
      canvas.drawCircle(center, coreR * 3.0, Paint()
        ..color = starColor.withValues(alpha: alpha * 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));

      // ② 鋭い核 (1px以下の白い点)
      canvas.drawCircle(center, coreR, Paint()
        ..color = starColor.withValues(alpha: alpha));
    }
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
    final sc = max(0.15, gd.s);

    // Breathing
    final bPhase = dayIdx < _breathPhases.length ? _breathPhases[dayIdx] : dayIdx * 0.71;
    final bPeriod = dayIdx < _breathPeriods.length ? _breathPeriods[dayIdx] : 3.0;
    final breath = 0.7 + 0.3 * sin(now / bPeriod + bPhase);

    // Color: gold-based unified palette
    // Core color: Major=bright gold, Minor=pale gold/warm white
    // Glow color: element/planet tint at very low saturation
    final Color coreCol;
    final Color glowCol;
    if (card.isMajor) {
      coreCol = const Color(0xFFF6BD60); // bright gold
      glowCol = SolaraColors.planetColor(card.planet ?? 'sun');
    } else {
      coreCol = const Color(0xFFE8D5A8); // pale warm gold
      glowCol = SolaraColors.elementColor(card.element);
    }

    // Size: Major=5.0, Minor=2.0–4.0 graduated
    double baseSize;
    if (card.isMajor) {
      baseSize = 5.0;
    } else {
      final rank = ((reading.cardId - 22) % 14) + 1; // 1–14
      baseSize = 2.0 + (rank / 14.0) * 2.0; // 2.0–4.0
    }
    double glowBlur = baseSize * 1.2;
    if (isFullMoon) baseSize = min(baseSize * 1.3, 5.0);
    if (isNewMoon) baseSize *= 0.8;
    if (isCurrent) baseSize = max(baseSize, 4.0);
    final dotR = max(2.0, baseSize) * sc;

    // Glow — 8-layer smooth gradient (no visible boundaries)
    final gR = glowBlur * sc;
    final glowCenter = Offset(gd.x, gd.y);
    final glowA = (card.isMajor ? 0.15 : 0.35) * breath * sc;
    const glowLayers = 8;
    for (int i = 0; i < glowLayers; i++) {
      final t = i / (glowLayers - 1); // 0.0(outer) → 1.0(inner)
      final r = gR * (1.8 - t * 0.8); // 1.8x → 1.0x
      final a = glowA * t * t; // quadratic: smooth ramp-up toward center
      canvas.drawCircle(glowCenter, r,
        Paint()..color = glowCol.withValues(alpha: a));
    }


    // Core — semi-transparent 3D sphere
    final center = Offset(gd.x, gd.y);
    final hlOff = Offset(gd.x - dotR * 0.3, gd.y - dotR * 0.3);
    const coreAlpha = 0.7; // 全体透過
    if (isNewMoon) {
      canvas.drawCircle(center, dotR,
        Paint()..color = const Color(0xFF2A0030).withValues(alpha: coreAlpha));
    } else {
      final gradient = ui.Gradient.radial(
        hlOff, dotR,
        [
          Color.lerp(coreCol, const Color(0xFFFFFFFF), 0.55)!.withValues(alpha: coreAlpha),
          coreCol.withValues(alpha: coreAlpha),
          Color.lerp(coreCol, const Color(0xFF000000), 0.30)!.withValues(alpha: coreAlpha * 0.6),
        ],
        [0.0, 0.5, 1.0],
      );
      canvas.drawCircle(center, dotR, Paint()..shader = gradient);
      // Specular dot
      final specAlpha2 = (dotR - 2.0).clamp(0.0, 2.0) / 2.0 * 0.3;
      if (specAlpha2 > 0.01) {
        canvas.drawCircle(hlOff, dotR * 0.18,
          Paint()..color = Color.fromRGBO(255, 255, 255, specAlpha2));
      }
    }

    // Major arcana extra glow — half size & half intensity of Full Moon glow
    if (card.isMajor && !isFullMoon) {
      const majCol = Color.fromRGBO(255, 240, 192, 1.0);
      const layers = 8;
      for (int i = 0; i < layers; i++) {
        final t = i / (layers - 1);
        final r = dotR + (11 - t * 7) * sc;
        final a = 0.07 * t * t;
        canvas.drawCircle(center, r,
          Paint()..color = majCol.withValues(alpha: a));
      }
    }

    // Full moon radial glow — 8-layer smooth
    if (isFullMoon) {
      const fmCol = Color.fromRGBO(255, 240, 192, 1.0);
      const layers = 8;
      for (int i = 0; i < layers; i++) {
        final t = i / (layers - 1); // 0(outer) → 1(inner)
        final r = dotR + (22 - t * 14) * sc; // +22 → +8
        final a = 0.14 * t * t;
        canvas.drawCircle(center, r,
          Paint()..color = fmCol.withValues(alpha: a));
      }
    }
  }

  void _drawStellaCore(Canvas canvas, double cx, double cy) {
    // Stella core — 20-layer smooth gradient
    final c = Offset(cx, cy);
    const layers = 20;
    for (int i = 0; i < layers; i++) {
      final t = i / (layers - 1); // 0(outer) → 1(inner)
      final r = 42 - t * 38; // 42 → 4
      final a = 0.25 * t * t; // quadratic: smooth 0 → 0.25
      final col = Color.lerp(SolaraColors.solaraGold, SolaraColors.solaraGoldLight, t)!;
      canvas.drawCircle(c, r, Paint()..color = col.withValues(alpha: a));
    }
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
    return (x: cx + x * s, y: cy + y * s, s: 1.0);
  }

  /// Hit-test for tap on spiral dots. Returns dayIndex or -1.
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
