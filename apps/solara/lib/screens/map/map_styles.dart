import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../utils/solara_api.dart' show solaraWorkerBase;
import 'map_hybrid_provider.dart';

/// マップスタイルの種類。LayerPanel から切替可。
enum MapStyle {
  smartLight,
  jawgStreets,
  jawgDark,
  osmHotLight,
  osmHotDark,
  cyclosmLight,
  cyclosmDark,
}

/// ナイトモード用の2段フィルター：
/// ①色を反転（invert）→ ②色相を180°回転（hue-rotate）
/// 合成すると CSS の `filter: invert(1) hue-rotate(180deg)` と同等。
///
/// Jawg Dark のように既にダークなタイルには適用しない。
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

  /// URL テンプレート。Jawg 系では `{lang}` プレースホルダを含み、
  /// [buildStyledTileLayer] で現在の言語に置換される。
  /// ハイブリッドスタイルでは使用しない（カスタム TileProvider が URL 生成）。
  final String urlTemplate;
  final List<String> subdomains;
  final int maxZoom;
  final bool dark;
  final Color backgroundColor;

  /// Jawg のようにサーバ側で既にダーク配色のタイルは、ColorFilter invert を適用しない。
  final bool supportsInvertFilter;

  /// `true` の場合、URL テンプレートの `{lang}` を現在の map 言語で置換する。
  /// または（[useHybrid] が true なら）言語圏判定に使う。
  final bool supportsLanguage;

  /// `true` の場合、[HybridLangTileProvider] を使って
  /// 言語ホーム圏 = OSM HOT、圏外 = Jawg にルーティングする。
  final bool useHybrid;

  const MapStyleConfig({
    required this.id,
    required this.label,
    required this.urlTemplate,
    this.subdomains = const ['a', 'b', 'c'],
    required this.maxZoom,
    required this.dark,
    required this.backgroundColor,
    this.supportsInvertFilter = true,
    this.supportsLanguage = false,
    this.useHybrid = false,
  });
}

const Map<MapStyle, MapStyleConfig> mapStyleConfigs = {
  // Smart — ハイブリッド: 言語ホーム圏は OSM HOT（無料）、圏外は Jawg（有料）。
  // Jawg 無料枠を節約しつつ多言語対応を維持する推奨スタイル。
  // Light のみ。Dark は Jawg Dark を別途選択。
  MapStyle.smartLight: MapStyleConfig(
    id: 'smart_light',
    label: 'Smart',
    urlTemplate: '', // ハイブリッドは TileProvider 側で URL 生成
    maxZoom: 19,
    dark: false,
    backgroundColor: Color(0xFFF4F1EA),
    supportsLanguage: true,
    useHybrid: true,
  ),
  // Jawg Maps — ラスタタイルだが `?lang=xx` で多言語ラベル切替可能
  // アプリ → solara-api Worker → Jawg の順でプロキシされる
  MapStyle.jawgStreets: MapStyleConfig(
    id: 'jawg_streets',
    label: 'Jawg',
    urlTemplate:
        '$solaraWorkerBase/tiles/jawg/jawg-streets/{z}/{x}/{y}.png?lang={lang}',
    subdomains: [],
    maxZoom: 22,
    dark: false,
    backgroundColor: Color(0xFFF4F1EA),
    supportsLanguage: true,
  ),
  MapStyle.jawgDark: MapStyleConfig(
    id: 'jawg_dark',
    label: 'Jawg 夜',
    urlTemplate:
        '$solaraWorkerBase/tiles/jawg/jawg-dark/{z}/{x}/{y}.png?lang={lang}',
    subdomains: [],
    maxZoom: 22,
    dark: true,
    backgroundColor: Color(0xFF0A0A14),
    // サーバ側で既にダーク配色なので invert フィルタ不要
    supportsInvertFilter: false,
    supportsLanguage: true,
  ),
  MapStyle.osmHotLight: MapStyleConfig(
    id: 'osm_hot_light',
    label: 'OSM',
    urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
    maxZoom: 19,
    dark: false,
    backgroundColor: Color(0xFFF4F1EA),
  ),
  MapStyle.osmHotDark: MapStyleConfig(
    id: 'osm_hot_dark',
    label: 'OSM 夜',
    urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
    maxZoom: 19,
    dark: true,
    backgroundColor: Color(0xFF0A0A14),
  ),
  MapStyle.cyclosmLight: MapStyleConfig(
    id: 'cyclosm_light',
    label: 'Cycle',
    urlTemplate:
        'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
    maxZoom: 19,
    dark: false,
    backgroundColor: Color(0xFFF4F1EA),
  ),
  MapStyle.cyclosmDark: MapStyleConfig(
    id: 'cyclosm_dark',
    label: 'Cycle 夜',
    urlTemplate:
        'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
    maxZoom: 19,
    dark: true,
    backgroundColor: Color(0xFF0A0A14),
  ),
};

/// id 文字列から MapStyle を復元。不明値（未保存・旧id）は smartLight。
/// Smart はハイブリッドで節約かつ多言語対応なので新規ユーザー向けのベストデフォルト。
MapStyle mapStyleFromId(String? id) {
  for (final e in mapStyleConfigs.entries) {
    if (e.value.id == id) return e.key;
  }
  return MapStyle.smartLight;
}

/// 選択スタイルに応じた TileLayer を返す。
/// - Smart（ハイブリッド）: [HybridLangTileProvider] でタイル単位に OSM / Jawg 振分け
/// - Jawg 系: URL の `{lang}` を現在値に置換（トークンは Worker 側で注入）
/// - dark 指定 + supportsInvertFilter の場合は ColorFilter で反転
Widget buildStyledTileLayer(MapStyle style, {String lang = 'ja'}) {
  final cfg = mapStyleConfigs[style]!;
  if (cfg.useHybrid) {
    return TileLayer(
      maxZoom: cfg.maxZoom.toDouble(),
      userAgentPackageName: 'com.solara.app',
      tileProvider: HybridLangTileProvider(
        lang: lang,
        jawgStyleId: 'jawg-streets', // Smart は Light のみサポート
      ),
    );
  }
  var url = cfg.urlTemplate;
  if (cfg.supportsLanguage) {
    url = url.replaceAll('{lang}', lang);
  }
  return TileLayer(
    urlTemplate: url,
    subdomains: cfg.subdomains,
    maxZoom: cfg.maxZoom.toDouble(),
    userAgentPackageName: 'com.solara.app',
    tileBuilder: (cfg.dark && cfg.supportsInvertFilter)
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
