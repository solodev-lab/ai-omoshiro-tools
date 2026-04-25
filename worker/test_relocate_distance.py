"""
岐阜市出生→各地リロケーション時のASC/MC・ハウスシフトを実測。
出生地からの距離・経度差別に「どこから houses が変わるか」を可視化。
"""
import json
import urllib.request

API = "https://solara-api.solodev-lab.com/astro/chart"

# 出生地: 岐阜市 (35.4233°N, 136.7606°E)
BIRTH = {"birthDate": "1990-01-01", "birthTime": "12:00",
         "birthLat": 35.4233, "birthLng": 136.7606, "birthTz": 9, "mode": "natal"}

# 検証地点 (近 → 遠)
DESTS = [
    ("岐阜(出生地)", 35.4233, 136.7606),
    ("名古屋",       35.1815, 136.9066),
    ("大阪",         34.6937, 135.5023),
    ("東京",         35.6762, 139.6503),
    ("札幌",         43.0621, 141.3544),
    ("福岡",         33.5904, 130.4017),
    ("ソウル",       37.5665, 126.9780),
    ("北京",         39.9042, 116.4074),
    ("シンガポール", 1.3521,  103.8198),
    ("ドバイ",       25.2048, 55.2708),
    ("ロンドン",     51.5074, -0.1278),
    ("NY",           40.7128, -74.0060),
    ("シドニー",     -33.8688, 151.2093),
]

def fetch(extra=None):
    body = dict(BIRTH)
    if extra:
        body.update(extra)
    req = urllib.request.Request(API, data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json",
                                          "User-Agent": "Mozilla/5.0 SolaraTest"})
    return json.loads(urllib.request.urlopen(req, timeout=30).read())

def planet_house(lon, houses):
    """惑星黄経からハウス番号(1-12)を返す"""
    lon = lon % 360
    for i in range(12):
        a = houses[i] % 360
        b = houses[(i + 1) % 12] % 360
        in_h = (a <= b and a <= lon < b) or (a > b and (lon >= a or lon < b))
        if in_h:
            return i + 1
    return None

base = fetch()
base_houses = base["houses"]
base_planets = base["natal"]
print(f"{'地点':<14} {'経度差':>7} {'ASC':>7} {'MC':>7} {'house基準ハウス変化数':>20}")
print(f"{'岐阜natal':<14} {0.0:>7.1f}° {base['asc']:>7.2f}° {base['mc']:>7.2f}° {0:>10}惑星")

for name, lat, lng in DESTS[1:]:
    r = fetch({"relocateLat": lat, "relocateLng": lng})
    lng_diff = lng - 136.7606
    # natal惑星の所属ハウスが何個変わるか
    changed = 0
    for k, v in base_planets.items():
        if planet_house(v, base_houses) != planet_house(v, r["houses"]):
            changed += 1
    print(f"{name:<14} {lng_diff:>+7.1f}° {r['asc']:>7.2f}° {r['mc']:>7.2f}° {changed:>10}/10惑星")
