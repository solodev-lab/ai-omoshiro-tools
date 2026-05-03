"""
Compare two perf_audit Markdown reports.

Parses the Summary tables of two reports and produces a side-by-side
Markdown diff, highlighting metrics that changed significantly.

Usage:
  python apps/solara/tools/perf_audit/analyzers/compare.py \
    --left  reports/a101fc_idle_30min_20260504_000428.md \
    --right reports/a101fc_idle_30min_20260504_004500.md \
    --label-left  debug \
    --label-right profile \
    --out   reports/compare_debug_vs_profile.md
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

import click

# Force UTF-8 stdout/stderr on Windows consoles.
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")  # type: ignore[attr-defined]
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")  # type: ignore[attr-defined]
except Exception:
    pass


def parse_metadata(md: str) -> dict[str, str]:
    """Extract header metadata fields like Device, Scenario, Started."""
    d: dict[str, str] = {}
    for key in [
        "Device", "Package", "Scenario", "Profile", "Duration",
        "Poll interval", "Started", "Finished", "Total samples",
    ]:
        m = re.search(rf"\*\*{re.escape(key)}:\*\*\s*(.+)$", md, re.MULTILINE)
        if m:
            v = m.group(1).strip()
            # Strip backticks (e.g. `df1daf14`) and trailing punctuation
            v = v.replace("`", "")
            d[key] = v
    return d


def parse_summary_table(md: str) -> dict[str, dict[str, str]]:
    """Extract the Summary table.

    Returns: {metric_name: {first, last, delta, trend}}
    """
    section = re.search(r"## Summary[^\n]*\n(.*?)(?=\n## |\Z)", md, re.DOTALL)
    if not section:
        return {}
    rows: dict[str, dict[str, str]] = {}
    for line in section.group(1).splitlines():
        m = re.match(
            r"\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|"
            r"\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|",
            line,
        )
        if not m:
            continue
        label = m.group(1).strip()
        first = m.group(2).strip()
        if label in {"Metric"} or "---" in label or "---" in first:
            continue
        rows[label] = {
            "first": first,
            "last": m.group(3).strip(),
            "delta": m.group(4).strip(),
            "trend": m.group(5).strip(),
        }
    return rows


def to_num(s: str) -> float | None:
    """Parse '569,541' / '46.51' / '-19,709' / '—' into float, else None."""
    if not s or s == "—":
        return None
    s = s.replace(",", "").replace("+", "").strip()
    try:
        return float(s)
    except ValueError:
        return None


def _classify(pct: float) -> str:
    if pct <= -50:
        return "(大幅低下)"
    if pct <= -10:
        return "(低下)"
    if pct >= 50:
        return "(大幅増加)"
    if pct >= 10:
        return "(増加)"
    return ""


def build_compare_md(
    left_md: str, right_md: str, label_left: str, label_right: str
) -> str:
    meta_l = parse_metadata(left_md)
    meta_r = parse_metadata(right_md)
    summ_l = parse_summary_table(left_md)
    summ_r = parse_summary_table(right_md)

    out: list[str] = []
    out.append(f"# perf_audit comparison: {label_left} vs {label_right}")
    out.append("")

    # ---- Conditions ----
    out.append("## Conditions")
    out.append("")
    out.append(f"| Field | {label_left} | {label_right} |")
    out.append("|---|---|---|")
    for k in [
        "Device", "Package", "Scenario", "Profile",
        "Duration", "Poll interval", "Started", "Finished", "Total samples",
    ]:
        out.append(f"| {k} | {meta_l.get(k, '—')} | {meta_r.get(k, '—')} |")
    out.append("")

    # ---- Side-by-side ----
    out.append(f"## Summary side-by-side")
    out.append("")
    headers = [
        "Metric",
        f"{label_left} First", f"{label_left} Last", f"{label_left} Δ",
        f"{label_right} First", f"{label_right} Last", f"{label_right} Δ",
        "Last Δ% (R vs L)", "Verdict",
    ]
    out.append("| " + " | ".join(headers) + " |")
    out.append("|" + "|".join(["---"] * len(headers)) + "|")

    all_metrics = sorted(set(summ_l.keys()) | set(summ_r.keys()))
    rel_pairs: list[tuple[float, str, float, float]] = []  # for highlights
    for metric in all_metrics:
        L = summ_l.get(metric, {})
        R = summ_r.get(metric, {})
        last_l = to_num(L.get("last", ""))
        last_r = to_num(R.get("last", ""))

        if last_l is not None and last_r is not None and last_l != 0:
            pct = (last_r - last_l) / abs(last_l) * 100
            rel = f"{pct:+.1f}%"
            verdict = _classify(pct)
            rel_pairs.append((pct, metric, last_l, last_r))
        elif last_l is None and last_r is not None:
            rel, verdict = "(L: —)", "(L 取得失敗)"
        elif last_l is not None and last_r is None:
            rel, verdict = "(R: —)", "(R 取得失敗)"
        else:
            rel, verdict = "—", ""

        out.append("| " + " | ".join([
            metric,
            L.get("first", "—"), L.get("last", "—"), L.get("delta", "—"),
            R.get("first", "—"), R.get("last", "—"), R.get("delta", "—"),
            rel, verdict,
        ]) + " |")
    out.append("")

    # ---- Highlights ----
    out.append("## Highlights — 差分 10% 以上のメトリクス (絶対値順)")
    out.append("")
    rel_pairs_filtered = [t for t in rel_pairs if abs(t[0]) >= 10]
    rel_pairs_filtered.sort(key=lambda t: -abs(t[0]))
    if rel_pairs_filtered:
        for pct, metric, last_l, last_r in rel_pairs_filtered:
            arrow = "↑" if pct > 0 else "↓"
            verdict = _classify(pct)
            out.append(
                f"- {arrow} **{metric}**: "
                f"{label_left} {last_l:,.1f} → {label_right} {last_r:,.1f} "
                f"({pct:+.1f}%) {verdict}"
            )
    else:
        out.append("_(差分 10% 以上のメトリクスなし — 両者ほぼ同等)_")
    out.append("")

    # ---- Footer ----
    out.append("---")
    out.append("_Generated by `analyzers/compare.py`_")
    out.append("")
    return "\n".join(out)


@click.command()
@click.option("--left", required=True, type=click.Path(exists=True, dir_okay=False),
              help="Left-side report (baseline)")
@click.option("--right", required=True, type=click.Path(exists=True, dir_okay=False),
              help="Right-side report (comparison target)")
@click.option("--label-left", default="left", show_default=True,
              help="Label for left report (e.g. 'debug')")
@click.option("--label-right", default="right", show_default=True,
              help="Label for right report (e.g. 'profile')")
@click.option("--out", default=None,
              help="Output path. If omitted, prints to stdout.")
def main(left: str, right: str, label_left: str, label_right: str, out: str | None) -> None:
    """Compare two perf_audit Markdown reports side-by-side."""
    left_md = Path(left).read_text(encoding="utf-8")
    right_md = Path(right).read_text(encoding="utf-8")
    md = build_compare_md(left_md, right_md, label_left, label_right)
    if out:
        Path(out).parent.mkdir(parents=True, exist_ok=True)
        Path(out).write_text(md, encoding="utf-8")
        click.echo(f"Written: {out}")
    else:
        click.echo(md)


if __name__ == "__main__":
    main()
