"""マップスタイル機能の実装検証スクリプト。

- 変更したファイルのサイズ・行数・関連シンボルを確認
- 未使用 import / 未参照シンボルを検出
- dart analyze との併用で最終チェック

履歴:
- 2026-04-20: 初版（4スタイル: OSM HOT × Light/Dark + CyclOSM × Light/Dark）
- 2026-05-04: Phase 3 でダークマトリクスを 2段→1段合成 (`_darkInvertHueRotate180Matrix`)
- 2026-05-09: CyclOSM 撤去 (2スタイル化) + 4層防御モデル導入時の reset Stream wiring 検証
"""

from __future__ import annotations
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]
SOLARA = REPO / "apps" / "solara"

TARGETS = [
    SOLARA / "lib" / "screens" / "map_screen.dart",
    SOLARA / "lib" / "screens" / "map" / "map_layer_panel.dart",
    SOLARA / "lib" / "screens" / "map" / "map_styles.dart",
    SOLARA / "lib" / "utils" / "solara_storage.dart",
]

ALL_LIB = list((SOLARA / "lib").rglob("*.dart"))


def ok(msg: str) -> None:
    print(f"  OK  {msg}")


def warn(msg: str) -> None:
    print(f"  !!  {msg}")


def section(title: str) -> None:
    print(f"\n=== {title} ===")


# ──────────────────────────────────────────────────────────
# 1. ファイルサイズ & 存在確認
# ──────────────────────────────────────────────────────────
section("1. File existence & size")
for p in TARGETS:
    if not p.exists():
        warn(f"missing: {p.relative_to(REPO)}")
        continue
    lines = p.read_text(encoding="utf-8").count("\n") + 1
    kb = p.stat().st_size / 1024
    status = "OK"
    if lines > 600:
        status = "!! LARGE"
    print(f"  {status}  {p.relative_to(REPO)}  ({lines} lines, {kb:.1f} KB)")


# ──────────────────────────────────────────────────────────
# 2. map_styles.dart のシンボルエクスポート確認
# ──────────────────────────────────────────────────────────
section("2. map_styles.dart exports")
styles_src = (SOLARA / "lib" / "screens" / "map" / "map_styles.dart").read_text(encoding="utf-8")

expected = [
    ("enum MapStyle", "enum定義"),
    ("class MapStyleConfig", "config class"),
    ("mapStyleConfigs", "プリセット辞書"),
    ("mapStyleFromId", "id復元関数"),
    ("buildStyledTileLayer", "TileLayer builder"),
    ("_darkInvertHueRotate180Matrix", "ダーク反転+色相回転 1段合成マトリクス (Phase 3)"),
    ("reset:", "TileLayer.reset Stream wiring (4層防御 第3層)"),
]
for sym, desc in expected:
    if sym in styles_src:
        ok(f"{desc} ({sym})")
    else:
        warn(f"missing: {desc} ({sym})")

# 2プリセット列挙 (2026-05-09: CyclOSM 撤去で 4→2)
enum_names = re.findall(r"MapStyle\.(\w+)", styles_src)
unique_names = set(enum_names)
print(f"  enum 値: {sorted(unique_names)}  ({len(unique_names)} 種)")
if len(unique_names) != 2:
    warn(f"MapStyle の列挙数が想定(2 = osmHotLight/osmHotDark)と違う")
if "cyclosmLight" in unique_names or "cyclosmDark" in unique_names:
    warn("CyclOSM 撤去 (2026-05-09) のはずだが enum に残存している")


# ──────────────────────────────────────────────────────────
# 3. map_screen.dart の wire-up 確認
# ──────────────────────────────────────────────────────────
section("3. map_screen.dart wiring")
screen_src = (SOLARA / "lib" / "screens" / "map_screen.dart").read_text(encoding="utf-8")

checks = [
    ("import 'map/map_styles.dart'", "import"),
    ("MapStyle _mapStyle", "state field"),
    ("_loadMapStyle()", "initState呼び出し"),
    ("SolaraStorage.loadMapStyleId", "load 呼び出し"),
    ("SolaraStorage.saveMapStyleId", "save 呼び出し"),
    ("buildStyledTileLayer(", "TileLayer差替"),
    ("mapStyleConfigs[_mapStyle]!.backgroundColor", "背景色連動"),
    ("onMapStyleChanged: _onMapStyleChanged", "LayerPanel 接続"),
    ("_bootReady", "4層防御 第2層: mount delay flag"),
    ("_tileResetCtrl", "4層防御 第3層: reset Stream controller"),
    ("_settleResetTimer", "4層防御 第4層: settle 後 verify-recover タイマー"),
]
for pat, desc in checks:
    if pat in screen_src:
        ok(f"{desc}")
    else:
        warn(f"missing: {desc} ({pat})")

