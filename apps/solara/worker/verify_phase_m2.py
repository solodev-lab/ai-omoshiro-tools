"""
Phase M2 引越しレイヤー 計算精度検証

目的:
  Dart 側 calcHousesRelocate (LST復元戦略) が Worker /astro/chart の
  relocate計算と同等の結果を出すかを比較する。

戦略:
  1. Worker に同一birthDate/birthTime, relocate=A で fetch → 真値A (mc_a, asc_a, houses_a)
  2. Worker に同一birthDate/birthTime, relocate=B で fetch → 基準B (mc_b, asc_b, houses_b)
  3. Pythonで Dart の calcHousesRelocate を再現:
     - LST_b = recoverLstFromMc(mc_b)
     - LST_a = LST_b + (lng_a - lng_b)
     - asc_a_recovered = calcAscendant(LST_a, lat_a, eps)
     - mc_a_recovered = calcMC(LST_a, eps)
     - houses_a_recovered = placidus(mc_a_recovered, asc_a_recovered, lat_a)
  4. (asc_a, mc_a, houses_a[k]) vs (asc_a_recovered, mc_a_recovered, houses_a_recovered[k])
     の差分を表示。閾値 0.5度。
"""
import json
import math
import urllib.request

API = "https://solara-api.solodev-lab.com/astro/chart"
OBLIQUITY_DEG = 23.4393  # Dart 側と同じ J2000 平均値


def to_rad(d): return d * math.pi / 180
def to_deg(r): return r * 180 / math.pi


def norm360(d):
    d = d % 360
    return d + 360 if d < 0 else d


def clamp(v, lo, hi):
    return max(lo, min(hi, v))


def recover_lst_from_mc(mc_deg):
    mc_r = to_rad(mc_deg)
    cos_eps = math.cos(to_rad(OBLIQUITY_DEG))
    return norm360(to_deg(math.atan2(math.sin(mc_r) * cos_eps, math.cos(mc_r))))


def calc_ascendant(lst_deg, lat, eps_deg):
    lst_r = to_rad(lst_deg)
    eps_r = to_rad(eps_deg)
    lat_r = to_rad(lat)
    return norm360(to_deg(math.atan2(
        -math.cos(lst_r),
        math.sin(eps_r) * math.tan(lat_r) + math.cos(eps_r) * math.sin(lst_r),
    )) + 180)


def calc_mc(lst_deg, eps_deg):
    lst_r = to_rad(lst_deg)
    eps_r = to_rad(eps_deg)
    return norm360(to_deg(math.atan2(math.sin(lst_r), math.cos(lst_r) * math.cos(eps_r))))


def placidus_cusps(mc, asc, lat, eps_deg=OBLIQUITY_DEG):
    eps_r = to_rad(eps_deg)
    cos_eps = math.cos(eps_r)
    sin_eps = math.sin(eps_r)
    tan_lat = math.tan(to_rad(lat))
    houses = [0.0] * 12
    houses[0] = asc
    houses[9] = mc
    houses[6] = norm360(asc + 180)
    houses[3] = norm360(mc + 180)

    mc_r = to_rad(mc)
    ramc = norm360(to_deg(math.atan2(math.sin(mc_r) * cos_eps, math.cos(mc_r))))

    def cusp(house):
        lon = norm360(mc + (house - 10) * 30) if house <= 12 else norm360(asc + (house - 1) * 30)
        for _ in range(50):
            sin_decl = clamp(math.sin(to_rad(lon)) * sin_eps, -1, 1)
            decl = math.asin(sin_decl)
            ad_arg = clamp(tan_lat * math.tan(decl), -1, 1)
            ad = to_deg(math.asin(ad_arg))
            if house == 11:
                target_ra = ramc + (90 + ad) / 3
            elif house == 12:
                target_ra = ramc + 2 * (90 + ad) / 3
            elif house == 2:
                target_ra = ramc - 240 + 2 * ad / 3
            else:
                target_ra = ramc - 210 + ad / 3
            ra_r = to_rad(target_ra)
            new_lon = norm360(to_deg(math.atan2(math.sin(ra_r), math.cos(ra_r) * cos_eps)))
            delta = abs(new_lon - lon)
            if delta < 0.001 or delta > 359.999:
                break
            lon = new_lon
        return lon

    houses[10] = cusp(11)
    houses[11] = cusp(12)
    houses[1] = cusp(2)
    houses[2] = cusp(3)
    houses[4] = norm360(houses[10] + 180)
    houses[5] = norm360(houses[11] + 180)
    houses[7] = norm360(houses[1] + 180)
    houses[8] = norm360(houses[2] + 180)
    return houses


