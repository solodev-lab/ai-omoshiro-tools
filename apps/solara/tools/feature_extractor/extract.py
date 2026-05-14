#!/usr/bin/env python3
"""Solara feature inventory extractor.

Solara の Dart / Worker JS ソースから以下を機械抽出し、層別 raw inventory
と coverage report を出力する:

  - class / mixin / extension / enum / typedef
  - public/private 関数 (top-level + method)
  - 直前の /// doc comment
  - import 文 (層分類 + 依存追跡)
  - Navigator.push / showDialog / showModalBottomSheet / showInfoPopup 呼出
  - Worker URL リテラル (Flutter 側)
  - Worker JS のルート定義 / Gemini 呼出 / KV/DO 使用

対整合チェック (coverage_report.md 内):
  #1 機械 → Doc        : 機械抽出したクラスが人手版に未記述
  #2 Doc → 機械        : 人手版にあるがコードに存在しない (ゴースト)
  #3 Worker ↔ Flutter  : エンドポイント対整合
  #4 画面 ↔ 機能集合   : 画面別の Worker URL / Popup / Navigator
  #5 import 依存グラフ : 層間依存マトリクス + ハブ + 孤立ファイル (Pro 化影響範囲)
  #6 ハッシュ stamp    : 前回実行からの変更ファイル検知 (_stamps.json)
  #7 astro_glossary    : 用語辞書の定義 ↔ 参照 対整合

出力:
  apps/solara/docs/feature_inventory/
    _index.md              # 全体ナビゲーション
    _stamps.json           # #6 用 ファイルハッシュ台帳 (機械生成)
    00_worker.md           # 層 0: Worker
    01a_pure_calc.md       # 層 1a: 純計算
    01b_static_data.md     # 層 1b: 静的データ辞書
    01c_models.md          # 層 1c: モデル
    02a_api_wrappers.md    # 層 2a: API ラッパ
    02b_persistence.md     # 層 2b: 永続化/キャッシュ
    02c_globals.md         # 層 2c: グローバル singleton
    03a_widgets_pure.md    # 層 3a: 共通ウィジェット (純粋)
    03b_theme.md           # 層 3b: テーマ・装飾
    03c_widgets_anim.md    # 層 3c: 演出ウィジェット
    04a_map.md             # 層 4a: Map 画面
    04b_horoscope.md       # 層 4b: Horoscope 画面
    04c_observe.md         # 層 4c: Observe (Tarot) 画面
    04d_galaxy.md          # 層 4d: Galaxy 画面
    04e_sanctuary.md       # 層 4e: Sanctuary 画面
    04f_subscreens.md      # 層 4f: サブ画面
    05_main.md             # 層 5: 連携層
    coverage_report.md     # 対整合チェック結果 (#1〜#4)

Usage:
    cd E:/AppCreate
    python apps/solara/tools/feature_extractor/extract.py            # 全層
    python apps/solara/tools/feature_extractor/extract.py --layer 0  # 特定層のみ
    python apps/solara/tools/feature_extractor/extract.py --dry-run  # 出力せずサマリのみ
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path, PurePosixPath
from typing import Optional

# ── Windows 文字化け対策 ────────────────────────────────────────
if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

# ── パス ──────────────────────────────────────────────────────
ROOT = Path(__file__).resolve().parents[2]  # apps/solara
LIB = ROOT / "lib"
WORKER_SRC = ROOT / "worker" / "src"
OUT_DIR = ROOT / "docs" / "feature_inventory"

# ── 層定義 ────────────────────────────────────────────────────
LAYER_ORDER = [
    "0", "1a", "1b", "1c",
    "2a", "2b", "2c",
    "3a", "3b", "3c",
    "4a", "4b", "4c", "4d", "4e", "4f",
    "5",
]

LAYER_NAMES = {
    "0":  "Worker (バックエンド計算式)",
    "1a": "純計算ユーティリティ",
    "1b": "静的データ辞書",
    "1c": "モデルクラス",
    "2a": "API/Worker ラッパ",
    "2b": "永続化/キャッシュ",
    "2c": "グローバル singleton",
    "3a": "共通ウィジェット (純粋)",
    "3b": "テーマ・装飾",
    "3c": "演出ウィジェット (animated)",
    "4a": "Map 画面",
    "4b": "Horoscope 画面",
    "4c": "Observe (Tarot) 画面",
    "4d": "Galaxy 画面",
    "4e": "Sanctuary 画面",
    "4f": "サブ画面 (Forecast / Locations / Philosophy / Font Preview)",
    "5":  "連携層 (main.dart / PopScope / IndexedStack)",
}

LAYER_FILENAMES = {
    "0":  "00_worker.md",
    "1a": "01a_pure_calc.md",
    "1b": "01b_static_data.md",
    "1c": "01c_models.md",
    "2a": "02a_api_wrappers.md",
    "2b": "02b_persistence.md",
    "2c": "02c_globals.md",
    "3a": "03a_widgets_pure.md",
    "3b": "03b_theme.md",
    "3c": "03c_widgets_anim.md",
    "4a": "04a_map.md",
    "4b": "04b_horoscope.md",
    "4c": "04c_observe.md",
    "4d": "04d_galaxy.md",
    "4e": "04e_sanctuary.md",
    "4f": "04f_subscreens.md",
    "5":  "05_main.md",
}

# ── データクラス ──────────────────────────────────────────────
@dataclass
class DartSymbol:
    kind: str            # class / mixin / extension / enum / typedef / function
    name: str
    parents: list[str] = field(default_factory=list)  # extends/implements/with
    line: int = 0
    doc: str = ""        # 直前の /// 連続コメント
    signature: str = ""  # 関数なら戻り値 + 引数の素

@dataclass
class DartFile:
    path: str            # apps/solara からの相対
    layer: str
    line_count: int
    file_doc: str = ""   # ファイル先頭の /// or // コメントブロック
    imports: list[str] = field(default_factory=list)
    symbols: list[DartSymbol] = field(default_factory=list)
    navigator_pushes: list[tuple[int, str]] = field(default_factory=list)
    popup_calls: list[tuple[int, str, str]] = field(default_factory=list)  # (line, fn, snippet)
    worker_urls: list[tuple[int, str]] = field(default_factory=list)
    parts: list[str] = field(default_factory=list)              # #5 part 'xxx.dart' ディレクティブ
    exports: list[str] = field(default_factory=list)            # #5 export 'xxx.dart' (barrel 再エクスポート)
    content_sha: str = ""                                       # #6 ハッシュ stamp 用
    glossary_defs: list[str] = field(default_factory=list)       # #7 astro_glossary キー定義
    glossary_refs: list[tuple[int, str]] = field(default_factory=list)  # #7 用語キー参照 (line, key)

@dataclass
class WorkerEndpoint:
    method: str
    path: str
    line: int
    handler_hint: str = ""

@dataclass
class WorkerFile:
    path: str
    line_count: int
    file_doc: str = ""
    endpoints: list[WorkerEndpoint] = field(default_factory=list)
    gemini_calls: list[tuple[int, str]] = field(default_factory=list)
    kv_uses: list[tuple[int, str]] = field(default_factory=list)
    do_uses: list[tuple[int, str]] = field(default_factory=list)
    exports: list[str] = field(default_factory=list)
    content_sha: str = ""  # #6 ハッシュ stamp 用

# ── 層分類 ────────────────────────────────────────────────────
#
# PATH_OVERRIDES — ヒューリスティック誤分類の手動オーバーライド。
#
# 機能インベントリ構築 (2026-05-14) の過程で蓄積された機械分類の盲点を反映。
# 各エントリは「人手版でオーナーが指摘した実態の層」に上書きする。
#
# 追加するときは inventory の該当層「機械分類の盲点」セクションに「解消済」
# と書き、それを根拠にここに足す (= 人手版とツールを必ず同期させる)。
PATH_OVERRIDES: dict[str, str] = {
    # 静的辞書ヘルパー (1a 検出だが本来 1b、層 1a.3 で指摘)
    "utils/astro_glossary.dart": "1b",
    "utils/celestial_event_meanings.dart": "1b",
    "utils/planet_intro.dart": "1b",
    # screens/map/ 配下だが横断 utils 層と機能が同じ (4a 検出だが本来 2a/3b/1b)
    "screens/map/map_astro.dart": "2a",          # /astro/chart ラッパ + scoreAll、Map+Horo 共用
    "screens/map/map_constants.dart": "3b",      # HTML CHART_STYLE / PlanetMeta 純定数
    "screens/map/daily_transit_data.dart": "1b", # AngleFilter + 静的テキスト辞書 1,013 行
    # screens/horoscope/ 配下だが cross-cutting (4b 検出だが本来 3a/1b、層 4b 着手時指摘)
    "screens/horoscope/horo_antique_icons.dart": "3a",      # AntiqueGlyph widget、16 ファイル横断 (Map/Galaxy/no_profile_guide も)
    "screens/horoscope/horo_constants.dart": "1b",          # signs/planetGlyphs/aspectSymbol/fortunePlanets 等静的辞書、13 ファイル横断
    "screens/horoscope/horo_aspect_description.dart": "1b", # planetInfo/aspectInfo 静的辞書 + buildAspectDescription 1 関数、Map+Horo 共用
}


def classify_dart(path: Path, content: str) -> str:
    rel = path.relative_to(LIB).as_posix()
    # オーバーライド (最優先)
    if rel in PATH_OVERRIDES:
        return PATH_OVERRIDES[rel]
    if rel == "main.dart":
        return "5"
    if rel.startswith("models/"):
        return "1c"
    if rel.startswith("theme/"):
        return "3b"
    if rel.startswith("screens/"):
        return _classify_screen(rel, content)
    if rel.startswith("widgets/"):
        return _classify_widget(rel, content)
    if rel.startswith("utils/"):
        return _classify_util(rel, content)
    return "?"

def _classify_screen(rel: str, content: str) -> str:
    if rel.startswith("screens/map/") or rel == "screens/map_screen.dart":
        return "4a"
    if rel.startswith("screens/horoscope/") or rel == "screens/horoscope_screen.dart":
        return "4b"
    if rel.startswith("screens/observe/") or rel == "screens/observe_screen.dart":
        return "4c"
    if rel.startswith("screens/galaxy/") or rel == "screens/galaxy_screen.dart":
        return "4d"
    if rel.startswith("screens/sanctuary/") or rel == "screens/sanctuary_screen.dart":
        return "4e"
    # forecast / locations / philosophy / font_preview などサブ画面
    return "4f"

def _classify_widget(rel: str, content: str) -> str:
    # antique_icons / astro_glyphs は装飾系として 3b 扱い
    name = rel.rsplit("/", 1)[-1]
    if name in ("antique_icons.dart", "horo_antique_icons.dart", "horo_astro_glyphs.dart"):
        return "3b"
    if "AnimationController" in content or "TickerProvider" in content:
        return "3c"
    return "3a"

def _classify_util(rel: str, content: str) -> str:
    imports = re.findall(r"import\s+['\"]([^'\"]+)['\"]", content)
    has_http = any(
        ("dart:io" in imp) or ("http" in imp) or imp.startswith("package:http")
        for imp in imports
    )
    has_storage = any(
        "shared_preferences" in imp or "path_provider" in imp or "sqflite" in imp
        for imp in imports
    )
    # singleton 判定: load()/initialize() を持つ
    has_init = bool(re.search(r"Future\s*<\s*void\s*>?\s*(initialize|load)\s*\(", content))
    has_singleton = bool(re.search(r"static\s+(final|const)\s+\w+\s+(instance|_instance)\b", content)) \
                 or bool(re.search(r"\bfactory\s+\w+\(\)\s*=>\s*\w+", content))
    # 静的データ辞書: 巨大 Map<> リテラル中心 (関数定義が少ない)
    map_literals = len(re.findall(r"\bMap<", content))
    list_literals = len(re.findall(r"\bList<", content))
    function_count = len(re.findall(r"^\s*(?:Future<[^>]+>|void|String|int|double|bool|List<[^>]+>|Map<[^>]+>)\s+\w+\s*\(", content, re.MULTILINE))
    if has_storage:
        return "2b"
    if has_http:
        return "2a"
    if (has_init or has_singleton) and ("Notifier" in content or "Stream" in content or "ValueNotifier" in content or "load" in content):
        return "2c"
    # 静的辞書系: const Map / 大量のリテラル
    if (map_literals + list_literals >= 3 and function_count <= 6) or content.count(",\n") > 200:
        return "1b"
    return "1a"

# ── Dart 抽出 ────────────────────────────────────────────────
DOC_LINE = re.compile(r"^\s*///\s?(.*)$")
SLASH_COMMENT = re.compile(r"^\s*//\s?(.*)$")
IMPORT_RE = re.compile(r"^\s*import\s+['\"]([^'\"]+)['\"]")
EXPORT_RE = re.compile(r"^\s*export\s+['\"]([^'\"]+)['\"]")
# part 'xxx.dart' — ただし `part of 'xxx.dart'` は除外 (こちらは子→親の宣言)
PART_RE = re.compile(r"^\s*part\s+(?!of\b)['\"]([^'\"]+)['\"]")

CLASS_RE = re.compile(
    r"^\s*(?:abstract\s+|sealed\s+|base\s+|interface\s+|final\s+|mixin\s+)*"
    r"(class|mixin|extension|enum|typedef)\s+"
    r"(\w+)"
    r"(?:\s+on\s+(\w+))?"
    r"(?:\s+extends\s+([\w<>,\s]+?))?"
    r"(?:\s+with\s+([\w<>,\s]+?))?"
    r"(?:\s+implements\s+([\w<>,\s]+?))?"
    r"\s*[\{=<]"
)

# 関数: 行頭から始まる
#   modifier* returnType name(...)
# returnType と name を分けるのが難しい (generic 含む) ので、ざっくり拾う
FUNCTION_RE = re.compile(
    r"^\s*"
    r"(?:@\w+\s+)*"                                      # annotation
    r"(?:static\s+|external\s+|future\s+)?"
    r"(?:Future\s*<[^>]*>\s*|void\s+|bool\s+|int\s+|double\s+|String\s+|"
    r"List\s*<[^>]*>\s*|Map\s*<[^>]*>\s*|Set\s*<[^>]*>\s*|Stream\s*<[^>]*>\s*|"
    r"Iterable\s*<[^>]*>\s*|[A-Z]\w*\s*<[^>]*>\s*|[A-Z]\w*\s+|[a-z]\w*\?\s+)"
    r"(_?\w+)\s*"
    r"\(",
    re.MULTILINE,
)

NAV_PUSH_RE = re.compile(r"Navigator\.(push|pushReplacement|pushNamed|pushAndRemoveUntil)\s*\(", re.MULTILINE)
POPUP_RE = re.compile(
    r"\b("
    r"showDialog|showModalBottomSheet|showInfoPopup|showSolaraDatePicker|"
    r"showLineNarrativeSheet|showBottomSheet|showAboutDialog|showMenu"
    r")\s*\(",
    re.MULTILINE,
)

# Dart の Worker URL 表現を網羅:
#   '$solaraWorkerBase/fortune'      (string interpolation, 直名)
#   '$_workerBase/astro/events?...'  (alias 変数 経由)
#   "$workerBase/tiles/..."
#   solaraWorkerBase + '/relocation' (+ 連結)
#   'https://solara-api.solodev-lab.com/...' (直リテラル)
WORKER_URL_RE = re.compile(
    r"""(?:'\$\w*[Ww]orkerBase[^']*')"""
    r"""|(?:"\$\w*[Ww]orkerBase[^"]*")"""
    r"""|(?:\w*[Ww]orkerBase\s*\+\s*['"][^'"]+['"])"""
    r"""|(?:['"]https?://[^'"]*solara[^'"]*['"])"""
)
# Worker URL の中から path 部分のみを抽出する用 (coverage report 用)
WORKER_URL_PATH_RE = re.compile(r"""[Ww]orkerBase[^/\w]*(/[A-Za-z0-9_/\-]+)""")

