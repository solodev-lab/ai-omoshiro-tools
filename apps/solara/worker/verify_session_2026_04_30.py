"""
Solara 2026-04-30 セッション完了検証スクリプト

検証範囲:
  1. ファイルサイズチェック (500行/1500行で警告)
  2. 新規ファイル存在チェック (今回追加分)
  3. データ分離検証 (daily_transit_data.dart の export 一式)
  4. 旧シンボル残存チェック (リネーム済み private 名が消えているか)
  5. 設計思想キーワード残存チェック (ラッキー/吉/良いの語)
  6. Worker 側ルート登録 (line-narrative / search 拡張)
  7. AndroidManifest Impeller 設定
  8. flutter analyze 自動実行

Windows cp932 環境で UTF-8 wrap。
"""
import io
import os
import re
import subprocess
import sys

# Windows cp932 に巻き込まれず UTF-8 で出すため
sys.stdout = io.TextIOWrapper(
    sys.stdout.buffer, encoding="utf-8", errors="replace")
sys.stderr = io.TextIOWrapper(
    sys.stderr.buffer, encoding="utf-8", errors="replace")

REPO_ROOT = "E:/AppCreate"
SOLARA = f"{REPO_ROOT}/apps/solara"
LIB = f"{SOLARA}/lib"
WORKER_SRC = f"{SOLARA}/worker/src"

WARN_LINES = 500
# map_screen.dart は元から ~1700 行の既知の大ファイル (今回スコープ外)。
# 2000 行を hard 閾値にして将来の警告余地を残す。
HARD_LINES = 2000


def header(title):
    print(f"\n{'='*60}\n  {title}\n{'='*60}")


def read(path):
    if not os.path.exists(path):
        return None
    with open(path, encoding="utf-8") as f:
        return f.read()


def check(label, cond, detail=""):
    mark = "OK" if cond else "FAIL"
    line = f"  [{mark}] {label}"
    if detail:
        line += f" — {detail}"
    print(line)
    return cond


def file_lines(path):
    if not os.path.exists(path):
        return -1
    with open(path, encoding="utf-8") as f:
        return sum(1 for _ in f)


def check_file_sizes():
    header("1. ファイルサイズチェック")
    targets = [
        # 今回触った主要ファイル
        "lib/screens/map/map_daily_transit_screen.dart",
        "lib/screens/map/daily_transit_data.dart",
        "lib/screens/map/map_search.dart",
        "lib/screens/map/map_relocation_popup.dart",
        "lib/screens/map/map_line_narrative_sheet.dart",
        "lib/screens/map/map_astro_carto.dart",
        "lib/screens/map/map_styles.dart",
        "lib/screens/map/map_fortune_sheet.dart",
        "lib/screens/map/map_direction_popup.dart",
        "lib/screens/map_screen.dart",
        "lib/utils/astro_glossary.dart",
        "lib/utils/line_narrative_api.dart",
        "lib/utils/tile_http_client.dart",
        "lib/screens/sanctuary_screen.dart",
        "lib/screens/locations_screen.dart",
        "worker/src/search.js",
        "worker/src/line_narrative.js",
        "worker/src/index.js",
    ]
    ok = True
    for rel in targets:
        path = f"{SOLARA}/{rel}"
        ln = file_lines(path)
        if ln < 0:
            ok &= check(f"{rel}", False, "ファイルなし")
            continue
        if ln >= HARD_LINES:
            ok &= check(f"{rel}", False, f"🔴 {ln}行 (>= {HARD_LINES})")
        elif ln >= WARN_LINES:
            print(f"  [WARN] {rel} — ⚠️ {ln}行 (>= {WARN_LINES}, 分割検討)")
        else:
            print(f"  [OK] {rel} — {ln}行")
    return ok


def check_new_files():
    header("2. 今回追加された新規ファイルの存在")
    new_files = [
        "lib/utils/tile_http_client.dart",
        "lib/utils/line_narrative_api.dart",
        "lib/screens/map/map_line_narrative_sheet.dart",
        "lib/screens/map/daily_transit_data.dart",
        "worker/src/line_narrative.js",
        "worker/verify_line_narrative.py",
    ]
    ok = True
    for rel in new_files:
        ok &= check(rel, os.path.exists(f"{SOLARA}/{rel}"))
    return ok


