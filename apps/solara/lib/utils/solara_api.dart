// Solara CF Worker API - 軽量なユーティリティ呼び出し
// (チャート/イベント系は別ファイルに既存。ここは補助エンドポイント用)
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Solara Cloudflare Worker のベース URL（**単一情報源**）。
///
/// 🔴 **重要**: Solara 内で Worker を参照する全ての Dart ファイルは、
/// URL をハードコードせず、この定数を import すること。
///
/// 過去のバグ: 複数箇所に URL を書いた結果、一部が古い `solodev-lab.workers.dev`
/// （存在しないサブドメイン）のままになり、sectory 計算で無言で fallback していた。
///
/// wrangler.toml の設定:
///   routes = [{ pattern = "solara-api.solodev-lab.com", custom_domain = true }]
///   fallback (自動発行): https://solara-api.kojifo369.workers.dev
const String solaraWorkerBase = 'https://solara-api.solodev-lab.com';

/// 緯度経度から IANA TZ名 (DST対応の基準) を取得。
/// 例: (35.68, 139.76) → 'Asia/Tokyo'
/// 失敗時は null を返す (呼び出し側で birthTz 整数fallback想定)。
Future<String?> fetchTimezoneName(double lat, double lng) async {
  try {
    final uri = Uri.parse('$solaraWorkerBase/tz?lat=$lat&lng=$lng');
    final res = await http.get(uri).timeout(const Duration(seconds: 5));
    if (res.statusCode == 200) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      final tz = body['tz'] as String?;
      if (tz != null && tz.isNotEmpty) return tz;
    }
  } catch (_) {
    // network error → fallback
  }
  return null;
}
