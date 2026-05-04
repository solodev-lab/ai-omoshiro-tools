"""
flutter_idle_runner_audit.py — Static audit for idle-time runners in Flutter apps.

idle (操作なし) でも常駐で frame schedule, rebuild, computation, sensor stream を
発生させ、CPU/battery を食う「常時呼び出し系・常時計算系」の Dart コード
パターンを検出する。

設計方針 (2026-05-04 オーナー指示):
  「常に呼び出される関数・常にメモリ使う関数を 1 つの list に列挙し、
   そのリストに対して target lib をスキャン、ヒット箇所を出す。
   見逃しゼロ保証 (チェック済み pattern は ✓/✗ で全部明示)」
  「他の画面・他のアプリ開発でも再利用可能に」

Usage:
  python tools/flutter_idle_runner_audit.py
  python tools/flutter_idle_runner_audit.py --target apps/solara/lib --out report.md
  python tools/flutter_idle_runner_audit.py --files-only screens/map  # サブディレクトリ絞り込み
"""
from __future__ import annotations

import argparse
import re
import sys
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path

try:
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')  # type: ignore[attr-defined]
except Exception:
    pass


@dataclass
class Pattern:
    pid: str
    tier: int
    name: str
    description: str
    regex: str
    risk: str  # 'high' | 'mid' | 'low'


