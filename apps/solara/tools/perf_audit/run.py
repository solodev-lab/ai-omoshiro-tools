"""
Solara perf_audit — CLI entry point.

Usage:
  python apps/solara/tools/perf_audit/run.py --device a101fc --scenario cold_start
  python apps/solara/tools/perf_audit/run.py -d a101fc -s idle_30min -p quick
  python apps/solara/tools/perf_audit/run.py -d a101fc -s idle_30min --skip dumpsys.batterystats_pkg
  python apps/solara/tools/perf_audit/run.py -d a101fc -s idle_30min --duration 60 --interval 10
"""
from __future__ import annotations

import os
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Any

import click
import yaml

# Force UTF-8 stdout/stderr on Windows consoles (cp932 default mangles JP text).
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")  # type: ignore[attr-defined]
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")  # type: ignore[attr-defined]
except Exception:
    pass

# Make this directory importable as a package root
ROOT = Path(__file__).parent
sys.path.insert(0, str(ROOT))

from analyzers.report import write_markdown_report  # noqa: E402
from collectors.android.dumpsys import DumpsysCollector  # noqa: E402
from collectors.android.proc import ProcCollector  # noqa: E402


# Default adb path on this dev machine. Override with --adb or $ADB_PATH.
DEFAULT_ADB = os.environ.get(
    "ADB_PATH",
    r"C:\Users\cojif\AppData\Local\Android\sdk\platform-tools\adb.exe",
)


def _load_yaml(p: Path) -> dict:
    with p.open("r", encoding="utf-8") as f:
        return yaml.safe_load(f) or {}


def _autodetect_serial(adb: str, dev: dict) -> str:
    """Resolve a serial for `dev` from adb devices -l.

    Resolution order:
      1. dev["serial"] if non-empty
      2. dev["model_pattern"] matched against `adb devices -l` lines
      3. If only one device is connected, fall back to it (and warn)
    """
    if dev.get("serial"):
        return dev["serial"]

    r = subprocess.run([adb, "devices", "-l"], capture_output=True, text=True, timeout=10)
    online: list[tuple[str, str]] = []  # (serial, full_line)
    for ln in r.stdout.splitlines()[1:]:
        # Format: "df1daf14    device product:A101FC model:A101FC device:A101FC ..."
        parts = ln.split()
        if len(parts) < 2:
            continue
        if parts[1] != "device":
            continue
        online.append((parts[0], ln))

    if not online:
        click.echo("No device connected via adb.", err=True)
        sys.exit(2)

    pattern = (dev.get("model_pattern") or "").strip()
    if pattern:
        # Normalize: '_' is what `adb` substitutes for spaces in model:
        pat_norm = pattern.replace(" ", "_").lower()
        matches = [s for s, ln in online if pat_norm in ln.lower()]
        if len(matches) == 1:
            return matches[0]
        if not matches:
            click.echo(
                f"No connected device matches model_pattern='{pattern}'.\n"
                f"adb devices -l output:\n  " + "\n  ".join(ln for _, ln in online),
                err=True,
            )
            sys.exit(2)
        click.echo(
            f"Multiple devices match model_pattern='{pattern}': {matches}\n"
            f"Edit presets/devices.yaml to set 'serial:' explicitly.",
            err=True,
        )
        sys.exit(2)

    # No pattern — fall back to single-device auto-detect
    if len(online) == 1:
        return online[0][0]
    serials = [s for s, _ in online]
    click.echo(
        f"Multiple devices connected ({serials}) and no model_pattern set "
        f"for this device. Edit presets/devices.yaml.",
        err=True,
    )
    sys.exit(2)


def _launch_app(adb: str, serial: str, package: str, verbose: bool) -> None:
    argv = [adb]
    if serial:
        argv += ["-s", serial]
    argv += [
        "shell", "monkey", "-p", package,
        "-c", "android.intent.category.LAUNCHER", "1",
    ]
    if verbose:
        click.echo(f"Launching {package} on {serial or 'default device'}...")
    r = subprocess.run(argv, capture_output=True, text=True, timeout=30)
    if r.returncode != 0 or "Error" in r.stderr:
        click.echo(f"Launch warning: rc={r.returncode} {r.stderr.strip()}", err=True)


