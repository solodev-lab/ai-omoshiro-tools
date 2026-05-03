import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../utils/solara_api.dart' show solaraWorkerBase;
import '../../utils/tile_http_client.dart';

/// マップスタイルの種類。LayerPanel から切替可。
enum MapStyle {
  osmHotLight,
  osmHotDark,
  cyclosmLight,
  cyclosmDark,
}

/// ナイトモード用の合成フィルター: invert + hue-rotate(180deg) を 1 段に合成。
/// CSS の `filter: invert(1) hue-rotate(180deg)` と同等。
/// Phase 3 (2026-05-03): 二重 ColorFiltered の saveLayer を 1 段に削減し、
/// ACG 画面点滅 / タイル描画砂嵐の主因を撤去。
/// (M2 * M1 を Python np.matmul で算出、テストピクセルで反転・色相維持を確認済)
const List<double> _darkInvertHueRotate180Matrix = <double>[
   0.574, -1.430, -0.144, 0, 255,
  -0.426, -0.430, -0.144, 0, 255,
  -0.426, -1.430,  0.856, 0, 255,
   0,      0,      0,     1,   0,
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
    this.subdomains = const ['a', 'b', 'c'],
    required this.maxZoom,
    required this.dark,
    required this.backgroundColor,
  });
}

const Map<MapStyle, MapStyleConfig> mapStyleConfigs = {
  // OSM HOT / CyclOSM はすべて Solara Worker 経由でプロキシ。
  // 直叩きだと OSM France 側で UA 不足の 403 が頻発するため、Worker 側で
  // 識別可能な User-Agent を設定 + Cloudflare edge cache 24h で安定化。
  // ラベルは現地言語のまま（Jawg 多言語対応はユーザー増えたら再検討）。
  MapStyle.osmHotLight: MapStyleConfig(
    id: 'osm_hot_light',
    label: 'Map',
    urlTemplate: '$solaraWorkerBase/tiles/osm/hot/{z}/{x}/{y}.png',
    subdomains: [],
    maxZoom: 19,
    dark: false,
    backgroundColor: Color(0xFFF4F1EA),
  ),
  MapStyle.osmHotDark: MapStyleConfig(
    id: 'osm_hot_dark',
    label: 'MapDark',
    urlTemplate: '$solaraWorkerBase/tiles/osm/hot/{z}/{x}/{y}.png',
    subdomains: [],
    maxZoom: 19,
    dark: true,
    backgroundColor: Color(0xFF0A0A14),
  ),
  MapStyle.cyclosmLight: MapStyleConfig(
    id: 'cyclosm_light',
    label: 'Cycle',
    urlTemplate: '$solaraWorkerBase/tiles/osm/cyclosm/{z}/{x}/{y}.png',
    subdomains: [],
    maxZoom: 19,
    dark: false,
    backgroundColor: Color(0xFFF4F1EA),
  ),
  MapStyle.cyclosmDark: MapStyleConfig(
    id: 'cyclosm_dark',
    label: 'CycleDark',
    urlTemplate: '$solaraWorkerBase/tiles/osm/cyclosm/{z}/{x}/{y}.png',
    subdomains: [],
    maxZoom: 19,
    dark: true,
    backgroundColor: Color(0xFF0A0A14),
  ),
};

/// id 文字列から MapStyle を復元。不明値（未保存・旧 Smart/Jawg id）は osmHotLight。
MapStyle mapStyleFromId(String? id) {
  for (final e in mapStyleConfigs.entries) {
    if (e.value.id == id) return e.key;
  }
  return MapStyle.osmHotLight;
}

/// 選択スタイルに応じた TileLayer を返す。
/// dark 指定の場合は ColorFilter で反転して暗色化。
///
/// tileProvider: アプリ全体で共有する HttpClient を渡し、
///   socket 枯渇による DNS 失敗の連鎖を防止 (詳細: tile_http_client.dart)。
Widget buildStyledTileLayer(MapStyle style) {
  final cfg = mapStyleConfigs[style]!;
  return TileLayer(
    key: ValueKey(cfg.id),
    urlTemplate: cfg.urlTemplate,
    subdomains: cfg.subdomains,
    maxZoom: cfg.maxZoom.toDouble(),
    userAgentPackageName: 'com.solara.app',
    tileProvider: NetworkTileProvider(httpClient: sharedTileHttpClient),
    // 2026-05-03: タイル fade-in を無効化 (内部 AnimatedOpacity が saveLayer trigger)。
    // ACG モード 2 回目入時の画面点滅 / Map スクロール後の砂嵐の主因対策。
    tileDisplay: const TileDisplay.instantaneous(),
    tileBuilder: cfg.dark
        ? (context, tileWidget, tile) => ColorFiltered(
              // 1 段に合成済 (saveLayer x2 → x1、ACG 画面点滅対策)
              colorFilter: const ColorFilter.matrix(_darkInvertHueRotate180Matrix),
              child: tileWidget,
            )
        : null,
  );
}