# ============================================================
# Pattern catalogue — 「常時呼び出し系・常時計算系」候補一覧
# 拡張時はここに追記するだけで report も自動的に追従。
# ============================================================
PATTERNS: list[Pattern] = [
    # Tier 1 — Frame-schedule drivers
    Pattern('T1-A', 1, 'AnimationController.repeat()',
            'Continuous animation tick → frame schedule on every vsync',
            r'\.repeat\s*\(', 'high'),
    Pattern('T1-B', 1, 'Ticker / createTicker',
            'Direct Ticker schedules frames manually',
            r'\b(?:Ticker\s*\(|createTicker\s*\()', 'high'),
    Pattern('T1-C', 1, 'Timer.periodic',
            'Periodic callback — runs at fixed interval forever',
            r'\bTimer\.periodic\b', 'high'),
    Pattern('T1-D', 1, 'Stream.periodic',
            'Periodic stream emit',
            r'\bStream\.periodic\b', 'high'),
    Pattern('T1-E', 1, 'Future.delayed',
            'Future.delayed — recursive use becomes infinite loop',
            r'\bFuture\.delayed\b', 'mid'),
    Pattern('T1-F', 1, 'scheduleFrameCallback',
            'Manual frame callback — explicit vsync trigger',
            r'\bscheduleFrameCallback\b', 'high'),

    # Tier 2 — InheritedWidget/Model watchers (auto-rebuild on notify)
    Pattern('T2-A', 2, 'MediaQuery.of(context)',
            'Rebuild on size/orientation/brightness/textScale change',
            r'\bMediaQuery\.of\s*\(', 'mid'),
    Pattern('T2-B', 2, 'Theme.of(context)',
            'Rebuild on theme change',
            r'\bTheme\.of\s*\(', 'low'),
    Pattern('T2-C', 2, 'MapCamera.of(context)',
            'flutter_map InheritedModel — rebuild on camera change (panning/zoom or internal notify)',
            r'\bMapCamera\.of\s*\(', 'high'),
    Pattern('T2-D', 2, 'dependOnInheritedWidgetOfExactType',
            'Manual InheritedWidget watch',
            r'dependOnInheritedWidget\w+', 'mid'),
    Pattern('T2-E', 2, 'InheritedModel',
            'Aspect-keyed inherited model dependency',
            r'\bInheritedModel\b', 'mid'),
    Pattern('T2-F', 2, 'DefaultTextStyle.of',
            'Rebuild on text style change',
            r'\bDefaultTextStyle\.of\s*\(', 'low'),

    # Tier 3 — Builder widgets (rebuild on listenable/stream notify)
    Pattern('T3-A', 3, 'AnimatedBuilder',
            'Rebuilds on Animation tick',
            r'\bAnimatedBuilder\s*\(', 'high'),
    Pattern('T3-B', 3, 'StreamBuilder',
            'Rebuilds on stream emit (frequency = stream rate)',
            r'\bStreamBuilder<', 'mid'),
    Pattern('T3-C', 3, 'ValueListenableBuilder',
            'Rebuilds on value change',
            r'\bValueListenableBuilder<', 'mid'),
    Pattern('T3-D', 3, 'ListenableBuilder',
            'Rebuilds on listener notify',
            r'\bListenableBuilder\s*\(', 'mid'),
    Pattern('T3-E', 3, 'FutureBuilder',
            'One-time rebuild but holds resources during pending future',
            r'\bFutureBuilder<', 'low'),

    # Tier 4 — Sensor / system streams (idle でも emit)
    Pattern('T4-A', 4, 'accelerometerEvents',
            'IMU stream — emits at sensor rate (idle でも変動で emit)',
            r'\baccelerometerEvents\b', 'high'),
    Pattern('T4-B', 4, 'gyroscopeEvents',
            'Gyroscope stream',
            r'\bgyroscopeEvents\b', 'high'),
    Pattern('T4-C', 4, 'userAccelerometerEvents',
            'User accelerometer stream',
            r'\buserAccelerometerEvents\b', 'high'),
    Pattern('T4-D', 4, 'magnetometerEvents',
            'Magnetometer stream',
            r'\bmagnetometerEvents\b', 'high'),
    Pattern('T4-E', 4, 'FlutterCompass.events',
            'Compass heading stream — emits frequently when sensor active',
            r'FlutterCompass\.events\b', 'high'),
    Pattern('T4-F', 4, 'Geolocator.getPositionStream',
            'GPS position stream',
            r'Geolocator\.getPositionStream\b', 'high'),
    Pattern('T4-G', 4, 'onConnectivityChanged',
            'Network state stream',
            r'\bonConnectivityChanged\b', 'mid'),

    # Tier 5 — Animations / transitions
    Pattern('T5-A', 5, 'AnimatedContainer',
            'Implicit transition (param 変化で animation 起動)',
            r'\bAnimatedContainer\s*\(', 'mid'),
    Pattern('T5-B', 5, 'AnimatedOpacity',
            'Implicit fade — saveLayer trigger',
            r'\bAnimatedOpacity\s*\(', 'mid'),
    Pattern('T5-C', 5, 'AnimatedAlign',
            'Implicit alignment',
            r'\bAnimatedAlign\s*\(', 'mid'),
    Pattern('T5-D', 5, 'AnimatedPositioned',
            'Implicit position',
            r'\bAnimatedPositioned\s*\(', 'mid'),
    Pattern('T5-E', 5, 'AnimatedDefaultTextStyle',
            'Text style transition',
            r'\bAnimatedDefaultTextStyle\s*\(', 'low'),
    Pattern('T5-F', 5, 'AnimatedSwitcher',
            'Child swap animation',
            r'\bAnimatedSwitcher\s*\(', 'mid'),
    Pattern('T5-G', 5, 'AnimatedCrossFade',
            'Two-child fade',
            r'\bAnimatedCrossFade\s*\(', 'mid'),
    Pattern('T5-H', 5, 'TweenAnimationBuilder',
            'Auto-tween animation',
            r'\bTweenAnimationBuilder<', 'mid'),
    Pattern('T5-I', 5, 'Hero',
            'Hero transition',
            r'\bHero\s*\(', 'low'),
    Pattern('T5-J', 5, 'FadeTransition',
            'Animation-driven fade',
            r'\bFadeTransition\s*\(', 'mid'),
    Pattern('T5-K', 5, 'ScaleTransition',
            'Animation-driven scale',
            r'\bScaleTransition\s*\(', 'mid'),
    Pattern('T5-L', 5, 'SlideTransition',
            'Animation-driven slide',
            r'\bSlideTransition\s*\(', 'mid'),
    Pattern('T5-M', 5, 'RotationTransition',
            'Animation-driven rotation',
            r'\bRotationTransition\s*\(', 'mid'),

    # Tier 6 — Long-lived listeners
    Pattern('T6-A', 6, '.addListener(',
            'ChangeNotifier listener — notify ごとに callback',
            r'\.addListener\s*\(', 'mid'),
    Pattern('T6-B', 6, '.listen(',
            'Stream subscription (long-lived if not cancelled)',
            r'\.listen\s*\(', 'mid'),
    Pattern('T6-C', 6, '.addObserver(',
            'WidgetsBindingObserver',
            r'\.addObserver\s*\(', 'low'),
    Pattern('T6-D', 6, 'addPostFrameCallback',
            'Post-frame callback — 1-shot but pattern often re-arms',
            r'\baddPostFrameCallback\b', 'mid'),

    # Tier 7 — flutter_map specific
    Pattern('T7-A', 7, 'mapEventStream',
            'flutter_map MapController.mapEventStream listener',
            r'\bmapEventStream\b', 'mid'),
    Pattern('T7-B', 7, 'onMapEvent',
            'flutter_map onMapEvent callback',
            r'\bonMapEvent\b', 'mid'),
    Pattern('T7-C', 7, 'onPositionChanged',
            'flutter_map onPositionChanged callback',
            r'\bonPositionChanged\b', 'mid'),
    Pattern('T7-D', 7, 'AnimatedMapController',
            'Animated camera mover',
            r'\bAnimatedMapController\b', 'mid'),
    Pattern('T7-E', 7, 'TileDisplay.fadeIn',
            'Tile fade-in animation (default — set instantaneous to disable)',
            r'\bTileDisplay\.fadeIn\b', 'low'),

    # Tier 8 — CustomPaint repaint patterns
    Pattern('T8-A', 8, 'shouldRepaint => true',
            'Always-repaint CustomPainter (画面全体毎 frame 描き直し)',
            r'shouldRepaint\s*\([^)]*\)\s*=>\s*true', 'high'),
    Pattern('T8-B', 8, 'CustomPaint repaint listenable',
            'Repaint on listenable notify',
            r'CustomPaint\s*\([^)]*\brepaint\s*:', 'mid'),

    # Tier 9 — Misc long-lived resources
    Pattern('T9-A', 9, 'WebSocket / Socket connect',
            'Long-lived TCP/WS connection',
            r'\b(?:WebSocket|Socket)\.(?:connect|listen)\b', 'mid'),
    Pattern('T9-B', 9, 'Isolate.spawn',
            'Background isolate may hold memory/CPU',
            r'\bIsolate\.(?:spawn|spawnUri)\b', 'low'),
    Pattern('T9-C', 9, 'SystemChannels handler',
            'Platform channel listener',
            r'SystemChannels\.\w+\.setMessageHandler', 'low'),
]


