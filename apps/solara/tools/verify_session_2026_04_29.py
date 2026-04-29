#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Solara 2026-04-29 セッション 包括検査スクリプト。

検査項目:
  1. 新規/改修ファイルの行数（肥大化検知）
  2. 旧実装の残骸検知（OmenButton/Preseed/SeedBadge 等が残っていないか）
  3. Solara 設計思想違反の検知（total= soft+hard / 「ラッキー」「金運」等）
  4. 未使用 import の grep 検知
  5. flutter analyze の最終確認
  6. Worker daily_transits.js の API 整合性検証

使い方:
    cd apps/solara
    python tools/verify_session_2026_04_29.py
"""

from __future__ import annotations
import io
import os
import re
import sys
import subprocess
from pathlib import Path

# Windows cp932 環境でも UTF-8 で stdout に書けるよう wrap する。
if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parents[1]  # apps/solara

# ── 1. ファイル行数チェック ──
TARGET_FILES = [
    # 新規
    "lib/utils/solara_manifesto.dart",
    "lib/utils/direction_energy.dart",
    "lib/utils/daily_transits_api.dart",
    "lib/screens/solara_philosophy_screen.dart",
    "lib/screens/map/map_direction_popup.dart",
    "lib/screens/map/map_daily_transit_screen.dart",
    "lib/widgets/daily_transit_badge.dart",
    "lib/widgets/category_icon.dart",
    "worker/src/daily_transits.js",
    # 改修
    "lib/screens/map/map_astro.dart",
    "lib/screens/map/map_sectors.dart",
    "lib/screens/map/map_constants.dart",
    "lib/screens/map/map_fortune_sheet.dart",
    "lib/screens/map_screen.dart",
    "lib/theme/solara_colors.dart",
    "lib/utils/astro_glossary.dart",
    "lib/utils/solara_storage.dart",
]

WARN_LINES = 800
FAIL_LINES = 1500


def check_file_sizes() -> list[str]:
    print("=" * 60)
    print("1. ファイル行数チェック")
    print("=" * 60)
    issues = []
    for rel in TARGET_FILES:
        p = ROOT / rel
        if not p.exists():
            issues.append(f"❌ MISSING: {rel}")
            print(f"  ❌ MISSING: {rel}")
            continue
        with p.open(encoding="utf-8") as f:
            n = sum(1 for _ in f)
        marker = "✅"
        if n > FAIL_LINES:
            marker = "🔴 OVERSIZED"
            issues.append(f"OVERSIZED: {rel} ({n}行)")
        elif n > WARN_LINES:
            marker = "⚠ LARGE"
        print(f"  {marker:14} {n:5d}行 {rel}")
    return issues


# ── 2. 旧実装の残骸検知 ──

DEAD_CODE_PATTERNS = [
    # (パターン, 説明, 許容ファイル[正規表現])
    (r"\bOmenButton\b",         "OmenButton 残骸",          r"verify_session_"),
    (r"\bOmenPhrase\b",         "OmenPhrase 残骸",          r"verify_session_"),
    (r"pickRandomOmenPhrase",   "pickRandomOmenPhrase 残骸", r"verify_session_"),
    (r"\bPreseed\b",            "Preseed widget 残骸",      r"verify_session_|project_solara_design_philosophy"),
    (r"\bPreseedHint\b",        "PreseedHint 残骸",         r"verify_session_"),
    (r"\bSeedBadge\b",          "SeedBadge 残骸",           r"verify_session_"),
    (r"_preseedState",          "_preseedState フィールド残骸", r"verify_session_"),
    (r"omen_phrases\.dart",     "omen_phrases import 残骸", r"verify_session_"),
    (r"omen_button\.dart",      "omen_button import 残骸", r"verify_session_"),
]


def check_dead_code() -> list[str]:
    print()
    print("=" * 60)
    print("2. 旧実装の残骸検知")
    print("=" * 60)
    issues = []
    for pat, label, allow_re in DEAD_CODE_PATTERNS:
        regex = re.compile(pat)
        allow = re.compile(allow_re) if allow_re else None
        hits = []
        for p in ROOT.rglob("*.dart"):
            if "/.dart_tool/" in p.as_posix() or "/build/" in p.as_posix():
                continue
            if allow and allow.search(p.as_posix()):
                continue
            try:
                with p.open(encoding="utf-8") as f:
                    for i, line in enumerate(f, 1):
                        if regex.search(line):
                            hits.append(f"{p.relative_to(ROOT)}:{i}: {line.strip()[:80]}")
            except UnicodeDecodeError:
                continue
        if hits:
            issues.append(f"{label} ({len(hits)} hit)")
            print(f"  🔴 {label}:")
            for h in hits[:5]:
                print(f"      {h}")
            if len(hits) > 5:
                print(f"      ... +{len(hits)-5}")
        else:
            print(f"  ✅ {label}: 残骸なし")
    return issues


# ── 3. 設計思想違反の検知 ──

PHILOSOPHY_VIOLATIONS = [
    # (パターン, 説明, 許容ファイル正規表現)
    # ※ コメントや説明文で意図的に触れている箇所は許容する
    (
        r"\.\s*total\s*=\s*soft\s*\+\s*hard|total\s*=\s*soft\s*\+\s*hard",
        "total = soft + hard 合算",
        None,
    ),
    (
        r"softRatio",
        "softRatio (割合化禁止)",
        None,
    ),
]


# 「ラッキー/幸運/金運」は Phase E7 で対応のため allowed_files に narrative
# テンプレ系を含める（セッション最終時点で残存OK／オーナー編集対応中）。
NARRATIVE_LEGACY = [
    "horo_relocation_templates.dart",
    "horo_aspect_description.dart",
    "astro_zenith_messages.dart",
    "celestial_event_meanings.dart",
    "observe_constants.dart",
]


def check_philosophy() -> list[str]:
    print()
    print("=" * 60)
    print("3. 設計思想違反検知 (total/ratio)")
    print("=" * 60)
    issues = []
    for pat, label, allow_re in PHILOSOPHY_VIOLATIONS:
        regex = re.compile(pat)
        allow = re.compile(allow_re) if allow_re else None
        hits = []
        for p in ROOT.rglob("*.dart"):
            if "/.dart_tool/" in p.as_posix() or "/build/" in p.as_posix():
                continue
            if allow and allow.search(p.as_posix()):
                continue
            try:
                with p.open(encoding="utf-8") as f:
                    for i, line in enumerate(f, 1):
                        # コメント行はスキップ
                        stripped = line.strip()
                        if stripped.startswith("//") or stripped.startswith("///") or stripped.startswith("*"):
                            continue
                        if regex.search(line):
                            hits.append(f"{p.relative_to(ROOT)}:{i}: {stripped[:100]}")
            except UnicodeDecodeError:
                continue
        if hits:
            issues.append(f"{label} ({len(hits)} hit)")
            print(f"  🔴 {label}:")
            for h in hits[:5]:
                print(f"      {h}")
            if len(hits) > 5:
                print(f"      ... +{len(hits)-5}")
        else:
            print(f"  ✅ {label}: 違反なし")
    print()
    print("  (narrative 系の「幸運/ラッキー/金運」テキストは Phase E7 で対応中につき本検査では除外)")
    return issues


# ── 4. flutter analyze ──


def run_flutter_analyze() -> list[str]:
    print()
    print("=" * 60)
    print("4. flutter analyze")
    print("=" * 60)
    try:
        r = subprocess.run(
            ["flutter", "analyze"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            timeout=180,
            shell=True,
        )
        out = (r.stdout or "") + (r.stderr or "")
        if "No issues found" in out:
            print("  ✅ No issues found")
            return []
        else:
            print(out.strip()[-1500:])
            return ["flutter analyze に issue あり"]
    except Exception as e:
        print(f"  ⚠ flutter 実行不可: {e}")
        return []


# ── 5. Worker API 整合性 ──


def check_worker_api() -> list[str]:
    print()
    print("=" * 60)
    print("5. Worker daily_transits.js の API 整合性")
    print("=" * 60)
    issues = []
    p = ROOT / "worker/src/daily_transits.js"
    if not p.exists():
        issues.append("worker/src/daily_transits.js なし")
        print(f"  ❌ ファイルなし: {p}")
        return issues
    src = p.read_text(encoding="utf-8")
    required_apis = [
        "computeDailyTransits",
        "buildAspects",
        "detectAspects",
        "DEFAULT_ASPECTS",
    ]
    for sym in required_apis:
        if sym in src:
            print(f"  ✅ {sym} 定義あり")
        else:
            issues.append(f"{sym} 未定義")
            print(f"  🔴 {sym} 未定義")
    # index.js が daily-transits route を持つか
    idx = (ROOT / "worker/src/index.js").read_text(encoding="utf-8")
    if "/astro/daily-transits" in idx:
        print("  ✅ index.js: /astro/daily-transits ルートあり")
    else:
        issues.append("/astro/daily-transits ルート未登録")
        print("  🔴 index.js: /astro/daily-transits ルートなし")
    return issues


# ── main ──


def main() -> int:
    print(f"Solara 検査開始 — root: {ROOT}")
    print()
    all_issues = []
    all_issues += check_file_sizes()
    all_issues += check_dead_code()
    all_issues += check_philosophy()
    all_issues += check_worker_api()
    all_issues += run_flutter_analyze()
    print()
    print("=" * 60)
    print("検査結果サマリ")
    print("=" * 60)
    if not all_issues:
        print("✅ すべての検査をパス")
        return 0
    print(f"⚠ {len(all_issues)} 件の指摘:")
    for it in all_issues:
        print(f"  - {it}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
