"""
flutter_duplicate_audit.py — Static audit for code duplication & similarity in Flutter projects.

7 Tier 検出 (DCM Pro 手法 + 業界研究 + Solara 特化):
  T1 Exact duplicate         空白・コメント正規化後の hash 完全一致
  T2 Structural duplicate    変数名・リテラル抽象化後の hash 一致 (DCM "変数名変更耐性" 再現)
  T3 Near duplicate          MinHash + Jaccard 類似度 ≥ 閾値 (業界標準 LSH)
  T4 Anti-pattern (Solara)   設計違反パターン直接 regex (合算 / dominant tint / 等)
  T5 Hardcoded value sprawl  同じ Color / 文字列が N 箇所以上に散在
  T6 Repeated boilerplate    Container+BoxDecoration / 16 方位 loop 等の反復
  T7 Functionality catalogue 関数の docstring + 名前を EN/JP で抽出、自然言語類似度で機能重複検出

Usage:
  python tools/flutter_duplicate_audit.py [--target apps/solara/lib] [--out report.md]
  python tools/flutter_duplicate_audit.py --catalogue-out tools/solara_function_catalogue.yaml
  python tools/flutter_duplicate_audit.py --check-similar-doc   (catalogue 既存時のみ)

完全 read-only — Solara コード一切変更しない。
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from collections import defaultdict
from dataclasses import dataclass, field, asdict
from pathlib import Path

try:
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')  # type: ignore[attr-defined]
except Exception:
    pass


# ============================================================
# T4: Solara 設計違反 anti-pattern catalogue
# memory project_solara_design_philosophy.md / project_solara_geo_sector.md と連動
# ============================================================
ANTI_PATTERNS = [
    # 設計思想違反 (合算による1次元化)
    ('AP-01', 'total = soft + hard 合算',
     r'total\s*=\s*[\w.]+\s*\+\s*[\w.]+\s*[+;]', 'high'),
    ('AP-02', 'tSoft+tHard+pSoft+pHard 合算ループ',
     r'(tSoft|tHard|pSoft|pHard)\s*\+\s*(tSoft|tHard|pSoft|pHard)', 'high'),
    ('AP-03', 'soft+hard 合算',
     r'\b(soft\s*\+\s*hard|hard\s*\+\s*soft)\b', 'high'),
    ('AP-04', 'softRatio / ハードRatio (1次元化)',
     r'\b(softRatio|hardRatio|soft_ratio|hard_ratio)\b', 'high'),
    # 廃止済み再導入
    ('AP-05', 'dominant tint / dominant color (合算 dominant 判定)',
     r'\bdominant\s*(Tint|Color|Category|Cat)\b', 'high'),
    ('AP-06', 'sectorTypeFromEnergy など廃止予定の rank 関数',
     r'\b(sectorType|sectorTypeFromEnergy)\s*\(', 'mid'),
    ('AP-07', 'blessed / shadow 廃止ランク分類',
     r'\b(blessed|shadowed?|midRank)\b', 'mid'),
    # 占い的吉凶判定
    ('AP-08', 'lucky / unlucky 文言',
     r'\b(lucky|unlucky|ラッキー|アンラッキー)\b', 'mid'),
    ('AP-09', '良い/悪い 二元論',
     r'良い方角|悪い方角|good\s+direction|bad\s+direction', 'mid'),
]


# ============================================================
# Token / function extraction
# ============================================================
COMMENT_RE = re.compile(r'//[^\n]*|/\*.*?\*/', re.DOTALL)
DOCSTRING_RE = re.compile(r'^[ \t]*///[ \t]?(.*)$', re.MULTILINE)
STRING_LIT_RE = re.compile(r'(?:"(?:[^"\\\n]|\\.)*"|\'(?:[^\'\\\n]|\\.)*\'|r"[^"]*"|r\'[^\']*\')')
NUMBER_LIT_RE = re.compile(r'\b(?:0x[0-9A-Fa-f]+|\d+\.?\d*(?:[eE][+-]?\d+)?)\b')
IDENT_RE = re.compile(r'\b([a-zA-Z_][a-zA-Z0-9_]*)\b')

DART_KEYWORDS = {
    'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch', 'class',
    'const', 'continue', 'covariant', 'default', 'deferred', 'do', 'dynamic', 'else',
    'enum', 'export', 'extends', 'extension', 'external', 'factory', 'false', 'final',
    'finally', 'for', 'function', 'get', 'hide', 'if', 'implements', 'import', 'in',
    'interface', 'is', 'late', 'library', 'mixin', 'new', 'null', 'on', 'operator',
    'part', 'required', 'rethrow', 'return', 'set', 'show', 'static', 'super', 'switch',
    'sync', 'this', 'throw', 'true', 'try', 'typedef', 'var', 'void', 'when', 'while',
    'with', 'yield',
    # builtin types frequently as identifiers
    'String', 'int', 'double', 'bool', 'List', 'Map', 'Set', 'Future', 'Stream',
    'Object', 'num', 'Iterable', 'Function',
}


@dataclass
class FunctionDef:
    file: str
    line: int
    name: str
    signature: str
    body: str          # raw body incl. braces
    doc_lines: list[str] = field(default_factory=list)


def split_camel_case(name: str) -> list[str]:
    """`_dominantTintByDir` -> ['dominant', 'tint', 'by', 'dir']"""
    s = name.lstrip('_')
    parts = re.findall(r'[A-Z][a-z0-9]*|[a-z0-9]+', s)
    return [p.lower() for p in parts if p]


def extract_japanese_keywords(text: str) -> list[str]:
    """Pull contiguous CJK / kana sequences as keywords."""
    return re.findall(r'[぀-ゟ゠-ヿー一-鿿A-Za-z]{2,}', text)


def normalize_for_exact(body: str) -> str:
    """T1: comment 除去 + 空白圧縮"""
    s = COMMENT_RE.sub('', body)
    s = re.sub(r'\s+', ' ', s).strip()
    return s


def normalize_for_structural(body: str) -> str:
    """T2: 識別子・リテラル抽象化"""
    s = COMMENT_RE.sub('', body)
    # string literals
    s = STRING_LIT_RE.sub('_STR', s)
    # number literals
    s = NUMBER_LIT_RE.sub('_NUM', s)
    # identifiers (除く: keywords)
    seen: dict[str, str] = {}
    counter = [0]

    def replace_ident(m: re.Match) -> str:
        ident = m.group(1)
        if ident in DART_KEYWORDS:
            return ident
        if ident not in seen:
            counter[0] += 1
            seen[ident] = f'_ID{counter[0]}'
        return seen[ident]

    s = IDENT_RE.sub(replace_ident, s)
    s = re.sub(r'\s+', ' ', s).strip()
    return s


def tokenize_for_minhash(body: str) -> list[str]:
    """T3: トークン列を抽象化 (Tier2 と同じ正規化を経てトークン化)"""
    norm = normalize_for_structural(body)
    # split by non-word chars but keep punctuation as token
    tokens = re.findall(r'_ID\d+|_STR|_NUM|[A-Za-z_]\w*|[+\-*/<>=!&|^%(){}\[\];,.:?]', norm)
    return tokens


# Simple MinHash + LSH (依存ゼロ自作)
class MiniMinHash:
    def __init__(self, num_perm: int = 128, seed: int = 1):
        self.num_perm = num_perm
        # Generate per-permutation hash params (linear congruential)
        rng = _Rng(seed)
        self._a = [rng.next() | 1 for _ in range(num_perm)]
        self._b = [rng.next() for _ in range(num_perm)]
        self._mod = (1 << 61) - 1  # Mersenne prime for modular hash

    def signature(self, tokens: list[str]) -> tuple[int, ...]:
        if not tokens:
            return tuple([0] * self.num_perm)
        # Pre-hash all unique tokens once
        token_hashes = [hash(t) & 0xFFFFFFFFFFFFFFFF for t in set(tokens)]
        sig = []
        for a, b in zip(self._a, self._b):
            min_h = self._mod
            for h in token_hashes:
                v = (a * h + b) % self._mod
                if v < min_h:
                    min_h = v
            sig.append(min_h)
        return tuple(sig)

    @staticmethod
    def jaccard(sig1: tuple[int, ...], sig2: tuple[int, ...]) -> float:
        if not sig1 or len(sig1) != len(sig2):
            return 0.0
        eq = sum(1 for a, b in zip(sig1, sig2) if a == b)
        return eq / len(sig1)


class _Rng:
    """Tiny deterministic RNG (no numpy dependency)."""
    def __init__(self, seed: int):
        self.x = seed or 1
    def next(self) -> int:
        self.x = (self.x * 6364136223846793005 + 1442695040888963407) & 0xFFFFFFFFFFFFFFFF
        return self.x


# ============================================================
# Function definition extraction (regex-based, best effort)
# ============================================================
# Match: optional return type, name, params, opening brace
# 例: 'Map<String, Color>? _dominantTintByDir() {'
#     'List<Polygon> buildSectors({...}) {'
#     'Future<void> _foo(int x) async {'
FUNC_HEADER_RE = re.compile(
    r'(?P<full>'
    r'(?:^|\n)'
    r'(?P<indent>[ \t]*)'
    r'(?:(?:Future|Stream|Iterable|List|Map|Set|void|bool|int|double|num|String|Color|[A-Z]\w*)(?:<[^>{};=]*>)?[ \t?]*[ \t])?'
    r'(?P<name>[a-zA-Z_]\w*)'
    r'[ \t]*'
    r'(?P<params>\([^()]*(?:\([^()]*\)[^()]*)*\))'
    r'[ \t]*(?:async\s*\*?|sync\s*\*)?[ \t]*'
    r'\{'
    r')',
    re.DOTALL
)


def find_matching_brace(text: str, open_idx: int) -> int:
    """Return index of matching `}` for `{` at open_idx. Naive (string-aware)."""
    depth = 0
    i = open_idx
    n = len(text)
    while i < n:
        c = text[i]
        if c == '"' or c == "'":
            quote = c
            i += 1
            while i < n and text[i] != quote:
                if text[i] == '\\':
                    i += 2
                else:
                    i += 1
            i += 1
            continue
        if c == '/' and i + 1 < n:
            if text[i+1] == '/':
                # line comment
                nl = text.find('\n', i)
                if nl == -1:
                    return -1
                i = nl + 1
                continue
            if text[i+1] == '*':
                end = text.find('*/', i+2)
                if end == -1:
                    return -1
                i = end + 2
                continue
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return -1


def extract_doc_lines(text: str, header_start: int) -> list[str]:
    """Walk backwards from header_start to collect contiguous /// doc lines."""
    # find newline before header_start, then read backwards
    lines = text[:header_start].splitlines()
    docs: list[str] = []
    for ln in reversed(lines):
        stripped = ln.strip()
        if stripped.startswith('///'):
            docs.append(stripped[3:].strip())
        elif stripped == '':
            if docs:
                break
            continue
        else:
            break
    return list(reversed(docs))


