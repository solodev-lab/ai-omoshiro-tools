"""
Solara Tier S #2 (A*C*G Line Narrative) 静的検証スクリプト

検証内容:
  1. Worker 側
     - line_narrative.js が存在する
     - export handleLineNarrative
     - callGemini を fortune.js から import
     - 設計思想キーワードが日本語/英語プロンプトに含まれる
     - 禁止語（ラッキー/lucky 等）がプロンプトのリテラル指示に存在しないこと
       ※ プロンプトは「禁止語を使うな」と書いてあるので、禁止指示文中に含まれるのは OK
   2. index.js でルート登録されている
   3. Dart 側
     - utils/line_narrative_api.dart 存在
     - LineNarrative クラス + fetchLineNarrative + cache
     - screens/map/map_line_narrative_sheet.dart 存在
     - showLineNarrativeSheet ヘルパー存在
     - map_relocation_popup.dart で showLineNarrativeSheet を呼んでいる
     - map_screen.dart で natalSummary を渡している

flutter analyze は別工程で実行（このスクリプトは静的構造のみ確認）。
"""
import os
import re
import sys

REPO_ROOT = "E:/AppCreate"
SOLARA = f"{REPO_ROOT}/apps/solara"
LIB = f"{SOLARA}/lib"
WORKER_SRC = f"{SOLARA}/worker/src"


def header(title):
    print(f"\n{'='*60}\n  {title}\n{'='*60}")


def read(path):
    if not os.path.exists(path):
        return None
    with open(path, encoding="utf-8") as f:
        return f.read()


def check(label, cond, detail=""):
    mark = "OK" if cond else "FAIL"
    print(f"  [{mark}] {label}{(' — ' + detail) if detail else ''}")
    return cond


def verify_worker():
    header("1. Worker 側 line_narrative.js")
    src = read(f"{WORKER_SRC}/line_narrative.js")
    ok = True
    ok &= check("ファイル存在", src is not None)
    if src is None:
        return False
    ok &= check("export handleLineNarrative", "export async function handleLineNarrative" in src)
    ok &= check("callGemini import", "from './fortune.js'" in src and "callGemini" in src)
    ok &= check("PLANET_JP 定義", "const PLANET_JP" in src)
    ok &= check("ANGLE_MEANING_JP 定義", "const ANGLE_MEANING_JP" in src)
    ok &= check("FRAME_MEANING_JP 定義", "const FRAME_MEANING_JP" in src)
    # 設計思想：日本語プロンプトに禁止語の「使うな」指示が入っているか
    ok &= check(
        "JAプロンプトに「ラッキー」禁止指示",
        "「ラッキー」" in src and "絶対に使わない" in src,
    )
    ok &= check(
        "JAプロンプトに Soft/Hard 独立2軸の説明",
        "ソフトとハードは独立した2つのエネルギー" in src,
    )
    ok &= check(
        "JAプロンプトに「在る・効く」指示",
        "「在る」" in src and "「効く」" in src,
    )
    ok &= check(
        "ENプロンプトに lucky 禁止指示",
        '"lucky"' in src and "NEVER use words" in src,
    )
    ok &= check(
        "ENプロンプトに Soft/Hard 独立軸の説明",
        "TWO INDEPENDENT energies" in src,
    )
    # 入力検証
    ok &= check("frame validation (natal/transit のみ)",
                "['natal', 'transit'].includes(frame)" in src)
    ok &= check("angle validation",
                "['ASC', 'MC', 'DSC', 'IC']" in src)
    return ok


def verify_index_route():
    header("2. index.js のルート登録")
    src = read(f"{WORKER_SRC}/index.js")
    if src is None:
        check("index.js 存在", False)
        return False
    ok = True
    ok &= check("import handleLineNarrative",
                "import { handleLineNarrative }" in src
                and "from './line_narrative.js'" in src)
    ok &= check("/astro/line-narrative ルート登録",
                "'/astro/line-narrative'" in src
                and "handleLineNarrative(body, env)" in src)
    return ok


def verify_dart_api():
    header("3. Dart 側 line_narrative_api.dart")
    src = read(f"{LIB}/utils/line_narrative_api.dart")
    if src is None:
        check("line_narrative_api.dart 存在", False)
        return False
    ok = True
    ok &= check("LineNarrative クラス", "class LineNarrative" in src)
    ok &= check("fromJson factory", "factory LineNarrative.fromJson" in src)
    ok &= check("fetchLineNarrative 関数",
                "Future<LineNarrative?> fetchLineNarrative" in src)
    ok &= check("LRU キャッシュ実装",
                "LinkedHashMap<String, LineNarrative>" in src
                and "_maxCacheEntries" in src)
    ok &= check("clearLineNarrativeCache 関数",
                "void clearLineNarrativeCache()" in src)
    ok &= check("solaraWorkerBase 参照（ハードコード回避）",
                "solaraWorkerBase" in src and "https://" not in re.sub(
                    r"//.*", "", src
                ).split("solaraWorkerBase")[0])
    return ok


