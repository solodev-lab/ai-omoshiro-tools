import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../widgets/solara_nav_bar.dart';
import '../horoscope/horo_panel_shared.dart' show PlanetVectorIcon;
import 'map_constants.dart';
import 'map_astro.dart';

/// HTML: addPlanetLines() — natal/progressed/transit 天体ラインを描画
/// turfLine(center, bearing, 20000km, 50pts) の大圏線を各惑星角度で描く

/// 大圏線のポイント生成（HTML: turfLine() 準拠）
List<LatLng> _geodesicLine(LatLng center, double bearing, {int steps = 50, double maxKm = 20000}) {
  const d = Distance();
  final pts = <LatLng>[];
  for (int i = 0; i <= steps; i++) {
    final dist = maxKm * 1000 * i / steps; // meters
    pts.add(d.offset(center, dist, bearing));
  }
  return pts;
}

/// 惑星のグループ名を返す
String? _planetGroup(String name) {
  for (final e in planetGroups.entries) {
    if (e.value.contains(name)) return e.key;
  }
  return null;
}

/// 1惑星分のライン情報
class PlanetLineData {
  final String planet;
  final String layer; // 'natal' | 'progressed' | 'transit'
  final double angle;
  final List<LatLng> points;
  final Color color;
  final double weight;
  final double opacity;
  final List<double>? dashPattern;

  const PlanetLineData({
    required this.planet, required this.layer, required this.angle,
    required this.points, required this.color, required this.weight,
    required this.opacity, this.dashPattern,
  });
}

/// ChartResult から全天体ラインデータを生成
List<PlanetLineData> buildPlanetLineData({
  required LatLng center,
  required ChartResult chart,
}) {
  final results = <PlanetLineData>[];

  final layerData = <String, Map<String, double>>{
    'natal': chart.natal,
    if (chart.transit != null) 'transit': chart.transit!,
    if (chart.progressed != null) 'progressed': chart.progressed!,
  };

  for (final entry in layerData.entries) {
    final lk = entry.key;
    final cd = entry.value;
    final style = chartStyles[lk]!;

    for (final pe in cd.entries) {
      final name = pe.key;
      if (name.startsWith('_')) continue; // skip _asc, _mc, _dsc, _ic
      final angle = pe.value;
      final pts = _geodesicLine(center, angle, steps: 50, maxKm: 20000);

      results.add(PlanetLineData(
        planet: name, layer: lk, angle: angle,
        points: pts, color: style.color,
        weight: style.weight, opacity: style.opacity,
        dashPattern: style.dashPattern,
      ));
    }
  }
  return results;
}

/// PlanetLineData → flutter_map Polyline に変換
/// フィルター: layer visibility, planet group visibility, fortune category filter
List<Polyline> buildPlanetPolylines({
  required List<PlanetLineData> lines,
  required Map<String, bool> layers,
  required Map<String, bool> planetGroupVis,
  required String activeCategory,
}) {
  final polylines = <Polyline>[];
  for (final pl in lines) {
    // Layer filter
    if (!(layers[pl.layer] ?? false)) continue;

    // Planet group filter
    final pg = _planetGroup(pl.planet);
    if (pg != null && !(planetGroupVis[pg] ?? true)) continue;

    // Fortune category filter
    double opacity = pl.opacity;
    if (activeCategory != 'all') {
      final catPlanets = fortunePlanets[activeCategory];
      if (catPlanets != null && !catPlanets.contains(pl.planet)) {
        opacity = 0.05; // dim
      }
    }

    polylines.add(Polyline(
      points: pl.points,
      color: pl.color.withAlpha((opacity * 255).round()),
      strokeWidth: pl.weight,
      pattern: pl.dashPattern != null
        ? StrokePattern.dashed(segments: pl.dashPattern!)
        : const StrokePattern.solid(),
    ));
  }
  return polylines;
}

/// 惑星シンボルレイヤー（HTML: updateSymPos の edge tracking を再現）
///
/// 各惑星ラインを画面座標に投影し、Liang–Barsky でビューポート矩形（マージン 30px）
/// との交点を求めてシンボルを配置する。
/// - 交点あり → ビューポート端にシンボル
/// - 交点なし & ライン上の点が画面内にある → ライン末端
/// - どちらでもない → 非表示（透明度 0）
///
/// `MapCamera.of(context)` を使うため `FlutterMap` の `children` 内で使うこと。
/// flutter_map 8.x の InheritedModel が camera 変化で自動 rebuild する。
class PlanetSymbolsLayer extends StatelessWidget {
  final List<PlanetLineData> lines;
  final Map<String, bool> layers;
  final Map<String, bool> planetGroupVis;
  final String activeCategory;