def extract_functions(content: str, file_rel: str) -> list[FunctionDef]:
    """Best-effort 関数抽出。class method、top-level、arrow function は別扱い。"""
    out: list[FunctionDef] = []
    # exclude obvious non-functions (control flow with `(` then `{`)
    excluded_names = {
        'if', 'else', 'for', 'while', 'switch', 'do', 'try', 'catch', 'finally',
        'return', 'throw', 'await', 'async', 'sync', 'is', 'as', 'in', 'with',
    }
    for m in FUNC_HEADER_RE.finditer(content):
        name = m.group('name')
        if name in excluded_names or name in DART_KEYWORDS:
            continue
        header_start = m.start('full') + (1 if m.group('full').startswith('\n') else 0)
        signature = (m.group('full') or '').strip().rstrip('{').strip()
        # Locate opening brace position
        brace_open = m.end('full') - 1  # m.end is exclusive of last char; '{' is last
        # find_matching_brace expects index of '{'
        if content[brace_open] != '{':
            # search forward
            brace_open = content.find('{', m.end('params'))
            if brace_open == -1:
                continue
        brace_close = find_matching_brace(content, brace_open)
        if brace_close == -1:
            continue
        body = content[brace_open:brace_close + 1]
        if len(body) < 30:  # too small (likely getter/empty)
            continue
        # Body line count check (DCM lines-threshold ≥ 3)
        body_lines = body.count('\n')
        if body_lines < 3:
            continue
        line_no = content.count('\n', 0, header_start) + 1
        doc_lines = extract_doc_lines(content, header_start)
        out.append(FunctionDef(
            file=file_rel,
            line=line_no,
            name=name,
            signature=signature[:200].replace('\n', ' '),
            body=body,
            doc_lines=doc_lines,
        ))
    return out


