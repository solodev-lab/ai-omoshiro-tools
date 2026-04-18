"""Solara コード検証スクリプト

チェック内容:
1. ファイル行数 (500行超は分割候補として警告)
2. 未使用 import (簡易検出)
3. print() / debugPrint() 残り
4. TODO / FIXME / XXX
5. 未使用の private シンボル (_funcName など、簡易検出)
"""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "lib"

FILE_SIZE_WARN = 500
FILE_SIZE_CRIT = 900

def gather_dart_files():
    return sorted(LIB.rglob("*.dart"))

def check_sizes(files):
    print("\n=== [1] ファイルサイズチェック ===")
    big = []
    for f in files:
        lines = f.read_text(encoding="utf-8", errors="ignore").count("\n") + 1
        if lines >= FILE_SIZE_CRIT:
            big.append((f, lines, "CRIT"))
        elif lines >= FILE_SIZE_WARN:
            big.append((f, lines, "WARN"))
    if not big:
        print("  OK: すべて 500 行未満")
    for f, n, lvl in big:
        print(f"  [{lvl}] {n:5d} lines  {f.relative_to(ROOT)}")
    return big

def check_unused_imports(files):
    print("\n=== [2] 未使用 import 疑い ===")
    hits = []
    for f in files:
        src = f.read_text(encoding="utf-8", errors="ignore")
        imports = re.findall(r"^import\s+'([^']+)'(?:\s+as\s+(\w+))?;", src, re.M)
        for path, alias in imports:
            if alias:
                # alias 使用されているか
                if not re.search(rf"\b{alias}\.", src):
                    hits.append((f, f"alias '{alias}' (from {path})"))
                continue
            # 相対 import の場合、ファイル名(拡張子除く)から主要シンボルを推測
            if path.startswith("package:flutter/") or path.startswith("dart:"):
                continue
            name = Path(path).stem
            # ファイル内で定義されている公開シンボルを grep するのは大変なので、
            # ファイル名のキャメルケース版が使われているか簡易確認
            camel = "".join(w.capitalize() for w in name.split("_"))
            # 簡易: ファイル名一部 or キャメル名がソース中にあるか
            src_wo_import = re.sub(r"^import\s+.+$", "", src, flags=re.M)
            if name not in src_wo_import and camel not in src_wo_import:
                hits.append((f, f"maybe unused: {path}"))
    if not hits:
        print("  OK: 明らかな未使用 import なし")
    for f, msg in hits:
        print(f"  {f.relative_to(ROOT)}: {msg}")
    return hits

def check_debug_prints(files):
    print("\n=== [3] print/debugPrint 残り ===")
    hits = []
    for f in files:
        src = f.read_text(encoding="utf-8", errors="ignore")
        for i, line in enumerate(src.splitlines(), 1):
            # コメント内は無視
            stripped = line.strip()
            if stripped.startswith("//") or stripped.startswith("*"):
                continue
            if re.search(r"\bprint\s*\(", line) or re.search(r"\bdebugPrint\s*\(", line):
                hits.append((f, i, line.strip()))
    if not hits:
        print("  OK: print/debugPrint なし")
    for f, i, line in hits:
        print(f"  {f.relative_to(ROOT)}:{i}  {line[:100]}")
    return hits

def check_todos(files):
    print("\n=== [4] TODO / FIXME / XXX ===")
    hits = []
    for f in files:
        src = f.read_text(encoding="utf-8", errors="ignore")
        for i, line in enumerate(src.splitlines(), 1):
            if re.search(r"\b(TODO|FIXME|XXX)\b", line):
                hits.append((f, i, line.strip()))
    if not hits:
        print("  OK: なし")
    for f, i, line in hits:
        print(f"  {f.relative_to(ROOT)}:{i}  {line[:120]}")
    return hits

def check_unused_private(files):
    """
    各ファイル内で定義された _private シンボル (関数・変数・クラス) が
    同じファイル内で2回以上出現しないものを "未使用" とみなす (簡易)。
    """
    print("\n=== [5] 未使用 private シンボル疑い ===")
    hits = []
    def_pat = re.compile(
        r"^\s*(?:static\s+)?(?:final\s+|const\s+|late\s+)*"
        r"(?:[\w<>\?,\s\[\]]+?\s+)?"
        r"(_[A-Za-z][A-Za-z0-9_]*)\s*(?:\(|=|;)",
        re.M,
    )
    class_pat = re.compile(r"^\s*class\s+(_[A-Za-z][A-Za-z0-9_]*)", re.M)
    for f in files:
        src = f.read_text(encoding="utf-8", errors="ignore")
        names = set(def_pat.findall(src)) | set(class_pat.findall(src))
        for n in names:
            # 定義以外の使用箇所が存在するか
            count = len(re.findall(rf"\b{re.escape(n)}\b", src))
            if count <= 1:
                hits.append((f, n))
    if not hits:
        print("  OK: 未使用 private シンボルなし")
    for f, n in hits:
        print(f"  {f.relative_to(ROOT)}: {n}")
    return hits

def main():
    files = gather_dart_files()
    print(f"対象: {len(files)} .dart ファイル")
    check_sizes(files)
    check_debug_prints(files)
    check_todos(files)
    check_unused_private(files)
    check_unused_imports(files)

if __name__ == "__main__":
    main()
