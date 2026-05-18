#!/usr/bin/env python3
"""
Flutter Widget Cost Audit v2
============================

v1 (flutter_widget_cost_audit.py) の検出に加え、saveLayer trigger 系を網羅。

追加検出:
- Opacity widget (alpha < 1.0 で saveLayer trigger)
- AnimatedOpacity / FadeTransition (Animation × Opacity)
- ShaderMask (saveLayer)
- ClipPath / ClipRRect with antiAliasWithSaveLayer / ClipOval
- canvas.saveLayer 直接呼び出し (CustomPainter 内)
- ImageFilter.blur 内の動的 sigma

実行: python tools/flutter_widget_cost_audit_v2.py [--target apps/solara/lib]
出力: tools/flutter_widget_cost_audit_v2_report.md
参考: ~/.claude/projects/E--AppCreate/memory/feedback_html_costly_widgets.md
"""
from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except (AttributeError, ValueError):
        pass


@dataclass
class Finding:
    file: Path
    line: int
    pattern: str
    risk: str  # critical / warning / info
    snippet: str
    note: str = ""


@dataclass
class FileContext:
    path: Path
    lines: list[str]
    has_repeat: bool = False
    repeat_lines: list[int] = field(default_factory=list)
    classification: str = "unknown"


ALWAYS_VISIBLE_HINTS = [
    "nav_bar", "_screen.dart", "home.dart", "_layer.dart",
    "main.dart", "_body.dart", "_chart.dart",
]
POPUP_HINTS = [
    "_overlay.dart", "_popup.dart", "_dialog.dart", "_sheet.dart",
    "_diagnosis.dart", "_picker.dart",
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


_NUMERIC_LITERAL = re.compile(r"^\s*-?\d+(\.\d+)?\s*$")
_CONST_NAME = re.compile(r"^\s*[A-Z_]{2,}[A-Z0-9_]*\s*$")


def is_static_value(value: str) -> bool:
    v = value.strip().rstrip(",").rstrip(")").strip()
    if not v:
        return True
    if _NUMERIC_LITERAL.match(v):
        return True
    if _CONST_NAME.match(v):
        return True
    return False


def is_opacity_one(value: str) -> bool:
    v = value.strip().rstrip(",").rstrip(")").strip()
    return v in ("1", "1.0", "1.00", "1.000")


# v1 既存
RE_BACKDROP_FILTER = re.compile(r"\bBackdropFilter\s*\(")
RE_COLOR_FILTERED = re.compile(r"\bColorFiltered\s*\(")
RE_IMAGE_FILTERED = re.compile(r"\bImageFiltered\s*\(")
RE_MASK_FILTER_BLUR = re.compile(r"\bMaskFilter\.blur\s*\(")
RE_REPEAT = re.compile(r"\.\.\s*repeat\s*\(")
RE_BLUR_RADIUS = re.compile(r"\bblurRadius\s*:\s*(.+?)(?:,|$|\))")
RE_SPREAD_RADIUS = re.compile(r"\bspreadRadius\s*:\s*(.+?)(?:,|$|\))")
RE_BOX_SHADOW_OPEN = re.compile(r"boxShadow\s*:\s*(?:const\s*)?\[")
RE_BOX_SHADOW_CTOR = re.compile(r"\bBoxShadow\s*\(")

# v2 追加
# Opacity (Animated/Sliver を除外)
RE_OPACITY = re.compile(r"(?<![\.A-Za-z])Opacity\s*\(")
RE_OPACITY_ARG = re.compile(r"\bopacity\s*:\s*(.+?)(?:,|$|\))")
RE_ANIMATED_OPACITY = re.compile(r"\bAnimatedOpacity\s*\(")
RE_SLIVER_OPACITY = re.compile(r"\bSliverOpacity\s*\(")
RE_FADE_TRANSITION = re.compile(r"\bFadeTransition\s*\(")
RE_SLIVER_FADE_TRANSITION = re.compile(r"\bSliverFadeTransition\s*\(")
RE_SHADER_MASK = re.compile(r"\bShaderMask\s*\(")
RE_CLIP_PATH = re.compile(r"\bClipPath\s*\(")
RE_CLIP_RRECT = re.compile(r"\bClipRRect\s*\(")
RE_CLIP_OVAL = re.compile(r"\bClipOval\s*\(")
# CustomPainter 内の生 saveLayer 呼び出し (canvas.saveLayer / c.saveLayer)
RE_CANVAS_SAVELAYER = re.compile(r"(?<![\w])(?:canvas|c)\.saveLayer\s*\(")
RE_IMAGE_FILTER_BLUR = re.compile(r"\bImageFilter\.blur\s*\(")
RE_SIGMA_ARG = re.compile(r"\bsigma[XY]\s*:\s*(.+?)(?:,|$|\))")
RE_ANTIALIAS_SAVELAYER = re.compile(r"\bClip\.antiAliasWithSaveLayer\b")


def snippet_for(lines, idx, before=1, after=1):
    start = max(0, idx - before)
    end = min(len(lines), idx + after + 1)
    out = []
    for i in range(start, end):
        marker = ">>" if i == idx else "  "
        out.append(f"{marker} {i + 1:>4}: {lines[i].rstrip()}")
    return "\n".join(out)


def detect_in_file(ctx: FileContext) -> list[Finding]:
    findings: list[Finding] = []
    lines = ctx.lines

    for i, line in enumerate(lines):
        if RE_REPEAT.search(line):
            ctx.has_repeat = True
            ctx.repeat_lines.append(i + 1)

    # v1 ── BackdropFilter
    for i, line in enumerate(lines):
        if RE_BACKDROP_FILTER.search(line):
            risk = "critical" if ctx.classification == "always-visible" else "warning"
            findings.append(Finding(
                file=ctx.path, line=i + 1, pattern="BackdropFilter", risk=risk,
                snippet=snippet_for(lines, i),
                note="毎フレーム背景を別 Surface buffer に描画し blur する。常時表示で使うと致命、popup でも開いている間は重い。",
            ))

    # v1 ── ColorFiltered
    for i, line in enumerate(lines):
        if RE_COLOR_FILTERED.search(line):
            risk = "warning"
            note_extra = ""
            window = " ".join(lines[max(0, i - 5):i + 1])
            if any(kw in window for kw in ["tileBuilder", "itemBuilder", "ListView", "GridView", "for ("]):
                risk = "critical"
                note_extra = " (per-tile / per-item で繰り返し適用される文脈)"
            findings.append(Finding(
                file=ctx.path, line=i + 1, pattern="ColorFiltered", risk=risk,
                snippet=snippet_for(lines, i),
                note="各タイル/アイテム毎に offscreen layer を作り Surface buffer 倍増の可能性" + note_extra,
            ))

    # v1 ── ImageFiltered
    for i, line in enumerate(lines):
        if RE_IMAGE_FILTERED.search(line):
            findings.append(Finding(
                file=ctx.path, line=i + 1, pattern="ImageFiltered", risk="warning",
                snippet=snippet_for(lines, i),
                note="毎フレーム画像にフィルタ適用。動的引数だと致命。",
            ))

    # v1 ── MaskFilter.blur
    for i, line in enumerate(lines):
        m = RE_MASK_FILTER_BLUR.search(line)
        if not m:
            continue
        after = line[m.end():]
        sigma_match = re.search(r"BlurStyle\.[a-zA-Z]+\s*,\s*(.+?)\s*\)", after)
        sigma_value = sigma_match.group(1) if sigma_match else "?"
        is_dynamic = not is_static_value(sigma_value)
        findings.append(Finding(
            file=ctx.path, line=i + 1, pattern="MaskFilter.blur",
            risk="warning" if is_dynamic else "info",
            snippet=snippet_for(lines, i),
            note=f"sigma = `{sigma_value}` " + ("(動的の可能性、毎 paint で再計算)" if is_dynamic else "(静的、許容)"),
        ))

    # v1 ── blurRadius / spreadRadius 動的
    for i, line in enumerate(lines):
        for prop_re, prop_name in [(RE_BLUR_RADIUS, "blurRadius"), (RE_SPREAD_RADIUS, "spreadRadius")]:
            m = prop_re.search(line)
            if not m:
                continue
            value = m.group(1)
            if is_static_value(value):
                continue
            risk = "critical" if ctx.has_repeat else "warning"
            note = (
                f"{prop_name} = `{value.strip()}` (動的)。Flutter は blurRadius を変動させると "
                "毎フレーム blur 再計算で Surface buffer 大量生成。"
                "alpha だけ変動させて blur/spread は固定値にすべき。"
            )
            if ctx.has_repeat:
                note += f" (このファイルに `..repeat(` あり 行 {ctx.repeat_lines[:3]})"
            findings.append(Finding(
                file=ctx.path, line=i + 1, pattern=f"{prop_name} dynamic",
                risk=risk, snippet=snippet_for(lines, i), note=note,
            ))

    # v1 ── 多段 BoxShadow
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
                    findings.append(Finding(
                        file=ctx.path, line=shadow_start_line,
                        pattern=f"BoxShadow x{shadow_count}", risk="warning",
                        snippet=snippet_for(lines, shadow_start_line - 1, 0, 4),
                        note=f"BoxShadow が {shadow_count} 段。各影は別レイヤー化されることがあり、合算コストが大きい。",
                    ))
                in_shadow_list = False
                shadow_count = 0

    # v2 ── Opacity widget (1.0 以外)
    for i, line in enumerate(lines):
        if not RE_OPACITY.search(line):
            continue
        if RE_ANIMATED_OPACITY.search(line) or RE_SLIVER_OPACITY.search(line):
            continue  # 別途
        opacity_match = RE_OPACITY_ARG.search(line)
        opacity_value = opacity_match.group(1).strip() if opacity_match else "?"
        if is_opacity_one(opacity_value):
            continue
        is_dynamic = not is_static_value(opacity_value)
        if is_dynamic and ctx.has_repeat:
            risk = "critical"
        elif is_dynamic:
            risk = "warning"
        else:
            risk = "info"
        note = (
            f"Opacity(opacity: {opacity_value}) — alpha < 1.0 で saveLayer trigger。"
            " 動的な opacity は毎フレーム saveLayer。代わりに半透明 Color (Container/BoxDecoration) を使うべき。"
        )
        if ctx.has_repeat and is_dynamic:
            note += " (このファイルに `..repeat(` あり)"
        findings.append(Finding(
            file=ctx.path, line=i + 1, pattern="Opacity widget",
            risk=risk, snippet=snippet_for(lines, i), note=note,
        ))

    # v2 ── AnimatedOpacity / SliverOpacity
    for i, line in enumerate(lines):
        if RE_ANIMATED_OPACITY.search(line) or RE_SLIVER_OPACITY.search(line):
            findings.append(Finding(
                file=ctx.path, line=i + 1, pattern="AnimatedOpacity",
                risk="critical", snippet=snippet_for(lines, i),
                note="AnimatedOpacity は内部で Opacity widget を使い、Animation 中は saveLayer trigger。"
                     " 半透明 Color の AnimatedContainer / AnimatedDefaultTextStyle 等で代替可。",
            ))

    # v2 ── FadeTransition
    for i, line in enumerate(lines):
        if RE_FADE_TRANSITION.search(line) or RE_SLIVER_FADE_TRANSITION.search(line):
            findings.append(Finding(
                file=ctx.path, line=i + 1, pattern="FadeTransition",
                risk="critical", snippet=snippet_for(lines, i),
                note="FadeTransition は Opacity を Animation で動かす。saveLayer 多発。"
                     " 必要に応じて自前の AnimatedBuilder + Color alpha で代替を検討。",
            ))

    # v2 ── ShaderMask
    for i, line in enumerate(lines):
        if RE_SHADER_MASK.search(line):
            risk = "critical" if ctx.classification == "always-visible" else "warning"
            findings.append(Finding(
                file=ctx.path, line=i + 1, pattern="ShaderMask",
                risk=risk, snippet=snippet_for(lines, i),
                note="ShaderMask は saveLayer trigger。常時表示なら致命。"
                     " gradient 単色塗り or RenderObject 経由の代替を検討。",
            ))

    # v2 ── ClipPath
    for i, line in enumerate(lines):
        if RE_CLIP_PATH.search(line):
            findings.append(Finding(
                file=ctx.path, line=i + 1, pattern="ClipPath",
                risk="warning", snippet=snippet_for(lines, i),
                note="ClipPath は Path 形状でクリップ → デフォルト antialias で saveLayer trigger。"
                     " clipBehavior: Clip.hardEdge にすれば saveLayer 回避可能。",
            ))

    # v2 ── ClipRRect / ClipOval
    for i, line in enumerate(lines):
        for re_pat, name in [(RE_CLIP_RRECT, "ClipRRect"), (RE_CLIP_OVAL, "ClipOval")]:
            if not re_pat.search(line):
                continue
            window = " ".join(lines[i:min(len(lines), i + 5)])
            if RE_ANTIALIAS_SAVELAYER.search(window):
                findings.append(Finding(
                    file=ctx.path, line=i + 1,
                    pattern=f"{name} (antiAliasWithSaveLayer)",
                    risk="critical", snippet=snippet_for(lines, i),
                    note=f"{name} で `clipBehavior: Clip.antiAliasWithSaveLayer` 指定 = 明示的 saveLayer trigger。"
                         " 通常は antiAlias (default) で十分。",
                ))
            else:
                findings.append(Finding(
                    file=ctx.path, line=i + 1, pattern=name,
                    risk="info", snippet=snippet_for(lines, i),
                    note=f"{name} default は最適化されるが、巨大領域で常時使うと描画コスト発生。",
                ))

    # v2 ── canvas.saveLayer 直接
    for i, line in enumerate(lines):
        if RE_CANVAS_SAVELAYER.search(line):
            findings.append(Finding(
                file=ctx.path, line=i + 1, pattern="canvas.saveLayer (raw)",
                risk="critical", snippet=snippet_for(lines, i),
                note="CustomPainter 内で生 saveLayer 呼び出し。Surface buffer + sync_file を必ず生成。"
                     " paint() が毎フレーム呼ばれるなら毎フレーム leak 候補。可能なら Layer 化や合成を見直し。",
            ))

    # v2 ── 動的 ImageFilter.blur (sigmaX/Y が変数)
    for i, line in enumerate(lines):
        if not RE_IMAGE_FILTER_BLUR.search(line):
            continue
        sigma_match = RE_SIGMA_ARG.search(line)
        sigma_value = sigma_match.group(1).strip() if sigma_match else "?"
        if not is_static_value(sigma_value):
            findings.append(Finding(
                file=ctx.path, line=i + 1, pattern="ImageFilter.blur dynamic",
                risk="critical", snippet=snippet_for(lines, i),
                note=f"sigma = `{sigma_value}` (動的)。BackdropFilter/ImageFiltered 経由で毎フレーム blur 再計算。",
            ))

    return findings


def scan(target: Path) -> tuple[list[Finding], int]:
    files = sorted(target.rglob("*.dart"))
    files = [
        p for p in files
        if all(seg not in p.parts for seg in (".dart_tool", "build", ".pub-cache", "generated_plugin_registrant"))
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
        ctx = FileContext(path=path, lines=text.splitlines(), classification=classify_file(path))
        all_findings.extend(detect_in_file(ctx))
    return all_findings, len(files)


def relpath(p: Path, base: Path) -> str:
    try:
        return str(p.relative_to(base)).replace("\\", "/")
    except ValueError:
        return str(p).replace("\\", "/")


def render_report(findings: list[Finding], target: Path, scanned_count: int) -> str:
    base = Path.cwd()
    lines: list[str] = []
    lines.append("# Flutter Widget Cost Audit v2 Report")
    lines.append("")
    lines.append("v1 検出 + saveLayer trigger 系拡張 (Opacity / AnimatedOpacity / FadeTransition / ShaderMask / ClipPath / canvas.saveLayer / 動的 ImageFilter.blur)")
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
    lines.append("_詳細: `~/.claude/projects/E--AppCreate/memory/feedback_html_costly_widgets.md`_")
    lines.append("")

    for risk_key, label, emoji in [("critical", "Critical", "🔴"), ("warning", "Warning", "🟡"), ("info", "Info", "⚪")]:
        items = by_risk.get(risk_key, [])
        if not items:
            continue
        lines.append(f"## {emoji} {label} ({len(items)})")
        lines.append("")
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


def main() -> int:
    parser = argparse.ArgumentParser(description="Flutter Widget Cost Audit v2 - exhaustive saveLayer detector")
    parser.add_argument("--target", type=Path, default=Path("apps/solara/lib"))
    parser.add_argument("--output", type=Path, default=Path(__file__).parent / "flutter_widget_cost_audit_v2_report.md")
    parser.add_argument("--fail-on-critical", action="store_true")
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