# #7 astro_glossary 用語辞書対整合 用:
#   定義: 'asc': AstroGlossaryEntry(   (astro_glossary.dart 内のみ)
#   参照: termKey: 'asc'  /  astroGlossary['asc']
GLOSSARY_DEF_RE = re.compile(r"""^\s*['"]([a-z][\w\-]*)['"]\s*:\s*AstroGlossaryEntry\(""")
GLOSSARY_REF_RE = re.compile(
    r"""termKey\s*:\s*['"]([a-z][\w\-]*)['"]"""
    r"""|astroGlossary\[\s*['"]([a-z][\w\-]*)['"]\s*\]"""
)

def extract_dart(path: Path) -> DartFile:
    text = path.read_text(encoding="utf-8", errors="replace")
    lines = text.splitlines()
    rel_to_solara = path.relative_to(ROOT).as_posix()
    layer = classify_dart(path, text)
    df = DartFile(path=rel_to_solara, layer=layer, line_count=len(lines))
    df.content_sha = hashlib.sha1(text.encode("utf-8", errors="replace")).hexdigest()

    # ── ファイル先頭の doc comment ──
    head = []
    for ln in lines:
        if ln.strip() == "":
            if head:
                break
            continue
        m = DOC_LINE.match(ln) or SLASH_COMMENT.match(ln)
        if m:
            head.append(m.group(1))
        else:
            break
    df.file_doc = "\n".join(head).strip()

    # ── import / part / export ──
    for ln in lines[:150]:
        m = IMPORT_RE.match(ln)
        if m:
            df.imports.append(m.group(1))
            continue
        pm = PART_RE.match(ln)
        if pm:
            df.parts.append(pm.group(1))
            continue
        em = EXPORT_RE.match(ln)
        if em:
            df.exports.append(em.group(1))

    # ── class / mixin / extension / enum ──
    pending_doc: list[str] = []
    for i, raw in enumerate(lines):
        doc_m = DOC_LINE.match(raw)
        if doc_m:
            pending_doc.append(doc_m.group(1))
            continue
        # 空行で doc がクリア
        if raw.strip() == "":
            pending_doc = []
            continue

        cls_m = CLASS_RE.match(raw)
        if cls_m:
            kind = cls_m.group(1)
            name = cls_m.group(2)
            parents = []
            for g in cls_m.groups()[2:]:
                if g:
                    parents.extend([p.strip() for p in g.split(",") if p.strip()])
            df.symbols.append(DartSymbol(
                kind=kind, name=name, parents=parents,
                line=i + 1, doc="\n".join(pending_doc).strip(),
                signature=raw.strip(),
            ))
            pending_doc = []
            continue

        # function: ざっくり判定
        fn_m = FUNCTION_RE.match(raw)
        if fn_m:
            name = fn_m.group(1)
            # 制御構文を除外
            if name in {"if", "for", "while", "switch", "return", "throw", "catch", "else"}:
                pending_doc = []
                continue
            df.symbols.append(DartSymbol(
                kind="function",
                name=name,
                line=i + 1,
                doc="\n".join(pending_doc).strip(),
                signature=raw.strip()[:160],
            ))
            pending_doc = []
            continue

        # コードらしい行が来たら doc 候補は捨てる
        if raw.strip().startswith("//") or raw.strip().startswith("/*") or raw.strip().startswith("*"):
            continue
        pending_doc = []

    # ── Navigator / popup / Worker URL / 用語キー ──
    is_glossary_file = rel_to_solara.endswith("utils/astro_glossary.dart")
    for i, raw in enumerate(lines):
        for m in NAV_PUSH_RE.finditer(raw):
            df.navigator_pushes.append((i + 1, raw.strip()[:160]))
        for m in POPUP_RE.finditer(raw):
            df.popup_calls.append((i + 1, m.group(1), raw.strip()[:160]))
        for m in WORKER_URL_RE.finditer(raw):
            df.worker_urls.append((i + 1, m.group(0)[:120]))
        # #7 用語キー参照 (termKey: '...' / astroGlossary['...'])
        for m in GLOSSARY_REF_RE.finditer(raw):
            key = m.group(1) or m.group(2)
            if key:
                df.glossary_refs.append((i + 1, key))
        # #7 用語キー定義 (astro_glossary.dart 内のみ)
        if is_glossary_file:
            dm = GLOSSARY_DEF_RE.match(raw)
            if dm:
                df.glossary_defs.append(dm.group(1))

    return df