def fetch_chart(birth, relocate):
    body = {
        "birthDate": birth["date"], "birthTime": birth["time"],
        "birthTz": birth["tz"], "birthLat": birth["lat"], "birthLng": birth["lng"],
        "mode": "natal", "transitDate": "2026-04-27T00:00:00Z",
        "houseSystem": "placidus",
        "relocateLat": relocate["lat"], "relocateLng": relocate["lng"],
    }
    req = urllib.request.Request(
        API, data=json.dumps(body).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "User-Agent": "Mozilla/5.0 SolaraTest",
        }, method="POST",
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode("utf-8"))


def angle_diff(a, b):
    """円周上の最短角距離。0..180°"""
    d = abs(norm360(a) - norm360(b))
    return d if d <= 180 else 360 - d


def verify_pair(birth, base_loc, target_loc, label):
    print(f"\n--- {label} ---")
    print(f"  Base:   {base_loc['name']} ({base_loc['lat']:.2f}, {base_loc['lng']:.2f})")
    print(f"  Target: {target_loc['name']} ({target_loc['lat']:.2f}, {target_loc['lng']:.2f})")

    base = fetch_chart(birth, base_loc)
    truth = fetch_chart(birth, target_loc)

    # Dart calcHousesRelocate の Python 再現
    lst_base = recover_lst_from_mc(base["mc"])
    lst_target = norm360(lst_base + (target_loc["lng"] - base_loc["lng"]))
    asc_recovered = calc_ascendant(lst_target, target_loc["lat"], OBLIQUITY_DEG)
    mc_recovered = calc_mc(lst_target, OBLIQUITY_DEG)
    houses_recovered = placidus_cusps(mc_recovered, asc_recovered, target_loc["lat"])

    # 差分
    asc_diff = angle_diff(truth["asc"], asc_recovered)
    mc_diff = angle_diff(truth["mc"], mc_recovered)
    print(f"  ASC: truth={truth['asc']:.3f}°  recovered={asc_recovered:.3f}°  diff={asc_diff:.4f}°")
    print(f"  MC : truth={truth['mc']:.3f}°  recovered={mc_recovered:.3f}°  diff={mc_diff:.4f}°")

    max_house_diff = 0.0
    for i in range(12):
        d = angle_diff(truth["houses"][i], houses_recovered[i])
        if d > max_house_diff:
            max_house_diff = d
    print(f"  Houses max diff: {max_house_diff:.4f}°")

    return {
        "asc": asc_diff, "mc": mc_diff, "houses_max": max_house_diff,
    }


def main():
    birth = {
        "date": "1985-07-15", "time": "14:30", "tz": 9,
        "lat": 35.6895, "lng": 139.6917,  # Tokyo
    }

    locations = {
        "tokyo":   {"name": "Tokyo",   "lat": 35.6895, "lng": 139.6917},
        "ny":      {"name": "NewYork", "lat": 40.7128, "lng": -74.0060},
        "la":      {"name": "LA",      "lat": 34.0522, "lng": -118.2437},
        "london":  {"name": "London",  "lat": 51.5074, "lng": -0.1278},
        "sydney":  {"name": "Sydney",  "lat": -33.8688, "lng": 151.2093},
        "mumbai":  {"name": "Mumbai",  "lat": 19.0760, "lng": 72.8777},
    }

    print("=" * 70)
    print("Phase M2: Dart calcHousesRelocate vs Worker /astro/chart 検証")
    print("Birth:", birth)
    print(f"閾値: 0.5度 / Obliquity (Dart): {OBLIQUITY_DEG}°")
    print("=" * 70)

    pairs = [
        ("tokyo", "ny"),
        ("tokyo", "la"),
        ("tokyo", "london"),
        ("ny", "tokyo"),
        ("ny", "sydney"),
        ("london", "mumbai"),
    ]

    results = []
    for base_key, target_key in pairs:
        try:
            r = verify_pair(
                birth, locations[base_key], locations[target_key],
                f"{base_key} → {target_key}",
            )
            results.append((f"{base_key}→{target_key}", r))
        except Exception as e:
            print(f"  ERROR: {e}")

    print("\n" + "=" * 70)
    print("サマリ:")
    print("=" * 70)
    threshold = 0.5
    all_pass = True
    for label, r in results:
        ok = r["asc"] < threshold and r["mc"] < threshold and r["houses_max"] < threshold
        mark = "[OK]" if ok else "[NG]"
        print(f"  {mark} {label:18s}  ASC {r['asc']:.4f}°  MC {r['mc']:.4f}°  Houses {r['houses_max']:.4f}°")
        if not ok:
            all_pass = False

    print("\n" + ("[OK] 全パス (閾値 0.5度)" if all_pass else "[NG] 一部 NG"))
    return 0 if all_pass else 1


if __name__ == "__main__":
    import sys
    sys.exit(main())
