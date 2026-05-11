#!/usr/bin/env python3
"""
Solara Text Overflow 監査ツール
================================

apps/solara/lib 以下の全 .dart を scan し、RIGHT OVERFLOWED の
リスクがある Text 配置を検出してチェックリスト (Markdown) を生成。

検出パターン:
1. Row/Column の direct child に裸 Text( がある (Flexible/Expanded で囲まれていない)
2. Expanded/Flexible の child が Row(mainAxisSize: MainAxisSize.min) を内包する widget
   (AstroTermLabel など、内部 Row(min) で親制約を破壊するパターン)
3. Text() に maxLines / overflow 指定がない (1 行省略を意図しているが省略されない)

設計: feedback_text_overflow.md

使い方:
  python apps/solara/tools/text_overflow_audit/audit.py

出力:
  apps/solara/tools/text_overflow_audit/report.md (Markdown チェックリスト)
  終了コード: 0 (検出 0 件) / 1 (検出あり、PR ブロック用)
"""
from __future__ import annotations

import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable


# ─────────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────────

SCRIPT_DIR = Path(__file__).resolve().parent
SOLARA_ROOT = SCRIPT_DIR.parent.parent  # apps/solara
LIB_ROOT = SOLARA_ROOT / "lib"
REPORT_PATH = SCRIPT_DIR / "report.md"

# 監査対象外: テストとツール自体
EXCLUDE_DIRS = {"test", "tools", ".dart_tool"}

# 監査対象 widget (内部 Row(MainAxisSize.min) を持つことが分かっている widget)
# 利用側が Expanded/Flexible でラップしている場合に overflow リスクあり。
ROW_MIN_WIDGETS = {
    # 注: AstroTermLabel は 2026-05-11 修正で Flexible-safe になった
    # MapBtn は 40x40 固定なので overflow リスクなし
}


# ─────────────────────────────────────────────────────────────────
# Data structures
# ─────────────────────────────────────────────────────────────────

@dataclass
class Finding:
    file: Path
    line: int
    column: int
    category: str   # 'naked_text_in_flex' | 'text_missing_overflow' | 'row_min_in_expanded'
    snippet: str
    context: str    # 周辺数行のコンテキスト

    def relative_path(self, root: Path) -> str:
        try:
            return str(self.file.relative_to(root)).replace("\\", "/")
        except ValueError:
            return str(self.file)


@dataclass
class FileScan:
    file: Path
    lines: list[str] = field(default_factory=list)
    findings: list[Finding] = field(default_factory=list)


# ─────────────────────────────────────────────────────────────────
# Scanner helpers
# ─────────────────────────────────────────────────────────────────

# Row( / Column( / Flex( のオープン位置を検出する正規表現
FLEX_OPEN_RE = re.compile(r"\b(?P<widget>Row|Column|Flex)\s*\(")

# Text( の出現位置 (= 1 つの Text コンストラクタ呼び出し)
TEXT_OPEN_RE = re.compile(r"\bText\s*\(")

# Flexible / Expanded / Wrap でラップされているか判定するための直前語
WRAPPING_KEYWORDS = ("Flexible", "Expanded", "Wrap", "FittedBox", "SizedBox", "ConstrainedBox", "OverflowBox", "FractionallySizedBox")