# ── Worker JS 抽出 ────────────────────────────────────────────
JS_DOC_BLOCK_RE = re.compile(r"^/\*\*?(.*?)\*/", re.DOTALL)
# Solara Worker の書式:
#   const path = url.pathname;
#   if (path === '/astro/chart' && request.method === 'POST') { ... }
#   if (path.startsWith('/tiles/osm/') && request.method === 'GET') { ... }
# また他形式も保険で拾う。
ROUTE_EQ_RE = re.compile(
    r"""\b(?:path|url\.pathname|pathname)\s*(?:===|==)\s*['"](/[^'"]+)['"]"""
)
ROUTE_STARTSWITH_RE = re.compile(
    r"""\b(?:path|url\.pathname|pathname)\.startsWith\(\s*['"](/[^'"]+)['"]"""
)
ROUTE_VERB_RE = re.compile(
    r"""\.(get|post|put|delete|patch)\(\s*['"](/[^'"]+)['"]"""
)
METHOD_RE = re.compile(
    r"""request\.method\s*(?:===|==)\s*['"](GET|POST|PUT|DELETE|PATCH|OPTIONS)['"]"""
)
GEMINI_RE = re.compile(r"generativelanguage\.googleapis\.com[^'\"\s]*")
KV_RE = re.compile(r"\benv\.\w*KV\w*\b|\bcaches\.default\b|\benv\.[A-Z_]+_KV\b")
DO_RE = re.compile(r"\benv\.[A-Z_]+_DO\b|\bDurableObject\b|\bnewUniqueId\(\)|\bidFromName\(")
JS_EXPORT_RE = re.compile(r"^\s*export\s+(?:default\s+)?(?:async\s+)?(?:function\s+(\w+)|const\s+(\w+)|class\s+(\w+))")
JS_FUNCTION_RE = re.compile(r"^\s*(?:async\s+)?function\s+(\w+)\s*\(", re.MULTILINE)

