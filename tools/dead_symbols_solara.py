#!/usr/bin/env python3
"""Solara lib/ 配下のトップレベル「未参照記号」検出。

apps/solara/tools/find_unused_code.py の改良版。flutter analyze の unused_*
警告は import / local variable レベルしか拾わないので、定義はあるが他のどこ
からも呼び出されない top-level 関数 / クラス / typedef / extension /
const を網羅的に検出する。

検出フロー:
  1. lib/ 全 .dart ファイルを走査して top-level 定義を抽出。
     - function / Future-returning / getter / setter
     - class / mixin / enum / extension / typedef
     - top-level const / final
  2. 各定義名を lib/ 全 .dart で grep し、定義行を除いた出現回数を数える。
  3. private (_ prefix) の記号:
     - 定義ファイル + その part files + ライブラリ親 (part of) の中だけ検索
  4. public 記号:
     - lib/ 全体で検索 (テスト/別パッケージから import される可能性も考慮)
  5. Flutter framework が呼ぶ override (build/dispose/initState/paint/
     shouldRepaint/didUpdateWidget/...) は always-used とみなす
  6. 結果は 3 段階に分類:
     - DEAD: 参照 0 件 (削除候補)
     - SUSPECT: 参照 1 件 (定義行と紐づくコメント等の可能性)
     - OK: 参照 2 件以上

正規表現ベースなので動的ディスパッチ・reflection・assets/key 系は誤検知あり。
最終判断は人間レビュー。
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from typing import Optional


# ──────────────── Flutter 「常に呼ばれる」override 名 ────────────────

FRAMEWORK_OVERRIDES = {
    # State / StatefulWidget
    'initState', 'dispose', 'didUpdateWidget', 'didChangeDependencies',
    'reassemble', 'deactivate', 'activate',
    'build', 'createState', 'createElement',
    # CustomPainter
    'paint', 'shouldRepaint', 'shouldRebuildSemantics',
    # ChangeNotifier / Listenable
    'notifyListeners',
    # StatelessWidget
    'createRenderObject', 'updateRenderObject',
    # SingleTickerProvider 等
    'createTicker',
    # equatable / value class
    'hashCode', '==', 'toString', 'noSuchMethod',
    # main
    'main',
    # Localization / route
    'didPush', 'didPushNext', 'didPopNext', 'didPop',
}

# 名前自体は generic だが Flutter では framework 呼出 + 型互換のため残す
RESERVED_PUBLIC_NAMES = FRAMEWORK_OVERRIDES | {
    # Pages / Routes (Flutter Navigator)
    'Page', 'Route',
}


# ──────────────── データモデル ────────────────

@dataclass
class SymbolDef:
    file: str               # lib/からの相対パス
    line: int
    name: str
    kind: str               # 'function' | 'class' | 'mixin' | 'enum' | 'extension' | 'typedef' | 'const'
    is_private: bool
    library_root: str       # part of の場合は親ファイル、それ以外は self
    parts: list[str] = field(default_factory=list)  # library_root が持つ全 part files


# ──────────────── 走査 / 抽出 ────────────────

CLASS_LIKE_RE = re.compile(
    r'^\s*(?:abstract\s+)?(?:base\s+|interface\s+|final\s+|sealed\s+|mixin\s+)?'
    r'(class|mixin|enum|extension|typedef)\s+'
    r'([A-Za-z_]\w*)',
    re.MULTILINE,
)

# top-level 関数 (戻り値型 + name + ()), private/public 両方拾う
FUNCTION_RE = re.compile(
    r'^(?:Future|Stream|Map|List|Set|Iterable|String|int|double|bool|void|num|dynamic|FutureOr|Object|'
    r'[A-Z]\w*|_[A-Za-z]\w*)[\w<>?,\s\.]*\s+'
    r'([A-Za-z_]\w*)\s*\(',
    re.MULTILINE,
)

# 関数 (型省略パターン: `myFn(...) => ...` / `myFn(...) {`) — Dart 慣習として戻り値型省略は少ない
# Solara では使ってないのでスキップ

# top-level const / final
CONST_RE = re.compile(
    r'^(?:const|final)\s+(?:[\w<>?,\s\.]+\s+)?([A-Za-z_]\w*)\s*=',
    re.MULTILINE,
)

PART_OF_RE = re.compile(r"^part\s+of\s+['\"]([^'\"]+)['\"]\s*;", re.MULTILINE)
PART_RE = re.compile(r"^part\s+['\"]([^'\"]+)['\"]\s*;", re.MULTILINE)


def walk_lib(lib_dir: str) -> list[str]:
    paths = []
    for root, _, files in os.walk(lib_dir):
        for f in files:
            if f.endswith('.dart'):
                paths.append(os.path.join(root, f))
    return paths


def parse_file(path: str, lib_dir: str) -> tuple[list[SymbolDef], Optional[str], list[str]]:
    """1 ファイルからトップレベル記号を抽出。"""
    with open(path, encoding='utf-8') as f:
        text = f.read()

    rel = os.path.relpath(path, lib_dir).replace('\\', '/')
    syms: list[SymbolDef] = []

    # part of 解決
    part_of_target: Optional[str] = None
    m = PART_OF_RE.search(text)
    if m:
        # 'horoscope_screen.dart' を相対パスで保持
        target = m.group(1)
        # 親ファイルからの相対パス → lib/ 相対に正規化
        target_path = os.path.normpath(os.path.join(os.path.dirname(rel), target)).replace('\\', '/')
        part_of_target = target_path

    parts: list[str] = []
    for m in PART_RE.finditer(text):
        parts.append(os.path.normpath(os.path.join(os.path.dirname(rel), m.group(1))).replace('\\', '/'))

    # 行番号取得用
    def line_of(pos: int) -> int:
        return text.count('\n', 0, pos) + 1

    def emit(name: str, kind: str, pos: int):
        if not name or name.startswith('__'):
            return
        syms.append(SymbolDef(
            file=rel,
            line=line_of(pos),
            name=name,
            kind=kind,
            is_private=name.startswith('_'),
            library_root=part_of_target or rel,
            parts=parts,
        ))

    # トップレベル定義のみ (インデントなし) を抽出するため、行頭固定
    for m in CLASS_LIKE_RE.finditer(text):
        kind_word = m.group(1)
        # typedef / class / mixin / enum / extension
        kind = kind_word
        emit(m.group(2), kind, m.start())

    for m in FUNCTION_RE.finditer(text):
        name = m.group(1)
        # クラス内メソッドは行頭インデントがあって除外される (regex は行頭固定)
        # コンストラクタ呼出のような Class(args) と区別: `Class(` パターンで戻り値型がない場合は
        # 戻り値型必須の正規表現で除外済
        emit(name, 'function', m.start())

    for m in CONST_RE.finditer(text):
        emit(m.group(1), 'const', m.start())

    return syms, part_of_target, parts


# ──────────────── 参照カウント ────────────────

def build_files_text(paths: list[str], lib_dir: str) -> dict[str, str]:
    out: dict[str, str] = {}
    for p in paths:
        rel = os.path.relpath(p, lib_dir).replace('\\', '/')
        with open(p, encoding='utf-8') as f:
            out[rel] = f.read()
    return out


def count_refs(name: str, scope_files: list[str], files_text: dict[str, str], def_file: str, def_line: int) -> int:
    """name の参照回数を scope_files の中で数える (定義行を除外)。"""
    pat = re.compile(rf'\b{re.escape(name)}\b')
    total = 0
    for fp in scope_files:
        if fp not in files_text:
            continue
        text = files_text[fp]
        for m in pat.finditer(text):
            line = text.count('\n', 0, m.start()) + 1
            if fp == def_file and line == def_line:
                continue
            total += 1
    return total


# ──────────────── 分析メイン ────────────────

@dataclass
class Result:
    sym: SymbolDef
    refs: int


def analyze(lib_dir: str) -> list[Result]:
    paths = walk_lib(lib_dir)
    files_text = build_files_text(paths, lib_dir)

    # ① 全 symbol を集める
    all_syms: list[SymbolDef] = []
    # part-of map: parent_rel → list[child_rel]
    parts_map: dict[str, list[str]] = defaultdict(list)
    for p in paths:
        syms, part_of_target, _parts = parse_file(p, lib_dir)
        all_syms.extend(syms)
        if part_of_target:
            rel = os.path.relpath(p, lib_dir).replace('\\', '/')
            parts_map[part_of_target].append(rel)

    # ② 各 symbol の参照スコープを決め、refs をカウント
    results: list[Result] = []
    public_scope = list(files_text.keys())  # lib/ 全体

    for sym in all_syms:
        # framework override は無条件 OK
        if sym.name in RESERVED_PUBLIC_NAMES:
            continue
        # `==` operator など特殊 (出ないはず)
        if not re.match(r'[A-Za-z_]\w*$', sym.name):
            continue

        if sym.is_private:
            # 定義ファイル + part of 親 + その親が抱える全 part files
            scope = {sym.file}
            if sym.library_root != sym.file:
                # part-of の場合、library_root が親
                scope.add(sym.library_root)
                scope.update(parts_map.get(sym.library_root, []))
            else:
                # 親ファイル自身。自分に紐づく part files
                scope.update(parts_map.get(sym.file, []))
            refs = count_refs(sym.name, sorted(scope), files_text, sym.file, sym.line)
        else:
            refs = count_refs(sym.name, public_scope, files_text, sym.file, sym.line)

        results.append(Result(sym=sym, refs=refs))

    return results


# ──────────────── レポート ────────────────

def render(results: list[Result], out_path: str):
    dead = [r for r in results if r.refs == 0]
    suspect = [r for r in results if r.refs == 1]
    dead.sort(key=lambda r: (r.sym.file, r.sym.line))
    suspect.sort(key=lambda r: (r.sym.file, r.sym.line))

    with open(out_path, 'w', encoding='utf-8') as f:
        f.write('# Solara dead-symbol report\n\n')
        f.write('Generated by `tools/dead_symbols_solara.py`.\n\n')
        f.write('正規表現ベースの静的解析ヒューリスティック。reflection / 動的ディスパッチ /\n')
        f.write('文字列キーで間接参照されるものは誤検知の可能性あり。最終判断は人間レビュー。\n\n')
        f.write('## Summary\n\n')
        f.write(f'| 段階 | 件数 |\n|---|---:|\n')
        f.write(f'| DEAD (参照 0) | {len(dead)} |\n')
        f.write(f'| SUSPECT (参照 1) | {len(suspect)} |\n')
        f.write(f'| 全 top-level 記号 | {len(results)} |\n\n')

        f.write('## DEAD (削除候補, 参照 0 件)\n\n')
        if not dead:
            f.write('_(なし)_\n\n')
        else:
            for r in dead:
                priv = '🔒' if r.sym.is_private else '🌐'
                f.write(f'- {priv} `{r.sym.file}:{r.sym.line}` `{r.sym.kind}` `{r.sym.name}`\n')

        f.write('\n## SUSPECT (要確認, 参照 1 件)\n\n')
        if not suspect:
            f.write('_(なし)_\n\n')
        else:
            for r in suspect:
                priv = '🔒' if r.sym.is_private else '🌐'
                f.write(f'- {priv} `{r.sym.file}:{r.sym.line}` `{r.sym.kind}` `{r.sym.name}`\n')


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    parser = argparse.ArgumentParser()
    parser.add_argument('--lib', default=os.path.join(here, '..', 'apps', 'solara', 'lib'))
    parser.add_argument('--out', default=os.path.join(here, 'dead_symbols_report.md'))
    args = parser.parse_args()
    lib_dir = os.path.abspath(args.lib)
    print(f'lib: {lib_dir}', file=sys.stderr)
    results = analyze(lib_dir)
    render(results, args.out)
    dead = sum(1 for r in results if r.refs == 0)
    suspect = sum(1 for r in results if r.refs == 1)
    print(f'symbols: {len(results)}, DEAD: {dead}, SUSPECT: {suspect}', file=sys.stderr)
    print(f'report: {args.out}', file=sys.stderr)


if __name__ == '__main__':
    main()