TIER_TITLES = {
    1: 'Tier 1 — Frame-schedule drivers',
    2: 'Tier 2 — InheritedWidget watchers',
    3: 'Tier 3 — Builder widgets',
    4: 'Tier 4 — Sensor / system streams',
    5: 'Tier 5 — Animations / transitions',
    6: 'Tier 6 — Long-lived listeners',
    7: 'Tier 7 — flutter_map specific',
    8: 'Tier 8 — CustomPaint repaint',
    9: 'Tier 9 — Misc long-lived resources',
}

RISK_LABEL = {'high': '[HIGH]', 'mid': '[MID]', 'low': '[LOW]'}


def scan(target_dir: Path, subdir_filter: str | None = None):
    results = defaultdict(list)
    files_scanned = 0
    skipped = 0

    for f in sorted(target_dir.rglob('*.dart')):
        rel = f.relative_to(target_dir)
        if subdir_filter and subdir_filter not in str(rel).replace('\\', '/'):
            skipped += 1
            continue
        files_scanned += 1
        try:
            content = f.read_text(encoding='utf-8')
        except Exception:
            continue
        for line_no, line in enumerate(content.splitlines(), start=1):
            stripped = line.strip()
            if not stripped or stripped.startswith('//'):
                continue
            for p in PATTERNS:
                if re.search(p.regex, line):
                    results[p.pid].append(
                        (str(rel).replace('\\', '/'), line_no, stripped[:130])
                    )
    return results, files_scanned, skipped