# ============================================================
# Hardcoded value & boilerplate detection
# ============================================================
COLOR_LIT_RE = re.compile(r'Color\(0x[0-9A-Fa-f]+\)')
CONTAINER_BOX_RE = re.compile(
    r'Container\s*\([^()]*decoration\s*:\s*BoxDecoration', re.DOTALL
)
DIR16_LOOP_RE = re.compile(
    r'for\s*\([^)]*(?:in\s+dir16|<\s*dir16\.length)', re.DOTALL
)


# ============================================================
# Scanning + report
# ============================================================
def is_excluded(rel: str) -> bool:
    parts = rel.replace('\\', '/').split('/')
    if any(p in {'build', '.dart_tool', 'generated', 'l10n_messages'} for p in parts):
        return True
    if rel.endswith('.g.dart') or rel.endswith('.freezed.dart') or rel.endswith('.mocks.dart'):
        return True
    if rel.endswith('_test.dart'):
        return True
    return False


def scan(target_dir: Path, exclude_tests: bool = True):
    files: list[tuple[Path, str]] = []
    for f in sorted(target_dir.rglob('*.dart')):
        rel = f.relative_to(target_dir).as_posix()
        if is_excluded(rel):
            continue
        if exclude_tests and 'test' in rel.split('/'):
            continue
        files.append((f, rel))

    all_funcs: list[FunctionDef] = []
    file_contents: dict[str, str] = {}
    anti_hits: list[tuple[str, str, int, str, str]] = []  # (pid, file, line, snippet, risk)
    color_uses: dict[str, list[tuple[str, int]]] = defaultdict(list)
    container_boilerplate: list[tuple[str, int]] = []
    dir16_loops: list[tuple[str, int]] = []

    for path, rel in files:
        try:
            content = path.read_text(encoding='utf-8')
        except Exception:
            continue
        file_contents[rel] = content

        # T4: anti-pattern grep
        for pid, name, pat, risk in [(p[0], p[1], p[2], p[3]) for p in ANTI_PATTERNS]:
            for m in re.finditer(pat, content):
                ln = content.count('\n', 0, m.start()) + 1
                line_text = content.splitlines()[ln-1].strip() if ln-1 < len(content.splitlines()) else ''
                # skip if inside a single-line comment
                if re.match(r'^\s*///?', line_text):
                    continue
                anti_hits.append((pid, rel, ln, line_text[:160], risk))

        # T5: Color / container / dir16 loop
        for m in COLOR_LIT_RE.finditer(content):
            ln = content.count('\n', 0, m.start()) + 1
            color_uses[m.group(0)].append((rel, ln))
        for m in CONTAINER_BOX_RE.finditer(content):
            ln = content.count('\n', 0, m.start()) + 1
            container_boilerplate.append((rel, ln))
        for m in DIR16_LOOP_RE.finditer(content):
            ln = content.count('\n', 0, m.start()) + 1
            dir16_loops.append((rel, ln))

        # Functions
        all_funcs.extend(extract_functions(content, rel))

    return {
        'files_count': len(files),
        'functions': all_funcs,
        'anti_hits': anti_hits,
        'color_uses': color_uses,
        'container_boilerplate': container_boilerplate,
        'dir16_loops': dir16_loops,
        'file_contents': file_contents,
    }