def extract_worker(path: Path) -> WorkerFile:
    text = path.read_text(encoding="utf-8", errors="replace")
    lines = text.splitlines()
    rel_to_solara = path.relative_to(ROOT).as_posix()
    wf = WorkerFile(path=rel_to_solara, line_count=len(lines))
    wf.content_sha = hashlib.sha1(text.encode("utf-8", errors="replace")).hexdigest()

    # 先頭 JSDoc or // コメントを拾う
    head: list[str] = []
    for ln in lines[:40]:
        s = ln.strip()
        if s.startswith("//"):
            head.append(s.lstrip("/ "))
        elif s.startswith("/*") or s.startswith("*"):
            head.append(s.strip("/* "))
        elif s == "":
            continue
        else:
            break
    wf.file_doc = "\n".join(head).strip()

    # ルート抽出: 同じ行内に method 指定があれば method を併記
    for i, raw in enumerate(lines):
        method_match = METHOD_RE.search(raw)
        line_method = method_match.group(1) if method_match else "?"
        for m in ROUTE_EQ_RE.finditer(raw):
            wf.endpoints.append(WorkerEndpoint(method=line_method, path=m.group(1), line=i + 1))
        for m in ROUTE_STARTSWITH_RE.finditer(raw):
            wf.endpoints.append(WorkerEndpoint(method=line_method, path=m.group(1) + "*", line=i + 1))
        for m in ROUTE_VERB_RE.finditer(raw):
            wf.endpoints.append(WorkerEndpoint(method=m.group(1).upper(), path=m.group(2), line=i + 1))
        for m in GEMINI_RE.finditer(raw):
            wf.gemini_calls.append((i + 1, m.group(0)))
        for m in KV_RE.finditer(raw):
            wf.kv_uses.append((i + 1, m.group(0)))
        for m in DO_RE.finditer(raw):
            wf.do_uses.append((i + 1, m.group(0)))

    # export
    for raw in lines:
        m = JS_EXPORT_RE.match(raw)
        if m:
            name = next((g for g in m.groups() if g), None)
            if name:
                wf.exports.append(name)

    # endpoint の重複を path+line で削る
    seen = set()
    deduped: list[WorkerEndpoint] = []
    for ep in wf.endpoints:
        key = (ep.path, ep.line)
        if key in seen:
            continue
        seen.add(key)
        deduped.append(ep)
    wf.endpoints = deduped

    return wf

# ── #5 import 依存グラフ ──────────────────────────────────────
#
# AST を持たない正規表現ベースなので「関数単位の call graph」は作れない。
# 代わりに **ファイル単位の import 依存グラフ** を構築する。
# Pro 化影響範囲特定には「あるファイルを変更したら誰が影響を受けるか」
# (= 逆依存) が分かれば十分なので、これで実用上の目的は満たせる。
def resolve_import(importer_rel: str, imp: str) -> Optional[str]:
    """relative import を ROOT 相対パスに解決。
       importer_rel: 'lib/screens/map_screen.dart' (ROOT 相対)
       imp: 'map/map_astro.dart' や '../utils/foo.dart' 等
       package:/dart: import は None を返す。"""
    if imp.startswith("package:") or imp.startswith("dart:"):
        return None
    importer_dir = PurePosixPath(importer_rel).parent
    combined = importer_dir / imp
    parts: list[str] = []
    for part in combined.as_posix().split("/"):
        if part == "..":
            if parts:
                parts.pop()
        elif part in ("", "."):
            continue
        else:
            parts.append(part)
    return "/".join(parts)

def build_import_graph(
    dart_files: list[DartFile],
) -> tuple[dict[str, set[str]], dict[str, set[str]]]:
    """forward[path] = そのファイルが import / part / export する ROOT 相対パス集合 (lib 内のみ)
       reverse[path] = そのファイルを import / part / export しているファイル集合
       part / export ディレクティブも edge として扱う
       (part file や barrel 経由ファイルが誤って孤立判定されるのを防ぐ)。"""
    by_path = {df.path: df for df in dart_files}
    forward: dict[str, set[str]] = {df.path: set() for df in dart_files}
    reverse: dict[str, set[str]] = {df.path: set() for df in dart_files}
    for df in dart_files:
        for ref in list(df.imports) + list(df.parts) + list(df.exports):
            resolved = resolve_import(df.path, ref)
            if resolved and resolved in by_path:
                forward[df.path].add(resolved)
                reverse[resolved].add(df.path)
    return forward, reverse

# ── #6 ハッシュ stamp (ファイル変更検知) ──────────────────────
def compute_stamp_diff(
    dart_files: list[DartFile],
    worker_files: list[WorkerFile],
) -> tuple[list[str], list[str], list[str], bool]:
    """前回 extract.py 実行時からの変更ファイルを検出。
       戻り値: (added, removed, changed, had_previous_stamps)
       _stamps.json を新しい内容で上書きする。"""
    stamp_path = OUT_DIR / "_stamps.json"
    new_stamps: dict[str, str] = {}
    for df in dart_files:
        new_stamps[df.path] = df.content_sha
    for wf in worker_files:
        new_stamps[wf.path] = wf.content_sha
    old_stamps: dict[str, str] = {}
    if stamp_path.exists():
        try:
            old_stamps = json.loads(stamp_path.read_text(encoding="utf-8"))
        except Exception:
            old_stamps = {}
    had_previous = bool(old_stamps)
    added = sorted(set(new_stamps) - set(old_stamps))
    removed = sorted(set(old_stamps) - set(new_stamps))
    changed = sorted(
        p for p in new_stamps
        if p in old_stamps and new_stamps[p] != old_stamps[p]
    )
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    stamp_path.write_text(
        json.dumps(new_stamps, indent=2, ensure_ascii=False, sort_keys=True),
        encoding="utf-8",
    )
    return added, removed, changed, had_previous

# ── レポート生成 ──────────────────────────────────────────────
def md_table(headers: list[str], rows: list[list[str]]) -> str:
    out: list[str] = []
    out.append("| " + " | ".join(headers) + " |")
    out.append("| " + " | ".join("---" for _ in headers) + " |")
    for r in rows:
        safe = [str(c).replace("|", "\\|").replace("\n", " ").strip() for c in r]
        out.append("| " + " | ".join(safe) + " |")
    return "\n".join(out)

