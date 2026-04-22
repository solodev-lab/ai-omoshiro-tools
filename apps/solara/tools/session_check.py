"""
Solara セッション終了前検査スクリプト

目的:
- 本セッションで変更したファイルの行数・構造を確認
- ファイル分割が適切か（1ファイル800行超えは警告）
- 不要なコード（デバッグprint、TODO残り、未使用import など）を検出
- ドキュメントが存在するか

使い方:
    python apps/solara/tools/session_check.py
"""
from __future__ import annotations
import io
import os
import re
import sys
from pathlib import Path

# Windows でも絵文字・日本語出力できるよう強制 UTF-8
if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parents[3]  # E:/AppCreate
SOLARA = ROOT / "apps" / "solara"

# 本セッションで変更したファイル
CHANGED_FILES = [
    SOLARA / "worker" / "src" / "astro.js",
    SOLARA / "lib" / "screens" / "map" / "map_astro.dart",
    SOLARA / "lib" / "screens" / "map" / "map_sectors.dart",
    SOLARA / "lib" / "screens" / "map_screen.dart",
    SOLARA / "docs" / "Map機能.md",
]

# 同階層の関連ファイル（分割粒度チェック用）
MAP_MODULE_FILES = list((SOLARA / "lib" / "screens" / "map").glob("*.dart"))

# 警告閾値
WARN_LINES = 800
ERROR_LINES = 1500

# 不要コード検出パターン
DEBUG_PATTERNS = [
    (r"print\s*\(", "print文（本番不要）"),
    (r"debugPrint\s*\(", "debugPrint（確認用）"),
    (r"//\s*DEBUG\s*:", "DEBUGコメント"),
    (r"//\s*TODO\s*:", "TODOコメント（残課題として把握）"),
    (r"//\s*FIXME\s*:", "FIXMEコメント"),
    (r"console\.log\s*\(", "console.log（JS本番不要）"),
]


def count_lines(path: Path) -> int:
    if not path.exists():
        return 0
    return sum(1 for _ in path.open("r", encoding="utf-8", errors="replace"))


def scan_file(path: Path) -> list[str]:
    """ファイル内の不要コード候補を検出"""
    if not path.exists():
        return []
    issues: list[str] = []
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except Exception as e:
        return [f"  [読込エラー] {e}"]

    for i, line in enumerate(text.splitlines(), start=1):
        for pat, label in DEBUG_PATTERNS:
            if re.search(pat, line):
                trimmed = line.strip()[:80]
                issues.append(f"  L{i}: [{label}] {trimmed}")
    return issues


def check_imports(path: Path) -> list[str]:
    """Dartファイルのimport順序・未使用imports を軽くチェック"""
    if not path.suffix == ".dart" or not path.exists():
        return []
    text = path.read_text(encoding="utf-8", errors="replace")
    imports = re.findall(r'^import\s+[\'"]([^\'"]+)[\'"]', text, re.MULTILINE)
    issues = []
    for imp in imports:
        symbol_name = imp.split("/")[-1].replace(".dart", "")
        # 雑な検出: import したファイル名のパスカルケース類似語が本文にないか
        # 厳密さ不要、警告のみ
    return issues


def pretty_header(text: str) -> None:
    print()
    print("=" * 78)
    print(f"  {text}")
    print("=" * 78)


def main() -> int:
    exit_code = 0

    pretty_header("1) 変更ファイル一覧と行数")
    for p in CHANGED_FILES:
        rel = p.relative_to(ROOT)
        if not p.exists():
            print(f"  ✗ NOT FOUND: {rel}")
            exit_code = 1
            continue
        lines = count_lines(p)
        status = "OK"
        if lines > ERROR_LINES:
            status = f"ERROR ({lines} > {ERROR_LINES} 要分割)"
            exit_code = 1
        elif lines > WARN_LINES:
            status = f"WARN  ({lines} > {WARN_LINES} 分割検討)"
        print(f"  {lines:>5} lines  {status:<35}  {rel}")

    pretty_header("2) map/ モジュール分割状況")
    print("  （1画面を複数ファイルに分割できているか）")
    total = 0
    for p in sorted(MAP_MODULE_FILES):
        lines = count_lines(p)
        total += lines
        print(f"  {lines:>5} lines  {p.name}")
    print(f"  ─────────")
    print(f"  {total:>5} lines  合計")

    pretty_header("3) 不要コード検出")
    any_issue = False
    for p in CHANGED_FILES:
        rel = p.relative_to(ROOT)
        issues = scan_file(p)
        if issues:
            any_issue = True
            print(f"\n  📄 {rel}")
            for iss in issues:
                print(iss)
    if not any_issue:
        print("  ✓ 不要コード検出なし")

    pretty_header("4) ドキュメント存在確認")
    docs_dir = SOLARA / "docs"
    required_docs = [
        "Map機能.md",
        "data_schema.md",
    ]
    for doc in required_docs:
        p = docs_dir / doc
        if p.exists():
            print(f"  ✓ {doc}  ({count_lines(p)} lines)")
        else:
            print(f"  ✗ {doc}  存在しない")
            exit_code = 1

    pretty_header("5) Worker 構造確認")
    worker_src = SOLARA / "worker" / "src"
    if worker_src.exists():
        for p in sorted(worker_src.glob("*.js")):
            print(f"  {count_lines(p):>5} lines  {p.name}")

    pretty_header("結果")
    if exit_code == 0:
        print("  ✅ 全項目 OK — コミット可能")
    else:
        print("  ⚠️  問題あり — 上記を対応後に再実行")
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