def _build_collectors(
    col_list: list[str], adb: str, serial: str, package: str
) -> list[dict[str, Any]]:
    """Build collector instances grouped by their containing class."""
    dumpsys_svcs: list[str] = []
    proc_subs: list[str] = []
    unknown: list[str] = []
    for c in col_list:
        if c.startswith("dumpsys."):
            dumpsys_svcs.append(c[len("dumpsys."):])
        elif c.startswith("proc."):
            proc_subs.append(c[len("proc."):])
        else:
            unknown.append(c)

    if unknown:
        click.echo(f"Unknown collectors ignored: {unknown}", err=True)

    instances: list[dict[str, Any]] = []
    if dumpsys_svcs:
        instances.append({
            "key": f"dumpsys ({', '.join(dumpsys_svcs)})",
            "instance": DumpsysCollector(adb, serial, package, services=dumpsys_svcs),
        })
    if proc_subs:
        instances.append({
            "key": f"proc ({', '.join(proc_subs)})",
            "instance": ProcCollector(adb, serial, package, sub=proc_subs),
        })
    return instances


def _run_poll(
    collectors_inst: list[dict[str, Any]],
    samples: list,
    errors: list[str],
    duration_sec: int,
    interval: int,
    quiet: bool,
) -> None:
    """Polling loop: call collect() on each collector every `interval` seconds."""
    started = time.time()
    next_poll = started
    poll_count = 0
    while time.time() - started < duration_sec:
        # Wait until next polling tick
        now = time.time()
        if now < next_poll:
            time.sleep(min(next_poll - now, 1.0))
            continue

        poll_count += 1
        elapsed = int(time.time() - started)
        remaining = max(0, duration_sec - elapsed)
        if not quiet:
            click.echo(f"  [poll #{poll_count}] t+{elapsed:>4}s ({remaining}s remaining)")
        for ci in collectors_inst:
            res = ci["instance"].collect()
            samples.extend(res.samples)
            errors.extend(f"{ci['key']}: {e}" for e in res.errors)
        next_poll += interval


@click.command()
@click.option("-d", "--device", required=True,
              help="Device key from presets/devices.yaml (e.g. a101fc, pixel8, so41b)")
@click.option("-s", "--scenario", required=True,
              help="Scenario name or YAML path (e.g. cold_start, idle_30min)")
@click.option("-p", "--profile", default="full", show_default=True,
              help="Collector profile from devices.yaml (quick/standard/full)")
@click.option("--collectors", default=None,
              help="Override collectors (comma-separated, e.g. 'dumpsys.meminfo,proc.fd')")
@click.option("--skip", default=None,
              help="Skip listed collectors (comma-separated)")
@click.option("--duration", type=int, default=None,
              help="Override scenario duration_sec")
@click.option("--interval", type=int, default=None,
              help="Override scenario poll_interval_sec")
@click.option("--adb", default=DEFAULT_ADB, show_default=True,
              help="adb executable path")
@click.option("--out", default=None,
              help="Output directory (default: <perf_audit>/reports/)")