  const PlanetSymbolsLayer({
    super.key,
    required this.lines,
    required this.layers,
    required this.planetGroupVis,
    required this.activeCategory,
  });

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final size = camera.nonRotatedSize;
    // 画面サイズ未確定（初期 1フレーム目の kImpossibleSize 等）はスキップ
    if (size.width <= 0 || size.height <= 0) {
      return const SizedBox.shrink();
    }

    // 2026-04-29: 左右マージンを縮小 (ユーザー要望「画面の端に近づけて、左右対称」)。
    // 下端は SolaraNavBar 全高 (= 80 + 3ボタンナビ時のみ systemNav-12px) を避ける。
    // ジェスチャーナビ端末ではここの加算は 0 で、旧来の 92px と同等。
    const leftMargin = 12.0;
    const rightMargin = 12.0;
    const topMargin = 30.0;
    final navInset = SolaraNavBar.systemNavInset(context);
    final bottomMargin = 80.0 + navInset + 12.0; // NavBar全高 + 視覚マージン
    final xn = leftMargin;
    final yn = topMargin;
    final xx = size.width - rightMargin;
    final yx = size.height - bottomMargin;

    final markers = <Marker>[];
    for (final pl in lines) {
      if (!(layers[pl.layer] ?? false)) continue;
      final pg = _planetGroup(pl.planet);
      if (pg != null && !(planetGroupVis[pg] ?? true)) continue;

      double opacity = 1.0;
      if (activeCategory != 'all') {
        final catPlanets = fortunePlanets[activeCategory];
        if (catPlanets != null && !catPlanets.contains(pl.planet)) {
          opacity = 0.1;
        }
      }

      // 惑星キーが planetMeta に登録されていない場合はスキップ（_asc 等は line 生成時に弾かれる）
      if (!planetMeta.containsKey(pl.planet)) continue;

      // Liang–Barsky でビューポート交点を探索（HTML: updateSymPos と等価）
      Offset? bestExit;
      Offset? last;
      bool inside = false;
      for (int i = 0; i < pl.points.length; i++) {
        final px = camera.latLngToScreenOffset(pl.points[i]);
        if (px.dx >= xn && px.dx <= xx && px.dy >= yn && px.dy <= yx) {
          inside = true;
        }
        if (i > 0 && last != null) {
          final dx = px.dx - last.dx;
          final dy = px.dy - last.dy;
          final sp = <double>[-dx, dx, -dy, dy];
          final sq = <double>[last.dx - xn, xx - last.dx, last.dy - yn, yx - last.dy];
          double t0 = 0, t1 = 1;
          bool ok = true;
          for (int j = 0; j < 4; j++) {
            if (sp[j] == 0) {
              if (sq[j] < 0) { ok = false; break; }
            } else {
              final t = sq[j] / sp[j];
              if (sp[j] < 0) {
                if (t > t0) t0 = t;
              } else {
                if (t < t1) t1 = t;
              }
            }
          }
          if (ok && t0 <= t1) {
            bestExit = Offset(last.dx + dx * t1, last.dy + dy * t1);
          }
        }
        last = px;
      }

      LatLng markerPos;
      if (bestExit != null) {
        markerPos = camera.screenOffsetToLatLng(bestExit);
      } else if (inside) {
        markerPos = pl.points.last;
      } else {
        continue; // 画面外
      }

      final style = chartStyles[pl.layer]!;
      final isNatal = pl.layer == 'natal';
      final sz = isNatal ? 28.0 : 22.0;
      // ベクターグリフのサイズ。フォント描画と違い OS に依存しないので Venus/Mars も
      // 他惑星と同じ単色細線で揃う。Horo 画面と同じ PlanetVectorIcon を使用。
      final glyphSize = isNatal ? 18.0 : 14.0;

      // 2026-05-03: Opacity widget 撤去 (ACG 画面点滅の原因)。
      // opacity を各色の alpha に伝搬 = saveLayer 回避。
      markers.add(Marker(
        point: markerPos,
        width: sz, height: sz,
        child: Container(
          width: sz, height: sz,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: style.bg.withValues(alpha: opacity),
            border: isNatal ? null : Border.all(
              color: style.color.withAlpha((153 * opacity).round()),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((76 * opacity).round()),
                blurRadius: 4, offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: PlanetVectorIcon(
              planetKey: pl.planet,
              size: glyphSize,
              color: style.fg.withValues(alpha: opacity),
            ),
          ),
        ),
      ));
    }
    return MarkerLayer(markers: markers);
  }
}
