import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../utils/solara_api.dart' show solaraWorkerBase;

/// 「その言語が OSM HOT で自然に表示される地理範囲（= 現地語が一致する国）」
///
/// ここに含まれるタイルは無料の OSM HOT で配信し、範囲外のタイルだけ Jawg で
/// 配信する。これで Jawg の有料枠を海外エリアのみに限定できる。
///
/// 各エントリ: `[south, north, west, east]`（度、WGS84）
const Map<String, List<List<double>>> langHomeBounds = {
  'ja': <List<double>>[
    // 日本本土〜南西諸島・小笠原まで含む大きめの bbox
    <double>[20.0, 46.0, 122.0, 154.0],
  ],
  'en': <List<double>>[
    <double>[24.0, 50.0, -125.0, -66.0], // 米本土
    <double>[55.0, 72.0, -170.0, -129.0], // アラスカ
    <double>[17.0, 23.0, -161.0, -154.0], // ハワイ（米国ターゲットで追加）
    <double>[17.0, 19.0, -68.0, -65.0], // プエルトリコ（米自治領）
    <double>[42.0, 83.0, -141.0, -52.0], // カナダ
    <double>[49.0, 61.0, -11.0, 2.0], // 英・アイルランド
    <double>[-45.0, -10.0, 112.0, 154.0], // 豪
    <double>[-48.0, -34.0, 165.0, 180.0], // NZ
  ],
};

/// ハイブリッド適用の最小ズーム。これより低い（世界俯瞰〜大陸レベル）では
/// 常に Jawg を使う（多言語性を優先し、OSM 日本語ラベルで世界が埋まるのを避ける）。
const int hybridMinZoom = 5;

/// 地図タイル座標 (z/x/y) を見て、言語圏内なら OSM HOT、圏外なら Jawg
/// （Solara Worker プロキシ経由）にルーティングする [TileProvider]。
///
/// Jawg 無料枠を浪費しないための節約戦略。
/// - 設定言語 = ja の場合、日本を映すタイルは OSM HOT（無料・現地日本語）
/// - 設定言語 = en の場合、米英豪加NZを映すタイルは OSM HOT（無料・現地英語）
/// - 上記以外 or ズーム < [hybridMinZoom] は Jawg を使用（有料だが多言語対応）
class HybridLangTileProvider extends TileProvider {
  /// UI から渡される言語コード。'ja' / 'en' 等。
  final String lang;

  /// Jawg の style id（'jawg-streets' / 'jawg-dark' 等）。Light 系で運用する。
  final String jawgStyleId;

  HybridLangTileProvider({
    required this.lang,
    this.jawgStyleId = 'jawg-streets',
    super.headers,
  });

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = _useOsmForTile(coordinates)
        ? _osmUrl(coordinates)
        : _jawgUrl(coordinates);
    return NetworkImage(url, headers: headers.isEmpty ? null : headers);
  }

  /// このタイルを OSM HOT で代用できるか判定。
  bool _useOsmForTile(TileCoordinates coords) {
    if (coords.z.toInt() < hybridMinZoom) return false;
    final bounds = langHomeBounds[lang];
    if (bounds == null || bounds.isEmpty) return false;
    final tileBbox = _tileBbox(coords);
    return bounds.any((b) => _bboxIntersects(b, tileBbox));
  }

  /// タイル座標 → [south, north, west, east]（Web Mercator 逆変換）
  static List<double> _tileBbox(TileCoordinates coords) {
    final z = coords.z.toInt();
    final x = coords.x.toInt();
    final y = coords.y.toInt();
    final n = 1 << z;
    final west = x / n * 360.0 - 180.0;
    final east = (x + 1) / n * 360.0 - 180.0;
    final north = _tileY2Lat(y, z);
    final south = _tileY2Lat(y + 1, z);
    return <double>[south, north, west, east];
  }

  static double _tileY2Lat(int y, int z) {
    final n = pi - 2 * pi * y / (1 << z);
    return 180.0 / pi * atan(0.5 * (exp(n) - exp(-n)));
  }

  /// [south, north, west, east] 形式の2つの bbox が交差するか判定。
  static bool _bboxIntersects(List<double> a, List<double> b) {
    if (a[1] < b[0]) return false; // a.north < b.south
    if (a[0] > b[1]) return false; // a.south > b.north
    if (a[3] < b[2]) return false; // a.east < b.west
    if (a[2] > b[3]) return false; // a.west > b.east
    return true;
  }

  String _osmUrl(TileCoordinates coords) {
    final z = coords.z.toInt();
    final x = coords.x.toInt();
    final y = coords.y.toInt();
    // OSM HOT — subdomain ローテーション
    final subdomain = ['a', 'b', 'c'][(x + y) % 3];
    return 'https://$subdomain.tile.openstreetmap.fr/hot/$z/$x/$y.png';
  }

  String _jawgUrl(TileCoordinates coords) {
    final z = coords.z.toInt();
    final x = coords.x.toInt();
    final y = coords.y.toInt();
    return '$solaraWorkerBase/tiles/jawg/$jawgStyleId/$z/$x/$y.png?lang=$lang';
  }
}
