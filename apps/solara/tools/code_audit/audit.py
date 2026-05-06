#!/usr/bin/env python3
"""Solara コードベース監査スクリプト。

検査項目:
  1. ファイル行数 (300 行超 = 分割推奨、500 行超 = 分割必須)
  2. 重複コードブロック (連続 8 行以上の完全一致)
  3. 未使用 import / private member 候補 (簡易検出)
  4. TODO/FIXME/XXX/DEBUG 残置
  5. print() / debugPrint() 残置 (リリースビルドで残る)

Usage:
    cd E:/AppCreate
    python apps/solara/tools/code_audit/audit.py
"""
from __future__ import annotations

import io
import re
import sys
from collections import defaultdict
from pathlib import Path

# Windows cp932 だと絵文字が落ちるので強制 UTF-8
if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

ROOT = Path(__file__).resolve().parents[2]  # apps/solara
LIB = ROOT / "lib"

LINE_WARN = 300
LINE_HARD = 500
DUP_MIN_LINES = 8

# ── ファイル列挙 ──────────────────────────────────────────────
def dart_files() -> list[Path]:
    files = list(LIB.rglob("*.dart"))
    # generated は除外
    return [f for f in files if not f.name.endswith(".g.dart") and not f.name.endswith(".freezed.dart")]


# ── 行数チェック ──────────────────────────────────────────────
def check_line_count(files: list[Path]) -> list[tuple[Path, int, str]]:
    out: list[tuple[Path, int, str]] = []
    for f in files:
        n = sum(1 for _ in f.open(encoding="utf-8"))
        if n >= LINE_HARD:
            out.append((f, n, "HARD"))
        elif n >= LINE_WARN:
            out.append((f, n, "WARN"))
    return sorted(out, key=lambda x: -x[1])


# ── 重複コード検出 ────────────────────────────────────────────
def normalize_line(line: str) -> str:
    s = line.strip()
    # 空行/コメントは無視
    if not s or s.startswith("//") or s.startswith("*") or s.startswith("/*"):
        return ""
    return s


def check_duplication(files: list[Path]) -> list[tuple[str, list[tuple[Path, int]]]]:
    block_locations: dict[str, list[tuple[Path, int]]] = defaultdict(list)
    for f in files:
        lines = f.read_text(encoding="utf-8").splitlines()
        norm = [normalize_line(line) for line in lines]
        for i in range(len(norm) - DUP_MIN_LINES + 1):
            block = "\n".join(norm[i : i + DUP_MIN_LINES])
            # 空行/短すぎブロックスキップ
            if block.count("\n") < DUP_MIN_LINES - 1:
                continue
            non_empty = sum(1 for l in norm[i : i + DUP_MIN_LINES] if l)
            if non_empty < DUP_MIN_LINES - 2:
                continue
            block_locations[block].append((f, i + 1))
    # 2 箇所以上で出現
    dupes = [(b, locs) for b, locs in block_locations.items() if len(locs) >= 2]
    # 別ファイル間の重複を優先
    def cross_file_score(locs: list[tuple[Path, int]]) -> int:
        return len({l[0] for l in locs})
    return sorted(dupes, key=lambda x: (-cross_file_score(x[1]), -len(x[1])))[:20]


# ── TODO / DEBUG 残置 ─────────────────────────────────────────
TODO_PAT = re.compile(r"//\s*(TODO|FIXME|XXX|HACK|DEBUG)\b", re.IGNORECASE)


def check_todos(files: list[Path]) -> list[tuple[Path, int, str]]:
    out: list[tuple[Path, int, str]] = []
    for f in files:
        for i, line in enumerate(f.open(encoding="utf-8"), 1):
            if TODO_PAT.search(line):
                out.append((f, i, line.strip()))
    return out


# ── print/debugPrint 残置 ─────────────────────────────────────
PRINT_PAT = re.compile(r"\b(print|debugPrint)\s*\(")


def check_prints(files: list[Path]) -> list[tuple[Path, int, str]]:
    out: list[tuple[Path, int, str]] = []
    for f in files:
        for i, line in enumerate(f.open(encoding="utf-8"), 1):
            stripped = line.strip()
            # コメント内は無視
            if stripped.startswith("//") or stripped.startswith("*"):
                continue
            if PRINT_PAT.search(line):
                out.append((f, i, stripped))
    return out


# ── 未使用 private member 候補 (簡易) ────────────────────────
PRIVATE_DECL = re.compile(r"^\s*(?:final|var|late|static\s+(?:final|const)|const)\s+\S+\s+(_\w+)\s*[=;]")
PRIVATE_FUNC = re.compile(r"^\s*(?:Future<[^>]*>|void|bool|int|double|String|Widget|List<[^>]*>|Map<[^>]*>|\w+)\s+(_\w+)\s*\(")


