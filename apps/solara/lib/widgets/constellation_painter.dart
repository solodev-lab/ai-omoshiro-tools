import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/galaxy_cycle.dart';
import '../utils/constellation_namer.dart';

/// Full-size constellation painter for replay overlay (v2: anamorphic 3D).
///
/// HTML exact: drawCycleOnCanvas with MST edges + shape types.
/// Anchor stars (Major Arcana) connected via MST + NOUN_SHAPES.
/// Field stars (Minor Arcana) float independently.
/// [cameraAngle] controls 3D perspective: 55° = scattered, 0° = aligned.
/// [progress] controls progressive drawing (0.0-1.0).
class ConstellationPainter extends CustomPainter {
  final GalaxyCycle cycle;
  final double progress;
  final double cameraAngle;
  final Color? overrideColor;
  final ui.Image? artImage; // HTML: ART_IMAGES[nounIdx] — constellation illustration
  final bool flipX; // HTML: NOUN_ART_TRANSFORMS[nounIdx].flipX

  ConstellationPainter({
    required this.cycle,
    this.progress = 1.0,
    this.cameraAngle = 0.0,
    this.overrideColor,
    this.artImage,
    this.flipX = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (cycle.dots.isEmpty) return;

    // HTML: use ADJ_COLOR for cycle color (星・線の核は属性色)
    final color = overrideColor ?? ConstellationNamer.adjColor(cycle.adjIdx);
    // glow は白ベース: 暗い属性でも星・線の存在感を保つ (濃いめ)
    final glowColor = Colors.white.withAlpha((0.7 * 255).round());

    // 黒背景→透明化: ColorFilter.matrix で輝度を alpha に変換 (progressでフェードイン)
    if (artImage != null) {
      canvas.save();
      final prog = min(1.0, progress * 2);
      final paint = Paint()
        ..colorFilter = ColorFilter.matrix([
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0.299 * prog, 0.587 * prog, 0.114 * prog, 0, 0, // alpha = 輝度 × progress
        ]);
      if (flipX) {
        canvas.translate(size.width, 0);
        canvas.scale(-1, 1);
      }
      canvas.drawImageRect(
        artImage!,
        Rect.fromLTWH(0, 0, artImage!.width.toDouble(), artImage!.height.toDouble()),
        Rect.fromLTWH(0, 0, size.width, size.height),
        paint,
      );
      canvas.restore();
    }

    // Separate anchors (Major) and field stars (Minor)
    final anchors = <ConstellationDot>[];
    final fields = <ConstellationDot>[];
    for (final d in cycle.dots) {
      if (d.isMajor) anchors.add(d);
      else fields.add(d);
    }

    // Project dots with 3D camera
    final anchorPositions = anchors.map((d) {
      final p = _project3D(d.x, d.y, d.z, size, cameraAngle);
      return Offset(p.x, p.y);
    }).toList();
    final fieldPositions = fields.map((d) {
      final p = _project3D(d.x, d.y, d.z, size, cameraAngle);
      return Offset(p.x, p.y);
    }).toList();

    // HTML: draw background gradient
    final bgGrad = ui.Gradient.radial(
      Offset(size.width / 2, size.height / 2), size.width * 0.7,
      [color.withAlpha((0.12 * 255).round()), color.withAlpha((0.03 * 255).round())],
    );
    canvas.drawRect(Offset.zero & size, Paint()..shader = bgGrad);

    // HTML: Field stars (small, no connections)
    final fieldCount = (fields.length * progress.clamp(0.0, 1.0)).floor();
    for (int i = 0; i < fieldCount && i < fields.length; i++) {
      final pos = fieldPositions[i];
      final ds = _depthScale(fields[i].z, cameraAngle).clamp(0.5, 1.5);
      canvas.drawCircle(pos, 1.2 * ds,
        Paint()..color = const Color(0x59F9D976)); // rgba(#F9D976, 0.35)
    }

    // HTML: MST edges with shapeType (connection phase: progress 0.0-0.6)
    final shapeType = (cycle.nounIdx >= 0 && cycle.nounIdx < ConstellationNamer.nounShapes.length)
        ? ConstellationNamer.nounShapes[cycle.nounIdx] : 'open';
    final edges = ConstellationNamer.buildEdges(anchorPositions, shapeType);
    final connProgress = (progress / 0.6).clamp(0.0, 1.0);
    final drawEdgeCount = (edges.length * connProgress).floor().clamp(0, edges.length);

    for (int i = 0; i < drawEdgeCount; i++) {
      final e = edges[i];
      if (e.from >= anchorPositions.length || e.to >= anchorPositions.length) continue;
      final a1 = anchorPositions[e.from], a2 = anchorPositions[e.to];

      // Shadow glow
      canvas.drawLine(a1, a2, Paint()
        ..color = glowColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      // Main line
      canvas.drawLine(a1, a2, Paint()
        ..color = color.withAlpha((0.8 * 255).round())
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round);
    }

    // HTML: Anchor dots (核=属性色、glow=白で存在感UP)
    final anchorDotCount = (anchors.length * progress.clamp(0.0, 1.0)).floor();
    for (int i = 0; i < anchorDotCount && i < anchors.length; i++) {
      final pos = anchorPositions[i];
      final ds = _depthScale(anchors[i].z, cameraAngle).clamp(0.6, 1.5);
      // Glow (白ベース、暗い属性でも見える、濃いめ)
      final gg = ui.Gradient.radial(pos, 10 * ds, [Colors.white.withAlpha((0.9 * 255).round()), Colors.transparent]);
      canvas.drawCircle(pos, 10 * ds, Paint()..shader = gg);
      // Core (属性色)
      canvas.drawCircle(pos, 3 * ds, Paint()..color = color.withAlpha((0.9 * 255).round()));
    }
  }

  static ({double x, double y}) _project3D(
    double nx, double ny, double nz, Size size, double camAngle,
  ) {
    final zWorld = nz * 80;
    final cosA = cos(camAngle);
    final sinA = sin(camAngle);
    final yWorld = (ny - 0.5) * size.height;
    final yRotated = yWorld * cosA - zWorld * sinA;
    final zRotated = yWorld * sinA + zWorld * cosA;
    final fov = 400.0;
    final scale = fov / (fov + zRotated + 100);
    return (
      x: size.width * 0.5 + (nx - 0.5) * size.width * scale,
      y: size.height * 0.5 + yRotated * scale,
    );
  }

  static double _depthScale(double z, double camAngle) {
    if (camAngle.abs() < 0.01) return 1.0;
    return (1.0 + z * 0.2 * sin(camAngle)).clamp(0.5, 1.5);
  }

  @override
  bool shouldRepaint(covariant ConstellationPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.cameraAngle != cameraAngle ||
        oldDelegate.cycle != cycle;
  }
}

/// Small constellation painter for Star Atlas grid cards.
/// Always shows front view (cameraAngle = 0).
/// HTML exact: drawCycleOnCanvas at 80x80 with progress=1.0.
class MiniConstellationPainter extends CustomPainter {
  final GalaxyCycle cycle;
  final ui.Image? artImage;
  final bool flipX;

  MiniConstellationPainter({required this.cycle, this.artImage, this.flipX = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (cycle.dots.isEmpty) return;

    // HTML: ADJ_COLOR for cycle color (星・線の核は属性色のまま)
    final color = ConstellationNamer.adjColor(cycle.adjIdx);
    // glow は白ベース: 暗い属性(Silent/Arcane/Abyssal等)でも星・線の存在感を保つ (濃いめ)
    final glowColor = Colors.white.withAlpha((0.7 * 255).round());

    // 黒背景→透明化: ColorFilter.matrix で輝度を alpha に変換
    // (黒=alpha0 完全透明 / 白=alpha255 完全不透明 / 中間=半透明)
    if (artImage != null) {
      canvas.save();
      final paint = Paint()
        ..colorFilter = const ColorFilter.matrix([
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0.299, 0.587, 0.114, 0, 0, // alpha = 輝度 (ITU-R BT.601)
        ]);
      if (flipX) {
        canvas.translate(size.width, 0);
        canvas.scale(-1, 1);
      }
      canvas.drawImageRect(
        artImage!,
        Rect.fromLTWH(0, 0, artImage!.width.toDouble(), artImage!.height.toDouble()),
        Rect.fromLTWH(0, 0, size.width, size.height),
        paint,
      );
      canvas.restore();
    }

    // Separate anchors and fields
    final anchors = <Offset>[];
    final fields = <Offset>[];
    for (final d in cycle.dots) {
      final pos = Offset(d.x * size.width, d.y * size.height);
      if (d.isMajor) anchors.add(pos);
      else fields.add(pos);
    }

    // HTML: MST edges with shapeType
    final shapeType = (cycle.nounIdx >= 0 && cycle.nounIdx < ConstellationNamer.nounShapes.length)
        ? ConstellationNamer.nounShapes[cycle.nounIdx] : 'open';
    final edges = ConstellationNamer.buildEdges(anchors, shapeType);

    // Draw edges
    for (final e in edges) {
      if (e.from >= anchors.length || e.to >= anchors.length) continue;
      // Glow (濃いめ・太め・強いblur)
      canvas.drawLine(anchors[e.from], anchors[e.to], Paint()
        ..color = glowColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9));
      // Line (核: 属性色、太く)
      canvas.drawLine(anchors[e.from], anchors[e.to], Paint()
        ..color = color.withAlpha((0.8 * 255).round())
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke);
    }

    // Draw field dots (暗い星→明るい星同等に: α 0.3→0.8)
    for (final pos in fields) {
      canvas.drawCircle(pos, 1.3, Paint()..color = color.withAlpha((0.8 * 255).round()));
    }

    // Draw anchor dots (glow半径UP + core UP: Miniでも存在感を出す)
    for (final pos in anchors) {
      final glow = ui.Gradient.radial(pos, 9, [Colors.white.withAlpha((0.95 * 255).round()), Colors.transparent]);
      canvas.drawCircle(pos, 9, Paint()..shader = glow);
      canvas.drawCircle(pos, 3.5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant MiniConstellationPainter oldDelegate) =>
      oldDelegate.cycle != cycle;
}