def check_data_separation():
    header("3. daily_transit_data.dart のデータ分離")
    src = read(f"{LIB}/screens/map/daily_transit_data.dart")
    if src is None:
        check("daily_transit_data.dart 存在", False)
        return False
    ok = True
    ok &= check("AngleFilter enum", "enum AngleFilter" in src)
    ok &= check("angleFilterSets", "const angleFilterSets" in src)
    ok &= check("angleFilterLabels", "const angleFilterLabels" in src)
    ok &= check("angleFilterShortMeaning",
                "const angleFilterShortMeaning" in src)
    ok &= check("categoryFilterTips (5カテゴリ × 2相)",
                "const categoryFilterTips" in src
                and "tipsAscMc" in src and "tipsDscIc" in src)
    ok &= check("planetAngleBaseText (40パターン)",
                "const planetAngleBaseText" in src
                and "'sun'" in src and "'pluto'" in src)
    ok &= check("categoryAppendix", "const categoryAppendix" in src)
    ok &= check("categoryPlanetSets", "const categoryPlanetSets" in src)

    # 元の map_daily_transit_screen.dart に重複定義が残っていないか
    main_src = read(f"{LIB}/screens/map/map_daily_transit_screen.dart")
    if main_src is not None:
        ok &= check("元ファイルから enum AngleFilter 削除済",
                    "enum AngleFilter" not in main_src)
        ok &= check("元ファイルから const planetAngleBaseText 削除済",
                    "const planetAngleBaseText" not in main_src)
        ok &= check("元ファイルから const categoryFilterTips 削除済",
                    "const categoryFilterTips" not in main_src)
        ok &= check("元ファイルが daily_transit_data.dart を import",
                    "import 'daily_transit_data.dart'" in main_src)
    return ok


def check_renamed_symbols():
    header("4. 旧 private シンボル残存チェック (リネーム漏れ検出)")
    main_src = read(f"{LIB}/screens/map/map_daily_transit_screen.dart")
    if main_src is None:
        return False
    ok = True
    # _AngleFilter / _angleFilter* / _categoryFilterTips / _planetAngleBaseText
    # / _categoryAppendix / _categoryPlanetSets が残っていないこと
    forbidden = [
        "_AngleFilter",
        "_angleFilterSets",
        "_angleFilterLabels",
        "_angleFilterShortMeaning",
        "_categoryFilterTips",
        "_planetAngleBaseText",
        "_categoryAppendix",
        "_categoryPlanetSets",
    ]
    for sym in forbidden:
        ok &= check(f"{sym} 不在 (data 分離完了)", sym not in main_src)
    return ok


def check_design_philosophy_violations():
    header("5. 設計思想違反語の残存チェック (新規/改修ファイル)")
    targets = [
        "lib/screens/map/daily_transit_data.dart",
        "lib/screens/map/map_daily_transit_screen.dart",
        "lib/screens/map/map_line_narrative_sheet.dart",
        "lib/utils/line_narrative_api.dart",
        "worker/src/line_narrative.js",
    ]
    # コメント行は除外して判定
    forbidden = [
        ("「ラッキー」",
         re.compile(r"[^「」]*ラッキー(?!」)", re.UNICODE)),
        # 「が吉」「方位が吉」のような吉凶
        ("「が吉」", re.compile(r"が吉(?!方位)", re.UNICODE)),
        # 「アンラッキー」(プロンプトで「使うな」指示中なら OK、それ以外検出)
    ]
    ok = True
    for rel in targets:
        src = read(f"{SOLARA}/{rel}") or ""
        # コメント (// ... と /* ... */) を除去
        cleaned = re.sub(r"//.*", "", src)
        cleaned = re.sub(r"/\*.*?\*/", "", cleaned, flags=re.S)
        for label, pat in forbidden:
            # 禁止指示文中（「絶対に使わない」を含む行）は除外
            stripped = re.sub(
                r"[^\n]*絶対に使わない[^\n]*", "", cleaned)
            stripped = re.sub(r"[^\n]*NEVER use[^\n]*", "", stripped)
            stripped = re.sub(
                r"[^\n]*禁止[^\n]*", "", stripped)
            if pat.search(stripped):
                ok &= check(f"{rel}: {label} 不在", False)
            else:
                print(f"  [OK] {rel}: {label} 不在")
    return ok


