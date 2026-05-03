"""
Markdown report generator for Solara perf_audit.

Aggregates a list of `Sample` objects (potentially from multiple polls and
collectors) and emits a single Markdown file with:
  - Header (device, scenario, duration, etc.)
  - Summary table (first / last / delta for key metrics)
  - Per-category time-series tables
  - File-descriptor breakdown (fd category, special handling)
  - Errors section
"""
from __future__ import annotations

from collections import defaultdict
from pathlib import Path
from typing import Any

from collectors.base import Sample


# Metrics worth tracking in the Summary table (key, label, format).
# Each entry pulls the named key from samples.data.
SUMMARY_KEYS: list[tuple[str, str, str, str]] = [
    # (sample.category, data_key, label, formatter)
    ("memory", "total_pss_kb", "Total Pss (KB)", "{:,}"),
    ("memory", "native_heap_kb", "Native Heap (KB)", "{:,}"),
    ("memory", "graphics_kb", "Graphics (KB)", "{:,}"),
    ("memory", "code_kb", "Code (KB)", "{:,}"),
    ("memory_smaps", "Pss_kb", "smaps Pss (KB)", "{:,}"),
    ("memory_smaps", "Swap_kb", "smaps Swap (KB)", "{:,}"),
    ("frame", "total_frames", "Frames rendered", "{:,}"),
    ("frame", "janky_pct", "Jank %", "{:.2f}"),
    ("frame", "p99_ms", "p99 frame ms", "{}"),
    ("cpu", "pkg_cpu_total_pct", "Pkg CPU %", "{:.1f}"),
    ("cpu", "sys_cpu_user_pct", "Sys CPU user %", "{:.1f}"),
    ("cpu", "load_1m", "Load 1m", "{:.2f}"),
    ("fd", "total", "fd total", "{}"),
    ("process", "VmRSS_kb", "VmRSS (KB)", "{:,}"),
    ("process", "Threads", "Threads", "{}"),
    ("process", "FDSize", "FDSize", "{}"),
    ("io", "read_bytes", "I/O read bytes", "{:,}"),
    ("io", "write_bytes", "I/O write bytes", "{:,}"),
    ("battery", "computed_drain_mah", "Computed drain (mAh)", "{:.2f}"),
    ("network", "total_rx_bytes", "Net RX bytes", "{:,}"),
    ("network", "total_tx_bytes", "Net TX bytes", "{:,}"),
]


def _fmt(val: Any, fmt: str) -> str:
    if val is None:
        return "—"
    try:
        return fmt.format(val)
    except (ValueError, TypeError):
        return str(val)


def _delta_arrow(first: float | int | None, last: float | int | None) -> str:
    if first is None or last is None:
        return ""
    if not isinstance(first, (int, float)) or not isinstance(last, (int, float)):
        return ""
    if last > first * 1.05:
        return "↑"
    if last < first * 0.95:
        return "↓"
    return "→"


def _delta_str(first: Any, last: Any, fmt: str) -> str:
    if not isinstance(first, (int, float)) or not isinstance(last, (int, float)):
        return ""
    diff = last - first
    sign = "+" if diff >= 0 else ""
    try:
        return f"{sign}{fmt.format(diff)}"
    except (ValueError, TypeError):
        return f"{sign}{diff}"


def _md_table(headers: list[str], rows: list[list[str]]) -> str:
    if not rows:
        return "_(no data)_\n"
    out = ["| " + " | ".join(headers) + " |"]
    out.append("|" + "|".join(["---"] * len(headers)) + "|")
    for r in rows:
        out.append("| " + " | ".join(r) + " |")
    return "\n".join(out) + "\n"