def verify_dart_sheet():
    header("4. Dart 側 map_line_narrative_sheet.dart")
    src = read(f"{LIB}/screens/map/map_line_narrative_sheet.dart")
    if src is None:
        check("map_line_narrative_sheet.dart 存在", False)
        return False
    ok = True
    ok &= check("MapLineNarrativeSheet クラス",
                "class MapLineNarrativeSheet" in src)
    ok &= check("showLineNarrativeSheet ヘルパー",
                "Future<void> showLineNarrativeSheet" in src)
    ok &= check("Soft/Hard セクション分け",
                "softNote" in src and "hardNote" in src)
    ok &= check("「詳しく読む」ボタン (JA/EN)",
                "詳しく読む" in src and "Read with AI" in src)
    ok &= check("失敗時フォールバック表示",
                "Could not load AI narrative" in src
                or "AI解釈を取得できませんでした" in src)
    ok &= check("static 辞書フォールバック (astro_glossary 参照)",
                "astroGlossary" in src
                and ("'aspect_lines'" in src or "aspect_lines" in src)
                and ("'transit_acg'" in src or "transit_acg" in src))
    return ok


def verify_popup_wiring():
    header("5. map_relocation_popup.dart の wiring")
    src = read(f"{LIB}/screens/map/map_relocation_popup.dart")
    if src is None:
        check("map_relocation_popup.dart 存在", False)
        return False
    ok = True
    ok &= check("MapLineNarrativeSheet import",
                "map_line_narrative_sheet.dart" in src)
    ok &= check("natalSummary フィールド",
                "Map<String, int>? natalSummary" in src)
    ok &= check("_openLineSheet メソッド",
                "void _openLineSheet" in src
                and "showLineNarrativeSheet(" in src)
    ok &= check("AstroFrame.transit 判定",
                "AstroFrame.transit" in src
                and "frameKey ==" in src)
    ok &= check("_buildLineRow に context 引数",
                "_buildLineRow(BuildContext context, NearbyAstroLine n)" in src)
    ok &= check("InkWell でタップ可能化",
                "InkWell(" in src and "onTap: canOpen" in src)
    return ok


def verify_screen_wiring():
    header("6. map_screen.dart の natalSummary 渡し")
    src = read(f"{LIB}/screens/map_screen.dart")
    if src is None:
        check("map_screen.dart 存在", False)
        return False
    ok = True
    ok &= check("MapRelocationPopup 呼出に natalSummary",
                "natalSummary: natalSummary" in src)
    ok &= check("signOf ヘルパー定義",
                "int signOf(double lon)" in src)
    ok &= check("ascSign 計算",
                "'ascSign'" in src)
    ok &= check("mcSign 計算",
                "'mcSign'" in src)
    return ok


def verify_no_forbidden_in_clientside():
    header("7. クライアント Dart に占い的吉凶語が入っていないか")
    files = [
        f"{LIB}/utils/line_narrative_api.dart",
        f"{LIB}/screens/map/map_line_narrative_sheet.dart",
    ]
    forbidden = [
        ("ラッキー", "「ラッキー」"),
        ("吉方位", "「吉方位」"),
        ("が吉", "「が吉」"),
        ("アンラッキー", "「アンラッキー」"),
    ]
    ok = True
    for path in files:
        src = read(path) or ""
        # コメント行は除外（簡易: // ... と /* */ を粗く外す）
        cleaned = re.sub(r"//.*", "", src)
        cleaned = re.sub(r"/\*.*?\*/", "", cleaned, flags=re.S)
        for needle, label in forbidden:
            present = needle in cleaned
            ok &= check(f"{os.path.basename(path)}: {label} 不在", not present)
    return ok


def main():
    results = [
        verify_worker(),
        verify_index_route(),
        verify_dart_api(),
        verify_dart_sheet(),
        verify_popup_wiring(),
        verify_screen_wiring(),
        verify_no_forbidden_in_clientside(),
    ]
    header("最終結果")
    if all(results):
        print("  [OK] すべての静的検証が通過しました")
        return 0
    print("  [FAIL] 失敗あり。上記ログを確認してください")
    return 1


if __name__ == "__main__":
    sys.exit(main())
