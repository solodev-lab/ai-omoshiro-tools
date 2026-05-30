#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""seed_d1_subdivisions.py — Stella 相談 候補プールに「区/地区」を追加 (D1)

cities1000 (seed_d1_cities.py で投入済の 16.9万件) に、世界の行政区/地区を追記する。
データ源: GeoNames allCountries (全 feature)。feature_code = A.ADM3 + P.PPLX を抽出。
  - A.ADM3 : 行政区 (日本の「区」=中区/天白区、ロンドンのボロ 等)
  - P.PPLX : 地区/区画 (上野/築地/豊洲、Le Marais/Montparnasse、Astoria 等)

設計 (オーナー方針):
  - 近所の日常活用が主目的。区/地区は「近所候補の粒度」を上げる。
  - 人口は GeoNames で 0 → 名目 2000 を一律付与。広域フロア (自国5万/地域10万/世界30万)
    未満なので far-travel は汚さず、近傍 bounding-box (フロア無し) では候補に乗る。
  - 名前は seed_d1_cities と同じ pick_name (JP=CJK最短/非JP=かな最短/無→ローマ字)。
  - 完全重複 (同名・座標近接) は 1 件にマージ。cities1000 と id/同名同座標が被るものは除外。

出力:
  _geonames_cache/subdivisions_data.sql  — INSERT OR IGNORE (gitignore)。wrangler --file 用。
既存スキーマ (0001_cities.sql) はそのまま。テーブル構造は変えない (population に名目値を入れるだけ)。

実行:
  python apps/solara/tools/seed_d1_subdivisions.py
  python apps/solara/tools/seed_d1_subdivisions.py --limit 5000   # 動作確認
