#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""seed_d1_cities.py — Stella 相談 候補プール (Cloudflare D1) seed 生成スクリプト

Phase B: 旧キュレート 762 都市 (world_cities.js) を D1 グローバル都市プールに置換する。
データ源: GeoNames cities1000 (全世界・人口 1000 以上、約 169,000 件)。

このスクリプトは「ローカルで SQL を生成するだけ」。Cloudflare アカウントには一切触れない。
生成後、オーナーが wrangler で D1 にロードする (手順は出力末尾 + Phase B-5 手順書)。

出力:
  1. ../worker/migrations/0001_cities.sql       — スキーマ (CREATE TABLE + index)。小さい・commit する。
  2. _geonames_cache/cities_data.sql            — バルク INSERT (約 12MB)。gitignore。wrangler d1 execute --file 用。
  キャッシュ (_geonames_cache/) に cities1000.zip / admin1CodesASCII.txt を保存し再 DL を避ける。

name 戦略 (実測: GeoNames col1 name は JP でもローマ字。日本語は col3 alternatenames に入る):
  - JP        : alternatenames の CJK トークンのうち最短 (例 厚木) → 無ければ col1 (ローマ字)。
  - 非 JP     : alternatenames の「かな」を含むトークンのうち最短 (例 パリ/ロンドン)。
                ※ かな縛りで中国語 (漢字のみ) を日本語名と誤認しないようにする。無ければ col1。
  - region    : JP のみ admin1 コード→日本語県名 (admin1CodesASCII 経由)。非 JP は NULL。

実行:
  python apps/solara/tools/seed_d1_cities.py            # フル生成
  python apps/solara/tools/seed_d1_cities.py --limit 2000  # 動作確認用に先頭 N 件だけ