def is_inside_scrollable_or_min_size(content: str, text_pos: int) -> bool:
    """
    Text( を囲む最も近い親が以下のいずれかかを判定:
      - SingleChildScrollView (内部は無限幅、overflow リスク低)
      - ListView / GridView / Wrap (折り返し可能)
      - Row/Column で mainAxisSize: MainAxisSize.min (親 min size 要求、低リスク)
    head 範囲 500 文字以内で検出。
    """
    head = content[max(0, text_pos - 800):text_pos]
    # SingleChildScrollView/ListView/Wrap の存在
    for kw in ("SingleChildScrollView", "ListView", "GridView", "Wrap("):
        if kw in head:
            # 同レベル前で開かれているか (簡易判定)
            pos = head.rfind(kw)
            # その widget が text_pos を含む構造か → 簡易: 後ろの '(' から '\n' 区切り内かを見る
            if pos >= 0:
                # widget の '(' を見つけ、その '(' から text_pos までの括弧バランス
                paren = head.find('(', pos)
                if paren >= 0:
                    depth = 1
                    closed_before_text = False
                    for ch in head[paren + 1:]:
                        if ch == '(':
                            depth += 1
                        elif ch == ')':
                            depth -= 1
                            if depth == 0:
                                closed_before_text = True
                                break
                    if not closed_before_text:
                        return True
    # Row mainAxisSize: MainAxisSize.min パターン
    last_row = head.rfind("Row(")
    if last_row >= 0:
        # Row( から text_pos までの 200 文字以内に "mainAxisSize: MainAxisSize.min" があれば low risk
        snippet = head[last_row:]
        if "mainAxisSize: MainAxisSize.min" in snippet[:200]:
            # Row が text_pos を含んでいるか (括弧バランス)
            depth = 0
            paren = head.find('(', last_row)
            if paren >= 0:
                depth = 1
                for ch in head[paren + 1:]:
                    if ch == '(':
                        depth += 1
                    elif ch == ')':
                        depth -= 1
                        if depth == 0:
                            return False
                if depth >= 1:
                    return True
    return False


def is_direct_child_of_flex(content: str, text_pos: int) -> tuple[bool, str]:
    """
    Text( が Row/Column/Flex の direct child として置かれているか判定。
    判定方法: Text( の直前の非空白文字を遡って、以下のいずれかを満たすか:
        - `children: [` の中で要素として並んでいる (Flex 直下)
        - `,` または `[` の直後 (Flex 内のリスト要素)
    `child:` の直後なら非 Flex 直下 (Container 等の child)。

    精度向上のため、Text( の前方コンテキスト 300 文字以内で:
    1. 最も近い `child:` または `children:` を探す
    2. その間に対応する '(' や '[' があるか確認
    3. children なら true、child なら false
    """
    if text_pos == 0:
        return False, ""
    # Text の直前 300 文字を見る
    head_start = max(0, text_pos - 500)
    head = content[head_start:text_pos]
    # 直前の `child:` または `children:` を探す (より近い方が優先)
    last_child = head.rfind("child:")
    last_children = head.rfind("children:")
    if last_child == -1 and last_children == -1:
        return False, ""
    # children: が child: より後ろ → Flex 直下
    # child: が children: より後ろ → 非 Flex 直下
    if last_children > last_child:
        # children: の後ろに [...Text(...)...] があれば direct child
        # children:[Text(...), ...] のような形か確認
        tail_after_children = head[last_children + len("children:"):]
        # 開き [ までは空白
        if "[" in tail_after_children:
            # [ から Text までの間に閉じ ] や閉じ ) があれば外側に出ている
            bracket_pos = tail_after_children.find("[")
            between = tail_after_children[bracket_pos + 1:]
            # 簡易: between に Text までの閉じ括弧/閉じ ] バランスを見る
            # しかしすでに head は Text の前まで → between は Text 直前まで
            depth_paren = 0
            depth_brk = 0
            for ch in between:
                if ch == "(":
                    depth_paren += 1
                elif ch == ")":
                    depth_paren -= 1
                elif ch == "[":
                    depth_brk += 1
                elif ch == "]":
                    depth_brk -= 1
            # depth_paren == 0 and depth_brk == 0 → Text は children リストの direct child
            if depth_paren == 0 and depth_brk == 0:
                # さらに、この children が Row/Column/Flex のものか確認
                pre_children = head[:last_children]
                pm = None
                for m in FLEX_OPEN_RE.finditer(pre_children):
                    pm = m
                if pm:
                    # pm から last_children までの括弧バランスで Flex がまだ開いてるか
                    depth = 0
                    for ch in pre_children[pm.end() - 1:last_children]:
                        if ch == "(":
                            depth += 1
                        elif ch == ")":
                            depth -= 1
                    if depth >= 1:
                        return True, pm.group("widget")
        return False, ""
    # child: のほうが近い → 非 Flex 直下
    return False, ""