@click.option("--quiet", is_flag=True, help="Suppress progress output")
def main(
    device: str,
    scenario: str,
    profile: str,
    collectors: str | None,
    skip: str | None,
    duration: int | None,
    interval: int | None,
    adb: str,
    out: str | None,
    quiet: bool,
) -> None:
    """Run a Solara performance audit scenario."""

    # ---- Load device + profile ----
    devices_path = ROOT / "presets" / "devices.yaml"
    devs_yaml = _load_yaml(devices_path)
    devices = devs_yaml.get("devices", {})
    profiles = devs_yaml.get("profiles", {})

    if device not in devices:
        click.echo(
            f"Unknown device: {device}\nAvailable: {list(devices.keys())}",
            err=True,
        )
        sys.exit(2)
    dev = devices[device]
    package = dev["package"]

    # ---- Resolve collector list ----
    if collectors:
        col_list = [c.strip() for c in collectors.split(",") if c.strip()]
    elif profile in profiles:
        col_list = list(profiles[profile]["collectors"])
    else:
        click.echo(
            f"Unknown profile: {profile}\nAvailable: {list(profiles.keys())}",
            err=True,
        )
        sys.exit(2)
    if skip:
        skip_set = {c.strip() for c in skip.split(",") if c.strip()}
        col_list = [c for c in col_list if c not in skip_set]
    caps_skip = set(dev.get("caps_skip", []) or [])
    if caps_skip:
        col_list = [c for c in col_list if c not in caps_skip]

    if not col_list:
        click.echo("No collectors selected after profile/skip/caps_skip filtering.", err=True)
        sys.exit(2)

    # ---- Resolve scenario ----
    scenarios_dir = ROOT / "scenarios"
    if scenario.endswith((".yaml", ".yml")):
        sc_path = Path(scenario)
        if not sc_path.is_absolute():
            sc_path = scenarios_dir / sc_path.name
    else:
        sc_path = scenarios_dir / f"{scenario}.yaml"
    if not sc_path.exists():
        click.echo(f"Scenario not found: {sc_path}", err=True)
        sys.exit(2)
    sc = _load_yaml(sc_path)

    duration_sec = duration if duration is not None else sc.get("duration_sec", 60)
    poll_interval = interval if interval is not None else sc.get("poll_interval_sec", 30)

    # ---- Resolve serial ----
    serial = _autodetect_serial(adb, dev)

    # ---- Build collector instances ----
    collectors_inst = _build_collectors(col_list, adb, serial, package)

    # ---- Pre-flight: availability check ----
    if not quiet:
        click.echo("=== Solara perf_audit ===")
        click.echo(f"Device:     {dev['name']} (serial={serial})")
        click.echo(f"Scenario:   {sc.get('name', sc_path.stem)}")
        click.echo(f"Duration:   {duration_sec}s @ {poll_interval}s interval")
        click.echo(f"Profile:    {profile}  (collectors: {len(col_list)})")
        click.echo()
        click.echo("Pre-flight checks:")
        for ci in collectors_inst:
            ok, reason = ci["instance"].is_available()
            mark = "OK  " if ok else "SKIP"
            extra = f" — {reason}" if not ok else ""
            click.echo(f"  [{mark}] {ci['key']}{extra}")
        click.echo()

    available = []
    for ci in collectors_inst:
        ok, _ = ci["instance"].is_available()
        if ok:
            available.append(ci)
    if not available:
        click.echo("No collectors available. Aborting.", err=True)
        sys.exit(2)
    collectors_inst = available

    # ---- Execute scenario operations ----
    started_at = datetime.now()
    samples: list = []
    errors: list[str] = []

    for op in sc.get("operations", []):
        t = op.get("type")
        if t == "instruction":
            click.echo(op["message"])
        elif t == "prompt_enter":
            try:
                input(op.get("message", "Press Enter to continue..."))
            except KeyboardInterrupt:
                click.echo("\nAborted.", err=True)
                sys.exit(130)
            except EOFError:
                # Non-interactive run (stdin redirected) — auto-continue.
                click.echo("(stdin EOF, auto-continue)")
        elif t == "launch":
            _launch_app(adb, serial, package, verbose=not quiet)
        elif t == "poll":
            poll_dur = op.get("duration_sec", duration_sec)
            try:
                _run_poll(collectors_inst, samples, errors, poll_dur, poll_interval, quiet)
            except KeyboardInterrupt:
                click.echo("\nPolling interrupted; writing partial report.")
                break
        else:
            click.echo(f"Unknown scenario op type: {t}", err=True)

    finished_at = datetime.now()

    # ---- Generate report ----
    out_dir = Path(out) if out else (ROOT / "reports")
    out_dir.mkdir(parents=True, exist_ok=True)
    stamp = started_at.strftime("%Y%m%d_%H%M%S")
    sc_name = sc.get("name", sc_path.stem)
    report_path = out_dir / f"{device}_{sc_name}_{stamp}.md"

    meta = {
        "device_label": dev["name"],
        "serial": serial,
        "package": package,
        "scenario": sc_name,
        "profile": profile,
        "duration_sec": duration_sec,
        "poll_interval_sec": poll_interval,
        "started_at": started_at.strftime("%Y-%m-%d %H:%M:%S"),
        "finished_at": finished_at.strftime("%Y-%m-%d %H:%M:%S"),
    }
    write_markdown_report(samples, errors, meta, report_path)

    if not quiet:
        click.echo()
        click.echo(f"OK Report: {report_path}")
        click.echo(f"   Samples: {len(samples)}, Errors: {len(errors)}")


if __name__ == "__main__":
    main()
