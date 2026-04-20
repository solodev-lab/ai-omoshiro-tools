"""Verify fortune_overlays file structure and look for issues.

- ファイル存在確認
- 各ファイルの行数
- import 関係
- 未使用の import
- 各 PainterBuilder クラスが存在するか
- MapScreen と dominant_fortune_overlay の接続確認
"""
from pathlib import Path
import re
import sys

REPO = Path(__file__).resolve().parents[3]  # .../AppCreate
SOLARA = REPO / "apps" / "solara"
OVERLAYS_DIR = SOLARA / "lib" / "widgets" / "fortune_overlays"
DISPATCHER = SOLARA / "lib" / "widgets" / "dominant_fortune_overlay.dart"
MAP_SCREEN = SOLARA / "lib" / "screens" / "map_screen.dart"

EXPECTED_FILES = [
    "_common.dart",
    "love_painter.dart",
    "money_painter.dart",
    "healing_painter.dart",
    "communication_painter.dart",
    "work_painter.dart",
]

EXPECTED_BUILDERS = [
    ("love_painter.dart", "LovePainterBuilder"),
    ("money_painter.dart", "MoneyPainterBuilder"),
    ("healing_painter.dart", "HealingPainterBuilder"),
    ("communication_painter.dart", "CommunicationPainterBuilder"),
    ("work_painter.dart", "WorkPainterBuilder"),
]


def read(p: Path) -> str:
    return p.read_text(encoding="utf-8")


def count_lines(p: Path) -> int:
    return len(p.read_text(encoding="utf-8").splitlines())


def find_imports(content: str) -> list[str]:
    return re.findall(r"^import\s+['\"]([^'\"]+)['\"]", content, re.M)


def find_class_names(content: str) -> list[str]:
    return re.findall(r"^class\s+(\w+)", content, re.M)


def find_top_level_funcs(content: str) -> list[str]:
    return re.findall(r"^(?:double|int|String|void|bool|dynamic|Color|Path)\s+(\w+)\s*\(", content, re.M)


def section(title: str) -> None:
    print()
    print("=" * 70)
    print(f"  {title}")
    print("=" * 70)


def check_files_exist() -> bool:
    section("[1] fortune_overlays ディレクトリの構成")
    if not OVERLAYS_DIR.exists():
        print(f"  NG: ディレクトリが存在しない: {OVERLAYS_DIR}")
        return False

    ok = True
    for name in EXPECTED_FILES:
        p = OVERLAYS_DIR / name
        if p.exists():
            print(f"  OK {name:<32} {count_lines(p):>5} lines")
        else:
            print(f"  NG {name} が存在しない")
            ok = False

    # 不要ファイルがないか
    extras = set(p.name for p in OVERLAYS_DIR.iterdir() if p.is_file()) - set(EXPECTED_FILES)
    if extras:
        print(f"  WARN 想定外のファイル: {sorted(extras)}")
    return ok


def check_dispatcher() -> bool:
    section("[2] dispatcher (dominant_fortune_overlay.dart)")
    if not DISPATCHER.exists():
        print(f"  NG: {DISPATCHER} が存在しない")
        return False
    content = read(DISPATCHER)
    print(f"  OK {DISPATCHER.name} ({count_lines(DISPATCHER)} lines)")

    # 全ビルダーが import されているか
    imports = find_imports(content)
    ok = True
    for fname, builder in EXPECTED_BUILDERS:
        if any(fname in i for i in imports):
            print(f"  OK import {fname}")
        else:
            print(f"  NG import 不足: {fname}")
            ok = False

    # switch 分岐で全ビルダーを生成しているか
    for _, builder in EXPECTED_BUILDERS:
        if re.search(rf"\b{builder}\s*\(\s*\)", content):
            print(f"  OK switch: {builder}()")
        else:
            print(f"  NG switch 生成不足: {builder}")
            ok = False

    # enum DominantFortuneKind 定義
    if re.search(r"enum\s+DominantFortuneKind\s*\{", content):
        print("  OK enum DominantFortuneKind 定義")
    else:
        print("  NG enum DominantFortuneKind が見つからない")
        ok = False

    return ok


def check_builders() -> bool:
    section("[3] 各 PainterBuilder クラスの存在")
    ok = True
    for fname, builder in EXPECTED_BUILDERS:
        p = OVERLAYS_DIR / fname
        content = read(p)
        classes = find_class_names(content)
        if builder in classes:
            # FortunePainterBuilder を継承しているか
            if re.search(rf"class\s+{builder}\s+extends\s+FortunePainterBuilder", content):
                print(f"  OK {builder} extends FortunePainterBuilder")
            else:
                print(f"  WARN {builder} は FortunePainterBuilder を継承していない可能性")
        else:
            print(f"  NG {builder} が {fname} に見つからない")
            ok = False
    return ok


