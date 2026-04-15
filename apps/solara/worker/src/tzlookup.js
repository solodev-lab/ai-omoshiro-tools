/**
 * IANA TimeZone lookup from lat/lng.
 * Uses bounding-box heuristic for common regions, falls back to longitude-based offset.
 *
 * 目的: Solara の出生チャート計算で、DST 考慮の正確な UTC 変換を実現する。
 * 精度: 主要国 (JP/US/CN/KR/IN/AU/UK/EU/etc) は IANA TZ名 を返す。
 * 境界や小国: `Etc/GMT±X` 固定オフセット fallback。
 *
 * より高精度が必要な場合は tz-lookup npm パッケージ採用を検討。
 */

// [minLat, maxLat, minLng, maxLng, IANA TZ name]
// 優先度順 (最初にマッチしたものを採用)
const TZ_BOXES = [
  // --- アジア ---
  [24, 46, 123, 146, 'Asia/Tokyo'],         // 日本
  [33, 39, 124, 132, 'Asia/Seoul'],         // 韓国
  [18, 54, 73, 135, 'Asia/Shanghai'],       // 中国 (HKも含む)
  [22, 25, 113, 115, 'Asia/Hong_Kong'],     // 香港 (中国より先にチェック)
  [13, 22, 96, 106, 'Asia/Bangkok'],        // タイ/カンボジア
  [-11, 7, 95, 141, 'Asia/Jakarta'],        // インドネシア西部
  [6, 37, 68, 97, 'Asia/Kolkata'],          // インド
  [24, 38, 60, 78, 'Asia/Karachi'],         // パキスタン/アフガニスタン
  [12, 33, 34, 60, 'Asia/Tehran'],          // イラン
  [41, 43, 28, 45, 'Asia/Istanbul'],        // トルコ
  [14, 22, 120, 126, 'Asia/Manila'],        // フィリピン
  [1, 7, 100, 107, 'Asia/Singapore'],       // シンガポール/マレーシア

  // --- オーストラリア/ニュージーランド ---
  [-44, -10, 140, 155, 'Australia/Sydney'], // 東部
  [-38, -10, 128, 140, 'Australia/Adelaide'],// 中央
  [-36, -13, 112, 128, 'Australia/Perth'],  // 西部
  [-48, -34, 165, 179, 'Pacific/Auckland'], // NZ

  // --- 北米 ---
  [48, 71, -179, -130, 'America/Anchorage'],  // アラスカ
  [18, 23, -161, -154, 'Pacific/Honolulu'],   // ハワイ
  [32, 49, -125, -115, 'America/Los_Angeles'],// 太平洋
  [25, 49, -115, -104, 'America/Denver'],     // 山岳
  [25, 49, -104, -87, 'America/Chicago'],     // 中央
  [25, 49, -87, -67, 'America/New_York'],     // 東部
  [45, 83, -141, -52, 'America/Toronto'],     // カナダ東部
  [14, 32, -118, -86, 'America/Mexico_City'], // メキシコ

  // --- 南米 ---
  [-34, 13, -82, -34, 'America/Sao_Paulo'],   // ブラジル
  [-56, -21, -73, -53, 'America/Argentina/Buenos_Aires'],
  [-56, -17, -76, -67, 'America/Santiago'],   // チリ

  // --- ヨーロッパ ---
  [50, 61, -8, 2, 'Europe/London'],           // UK/アイルランド
  [42, 52, -10, 4, 'Europe/Paris'],           // 西欧
  [47, 55, 5, 15, 'Europe/Berlin'],           // ドイツ周辺
  [36, 48, 6, 19, 'Europe/Rome'],             // 南欧
  [36, 45, -10, 4, 'Europe/Madrid'],          // スペイン/ポルトガル
  [55, 70, 19, 30, 'Europe/Helsinki'],        // 北欧
  [41, 82, 19, 180, 'Europe/Moscow'],         // ロシア (広範囲)
  [34, 42, 19, 30, 'Europe/Athens'],          // ギリシャ

  // --- アフリカ ---
  [-35, 37, -20, 20, 'Africa/Lagos'],         // 西/中央アフリカ
  [-35, 37, 20, 52, 'Africa/Cairo'],          // 東アフリカ
];

/**
 * 緯度経度から IANA TZ名 を推定する。
 * 返り値: { tz: string, source: 'box'|'offset'|'utc' }
 */
export function lookupTimezone(lat, lng) {
  // 有効性チェック
  if (typeof lat !== 'number' || typeof lng !== 'number' ||
      isNaN(lat) || isNaN(lng) ||
      lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    return { tz: 'UTC', source: 'utc' };
  }

  // bounding box チェック (最初にマッチしたもの)
  for (const [minLat, maxLat, minLng, maxLng, tz] of TZ_BOXES) {
    if (lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng) {
      return { tz, source: 'box' };
    }
  }

  // Fallback: 経度ベース (DSTなしの固定オフセット)
  // Etc/GMT の符号は反転 (Etc/GMT-9 = UTC+9)
  const offset = Math.round(lng / 15);
  const sign = offset > 0 ? '-' : '+';
  const tz = `Etc/GMT${sign}${Math.abs(offset)}`;
  return { tz, source: 'offset' };
}