def find_exact_dups(funcs: list[FunctionDef]) -> dict[str, list[FunctionDef]]:
    groups: dict[str, list[FunctionDef]] = defaultdict(list)
    for fn in funcs:
        h = hashlib.sha256(normalize_for_exact(fn.body).encode()).hexdigest()[:16]
        groups[h].append(fn)
    return {h: g for h, g in groups.items() if len(g) >= 2}


def find_structural_dups(funcs: list[FunctionDef]) -> dict[str, list[FunctionDef]]:
    groups: dict[str, list[FunctionDef]] = defaultdict(list)
    for fn in funcs:
        h = hashlib.sha256(normalize_for_structural(fn.body).encode()).hexdigest()[:16]
        groups[h].append(fn)
    return {h: g for h, g in groups.items() if len(g) >= 2}


def find_near_dups(funcs: list[FunctionDef], threshold: float = 0.70):
    """T3: MinHash-based near-duplicate detection.

    Returns list of (fn_a, fn_b, jaccard_estimate) tuples.
    """
    mh = MiniMinHash(num_perm=128, seed=42)
    sigs: list[tuple[FunctionDef, tuple[int, ...]]] = []
    for fn in funcs:
        tokens = tokenize_for_minhash(fn.body)
        # Min token threshold raised to suppress false positives from short
        # boilerplate (getters, single-line setStates, etc.).
        if len(tokens) < 60:
            continue
        sigs.append((fn, mh.signature(tokens)))

    # Banding LSH: 16 bands × 8 rows for 128 perms
    bands, rows = 16, 8
    buckets: dict[tuple, list[int]] = defaultdict(list)
    for idx, (_, sig) in enumerate(sigs):
        for b in range(bands):
            band_key = (b,) + sig[b*rows:(b+1)*rows]
            buckets[band_key].append(idx)

    candidate_pairs: set[tuple[int, int]] = set()
    for indices in buckets.values():
        if len(indices) < 2:
            continue
        for i, idx_a in enumerate(indices):
            for idx_b in indices[i+1:]:
                pair = (min(idx_a, idx_b), max(idx_a, idx_b))
                candidate_pairs.add(pair)

    results = []
    for a, b in candidate_pairs:
        fn_a, sig_a = sigs[a]
        fn_b, sig_b = sigs[b]
        if fn_a.file == fn_b.file and fn_a.name == fn_b.name:
            continue
        jaccard_est = MiniMinHash.jaccard(sig_a, sig_b)
        if jaccard_est >= threshold:
            results.append((fn_a, fn_b, jaccard_est))
    results.sort(key=lambda x: -x[2])
    return results


