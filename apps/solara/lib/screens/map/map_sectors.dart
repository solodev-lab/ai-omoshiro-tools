import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'map_constants.dart';

/// 16方位扇状セクター — `activeCategory` のカテゴリ色 1色 + alpha のみ可変。
///
/// 🔴 設計仕様 (2026-05-04 オーナー直接指示、`project_solara_design_philosophy.md` の例外節):
/// - **1色のみ**で塗る（`sectorColor` = `categoryColors[activeCategory]`）
/// - **alpha (濃さ) は合算スコアの相対値**で 1軸変化
/// - **soft/hard の色分け・リング構造・境目なし**
/// - どこまで遠くを見てもその方角は 1色のみ
/// - soft+hard 合算は `_displayScores()` 側で済んでいる前提（呼出側責務）
///
/// 過去にあった以下の機構は **すべて撤廃** された (再導入禁止):
/// - 2リング構造 (内 soft / 外 hard) を別色で描画
/// - `tintByDir` で各方位を dominant カテゴリ色に上書き (合算 dominant 判定 = 設計思想違反)
/// - `sectorType` / `sectorTypeFromEnergy` の strong/weak/null 3段階判定
List<Polygon> buildSectors({
  required LatLng center,
  required Map<String, double> sectorScores,
  required Color sectorColor,
  required bool visible,
  bool lightMap = false,
  double dimFactor = 1.0,
  /// rank 1/2/3 の濃さ倍率 (default: 1.00/0.70/0.40)。
  /// カテゴリ別の微調整を呼出側で渡せる。スコア比正規化はせず純粋 rank 由来。
  List<double> rankAlphaMul = const [1.00, 0.70, 0.40],
}) {
  if (!visible) return const [];

  final polygons = <Polygon>[];
  const d = Distance();
  const maxDist = 20000000.0;
  const radialSteps = 30;
  const arcSteps = 30;
  const sectorWidth = 22.5;

  final lat = center.latitude;
  final nPolarM = ((90 - lat) * 111.32 - 200).clamp(500.0, 20000.0) * 1000.0;
  final sPolarM = ((90 + lat) * 111.32 - 200).clamp(500.0, 20000.0) * 1000.0;

  // 2026-05-04 オーナー要望: 各カテゴリで上位 3 方位のみ描画。
  // スコア値は順位決定のためにのみ使い、濃さは rank で明確に分ける
  // (スコアが近接していても 1位/2位/3位 で見て分かる差をつける)。
  final sortedDirs = sectorScores.entries
      .where((e) => e.value > 0.01)
      .toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  if (sortedDirs.isEmpty) return polygons;
  final rankByDir = <String, int>{
    for (int i = 0; i < sortedDirs.length && i < 3; i++) sortedDirs[i].key: i,
  };

  // alpha 上限 (light map では地色に負けないよう底上げ)。
  // 2026-05-04 オーナー要望: 全体的に薄く。
  final maxFillA = lightMap ? 130 : 100;
  final maxBorderA = lightMap ? 180 : 150;

  for (int i = 0; i < dir16.length; i++) {
    final dir = dir16[i];
    final rank = rankByDir[dir];
    if (rank == null) continue;

    final mul = rank < rankAlphaMul.length ? rankAlphaMul[rank] : 1.0;
    final fillA = (mul * dimFactor * maxFillA).round().clamp(0, 255);
    final borderA = (mul * dimFactor * maxBorderA).round().clamp(0, 255);
    if (fillA < 5) continue;

    final centerDeg = i * 22.5;
    final startDeg = centerDeg - sectorWidth / 2;
    final adjustedStart = startDeg < 0 ? startDeg + 360 : startDeg;
    final s = adjustedStart;
    final e2 = s + sectorWidth;

    double radius = maxDist;
    if (dir == 'N') radius = nPolarM < maxDist ? nPolarM : maxDist;
    if (dir == 'S') radius = sPolarM < maxDist ? sPolarM : maxDist;

    final points = _fanPoints(d, center, s, e2, radius,
        radialSteps: radialSteps, arcSteps: arcSteps);

    polygons.add(Polygon(
      points: points,
      color: sectorColor.withAlpha(fillA),
      borderColor: sectorColor.withAlpha(borderA),
      borderStrokeWidth: 1.5,
    ));
  }
  return polygons;
}

/// 扇形のポイント列を生成 (full fan、innerRatio=0 / outerRatio=1 固定)。
List<LatLng> _fanPoints(
  Distance d,
  LatLng center,
  double startDeg,
  double endDeg,
  double radius, {
  required int radialSteps,
  required int arcSteps,
}) {
  final points = <LatLng>[];
  // 始辺: 中心 → 外側
  for (int step = 0; step <= radialSteps; step++) {
    final dist = radius * step / radialSteps;
    points.add(d.offset(center, dist, startDeg % 360));
  }
  // 外周弧: start → end
  for (int step = 1; step <= arcSteps; step++) {
    final a = startDeg + (endDeg - startDeg) * step / arcSteps;
    points.add(d.offset(center, radius, a % 360));
  }
  // 終辺: 外側 → 中心
  for (int step = radialSteps; step >= 0; step--) {
    final dist = radius * step / radialSteps;
    points.add(d.offset(center, dist, endDeg % 360));
  }
  return points;
}

/// 8方向のコンパスライン — gold dashed、扇状とは独立。
List<Polyline> buildCompass({required LatLng center, required bool visible}) {
  if (!visible) return const [];
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

/// 方位ラベルマーカー（N,NE,E... を3距離に表示）。
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