def render_dart_file(df: DartFile) -> str:
    out: list[str] = []
    out.append(f"### `{df.path}` ({df.line_count} 行)")
    out.append("")
    if df.file_doc:
        out.append("**ファイル先頭コメント:**")
        out.append("")
        out.append("```")
        out.append(df.file_doc)
        out.append("```")
        out.append("")
    # imports
    if df.imports:
        external = [i for i in df.imports if i.startswith("package:")]
        relative = [i for i in df.imports if not i.startswith("package:") and not i.startswith("dart:")]
        builtin = [i for i in df.imports if i.startswith("dart:")]
        if external or relative or builtin:
            out.append(f"**imports:** dart={len(builtin)} / package={len(external)} / relative={len(relative)}")
            if relative:
                out.append("")
                out.append("- relative: " + ", ".join(f"`{r}`" for r in relative))
            out.append("")
    # symbols
    classes = [s for s in df.symbols if s.kind in ("class", "mixin", "extension", "enum", "typedef")]
    functions = [s for s in df.symbols if s.kind == "function"]
    if classes:
        out.append(f"**型定義 ({len(classes)}):**")
        out.append("")
        for s in classes:
            parents = " : " + ", ".join(s.parents) if s.parents else ""
            out.append(f"- L{s.line} `{s.kind} {s.name}{parents}`")
            if s.doc:
                first_line = s.doc.split("\n")[0]
                out.append(f"  - {first_line}")
        out.append("")
    if functions:
        public_fn = [s for s in functions if not s.name.startswith("_")]
        private_fn = [s for s in functions if s.name.startswith("_")]
        out.append(f"**関数 ({len(public_fn)} public + {len(private_fn)} private):**")
        out.append("")
        for s in public_fn[:200]:
            doc_first = s.doc.split("\n")[0] if s.doc else ""
            out.append(f"- L{s.line} `{s.name}()`" + (f" — {doc_first}" if doc_first else ""))
        if len(public_fn) > 200:
            out.append(f"  - … 残り {len(public_fn) - 200} public 関数省略")
        if private_fn:
            out.append("")
            out.append(f"  <details><summary>private 関数 {len(private_fn)} 件</summary>")
            out.append("")
            for s in private_fn[:200]:
                out.append(f"  - L{s.line} `{s.name}()`")
            if len(private_fn) > 200:
                out.append(f"    - … 残り {len(private_fn) - 200} 省略")
            out.append("")
            out.append("  </details>")
        out.append("")
    # 連携系
    if df.navigator_pushes:
        out.append(f"**Navigator.push 等 ({len(df.navigator_pushes)}):**")
        out.append("")
        for line, snippet in df.navigator_pushes[:50]:
            out.append(f"- L{line}: `{snippet}`")
        if len(df.navigator_pushes) > 50:
            out.append(f"  - … 残り {len(df.navigator_pushes) - 50} 省略")
        out.append("")
    if df.popup_calls:
        out.append(f"**Popup/Dialog 呼出 ({len(df.popup_calls)}):**")
        out.append("")
        # 関数名ごとにカウント
        counts: dict[str, int] = {}
        for line, fn, snippet in df.popup_calls:
            counts[fn] = counts.get(fn, 0) + 1
        out.append("- 集計: " + ", ".join(f"`{k}`×{v}" for k, v in sorted(counts.items(), key=lambda x: -x[1])))
        out.append("")
    if df.worker_urls:
        out.append(f"**Worker URL リテラル ({len(df.worker_urls)}):**")
        out.append("")
        for line, snippet in df.worker_urls[:30]:
            out.append(f"- L{line}: `{snippet}`")
        out.append("")
    out.append("")
    return "\n".join(out)

def render_worker_file(wf: WorkerFile) -> str:
    out: list[str] = []
    out.append(f"### `{wf.path}` ({wf.line_count} 行)")
    out.append("")
    if wf.file_doc:
        out.append("**ファイル先頭コメント:**")
        out.append("")
        out.append("```")
        out.append(wf.file_doc[:1200])
        out.append("```")
        out.append("")
    if wf.endpoints:
        out.append(f"**エンドポイント / ルート ({len(wf.endpoints)}):**")
        out.append("")
        rows = [[ep.method, ep.path, f"L{ep.line}"] for ep in wf.endpoints]
        out.append(md_table(["method", "path", "line"], rows))
        out.append("")
    if wf.gemini_calls:
        out.append(f"**Gemini API 呼出 ({len(wf.gemini_calls)}):**")
        out.append("")
        for line, url in wf.gemini_calls[:20]:
            out.append(f"- L{line}: `{url}`")
        out.append("")
    if wf.kv_uses:
        out.append(f"**KV 使用 ({len(wf.kv_uses)} 行):**")
        out.append("")
        out.append("- 出現行: " + ", ".join(f"L{l}" for l, _ in wf.kv_uses[:20]))
        out.append("")
    if wf.do_uses:
        out.append(f"**Durable Object 使用 ({len(wf.do_uses)} 行):**")
        out.append("")
        out.append("- 出現行: " + ", ".join(f"L{l}" for l, _ in wf.do_uses[:20]))
        out.append("")
    if wf.exports:
        out.append(f"**export ({len(wf.exports)}):** " + ", ".join(f"`{e}`" for e in wf.exports))
        out.append("")
    out.append("")
    return "\n".join(out)

