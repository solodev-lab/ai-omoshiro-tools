import 'dart:math';
import 'package:flutter/material.dart';
import '../models/galaxy_cycle.dart';
import '../theme/solara_colors.dart';
import '../utils/tarot_data.dart';

/// Full-size constellation painter for replay overlay (v2: anamorphic 3D).
///
/// Anchor stars (Major Arcana) are connected with straight lines.
/// Field stars (Minor Arcana) float independently.
/// [cameraAngle] controls the 3D perspective: 55° = scattered, 0° = aligned.
/// [progress] controls progressive drawing (0.0-1.0).
class ConstellationPainter extends CustomPainter {
  final GalaxyCycle cycle;
  final double progress; // 0.0 = nothing, 1.0 = fully drawn
  final double cameraAngle; // radians, 0 = front view (aligned), ~0.96 = 55°
  final Color? overrideColor;

  ConstellationPainter({
    required this.cycle,
    this.progress = 1.0,
    this.cameraAngle = 0.0,
    this.overrideColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (cycle.dots.isEmpty) return;

    final color = overrideColor ?? _seedCardColor();

    // Separate anchors (Major) and field stars (Minor)
    final anchors = <ConstellationDot>[];
    final fields = <ConstellationDot>[];
    for (final d in cycle.dots) {
      if (d.isMajor) {
        anchors.add(d);
      } else {
        fields.add(d);
      }
    }

    // Project dots with 3D camera
    List<Offset> projectDots(List<ConstellationDot> dots) {
      return dots.map((d) {
        final projected = _project3D(d.x, d.y, d.z, size, cameraAngle);
        return Offset(projected.x, projected.y);
      }).toList();
    }

    final anchorPositions = projectDots(anchors);
    final fieldPositions = projectDots(fields);

    // Sort anchors by nearest-neighbor traversal to prevent line crossing
    final orderedAnchors = _nearestNeighborOrder(anchorPositions);

    // Draw anchor connections (straight lines)
    if (orderedAnchors.length > 1) {
      // Connection phase: progress 0.0-0.6
      final connProgress = (progress / 0.6).clamp(0.0, 1.0);
      final drawCount = (orderedAnchors.length * connProgress).round();

      if (drawCount > 1) {
        final path = Path()
          ..moveTo(orderedAnchors[0].dx, orderedAnchors[0].dy);
        for (int i = 1; i < drawCount; i++) {
          path.lineTo(orderedAnchors[i].dx, orderedAnchors[i].dy);
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

    // Draw field stars (small, no connections)
    final fieldDotProgress = progress.clamp(0.0, 1.0);
    final visibleFields = (fields.length * fieldDotProgress).round();
    for (int i = 0; i < visibleFields && i < fields.length; i++) {
      final cd = fields[i];
      final pos = fieldPositions[i];
      final dotColor = _dotColor(cd);
      final depthScale = _depthScale(cd.z, cameraAngle);

      // Small glow
      canvas.drawCircle(
        pos,
        3.0 * depthScale,
        Paint()
          ..color = dotColor.withValues(alpha: 0.2)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0 * depthScale),
      );
      // Core
      canvas.drawCircle(
        pos,
        1.5 * depthScale,
        Paint()..color = dotColor.withValues(alpha: 0.6),
      );
    }

    // Draw anchor stars (large with strong glow)
    final anchorDotProgress = progress.clamp(0.0, 1.0);
    final visibleAnchors = (anchors.length * anchorDotProgress).round();
    for (int i = 0; i < visibleAnchors && i < anchors.length; i++) {
      final cd = anchors[i];
      final pos = anchorPositions[i];
      final dotColor = _dotColor(cd);
      final depthScale = _depthScale(cd.z, cameraAngle);

      // Strong glow
      canvas.drawCircle(
        pos,
        8.0 * depthScale,
        Paint()
          ..color = dotColor.withValues(alpha: 0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12.0 * depthScale),
      );
      // Core
      canvas.drawCircle(
        pos,
        4.0 * depthScale,
        Paint()..color = dotColor.withValues(alpha: 0.9),
      );
    }
  }

  /// 3D projection: applies camera tilt to z-offset dots.
  /// At cameraAngle=0 (front), all dots project to their (x,y) positions.
  /// At cameraAngle=55° (~0.96 rad), dots scatter based on z depth.
  static ({double x, double y}) _project3D(
    double nx, double ny, double nz, Size size, double camAngle,
  ) {
    // nz ranges from -1 to 1, scale to world units
    final zWorld = nz * 80;
    // Camera rotation around X axis
    final cosA = cos(camAngle);
    final sinA = sin(camAngle);
    final yWorld = (ny - 0.5) * size.height;
    final yRotated = yWorld * cosA - zWorld * sinA;
    final zRotated = yWorld * sinA + zWorld * cosA;
    // Simple perspective
    final fov = 400.0;
    final scale = fov / (fov + zRotated + 100);
    return (
      x: size.width * 0.5 + (nx - 0.5) * size.width * scale,
      y: size.height * 0.5 + yRotated * scale,
    );
  }

  /// Depth-based size scaling.
  static double _depthScale(double z, double camAngle) {
    if (camAngle.abs() < 0.01) return 1.0;
    // Scale based on depth: closer = larger
    return (1.0 + z * 0.2 * sin(camAngle)).clamp(0.5, 1.5);
  }

  /// Nearest-neighbor ordering to minimize line crossings.
  static List<Offset> _nearestNeighborOrder(List<Offset> points) {
    if (points.length <= 2) return points;

    final remaining = List<Offset>.from(points);
    final ordered = <Offset>[remaining.removeAt(0)];

    while (remaining.isNotEmpty) {
      final last = ordered.last;
      var nearestIdx = 0;
      var nearestDist = double.infinity;
      for (int i = 0; i < remaining.length; i++) {
        final d = (last - remaining[i]).distance;
        if (d < nearestDist) {
          nearestDist = d;
          nearestIdx = i;
        }
      }
      ordered.add(remaining.removeAt(nearestIdx));
    }
    return ordered;
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

  @override
  bool shouldRepaint(covariant ConstellationPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.cameraAngle != cameraAngle ||
        oldDelegate.cycle != cycle;
  }
}

/// Small constellation painter for Star Atlas grid cards.
/// Always shows front view (cameraAngle = 0).
class MiniConstellationPainter extends CustomPainter {
  final GalaxyCycle cycle;

  MiniConstellationPainter({required this.cycle});

  @override
  void paint(Canvas canvas, Size size) {
    if (cycle.dots.isEmpty) return;

    final color = _seedCardColor();

    // Separate anchors and fields
    final anchors = <Offset>[];
    final fields = <Offset>[];
    for (final d in cycle.dots) {
      final pos = Offset(d.x * size.width, d.y * size.height);
      if (d.isMajor) {
        anchors.add(pos);
      } else {
        fields.add(pos);
      }
    }

    // Order anchors by nearest-neighbor
    final ordered = ConstellationPainter._nearestNeighborOrder(anchors);

    // Draw anchor connections
    if (ordered.length > 1) {
      final path = Path()..moveTo(ordered[0].dx, ordered[0].dy);
      for (int i = 1; i < ordered.length; i++) {
        path.lineTo(ordered[i].dx, ordered[i].dy);
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

    // Draw field dots (tiny)
    for (final pos in fields) {
      canvas.drawCircle(
        pos,
        1.0,
        Paint()..color = color.withValues(alpha: 0.3),
      );
    }

    // Draw anchor dots
    for (final pos in anchors) {
      canvas.drawCircle(
        pos,
        2.5,
        Paint()..color = color.withValues(alpha: 0.8),
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