def write_markdown_report(
    samples: list[Sample],
    errors: list[str],
    meta: dict[str, Any],
    out_path: Path,
) -> None:
    """Build a Markdown report and write it to out_path."""
    lines: list[str] = []

    # ---- Header ----
    lines.append(f"# Solara perf_audit report — {meta.get('scenario', '?')}")
    lines.append("")
    lines.append(f"- **Device:** {meta.get('device_label', '?')} (serial=`{meta.get('serial', '?')}`)")
    lines.append(f"- **Package:** `{meta.get('package', '?')}`")
    lines.append(f"- **Scenario:** {meta.get('scenario', '?')}")
    lines.append(f"- **Profile:** {meta.get('profile', '?')}")
    lines.append(f"- **Duration:** {meta.get('duration_sec', '?')} s")
    lines.append(f"- **Poll interval:** {meta.get('poll_interval_sec', '?')} s")
    lines.append(f"- **Started:** {meta.get('started_at', '?')}")
    lines.append(f"- **Finished:** {meta.get('finished_at', '?')}")
    lines.append(f"- **Total samples:** {len(samples)}")
    lines.append("")

    # ---- Summary ----
    lines.append("## Summary — first / last / delta")
    lines.append("")
    by_cat: dict[str, list[Sample]] = defaultdict(list)
    for s in samples:
        by_cat[s.category].append(s)
    for ss in by_cat.values():
        ss.sort(key=lambda s: s.timestamp)

    summary_rows: list[list[str]] = []
    for cat, key, label, fmt in SUMMARY_KEYS:
        ss = by_cat.get(cat, [])
        if not ss:
            continue
        first_val = next((s.data.get(key) for s in ss if s.data.get(key) is not None), None)
        last_val = next((s.data.get(key) for s in reversed(ss) if s.data.get(key) is not None), None)
        if first_val is None and last_val is None:
            continue
        summary_rows.append([
            label,
            _fmt(first_val, fmt),
            _fmt(last_val, fmt),
            _delta_str(first_val, last_val, fmt),
            _delta_arrow(first_val, last_val),
        ])
    if summary_rows:
        lines.append(_md_table(
            ["Metric", "First", "Last", "Δ", "Trend"], summary_rows
        ))
    else:
        lines.append("_(no summary metrics extracted)_")
    lines.append("")

    # ---- Per-category time-series ----
    lines.append("## Time series by category")
    lines.append("")
    for cat in sorted(by_cat.keys()):
        ss = by_cat[cat]
        lines.append(f"### {cat}")
        lines.append("")

        # Collect scalar keys (skip dict/list valued)
        all_keys: set[str] = set()
        for s in ss:
            for k, v in s.data.items():
                if isinstance(v, (str, int, float, bool)) or v is None:
                    all_keys.add(k)

        if not all_keys:
            # Render structured (dict/list) data per sample
            for s in ss[:5]:  # first 5 only
                lines.append(f"**{s.timestamp.strftime('%H:%M:%S')}**:")
                lines.append("```json")
                import json
                try:
                    lines.append(json.dumps(s.data, indent=2, default=str))
                except Exception:
                    lines.append(str(s.data))
                lines.append("```")
                lines.append("")
            if len(ss) > 5:
                lines.append(f"_... and {len(ss) - 5} more samples_")
            lines.append("")
            continue

        keys = sorted(all_keys)
        # Limit columns to keep table readable; keep top N by 'has any value' count
        if len(keys) > 12:
            counts = {k: sum(1 for s in ss if s.data.get(k) is not None) for k in keys}
            keys = sorted(counts, key=lambda k: -counts[k])[:12]

        headers = ["t"] + keys
        rows: list[list[str]] = []
        for s in ss:
            row = [s.timestamp.strftime("%H:%M:%S")]
            for k in keys:
                v = s.data.get(k)
                row.append("—" if v is None else str(v))
            rows.append(row)
        lines.append(_md_table(headers, rows))
        lines.append("")

        # Special handling for fd: dump first/last by_target breakdown
        if cat == "fd":
            for label, idx in [("first", 0), ("last", -1)]:
                if not ss:
                    break
                bt = ss[idx].data.get("by_target", {})
                if not bt:
                    continue
                lines.append(f"**fd breakdown ({label}):**")
                fd_rows = sorted(bt.items(), key=lambda kv: -kv[1])[:20]
                lines.append(_md_table(
                    ["target (normalized)", "count"],
                    [[k, str(v)] for k, v in fd_rows],
                ))
                lines.append("")

    # ---- Errors ----
    if errors:
        lines.append("## Errors / warnings")
        lines.append("")
        for e in errors:
            lines.append(f"- {e}")
        lines.append("")

    # ---- Footer ----
    lines.append("---")
    lines.append(f"_Generated by `apps/solara/tools/perf_audit/run.py`_")
    lines.append("")

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(lines), encoding="utf-8")
