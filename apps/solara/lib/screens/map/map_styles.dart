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

/// ナイトモード用の2段フィルター：
/// ①色を反転（invert）→ ②色相を180°回転（hue-rotate）
/// 合成すると CSS の `filter: invert(1) hue-rotate(180deg)` と同等。
///
/// 2026-05-01: 旧版は ColorFiltered を 2段ネスト (内: invert / 外: hue-rotate)
/// していたが、各 ColorFiltered が独立した GPU saveLayer / Surface buffer を
/// 生成するため、画面上のタイル枚数 × 2 倍のオフスクリーンバッファが消費され、
/// Adreno (Snapdragon) で fd 枯渇 + メモリプレッシャーの主要因となっていた。
///
/// 解決策: 4×5 アフィン色行列を CPU 側で前計算合成 (`hue ∘ invert`)、
/// 単一の ColorFiltered で同じ視覚結果を得る。saveLayer 数が半減する。
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

/// 4×5 アフィン色行列の合成: `outer ∘ inner`。
/// out = outer · (inner · src + inner_offset) + outer_offset
///     = (outer · inner) · src + (outer · inner_offset + outer_offset)
List<double> _composeColorMatrix(List<double> outer, List<double> inner) {
  final r = List<double>.filled(20, 0);
  for (int row = 0; row < 4; row++) {
    for (int col = 0; col < 4; col++) {
      double sum = 0;
      for (int k = 0; k < 4; k++) {
        sum += outer[row * 5 + k] * inner[k * 5 + col];
      }
      r[row * 5 + col] = sum;
    }
    // offset 列: outer · inner_offset + outer_offset
    double offset = outer[row * 5 + 4];
    for (int k = 0; k < 4; k++) {
      offset += outer[row * 5 + k] * inner[k * 5 + 4];
    }
    r[row * 5 + 4] = offset;
  }
  return r;
}

/// 起動時に一度だけ計算する合成行列 (hue-rotate ∘ invert)。
final List<double> _darkComposedMatrix =
    _composeColorMatrix(_hueRotate180Matrix, _invertMatrix);

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
    tileBuilder: cfg.dark
        ? (context, tileWidget, tile) => ColorFiltered(
              // 2026-05-01: hue-rotate ∘ invert を 1段合成。
              // saveLayer / Surface buffer がタイル枚数分減り Adreno で安定化。
              colorFilter: ColorFilter.matrix(_darkComposedMatrix),
              child: tileWidget,
            )
        : null,
  );
}