# 旧ハードコード URL が残っていないか
legacy_urls = [
    "basemaps.cartocdn.com/dark_nolabels",
    "basemaps.cartocdn.com/dark_only_labels",
    "basemaps.cartocdn.com/rastertiles/voyager",
    "tiles.stadiamaps.com/tiles/stamen",
    "tile.opentopomap.org",
    "server.arcgisonline.com",
    "tile-cyclosm.openstreetmap.fr",  # 2026-05-09 撤去: クライアント側からは完全消滅すべき
    "tile.openstreetmap.fr/hot",      # Worker 経由なので screen に直接書かれていてはいけない
]
print("  旧タイルURLが map_screen.dart に残っていないかチェック:")
for url in legacy_urls:
    if url in screen_src:
        warn(f"  残存: {url}")
    else:
        ok(f"  クリーン: {url} なし")


# ──────────────────────────────────────────────────────────
# 4. LayerPanel UI 経路確認
# ──────────────────────────────────────────────────────────
section("4. LayerPanel UI")
panel_src = (SOLARA / "lib" / "screens" / "map" / "map_layer_panel.dart").read_text(encoding="utf-8")

checks = [
    ("import 'map_styles.dart'", "import"),
    ("MapStyle mapStyle", "受入フィールド"),
    ("onMapStyleChanged", "callback"),
    ("_section('MAPSTYLE'", "MAPSTYLE セクション"),
    ("_styleOption", "描画メソッド"),
    ("mapStyleConfigs.entries", "ループ元"),
]
for pat, desc in checks:
    if pat in panel_src:
        ok(f"{desc}")
    else:
        warn(f"missing: {desc} ({pat})")


# ──────────────────────────────────────────────────────────
# 5. SolaraStorage 拡張確認
# ──────────────────────────────────────────────────────────
section("5. SolaraStorage map style API")
storage_src = (SOLARA / "lib" / "utils" / "solara_storage.dart").read_text(encoding="utf-8")

checks = [
    ("_mapStyleKey = 'solara_map_style'", "key定数"),
    ("Future<String?> loadMapStyleId()", "load"),
    ("Future<void> saveMapStyleId(String id)", "save"),
]
for pat, desc in checks:
    if pat in storage_src:
        ok(f"{desc}")
    else:
        warn(f"missing: {desc} ({pat})")


# ──────────────────────────────────────────────────────────
# 6. 変更ファイルの未使用 import 検出
# ──────────────────────────────────────────────────────────
section("6. Unused imports in changed files")
def check_unused_imports(path: Path) -> list[str]:
    src = path.read_text(encoding="utf-8")
    # import 行抽出
    import_re = re.compile(r"^import\s+['\"]([^'\"]+)['\"](?:\s+as\s+(\w+))?;", re.M)
    unused = []
    # コード部分（import 以外）を抽出
    lines = src.splitlines()
    code_body = "\n".join(l for l in lines if not l.lstrip().startswith("import "))
    for m in import_re.finditer(src):
        pkg, alias = m.group(1), m.group(2)
        if alias:
            # aliased: `as alias` の alias を使っているか
            if not re.search(rf"\b{alias}\.", code_body):
                unused.append(f"{pkg} as {alias}")
            continue
        # ファイル名ベースの symbol を推測
        leaf = pkg.rsplit("/", 1)[-1].replace(".dart", "")
        # 同じファイル内で使っていそうなシンボル候補をパッケージから推測しきれないため、
        # simple heuristic: leaf が stopwords でなく、コード内にまったく触れられない場合はチェック対象
        # （実際には dart analyze が unused_import を報告するので補助的）
        if leaf in {"material", "cupertino", "dart:core", "dart:async"}:
            continue
    return unused

for p in TARGETS:
    if not p.exists():
        continue
    unused = check_unused_imports(p)
    if unused:
        for u in unused:
            warn(f"{p.name}: unused alias import {u}")
    else:
        ok(f"{p.name}: alias-imports OK")


# ──────────────────────────────────────────────────────────
# 7. _searchResultName が本当に使われていないかだけ確認
# ──────────────────────────────────────────────────────────
section("7. Dead field check (pre-existing: _searchResultName)")
# 今回は触っていないが、検証対象として参照されていないフィールドを報告するだけ
count = len(re.findall(r"\b_searchResultName\b", screen_src))
print(f"  _searchResultName 出現回数: {count}")
if count == 1:
    warn("  宣言のみで使用箇所なし → 削除候補（今回は範囲外のため保留）")


# ──────────────────────────────────────────────────────────
# 8. dart analyze（変更ファイル限定）
# ──────────────────────────────────────────────────────────
section("8. flutter analyze (changed files)")
try:
    result = subprocess.run(
        ["flutter", "analyze"] + [str(p) for p in TARGETS],
        cwd=str(SOLARA),
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=120,
    )
    last_lines = (result.stdout or "").strip().splitlines()[-5:]
    for line in last_lines:
        print(f"  {line}")
    if result.returncode == 0:
        ok("analyze clean")
    else:
        warn(f"analyze failed (rc={result.returncode})")
except FileNotFoundError:
    warn("flutter コマンド未検出（PATH 要確認）")


print("\n=== 検証完了 ===")