"""
from __future__ import annotations

import sys
import zipfile
from pathlib import Path

# seed_d1_cities の helper を再利用 (name/region ロジックを完全踏襲)
from seed_d1_cities import (
    CACHE, ADMIN1_URL, ADMIN1_PATH, CITIES_URL, ZIP_PATH, TXT_PATH,
    download, extract_cities, parse_admin1_jp, pick_name, has_cjk, sql_str,
)

try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass

ALL_URL = "https://download.geonames.org/export/dump/allCountries.zip"
ALL_ZIP = CACHE / "allCountries.zip"
OUT_SQL = CACHE / "subdivisions_data.sql"

WANT_CODES = {"A.ADM3", "P.PPLX"}
NOMINAL_POP = 2000          # 名目人口 (広域フロア5万未満 / 近傍では候補に乗る)
INSERT_BATCH = 100
COORD_Q = 2                 # 重複判定の座標丸め桁 (2 ≒ 1km)


def round_key(name: str, lat: float, lng: float):
    return (name, round(lat, COORD_Q), round(lng, COORD_Q))


def norm_ascii(s: str) -> str:
    """ローマ字を正規化 (小文字・英数のみ)。'Tempaku-ku'/'Tempaku Ku' → 'tempakuku'。"""
    return "".join(ch for ch in s.lower() if ch.isalnum())


def ascii_key(ascii_name: str, lat: float, lng: float):
    # round1 ≒ 11km。同一区の ADM3/PPLX (座標が 1-2km ずれる) を束ねる。
    return (norm_ascii(ascii_name), round(lat, 1), round(lng, 1))


def load_existing():
    """cities1000 の (id 集合) と (表示名+座標 集合) を作り、重複除外に使う。"""
    ids = set()
    seen = set()
    admin1_jp = parse_admin1_jp()
    with open(TXT_PATH, encoding="utf-8") as f:
        for line in f:
            c = line.rstrip("\n").split("\t")
            if len(c) < 15:
                continue
            try:
                gid = int(c[0]); lat = float(c[4]); lng = float(c[5])
            except ValueError:
                continue
            ids.add(gid)
            name = pick_name(c[1], c[3], c[8])
            seen.add(round_key(name, lat, lng))
    return ids, seen, admin1_jp


def main():
    limit = None
    if "--limit" in sys.argv:
        limit = int(sys.argv[sys.argv.index("--limit") + 1])

    download(ADMIN1_URL, ADMIN1_PATH, 10_000)
    download(CITIES_URL, ZIP_PATH, 1_000_000)
    extract_cities()
    if not ALL_ZIP.exists():
        download(ALL_URL, ALL_ZIP, 100_000_000)

    print("[load] cities1000 (重複除外用) ...", flush=True)
    existing_ids, seen, admin1_jp = load_existing()
    print(f"[load] existing cities: ids={len(existing_ids)} keys={len(seen)}")

    # Phase 1: ADM3+PPLX を収集 (cities1000 に id がある PPLX は除外)。
    cand = []
    dup = 0
    with zipfile.ZipFile(ALL_ZIP) as z:
        name_in = [n for n in z.namelist() if n.endswith(".txt")][0]
        with z.open(name_in) as fh:
            for raw in fh:
                c = raw.decode("utf-8", "replace").rstrip("\n").split("\t")
                if len(c) < 15:
                    continue
                code = f"{c[6]}.{c[7]}"
                if code not in WANT_CODES:
                    continue
                try:
                    gid = int(c[0]); lat = float(c[4]); lng = float(c[5])
                except ValueError:
                    continue
                if gid in existing_ids:        # 既に cities1000 にある (PPLX 人口>=1000)
                    dup += 1
                    continue
                country = c[8]
                name = pick_name(c[1], c[3], country)
                # 日本の PPLX (地区) はローマ字のみの obscure な町を除外し、日本語名が
                # 付く地区 (上野/築地/豊洲 等) だけ残す。ADM3 (区) は常に残す。
                if country == "JP" and code == "P.PPLX" and not has_cjk(name):
                    dup += 1
                    continue
                region = admin1_jp.get(c[10]) if country == "JP" else None
                cand.append((code, gid, name, c[2], lat, lng, country, region))

    # Phase 2: ADM3 を先に処理 (CJK 名が勝つ) → 表示名/ローマ字の二軸で重複除去。
    cand.sort(key=lambda r: 0 if r[0] == "A.ADM3" else 1)
    seen_disp = seen                 # cities1000 の (表示名,座標) を継承
    seen_asc = set()
    rows = []
    n_adm3 = n_pplx = 0
    for (code, gid, name, asc, lat, lng, country, region) in cand:
        dk = round_key(name, lat, lng)
        ak = ascii_key(asc, lat, lng)
        if dk in seen_disp or ak in seen_asc:   # 完全重複 (同名 or 同ローマ字・近接) はマージ
            dup += 1
            continue
        seen_disp.add(dk)
        seen_asc.add(ak)
        rows.append((gid, name, asc, lat, lng, country, region, NOMINAL_POP))
        if code == "A.ADM3":
            n_adm3 += 1
        else:
            n_pplx += 1
        if limit and len(rows) >= limit:
            break

    print(f"[parse] subdivisions={len(rows)} (ADM3={n_adm3} PPLX={n_pplx}) merged/skip={dup}")

    cols_clause = "(id,name,ascii,lat,lng,country,region,population)"
    n_inserts = 0
    with open(OUT_SQL, "w", encoding="utf-8") as out:
        out.write("-- GENERATED by seed_d1_subdivisions.py — 区/地区追加 (INSERT OR IGNORE)\n")
        out.write(f"-- rows: {len(rows)} (ADM3={n_adm3} PPLX={n_pplx})\n")
        for i in range(0, len(rows), INSERT_BATCH):
            chunk = rows[i:i + INSERT_BATCH]
            values = [
                "({},{},{},{:.5f},{:.5f},{},{},{})".format(
                    gid, sql_str(nm), sql_str(asc), lat, lng,
                    sql_str(cty), sql_str(reg), pop)
                for (gid, nm, asc, lat, lng, cty, reg, pop) in chunk
            ]
            out.write(f"INSERT OR IGNORE INTO cities {cols_clause} VALUES\n")
            out.write(",\n".join(values))
            out.write(";\n")
            n_inserts += 1
    size_mb = OUT_SQL.stat().st_size / 1_000_000
    print(f"[write] {OUT_SQL} ({n_inserts} INSERT 文, {size_mb:.1f} MB)")

    jp = sum(1 for r in rows if r[5] == "JP")
    jp_ja = sum(1 for r in rows if r[5] == "JP" and has_cjk(r[1]))
    print(f"[report] JP={jp} 日本語名={jp_ja}")
    nagoya = [r[1] for r in rows if r[5] == "JP" and 35.05 <= r[3] <= 35.25 and 136.83 <= r[4] <= 137.05]
    print(f"[report] 名古屋近辺サンプル: {nagoya[:20]}")
    print("\n適用 (オーナー or 確認後):")
    print(f"  npx wrangler d1 execute solara-cities --remote --yes --file={OUT_SQL}")


if __name__ == "__main__":
    main()
