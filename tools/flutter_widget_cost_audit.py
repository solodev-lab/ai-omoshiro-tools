#!/usr/bin/env python3
"""
Flutter Widget Cost Audit
=========================

Flutter (Dart) のソースを静的にスキャンして、Surface buffer / GPU sync object を
過剰消費しがちな高コスト widget の使用箇所を網羅検出するツール。

HTML/CSS の見た目を機械的に Flutter に移植したときに陥る「同名でも実装コストが
全く違うウィジェット (BackdropFilter / ColorFiltered / 動的 BoxShadow など)」の
検出を目的とする。

実行:
  python tools/flutter_widget_cost_audit.py [--target apps/solara/lib]

出力:
  tools/flutter_widget_cost_audit_report.md  (Markdown レポート)
  終了コード 1 = 🔴 Critical 検出あり (CI で fail させたいときに使う)

参考:
  ~/.claude/projects/E--AppCreate/memory/feedback_html_costly_widgets.md
"""
from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterator

# Windows の cp932 で文字化けしないよう stdout/stderr を UTF-8 に
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except (AttributeError, ValueError):
        pass


# ─────────────────────────────────────────────────
# データ構造
# ─────────────────────────────────────────────────
@dataclass
class Finding:
    file: Path
    line: int
    pattern: str  # "BackdropFilter" / "ColorFiltered" / "blurRadius_dynamic" 等
    risk: str  # "critical" / "warning" / "info"
    snippet: str  # 該当行 (前後 1-2 行含む)
    note: str = ""  # 補足


@dataclass
class FileContext:
    path: Path
    lines: list[str]
    has_repeat: bool = False  # AnimationController.repeat() を持つか
    repeat_lines: list[int] = field(default_factory=list)
    classification: str = "unknown"  # "always-visible" / "popup" / "unknown"


# ─────────────────────────────────────────────────
# ファイル分類 (ヒューリスティクス)
# ─────────────────────────────────────────────────
ALWAYS_VISIBLE_HINTS = [
    "nav_bar",
    "_screen.dart",
    "home.dart",
    "_layer.dart",
    "main.dart",
    "_body.dart",
    "_chart.dart",  # 永続的にチャート表示する系も含めておく
]
POPUP_HINTS = [
    "_overlay.dart",
    "_popup.dart",
    "_dialog.dart",
    "_sheet.dart",
    "_diagnosis.dart",
    "_picker.dart",
]


def classify_file(path: Path) -> str:
    name = path.name.lower()
    full = str(path).lower().replace("\\", "/")
    for hint in POPUP_HINTS:
        if hint in name or hint in full:
            return "popup"
    for hint in ALWAYS_VISIBLE_HINTS:
        if hint in name or hint in full:
            return "always-visible"
    return "unknown"


# ─────────────────────────────────────────────────
# 動的判定: BoxShadow パラメータの値が「アニメ可能性のある式」か
# ─────────────────────────────────────────────────
# 純粋な数値リテラル (例: 14, 14.0, 0, 1.5)
_NUMERIC_LITERAL = re.compile(r"^\s*-?\d+(\.\d+)?\s*$")
# const double 等の名前付き定数を許容したい場合のパターン
_CONST_NAME = re.compile(r"^\s*[A-Z_]{2,}[A-Z0-9_]*\s*$")


def is_static_value(value: str) -> bool:
    """値が「明らかに静的 = アニメ不可」なら True を返す。
    安全側に倒し、判定に迷ったら False (動的扱い) を返す。
    """
    v = value.strip().rstrip(",").rstrip(")").strip()
    if not v:
        return True
    # 数値リテラルだけは静的
    if _NUMERIC_LITERAL.match(v):
        return True
    # 全大文字定数 (PI, MAX_BLUR 等) は static const と仮定
    if _CONST_NAME.match(v):
        return True
    return False


