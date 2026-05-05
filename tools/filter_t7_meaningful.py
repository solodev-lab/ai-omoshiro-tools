#!/usr/bin/env python3
"""T7 catalogue から「自然言語的に意味が似ている」関数ペアを抽出する後処理。

flutter_duplicate_audit.py が出力した T7 doc-similar pairs (496 件) のうち、
ほとんどが initState ⇄ initState のような framework lifecycle method 同士で、
共通キーワードが "init, state" だけのノイズ。

このスクリプトは下記の足切りで「本当に機能が似ていそう」なペアだけ残す:

  1. 同名関数ペアは除外 (initState ⇄ initState など)
  2. Flutter lifecycle / generic builder 系の名前は両方除外
  3. doc_jp も comment_keywords_jp も空のエントリは除外
     (= 自然言語シグナルがゼロのもの)
  4. 共通語に generic 単語 (build, init, state, on, tap, value, widget,
     flutter, context...) のみは除外
  5. 共通語が 4 個以上 + Jaccard ≥ 0.40

候補は Markdown レポートに出力。閾値は CLI で調整可能。
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from typing import Iterable

# YAML を依存ゼロで読むため簡易パーサ (catalogue は安定構造のため十分)
try:
    import yaml  # type: ignore
    HAS_YAML = True
except ImportError:
    HAS_YAML = False


# ──────────────── 除外語リスト ────────────────

LIFECYCLE_NAMES = {
    'initState', 'dispose', 'didUpdateWidget', 'didChangeDependencies',
    'reassemble', 'deactivate', 'activate', 'build', 'createState',
    'shouldRepaint', 'paint',
}

# 同じ "name_words_en" を共有する関数同士の足切りに使う
GENERIC_NAME_WORDS = {
    'build', 'init', 'state', 'dispose', 'on', 'tap', 'changed', 'pressed',
    'context', 'widget', 'value', 'set', 'get', 'is', 'has', 'with', 'to',
    'from', 'of', 'for', 'and', 'or', 'the', 'a',
    'create', 'update', 'remove', 'add',  # too generic alone
}

# doc_jp / comment_keywords_jp に出現する generic な日本語語
GENERIC_JP_WORDS = {
    '関数', 'メソッド', 'クラス', '実装', '処理', '取得', '設定',
    'する', 'いる', 'こと', 'もの', 'ため', 'よう', '場合',
}

# Dart/Flutter の API 語
GENERIC_DART_API = {
    'flutter', 'material', 'widget', 'state', 'context', 'build',
    'override', 'super', 'final', 'const', 'static', 'void',
    'string', 'int', 'double', 'bool', 'list', 'map', 'set',
    'future', 'stream', 'function', 'callback',
}


# ──────────────── YAML 読み (依存ゼロ fallback) ────────────────

def parse_yaml_simple(text: str) -> list[dict]:
    """カタログ YAML 専用の簡易パーサ。ネスト浅い & 構造固定なので動く。

    対応形式:
      functions:
        - id: "..."
          file: "..."
          line: 12
          name: "..."
          signature: "..."
          doc_jp: "..."
          name_words_en: ["a", "b"]
          comment_keywords_jp: ["x", "y"]
    """
    entries = []
    cur: dict | None = None
    in_functions = False
    for raw in text.splitlines():
        line = raw.rstrip()
        if line.strip().startswith('#'):
            continue
        if line.strip() == 'functions:':
            in_functions = True
            continue
        if not in_functions:
            continue
        if line.startswith('  - '):
            if cur is not None:
                entries.append(cur)
            cur = {}
            kv = line[4:].split(':', 1)
            if len(kv) == 2:
                cur[kv[0].strip()] = _parse_value(kv[1].strip())
        elif line.startswith('    ') and ':' in line:
            kv = line.strip().split(':', 1)
            if cur is None:
                continue
            cur[kv[0].strip()] = _parse_value(kv[1].strip())
    if cur is not None:
        entries.append(cur)
    return entries


def _parse_value(v: str):
    v = v.strip()
    if v.startswith('"') and v.endswith('"'):
        return v[1:-1]
    if v.startswith('[') and v.endswith(']'):
        inner = v[1:-1].strip()
        if not inner:
            return []
        items = []
        for it in re.findall(r'"([^"]*)"', inner):
            items.append(it)
        return items
    try:
        return int(v)
    except ValueError:
        return v


# ──────────────── 単語抽出 + フィルタ ────────────────

def words_of(entry: dict, drop_generic: bool = True) -> set[str]:
    """entry から比較用の word set を作る。"""
    words: set[str] = set()
    for w in entry.get('name_words_en', []) or []:
        words.add(w.lower())
    for w in entry.get('comment_keywords_jp', []) or []:
        words.add(w)
    doc = entry.get('doc_jp', '') or ''
    for w in re.findall(r'[a-zA-Z_]\w+|[぀-ゟ゠-ヿー一-鿿]{2,}', doc):
        words.add(w.lower() if w.isascii() else w)
    if drop_generic:
        words = {
            w for w in words
            if len(w) >= 2
            and w not in GENERIC_NAME_WORDS
            and w not in GENERIC_JP_WORDS
            and w not in GENERIC_DART_API
        }
    return words


def has_real_signal(entry: dict) -> bool:
    """自然言語シグナルが実体あるか (空 doc + generic only な name は除外)。"""
    if entry.get('doc_jp') or entry.get('comment_keywords_jp'):
        return True
    name_words = entry.get('name_words_en', []) or []
    non_generic = [
        w for w in name_words
        if w.lower() not in GENERIC_NAME_WORDS and len(w) >= 3
    ]
    return len(non_generic) >= 2


# ──────────────── 比較 ────────────────

def find_meaningful(
    catalogue: list[dict],
    *,
    threshold: float,
    min_overlap: int,
) -> list[tuple]:
    pairs = []
    word_sets = []
    for entry in catalogue:
        if entry.get('name') in LIFECYCLE_NAMES:
            word_sets.append((entry, set()))
            continue
        if not has_real_signal(entry):
            word_sets.append((entry, set()))
            continue
        ws = words_of(entry)
        if len(ws) < 3:
            word_sets.append((entry, set()))
            continue
        word_sets.append((entry, ws))

    for i in range(len(word_sets)):
        ea, wa = word_sets[i]
        if not wa:
            continue
        for j in range(i + 1, len(word_sets)):
            eb, wb = word_sets[j]
            if not wb:
                continue
            if ea['name'] == eb['name']:
                continue
            inter = wa & wb
            if len(inter) < min_overlap:
                continue
            jac = len(inter) / len(wa | wb)
            if jac < threshold:
                continue
            pairs.append((jac, len(inter), ea, eb, sorted(inter)))
    pairs.sort(key=lambda x: (-x[0], -x[1]))
    return pairs


# ──────────────── 出力 ────────────────

def render_markdown(pairs: list[tuple], out_path: str, *, threshold: float, min_overlap: int):
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write('# T7 doc-similar (filtered for meaningful pairs)\n\n')
        f.write(f'- threshold: Jaccard ≥ {threshold}\n')
        f.write(f'- min keyword overlap: {min_overlap}\n')
        f.write(f'- excluded: same-name pairs, lifecycle methods, empty docs\n')
        f.write(f'- pairs found: **{len(pairs)}**\n\n')
        f.write('Generated by `tools/filter_t7_meaningful.py` from `solara_function_catalogue.yaml`.\n\n')

        for idx, (jac, n_inter, ea, eb, common) in enumerate(pairs, 1):
            f.write(f'## #{idx} — Jaccard ≈ {jac:.2f} (overlap {n_inter})\n\n')
            f.write(f'- A: `{ea["file"]}:{ea["line"]}` `{ea["name"]}`\n')
            if ea.get('doc_jp'):
                doc = ea["doc_jp"]
                doc_short = doc[:80] + ('...' if len(doc) > 80 else '')
                f.write(f'  - JP: {doc_short}\n')
            f.write(f'- B: `{eb["file"]}:{eb["line"]}` `{eb["name"]}`\n')
            if eb.get('doc_jp'):
                doc = eb["doc_jp"]
                doc_short = doc[:80] + ('...' if len(doc) > 80 else '')
                f.write(f'  - JP: {doc_short}\n')
            f.write(f'- Common keywords: `{", ".join(common)}`\n\n')


# ──────────────── main ────────────────

def main():
    parser = argparse.ArgumentParser()
    here = os.path.dirname(os.path.abspath(__file__))
    parser.add_argument('--catalogue', default=os.path.join(here, 'solara_function_catalogue.yaml'))
    parser.add_argument('--out', default=os.path.join(here, 't7_meaningful_pairs.md'))
    parser.add_argument('--threshold', type=float, default=0.40,
                        help='Minimum Jaccard similarity (default 0.40)')
    parser.add_argument('--min-overlap', type=int, default=4,
                        help='Minimum number of overlapping keywords (default 4)')
    args = parser.parse_args()

    with open(args.catalogue, encoding='utf-8') as f:
        text = f.read()

    if HAS_YAML:
        data = yaml.safe_load(text)
        catalogue = data.get('functions', [])
    else:
        catalogue = parse_yaml_simple(text)

    print(f'catalogue entries: {len(catalogue)}', file=sys.stderr)

    pairs = find_meaningful(catalogue, threshold=args.threshold, min_overlap=args.min_overlap)
    print(f'meaningful pairs: {len(pairs)}', file=sys.stderr)

    render_markdown(pairs, args.out, threshold=args.threshold, min_overlap=args.min_overlap)
    print(f'report: {args.out}', file=sys.stderr)


if __name__ == '__main__':
    main()
