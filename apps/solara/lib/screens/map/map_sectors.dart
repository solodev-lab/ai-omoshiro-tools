import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/solara_colors.dart';
import '../../utils/direction_energy.dart';
import 'map_constants.dart';

/// HTML: computeRanks — sort 16-dir by score, top1=strong, top2=weak, rest=null
/// ⚠ 設計思想的に非推奨: ソフト/ハード合算スコアでランク付けしている。
/// 新規呼び出しは sectorTypeFromEnergy を使うこと。
String sectorType(String dir, Map<String, double> sectorScores) {
  final sorted = sectorScores.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final rank = sorted.indexWhere((e) => e.key == dir);
  if (rank == 0) return 'strong';
  if (rank == 1) return 'weak';
  return 'null';
}

/// 2エネルギー版ランク付け。
/// `sortKey`（= max(soft, hard)）で並べ、top1=strong / top2=weak。
/// これは「合算」ではなく「最大成分」での比較なので、
/// 設計思想に違反しない（ソフト/ハードを独立に保持したまま、
/// 表示順用の便宜的な並びを得るだけ）。
String sectorTypeFromEnergy(String dir, Map<String, DirectionEnergy> energies) {
  final sorted = energies.entries.toList()
    ..sort((a, b) => b.value.sortKey.compareTo(a.value.sortKey));
  final rank = sorted.indexWhere((e) => e.key == dir);
  if (rank == 0) return 'strong';
  if (rank == 1) return 'weak';
  return 'null';
}

