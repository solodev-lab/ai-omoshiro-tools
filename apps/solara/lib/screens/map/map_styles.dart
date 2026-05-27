import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/solara_api.dart' show solaraOsmTileBase;
import '../../utils/tile_http_client.dart';

/// マップスタイルの種類。LayerPanel から切替可。
///
/// 2026-05-09: cyclosm{Light,Dark} を一旦削除。理由は2つ:
/// (1) 本番 Worker のデプロイ済み版に cyclosm allowlist が含まれず HTTP 400 多発
/// (2) CyclOSM の OSM usage policy がアプリ商用利用を制限しており、
///     ストアアップ前に再検討が必要 (Apple/Google 審査で問題視されるリスク)
/// 旧 id 'cyclosm_light' / 'cyclosm_dark' は mapStyleFromId() で osmHotLight に
/// フォールバックされる。詳細: project_solara_map_styles.md
enum MapStyle {
  osmHotLight,
  osmHotDark,
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
  // OSM HOT は Solara Worker 経由でプロキシ。
  // 直叩きだと OSM France 側で UA 不足の 403 が頻発するため、Worker 側で
  // 識別可能な User-Agent を設定 + Cloudflare edge cache 24h で安定化。
  // ラベルは現地言語のまま（Jawg 多言語対応はユーザー増えたら再検討）。
  MapStyle.osmHotLight: MapStyleConfig(
    id: 'osm_hot_light',
    label: 'Map',
    urlTemplate: '$solaraOsmTileBase/hot/{z}/{x}/{y}.png',
    subdomains: [],
    maxZoom: 19,
    dark: false,
    backgroundColor: Color(0xFFF4F1EA),
  ),
  MapStyle.osmHotDark: MapStyleConfig(
    id: 'osm_hot_dark',
    label: 'MapDark',
    urlTemplate: '$solaraOsmTileBase/hot/{z}/{x}/{y}.png',
    subdomains: [],
    maxZoom: 19,
    dark: true,
    backgroundColor: Color(0xFF0A0A14),
  ),
};

/// id 文字列から MapStyle を復元。
/// 不明値（未保存・旧 Smart/Jawg/CyclOSM id）は osmHotLight にフォールバック。
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
///
/// [resetStream] 呼出側で `StreamController<void>` を持ち `add(null)` 発火すると、
///   flutter_map の公式機構で全タイルを State 保持のまま再 fetch する。
///   過去の ValueKey bump (State 破棄) は in-flight fetch をキャンセルして
///   Case C (flutter_map がタイル消失に気付かない状態) を量産していたので廃止。
/// [onTileError] 個別タイル fetch 失敗時に呼ばれる。caller でデバウンスして
///   resetStream を発火すると、まとめて再試行できる。
Widget buildStyledTileLayer(
  MapStyle style, {
  Stream<void>? resetStream,
  void Function()? onTileError,
}) {
  final cfg = mapStyleConfigs[style]!;
  // 2026-05-09: TileLayer の ValueKey を撤去。
  // 過去 (2026-05-08) は urlTemplate ベース key で State 維持を狙ったが、
  // dark 用 ColorFiltered ラップで親要素の型が変わるため、ValueKey 同一でも
  // State は破棄される (Flutter element matching の仕様)。
  // 8.3.0 の内部 TileKey システム (#2195) との衝突回避も兼ねて key 撤去。
  // State 強制再生成は reset Stream で実現する。
  final layer = TileLayer(
    urlTemplate: cfg.urlTemplate,
    subdomains: cfg.subdomains,
    maxZoom: cfg.maxZoom.toDouble(),
    userAgentPackageName: 'com.solara.app',
    tileProvider: NetworkTileProvider(httpClient: sharedTileHttpClient),
    // 2026-05-09: 公式の State 保持リフレッシュ機構 (v8.0+ TileLayer.reset)。
    // Case C (errorTileCallback も呼ばれず痕跡なくタイルが蒸発する状態) からの
    // 唯一効く復旧手段。caller が StreamController で発火を制御。
    reset: resetStream,
    // 2026-05-03: タイル fade-in を無効化 (内部 AnimatedOpacity が saveLayer trigger)。
    // ACG モード 2 回目入時の画面点滅 / Map スクロール後の砂嵐の主因対策。
    tileDisplay: const TileDisplay.instantaneous(),
    // 2026-05-07: hot restart 直後の「一部タイル描画されない」対策。
    // errored タイルは pan/zoom で margin 外に出たら自動 evict → 次回 fetch 機会を作る。
    evictErrorTileStrategy: EvictErrorTileStrategy.notVisibleRespectMargin,
    // 2026-05-08 診断ログ追加: タイル fetch エラーをターミナルに表示。
    // Worker 側の問題 (5xx/429) なのか flutter_map 内部 (タイムアウト/解析失敗)
    // なのか切り分けるための情報源。本番ビルド (kReleaseMode) では何も出さない。
    errorTileCallback: (tile, error, stackTrace) {
      if (kDebugMode) {
        // ignore: avoid_print
        debugPrint(
          '[Solara TileLayer] ❌ z=${tile.coordinates.z} '
          'x=${tile.coordinates.x} y=${tile.coordinates.y} → $error',
        );
      }
      if (onTileError != null) onTileError();
    },
  );
  if (kDebugMode) {
    // ignore: avoid_print
    debugPrint('[Solara TileLayer] 🏗  build style=${cfg.id}');
  }
  if (!cfg.dark) return layer;
  // Phase 3 (2026-05-04): per-tile ColorFiltered → container 単位に変更。
  // saveLayer 回数を画面タイル数 (~36) から 1 に削減。matrix は flutter_map 公式の
  // darkModeTilesContainerBuilder と同一値 (invert + hue-rotate 180° を 1 段合成)。
  return ColorFiltered(
    colorFilter: const ColorFilter.matrix(_darkInvertHueRotate180Matrix),
    child: layer,
  );
}

// ── OSM Attribution (ODbL ライセンス必須要件) ────────────────────────
// OpenStreetMap のタイルを表示するすべての画面で必須。Apple/Google ストア
// 審査の地図カテゴリチェックでも検出対象。"© OpenStreetMap contributors"
// 表記 + ODbL ライセンスページへのリンクが必要。
// (HOT タイル使用なので Humanitarian OSM Team もクレジット推奨)。
// 通常 FlutterMap children の最後尾に追加して右下に表示する。

/// 標準サイズの attribution (Map メイン画面・候補地ピッカー用)。
/// デフォルトで右下に「i」アイコン、タップで展開して全クレジット表示。
Widget buildOsmAttribution() {
  return RichAttributionWidget(
    showFlutterMapAttribution: false,
    attributions: [
      TextSourceAttribution(
        'OpenStreetMap contributors',
        onTap: () => launchUrl(
          Uri.parse('https://www.openstreetmap.org/copyright'),
          mode: LaunchMode.externalApplication,
        ),
      ),
      const TextSourceAttribution('Humanitarian OSM Team'),
    ],
  );
}

/// minimap (出生地入力等の小さい埋め込み地図) 用の常時表示版。
/// 「i」展開式は誤タップが多いため、最小限の文字列で右下固定表示。
Widget buildOsmAttributionCompact() {
  return const SimpleAttributionWidget(
    source: Text(
      '© OpenStreetMap',
      style: TextStyle(fontSize: 9, color: Color(0xFF333333)),
    ),
    backgroundColor: Color(0xCCFFFFFF),
  );
}
