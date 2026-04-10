import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'map_constants.dart';

/// HTML: computeRanks — sort 16-dir by score, top1=strong, top2=weak, rest=null
String sectorType(String dir, Map<String, double> sectorScores) {
  final sorted = sectorScores.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final rank = sorted.indexWhere((e) => e.key == dir);
  if (rank == 0) return 'strong';
  if (rank == 1) return 'weak';
  return 'null';
}

/// HTML: scoreToStyle — 16方位セクターのポリゴンを生成
List<Polygon> buildSectors({
  required LatLng center,
  required Map<String, double> sectorScores,
  required Color sectorColor,
  required bool visible,
}) {
  if (!visible) return [];
  final polygons = <Polygon>[];
  const d = Distance();
  const maxDist = 20000000.0;
  const radialSteps = 30;
  const arcSteps = 30;

  for (int i = 0; i < dir16.length; i++) {
    final dir = dir16[i];
    final startDeg = i * 22.5 - 11.25;
    final adjustedStart = startDeg < 0 ? startDeg + 360 : startDeg;
    final s = adjustedStart;
    final e2 = s + 22.5;

    final type = sectorType(dir, sectorScores);
    final points = <LatLng>[];

    for (int step = 0; step <= radialSteps; step++) {
      final dist = maxDist * step / radialSteps;
      points.add(d.offset(center, dist, s % 360));
    }
    for (int step = 1; step <= arcSteps; step++) {
      final a = s + (e2 - s) * step / arcSteps;
      points.add(d.offset(center, maxDist, a % 360));
    }
    for (int step = radialSteps; step >= 0; step--) {
      final dist = maxDist * step / radialSteps;
      points.add(d.offset(center, dist, e2 % 360));
    }

    Color fillColor;
    Color borderColor;
    double borderWidth;
    switch (type) {
      case 'strong':
        fillColor = sectorColor.withAlpha(102);
        borderColor = sectorColor.withAlpha(217);
        borderWidth = 3;
        break;
      case 'weak':
        fillColor = sectorColor.withAlpha(51);
        borderColor = sectorColor.withAlpha(128);
        borderWidth = 2;
        break;
      default:
        fillColor = const Color(0x083A4A6B);
        borderColor = const Color(0x1F3A4A6B);
        borderWidth = 0.5;
    }

    polygons.add(Polygon(
      points: points,
      color: fillColor,
      borderColor: borderColor,
      borderStrokeWidth: borderWidth,
    ));
  }
  return polygons;
}

/// 8方向のコンパスライン — HTML: 8 direction lines, gold dashed
List<Polyline> buildCompass({required LatLng center, required bool visible}) {
  if (!visible) return [];
  final lines = <Polyline>[];
  const d = Distance();
  for (int i = 0; i < 8; i++) {
    final bearing = i * 45.0;
    final pts = <LatLng>[];
    for (double km = 0; km <= 20000000; km += 1000000) {
      pts.add(d.offset(center, km, bearing));
    }
    lines.add(Polyline(
      points: pts,
      color: const Color(0x59C9A84C),
      strokeWidth: 1,
      pattern: StrokePattern.dashed(segments: const [4.0, 8.0]),
    ));
  }
  return lines;
}

/// 方位ラベルマーカー（N,NE,E... を3距離に表示）
List<Marker> buildDirLabels({required LatLng center}) {
  final markers = <Marker>[];
  const d = Distance();
  const dirs = [
    ('N', 0.0), ('NE', 45.0), ('E', 90.0), ('SE', 135.0),
    ('S', 180.0), ('SW', 225.0), ('W', 270.0), ('NW', 315.0),
  ];
  for (final dist in [500000.0, 2000000.0, 8000000.0]) {
    for (final dir in dirs) {
      final pt = d.offset(center, dist, dir.$2);
      final isCardinal = ['N', 'E', 'S', 'W'].contains(dir.$1);
      markers.add(Marker(
        point: pt,
        width: 24, height: 16,
        child: Center(
          child: Text(
            dir.$1,
            style: TextStyle(
              fontSize: isCardinal ? 11.0 : 9.0,
              fontWeight: FontWeight.bold,
              color: Color(isCardinal ? 0x80FFFFFF : 0x4DFFFFFF),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ));
    }
  }
  return markers;
}

/// モックスコア生成（天文計算の実装前）
Map<String, double> generateMockScores(Map<String, Map<String, double>> sectorComps) {
  final rng = Random(DateTime.now().day);
  final scores = <String, double>{};
  for (final d in dir16) {
    final ts = rng.nextDouble() * 2.5;
    final th = rng.nextDouble() * 1.5;
    final ps = rng.nextDouble() * 1.2;
    final ph = rng.nextDouble() * 0.8;
    sectorComps[d] = {'tSoft': ts, 'tHard': th, 'pSoft': ps, 'pHard': ph};
    scores[d] = ts + th + ps + ph;
  }
  return scores;
}