def is_wrapped_by_flex_widget(content: str, text_pos: int) -> bool:
    """
    text_pos の直前 (近接 80 文字以内) に Flexible/Expanded/Wrap/FittedBox/...
    の "child:" 直前指定があるか。緩い判定。
    """
    # text_pos から後ろに 200 文字さかのぼって、Text( の直前にラップキーワードがあるか確認
    head = content[max(0, text_pos - 200) : text_pos]
    # "Flexible(\n  child:" のような形を想定
    for kw in WRAPPING_KEYWORDS:
        # "Flexible(" などが直前 200 文字以内にあれば、それで囲まれた child の可能性
        # ただし child: 経由でないとダメ。"child:" が間にあれば真。
        if kw + "(" in head:
            # Flexible( ... child: ... Text(
            kw_pos = head.rfind(kw + "(")
            tail = head[kw_pos:]
            if "child:" in tail:
                return True
    return False


def _text_args_span(content: str, text_open_pos: int) -> tuple[int, int]:
    """Text() の引数文字列範囲 [start, end] を返す ('(' の直後 〜 対応する ')' 直前)。
    見つからない場合は (-1, -1)。"""
    paren_pos = content.find("(", text_open_pos)
    if paren_pos == -1:
        return -1, -1
    start = paren_pos + 1
    depth = 1
    for i in range(start, min(len(content), start + 4000)):
        ch = content[i]
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return start, i
    return -1, -1


def text_has_overflow_setting(content: str, text_open_pos: int) -> bool:
    """Text( ... の引数内に overflow / maxLines / softWrap の指定があるか。"""
    start, end = _text_args_span(content, text_open_pos)
    if start < 0:
        return True  # スコープ不明、検査対象外
    args = content[start:end]
    return (
        "overflow:" in args
        or "maxLines:" in args
        or "softWrap:" in args
    )


def looks_like_short_literal(content: str, text_open_pos: int) -> bool:
    """短文リテラル (≤10 字) は overflow リスクなし。"""
    start, end = _text_args_span(content, text_open_pos)
    if start < 0:
        return False
    args = content[start:end]
    m = re.search(r"""['"]([^'"]{0,40})['"]""", args)
    if not m:
        return False
    literal = m.group(1)
    return len(literal) <= 10


# ─────────────────────────────────────────────────────────────────
# Main scan
# ─────────────────────────────────────────────────────────────────

def scan_file(path: Path) -> FileScan:
    text = path.read_text(encoding="utf-8", errors="replace")
    lines = text.split("\n")
    scan = FileScan(file=path, lines=lines)

    for m in TEXT_OPEN_RE.finditer(text):
        text_pos = m.start()
        # 1) Flex 系の direct child として置かれているか
        in_flex, flex_widget = is_direct_child_of_flex(text, text_pos)
        if not in_flex:
            continue
        # 1.5) Row(min) / SingleChildScrollView 内などはリスク低
        if is_inside_scrollable_or_min_size(text, text_pos):
            continue
        # 2) Flexible/Expanded/Wrap/FittedBox 等でラップされているか
        wrapped = is_wrapped_by_flex_widget(text, text_pos)
        # 3) Text 自身に overflow/maxLines/softWrap 指定があるか
        has_overflow = text_has_overflow_setting(text, text_pos)
        # 4) 短い literal は除外
        short = looks_like_short_literal(text, text_pos)

        is_row = (flex_widget == "Row")
        if wrapped and has_overflow:
            continue  # 完璧
        if short:
            # 短文はリスク低
            continue
        if not is_row:
            # Column / Flex 直下は縦方向で折り返し可能、低優先
            continue
        if not wrapped and not has_overflow:
            category = "row_naked"
        elif wrapped and not has_overflow:
            category = "row_wrapped_no_overflow"
        elif not wrapped and has_overflow:
            category = "row_overflow_no_wrap"
        else:
            continue

        # 行・列を計算
        line_no = text[:text_pos].count("\n") + 1
        col = text_pos - text.rfind("\n", 0, text_pos)
        # 周辺コンテキスト (前 2 行 + 該当行 + 後 2 行)
        ctx_start = max(0, line_no - 3)
        ctx_end = min(len(lines), line_no + 2)
        context_lines = []
        for i in range(ctx_start, ctx_end):
            marker = " >> " if i == line_no - 1 else "    "
            context_lines.append(f"{marker}{i + 1:4d}: {lines[i]}")
        context = "\n".join(context_lines)
        snippet = lines[line_no - 1].strip() if line_no <= len(lines) else ""

        scan.findings.append(Finding(
            file=path,
            line=line_no,
            column=col,
            category=category,
            snippet=snippet,
            context=context,
        ))
    return scan