def write_report(results, files_scanned, skipped, target_dir, out):
    total_hits = sum(len(v) for v in results.values())
    high_hits = sum(
        len(results.get(p.pid, [])) for p in PATTERNS if p.risk == 'high'
    )
    out.write('# Flutter idle-runner audit report\n\n')
    out.write('Generated by `tools/flutter_idle_runner_audit.py`\n\n')
    out.write(f'- Target: `{target_dir}`\n')
    out.write(f'- Files scanned: **{files_scanned}**')
    if skipped:
        out.write(f' (skipped by filter: {skipped})')
    out.write('\n')
    out.write(f'- Patterns checked: **{len(PATTERNS)} / {len(PATTERNS)}** (no skip — coverage 100%)\n')
    out.write(f'- Total hits: **{total_hits}** (high-risk: {high_hits})\n\n')

    # Summary table
    out.write('## Summary by tier\n\n')
    out.write('| Tier | Title | High | Mid | Low | Total |\n')
    out.write('|---|---|---:|---:|---:|---:|\n')
    by_tier = defaultdict(list)
    for p in PATTERNS:
        by_tier[p.tier].append(p)
    for tier in sorted(by_tier):
        h = m = lo = 0
        for p in by_tier[tier]:
            n = len(results.get(p.pid, []))
            if p.risk == 'high':
                h += n
            elif p.risk == 'mid':
                m += n
            else:
                lo += n
        out.write(f'| {tier} | {TIER_TITLES[tier]} | {h} | {m} | {lo} | {h + m + lo} |\n')
    out.write('\n')

    # High-risk top hits (quick triage)
    out.write('## Quick triage — high-risk hits only\n\n')
    high_listed = False
    for p in PATTERNS:
        if p.risk != 'high':
            continue
        hits = results.get(p.pid, [])
        if not hits:
            continue
        high_listed = True
        out.write(f'### {p.pid} `{p.name}` ({len(hits)} 件)\n')
        for f, ln, txt in hits[:10]:
            out.write(f'- `{f}:{ln}` — `{txt}`\n')
        if len(hits) > 10:
            out.write(f'- ... +{len(hits) - 10} more\n')
        out.write('\n')
    if not high_listed:
        out.write('_No high-risk hits._\n\n')

    # Detail per pattern (full list, all tiers, including 0-hit)
    out.write('## Detail by pattern (incl. 0-hit for coverage proof)\n\n')
    for tier in sorted(by_tier):
        out.write(f'### {TIER_TITLES[tier]}\n\n')
        for p in by_tier[tier]:
            hits = results.get(p.pid, [])
            check = 'HIT' if hits else 'OK '
            out.write(
                f'#### [{check}] {p.pid} {RISK_LABEL[p.risk]} `{p.name}`\n'
            )
            out.write(f'_{p.description}_\n\n')
            if not hits:
                out.write('- No hits (0 件)\n\n')
            else:
                out.write(f'- **{len(hits)} hits:**\n')
                for f, ln, txt in hits[:25]:
                    out.write(f'  - `{f}:{ln}` — `{txt}`\n')
                if len(hits) > 25:
                    out.write(f'  - ... +{len(hits) - 25} more\n')
                out.write('\n')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--target', default='apps/solara/lib',
                        help='Lib directory to scan (relative to cwd or absolute)')
    parser.add_argument('--out', default='-',
                        help='Output path or "-" for stdout')
    parser.add_argument('--files-only', default=None,
                        help='Filter scanned files by substring (e.g. "screens/map")')
    args = parser.parse_args()

    target = Path(args.target).resolve()
    if not target.exists():
        print(f'Target not found: {target}', file=sys.stderr)
        sys.exit(1)

    results, files_scanned, skipped = scan(target, args.files_only)
    if args.out == '-':
        write_report(results, files_scanned, skipped, target, sys.stdout)
    else:
        outp = Path(args.out)
        outp.parent.mkdir(parents=True, exist_ok=True)
        with outp.open('w', encoding='utf-8') as f:
            write_report(results, files_scanned, skipped, target, f)
        print(f'Report saved to {outp}')


if __name__ == '__main__':
    main()
