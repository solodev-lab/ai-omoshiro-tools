"""
NY出生→米国内各地リロケーションのASC/MC・ハウスシフト実測。
US市場で「国内移住」がリロケーション機能として意味があるか検証。
"""
import json
import urllib.request

API = "https://solara-api.solodev-lab.com/astro/chart"

# 出生地: ニューヨーク (40.7128°N, -74.0060°W) Eastern timezone -5
BIRTH = {"birthDate": "1990-01-01", "birthTime": "12:00",
         "birthLat": 40.7128, "birthLng": -74.0060, "birthTz": -5, "mode": "natal"}

# 米国内の主要都市 (経度の小さい順 → 大きい順 = 東岸 → 西岸 → ハワイ)
DESTS = [
    ("NY(出生地)",     40.7128, -74.0060),
    ("Boston",         42.3601, -71.0589),
    ("Washington DC",  38.9072, -77.0369),
    ("Miami",          25.7617, -80.1918),
    ("Atlanta",        33.7490, -84.3880),
    ("Chicago",        41.8781, -87.6298),
    ("Houston",        29.7604, -95.3698),
    ("Dallas",         32.7767, -96.7970),
    ("Denver",         39.7392, -104.9903),
    ("Salt Lake City", 40.7608, -111.8910),
    ("Phoenix",        33.4484, -112.0740),
    ("Las Vegas",      36.1699, -115.1398),
    ("Seattle",        47.6062, -122.3321),
    ("San Francisco",  37.7749, -122.4194),
    ("Los Angeles",    34.0522, -118.2437),
    ("Honolulu",       21.3099, -157.8581),
    ("Anchorage",      61.2181, -149.9003),
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
print(f"{'地点':<18} {'経度差':>7} {'ASC':>9} {'MC':>9} {'ハウス変化':>15}")
print(f"{'NY natal':<18} {0.0:>7.1f}° {base['asc']:>8.2f}° {base['mc']:>8.2f}° {0:>10}惑星")

for name, lat, lng in DESTS[1:]:
    r = fetch({"relocateLat": lat, "relocateLng": lng})
    lng_diff = lng - (-74.0060)
    changed = 0
    for k, v in base_planets.items():
        if planet_house(v, base_houses) != planet_house(v, r["houses"]):
            changed += 1
    print(f"{name:<18} {lng_diff:>+7.1f}° {r['asc']:>8.2f}° {r['mc']:>8.2f}° {changed:>10}/10惑星")
