#!/usr/bin/env python3
"""
Flutter Repaint Profiler
========================

Dart VM Service に接続して、Flutter アプリの実行時 timeline を取得し、
「どの widget / RenderObject が頻繁に build/paint されているか」を計測する。

「動いていないはずの widget が裏で repaint されている」を計測ベースで暴くツール。
仮説や設計ミスではなく、実行時の事実だけが出る。

使い方:
  1. flutter run --profile でアプリ起動
  2. ターミナルに出る VM Service URL をコピー (例: http://127.0.0.1:60113/XXXX=/)
  3. python tools/flutter_repaint_profiler.py <URL>
  4. プロンプトに従って 30 秒画面操作
  5. tools/flutter_repaint_profiler_report.md にレポート出力

依存:
  pip install websocket-client

参考:
  Dart VM Service Protocol: https://github.com/dart-lang/sdk/blob/main/runtime/vm/service/service.md
  Flutter Service Extensions: https://github.com/flutter/flutter/blob/main/packages/flutter/lib/src/foundation/binding.dart
"""
from __future__ import annotations

import argparse
import json
import sys
import time
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

# Windows の cp932 で文字化けしないよう stdout/stderr を UTF-8 に
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except (AttributeError, ValueError):
        pass

try:
    from websocket import create_connection
except ImportError:
    print("ERROR: websocket-client パッケージが必要です。")
    print("実行: pip install websocket-client")
    sys.exit(1)


# ─────────────────────────────────────────────────
# Dart VM Service WebSocket クライアント
# ─────────────────────────────────────────────────
class VmServiceClient:
    def __init__(self, ws_url: str, timeout: float = 30.0) -> None:
        self.ws_url = ws_url
        self.timeout = timeout
        self.ws = None
        self._req_id = 0

    def connect(self) -> None:
        print(f"Connecting to {self.ws_url} ...")
        self.ws = create_connection(self.ws_url, timeout=self.timeout)
        print("Connected.")

    def close(self) -> None:
        if self.ws is not None:
            self.ws.close()

    def call(self, method: str, params: dict[str, Any] | None = None) -> Any:
        """JSON-RPC 同期呼び出し。一致する id の応答が来るまで読み続ける。"""
        self._req_id += 1
        req_id = self._req_id
        req = {"jsonrpc": "2.0", "id": str(req_id), "method": method, "params": params or {}}
        self.ws.send(json.dumps(req))
        while True:
            raw = self.ws.recv()
            try:
                msg = json.loads(raw)
            except json.JSONDecodeError:
                continue
            # event (id なし) は無視。応答だけ拾う。
            if msg.get("id") != str(req_id):
                continue
            if "error" in msg:
                err = msg["error"]
                raise RuntimeError(f"VM Service error on {method}: {err}")
            return msg.get("result")


# ─────────────────────────────────────────────────
# URL 変換
# ─────────────────────────────────────────────────
def http_to_ws_url(http_url: str) -> str:
    """flutter run のログに出る http URL を ws URL に変換。

    例: http://127.0.0.1:60113/FEtm8jVC1z8=/  ->  ws://127.0.0.1:60113/FEtm8jVC1z8=/ws
    """
    u = http_url.strip().rstrip("/")
    if u.startswith("https://"):
        u = "wss://" + u[len("https://") :]
    elif u.startswith("http://"):
        u = "ws://" + u[len("http://") :]
    elif not (u.startswith("ws://") or u.startswith("wss://")):
        raise ValueError(f"unsupported scheme: {http_url}")
    return u + "/ws"