def build_catalogue(funcs: list[FunctionDef]) -> list[dict]:
    out = []
    for fn in funcs:
        doc_jp_full = ' '.join(fn.doc_lines)
        name_words = split_camel_case(fn.name)
        comment_kw_jp = list(set(extract_japanese_keywords(doc_jp_full)))
        out.append({
            'id': hashlib.sha256(f'{fn.file}:{fn.line}:{fn.name}'.encode()).hexdigest()[:12],
            'file': fn.file,
            'line': fn.line,
            'name': fn.name,
            'signature': fn.signature,
            'doc_jp': doc_jp_full,
            'name_words_en': name_words,
            'comment_keywords_jp': comment_kw_jp,
        })
    return out


def find_doc_similar(catalogue: list[dict], threshold: float = 0.50):
    """T7: 自然言語類似度で機能重複候補を検出.

    比較対象: doc_jp + name_words_en + comment_keywords_jp の word set
    Jaccard 類似度ベース。
    """
    def words_of(entry: dict) -> set[str]:
        words: set[str] = set()
        words.update(entry.get('name_words_en', []))
        for w in entry.get('comment_keywords_jp', []):
            words.add(w)
        # split doc_jp into rough word-like chunks
        for w in re.findall(r'[a-zA-Z_]\w+|[぀-ゟ゠-ヿー一-鿿]{2,}', entry.get('doc_jp', '')):
            words.add(w.lower() if w.isascii() else w)
        # filter very common stop-words
        stop = {'する', 'の', 'を', 'が', 'は', 'に', 'で', 'と', 'or', 'and', 'a', 'the', 'is', 'on', 'in'}
        return {w for w in words if w not in stop and len(w) >= 2}

    word_sets = [(entry, words_of(entry)) for entry in catalogue]
    pairs = []
    for i in range(len(word_sets)):
        ea, wa = word_sets[i]
        if not wa:
            continue
        for j in range(i+1, len(word_sets)):
            eb, wb = word_sets[j]
            if not wb:
                continue
            inter = len(wa & wb)
            if inter < 2:
                continue
            jac = inter / max(1, len(wa | wb))
            if jac >= threshold:
                pairs.append((ea, eb, jac, sorted(wa & wb)))
    pairs.sort(key=lambda x: -x[2])
    return pairs