def iter_dart_files(root: Path) -> Iterable[Path]:
    for p in root.rglob("*.dart"):
        if any(part in EXCLUDE_DIRS for part in p.parts):
            continue
        yield p


# ─────────────────────────────────────────────────────────────────
# Report generation
# ─────────────────────────────────────────────────────────────────

CATEGORY_LABELS = {
    "row_naked": "🔴 Row 直下の裸 Text (Flexible なし & overflow 設定なし) — 最優先",
    "row_wrapped_no_overflow": "🟡 Row 直下、Flex でラップ済みだが overflow 未設定",
    "row_overflow_no_wrap": "🟡 Row 直下、overflow 設定済みだが Flexible で囲まれていない",
}

CATEGORY_SEVERITY = {
    "row_naked": 3,
    "row_wrapped_no_overflow": 2,
    "row_overflow_no_wrap": 2,
}


def write_report(scans: list[FileScan]) -> int:
    total = sum(len(s.findings) for s in scans)
    by_category: dict[str, list[Finding]] = {k: [] for k in CATEGORY_LABELS}
    by_file: dict[Path, list[Finding]] = {}
    for s in scans:
        for f in s.findings:
            if f.category not in by_category:
                continue
            by_category[f.category].append(f)
            by_file.setdefault(s.file, []).append(f)

    lines = []
    lines.append("# Solara Text Overflow 監査レポート\n")
    lines.append(f"対象: `apps/solara/lib/**/*.dart` (除外: {sorted(EXCLUDE_DIRS)})\n")
    lines.append(f"検出総数: **{total}** 箇所\n\n")
    lines.append("## カテゴリ別サマリ\n")
    lines.append("| 重大度 | カテゴリ | 件数 |\n|---|---|---|\n")
    for cat, label in CATEGORY_LABELS.items():
        sev = CATEGORY_SEVERITY[cat]
        emoji = "🔴" * sev + "⚪" * (3 - sev)
        lines.append(f"| {emoji} | {label} | {len(by_category[cat])} |\n")
    lines.append("\n")

    lines.append("## ファイル別チェックリスト\n\n")
    lines.append("各箇所を確認・修正したらチェックを入れてください。\n\n")

    # ファイルパスでソート
    for path in sorted(by_file.keys(), key=lambda p: str(p)):
        findings = sorted(by_file[path], key=lambda f: f.line)
        rel = str(path.relative_to(SOLARA_ROOT)).replace("\\", "/")
        lines.append(f"### `{rel}` ({len(findings)} 件)\n\n")
        for f in findings:
            cat_label = CATEGORY_LABELS[f.category]
            lines.append(f"- [ ] **L{f.line}** {cat_label}\n")
            lines.append(f"  ```dart\n")
            for cl in f.context.split("\n"):
                lines.append(f"  {cl}\n")
            lines.append(f"  ```\n\n")

    REPORT_PATH.write_text("".join(lines), encoding="utf-8")
    return total


# ─────────────────────────────────────────────────────────────────
# Entry point
# ─────────────────────────────────────────────────────────────────

def main() -> int:
    if not LIB_ROOT.exists():
        print(f"ERROR: {LIB_ROOT} not found", file=sys.stderr)
        return 2
    scans = [scan_file(p) for p in iter_dart_files(LIB_ROOT)]
    total = write_report(scans)
    print(f"=== Solara Text Overflow Audit ===")
    print(f"Scanned: {len(scans)} files")
    print(f"Findings: {total}")
    print(f"Report:  {REPORT_PATH}")
    return 0 if total == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
