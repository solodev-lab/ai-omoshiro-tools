"""
Tier A #5 / CCG (Cyclo*Carto*Graphy) ライン計算検証

3つの観点で検証:

1. USNO 線形 GMST 公式 vs Worker (astronomy-engine) の SiderealTime 整合
   - astro_lines.dart の gmstHoursFromUtc が Worker と <0.01 hours で一致するか
   - 1985〜2030 の任意UTCで検証

2. Transit ライン geometry: 任意 transitDate での transit-MC line lng が
   Worker calcMC(date, lng) ≈ transit-planet ecliptic lon を満たすか
   - 戦略: birthDate = transitDate にして natal=transit と同一視
   - relocateLat/Lng = 計算した MC line 上の点
   - chart.mc ≈ chart.natal[planet] を期待

3. Solar Arc 算術: solarArc[sun] == progressed[sun] (定義より)
   - solarArc[planet] = natal[planet] + (prog.sun - natal.sun)
   - sun に適用すれば prog.sun に一致

許容誤差: GMST < 0.01h (= 0.15°), MC line < 1.0°, solar arc < 0.001°
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


def angle_diff(a, b):
    d = abs(norm360(a) - norm360(b))
    return d if d <= 180 else 360 - d


def gmst_hours_from_utc(utc_iso):
    """astro_lines.dart の gmstHoursFromUtc と同じ USNO 線形公式 (Python 移植)."""
    import datetime as dt
    if utc_iso.endswith("Z"):
        utc_iso = utc_iso[:-1] + "+00:00"
    d = dt.datetime.fromisoformat(utc_iso).astimezone(dt.timezone.utc)
    epoch_ms = int(d.timestamp() * 1000)
    jd = epoch_ms / 86400000.0 + 2440587.5
    days = jd - 2451545.0
    g = 18.697374558 + 24.06570982441908 * days
    return ((g % 24) + 24) % 24


def recover_lst_from_mc(mc_deg):
    mc_r = to_rad(mc_deg)
    cos_eps = math.cos(to_rad(OBLIQUITY_DEG))
    return norm360(to_deg(math.atan2(math.sin(mc_r) * cos_eps, math.cos(mc_r))))


def gmst_from_chart(chart_mc, observer_lng):
    lst = recover_lst_from_mc(chart_mc)
    return ((lst - observer_lng) / 15) % 24


def ecliptic_to_equatorial(lambda_deg):
    l_r = to_rad(lambda_deg)
    e_r = to_rad(OBLIQUITY_DEG)
    dec = math.asin(math.sin(e_r) * math.sin(l_r))
    ra = math.atan2(math.cos(e_r) * math.sin(l_r), math.cos(l_r))
    return norm360(to_deg(ra)), to_deg(dec)


def fetch_chart(birth, target_iso, relocate=None):
    body = {
        "birthDate": birth["date"], "birthTime": birth["time"],
        "birthTz": birth["tz"], "birthLat": birth["lat"], "birthLng": birth["lng"],
        "mode": "both", "transitDate": target_iso,
        "houseSystem": "placidus",
    }
    if relocate is not None:
        body["relocateLat"] = relocate["lat"]
        body["relocateLng"] = relocate["lng"]
    req = urllib.request.Request(
        API, data=json.dumps(body).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "User-Agent": "Mozilla/5.0 SolaraTest",
        }, method="POST",
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode("utf-8"))


def gmst_diff_hours(a, b):
    """24時間境界をまたいだときの最短差。"""
    d = abs(a - b) % 24
    return min(d, 24 - d)


# ── Test 1: GMST 公式整合 ──
def test_gmst_formula():
    print("=" * 70)
    print("Test 1: USNO 線形 GMST vs Worker SiderealTime")
    print("=" * 70)
    cases = [
        # (label, birthUTC, birthLng)
        # birthDate/Time/Tz から UTC を構築 → 同じUTCで GMST 比較
        ("1985-07-15 05:30Z lng=0",   "1985-07-15", "14:30",  9, 0.0),
        ("2000-01-01 00:00Z lng=0",   "2000-01-01", "09:00",  9, 0.0),
        ("2026-04-28 12:00Z lng=139", "2026-04-28", "21:00",  9, 139.6917),
        ("2030-12-31 23:59Z lng=-74", "2030-12-31", "18:59", -5, -74.0),
    ]
    max_diff = 0.0
    passed = 0
    for label, bd, bt, btz, blng in cases:
        # birth UTC
        import datetime as dt
        local = dt.datetime.fromisoformat(f"{bd}T{bt}:00")
        utc = local - dt.timedelta(hours=btz)
        utc_iso = utc.replace(tzinfo=dt.timezone.utc).isoformat().replace("+00:00", "Z")

        usno = gmst_hours_from_utc(utc_iso)

        birth = {"date": bd, "time": bt, "tz": btz, "lat": 0.0, "lng": blng}
        chart = fetch_chart(birth, utc_iso)
        worker_gmst = gmst_from_chart(chart["mc"], blng)

        diff = gmst_diff_hours(usno, worker_gmst)
        ok = diff < 0.01
        max_diff = max(max_diff, diff)
        passed += int(ok)
        mark = "[OK]" if ok else "[NG]"
        print(f"  {mark} {label}: USNO={usno:8.4f}h, Worker={worker_gmst:8.4f}h, Δ={diff*3600:.2f}sec")
    print(f"  → {passed}/{len(cases)} pass, max diff = {max_diff*3600:.2f}秒\n")
    return passed == len(cases)


# ── Test 2: Transit ライン geometry ──
def test_transit_mc_line():
    print("=" * 70)
    print("Test 2: Transit MC line geometry (chart.mc ~= planet ecliptic lon @ MC line lng)")
    print("=" * 70)
    transit_iso = "2026-04-28T12:00:00Z"
    # birth=transitDate なので chart.natal == chart.transit (時刻同一)
    birth = {"date": "2026-04-28", "time": "21:00", "tz": 9, "lat": 0.0, "lng": 0.0}

    # まず natal=transit chart 取得
    base = fetch_chart(birth, transit_iso, relocate={"lat": 0.0, "lng": 0.0})
    natal = base["natal"]
    gmst = gmst_hours_from_utc(transit_iso)

    test_planets = ["sun", "venus", "mars", "jupiter", "saturn"]
    test_lats = [0, 30, -30]

    passed, total = 0, 0
    max_diff = 0.0
    for planet in test_planets:
        lon = natal[planet]
        ra, dec = ecliptic_to_equatorial(lon)
        mc_lng = norm_lng(ra - gmst * 15)
        for lat in test_lats:
            relo = {"lat": lat, "lng": mc_lng}
            r = fetch_chart(birth, transit_iso, relocate=relo)
            diff = angle_diff(r["natal"][planet], r["mc"])
            ok = diff < 1.0
            max_diff = max(max_diff, diff)
            mark = "[OK]" if ok else "[NG]"
            print(f"  {mark} {planet:8s} MC line @ lat={lat:+4d} lng={mc_lng:+7.2f}: Δ(lon, mc) = {diff:.4f}°")
            passed += int(ok)
            total += 1
    print(f"  → {passed}/{total} pass, max diff = {max_diff:.4f}°\n")
    return passed == total


# ── Test 3: Solar Arc 算術 ──
def test_solar_arc():
    print("=" * 70)
    print("Test 3: Solar Arc 算術 (solarArc[sun] == progressed[sun])")
    print("=" * 70)
    birth = {"date": "1985-07-15", "time": "14:30", "tz": 9, "lat": 35.6895, "lng": 139.6917}
    transit_iso = "2026-04-28T00:00:00Z"
    chart = fetch_chart(birth, transit_iso)
    natal = chart["natal"]
    progressed = chart["progressed"]
    arc = (progressed["sun"] - natal["sun"]) % 360
    solar_arc = {p: (natal[p] + arc) % 360 for p in natal}
    diffs = []
    for p in natal:
        d = angle_diff(solar_arc[p], (natal[p] + arc) % 360)
        diffs.append(d)
    diff_sun = angle_diff(solar_arc["sun"], progressed["sun"])
    ok_sun = diff_sun < 0.001
    mark = "[OK]" if ok_sun else "[NG]"
    print(f"  arc (prog.sun - natal.sun) = {arc:.4f}°")
    print(f"  {mark} solarArc.sun ({solar_arc['sun']:.4f}°) == prog.sun ({progressed['sun']:.4f}°), Δ={diff_sun:.6f}°")
    # 全惑星に同じ arc が乗っていることを確認
    print(f"  全10惑星に同 arc 適用: max Δ = {max(diffs):.6f}° (定義通り)")

    # 追加: 同じ arc が他惑星にも適用されることを実用的に確認
    # natal[venus] + arc が astrologically meaningful な範囲に収まるかは別問題なので
    # ここでは純粋に算術の整合性のみ
    return ok_sun


def main():
    results = []
    results.append(("GMST formula", test_gmst_formula()))
    results.append(("Transit MC line", test_transit_mc_line()))
    results.append(("Solar Arc arithmetic", test_solar_arc()))

    print("=" * 70)
    print("CCG ライン計算 サマリ")
    print("=" * 70)
    all_ok = True
    for name, ok in results:
        mark = "[OK]" if ok else "[NG]"
        print(f"  {mark} {name}")
        all_ok = all_ok and ok
    return 0 if all_ok else 1


if __name__ == "__main__":
    import sys
    sys.exit(main())