# ─────────────────────────────────────────────────
# 個別検出関数
# ─────────────────────────────────────────────────
RE_BACKDROP_FILTER = re.compile(r"\bBackdropFilter\s*\(")
RE_COLOR_FILTERED = re.compile(r"\bColorFiltered\s*\(")
RE_IMAGE_FILTERED = re.compile(r"\bImageFiltered\s*\(")
RE_MASK_FILTER_BLUR = re.compile(r"\bMaskFilter\.blur\s*\(")
RE_REPEAT = re.compile(r"\.\.\s*repeat\s*\(")
RE_BLUR_RADIUS = re.compile(r"\bblurRadius\s*:\s*(.+?)(?:,|$|\))")
RE_SPREAD_RADIUS = re.compile(r"\bspreadRadius\s*:\s*(.+?)(?:,|$|\))")
RE_BOX_SHADOW_OPEN = re.compile(r"boxShadow\s*:\s*(?:const\s*)?\[")
RE_BOX_SHADOW_CTOR = re.compile(r"\bBoxShadow\s*\(")


def snippet_for(lines: list[str], idx: int, before: int = 1, after: int = 1) -> str:
    start = max(0, idx - before)
    end = min(len(lines), idx + after + 1)
    out: list[str] = []
    for i in range(start, end):
        marker = ">>" if i == idx else "  "
        out.append(f"{marker} {i + 1:>4}: {lines[i].rstrip()}")
    return "\n".join(out)


