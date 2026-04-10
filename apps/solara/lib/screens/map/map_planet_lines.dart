import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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

/// 惑星シンボルマーカー（ラインの端点に表示）
/// HTML: edge tracking — ビューポート端にシンボルを配置する機能は
/// flutter_map では直接実装困難なため、ライン末端に固定配置する
List<Marker> buildPlanetSymbols({
  required List<PlanetLineData> lines,
  required Map<String, bool> layers,
  required Map<String, bool> planetGroupVis,
  required String activeCategory,
}) {
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

    final meta = planetMeta[pl.planet];
    if (meta == null) continue;

    final style = chartStyles[pl.layer]!;
    final isNatal = pl.layer == 'natal';
    final sz = isNatal ? 28.0 : 22.0;
    final fs = isNatal ? 15.0 : 11.0;

    // 線の途中（7番目のポイントあたり）にシンボルを配置
    // HTML では edge tracking するが、Flutter では固定位置
    final symIdx = (pl.points.length * 0.12).round().clamp(1, pl.points.length - 1);
    final symPos = pl.points[symIdx];

    markers.add(Marker(
      point: symPos,
      width: sz, height: sz,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: sz, height: sz,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: style.bg,
            border: isNatal ? null : Border.all(
              color: style.color.withAlpha(153),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(76),
                blurRadius: 4, offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              meta.sym,
              style: TextStyle(
                fontSize: fs, fontWeight: FontWeight.bold,
                color: style.fg,
              ),
            ),
          ),
        ),
      ),
    ));
  }
  return markers;
}
