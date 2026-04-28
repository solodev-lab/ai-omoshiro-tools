"""
アストロカートグラフィ線の「基準点不変性」 解析的検証 (Worker依存なし)

主張:
  buildAstroLines(natal, baselineMc=birth_mc, baselineLng=birth_lng) と
  buildAstroLines(natal, baselineMc=home_mc,  baselineLng=home_lng) は
  同じ40本のラインを生成する (出生時刻のGMSTが同じだから)。

理論:
  GMST は時刻のみの関数、地点に依存しない地球規模の値。
  LST(lng) = GMST + lng/15
  MC(lng)  = lst_to_mc(LST(lng))

  ある瞬間の (MC, lng) ペアから GMST を逆算する関数:
    GMST = (recover_lst(MC) - lng) / 15
  これはどの (MC, lng) ペアを入れても同じ GMST を返す
  (= buildAstroLines は基準点に依存しない)。

検証:
  仮想 GMST を 12 時間 (恣意値) として、世界中の 6地点で MC を順方向計算 →
  逆方向に GMST を recover → 全6地点で一致 (浮動小数点誤差以内) を確認。
"""
import math
import sys

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

OBLIQUITY_DEG = 23.4393


def to_rad(d): return d * math.pi / 180
def to_deg(r): return r * 180 / math.pi


def norm360(d):
    d = d % 360
    return d + 360 if d < 0 else d


def lst_to_mc(lst_deg):
    """LST (赤経で表現) → MC (黄経) 変換 (順方向)
    lst_to_mc は recover_lst の逆関数:
      recover_lst(MC) = atan2(sin(MC)*cos(ε), cos(MC))
    →  lst_to_mc(LST) = atan2(sin(LST)/cos(ε), cos(LST))
    """
    lst_r = to_rad(lst_deg)
    cos_eps = math.cos(to_rad(OBLIQUITY_DEG))
    return norm360(to_deg(math.atan2(math.sin(lst_r) / cos_eps, math.cos(lst_r))))


def recover_lst_from_mc(mc_deg):
    """Dart astro_lines.dart `_gmstHoursFromBaseline` 内の LST 復元と同じ"""
    mc_r = to_rad(mc_deg)
    cos_eps = math.cos(to_rad(OBLIQUITY_DEG))
    return norm360(to_deg(math.atan2(math.sin(mc_r) * cos_eps, math.cos(mc_r))))


def recover_gmst_hours(mc_deg, lng_deg):
    """fetch時のMC + lng → GMST (時間単位) を逆算"""
    lst = recover_lst_from_mc(mc_deg)
    return ((lst - lng_deg) / 15) % 24


def main():
    print("=" * 78)
    print("アストロカートグラフィ線の基準点不変性 (解析的検証)")
    print("=" * 78)

    # 仮想 GMST = 出生時刻における グリニッジ恒星時 (時間単位)
    # 任意の値で検証可能 (実際の出生時刻に対応する具体値である必要はない)
    gmst_truth = 12.345  # h

    # 世界各地の経度 (出生地候補)
    sites = {
        "Tokyo": 139.6917,
        "London": -0.1276,
        "New York": -74.0060,
        "Sydney": 151.2093,
        "Cape Town": 18.4241,
        "Reykjavik": -21.9426,
    }

    print(f"\n仮想 GMST(出生時刻) = {gmst_truth} 時 (恣意値)")
    print("\n各地点で MC を順方向に計算 → 逆方向で GMST を復元:\n")
    print(f"{'地点':<12} {'lng':>10} {'順方向MC':>12} {'復元GMST':>14} {'差(秒)':>12}")
    print("─" * 78)

    max_diff_s = 0.0
    for name, lng in sites.items():
        # 順方向: GMST + lng/15 → LST → MC
        lst_deg = (gmst_truth * 15 + lng) % 360
        mc = lst_to_mc(lst_deg)
        # 逆方向: (MC, lng) → GMST
        gmst_recovered = recover_gmst_hours(mc, lng)
        diff_s = abs(gmst_recovered - gmst_truth) * 3600
        # GMST は 24h 周期なので、差が 24h 近ければ実質一致
        if diff_s > 12 * 3600:
            diff_s = 24 * 3600 - diff_s
        max_diff_s = max(max_diff_s, diff_s)
        print(f"{name:<12} {lng:>10.4f} {mc:>12.6f} {gmst_recovered:>14.10f} {diff_s:>12.8f}")

    print("─" * 78)
    print(f"最大 GMST 復元誤差: {max_diff_s:.8f} 秒")

    # 1ミリ秒以内なら浮動小数点誤差として完全に許容
    if max_diff_s < 1e-3:
        print("\n✅ 全地点で同じ GMST を復元 → buildAstroLines は基準点に依存しない")
        print("   = 線は出生時刻のみで決まる (どこの (MC,lng) を渡しても同じ40本)")
        print("\n結論:")
        print("   現状コードは home設定済みなら home の (MC, lng) を使うが、")
        print("   復元される GMST は同じなので、生成される線は birth と完全に同じ。")
        print("   → A案 (mode 入退時の再構築) は不要。birth マーカー追加だけでよい。")
        return 0
    else:
        print("\n❌ GMST 復元に差あり → A案が必要")
        return 1


if __name__ == "__main__":
    sys.exit(main())