/// HTML: scoreToStyle — 16方位セクターのポリゴンを生成
/// 参考: mockup/index.html L1875-1895（R=20000km、nPolar/sPolar で極域距離制限）
///
/// lightMap=true の時は明るい地図（OSM Light等）用に、塗り alpha と
/// ボーダー alpha を少し上げて、薄い地色にも負けないようにする。
///
/// 🔴 設計思想変更 (2026-04-29): 単色塗りから2エネルギー並列描画へ。
/// sectorEnergies が指定された場合: 各セクターを「内側=ソフト色 / 外側=ハード色」
/// の2リング構造で描画し、ソフト/ハード量を独立した alpha で表現する。
/// 後方互換のため sectorScores パラメータは残し、フォールバックとして利用。
List<Polygon> buildSectors({
  required LatLng center,
  required Map<String, double> sectorScores,
  required Color sectorColor,
  required bool visible,
  bool lightMap = false,
  Map<String, DirectionEnergy>? sectorEnergies,
  double dimFactor = 1.0,
  String activeCategory = 'all',
  /// activeCategory == 'all' のとき各方位の dominant カテゴリ色を渡す。
  /// {dir: Color} 形式。null or 空時は energySoft/energyHard で塗る (旧挙動)。
  Map<String, Color>? sectorTintByDir,
}) {
  if (!visible) return [];

  // 2エネルギー版が利用可能ならそちらを優先
  if (sectorEnergies != null && sectorEnergies.isNotEmpty) {
    return _buildSectorsTwoEnergy(
      center: center,
      energies: sectorEnergies,
      lightMap: lightMap,
      dimFactor: dimFactor,
      activeCategory: activeCategory,
      tintByDir: sectorTintByDir,
    );
  }

  // ── レガシー: 単色塗り版（設計思想的に非推奨だが互換性のため残す） ──
  final polygons = <Polygon>[];
  const d = Distance();
  const maxDist = 20000000.0;
  const radialSteps = 30;
  const arcSteps = 30;
  const sectorWidth = 22.5;

  final lat = center.latitude;
  final nPolarM = ((90 - lat) * 111.32 - 200).clamp(500.0, 20000.0) * 1000.0;
  final sPolarM = ((90 + lat) * 111.32 - 200).clamp(500.0, 20000.0) * 1000.0;

  for (int i = 0; i < dir16.length; i++) {
    final dir = dir16[i];
    final centerDeg = i * 22.5;
    final startDeg = centerDeg - sectorWidth / 2;
    final adjustedStart = startDeg < 0 ? startDeg + 360 : startDeg;
    final s = adjustedStart;
    final e2 = s + sectorWidth;

    double radius = maxDist;
    if (dir == 'N') radius = nPolarM < maxDist ? nPolarM : maxDist;
    if (dir == 'S') radius = sPolarM < maxDist ? sPolarM : maxDist;

    final type = sectorType(dir, sectorScores);
    final points = _fanPoints(d, center, s, e2, radius, 0, 1.0,
        radialSteps: radialSteps, arcSteps: arcSteps);

    Color fillColor;
    Color borderColor;
    double borderWidth;
    final strongFillA = lightMap ? 140 : 102;
    final strongBorderA = lightMap ? 240 : 217;
    final weakFillA = lightMap ? 80 : 51;
    final weakBorderA = lightMap ? 180 : 128;
    switch (type) {
      case 'strong':
        fillColor = sectorColor.withAlpha(strongFillA);
        borderColor = sectorColor.withAlpha(strongBorderA);
        borderWidth = lightMap ? 3.5 : 3;
        break;
      case 'weak':
        fillColor = sectorColor.withAlpha(weakFillA);
        borderColor = sectorColor.withAlpha(weakBorderA);
        borderWidth = lightMap ? 2.5 : 2;
        break;
      default:
        fillColor = const Color(0x00000000);
        borderColor = const Color(0x00000000);
        borderWidth = 0;
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

/// 2エネルギー描画: 各セクターを「内側ソフト / 外側ハード」の2リングで描画。
/// ソフト = SolaraColors.energySoft（銀月色）、ハード = SolaraColors.energyHard（金陽色）。
/// 量は独立して alpha に反映され、合算しない。
List<Polygon> _buildSectorsTwoEnergy({
  required LatLng center,
  required Map<String, DirectionEnergy> energies,
  required bool lightMap,
  required double dimFactor,
  String activeCategory = 'all',
  Map<String, Color>? tintByDir,
}) {
  final polygons = <Polygon>[];
  const d = Distance();
  const maxDist = 20000000.0;
  const radialSteps = 30;
  const arcSteps = 30;
  const sectorWidth = 22.5;

  final lat = center.latitude;
  final nPolarM = ((90 - lat) * 111.32 - 200).clamp(500.0, 20000.0) * 1000.0;
  final sPolarM = ((90 + lat) * 111.32 - 200).clamp(500.0, 20000.0) * 1000.0;

  // 全方位中の最大ソフト・最大ハードを取り、各方位を独立に正規化する。
  // 「ソフト全体での比率」「ハード全体での比率」をそれぞれ独立に算出するため、
  // 1次元化（合算）にはならない。
  double maxSoft = 0;
  double maxHard = 0;
  for (final e in energies.values) {
    if (e.soft > maxSoft) maxSoft = e.soft;
    if (e.hard > maxHard) maxHard = e.hard;
  }
  if (maxSoft < 1e-9) maxSoft = 1;
  if (maxHard < 1e-9) maxHard = 1;

  // top 2 ランクで強調表示。それ以外は薄く控えめに描画。
  final ranking = energies.entries.toList()
    ..sort((a, b) => b.value.sortKey.compareTo(a.value.sortKey));
  final topRanks = <String, int>{
    for (int i = 0; i < ranking.length; i++) ranking[i].key: i,
  };

  for (int i = 0; i < dir16.length; i++) {
    final dir = dir16[i];
    final energy = energies[dir];
    if (energy == null) continue;

    final rank = topRanks[dir] ?? 99;
    if (rank > 1 && energy.soft / maxSoft < 0.35 && energy.hard / maxHard < 0.35) {
      // 上位2位以外で、かつ両エネルギーが控えめな方角はスキップ
      continue;
    }

    final centerDeg = i * 22.5;
    final startDeg = centerDeg - sectorWidth / 2;
    final adjustedStart = startDeg < 0 ? startDeg + 360 : startDeg;
    final s = adjustedStart;
    final e2 = s + sectorWidth;

    double radius = maxDist;
    if (dir == 'N') radius = nPolarM < maxDist ? nPolarM : maxDist;
    if (dir == 'S') radius = sPolarM < maxDist ? sPolarM : maxDist;

    // 内側半分（0 → 50%） = ソフトリング
    final softPoints = _fanPoints(d, center, s, e2, radius, 0.0, 0.5,
        radialSteps: radialSteps, arcSteps: arcSteps);
    // 外側半分（50% → 100%） = ハードリング
    final hardPoints = _fanPoints(d, center, s, e2, radius, 0.5, 1.0,
        radialSteps: radialSteps, arcSteps: arcSteps);

    // alpha 計算: 上位ランクほど強調、各エネルギーの量で調整
    // activeCategory == 'all' のときのみ TOP2 を +0.10 強調 (総合表示で目立たせる)
    // 他カテゴリは控えめにして、TOP2 と他の差を弱める (カテゴリ別の細部に集中)
    final isAll = activeCategory == 'all';
    double rankMul;
    if (rank == 0) {
      rankMul = isAll ? 0.85 : 0.75;
    } else if (rank == 1) {
      rankMul = isAll ? 0.65 : 0.55;
    } else {
      rankMul = 0.4;
    }

    // 各エネルギーは自分のスケールで正規化（独立保持）
    final softAlphaBase = (energy.soft / maxSoft).clamp(0.0, 1.0);
    final hardAlphaBase = (energy.hard / maxHard).clamp(0.0, 1.0);

    // lightMap モードでは alpha を底上げして可視性確保
    final maxFillA = lightMap ? 170 : 135;
    final maxBorderA = lightMap ? 230 : 200;

    final softFillA = (softAlphaBase * rankMul * dimFactor * maxFillA).round();
    final hardFillA = (hardAlphaBase * rankMul * dimFactor * maxFillA).round();
    final softBorderA = (softAlphaBase * rankMul * dimFactor * maxBorderA).round();
    final hardBorderA = (hardAlphaBase * rankMul * dimFactor * maxBorderA).round();

    // 設計思想: ソフト=銀月色 / ハード=金陽色 が基本。
    // ただし activeCategory == 'all' のときは「各方位の dominant カテゴリ色」を
    // 渡せる (tintByDir)。各方位で healing/money/love/work/communication の
    // どれが最大かを反映 → 一目でカテゴリ性質が分かる。
    final tint = tintByDir?[dir];
    final softColor = tint != null
        ? Color.lerp(SolaraColors.energySoft, tint, 0.6)!
        : SolaraColors.energySoft;
    final hardColor = tint != null
        ? Color.lerp(SolaraColors.energyHard, tint, 0.6)!
        : SolaraColors.energyHard;

    // ソフトリング（内側）
    if (softFillA > 5) {
      polygons.add(Polygon(
        points: softPoints,
        color: softColor.withAlpha(softFillA),
        borderColor: softColor.withAlpha(softBorderA),
        borderStrokeWidth: rank == 0 ? 2.0 : 1.2,
      ));
    }
    // ハードリング（外側）
    if (hardFillA > 5) {
      polygons.add(Polygon(
        points: hardPoints,
        color: hardColor.withAlpha(hardFillA),
        borderColor: hardColor.withAlpha(hardBorderA),
        borderStrokeWidth: rank == 0 ? 2.0 : 1.2,
      ));
    }
  }
  return polygons;
}

/// 扇形（リング）のポイント列を生成。
/// innerRatio / outerRatio は radius に対する内側/外側の半径比（0〜1）。
/// innerRatio=0, outerRatio=1 で従来のフル扇。
List<LatLng> _fanPoints(
  Distance d,
  LatLng center,
  double startDeg,
  double endDeg,
  double radius,
  double innerRatio,
  double outerRatio, {
  required int radialSteps,
  required int arcSteps,
}) {
  final points = <LatLng>[];
  final innerR = radius * innerRatio;
  final outerR = radius * outerRatio;

  // 始辺: inner → outer
  for (int step = 0; step <= radialSteps; step++) {
    final t = step / radialSteps;
    final dist = innerR + (outerR - innerR) * t;
    points.add(d.offset(center, dist, startDeg % 360));
  }
  // 外周弧: start → end
  for (int step = 1; step <= arcSteps; step++) {
    final a = startDeg + (endDeg - startDeg) * step / arcSteps;
    points.add(d.offset(center, outerR, a % 360));
  }
  // 終辺: outer → inner
  for (int step = radialSteps; step >= 0; step--) {
    final t = step / radialSteps;
    final dist = innerR + (outerR - innerR) * t;
    points.add(d.offset(center, dist, endDeg % 360));
  }
  // innerR > 0 のとき内周弧を逆順で閉じる
  if (innerR > 0) {
    for (int step = arcSteps - 1; step >= 1; step--) {
      final a = startDeg + (endDeg - startDeg) * step / arcSteps;
      points.add(d.offset(center, innerR, a % 360));
    }
  }
  return points;
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