def check_common() -> bool:
    section("[4] _common.dart の内容")
    p = OVERLAYS_DIR / "_common.dart"
    content = read(p)
    needed_funcs = ["easeOutCubic", "easeOutBack", "stageAlpha"]
    ok = True
    for f in needed_funcs:
        if re.search(rf"double\s+{f}\s*\(", content):
            print(f"  OK {f}")
        else:
            print(f"  NG {f} が見つからない")
            ok = False
    if re.search(r"abstract\s+class\s+FortunePainterBuilder", content):
        print("  OK abstract FortunePainterBuilder")
    else:
        print("  NG abstract FortunePainterBuilder が見つからない")
        ok = False
    return ok


def check_dead_imports() -> bool:
    """各ファイルの import が実際に使われているか軽く確認."""
    section("[5] 未使用 import チェック")
    ok = True
    for p in OVERLAYS_DIR.iterdir():
        if not p.suffix == ".dart":
            continue
        content = read(p)
        imports = find_imports(content)
        for imp in imports:
            # 標準ライブラリ: dart:math as math, dart:ui as ui
            if imp.startswith("dart:math"):
                # as math で使用されているか
                if re.search(r"\bmath\.", content):
                    continue
                else:
                    print(f"  WARN {p.name}: import '{imp}' が使われていない可能性")
                    ok = False
            elif imp.startswith("dart:ui"):
                if re.search(r"\bui\.", content):
                    continue
                else:
                    print(f"  WARN {p.name}: import '{imp}' が使われていない可能性")
                    ok = False
            elif imp == "package:flutter/material.dart":
                # Material/Flutter クラスを何か使っているか
                if re.search(r"\b(Canvas|Paint|Path|Offset|Color|Size|Rect|CustomPainter|Colors)\b", content):
                    continue
                else:
                    print(f"  WARN {p.name}: material.dart が使われていない可能性")
                    ok = False
            elif imp.endswith("_common.dart") or "fortune_overlays/" in imp:
                # 共通ヘルパが使われているか
                if re.search(r"\b(stageAlpha|easeOutCubic|easeOutBack|easeInOutQuad|FortunePainterBuilder)\b", content):
                    continue
                else:
                    print(f"  WARN {p.name}: _common.dart の関数が使われていない可能性")
    if ok:
        print("  OK 未使用 import は検出されず")
    return ok


def check_map_screen() -> bool:
    section("[6] MapScreen との接続")
    if not MAP_SCREEN.exists():
        print(f"  NG: {MAP_SCREEN} が存在しない")
        return False
    content = read(MAP_SCREEN)
    ok = True

    checks = [
        (r"import\s+['\"].*dominant_fortune_overlay\.dart['\"]", "dispatcher import"),
        (r"DominantFortuneOverlay\s*\(", "DominantFortuneOverlay ウィジェット使用"),
        (r"_debugAlwaysShowOverlay", "_debugAlwaysShowOverlay フラグ"),
        (r"_debugCycleOverlayKinds", "_debugCycleOverlayKinds フラグ"),
        (r"_debugCycleOrder", "_debugCycleOrder 定義"),
        (r"_implementedOverlayKinds", "_implementedOverlayKinds 定義"),
        (r"_onMapTap", "_onMapTap ハンドラ"),
        (r"onTap:\s*\(_,\s*_\)\s*=>\s*_onMapTap", "Map onTap 接続"),
    ]
    for pat, desc in checks:
        if re.search(pat, content):
            print(f"  OK {desc}")
        else:
            print(f"  NG {desc} が見つからない")
            ok = False

    # 5つのカテゴリ全てが _implementedOverlayKinds に含まれているか
    block_match = re.search(
        r"_implementedOverlayKinds\s*=\s*<DominantFortuneKind>\{([^}]*)\}",
        content,
    )
    if block_match:
        block = block_match.group(1)
        for cat in ["love", "money", "healing", "communication", "work"]:
            if f"DominantFortuneKind.{cat}" in block:
                print(f"  OK {cat} が _implementedOverlayKinds に登録済み")
            else:
                print(f"  NG {cat} が _implementedOverlayKinds に未登録")
                ok = False
    return ok


def check_debug_flags() -> bool:
    section("[7] デバッグフラグの値（本番化時の参考）")
    content = read(MAP_SCREEN)
    flags = re.findall(
        r"const\s+bool\s+(_debug\w+)\s*=\s*(true|false)", content
    )
    for name, val in flags:
        marker = "(本番で false 推奨)" if val == "true" else ""
        print(f"  {name} = {val} {marker}")
    return True


def main() -> int:
    print(f"REPO: {REPO}")
    print(f"SOLARA: {SOLARA}")
    results = [
        check_files_exist(),
        check_dispatcher(),
        check_builders(),
        check_common(),
        check_dead_imports(),
        check_map_screen(),
        check_debug_flags(),
    ]
    section("[結果サマリ]")
    passed = sum(1 for r in results if r)
    total = len(results)
    print(f"  {passed}/{total} passed")
    return 0 if all(results) else 1


if __name__ == "__main__":
    sys.exit(main())