# ─────────────────────────────────────────────────
# Profiling フロー
# ─────────────────────────────────────────────────
def profile(http_url: str, duration: int, output_path: Path) -> int:
    ws_url = http_to_ws_url(http_url)
    cli = VmServiceClient(ws_url)
    cli.connect()
    try:
        # 1. VM 情報 + isolate 取得
        vm = cli.call("getVM")
        isolates = vm.get("isolates", [])
        if not isolates:
            print("ERROR: isolate が見つかりません。アプリが起動しているか確認してください。")
            return 1
        isolate_id = isolates[0]["id"]
        print(f"Isolate: {isolate_id}")

        # 2. Service extension で widget/render profiling 有効化 (任意 = 失敗しても続行)
        for ext_method, params in [
            (
                "ext.flutter.profileUserWidgetBuilds",
                {"isolateId": isolate_id, "enabled": "true"},
            ),
            (
                "ext.flutter.profileRenderObjectPaints",
                {"isolateId": isolate_id, "enabled": "true"},
            ),
            (
                "ext.flutter.profileRenderObjectLayouts",
                {"isolateId": isolate_id, "enabled": "true"},
            ),
        ]:
            try:
                cli.call(ext_method, params)
                print(f"  Enabled: {ext_method}")
            except RuntimeError as e:
                print(f"  Skip (optional): {ext_method} → {e}")

        # 3. Timeline 記録ストリーム設定 + クリア
        cli.call(
            "setVMTimelineFlags",
            {"recordedStreams": ["Dart", "Embedder", "GC", "API"]},
        )
        cli.call("clearVMTimeline")
        print("Timeline cleared.\n")

        # 4. ユーザー操作待ち
        print("=" * 60)
        print(f"  {duration} 秒間 profiling します")
        print("=" * 60)
        print(" 推奨操作 (10秒ずつ):")
        print("  Phase 1 (0-10s):  アイドル — 何もせず画面を見つめる")
        print("  Phase 2 (10-20s): Map 画面で軽くパン (ゆっくり指で動かす)")
        print("  Phase 3 (20-30s): タブ切替 (Map ↔ Horo ↔ Sanctuary)")
        print()
        start = time.monotonic()
        for sec in range(duration, 0, -1):
            if sec % 5 == 0 or sec <= 3:
                phase = (
                    "Phase 1 アイドル"
                    if duration - sec < 10
                    else "Phase 2 Map パン"
                    if duration - sec < 20
                    else "Phase 3 タブ切替"
                )
                print(f"  残り {sec:>2}秒  ({phase})")
            time.sleep(1)
        elapsed = time.monotonic() - start
        print(f"\nElapsed: {elapsed:.1f}s")

        # 5. Timeline 取得
        print("\nTimeline 取得中 ...")
        timeline = cli.call("getVMTimeline")
        events = timeline.get("traceEvents", [])
        print(f"Total events: {len(events)}")

        # 6. 解析 + レポート出力
        report = analyze(events, duration)
        output_path.write_text(report, encoding="utf-8")
        print(f"\nReport: {output_path}")
        print()
        # コンソールにサマリだけ出す
        print("─" * 60)
        for line in report.splitlines()[:50]:
            print(line)
        print("─" * 60)
        if len(report.splitlines()) > 50:
            print(f"  (... see {output_path} for full report)")

        return 0
    finally:
        cli.close()