"""
from __future__ import annotations

import sys
import urllib.request
import zipfile
from pathlib import Path

# Windows コンソール (cp932) で日本語 print が落ちないように
try:
    sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
except Exception:
    pass

CITIES_URL = "https://download.geonames.org/export/dump/cities1000.zip"
ADMIN1_URL = "https://download.geonames.org/export/dump/admin1CodesASCII.txt"

HERE = Path(__file__).resolve().parent
CACHE = HERE / "_geonames_cache"
CACHE.mkdir(exist_ok=True)
ZIP_PATH = CACHE / "cities1000.zip"
TXT_PATH = CACHE / "cities1000.txt"
ADMIN1_PATH = CACHE / "admin1CodesASCII.txt"
DATA_SQL = CACHE / "cities_data.sql"

SCHEMA_SQL = HERE.parent / "worker" / "migrations" / "0001_cities.sql"

INSERT_BATCH = 100  # 1 INSERT 文あたりの行数 (D1 の文サイズ制限に余裕を持たせる)

# GeoNames admin1 asciiname (ローマ字) → 日本語県名 (47)。
PREF_JA = {
    "Hokkaido": "北海道", "Aomori": "青森県", "Iwate": "岩手県", "Miyagi": "宮城県",
    "Akita": "秋田県", "Yamagata": "山形県", "Fukushima": "福島県", "Ibaraki": "茨城県",
    "Tochigi": "栃木県", "Gunma": "群馬県", "Saitama": "埼玉県", "Chiba": "千葉県",
    "Tokyo": "東京都", "Kanagawa": "神奈川県", "Niigata": "新潟県", "Toyama": "富山県",
    "Ishikawa": "石川県", "Fukui": "福井県", "Yamanashi": "山梨県", "Nagano": "長野県",
    "Gifu": "岐阜県", "Shizuoka": "静岡県", "Aichi": "愛知県", "Mie": "三重県",
    "Shiga": "滋賀県", "Kyoto": "京都府", "Osaka": "大阪府", "Hyogo": "兵庫県",
    "Nara": "奈良県", "Wakayama": "和歌山県", "Tottori": "鳥取県", "Shimane": "島根県",
    "Okayama": "岡山県", "Hiroshima": "広島県", "Yamaguchi": "山口県", "Tokushima": "徳島県",
    "Kagawa": "香川県", "Ehime": "愛媛県", "Kochi": "高知県", "Fukuoka": "福岡県",
    "Saga": "佐賀県", "Nagasaki": "長崎県", "Kumamoto": "熊本県", "Oita": "大分県",
    "Miyazaki": "宮崎県", "Kagoshima": "鹿児島県", "Okinawa": "沖縄県",
}


def download(url: str, dest: Path, min_size: int):
    if dest.exists() and dest.stat().st_size > min_size:
        print(f"[cache] {dest.name} ({dest.stat().st_size} bytes)")
        return
    print(f"[download] {url} ...")
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (solara-seed)"})
    with urllib.request.urlopen(req, timeout=180) as resp:
        data = resp.read()
    dest.write_bytes(data)
    print(f"[download] {dest.name} saved {len(data)} bytes")


def extract_cities():
    if TXT_PATH.exists() and TXT_PATH.stat().st_size > 1_000_000:
        print(f"[cache] {TXT_PATH.name} ({TXT_PATH.stat().st_size} bytes)")
        return
    with zipfile.ZipFile(ZIP_PATH) as z:
        with z.open("cities1000.txt") as f:
            TXT_PATH.write_bytes(f.read())
    print(f"[extract] {TXT_PATH.name} ({TXT_PATH.stat().st_size} bytes)")


def has_kana(s: str) -> bool:
    return any(0x3040 <= ord(ch) <= 0x30FF for ch in s)


def has_cjk(s: str) -> bool:
    for ch in s:
        o = ord(ch)
        if (0x3040 <= o <= 0x30FF) or (0x4E00 <= o <= 0x9FFF) or (0x3400 <= o <= 0x4DBF):
            return True
    return False


def parse_admin1_jp() -> dict:
    """admin1CodesASCII.txt から ('JP', code) → 日本語県名 を作る。"""
    out = {}
    with open(ADMIN1_PATH, encoding="utf-8") as f:
        for line in f:
            cols = line.rstrip("\n").split("\t")
            if len(cols) < 3:
                continue
            key = cols[0]  # 例 "JP.40"
            ascii_name = cols[2]
            if not key.startswith("JP."):
                continue
            code = key.split(".", 1)[1]
            ja = PREF_JA.get(ascii_name)
            if ja:
                out[code] = ja
    return out


def pick_name(name_col1: str, alt: str, country: str) -> str:
    """日本語表示名を決める。JP=CJK 最短 / 非JP=かな最短 / 無ければローマ字。"""
    tokens = [t.strip() for t in alt.split(",")] if alt else []
    tokens = [t for t in tokens if t]
    if country == "JP":
        cands = [t for t in tokens if has_cjk(t)]
    else:
        cands = [t for t in tokens if has_kana(t)]
    if cands:
        return min(cands, key=len)
    return name_col1


def sql_str(s) -> str:
    if s is None or s == "":
        return "NULL"
    return "'" + str(s).replace("'", "''") + "'"


SCHEMA = """-- GENERATED by apps/solara/tools/seed_d1_cities.py — Stella 相談 候補プール (D1)
-- Cloudflare D1 schema. 適用:
--   wrangler d1 execute solara-cities --remote --file=apps/solara/worker/migrations/0001_cities.sql
DROP TABLE IF EXISTS cities;
CREATE TABLE cities (
  id         INTEGER PRIMARY KEY,   -- GeoNames geonameid
  name       TEXT NOT NULL,         -- 日本語表示名 (無ければローマ字)
  ascii      TEXT,                  -- asciiname (ローマ字フォールバック / 検索用)
  lat        REAL NOT NULL,
  lng        REAL NOT NULL,
  country    TEXT NOT NULL,         -- ISO 3166-1 alpha-2
  region     TEXT,                  -- 日本語県名 (JP のみ)、他は NULL
  population INTEGER NOT NULL DEFAULT 0
);
-- bounding-box (おでかけ/近傍半径): lat 範囲で絞り lng でフィルタ
CREATE INDEX idx_cities_latlng ON cities(lat, lng);
-- 自国スコープ: WHERE country=? AND population>=? ORDER BY population DESC
CREATE INDEX idx_cities_country_pop ON cities(country, population);
-- 世界/地域スコープ: population フロア + ORDER BY population DESC LIMIT N
CREATE INDEX idx_cities_pop ON cities(population);
"""


def main():
    limit = None
    if "--limit" in sys.argv:
        i = sys.argv.index("--limit")
        limit = int(sys.argv[i + 1])

    download(CITIES_URL, ZIP_PATH, 1_000_000)
    download(ADMIN1_URL, ADMIN1_PATH, 10_000)
    extract_cities()

    admin1_jp = parse_admin1_jp()
    print(f"[admin1] JP prefecture codes mapped: {len(admin1_jp)}")

    rows = []
    skipped = 0
    with open(TXT_PATH, encoding="utf-8") as f:
        for line in f:
            cols = line.rstrip("\n").split("\t")
            if len(cols) < 19:
                skipped += 1
                continue
            try:
                gid = int(cols[0])
                lat = float(cols[4])
                lng = float(cols[5])
            except ValueError:
                skipped += 1
                continue
            name_col1 = cols[1]
            ascii_name = cols[2]
            alt = cols[3]
            country = cols[8]
            admin1 = cols[10]
            try:
                pop = int(cols[14] or 0)
            except ValueError:
                pop = 0
            name = pick_name(name_col1, alt, country)
            region = admin1_jp.get(admin1) if country == "JP" else None
            rows.append((gid, name, ascii_name, lat, lng, country, region, pop))
            if limit and len(rows) >= limit:
                break

    print(f"[parse] rows={len(rows)} skipped={skipped}")

    # ── スキーマ出力 ──
    SCHEMA_SQL.parent.mkdir(parents=True, exist_ok=True)
    SCHEMA_SQL.write_text(SCHEMA, encoding="utf-8")
    print(f"[write] schema → {SCHEMA_SQL}")

    # ── データ出力 (batched multi-row INSERT) ──
    cols_clause = "(id,name,ascii,lat,lng,country,region,population)"
    n_inserts = 0
    with open(DATA_SQL, "w", encoding="utf-8") as out:
        out.write("-- GENERATED by seed_d1_cities.py — wrangler d1 execute --file 用バルクデータ\n")
        out.write(f"-- rows: {len(rows)}\n")
        for i in range(0, len(rows), INSERT_BATCH):
            chunk = rows[i : i + INSERT_BATCH]
            values = []
            for (gid, name, ascii_name, lat, lng, country, region, pop) in chunk:
                values.append(
                    "({},{},{},{:.5f},{:.5f},{},{},{})".format(
                        gid, sql_str(name), sql_str(ascii_name), lat, lng,
                        sql_str(country), sql_str(region), pop,
                    )
                )
            out.write(f"INSERT INTO cities {cols_clause} VALUES\n")
            out.write(",\n".join(values))
            out.write(";\n")
            n_inserts += 1
    size_mb = DATA_SQL.stat().st_size / 1_000_000
    print(f"[write] data  → {DATA_SQL} ({n_inserts} INSERT 文, {size_mb:.1f} MB)")

    # ── レポート ──
    jp = sum(1 for r in rows if r[5] == "JP")
    jp_ja = sum(1 for r in rows if r[5] == "JP" and has_cjk(r[1]))
    jp_region = sum(1 for r in rows if r[5] == "JP" and r[6])
    print(f"[report] JP={jp}  日本語名={jp_ja}  県名付き={jp_region}")
    for tag, floor in (("世界(>=30万)", 300_000), ("地域(>=10万)", 100_000), ("自国(>=5万)", 50_000)):
        n = sum(1 for r in rows if r[7] >= floor)
        print(f"[report] {tag}: {n} 件")
    print("\n次の手順 (オーナー実行・Cloudflare ログイン要):")
    print("  1) npx wrangler d1 create solara-cities")
    print("  2) 出力された database_id を wrangler.toml の [[d1_databases]] に貼る")
    print(f"  3) npx wrangler d1 execute solara-cities --remote --file={SCHEMA_SQL}")
    print(f"  4) npx wrangler d1 execute solara-cities --remote --yes --file={DATA_SQL}")
    print("     (約16.9万行・数分。d1 import は v4 廃止 → execute --file を使う)")
    print("  5) npx wrangler deploy")


if __name__ == "__main__":
    main()