# ============================================================
# Report
# ============================================================
def write_report(data, target_dir: Path, out, exact_dups, struct_dups, near_dups,
                 catalogue, doc_pairs):
    funcs = data['functions']
    out.write(f'# Flutter duplicate-audit report\n\n')
    out.write(f'Generated by `tools/flutter_duplicate_audit.py`\n\n')
    out.write(f'- Target: `{target_dir}`\n')
    out.write(f'- Files scanned: **{data["files_count"]}**\n')
    out.write(f'- Functions extracted: **{len(funcs)}**\n')
    out.write(f'- Tier coverage: 1, 2, 3, 4, 5, 6, 7 (no skip)\n\n')

    # Summary
    out.write('## Summary\n\n')
    out.write('| Tier | Description | Hits |\n|---|---|---:|\n')
    out.write(f'| T1 | Exact duplicate functions | {sum(len(g) for g in exact_dups.values())} (in {len(exact_dups)} groups) |\n')
    out.write(f'| T2 | Structural duplicates | {sum(len(g) for g in struct_dups.values())} (in {len(struct_dups)} groups) |\n')
    out.write(f'| T3 | Near-duplicates (MinHash ≥ 0.70) | {len(near_dups)} pairs |\n')
    out.write(f'| T4 | Anti-patterns (Solara design violation) | {len(data["anti_hits"])} |\n')
    n_color_sprawl = sum(1 for v in data['color_uses'].values() if len(v) >= 4)
    out.write(f'| T5 | Hardcoded Color sprawl (≥ 4 sites) | {n_color_sprawl} unique values |\n')
    out.write(f'| T6 | Container+BoxDecoration occurrences | {len(data["container_boilerplate"])} | \n')
    out.write(f'| T6 | dir16 loop occurrences | {len(data["dir16_loops"])} |\n')
    out.write(f'| T7 | Functions catalogued | {len(catalogue)} |\n')
    out.write(f'| T7 | Doc-similar pairs (Jaccard ≥ 0.50) | {len(doc_pairs)} |\n')
    out.write('\n')

    # T1
    out.write('## T1 — Exact duplicates\n\n')
    if not exact_dups:
        out.write('_No exact duplicates._\n\n')
    else:
        for h, group in exact_dups.items():
            out.write(f'### Group `{h}` ({len(group)} functions)\n')
            for fn in group:
                out.write(f'- `{fn.file}:{fn.line}` `{fn.name}` — {len(fn.body)} chars\n')
            out.write('\n')

    # T2
    out.write('## T2 — Structural duplicates (variable/literal abstraction)\n\n')
    only_struct = {h: g for h, g in struct_dups.items() if h not in exact_dups}
    if not only_struct:
        out.write('_No additional structural duplicates beyond T1._\n\n')
    else:
        for h, group in only_struct.items():
            out.write(f'### Group `{h}` ({len(group)} functions)\n')
            for fn in group:
                out.write(f'- `{fn.file}:{fn.line}` `{fn.name}`\n')
            out.write('\n')

    # T3
    out.write('## T3 — Near-duplicates (MinHash + Jaccard ≥ 0.70)\n\n')
    if not near_dups:
        out.write('_No near-duplicate pairs._\n\n')
    else:
        for fn_a, fn_b, jac in near_dups[:30]:
            out.write(f'- `{fn_a.file}:{fn_a.line}` `{fn_a.name}` ⇄ `{fn_b.file}:{fn_b.line}` `{fn_b.name}` — Jaccard ≈ {jac:.2f}\n')
        if len(near_dups) > 30:
            out.write(f'- … +{len(near_dups)-30} more\n')
        out.write('\n')

    # T4
    out.write('## T4 — Solara anti-patterns (design philosophy violations)\n\n')
    if not data['anti_hits']:
        out.write('_No anti-pattern hits._\n\n')
    else:
        by_pid: dict[str, list] = defaultdict(list)
        for pid, rel, ln, snip, risk in data['anti_hits']:
            by_pid[pid].append((rel, ln, snip, risk))
        ap_meta = {p[0]: (p[1], p[3]) for p in ANTI_PATTERNS}
        for pid, hits in by_pid.items():
            name, risk = ap_meta.get(pid, ('?', 'low'))
            risk_marker = {'high': '🔴', 'mid': '🟡', 'low': '🟢'}.get(risk, '⚪')
            out.write(f'### {risk_marker} {pid} `{name}` ({len(hits)} 件)\n')
            for rel, ln, snip, _ in hits[:15]:
                out.write(f'- `{rel}:{ln}` — `{snip}`\n')
            if len(hits) > 15:
                out.write(f'- … +{len(hits)-15} more\n')
            out.write('\n')

    # T5
    out.write('## T5 — Hardcoded Color sprawl (≥ 4 sites)\n\n')
    sprawl = [(v, locs) for v, locs in data['color_uses'].items() if len(locs) >= 4]
    sprawl.sort(key=lambda x: -len(x[1]))
    if not sprawl:
        out.write('_No widely-spread hardcoded colors._\n\n')
    else:
        for v, locs in sprawl[:25]:
            out.write(f'- `{v}` — {len(locs)} sites\n')
            for f, ln in locs[:8]:
                out.write(f'  - `{f}:{ln}`\n')
            if len(locs) > 8:
                out.write(f'  - … +{len(locs)-8} more\n')
        out.write('\n')

    # T6
    out.write('## T6 — Repeated boilerplate patterns\n\n')
    out.write(f'### Container + BoxDecoration ({len(data["container_boilerplate"])} 件)\n')
    for f, ln in data['container_boilerplate'][:15]:
        out.write(f'- `{f}:{ln}`\n')
    if len(data['container_boilerplate']) > 15:
        out.write(f'- … +{len(data["container_boilerplate"])-15} more\n')
    out.write('\n')
    out.write(f'### dir16 loop ({len(data["dir16_loops"])} 件)\n')
    for f, ln in data['dir16_loops'][:15]:
        out.write(f'- `{f}:{ln}`\n')
    if len(data['dir16_loops']) > 15:
        out.write(f'- … +{len(data["dir16_loops"])-15} more\n')
    out.write('\n')

    # T7
    out.write('## T7 — Functionality catalogue & natural-language similarity\n\n')
    out.write(f'_Catalogue saved to YAML (see `--catalogue-out`)._\n\n')
    if not doc_pairs:
        out.write('_No doc-similar pairs (≥ 0.50)._\n\n')
    else:
        out.write(f'### Top doc-similar pairs (potential functional duplicates)\n\n')
        for ea, eb, jac, common in doc_pairs[:25]:
            out.write(f'- **Jaccard ≈ {jac:.2f}**\n')
            out.write(f'  - `{ea["file"]}:{ea["line"]}` `{ea["name"]}` — JP: "{ea["doc_jp"][:80]}"\n')
            out.write(f'  - `{eb["file"]}:{eb["line"]}` `{eb["name"]}` — JP: "{eb["doc_jp"][:80]}"\n')
            out.write(f'  - Common keywords: {", ".join(common[:8])}\n\n')


