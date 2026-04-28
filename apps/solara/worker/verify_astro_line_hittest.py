"""
Tier A #3 — Astro*Carto*Graphy モード: 線タップ判定 (画面pixel距離) 検証

実装ファイル:
  apps/solara/lib/utils/astro_lines.dart
    _pointToSegmentPx           : 点-線分pixel距離 (Euclidean)
    _minPixelDistanceToLine     : 1ライン全セグメントの最小pixel距離
    findNearbyLinesScreen       : 閾値以内のラインを pixel距離昇順で返す

検証目的:
  Dart 実装と等価なPython実装で、典型的な3ケースについて
  期待値と一致することを確認する (geometry math のみ、API call なし)。

期待値は手計算 (シンプルなケースを意図的に選ぶ)。
"""
import math
import sys

# Windows コンソール (cp932) で記号が落ちないよう UTF-8 出力強制
try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

THRESHOLD_PX = 20
MAX_JUMP_PX = 4096


def point_to_segment_px(p, a, b):
    ax, ay = a
    bx, by = b
    dx, dy = bx - ax, by - ay
    len_sq = dx * dx + dy * dy
    if len_sq < 1e-9:
        ex, ey = p[0] - ax, p[1] - ay
        return math.sqrt(ex * ex + ey * ey)
    t = ((p[0] - ax) * dx + (p[1] - ay) * dy) / len_sq
    t = max(0.0, min(1.0, t))
    cx, cy = ax + t * dx, ay + t * dy
    ex, ey = p[0] - cx, p[1] - cy
    return math.sqrt(ex * ex + ey * ey)


def min_pixel_distance_to_line(tap_px, segments_px, max_jump_px=MAX_JUMP_PX):
    """segments_px = [[(x,y), ...], ...] (画面座標に投影済み)"""
    min_d = float("inf")
    for seg in segments_px:
        if len(seg) < 2:
            continue
        prev = seg[0]
        for i in range(1, len(seg)):
            nxt = seg[i]
            jx, jy = nxt[0] - prev[0], nxt[1] - prev[1]
            if jx * jx + jy * jy < max_jump_px * max_jump_px:
                d = point_to_segment_px(tap_px, prev, nxt)
                if d < min_d:
                    min_d = d
            prev = nxt
    return min_d


# ── テストケース ──
# 線A: 縦の直線 (画面 x=500, y=100..600 を 100px刻みでサンプル)
LINE_A = [[(500, 100), (500, 200), (500, 300), (500, 400), (500, 500), (500, 600)]]
# 線B: 斜め線 (左上→右下、(100,100)..(700,700))
LINE_B = [[(100, 100), (200, 200), (300, 300), (400, 400), (500, 500), (600, 600), (700, 700)]]
# 線C: 子午線跨ぎ模擬 (中央(400,300)から急に画面端外(5000,300)へジャンプする想定 → スキップ)
LINE_C = [[(380, 300), (400, 300), (5000, 300), (5020, 300)]]


def case(name, tap_px, segments, expected_pass, expected_dist=None, tol=0.01):
    actual = min_pixel_distance_to_line(tap_px, segments)
    passes = actual <= THRESHOLD_PX
    status = "PASS" if passes == expected_pass else "FAIL"
    parts = [f"[{status}] {name}", f"tap={tap_px}", f"min_d={actual:.3f}px",
             f"hit={passes} (expected={expected_pass})"]
    if expected_dist is not None:
        diff = abs(actual - expected_dist)
        parts.append(f"expected_d={expected_dist}px diff={diff:.4f}")
        if diff > tol:
            status = "FAIL"
            parts[0] = f"[{status}] {name}"
    print("  " + " | ".join(parts))
    return passes == expected_pass and (expected_dist is None or abs(actual - expected_dist) <= tol)


def main():
    print("=" * 78)
    print("Tier A #3: Astro Line Hit Test (pixel-space) Verification")
    print(f"Threshold = {THRESHOLD_PX}px")
    print("=" * 78)
    results = []

    print("\n[Case 1] 縦線A (x=500) からの距離:")
    # サンプル点に直接ヒット → 距離=0
    results.append(case("on-sample (500,200)", (500, 200), LINE_A, True, 0.0))
    # 線分の中央 (500, 250) → 距離=0 (線上)
    results.append(case("on-segment-mid (500,250)", (500, 250), LINE_A, True, 0.0))
    # 横に19px外れた → 距離=19、threshold(20)以内
    results.append(case("near (519,250)", (519, 250), LINE_A, True, 19.0))
    # 横に21px外れた → 距離=21、threshold外
    results.append(case("just-out (521,250)", (521, 250), LINE_A, False, 21.0))
    # 線の上端より上 (500, 50) → 端点(500,100)への距離=50
    results.append(case("beyond-endpoint (500,50)", (500, 50), LINE_A, False, 50.0))

    print("\n[Case 2] 斜め線B (45°) からの距離:")
    # 線(y=x)上 (300,300) → 0
    results.append(case("on-line (300,300)", (300, 300), LINE_B, True, 0.0))
    # 線 x-y=0 への垂直距離 = |x-y|/sqrt(2):
    #   (310,290) → 20/√2 ≈ 14.14 < 20px → hit
    results.append(case("perp 14.14 (310,290)", (310, 290), LINE_B, True, 20 / math.sqrt(2)))
    #   (320,280) → 40/√2 ≈ 28.28 > 20px → miss
    results.append(case("perp 28.28 (320,280)", (320, 280), LINE_B, False, 40 / math.sqrt(2)))
    #   (350,250) → 100/√2 ≈ 70.71 → miss
    results.append(case("far 70.71 (350,250)", (350, 250), LINE_B, False, 100 / math.sqrt(2)))

    print("\n[Case 3] 子午線跨ぎ模擬 (LINE_C):")
    # (400, 300) サンプル点 → 0
    results.append(case("on-sample (400,300)", (400, 300), LINE_C, True, 0.0))
    # (4000, 300) は (400,300)→(5000,300) 線分上だが jump > maxJumpPx でスキップされる
    # → 計算対象は (380,300)→(400,300) と (5000,300)→(5020,300) のみ
    # (4000,300) からの最短距離は (5000,300) への 1000px (>= threshold で hit外)
    results.append(case("antimeridian-skip (4000,300)", (4000, 300), LINE_C, False))

    print("\n" + "=" * 78)
    passed = sum(1 for r in results if r)
    total = len(results)
    print(f"結果: {passed}/{total} pass")
    print("=" * 78)
    if passed == total:
        print("✅ 全ケース pass — 点-線分 pixel距離計算と子午線跨ぎ skip が正常動作。")
        return 0
    else:
        print("❌ 失敗ケースあり。Dart実装の数式とPython実装に差分がないか確認。")
        return 1


if __name__ == "__main__":
    sys.exit(main())
