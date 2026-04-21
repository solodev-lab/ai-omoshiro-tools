"""
ファイル分割の健全性チェック
- lib/screens/map/ 配下の各ファイルの行数・責務・相互依存を確認
- 目安: 1ファイル 300行以下を望ましいライン、500行超は分割検討
"""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1] / "lib"
THRESHOLD_WARN = 300
THRESHOLD_CRIT = 500

def count_lines(p: Path) -> int:
    return sum(1 for _ in p.read_text(encoding="utf-8", errors="ignore").splitlines())

def scan_imports(p: Path) -> list[str]:
    text = p.read_text(encoding="utf-8", errors="ignore")
    return re.findall(r"^import\s+['\"]([^'\"]+)['\"]", text, re.MULTILINE)

def count_top_level_symbols(p: Path) -> dict[str, int]:
    text = p.read_text(encoding="utf-8", errors="ignore")
    return {
        "class": len(re.findall(r"^class\s+\w+", text, re.MULTILINE)),
        "fn":    len(re.findall(r"^(?:[A-Za-z_][\w<>?,\s]*\s+)?\w+\s*\([^)]*\)\s*(?:async\s*)?\{", text, re.MULTILINE)),
    }

def main() -> int:
    targets = sorted(ROOT.rglob("*.dart"))
    if not targets:
        print("No dart files found under", ROOT)
        return 1

    print(f"{'file':<60} {'lines':>6} {'cls':>4} {'imp':>4}  status")
    print("-" * 90)

    crit = 0
    warn = 0
    total_lines = 0

    for p in targets:
        lines = count_lines(p)
        total_lines += lines
        syms = count_top_level_symbols(p)
        imports = scan_imports(p)
        rel = p.relative_to(ROOT.parent).as_posix()
        status = "OK"
        if lines > THRESHOLD_CRIT:
            status = "CRIT (要分割)"
            crit += 1
        elif lines > THRESHOLD_WARN:
            status = "WARN"
            warn += 1
        print(f"{rel:<60} {lines:>6} {syms['class']:>4} {len(imports):>4}  {status}")

    print("-" * 90)
    print(f"total files: {len(targets)}  total lines: {total_lines}")
    print(f"WARN (>{THRESHOLD_WARN}): {warn}  CRIT (>{THRESHOLD_CRIT}): {crit}")

    # map/ 配下は特に細かく
    print("\n--- map/ 配下サマリー ---")
    map_dir = ROOT / "screens" / "map"
    if map_dir.exists():
        for p in sorted(map_dir.glob("*.dart")):
            lines = count_lines(p)
            syms = count_top_level_symbols(p)
            print(f"  {p.name:<30} {lines:>4} lines  classes={syms['class']}")

    return 0 if crit == 0 else 2

if __name__ == "__main__":
    sys.exit(main())
