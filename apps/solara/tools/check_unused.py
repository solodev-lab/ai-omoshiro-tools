"""
map/ 配下で未使用シンボル（関数・クラス・定数）を検出する。
各シンボル名を lib/ 全体で grep し、定義以外の参照が無ければ未使用候補として報告。

注意:
- public な Widget など外部から import されている物は残る
- 呼び出し側が動的解決（Map lookup 等）の場合は誤検知する
- あくまで削除「候補」を示すツール
"""
from pathlib import Path
import re
import sys

SOLARA_LIB = Path(__file__).resolve().parents[1] / "lib"
TARGET_DIR = SOLARA_LIB / "screens" / "map"

# トップレベル定義の抽出パターン
PATTERNS = {
    "class":    re.compile(r"^class\s+(\w+)", re.MULTILINE),
    "mixin":    re.compile(r"^mixin\s+(\w+)", re.MULTILINE),
    "enum":     re.compile(r"^enum\s+(\w+)", re.MULTILINE),
    "function": re.compile(r"^(?:(?:Future|Stream|Map|List|Set|Iterable|String|int|double|bool|void|num|dynamic|[A-Z]\w*)[\w<>?,\s]*\s+)(\w+)\s*\(", re.MULTILINE),
    "const":    re.compile(r"^(?:const|final)\s+(?:[\w<>?,\s]+\s+)?(\w+)\s*=", re.MULTILINE),
}

# 名前がこのパターンなら private で外部参照検知対象外
PRIVATE = re.compile(r"^_")

def list_symbols(p: Path) -> list[tuple[str, str]]:
    text = p.read_text(encoding="utf-8", errors="ignore")
    out: list[tuple[str, str]] = []
    seen = set()
    for kind, pat in PATTERNS.items():
        for m in pat.finditer(text):
            name = m.group(1)
            if name in seen:
                continue
            seen.add(name)
            out.append((kind, name))
    return out

def search_refs(name: str, exclude: Path) -> int:
    """lib/ 全体で name の参照数（定義ファイル除外）"""
    pat = re.compile(r"\b" + re.escape(name) + r"\b")
    count = 0
    for p in SOLARA_LIB.rglob("*.dart"):
        if p == exclude:
            continue
        try:
            text = p.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue
        count += len(pat.findall(text))
    return count

def main() -> int:
    print(f"=== map/ 配下の未使用候補スキャン ===\n")
    total = 0
    suspects: list[tuple[str, str, str]] = []

    for p in sorted(TARGET_DIR.glob("*.dart")):
        symbols = list_symbols(p)
        for kind, name in symbols:
            if PRIVATE.match(name):
                # private は同ファイル内で使われていれば OK (そもそも外部参照されない)
                defined_in_file = p.read_text(encoding="utf-8", errors="ignore").count(name)
                if defined_in_file <= 1:
                    suspects.append((p.name, kind, name + " (private, 自ファイル内0参照)"))
                continue
            # public: 自ファイル内の使用回数も確認
            total += 1
            refs = search_refs(name, p)
            own = p.read_text(encoding="utf-8", errors="ignore").count(name)
            if refs == 0 and own <= 1:
                suspects.append((p.name, kind, name))

    print(f"検査対象 public シンボル: {total}")
    print(f"未使用候補: {len(suspects)}\n")
    if suspects:
        print(f"{'file':<30} {'kind':<10} name")
        print("-" * 70)
        for f, k, n in suspects:
            print(f"{f:<30} {k:<10} {n}")
    else:
        print("未使用シンボルは検出されませんでした。")

    return 0

if __name__ == "__main__":
    sys.exit(main())