def detect_in_file(ctx: FileContext) -> list[Finding]:
    findings: list[Finding] = []
    lines = ctx.lines

    # ── 1) AnimationController.repeat() の場所を先に集める (リスク補強用)
    for i, line in enumerate(lines):
        if RE_REPEAT.search(line):
            ctx.has_repeat = True
            ctx.repeat_lines.append(i + 1)

    # ── 2) BackdropFilter
    for i, line in enumerate(lines):
        if RE_BACKDROP_FILTER.search(line):
            risk = "critical" if ctx.classification == "always-visible" else (
                "warning" if ctx.classification == "popup" else "warning"
            )
            findings.append(
                Finding(
                    file=ctx.path,
                    line=i + 1,
                    pattern="BackdropFilter",
                    risk=risk,
                    snippet=snippet_for(lines, i),
                    note=(
                        "毎フレーム背景を別 Surface buffer に描画し blur する。"
                        " 常時表示で使うと致命、popup でも開いている間は重い。"
                    ),
                )
            )

    # ── 3) ColorFiltered
    for i, line in enumerate(lines):
        if RE_COLOR_FILTERED.search(line):
            # tileBuilder / itemBuilder / per-element ループ内の使用は per-N コスト
            risk = "warning"
            note_extra = ""
            window = " ".join(lines[max(0, i - 5) : i + 1])
            if any(
                kw in window
                for kw in ["tileBuilder", "itemBuilder", "ListView", "GridView", "for ("]
            ):
                risk = "critical"
                note_extra = " (per-tile / per-item で繰り返し適用される文脈)"
            findings.append(
                Finding(
                    file=ctx.path,
                    line=i + 1,
                    pattern="ColorFiltered",
                    risk=risk,
                    snippet=snippet_for(lines, i),
                    note="各タイル/アイテム毎に offscreen layer を作り Surface buffer 倍増の可能性"
                    + note_extra,
                )
            )

    # ── 4) ImageFiltered
    for i, line in enumerate(lines):
        if RE_IMAGE_FILTERED.search(line):
            findings.append(
                Finding(
                    file=ctx.path,
                    line=i + 1,
                    pattern="ImageFiltered",
                    risk="warning",
                    snippet=snippet_for(lines, i),
                    note="毎フレーム画像にフィルタ適用。動的引数だと致命。",
                )
            )

    # ── 5) MaskFilter.blur (CustomPainter 内)
    for i, line in enumerate(lines):
        m = RE_MASK_FILTER_BLUR.search(line)
        if not m:
            continue
        # 引数 sigma が動的かどうかを軽く確認
        # MaskFilter.blur(BlurStyle.normal, 5 * scale) ← scale が動的ならアニメ
        after = line[m.end() :]
        # `BlurStyle.xxx, <sigma>)` の sigma 部分を抜き出す
        sigma_match = re.search(r"BlurStyle\.[a-zA-Z]+\s*,\s*(.+?)\s*\)", after)
        sigma_value = sigma_match.group(1) if sigma_match else "?"
        is_dynamic = not is_static_value(sigma_value)
        findings.append(
            Finding(
                file=ctx.path,
                line=i + 1,
                pattern="MaskFilter.blur",
                risk="warning" if is_dynamic else "info",
                snippet=snippet_for(lines, i),
                note=f"sigma = `{sigma_value}` "
                + ("(動的の可能性、毎 paint で再計算)" if is_dynamic else "(静的、許容)"),
            )
        )

    # ── 6) blurRadius / spreadRadius の動的検出
    for i, line in enumerate(lines):
        for prop_re, prop_name in [
            (RE_BLUR_RADIUS, "blurRadius"),
            (RE_SPREAD_RADIUS, "spreadRadius"),
        ]:
            m = prop_re.search(line)
            if not m:
                continue
            value = m.group(1)
            if is_static_value(value):
                continue
            # 動的: AnimationController.repeat() を持つファイルなら critical
            risk = "critical" if ctx.has_repeat else "warning"
            note = (
                f"{prop_name} = `{value.strip()}` (動的)。Flutter は blurRadius を変動させると "
                "毎フレーム blur 再計算で Surface buffer 大量生成。"
                "alpha だけ変動させて blur/spread は固定値にすべき。"
            )
            if ctx.has_repeat:
                note += f" (このファイルに `..repeat(` あり 行 {ctx.repeat_lines[:3]})"
            findings.append(
                Finding(
                    file=ctx.path,
                    line=i + 1,
                    pattern=f"{prop_name} dynamic",
                    risk=risk,
                    snippet=snippet_for(lines, i),
                    note=note,
                )
            )

    # ── 7) 多段 BoxShadow (3 個以上)
    # boxShadow: [ から ] までの間に BoxShadow( が何個あるか
    in_shadow_list = False
    shadow_count = 0
    shadow_start_line = 0
    bracket_depth = 0
    for i, line in enumerate(lines):
        if not in_shadow_list:
            if RE_BOX_SHADOW_OPEN.search(line):
                in_shadow_list = True
                shadow_count = 0
                shadow_start_line = i + 1
                bracket_depth = line.count("[") - line.count("]")
                shadow_count += len(RE_BOX_SHADOW_CTOR.findall(line))
        else:
            shadow_count += len(RE_BOX_SHADOW_CTOR.findall(line))
            bracket_depth += line.count("[") - line.count("]")
            if bracket_depth <= 0:
                if shadow_count >= 3:
                    findings.append(
                        Finding(
                            file=ctx.path,
                            line=shadow_start_line,
                            pattern=f"BoxShadow x{shadow_count}",
                            risk="warning",
                            snippet=snippet_for(lines, shadow_start_line - 1, 0, 4),
                            note=f"BoxShadow が {shadow_count} 段。各影は別レイヤー化されることがあり、合算コストが大きい。",
                        )
                    )
                in_shadow_list = False
                shadow_count = 0

    return findings


# ─────────────────────────────────────────────────
# スキャン本体
# ─────────────────────────────────────────────────
def scan(target: Path) -> tuple[list[Finding], int]:
    """対象ディレクトリ配下の .dart ファイルを全件スキャン。"""
    files = sorted(target.rglob("*.dart"))
    # Generated / build / .dart_tool 除外
    files = [
        p
        for p in files
        if all(
            seg not in p.parts
            for seg in (".dart_tool", "build", ".pub-cache", "generated_plugin_registrant")
        )
        and not p.name.endswith(".g.dart")
        and not p.name.endswith(".freezed.dart")
    ]
    all_findings: list[Finding] = []
    for path in files:
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            try:
                text = path.read_text(encoding="cp932")
            except Exception:
                continue
        ctx = FileContext(
            path=path,
            lines=text.splitlines(),
            classification=classify_file(path),
        )
        all_findings.extend(detect_in_file(ctx))
    return all_findings, len(files)