def _build_part_groups(files: list[Path]) -> dict[Path, list[Path]]:
    """`part of '...'` で繋がる .dart ファイル群をグルーピング。
    Dart の private (_xxx) は library scope なので、part-of 関係にあるファイル全体で
    references を数える必要がある (extension method など)。
    Returns: {file: [files in same library]}
    """
    PART_OF = re.compile(r"^\s*part\s+of\s+['\"]([^'\"]+)['\"]")
    PART = re.compile(r"^\s*part\s+['\"]([^'\"]+)['\"]")
    # part_of_targets: child -> parent
    parent: dict[Path, Path] = {}
    children: dict[Path, list[Path]] = defaultdict(list)
    for f in files:
        try:
            text = f.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for line in text.splitlines()[:50]:
            m = PART_OF.match(line)
            if m:
                target = (f.parent / m.group(1)).resolve()
                parent[f] = target
                children[target].append(f)
                break
    # group 構築
    groups: dict[Path, list[Path]] = {}
    for f in files:
        if f in parent:
            root = parent[f]
            while root in parent:
                root = parent[root]
            groups[f] = [root] + children.get(root, [])
        else:
            groups[f] = [f] + children.get(f, [])
    return groups


def check_unused_private(files: list[Path]) -> list[tuple[Path, int, str]]:
    """part-of で繋がるファイル全体で reference == 1 (= 宣言のみ) のものを未使用候補に。"""
    groups = _build_part_groups(files)
    out: list[tuple[Path, int, str]] = []
    # group 単位の text を cache
    group_text_cache: dict[tuple[Path, ...], str] = {}
    for f in files:
        text = f.read_text(encoding="utf-8")
        lines = text.splitlines()
        decls: list[tuple[int, str]] = []
        for i, line in enumerate(lines, 1):
            m = PRIVATE_DECL.match(line) or PRIVATE_FUNC.match(line)
            if m:
                decls.append((i, m.group(1)))
        if not decls:
            continue
        group_files = tuple(sorted(groups.get(f, [f]), key=str))
        if group_files not in group_text_cache:
            group_text_cache[group_files] = "\n".join(
                gf.read_text(encoding="utf-8") for gf in group_files if gf.exists()
            )
        all_text = group_text_cache[group_files]
        for line_no, name in decls:
            count = len(re.findall(r"\b" + re.escape(name) + r"\b", all_text))
            if count == 1:
                out.append((f, line_no, name))
    return out


# ── メイン ────────────────────────────────────────────────────
def fmt(p: Path) -> str:
    return str(p.relative_to(ROOT)).replace("\\", "/")


def main() -> int:
    files = dart_files()
    print(f"# Solara Code Audit\n")
    print(f"対象: {LIB.relative_to(ROOT)} ({len(files)} 個の .dart)\n")

    # 1. 行数
    print("## 1. ファイル行数 (>= 300 行)\n")
    big = check_line_count(files)
    if big:
        print("| 行数 | 判定 | ファイル |")
        print("|------|------|----------|")
        for f, n, sev in big:
            mark = "🔴" if sev == "HARD" else "🟡"
            print(f"| {n} | {mark} {sev} | {fmt(f)} |")
    else:
        print("✅ 全ファイル < 300 行")
    print()

    # 2. 重複
    print(f"## 2. 重複コード (>= {DUP_MIN_LINES} 行連続一致、上位 20 件)\n")
    dupes = check_duplication(files)
    if dupes:
        for i, (block, locs) in enumerate(dupes, 1):
            files_set = {l[0] for l in locs}
            n_files = len(files_set)
            scope = "📁 別ファイル間" if n_files >= 2 else "📄 同ファイル内"
            print(f"### {i}. {scope} ({len(locs)} 箇所、{n_files} ファイル)\n")
            for path, line in locs[:5]:
                print(f"  - {fmt(path)}:{line}")
            preview = block.split("\n")[0][:80]
            print(f"  ```\n  {preview}\n  ```\n")
    else:
        print("✅ 重複なし")
    print()

    # 3. TODO
    print("## 3. TODO/FIXME/HACK/DEBUG 残置\n")
    todos = check_todos(files)
    if todos:
        for f, i, text in todos:
            print(f"  - {fmt(f)}:{i} — `{text[:120]}`")
    else:
        print("✅ なし")
    print()

    # 4. print
    print("## 4. print()/debugPrint() 残置\n")
    prints = check_prints(files)
    if prints:
        for f, i, text in prints:
            print(f"  - {fmt(f)}:{i} — `{text[:120]}`")
    else:
        print("✅ なし")
    print()

    # 5. 未使用 private (簡易)
    print("## 5. 未使用 private member 候補 (file 内 reference == 1)\n")
    unused = check_unused_private(files)
    if unused:
        for f, i, name in unused[:30]:
            print(f"  - {fmt(f)}:{i} — `{name}`")
        if len(unused) > 30:
            print(f"  ... 他 {len(unused) - 30} 件")
    else:
        print("✅ なし")
    print()

    print("---")
    print(f"\n総計: 行数違反 {len(big)} / 重複 {len(dupes)} / TODO {len(todos)} / print {len(prints)} / 未使用候補 {len(unused)}")

    # exit code: 重大な問題があれば 1
    hard_count = sum(1 for _, _, s in big if s == "HARD")
    return 1 if hard_count > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
