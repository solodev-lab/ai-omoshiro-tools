import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// マップスタイルの種類。LayerPanel から切替可。
enum MapStyle {
  osmHotLight,
  osmHotDark,
  cyclosmLight,
  cyclosmDark,
}

/// ナイトモード用の2段フィルター：
/// ①色を反転（invert）→ ②色相を180°回転（hue-rotate）
/// 合成すると CSS の `filter: invert(1) hue-rotate(180deg)` と同等。
/// 白背景→黒、黒文字→白、赤道路→赤のまま（色相保持）。
const List<double> _invertMatrix = <double>[
  -1, 0, 0, 0, 255,
   0,-1, 0, 0, 255,
   0, 0,-1, 0, 255,
   0, 0, 0, 1, 0,
];
const List<double> _hueRotate180Matrix = <double>[
  -0.574, 1.430, 0.144, 0, 0,
   0.426, 0.430, 0.144, 0, 0,
   0.426, 1.430,-0.856, 0, 0,
   0,     0,    0,     1, 0,
];

class MapStyleConfig {
  final String id;
  final String label;
  final String urlTemplate;
  final List<String> subdomains;
  final int maxZoom;
  final bool dark;
  final Color backgroundColor;

  const MapStyleConfig({
    required this.id,
    required this.label,
    required this.urlTemplate,
    required this.subdomains,
    required this.maxZoom,
    required this.dark,
    required this.backgroundColor,
  });
}

const Map<MapStyle, MapStyleConfig> mapStyleConfigs = {
  MapStyle.osmHotLight: MapStyleConfig(
    id: 'osm_hot_light',
    label: 'OSM',
    urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
    subdomains: ['a', 'b', 'c'],
    maxZoom: 19,
    dark: false,
    backgroundColor: Color(0xFFF4F1EA),
  ),
  MapStyle.osmHotDark: MapStyleConfig(
    id: 'osm_hot_dark',
    label: 'OSM 夜',
    urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
    subdomains: ['a', 'b', 'c'],
    maxZoom: 19,
    dark: true,
    backgroundColor: Color(0xFF0A0A14),
  ),
  MapStyle.cyclosmLight: MapStyleConfig(
    id: 'cyclosm_light',
    label: 'Cycle',
    urlTemplate: 'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
    subdomains: ['a', 'b', 'c'],
    maxZoom: 19,
    dark: false,
    backgroundColor: Color(0xFFF4F1EA),
  ),
  MapStyle.cyclosmDark: MapStyleConfig(
    id: 'cyclosm_dark',
    label: 'Cycle 夜',
    urlTemplate: 'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
    subdomains: ['a', 'b', 'c'],
    maxZoom: 19,
    dark: true,
    backgroundColor: Color(0xFF0A0A14),
  ),
};

/// id 文字列から MapStyle を復元。不明値は osmHotLight。
MapStyle mapStyleFromId(String? id) {
  for (final e in mapStyleConfigs.entries) {
    if (e.value.id == id) return e.key;
  }
  return MapStyle.osmHotLight;
}

/// 選択スタイルに応じた TileLayer を返す。dark 時は ColorFilter を被せる。
Widget buildStyledTileLayer(MapStyle style) {
  final cfg = mapStyleConfigs[style]!;
  return TileLayer(
    urlTemplate: cfg.urlTemplate,
    subdomains: cfg.subdomains,
    maxZoom: cfg.maxZoom.toDouble(),
    userAgentPackageName: 'com.solara.app',
    tileBuilder: cfg.dark
      ? (context, tileWidget, tile) => ColorFiltered(
          // 外側：色相180°回転（invert後の色を元に戻す）
          colorFilter: const ColorFilter.matrix(_hueRotate180Matrix),
          child: ColorFiltered(
            // 内側：色反転（白↔黒）
            colorFilter: const ColorFilter.matrix(_invertMatrix),
            child: tileWidget,
          ),
        )
      : null,
  );
}