# ── 対整合チェック ────────────────────────────────────────────
def build_coverage_report(
    dart_files: list[DartFile],
    worker_files: list[WorkerFile],
    inventory_md_text: Optional[str],
    stamp_diff: Optional[tuple[list[str], list[str], list[str], bool]] = None,
) -> str:
    out: list[str] = []
    out.append("# Solara feature inventory — Coverage Report")
    out.append("")
    out.append("> 機械抽出 ↔ ドキュメント / Worker ↔ Flutter の対整合チェック結果。")
    out.append("> このファイルは extract.py が再生成する。手で編集しないこと。")
    out.append("")

    # ── #3 Worker endpoint vs Flutter URL ──
    worker_paths: set[str] = set()
    for wf in worker_files:
        for ep in wf.endpoints:
            worker_paths.add(ep.path)

    flutter_paths: set[str] = set()
    flutter_url_pattern = re.compile(r"['\"](/[a-zA-Z][\w/\-]+)['\"]")
    for df in dart_files:
        # Worker URL リテラルから path 部分を取り出す
        for _, snippet in df.worker_urls:
            # solaraWorkerBase + '/xxx/yyy'
            m = WORKER_URL_PATH_RE.search(snippet) or re.search(r"""['"](/[^'"$\s?]+)['"]""", snippet)
            if m:
                p = m.group(1)
                # クエリやテンプレ式の除去
                p = p.split("?")[0]
                p = re.sub(r"\$\{[^}]+\}", "", p)
                if p:
                    flutter_paths.add(p)

    out.append("## #3 Worker ↔ Flutter エンドポイント対整合")
    out.append("")
    out.append(f"- Worker 側に定義された path: **{len(worker_paths)}**")
    out.append(f"- Flutter から呼ばれている path リテラル: **{len(flutter_paths)}**")
    out.append("")
    # wildcard (path.startsWith() 由来の `/foo/*`) に対応した集合演算
    def _worker_covers(wp: str, fp: str) -> bool:
        if wp.endswith("*"):
            return fp.startswith(wp[:-1])
        return wp == fp
    worker_only: list[str] = []
    common_set: set[str] = set()
    for wp in sorted(worker_paths):
        if any(_worker_covers(wp, fp) for fp in flutter_paths):
            common_set.add(wp)
        else:
            worker_only.append(wp)
    flutter_only: list[str] = []
    for fp in sorted(flutter_paths):
        if not any(_worker_covers(wp, fp) for wp in worker_paths):
            flutter_only.append(fp)
    common = sorted(common_set)
    out.append("### Worker → Flutter 漏れ (Worker にあるが Flutter から呼出無し)")
    out.append("")
    if worker_only:
        for p in worker_only:
            out.append(f"- `{p}`")
    else:
        out.append("- (該当なし)")
    out.append("")
    out.append("### Flutter → Worker 漏れ (Flutter が呼ぶが Worker に定義無し)")
    out.append("")
    out.append("> 注意: Flutter リテラルにテンプレ展開 `${var}` を含むものは検出精度低。")
    out.append("")
    if flutter_only:
        for p in flutter_only:
            out.append(f"- `{p}`")
    else:
        out.append("- (該当なし)")
    out.append("")
    out.append("### 一致 (= 健全)")
    out.append("")
    if common:
        for p in common:
            out.append(f"- `{p}`")
    else:
        out.append("- (該当なし)")
    out.append("")

    # ── #1/#2 機械抽出 ↔ ドキュメント ──
    out.append("## #1 / #2 機械抽出 ↔ feature_inventory.md (人手版) の対整合")
    out.append("")
    if inventory_md_text is None:
        out.append("> `apps/solara/docs/feature_inventory.md` がまだ存在しない。")
        out.append("> 人手版ファイル作成後に再実行すると、ここに class/関数名の漏れチェック結果が出る。")
    else:
        all_classes: set[str] = set()
        for df in dart_files:
            for s in df.symbols:
                if s.kind in ("class", "mixin", "extension", "enum"):
                    all_classes.add(s.name)
        documented: set[str] = set()
        for tok in re.findall(r"`([A-Z]\w+)`", inventory_md_text):
            documented.add(tok)
        undocumented = sorted(all_classes - documented)
        ghost = sorted(documented - all_classes)
        out.append(f"- 機械抽出した class/mixin/extension/enum: **{len(all_classes)}**")
        out.append(f"- inventory に登場する識別子 (大文字始まり ``backtick``囲み): **{len(documented)}**")
        out.append("")
        out.append(f"### #1 機械にあるが Doc に書かれていない ({len(undocumented)})")
        out.append("")
        if undocumented:
            for n in undocumented[:200]:
                out.append(f"- `{n}`")
            if len(undocumented) > 200:
                out.append(f"- … 残り {len(undocumented) - 200} 省略")
        else:
            out.append("- (該当なし)")
        out.append("")
        out.append(f"### #2 Doc に書いてあるがコードに存在しない (ゴースト記述) ({len(ghost)})")
        out.append("")
        out.append("> 注: Flutter SDK や外部ライブラリの型もここに乗る (誤検出)。")
        out.append("> 真のゴーストはアプリ独自型のみ。実際の Doc 修正対象は手で絞り込む。")
        out.append("")
        if ghost:
            for n in ghost[:200]:
                out.append(f"- `{n}`")
            if len(ghost) > 200:
                out.append(f"- … 残り {len(ghost) - 200} 省略")
        else:
            out.append("- (該当なし)")
        out.append("")

    # ── #4 画面 ↔ 機能集合 ──
    out.append("## #4 画面 ↔ 機能集合")
    out.append("")
    screen_layers = ["4a", "4b", "4c", "4d", "4e", "4f"]
    for layer in screen_layers:
        screen_files = [df for df in dart_files if df.layer == layer]
        if not screen_files:
            continue
        out.append(f"### 層 {layer}: {LAYER_NAMES[layer]}")
        out.append("")
        out.append(f"- ファイル数: {len(screen_files)}")
        # 使用 Worker URL
        used_paths: set[str] = set()
        for df in screen_files:
            for _, snippet in df.worker_urls:
                m = WORKER_URL_PATH_RE.search(snippet) or re.search(r"""['"](/[^'"$\s?]+)['"]""", snippet)
                if m:
                    used_paths.add(m.group(1).split("?")[0])
        # 遷移先 popup
        popups: dict[str, int] = {}
        for df in screen_files:
            for _, fn, _ in df.popup_calls:
                popups[fn] = popups.get(fn, 0) + 1
        nav_pushes = sum(len(df.navigator_pushes) for df in screen_files)
        out.append(f"- Worker URL 呼出: {sorted(used_paths) if used_paths else '(なし)'}")
        out.append(f"- Popup/Dialog: " + (", ".join(f"`{k}`×{v}" for k, v in popups.items()) if popups else "(なし)"))
        out.append(f"- Navigator.push 等: {nav_pushes} 箇所")
        out.append("")

    # ── #5 import 依存グラフ (ファイル単位の call graph 代替) ──
    out.append("## #5 import 依存グラフ (Pro 化影響範囲特定用)")
    out.append("")
    out.append("> 正規表現ベースのため関数単位の call graph は作れない。")
    out.append("> 代わりに **ファイル単位の import 依存グラフ** を構築。")
    out.append("> 「あるファイルを変更したら誰が影響を受けるか」(= 逆依存) が分かれば")
    out.append("> Pro ゲート挿入の影響範囲は特定できる。")
    out.append("")
    forward, reverse = build_import_graph(dart_files)
    layer_of = {df.path: df.layer for df in dart_files}

    # #5a 層間依存マトリクス
    out.append("### #5a 層間依存マトリクス (行 = import する側、列 = される側)")
    out.append("")
    edge_layers = [l for l in LAYER_ORDER if l != "0"]
    matrix: dict[tuple[str, str], int] = {}
    for src, deps in forward.items():
        sl = layer_of.get(src, "?")
        for dst in deps:
            dl = layer_of.get(dst, "?")
            matrix[(sl, dl)] = matrix.get((sl, dl), 0) + 1
    header = ["from\\to"] + edge_layers
    rows: list[list[str]] = []
    for sl in edge_layers:
        row = [sl]
        for dl in edge_layers:
            cnt = matrix.get((sl, dl), 0)
            row.append(str(cnt) if cnt else "·")
        rows.append(row)
    out.append(md_table(header, rows))
    out.append("")
    out.append("> 健全な依存方向は「番号が大きい層 → 小さい層」(上位が下位に依存)。")
    out.append("> 番号が小さい層から大きい層への矢印 (左下三角) は逆流依存の疑い。")
    out.append("")

    # #5b ハブファイル (逆依存が多い = 変更リスク大)
    hub_ranked = sorted(
        ((p, len(rev)) for p, rev in reverse.items() if rev),
        key=lambda x: -x[1],
    )
    out.append("### #5b ハブファイル Top 20 (逆依存が多い = 変更影響大)")
    out.append("")
    out.append("> これらを Pro ゲート化・改修するときは影響範囲が広い。慎重に。")
    out.append("")
    rows = [
        [f"`{p}`", layer_of.get(p, "?"), str(cnt)]
        for p, cnt in hub_ranked[:20]
    ]
    out.append(md_table(["ファイル", "層", "被 import 数"], rows))
    out.append("")

    # #5c 孤立ファイル (誰からも import されない = エントリ点 or 死蔵候補)
    orphans = sorted(
        df.path for df in dart_files
        if not reverse.get(df.path) and df.path != "lib/main.dart"
    )
    out.append(f"### #5c 孤立ファイル ({len(orphans)}) — 誰からも import されない")
    out.append("")
    out.append("> `lib/main.dart` (エントリ点) は除外済。残りは「画面のトップ」か")
    out.append("> 「死蔵コード候補」。後者なら削除候補。")
    out.append("")
    if orphans:
        for p in orphans:
            out.append(f"- `{p}` (層 {layer_of.get(p, '?')})")
    else:
        out.append("- (該当なし)")
    out.append("")

    # ── #6 ハッシュ stamp (ファイル変更検知) ──
    out.append("## #6 ハッシュ stamp — 前回 extract.py 実行からの変更ファイル")
    out.append("")
    out.append("> 各ソースの SHA1 を `_stamps.json` に記録し、差分を検出。")
    out.append("> 変更されたファイルが属する層は、人手版インベントリ章の見直し対象。")
    out.append("")
    if stamp_diff is None:
        out.append("> (stamp 情報が渡されていない — 全層生成時のみ計算)")
    else:
        added, removed, changed, had_previous = stamp_diff
        if not had_previous:
            out.append("- 初回実行: `_stamps.json` のベースラインを作成した。")
            out.append("  次回実行時から変更ファイルがここに表示される。")
        else:
            stamp_layer = {**layer_of}
            for wf in worker_files:
                stamp_layer[wf.path] = "0"
            out.append(f"- 追加: **{len(added)}** / 削除: **{len(removed)}** / 変更: **{len(changed)}**")
            out.append("")
            if changed:
                out.append("### 変更されたファイル (層別)")
                out.append("")
                by_layer: dict[str, list[str]] = {}
                for p in changed:
                    by_layer.setdefault(stamp_layer.get(p, "?"), []).append(p)
                for layer in LAYER_ORDER + ["?"]:
                    if layer in by_layer:
                        out.append(f"- **層 {layer}**: " + ", ".join(f"`{p}`" for p in sorted(by_layer[layer])))
                out.append("")
            if added:
                out.append("### 追加されたファイル")
                out.append("")
                for p in added:
                    out.append(f"- `{p}` (層 {stamp_layer.get(p, '?')})")
                out.append("")
            if removed:
                out.append("### 削除されたファイル")
                out.append("")
                for p in removed:
                    out.append(f"- `{p}`")
                out.append("")
            if not (added or removed or changed):
                out.append("- 変更なし — 全インベントリ章は最新。")
                out.append("")

    # ── #7 astro_glossary 用語辞書対整合 ──
    out.append("## #7 astro_glossary 用語辞書対整合")
    out.append("")
    out.append("> `astro_glossary.dart` の定義キー ↔ コード内の参照 (`termKey:` /")
    out.append("> `astroGlossary[...]`) を突合。死蔵エントリと壊れた用語ラベルを検出。")
    out.append("")
    defined_keys: set[str] = set()
    for df in dart_files:
        defined_keys.update(df.glossary_defs)
    ref_locations: dict[str, list[str]] = {}
    for df in dart_files:
        for line, key in df.glossary_refs:
            ref_locations.setdefault(key, []).append(f"{df.path}:{line}")
    referenced_keys = set(ref_locations)
    unused = sorted(defined_keys - referenced_keys)
    undefined = sorted(referenced_keys - defined_keys)
    out.append(f"- 定義キー数: **{len(defined_keys)}** / 参照キー数 (リテラルのみ): **{len(referenced_keys)}**")
    out.append("")
    out.append("> ⚠️ 検出できるのは **リテラル参照のみ** (`termKey: 'asc'` / `astroGlossary['asc']`)。")
    out.append("> 次のケースは検出不可なので #7a を「確定した死蔵」と即断しないこと:")
    out.append(">  - `map_line_narrative_sheet.dart` の `_glossaryKey` getter (動的計算)")
    out.append(">  - `AstroTermLabel(termKey: someVariable)` のような変数渡し")
    out.append("> #7a は **死蔵候補** であり、削除前に grep で変数経由参照を確認すること。")
    out.append("")
    out.append(f"### #7a 定義済みだが未参照 ({len(unused)}) — 死蔵 glossary エントリ候補")
    out.append("")
    out.append("> 上記⚠️の通り、変数経由参照は検出できていない。確定前に要 grep。")
    out.append("")
    if unused:
        for k in unused:
            out.append(f"- `{k}`")
    else:
        out.append("- (該当なし)")
    out.append("")
    out.append(f"### #7b 参照されているが未定義 ({len(undefined)}) — 壊れた用語ラベル")
    out.append("")
    if undefined:
        for k in undefined:
            locs = ", ".join(ref_locations.get(k, [])[:5])
            out.append(f"- `{k}` — 参照元: {locs}")
    else:
        out.append("- (該当なし)")
    out.append("")

    return "\n".join(out)