# ─────────────────────────────────────────────────
# レポート生成
# ─────────────────────────────────────────────────
def relpath(p: Path, base: Path) -> str:
    try:
        return str(p.relative_to(base)).replace("\\", "/")
    except ValueError:
        return str(p).replace("\\", "/")


def render_report(findings: list[Finding], target: Path, scanned_count: int) -> str:
    base = Path.cwd()
    lines: list[str] = []
    lines.append("# Flutter Widget Cost Audit Report")
    lines.append("")
    lines.append(f"- Target: `{relpath(target, base)}`")
    lines.append(f"- Files scanned: **{scanned_count}**")

    by_risk: dict[str, list[Finding]] = {"critical": [], "warning": [], "info": []}
    for f in findings:
        by_risk.setdefault(f.risk, []).append(f)

    lines.append(f"- 🔴 Critical: **{len(by_risk['critical'])}**")
    lines.append(f"- 🟡 Warning:  **{len(by_risk['warning'])}**")
    lines.append(f"- ⚪ Info:     **{len(by_risk['info'])}**")
    lines.append("")
    lines.append(
        "リスク基準: HTML→Flutter 移植で出やすい高コスト widget のうち、"
        "常時表示領域 / アニメ blur / per-tile/item 適用を **致命**、"
        "popup などで使われているものを **警告** とする。"
    )
    lines.append("")
    lines.append(
        "_詳細: `~/.claude/projects/E--AppCreate/memory/feedback_html_costly_widgets.md`_"
    )
    lines.append("")

    for risk_key, label, emoji in [
        ("critical", "Critical", "🔴"),
        ("warning", "Warning", "🟡"),
        ("info", "Info", "⚪"),
    ]:
        items = by_risk.get(risk_key, [])
        if not items:
            continue
        lines.append(f"## {emoji} {label} ({len(items)})")
        lines.append("")
        # ファイルごとにグループ化
        by_file: dict[Path, list[Finding]] = {}
        for f in items:
            by_file.setdefault(f.file, []).append(f)
        for path, group in sorted(by_file.items(), key=lambda kv: str(kv[0])):
            cls = classify_file(path)
            lines.append(f"### `{relpath(path, base)}`  _[{cls}]_")
            lines.append("")
            for f in sorted(group, key=lambda x: x.line):
                lines.append(f"- **L{f.line}** `{f.pattern}` — {f.note}")
                lines.append("")
                lines.append("  ```dart")
                for sl in f.snippet.splitlines():
                    lines.append(f"  {sl}")
                lines.append("  ```")
                lines.append("")
        lines.append("")
    return "\n".join(lines) + "\n"


# ─────────────────────────────────────────────────
# CLI
# ─────────────────────────────────────────────────
def main() -> int:
    parser = argparse.ArgumentParser(
        description="Flutter Widget Cost Audit - HTML porting cost trap detector"
    )
    parser.add_argument(
        "--target",
        type=Path,
        default=Path("apps/solara/lib"),
        help="走査するディレクトリ (デフォルト apps/solara/lib)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(__file__).parent / "flutter_widget_cost_audit_report.md",
        help="レポート出力先",
    )
    parser.add_argument(
        "--fail-on-critical",
        action="store_true",
        help="🔴 Critical を検出したら終了コード 1 (CI 用)",
    )
    args = parser.parse_args()

    target = args.target.resolve()
    if not target.exists():
        print(f"ERROR: target が存在しません: {target}")
        return 2

    print(f"Scanning {target} ...")
    findings, scanned = scan(target)
    print(f"Scanned {scanned} .dart files")
    print(f"Findings: {len(findings)}")

    report = render_report(findings, target, scanned)
    args.output.write_text(report, encoding="utf-8")
    print(f"Report: {args.output}")

    by_risk = {"critical": 0, "warning": 0, "info": 0}
    for f in findings:
        by_risk[f.risk] = by_risk.get(f.risk, 0) + 1
    print()
    print(f"  🔴 Critical: {by_risk['critical']}")
    print(f"  🟡 Warning:  {by_risk['warning']}")
    print(f"  ⚪ Info:     {by_risk['info']}")

    if args.fail_on_critical and by_risk["critical"] > 0:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