def write_catalogue_yaml(catalogue: list[dict], path: Path):
    """Minimal YAML writer (no pyyaml dependency)."""
    def esc(s: str) -> str:
        return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', ' ')
    with path.open('w', encoding='utf-8') as f:
        f.write('# Solara function catalogue (auto-generated)\n')
        f.write('# Use --check-similar-doc to find functionally similar pairs.\n\n')
        f.write('functions:\n')
        for e in catalogue:
            f.write(f'  - id: "{e["id"]}"\n')
            f.write(f'    file: "{esc(e["file"])}"\n')
            f.write(f'    line: {e["line"]}\n')
            f.write(f'    name: "{esc(e["name"])}"\n')
            f.write(f'    signature: "{esc(e["signature"])}"\n')
            f.write(f'    doc_jp: "{esc(e["doc_jp"])}"\n')
            f.write(f'    name_words_en: [{", ".join(json.dumps(w) for w in e["name_words_en"])}]\n')
            f.write(f'    comment_keywords_jp: [{", ".join(json.dumps(w, ensure_ascii=False) for w in e["comment_keywords_jp"])}]\n')


# ============================================================
# CLI
# ============================================================
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--target', default='apps/solara/lib')
    parser.add_argument('--out', default='tools/flutter_duplicate_audit_report.md')
    parser.add_argument('--catalogue-out', default='tools/solara_function_catalogue.yaml')
    parser.add_argument('--near-threshold', type=float, default=0.70)
    parser.add_argument('--doc-threshold', type=float, default=0.50)
    parser.add_argument('--include-tests', action='store_true')
    args = parser.parse_args()

    target = Path(args.target).resolve()
    if not target.exists():
        print(f'Target not found: {target}', file=sys.stderr)
        sys.exit(1)

    print(f'Scanning {target} ...', file=sys.stderr)
    data = scan(target, exclude_tests=not args.include_tests)
    funcs = data['functions']
    print(f'  files: {data["files_count"]}, functions: {len(funcs)}', file=sys.stderr)

    print('Computing T1 exact duplicates ...', file=sys.stderr)
    exact_dups = find_exact_dups(funcs)
    print(f'  groups: {len(exact_dups)}', file=sys.stderr)

    print('Computing T2 structural duplicates ...', file=sys.stderr)
    struct_dups = find_structural_dups(funcs)
    print(f'  groups: {len(struct_dups)}', file=sys.stderr)

    print('Computing T3 near-duplicates (MinHash) ...', file=sys.stderr)
    near_dups = find_near_dups(funcs, threshold=args.near_threshold)
    print(f'  pairs: {len(near_dups)}', file=sys.stderr)

    print('Building T7 functionality catalogue ...', file=sys.stderr)
    catalogue = build_catalogue(funcs)
    doc_pairs = find_doc_similar(catalogue, threshold=args.doc_threshold)
    print(f'  doc-similar pairs: {len(doc_pairs)}', file=sys.stderr)

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open('w', encoding='utf-8') as f:
        write_report(data, target, f, exact_dups, struct_dups, near_dups, catalogue, doc_pairs)
    print(f'Report saved: {out_path}', file=sys.stderr)

    cat_path = Path(args.catalogue_out)
    cat_path.parent.mkdir(parents=True, exist_ok=True)
    write_catalogue_yaml(catalogue, cat_path)
    print(f'Catalogue saved: {cat_path}', file=sys.stderr)


if __name__ == '__main__':
    main()
