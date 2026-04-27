"""
Phase M2 論点3: アスペクト線計算 vs Worker 整合性検証

戦略:
  Dart の buildAstroLines で生成した「金星 ASC ライン」上の任意の点を取り、
  その点で relocate=その点 で fetchChart → 金星の黄経 ≈ ASC、を確認。
  同様に MC line, IC line, DSC line の整合性も確認。

許容誤差: 1.0度 (緯度ステップ2度 + obliquity定数化の合算誤差を許容)
"""
import json
import math
import urllib.request

API = "https://solara-api.solodev-lab.com/astro/chart"
OBLIQUITY_DEG = 23.4393


def to_rad(d): return d * math.pi / 180
def to_deg(r): return r * 180 / math.pi


def norm360(d):
    d = d % 360
    return d + 360 if d < 0 else d


def norm_lng(d):
    d = ((d + 180) % 360 + 360) % 360 - 180
    return d


def clamp(v, lo, hi):
    return max(lo, min(hi, v))


def angle_diff(a, b):
    d = abs(norm360(a) - norm360(b))
    return d if d <= 180 else 360 - d


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


def mc_line_lng(ra_deg, gmst_hours, anti=False):
    lng = ra_deg - gmst_hours * 15
    if anti:
        lng += 180
    return norm_lng(lng)


def horizon_lng(ra_deg, dec_deg, gmst_hours, lat_deg, ascending=True):
    """その緯度で惑星が地平線上にあるときの観測者経度。失敗時は None。"""
    tan_dec = math.tan(to_rad(dec_deg))
    tan_lat = math.tan(to_rad(lat_deg))
    cos_h = -tan_dec * tan_lat
    if cos_h < -1 or cos_h > 1:
        return None
    h = math.acos(clamp(cos_h, -1, 1))
    h_signed = -h if ascending else h
    lst = norm360(to_deg(to_rad(ra_deg) + h_signed) * 1)  # 度に戻す
    # Wait: lst の計算は (ra_deg [deg] + h_signed [rad → deg]) なので変換注意
    lst = norm360(ra_deg + to_deg(h_signed))
    return norm_lng(lst - gmst_hours * 15)


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


def main():
    birth = {
        "date": "1985-07-15", "time": "14:30", "tz": 9,
        "lat": 35.6895, "lng": 139.6917,  # Tokyo
    }
    base_loc = {"name": "Tokyo", "lat": 35.6895, "lng": 139.6917}

    # Tokyo で fetch して natal/mc 取得
    base = fetch_chart(birth, base_loc)
    natal = base["natal"]
    base_mc = base["mc"]
    base_lng = base_loc["lng"]
    gmst = gmst_from_baseline(base_mc, base_lng)

    print("=" * 70)
    print("Phase M2 アスペクト線 検証 (Tokyo natal)")
    print(f"GMST recovered: {gmst:.6f}h")
    print(f"閾値: 1.0度 (緯度ステップ2度+obliquity定数化の合算誤差を許容)")
    print("=" * 70)

    # 5惑星 × 4アングル × 数点でサンプル検証
    test_planets = ["sun", "venus", "mars", "jupiter", "saturn"]
    test_lats = [0, 25, 45, -25]  # 赤道 / 中緯度南北 / 高緯度

    results = []
    for planet in test_planets:
        lon = natal[planet]
        ra, dec = ecliptic_to_equatorial(lon)

        # MC line: 金星 RA に対応する縦線
        mc_lng = mc_line_lng(ra, gmst, anti=False)
        ic_lng = mc_line_lng(ra, gmst, anti=True)

        for lat in test_lats:
            # MC line 上の点で fetchChart → 惑星黄経が MC と一致するか
            relo = {"lat": lat, "lng": mc_lng}
            try:
                r = fetch_chart(birth, relo)
                planet_lon = r["natal"][planet]
                diff = angle_diff(planet_lon, r["mc"])
                ok = diff < 1.0
                mark = "[OK]" if ok else "[NG]"
                print(f"  {mark} {planet:8s} MC@lat={lat:+4d} lng={mc_lng:+7.2f} : Δ(lon, mc) = {diff:.4f}°")
                results.append(("MC", planet, lat, diff, ok))
            except Exception as e:
                print(f"  ERR {planet} MC@lat={lat}: {e}")

            # IC line 検証
            relo = {"lat": lat, "lng": ic_lng}
            try:
                r = fetch_chart(birth, relo)
                planet_lon = r["natal"][planet]
                diff = angle_diff(planet_lon, r["ic"])
                ok = diff < 1.0
                mark = "[OK]" if ok else "[NG]"
                print(f"  {mark} {planet:8s} IC@lat={lat:+4d} lng={ic_lng:+7.2f} : Δ(lon, ic) = {diff:.4f}°")
                results.append(("IC", planet, lat, diff, ok))
            except Exception as e:
                print(f"  ERR {planet} IC@lat={lat}: {e}")

            # ASC line 検証 (周極判定 + 計算)
            asc_lng = horizon_lng(ra, dec, gmst, lat, ascending=True)
            if asc_lng is not None:
                relo = {"lat": lat, "lng": asc_lng}
                try:
                    r = fetch_chart(birth, relo)
                    planet_lon = r["natal"][planet]
                    diff = angle_diff(planet_lon, r["asc"])
                    ok = diff < 1.0
                    mark = "[OK]" if ok else "[NG]"
                    print(f"  {mark} {planet:8s} ASC@lat={lat:+4d} lng={asc_lng:+7.2f} : Δ(lon, asc) = {diff:.4f}°")
                    results.append(("ASC", planet, lat, diff, ok))
                except Exception as e:
                    print(f"  ERR {planet} ASC@lat={lat}: {e}")
            else:
                print(f"  --   {planet:8s} ASC@lat={lat:+4d} : 周極 (解なし)")

            # DSC line 検証
            dsc_lng = horizon_lng(ra, dec, gmst, lat, ascending=False)
            if dsc_lng is not None:
                relo = {"lat": lat, "lng": dsc_lng}
                try:
                    r = fetch_chart(birth, relo)
                    planet_lon = r["natal"][planet]
                    diff = angle_diff(planet_lon, r["dsc"])
                    ok = diff < 1.0
                    mark = "[OK]" if ok else "[NG]"
                    print(f"  {mark} {planet:8s} DSC@lat={lat:+4d} lng={dsc_lng:+7.2f} : Δ(lon, dsc) = {diff:.4f}°")
                    results.append(("DSC", planet, lat, diff, ok))
                except Exception as e:
                    print(f"  ERR {planet} DSC@lat={lat}: {e}")
            else:
                print(f"  --   {planet:8s} DSC@lat={lat:+4d} : 周極 (解なし)")

    print("\n" + "=" * 70)
    total = len(results)
    passed = sum(1 for r in results if r[4])
    max_diff = max((r[3] for r in results), default=0)
    print(f"サマリ: {passed}/{total} pass, max diff = {max_diff:.4f}°")
    return 0 if passed == total else 1


if __name__ == "__main__":
    import sys
    sys.exit(main())
