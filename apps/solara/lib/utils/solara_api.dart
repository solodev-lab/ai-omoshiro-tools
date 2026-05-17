// Solara CF Worker API - 軽量なユーティリティ呼び出し
// (チャート/イベント系は別ファイルに既存。ここは補助エンドポイント + URL 集約)
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Solara Cloudflare Worker のベース URL（**単一情報源**）。
///
/// 🔴 **重要**: Solara 内で Worker を参照する全ての Dart ファイルは、
/// URL をハードコードせず、本ファイルの定数を import すること。
///
/// 過去のバグ: 複数箇所に URL を書いた結果、一部が古い `solodev-lab.workers.dev`
/// （存在しないサブドメイン）のままになり、sectory 計算で無言で fallback していた。
///
/// wrangler.toml の設定:
///   routes = [{ pattern = "solara-api.solodev-lab.com", custom_domain = true }]
///   fallback (自動発行): https://solara-api.kojifo369.workers.dev
const String solaraWorkerBase = 'https://solara-api.solodev-lab.com';

/// 🔴 ルート物理分離 (project_solara_security_principles.md §2):
///   `/public/*`    認証不要 - 純数学計算、マップタイル、検索
///   `/auth/*`      Sign in 連携、attestation 登録 (Phase 1 残で本実装)
///   `/protected/*` 重防御 - Gemini 呼出全部。将来 attestation + entitlement
///                  + per-user rate limit (Phase 1 残)。
///
/// 本ファイルに **全エンドポイント URL を集約**。新ルート追加時はここに 1 行追加し
/// 各呼出箇所は文字列リテラルではなく定数 import 経由で参照する。

// /public/* — 認証不要
const String solaraTzUrl = '$solaraWorkerBase/public/tz';
const String solaraChartUrl = '$solaraWorkerBase/public/astro/chart';
const String solaraEventsUrl = '$solaraWorkerBase/public/astro/events';
const String solaraForecastUrl = '$solaraWorkerBase/public/astro/forecast';
const String solaraDailyTransitsUrl =
    '$solaraWorkerBase/public/astro/daily-transits';
const String solaraSearchUrl = '$solaraWorkerBase/public/search';

/// OSM タイル URL テンプレート (`{z}/{x}/{y}` を flutter_map が埋める)。
/// 末尾に `/<source>/{z}/{x}/{y}.png` をユーザーが付ける形で使う。
/// 例: '$solaraOsmTileBase/hot/{z}/{x}/{y}.png'
const String solaraOsmTileBase = '$solaraWorkerBase/public/tiles/osm';

// /auth/* — Sign in + attestation (Phase 1 残で本実装、現状 stub)
const String solaraWhoamiUrl = '$solaraWorkerBase/auth/whoami';
const String solaraAttestUrl = '$solaraWorkerBase/auth/attest';

// /protected/* — Gemini 系、attestation + entitlement 必須 (Phase 1 残で middleware 配線)
const String solaraFortuneUrl = '$solaraWorkerBase/protected/fortune';
const String solaraTarotUrl = '$solaraWorkerBase/protected/tarot';
const String solaraRelocationUrl = '$solaraWorkerBase/protected/relocation';
const String solaraConsultationUrl =
    '$solaraWorkerBase/protected/astro/consultation';

/// 緯度経度から IANA TZ名 (DST対応の基準) を取得。
/// 例: (35.68, 139.76) → 'Asia/Tokyo'
/// 失敗時は null を返す (呼び出し側で birthTz 整数fallback想定)。
Future<String?> fetchTimezoneName(double lat, double lng) async {
  try {
    final uri = Uri.parse('$solaraTzUrl?lat=$lat&lng=$lng');
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
