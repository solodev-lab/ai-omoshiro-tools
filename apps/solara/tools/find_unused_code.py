"""不要コード（未使用インポート・未参照シンボル）の検出。

flutter analyze の出力から unused_* 系の警告だけを抽出。
さらに lib/ 配下の Dart ファイルから「定義されているが他のどのファイルでも参照されない
top-level シンボル（class/typedef/関数）」をヒューリスティックに探す。
誤検知あり前提（部分一致のため）、人間レビュー前提のリストアップ用途。
"""
import os
import re
import subprocess
import sys

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
LIB_DIR = os.path.join(REPO_ROOT, "lib")

# 抽出対象の analyze カテゴリ
UNUSED_CATEGORIES = (
    "unused_import",
    "unused_field",
    "unused_local_variable",
    "unused_element",
    "dead_code",
)

def run_analyze():
    print("=== flutter analyze unused-* hits ===")
    # Windows: flutter は flutter.bat として配布されているため shell=True が必要。
    proc = subprocess.run(
        "flutter analyze --no-pub",
        cwd=REPO_ROOT, capture_output=True, text=True, encoding="utf-8",
        shell=True,
    )
    out = (proc.stdout or "") + (proc.stderr or "")
    hits = []
    for line in out.splitlines():
        for cat in UNUSED_CATEGORIES:
            if f" - {cat}" in line:
                hits.append(line.strip())
                break
    if not hits:
        print("  (none)")
    else:
        for h in hits:
            print(f"  {h}")
    print()

# 1ファイルから top-level クラス・関数名を抽出（簡易・private は対象外）
SYMBOL_RE = re.compile(
    r"^(?:abstract\s+|sealed\s+|mixin\s+|enum\s+|extension\s+|typedef\s+|class\s+)?"
    r"\b(class|enum|mixin|extension|typedef)\s+([A-Z][A-Za-z0-9_]*)",
    re.MULTILINE,
)
FN_RE = re.compile(
    r"^\s*(?:Future<[^>]+>|void|[A-Z][A-Za-z0-9_<>?]*)\s+([A-Z][A-Za-z0-9_]*)\s*\(",
    re.MULTILINE,
)

def find_orphans():
    print("=== Possibly unused top-level symbols (heuristic) ===")
    files = []
    for root, _, fs in os.walk(LIB_DIR):
        for f in fs:
            if f.endswith(".dart"):
                files.append(os.path.join(root, f))

    # 全ファイル本文を1つの巨大文字列にしておき、シンボル名で検索する
    bodies = {}
    for p in files:
        with open(p, "r", encoding="utf-8") as fh:
            bodies[p] = fh.read()

    all_text = "\n".join(bodies.values())

    suspects = []
    for path, body in bodies.items():
        rel = os.path.relpath(path, REPO_ROOT).replace("\\", "/")
        for m in SYMBOL_RE.finditer(body):
            name = m.group(2)
            if name.startswith("_"):
                continue
            # 自ファイル内も含めた使用回数
            count = len(re.findall(rf"\b{name}\b", all_text))
            if count <= 1:  # 定義のみ・他参照ゼロ
                suspects.append(f"  {rel:60s} :: {name}")

    if not suspects:
        print("  (none - all top-level public symbols are referenced)")
    else:
        for s in suspects:
            print(s)

if __name__ == "__main__":
    run_analyze()
    find_orphans()