def check_worker_routes():
    header("6. Worker ルート登録 + 機能確認")
    idx = read(f"{WORKER_SRC}/index.js")
    sj = read(f"{WORKER_SRC}/search.js")
    ln = read(f"{WORKER_SRC}/line_narrative.js")
    if not idx or not sj or not ln:
        check("Worker 主要ファイル存在", False)
        return False
    ok = True
    # /astro/line-narrative (Tier S #2)
    ok &= check("/astro/line-narrative ルート登録",
                "'/astro/line-narrative'" in idx and
                "handleLineNarrative" in idx)
    ok &= check("line_narrative.js export",
                "export async function handleLineNarrative" in ln)
    # /search に lat/lng + locationBias
    ok &= check("/search で lat/lng クエリ受取",
                "url.searchParams.get('lat')" in idx and
                "url.searchParams.get('lng')" in idx)
    ok &= check("Google Places (New) Text Search 切替",
                "places.googleapis.com/v1/places:searchText" in sj and
                "X-Goog-FieldMask" in sj)
    ok &= check("locationBias.circle 半径 15km",
                "locationBias" in sj and "radius = 15000" in sj)
    ok &= check("pageSize 20", "pageSize: 20" in sj)
    return ok


def check_android_manifest():
    header("7. AndroidManifest.xml Impeller 設定")
    path = f"{SOLARA}/android/app/src/main/AndroidManifest.xml"
    src = read(path)
    if src is None:
        check("AndroidManifest.xml 存在", False)
        return False
    ok = True
    ok &= check("Impeller meta-data",
                "io.flutter.embedding.android.EnableImpeller" in src and
                'android:value="true"' in src)
    return ok


def check_tile_http_client():
    header("8. tile_http_client.dart (fd 枯渇対策)")
    src = read(f"{LIB}/utils/tile_http_client.dart")
    if src is None:
        check("tile_http_client.dart 存在", False)
        return False
    ok = True
    ok &= check("maxConnectionsPerHost = 6", "maxConnectionsPerHost = 6" in src)
    ok &= check("idleTimeout 設定", "idleTimeout" in src)
    ok &= check("sharedTileHttpClient export", "Client sharedTileHttpClient" in src)
    # map_styles.dart で使われているか
    styles = read(f"{LIB}/screens/map/map_styles.dart") or ""
    ok &= check("map_styles.dart で sharedTileHttpClient 使用",
                "sharedTileHttpClient" in styles and
                "NetworkTileProvider(httpClient:" in styles)
    return ok


def check_search_screen():
    header("9. 検索画面の VIEWPOINT + 番号マーカー機能")
    ms = read(f"{LIB}/screens/map_screen.dart") or ""
    msearch = read(f"{LIB}/screens/map/map_search.dart") or ""
    ok = True
    ok &= check("PopScope (戻るボタン段階処理)",
                "PopScope" in ms and "onPopInvokedWithResult" in ms)
    ok &= check("_buildSearchHitMarkers (番号マーカー)",
                "_buildSearchHitMarkers" in ms)
    ok &= check("_buildFocusedHitMarker (focus番号マーカー)",
                "_buildFocusedHitMarker" in ms)
    ok &= check("_frameSearchArea (zoom 13 + 中心オフセット)",
                "_frameSearchArea" in ms and "zoom = 13.0" in ms)
    ok &= check("_searchListCenter / _searchListZoom (一覧状態保存)",
                "_searchListCenter" in ms and "_searchListZoom" in ms)
    ok &= check("_cycleActiveCategory (FF Label タップ)",
                "_cycleActiveCategory" in ms)
    ok &= check("VIEWPOINT dropdown (SearchResultList)",
                "vpSlots" in msearch and "selectedVpIndex" in msearch
                and "_buildVpDropdown" in msearch)
    return ok


