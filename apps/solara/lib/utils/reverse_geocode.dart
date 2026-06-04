import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_locale.dart';

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
  final detail = await reverseGeocodeDetail(lat, lng);
  if (detail?.name == null) return null;
  final name = detail!.name!;
  if (maxLength != null && name.length > maxLength) {
    return name.substring(0, maxLength);
  }
  return name;
}

/// Nominatim Reverse の結果から取り出した詳細レコード。
/// いずれも欠落しうるので呼出側で null 許容を扱うこと。
class ReverseGeocodeResult {
  /// 都市名 (city > town > village > suburb > neighbourhood)。
  final String? name;

  /// 第一行政区分 (都道府県 / 州 / region)。Nominatim の `state` / `province` 由来。
  final String? region;

  /// 国名 (現地語表記、例「日本」「United States」)。`country` 由来。
  final String? country;

  /// 国コード ISO 3166-1 alpha-2 大文字化 (例「JP」「US」)。
  /// CandidateLocation.country は country code を入れる慣習なのでこちらを使う。
  final String? countryCode;

  const ReverseGeocodeResult({
    this.name,
    this.region,
    this.country,
    this.countryCode,
  });

  /// 何も取れていないかどうか (全フィールド null/空)。
  bool get isEmpty =>
      (name == null || name!.isEmpty) &&
      (region == null || region!.isEmpty) &&
      (country == null || country!.isEmpty) &&
      (countryCode == null || countryCode!.isEmpty);
}

/// 緯度経度から逆ジオコーディングで region / country まで含む詳細を取得する。
///
/// Consultation の Place Picker など、住所表示に詳細が要る用途で利用。
/// 失敗時は null。
Future<ReverseGeocodeResult?> reverseGeocodeDetail(double lat, double lng) async {
  try {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?format=json&lat=$lat&lon=$lng&zoom=16',
    );
    final resp = await http.get(uri, headers: {
      'User-Agent': 'SolaraApp/1.0',
      'Accept-Language': '${AppLocale.instance.resolvedCode},en',
    }).timeout(const Duration(seconds: 8));
    if (resp.statusCode != 200) return null;
    final data = json.decode(resp.body) as Map<String, dynamic>;
    final addr = data['address'] as Map<String, dynamic>? ?? const {};
    final name = (addr['city'] ??
            addr['town'] ??
            addr['village'] ??
            addr['suburb'] ??
            addr['neighbourhood'])
        ?.toString();
    final region =
        (addr['state'] ?? addr['province'] ?? addr['region'])?.toString();
    final country = addr['country']?.toString();
    final cc = (addr['country_code'] as String?)?.toUpperCase();
    return ReverseGeocodeResult(
      name: name,
      region: region,
      country: country,
      countryCode: cc,
    );
  } catch (_) {
    return null;
  }
}
