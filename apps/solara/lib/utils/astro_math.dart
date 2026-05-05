// ══════════════════════════════════════════════════
// Astro 数学ユーティリティ
//
// 重複検出 (audit T1 #4 / #5, 2026-05-05) で、4 ファイルに同一実装の角度
// ユーティリティが散在していたため集約:
//   - angDist:     horo_chart_data.dart (_angDist),
//                  horo_pattern_logic.dart (local angDist x2),
//                  map_astro.dart (_angDist)
//   - normalize360: utils/astro_lines.dart (_norm360),
//                   utils/astro_houses.dart (_norm360),
//                   map_astro.dart (_norm360)
//
// すべて引数を直接 % 360 で正規化する純関数で副作用なし。
// 黄経はもちろん、トランジット/プログレス/アスペクト等あらゆる角度演算で
// 共通利用される基礎関数なので、独立 util ファイルに切り出す。
// ══════════════════════════════════════════════════

/// 角度 d を 0..360 に正規化する。
/// 入力は任意の実数 (負・360超 OK)。
double normalize360(double d) {
  d = d % 360;
  return d < 0 ? d + 360 : d;
}

/// 2 つの角度の最小角距離 (0..180)。
/// 入力 a, b は度。内部で abs % 360 → 180 折り返し。
double angDist(double a, double b) {
  final d = (a - b).abs() % 360;
  return d > 180 ? 360 - d : d;
}