# ─────────────────────────────────────────────────
# 解析
# ─────────────────────────────────────────────────
def analyze(events: list[dict[str, Any]], duration: int) -> str:
    """Trace Event を集計してレポート文字列を返す。

    Trace Event Format (Chrome Tracing 互換):
      ph "B" = Begin, "E" = End, "X" = Complete (begin+end), "i" = Instant
      cat = category ("Embedder", "Dart", "GC", "API" など)
      name = event 名 ("Frame", "Animator::Render", "BUILD", "PAINT" など)
      ts = timestamp (microseconds)
      args = 任意の追加情報

    着目したい event:
      - "Frame" / "Animator::BeginFrame" : フレーム数 = 描画頻度
      - 名前に "BUILD" / "PAINT" / "LAYOUT" を含むもの : widget/render 操作頻度
      - args に widget 名が入っていることがある (profileWidgetBuilds 有効時)
    """
    if not events:
        return "# Flutter Repaint Profile Report\n\n(no events recorded)\n"

    # 全体集計
    total_events = len(events)
    begin_events = [e for e in events if e.get("ph") == "B"]
    complete_events = [e for e in events if e.get("ph") == "X"]
    instant_events = [e for e in events if e.get("ph") == "i"]

    # 名前とカテゴリ別カウント
    name_counter: Counter[str] = Counter()
    name_cat_counter: Counter[tuple[str, str]] = Counter()
    cat_counter: Counter[str] = Counter()
    for e in events:
        if e.get("ph") not in ("B", "X", "i"):
            continue
        name = e.get("name", "")
        cat = e.get("cat", "")
        if not name:
            continue
        name_counter[name] += 1
        name_cat_counter[(cat, name)] += 1
        cat_counter[cat] += 1

    # フレーム関連 event の特定
    frame_event_names = {
        "Frame",
        "Animator::BeginFrame",
        "Animator::Render",
        "VsyncProcessCallback",
        "Frame Request Pending",
    }
    frame_count = sum(name_counter[n] for n in frame_event_names if n in name_counter)

    # PAINT / BUILD / LAYOUT 名前を含む event を抽出
    paint_events: Counter[str] = Counter()
    build_events: Counter[str] = Counter()
    layout_events: Counter[str] = Counter()
    for name, n in name_counter.items():
        upper = name.upper()
        if "PAINT" in upper:
            paint_events[name] = n
        if "BUILD" in upper:
            build_events[name] = n
        if "LAYOUT" in upper:
            layout_events[name] = n

    # widget 名抽出 (profile*WidgetBuilds が ON の場合、args.widget に入る場合あり)
    widget_build_counter: Counter[str] = Counter()
    render_paint_counter: Counter[str] = Counter()
    for e in events:
        args = e.get("args") or {}
        widget_name = args.get("widget") or args.get("Widget")
        if widget_name and ("BUILD" in e.get("name", "").upper() or e.get("cat") == "Dart"):
            widget_build_counter[widget_name] += 1
        ro_name = args.get("renderObject") or args.get("RenderObject")
        if ro_name and "PAINT" in e.get("name", "").upper():
            render_paint_counter[ro_name] += 1

    # Frame 間隔の中央値 (アイドル期に repaint されているかの指標)
    # Animator::BeginFrame の連続タイムスタンプから差分を取る
    begin_frame_ts: list[int] = []
    for e in events:
        if e.get("name") == "Animator::BeginFrame" and e.get("ph") == "B":
            ts = e.get("ts")
            if isinstance(ts, int):
                begin_frame_ts.append(ts)
    begin_frame_ts.sort()
    intervals_us: list[int] = [
        b - a for a, b in zip(begin_frame_ts, begin_frame_ts[1:])
    ]
    if intervals_us:
        intervals_us.sort()
        median_us = intervals_us[len(intervals_us) // 2]
        median_fps = 1_000_000 / median_us if median_us > 0 else 0.0
    else:
        median_us = 0
        median_fps = 0.0

    # ─────────────────────────
    # レポート構築
    # ─────────────────────────
    lines: list[str] = []
    lines.append("# Flutter Repaint Profile Report")
    lines.append("")
    lines.append(f"- Profile duration: **{duration} 秒**")
    lines.append(f"- Total trace events: **{total_events:,}**")
    lines.append(f"  - Begin (B): {len(begin_events):,}")
    lines.append(f"  - Complete (X): {len(complete_events):,}")
    lines.append(f"  - Instant (i): {len(instant_events):,}")
    lines.append(f"- Frame events (Frame / Animator::BeginFrame 等): **{frame_count:,}**")
    if intervals_us:
        lines.append(
            f"- Frame interval (median): **{median_us / 1000:.1f} ms** "
            f"(≈ {median_fps:.1f} fps)"
        )
    lines.append("")

    # 判定セクション
    lines.append("## 🚨 Idle Repaint 判定")
    lines.append("")
    lines.append(
        "Profile 中の 1/3 (Phase 1 = 最初の 10 秒) はアイドル指示を出しているので、"
        "ここで Frame が大量に走っているなら **動かないはずの widget が動いている** 証拠。"
    )
    if begin_frame_ts:
        # 最初の 10 秒に発火した Frame 数を概算 (相対 ts 想定)
        ts0 = begin_frame_ts[0]
        in_first_10s = sum(1 for ts in begin_frame_ts if ts - ts0 < 10_000_000)
        lines.append("")
        lines.append(f"- Phase 1 (idle) 中の Frame 数: **{in_first_10s}**")
        if in_first_10s >= 60 * 9:  # 60fps × 9 秒以上
            lines.append("  - 🔴 ほぼ毎フレーム再描画 = 常時 repaint している widget あり")
        elif in_first_10s >= 60 * 3:
            lines.append("  - 🟡 アイドルなのに頻繁に再描画されている")
        elif in_first_10s >= 30:
            lines.append("  - 🟢 軽微な再描画 (許容範囲)")
        else:
            lines.append("  - ✅ ほぼ静止 (理想的)")
    lines.append("")

    # 上位 event カテゴリ
    lines.append("## Event Category Top")
    lines.append("")
    lines.append("| Category | Count |")
    lines.append("|---|---:|")
    for cat, n in cat_counter.most_common(10):
        lines.append(f"| `{cat or '(none)'}` | {n:,} |")
    lines.append("")

    # 上位 event 名
    lines.append("## Event Name Top 30")
    lines.append("")
    lines.append("| Event | Category | Count |")
    lines.append("|---|---|---:|")
    for (cat, name), n in name_cat_counter.most_common(30):
        # `|` を含む名前があると markdown table が壊れるので escape
        nm = name.replace("|", "\\|")
        lines.append(f"| `{nm}` | `{cat or '-'}` | {n:,} |")
    lines.append("")

    # PAINT 関連
    if paint_events:
        lines.append("## PAINT 関連 event 頻度")
        lines.append("")
        lines.append("| Event | Count |")
        lines.append("|---|---:|")
        for name, n in paint_events.most_common(20):
            nm = name.replace("|", "\\|")
            lines.append(f"| `{nm}` | {n:,} |")
        lines.append("")

    # BUILD 関連
    if build_events:
        lines.append("## BUILD 関連 event 頻度")
        lines.append("")
        lines.append("| Event | Count |")
        lines.append("|---|---:|")
        for name, n in build_events.most_common(20):
            nm = name.replace("|", "\\|")
            lines.append(f"| `{nm}` | {n:,} |")
        lines.append("")

    # widget 別 build (profileUserWidgetBuilds が効いていれば中身がある)
    if widget_build_counter:
        lines.append("## Widget Build Frequency Top 30")
        lines.append("")
        lines.append("(profileUserWidgetBuilds が有効な場合のみ集計)")
        lines.append("")
        lines.append("| Widget | Builds |")
        lines.append("|---|---:|")
        for name, n in widget_build_counter.most_common(30):
            nm = name.replace("|", "\\|")
            lines.append(f"| `{nm}` | {n:,} |")
        lines.append("")

    if render_paint_counter:
        lines.append("## RenderObject Paint Frequency Top 30")
        lines.append("")
        lines.append("(profileRenderObjectPaints が有効な場合のみ集計)")
        lines.append("")
        lines.append("| RenderObject | Paints |")
        lines.append("|---|---:|")
        for name, n in render_paint_counter.most_common(30):
            nm = name.replace("|", "\\|")
            lines.append(f"| `{nm}` | {n:,} |")
        lines.append("")

    # 解釈ガイド
    lines.append("## 解釈ガイド")
    lines.append("")
    lines.append("- **Phase 1 (idle) で Frame が高頻度** → 常時 repaint widget あり → AnimationController.repeat() 等を疑う")
    lines.append("- **PAINT 系が突出** → 描画自体が重い (ColorFilter / BoxShadow.blurRadius 動的等)")
    lines.append("- **BUILD 系が突出** → setState 多発 / InheritedWidget の必要以上の伝播")
    lines.append(
        "- **Widget Build が一部 widget に集中** → その widget の `key` 設定 / `RepaintBoundary` 検討"
    )
    lines.append("")

    return "\n".join(lines) + "\n"


# ─────────────────────────────────────────────────
# CLI
# ─────────────────────────────────────────────────
def main() -> int:
    parser = argparse.ArgumentParser(
        description="Flutter Repaint Profiler - Dart VM Service via WebSocket"
    )
    parser.add_argument(
        "url",
        help="Dart VM Service の HTTP URL (例: http://127.0.0.1:60113/XXXX=/)",
    )
    parser.add_argument(
        "--duration",
        type=int,
        default=30,
        help="Profile 取得時間 (秒、デフォルト 30)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(__file__).parent / "flutter_repaint_profiler_report.md",
        help="レポート出力先 (デフォルト: tools/flutter_repaint_profiler_report.md)",
    )
    args = parser.parse_args()
    return profile(args.url, args.duration, args.output)


if __name__ == "__main__":
    sys.exit(main())