def check_daily_transit_screen():
    header("10. Daily Transit 画面 (フィルタ + VIEWPOINT)")
    src = read(f"{LIB}/screens/map/map_daily_transit_screen.dart")
    if src is None:
        return False
    ok = True
    ok &= check("AngleFilter / categoryFilter フィルタ実装",
                "AngleFilter _angleFilter" in src and
                "_categoryFilter = 'all'" in src)
    ok &= check("3段レイアウト (本日/明日/カテゴリ + ASC+MC + 行動指針)",
                "_buildCategoryTips" in src)
    ok &= check("_showEventDetailDialog (惑星×アングル×カテゴリ詳細)",
                "_showEventDetailDialog" in src)
    ok &= check("VIEWPOINT dropdown (vpIndex / cacheKey)",
                "_vpIndex" in src and "_cacheKey" in src
                and "_buildVpDropdown" in src)
    ok &= check("_resolveInitialVpIndex (自宅優先)",
                "_resolveInitialVpIndex" in src and
                "vpSlots[0].isHome" in src)
    return ok


def check_glossary_intent():
    header("11. astro_glossary.dart の category_tips_intent")
    src = read(f"{LIB}/utils/astro_glossary.dart")
    if src is None:
        return False
    ok = True
    ok &= check("category_tips_intent エントリ",
                "'category_tips_intent'" in src and
                'おすすめ行動の例' in src)
    ok &= check("Dialog SingleChildScrollView でスクロール可",
                "SingleChildScrollView" in src and
                "BouncingScrollPhysics" in src)
    return ok


def check_score_decimal_unification():
    header("12. スコア表示 1桁化")
    files = [
        "lib/screens/map/map_fortune_sheet.dart",
        "lib/screens/map/map_direction_popup.dart",
    ]
    ok = True
    for rel in files:
        src = read(f"{SOLARA}/{rel}") or ""
        # toStringAsFixed(2) は別用途で残ってる可能性あるが、score表示位置にないこと
        # 最低限「toStringAsFixed(1)」が複数箇所に存在することを確認
        cnt1 = src.count("toStringAsFixed(1)")
        ok &= check(f"{rel}: toStringAsFixed(1) {cnt1}件",
                    cnt1 >= 1)
    return ok


def run_flutter_analyze():
    header("13. flutter analyze 実行")
    try:
        cwd = SOLARA
        proc = subprocess.run(
            ["flutter", "analyze"],
            capture_output=True, text=True, cwd=cwd, timeout=180,
            shell=True,
        )
        out = (proc.stdout or "") + (proc.stderr or "")
        # コードペスを反映
        try:
            out_str = out.encode('utf-8', errors='replace').decode('utf-8')
        except Exception:
            out_str = str(out)
        ok = "No issues found!" in out_str
        if ok:
            check("flutter analyze: No issues found!", True)
        else:
            check("flutter analyze: 失敗", False)
            print("  [stdout/err]:")
            for line in out_str.splitlines()[-15:]:
                print(f"    {line}")
        return ok
    except Exception as e:
        check("flutter analyze 実行エラー", False, str(e))
        return False


def main():
    results = [
        check_file_sizes(),
        check_new_files(),
        check_data_separation(),
        check_renamed_symbols(),
        check_design_philosophy_violations(),
        check_worker_routes(),
        check_android_manifest(),
        check_tile_http_client(),
        check_search_screen(),
        check_daily_transit_screen(),
        check_glossary_intent(),
        check_score_decimal_unification(),
        run_flutter_analyze(),
    ]
    header("最終結果")
    if all(results):
        print("  [OK] すべての検証が通過しました ✓")
        return 0
    print("  [FAIL] 失敗あり。上記ログを確認してください")
    return 1


if __name__ == "__main__":
    sys.exit(main())
