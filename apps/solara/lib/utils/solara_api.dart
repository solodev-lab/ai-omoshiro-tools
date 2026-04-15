// Solara CF Worker API - 軽量なユーティリティ呼び出し
// (チャート/イベント系は別ファイルに既存。ここは補助エンドポイント用)
import 'dart:convert';
import 'package:http/http.dart' as http;

const String solaraWorkerBase = 'https://solara-api.solodev-lab.workers.dev';

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
