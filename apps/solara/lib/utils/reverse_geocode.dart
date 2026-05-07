import 'dart:convert';

import 'package:http/http.dart' as http;

// ============================================================
// reverseGeocode — 緯度経度 → 地名 (Nominatim Reverse) 共通ヘルパー
//
// 2026-05-07: Solara 内で共通利用するために pure 関数として抽出。
//   - map_vp_panel.dart::SlotManager.saveCurrentLocation
//   - horo_birth_panel.dart (Horo 試算用 BirthData 入力)
//
// 実装詳細:
//   - Nominatim Reverse API (User-Agent: SolaraApp/1.0, lang: ja,en)
//   - 抽出優先順: city > town > village > suburb > neighbourhood
//     （suburb 先頭だと OSM の道路ループ等の局所タグを拾うため都市名を優先）
//   - 例外/失敗時は null (呼び出し側で fallback を決める)
// ============================================================

/// 緯度経度から地名（市町村名）を逆ジオコーディングで取得する。
///
/// [maxLength] 指定時は地名を切り詰める (短縮表示用、e.g. VP slot 8文字)。
/// 失敗時は null を返す。
Future<String?> reverseGeocode(double lat, double lng, {int? maxLength}) async {
  try {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?format=json&lat=$lat&lon=$lng&zoom=16',
    );
    final resp = await http.get(uri, headers: {
      'User-Agent': 'SolaraApp/1.0',
      'Accept-Language': 'ja,en',
    }).timeout(const Duration(seconds: 8));
    if (resp.statusCode != 200) return null;
    final data = json.decode(resp.body) as Map<String, dynamic>;
    final addr = data['address'] as Map<String, dynamic>? ?? {};
    final disp = addr['city'] ??
        addr['town'] ??
        addr['village'] ??
        addr['suburb'] ??
        addr['neighbourhood'];
    if (disp == null) return null;
    final name = disp.toString();
    if (maxLength != null && name.length > maxLength) {
      return name.substring(0, maxLength);
    }
    return name;
  } catch (_) {
    return null;
  }
}
