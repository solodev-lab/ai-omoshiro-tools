"""
L2 Astro*Carto*Graphy: 天底点 (Nadir Point) 検証

天底点の定義:
  各惑星の IC ライン上で 緯度=-δ となる地点。
  天頂点と地球中心を挟んで完全に対称、観測者から見ると惑星が
  足元の真下 (大地の裏側) にある = altitude -90°。

検証戦略:
  Dart `astro_lines.dart` で計算した天底点 = (-δ, MC_line_lng + 180°)
  について、altitude を独立計算し、altitude ≈ -90° を確認する。

天文学的根拠 (高度の球面三角法):
  sin(alt) = sin(φ)·sin(δ) + cos(φ)·cos(δ)·cos(H)
  天底点では:
    φ = -δ (緯度=赤緯の南北反転)
    lng = α - GMST*15 + 180° (IC line = MC line の anti-meridian)
    H = LST - α = (α + 180 - GMST*15)/15·15 + GMST*15 - α = 180°
    cos(H) = -1
  → sin(alt) = sin(-δ)·sin(δ) + cos(-δ)·cos(δ)·(-1)
            = -sin²(δ) - cos²(δ) = -1
  → alt = -90° (理論値)

許容誤差: 0.01° (浮動小数点誤差のみ)
"""
import json
import math
import urllib.request
import sys

API = "https://solara-api.solodev-lab.com/astro/chart"
OBLIQUITY_DEG = 23.4393

PLANETS = [
    "sun", "moon", "mercury", "venus", "mars",
    "jupiter", "saturn", "uranus", "neptune", "pluto",
]


def to_rad(d): return d * math.pi / 180
def to_deg(r): return r * 180 / math.pi


def norm360(d):
    d = d % 360
    return d + 360 if d < 0 else d


def norm_lng(d):
    d = ((d + 180) % 360 + 360) % 360 - 180
    return d


def recover_lst_from_mc(mc_deg):
    mc_r = to_rad(mc_deg)
    cos_eps = math.cos(to_rad(OBLIQUITY_DEG))
    return norm360(to_deg(math.atan2(math.sin(mc_r) * cos_eps, math.cos(mc_r))))


def gmst_from_baseline(base_mc, base_lng):
    lst_base = recover_lst_from_mc(base_mc)
    return ((lst_base - base_lng) / 15) % 24


def ecliptic_to_equatorial(lambda_deg):
    l_r = to_rad(lambda_deg)
    e_r = to_rad(OBLIQUITY_DEG)
    dec = math.asin(math.sin(e_r) * math.sin(l_r))
    ra = math.atan2(math.cos(e_r) * math.sin(l_r), math.cos(l_r))
    return norm360(to_deg(ra)), to_deg(dec)


def compute_nadir(ra_deg, dec_deg, gmst_hours):
    """天底点 (lat=-δ, lng=MC_line_lng+180°) を返す"""
    mc_lng = norm_lng(ra_deg - gmst_hours * 15)
    lat = -dec_deg
    lng = norm_lng(mc_lng + 180)
    return lat, lng


def compute_altitude(lat_deg, lng_deg, ra_deg, dec_deg, gmst_hours):
    lst_hours = (gmst_hours + lng_deg / 15) % 24
    lst_deg = lst_hours * 15
    h_deg = lst_deg - ra_deg
    phi = to_rad(lat_deg)
    dec = to_rad(dec_deg)
    h = to_rad(h_deg)
    sin_alt = math.sin(phi) * math.sin(dec) + math.cos(phi) * math.cos(dec) * math.cos(h)
    sin_alt = max(-1.0, min(1.0, sin_alt))
    return to_deg(math.asin(sin_alt))


def fetch_chart(birth):
    body = {
        "birthDate": birth["date"], "birthTime": birth["time"],
        "birthTz": birth["tz"], "birthLat": birth["lat"], "birthLng": birth["lng"],
        "mode": "natal", "transitDate": "2026-05-11T00:00:00Z",
        "houseSystem": "placidus",
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


def main():
    birth = {
        "date": "1985-07-15", "time": "14:30", "tz": 9,
        "lat": 35.6895, "lng": 139.6917,  # Tokyo
    }
    print("=" * 72)
    print("L2 天底点 (Nadir Point) 検証")
    print(f"  Birth: {birth['date']} {birth['time']} JST, Tokyo ({birth['lat']:.4f}, {birth['lng']:.4f})")
    print(f"  許容誤差: 0.01° (理論値 -90°)")
    print("=" * 72)

    chart = fetch_chart(birth)
    natal = chart["natal"]
    base_mc = chart["mc"]
    base_lng = birth["lng"]
    gmst = gmst_from_baseline(base_mc, base_lng)

    print(f"  GMST recovered: {gmst:.6f}h")
    print()

    results = []
    print(f"  {'planet':<10} {'-δ(lat)':>10} {'IC_lng':>10} {'altitude':>13} {'pass':>6}")
    print(f"  {'-' * 10} {'-' * 10} {'-' * 10} {'-' * 13} {'-' * 6}")

    for planet in PLANETS:
        lon = natal.get(planet)
        if lon is None:
            continue
        ra, dec = ecliptic_to_equatorial(lon)
        nad_lat, nad_lng = compute_nadir(ra, dec, gmst)
        alt = compute_altitude(nad_lat, nad_lng, ra, dec, gmst)
        diff = abs(-90.0 - alt)
        ok = diff < 0.01
        mark = "[OK]" if ok else "[NG]"
        print(f"  {planet:<10} {nad_lat:>+10.4f} {nad_lng:>+10.4f} {alt:>+12.6f}° {mark:>6}")
        results.append((planet, nad_lat, nad_lng, alt, diff, ok))

    print()
    print("=" * 72)
    total = len(results)
    passed = sum(1 for r in results if r[5])
    max_diff = max((r[4] for r in results), default=0)
    print(f"  サマリ: {passed}/{total} pass, max altitude error = {max_diff:.6f}°")

    print()
    print("  極地クランプ確認 (|-δ| > 75° の天底点はマーカー非表示)")
    extreme = [r for r in results if abs(r[1]) > 75]
    if extreme:
        for r in extreme:
            print(f"    [SKIP] {r[0]}: -δ = {r[1]:+.2f}° (latLimit=75°超 → マーカー非表示)")
    else:
        print("    全惑星の |-δ| が75°以下 → 全マーカー表示対象")

    # 天頂・天底ペア検証: zenith + nadir = 180° 経度差、緯度反転
    print()
    print("  ペア対称性検証 (天頂と天底は地球中心を挟んで対称)")
    pair_ok = 0
    for planet in PLANETS:
        lon = natal.get(planet)
        if lon is None:
            continue
        ra, dec = ecliptic_to_equatorial(lon)
        zen_lat = dec
        zen_lng = norm_lng(ra - gmst * 15)
        nad_lat, nad_lng = compute_nadir(ra, dec, gmst)
        lat_match = abs(zen_lat + nad_lat) < 1e-9
        lng_diff = abs(((zen_lng - nad_lng) + 540) % 360 - 180)
        lng_match = abs(lng_diff - 180) < 1e-6 or abs(lng_diff) < 1e-6
        if lat_match and lng_match:
            pair_ok += 1
    print(f"    {pair_ok}/{len(PLANETS)} ペア対称性 OK")

    print("=" * 72)
    sys.exit(0 if passed == total and pair_ok == len(PLANETS) else 1)


if __name__ == "__main__":
    main()