# ── 層別レポート出力 ──────────────────────────────────────────
def emit_layer_md(layer: str, dart_files: list[DartFile], worker_files: list[WorkerFile]) -> str:
    title = LAYER_NAMES[layer]
    out: list[str] = []
    out.append(f"# 層 {layer}: {title}")
    out.append("")
    out.append("> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。")
    out.append("> 手で編集しても次の再生成で上書きされる。")
    out.append("")
    if layer == "0":
        if not worker_files:
            out.append("(Worker ファイルが見つかりません)")
            return "\n".join(out)
        out.append(f"## サマリ")
        out.append("")
        total_endpoints = sum(len(wf.endpoints) for wf in worker_files)
        total_gemini = sum(len(wf.gemini_calls) for wf in worker_files)
        total_kv = sum(len(wf.kv_uses) for wf in worker_files)
        total_do = sum(len(wf.do_uses) for wf in worker_files)
        out.append(f"- ファイル数: {len(worker_files)}")
        out.append(f"- エンドポイント総数: {total_endpoints}")
        out.append(f"- Gemini 呼出箇所: {total_gemini}")
        out.append(f"- KV 使用: {total_kv} 行 / Durable Object 使用: {total_do} 行")
        out.append("")
        out.append("## ファイル別")
        out.append("")
        for wf in worker_files:
            out.append(render_worker_file(wf))
        return "\n".join(out)
    # 通常の Dart 層
    target = [df for df in dart_files if df.layer == layer]
    if not target:
        out.append("(該当ファイルなし)")
        return "\n".join(out)
    out.append(f"## サマリ")
    out.append("")
    total_lines = sum(df.line_count for df in target)
    total_classes = sum(len([s for s in df.symbols if s.kind in ("class", "mixin", "extension", "enum")]) for df in target)
    total_functions = sum(len([s for s in df.symbols if s.kind == "function"]) for df in target)
    total_nav = sum(len(df.navigator_pushes) for df in target)
    total_popup = sum(len(df.popup_calls) for df in target)
    total_worker = sum(len(df.worker_urls) for df in target)
    out.append(f"- ファイル数: {len(target)} / 総行数: {total_lines}")
    out.append(f"- class/mixin/extension/enum: {total_classes}")
    out.append(f"- 関数 (top-level + method の素拾い): {total_functions}")
    out.append(f"- Navigator.push 等: {total_nav}")
    out.append(f"- Popup/Dialog 呼出: {total_popup}")
    out.append(f"- Worker URL リテラル: {total_worker}")
    out.append("")
    out.append("## ファイル別")
    out.append("")
    for df in sorted(target, key=lambda d: d.path):
        out.append(render_dart_file(df))
    return "\n".join(out)

def emit_index_md(dart_files: list[DartFile], worker_files: list[WorkerFile]) -> str:
    out: list[str] = []
    out.append("# Solara Feature Inventory — Index")
    out.append("")
    out.append("> Solara の機械抽出機能インベントリ。")
    out.append("> 各層のファイルは `extract.py` が自動生成する raw 素材。")
    out.append("> 人手版 (機能の意味を整理した版) は `../feature_inventory.md` を参照。")
    out.append("")
    out.append("## 層構成")
    out.append("")
    out.append(md_table(
        ["層", "名称", "ファイル数", "Markdown"],
        [
            [
                layer,
                LAYER_NAMES[layer],
                str(len(worker_files) if layer == "0" else len([d for d in dart_files if d.layer == layer])),
                f"[{LAYER_FILENAMES[layer]}]({LAYER_FILENAMES[layer]})",
            ]
            for layer in LAYER_ORDER
        ],
    ))
    out.append("")
    out.append("## 全体統計")
    out.append("")
    out.append(f"- Dart ファイル: {len(dart_files)}")
    out.append(f"- Worker JS ファイル: {len(worker_files)}")
    out.append(f"- Worker エンドポイント総数: {sum(len(wf.endpoints) for wf in worker_files)}")
    out.append(f"- Dart class/mixin/extension/enum 総数: {sum(len([s for s in df.symbols if s.kind in ('class', 'mixin', 'extension', 'enum')]) for df in dart_files)}")
    out.append(f"- Dart 関数総数 (素拾い): {sum(len([s for s in df.symbols if s.kind == 'function']) for df in dart_files)}")
    out.append("")
    out.append("## 対整合チェック")
    out.append("")
    out.append("- [coverage_report.md](coverage_report.md) を参照。")
    out.append("- #1 機械 → Doc / #2 Doc → 機械 / #3 Worker ↔ Flutter / #4 画面 ↔ 機能 を集計済み。")
    out.append("- #5 import 依存グラフ / #6 ハッシュ stamp / #7 astro_glossary 対整合 も集計済み。")
    out.append("")
    out.append("## 未分類ファイル (要 override)")
    out.append("")
    unclassified = [df for df in dart_files if df.layer == "?"]
    if unclassified:
        for df in unclassified:
            out.append(f"- `{df.path}`")
    else:
        out.append("- (なし)")
    out.append("")
    return "\n".join(out)

# ── メイン ────────────────────────────────────────────────────
def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--layer", action="append", help="特定の層だけ出力 (例: 0, 1a, 4a)。複数指定可。")
    ap.add_argument("--dry-run", action="store_true", help="ファイル書き出しせずサマリだけ表示")
    args = ap.parse_args()

    target_layers: Optional[set[str]] = set(args.layer) if args.layer else None

    print(f"[extract] LIB = {LIB}")
    print(f"[extract] WORKER_SRC = {WORKER_SRC}")
    print(f"[extract] OUT_DIR = {OUT_DIR}")

    # Dart ファイル抽出
    dart_files: list[DartFile] = []
    for f in sorted(LIB.rglob("*.dart")):
        if f.name.endswith(".g.dart") or f.name.endswith(".freezed.dart"):
            continue
        try:
            df = extract_dart(f)
            dart_files.append(df)
        except Exception as e:
            print(f"[extract] ERROR Dart {f}: {e}")

    # Worker JS 抽出
    worker_files: list[WorkerFile] = []
    if WORKER_SRC.exists():
        for f in sorted(WORKER_SRC.rglob("*.js")):
            try:
                wf = extract_worker(f)
                worker_files.append(wf)
            except Exception as e:
                print(f"[extract] ERROR Worker {f}: {e}")

    # サマリ
    print(f"[extract] Dart files: {len(dart_files)}")
    print(f"[extract] Worker files: {len(worker_files)}")
    layer_counts: dict[str, int] = {}
    for df in dart_files:
        layer_counts[df.layer] = layer_counts.get(df.layer, 0) + 1
    for layer in LAYER_ORDER:
        if layer == "0":
            print(f"[extract]   layer {layer:<3}: worker={len(worker_files)}")
        else:
            print(f"[extract]   layer {layer:<3}: dart={layer_counts.get(layer, 0)}")
    if layer_counts.get("?", 0) > 0:
        print(f"[extract]   layer  ? : dart={layer_counts['?']}  (未分類)")
    print(f"[extract] Worker endpoints: {sum(len(wf.endpoints) for wf in worker_files)}")
    total_classes = sum(len([s for s in df.symbols if s.kind in ('class', 'mixin', 'extension', 'enum')]) for df in dart_files)
    total_fns = sum(len([s for s in df.symbols if s.kind == 'function']) for df in dart_files)
    print(f"[extract] classes/mixins/extensions/enums: {total_classes}")
    print(f"[extract] functions (rough): {total_fns}")

    if args.dry_run:
        print("[extract] --dry-run: ファイル書き出しスキップ")
        return 0

    OUT_DIR.mkdir(parents=True, exist_ok=True)

    # 層別 md
    for layer in LAYER_ORDER:
        if target_layers and layer not in target_layers:
            continue
        text = emit_layer_md(layer, dart_files, worker_files)
        out_path = OUT_DIR / LAYER_FILENAMES[layer]
        out_path.write_text(text, encoding="utf-8")
        print(f"[extract] wrote {out_path}")

    # _index.md
    if not target_layers:
        idx_path = OUT_DIR / "_index.md"
        idx_path.write_text(emit_index_md(dart_files, worker_files), encoding="utf-8")
        print(f"[extract] wrote {idx_path}")

    # coverage_report.md
    if not target_layers:
        inventory_path = ROOT / "docs" / "feature_inventory.md"
        inventory_text = inventory_path.read_text(encoding="utf-8") if inventory_path.exists() else None
        # #6 ハッシュ stamp: 前回実行からの変更を検出 (_stamps.json を更新)
        stamp_diff = compute_stamp_diff(dart_files, worker_files)
        added, removed, changed, had_previous = stamp_diff
        if had_previous:
            print(f"[extract] stamp diff: +{len(added)} -{len(removed)} ~{len(changed)}")
        else:
            print(f"[extract] stamp: baseline created (_stamps.json)")
        cov_path = OUT_DIR / "coverage_report.md"
        cov_path.write_text(
            build_coverage_report(dart_files, worker_files, inventory_text, stamp_diff),
            encoding="utf-8",
        )
        print(f"[extract] wrote {cov_path}")

    return 0

if __name__ == "__main__":
    sys.exit(main())
