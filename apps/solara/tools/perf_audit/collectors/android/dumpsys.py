"""
Dumpsys-based Android collector.

Wraps `adb shell dumpsys <service>` calls into structured Sample entries.
Each method below targets one service and parses the most useful subset.

Coverage:
  meminfo            -> category: memory     (Pss / Java / Native / Graphics)
  gfxinfo            -> category: frame      (jank %, percentiles)
  gfxinfo_framestats -> category: frame      (per-frame timings, last 120 frames)
  batterystats_pkg   -> category: battery    (per-uid drain breakdown)
  netstats           -> category: network    (RX/TX bytes per uid)
  sensorservice      -> category: sensor     (active sensor clients)
  location           -> category: location   (active GPS clients)
  cpuinfo            -> category: cpu        (per-process CPU%)
  activity_processes -> category: lifecycle  (process state)

Each parser is best-effort: when the regex doesn't match (e.g. older Android
emits a different layout), the sample is still emitted with whatever was
extracted, plus the full `raw` output for offline re-parsing.
"""
from __future__ import annotations

import re
from datetime import datetime

from ..base import AndroidCollector, CollectionResult, Sample


_SERVICE_DISPATCH: dict[str, str] = {
    "meminfo": "_meminfo",
    "gfxinfo": "_gfxinfo",
    "gfxinfo_framestats": "_gfxinfo_framestats",
    "batterystats_pkg": "_batterystats_pkg",
    "netstats": "_netstats",
    "sensorservice": "_sensorservice",
    "location": "_location",
    "cpuinfo": "_cpuinfo",
    "activity_processes": "_activity_processes",
}


class DumpsysCollector(AndroidCollector):
    """Collect metrics via dumpsys services."""

    name = "dumpsys"
    categories = [
        "memory", "frame", "battery", "network",
        "sensor", "location", "cpu", "lifecycle",
    ]

    def __init__(self, adb_path: str, serial: str, package: str,
                 services: list[str] | None = None):
        super().__init__(adb_path, serial, package)
        self.services = services if services is not None else list(_SERVICE_DISPATCH.keys())

    def collect(self) -> CollectionResult:
        result = CollectionResult(name=self.name)
        ts = datetime.now()
        for svc in self.services:
            method_name = _SERVICE_DISPATCH.get(svc)
            if not method_name:
                result.errors.append(f"unknown dumpsys service: {svc}")
                continue
            try:
                sample = getattr(self, method_name)(ts)
                if sample is not None:
                    result.samples.append(sample)
            except Exception as e:
                result.errors.append(f"{svc}: {e!r}")
        return result

    # ---------- memory ----------
    def _meminfo(self, ts: datetime) -> Sample:
        rc, out, err = self.adb_shell(f"dumpsys meminfo {self.package}", timeout=30)
        d: dict[str, object] = {}

        # "TOTAL PSS:   332456            TOTAL RSS: ..."  or  "TOTAL  332456 ..."
        m = re.search(r"TOTAL\s+PSS:\s*(\d+)", out)
        if m:
            d["total_pss_kb"] = int(m.group(1))
        else:
            # Fallback for older format
            m = re.search(r"^\s*TOTAL\s+(\d+)", out, re.MULTILINE)
            if m:
                d["total_pss_kb"] = int(m.group(1))

        # Section rows: "Native Heap   123456 ..." etc.
        for label, key in [
            ("Native Heap", "native_heap_kb"),
            ("Dalvik Heap", "dalvik_heap_kb"),
            ("Dalvik Other", "dalvik_other_kb"),
            ("Stack", "stack_kb"),
            ("Cursor", "cursor_kb"),
            ("Ashmem", "ashmem_kb"),
            ("Other dev", "other_dev_kb"),
            (".so mmap", "so_mmap_kb"),
            (".jar mmap", "jar_mmap_kb"),
            (".apk mmap", "apk_mmap_kb"),
            (".ttf mmap", "ttf_mmap_kb"),
            (".dex mmap", "dex_mmap_kb"),
            (".oat mmap", "oat_mmap_kb"),
            (".art mmap", "art_mmap_kb"),
            ("Other mmap", "other_mmap_kb"),
            ("EGL mtrack", "egl_mtrack_kb"),
            ("GL mtrack", "gl_mtrack_kb"),
            ("Unknown", "unknown_kb"),
            ("Graphics", "graphics_kb"),
            ("Code", "code_kb"),
            ("Private Other", "private_other_kb"),
            ("System", "system_kb"),
        ]:
            m = re.search(rf"^\s*{re.escape(label)}\s+(\d+)", out, re.MULTILINE)
            if m:
                d[key] = int(m.group(1))

        # Heap stats: "Heap Size:  ... Heap Alloc: ... Heap Free: ..."
        for label, key in [
            ("Heap Size", "heap_size_kb"),
            ("Heap Alloc", "heap_alloc_kb"),
            ("Heap Free", "heap_free_kb"),
        ]:
            m = re.search(rf"{re.escape(label)}:\s*(\d+)", out)
            if m:
                d[key] = int(m.group(1))

        # Views / ViewRootImpl / AppContexts / Activities counts
        for label, key in [
            ("Views", "views"),
            ("ViewRootImpl", "view_roots"),
            ("AppContexts", "app_contexts"),
            ("Activities", "activities"),
            ("Assets", "assets"),
            ("AssetManagers", "asset_managers"),
            ("Local Binders", "local_binders"),
            ("Proxy Binders", "proxy_binders"),
            ("Parcel memory", "parcel_memory_kb"),
            ("Parcel count", "parcel_count"),
            ("Death Recipients", "death_recipients"),
            ("OpenSSL Sockets", "openssl_sockets"),
            ("WebViews", "webviews"),
        ]:
            m = re.search(rf"{re.escape(label)}:\s*(\d+)", out)
            if m:
                d[key] = int(m.group(1))

        if rc != 0:
            d["_warn"] = err.strip() or "dumpsys meminfo non-zero rc"
        return Sample(ts, self.name, "memory", d, out)

    # ---------- frame ----------
    def _gfxinfo(self, ts: datetime) -> Sample:
        rc, out, _ = self.adb_shell(f"dumpsys gfxinfo {self.package}", timeout=20)
        d: dict[str, object] = {}

        m = re.search(r"Total frames rendered:\s*(\d+)", out)
        if m:
            d["total_frames"] = int(m.group(1))
        m = re.search(r"Janky frames:\s*(\d+)\s*\(([\d.]+)%\)", out)
        if m:
            d["janky_frames"] = int(m.group(1))
            d["janky_pct"] = float(m.group(2))
        # Newer Android adds "Janky frames (legacy)" + percentile lines like "50th percentile: 8ms"
        for pct_label, key in [
            ("50th percentile", "p50_ms"),
            ("90th percentile", "p90_ms"),
            ("95th percentile", "p95_ms"),
            ("99th percentile", "p99_ms"),
        ]:
            m = re.search(rf"{re.escape(pct_label)}:\s*(\d+)\s*ms", out)
            if m:
                d[key] = int(m.group(1))
        for label, key in [
            ("Number Missed Vsync", "missed_vsync"),
            ("Number High input latency", "high_input_latency"),
            ("Number Slow UI thread", "slow_ui_thread"),
            ("Number Slow bitmap uploads", "slow_bitmap_uploads"),
            ("Number Slow issue draw commands", "slow_issue_draw"),
            ("Number Frame deadline missed", "frame_deadline_missed"),
        ]:
            m = re.search(rf"{re.escape(label)}:\s*(\d+)", out)
            if m:
                d[key] = int(m.group(1))
        return Sample(ts, self.name, "frame", d, out)

    def _gfxinfo_framestats(self, ts: datetime) -> Sample | None:
        """Per-frame timings for the last ~120 frames.

        Output format starts with `---PROFILEDATA---`. Each row has 14
        nanosecond timestamps. We compute basic stats on the input→swap delta.
        """
        rc, out, _ = self.adb_shell(
            f"dumpsys gfxinfo {self.package} framestats", timeout=20
        )
        d: dict[str, object] = {}
        rows: list[list[int]] = []
        in_block = False
        for line in out.splitlines():
            if line.strip().startswith("---PROFILEDATA---"):
                in_block = not in_block
                continue
            if not in_block or not line.strip() or line.startswith("Flags"):
                continue
            parts = line.split(",")
            try:
                vals = [int(p) for p in parts]
                rows.append(vals)
            except ValueError:
                continue

        if rows:
            # Column 1 = INTENDED_VSYNC, Column 13 = FRAME_COMPLETED (per Android docs)
            # Use total = FRAME_COMPLETED - INTENDED_VSYNC (in ns)
            durations_ms = []
            for r in rows:
                if len(r) >= 14:
                    dur_ns = r[13] - r[1]
                    if dur_ns > 0:
                        durations_ms.append(dur_ns / 1_000_000.0)
            if durations_ms:
                durations_ms.sort()
                n = len(durations_ms)
                d["frames_sampled"] = n
                d["mean_ms"] = sum(durations_ms) / n
                d["p50_ms"] = durations_ms[n // 2]
                d["p90_ms"] = durations_ms[int(n * 0.9)]
                d["p99_ms"] = durations_ms[min(n - 1, int(n * 0.99))]
                d["max_ms"] = durations_ms[-1]
                d["over_16ms_pct"] = sum(1 for x in durations_ms if x > 16.7) / n * 100
                d["over_33ms_pct"] = sum(1 for x in durations_ms if x > 33.3) / n * 100
        return Sample(ts, self.name, "frame_detail", d, out[:50000])  # cap raw

    # ---------- battery ----------
    def _batterystats_pkg(self, ts: datetime) -> Sample:
        """Per-package battery stats since last full charge."""
        rc, out, _ = self.adb_shell(
            f"dumpsys batterystats --charged {self.package}", timeout=60
        )
        d: dict[str, object] = {}

        m = re.search(r"Estimated power use \(mAh\):\s*$", out, re.MULTILINE)
        # The "Computed drain: X mAh" line is more useful
        m = re.search(r"Computed drain:\s*([\d.]+)", out)
        if m:
            d["computed_drain_mah"] = float(m.group(1))
        m = re.search(r"actual drain:\s*([\d.]+)-?([\d.]+)?", out, re.IGNORECASE)
        if m:
            d["actual_drain_mah_low"] = float(m.group(1))
            if m.group(2):
                d["actual_drain_mah_high"] = float(m.group(2))

        # Per-package consumption row inside "Estimated power use" section
        m = re.search(
            rf"Uid \w+:\s*([\d.]+)\s*\(.*?\)\s*Including:.*?{re.escape(self.package)}",
            out, re.DOTALL,
        )
        if m:
            d["uid_drain_mah"] = float(m.group(1))

        # Wake locks held by package (count only, full list in raw)
        m = re.search(rf"{re.escape(self.package)}.*?Wake lock\s+(\S+).*?:\s*([\d:.hms]+)",
                      out, re.DOTALL)
        if m:
            d["sample_wake_lock_name"] = m.group(1)
            d["sample_wake_lock_held"] = m.group(2)

        # CPU time foreground / background (s)
        for label, key in [
            (r"User CPU time:\s*([\d.]+)\s*s", "cpu_user_s"),
            (r"System CPU time:\s*([\d.]+)\s*s", "cpu_system_s"),
            (r"Foreground CPU time:\s*([\d.]+)\s*s", "cpu_foreground_s"),
        ]:
            m = re.search(label, out)
            if m:
                d[key] = float(m.group(1))

        # Mobile/Wifi bytes
        for label, key in [
            (r"Mobile network:\s*([\d.]+)\s*B received", "mobile_rx_b"),
            (r"Mobile network:.*?([\d.]+)\s*B sent", "mobile_tx_b"),
            (r"Wifi network:\s*([\d.]+)\s*B received", "wifi_rx_b"),
            (r"Wifi network:.*?([\d.]+)\s*B sent", "wifi_tx_b"),
        ]:
            m = re.search(label, out)
            if m:
                try:
                    d[key] = float(m.group(1))
                except ValueError:
                    pass

        return Sample(ts, self.name, "battery", d, out[:80000])

    # ---------- network ----------
    def _netstats(self, ts: datetime) -> Sample:
        rc, out, _ = self.adb_shell("dumpsys netstats detail", timeout=30)
        d: dict[str, object] = {}
        # Locate the package's UID block; format varies per Android version.
        # Pattern: "uid=10234 ... rb=NNNNN tb=NNNNN ..."
        # We instead look up our package via `pm list packages -U`.
        rc2, uid_out, _ = self.adb_shell(
            f"pm list packages -U {self.package}", timeout=10
        )
        uid: int | None = None
        m = re.search(r"uid:(\d+)", uid_out)
        if m:
            uid = int(m.group(1))
        d["uid"] = uid

        if uid is not None:
            # Sum rb / tb for our uid across interfaces
            total_rb = 0
            total_tb = 0
            for line in out.splitlines():
                if f"uid={uid} " not in line:
                    continue
                m_rb = re.search(r"rb=(\d+)", line)
                m_tb = re.search(r"tb=(\d+)", line)
                if m_rb:
                    total_rb += int(m_rb.group(1))
                if m_tb:
                    total_tb += int(m_tb.group(1))
            d["total_rx_bytes"] = total_rb
            d["total_tx_bytes"] = total_tb
        return Sample(ts, self.name, "network", d, out[:80000])

    # ---------- sensor ----------
    def _sensorservice(self, ts: datetime) -> Sample:
        rc, out, _ = self.adb_shell("dumpsys sensorservice", timeout=20)
        d: dict[str, object] = {}
        # Active connections: lines like "0 connections" or "Active connections:"
        m = re.search(r"(\d+)\s+(?:active )?connections", out, re.IGNORECASE)
        if m:
            d["active_connections"] = int(m.group(1))

        # Sensors used by our package — count occurrences in "Active sensors" block
        sensor_for_pkg: list[str] = []
        block = re.search(r"Active sensors:(.*?)(?:Soaking Sensors:|Previous Registrations|$)",
                          out, re.DOTALL)
        if block:
            for ln in block.group(1).splitlines():
                if self.package in ln or f"pid=" in ln and self.package in ln:
                    sensor_for_pkg.append(ln.strip())
        d["sensors_in_use_by_package"] = sensor_for_pkg

        # Sample rates ("Hardware sensor X | rate=NN Hz")
        for typ in ["Accelerometer", "Magnetic Field", "Gyroscope", "Orientation", "Pressure"]:
            m = re.search(rf"{typ}.*?rate=(\d+)\s*Hz", out)
            if m:
                d[f"{typ.lower().replace(' ', '_')}_hz"] = int(m.group(1))
        return Sample(ts, self.name, "sensor", d, out[:80000])

    # ---------- location ----------
    def _location(self, ts: datetime) -> Sample:
        rc, out, _ = self.adb_shell("dumpsys location", timeout=20)
        d: dict[str, object] = {}
        # Active GPS clients block
        # "Records by Provider: gps Provider active: <count>"
        for prov in ["gps", "network", "fused", "passive"]:
            m = re.search(rf"{prov}\s+active:\s*(\d+)", out)
            if m:
                d[f"{prov}_active_clients"] = int(m.group(1))

        # Lines mentioning our package
        pkg_lines: list[str] = []
        for ln in out.splitlines():
            if self.package in ln:
                pkg_lines.append(ln.strip())
        d["package_mentions"] = pkg_lines[:30]  # cap
        d["uses_location_count"] = len(pkg_lines)
        return Sample(ts, self.name, "location", d, out[:60000])

    # ---------- cpu ----------
    def _cpuinfo(self, ts: datetime) -> Sample:
        rc, out, _ = self.adb_shell("dumpsys cpuinfo", timeout=20)
        d: dict[str, object] = {}
        m = re.search(r"Load:\s*([\d.]+)\s*/\s*([\d.]+)\s*/\s*([\d.]+)", out)
        if m:
            d["load_1m"] = float(m.group(1))
            d["load_5m"] = float(m.group(2))
            d["load_15m"] = float(m.group(3))

        # Header line: "CPU usage from NNNNms to 0ms ago (...):"
        m = re.search(r"CPU usage from\s+(\d+)ms to (\d+)ms ago", out)
        if m:
            d["window_ms"] = int(m.group(1)) - int(m.group(2))

        # Our package's row: " 12% 1234/com.solodevlab.solara: 8% user + 4% kernel"
        m = re.search(
            rf"^\s*([\d.]+)%\s+\d+/{re.escape(self.package)}\s*:\s*([\d.]+)% user\s*\+\s*([\d.]+)% kernel",
            out, re.MULTILINE,
        )
        if m:
            d["pkg_cpu_total_pct"] = float(m.group(1))
            d["pkg_cpu_user_pct"] = float(m.group(2))
            d["pkg_cpu_kernel_pct"] = float(m.group(3))

        # System-wide total: "TOTAL: NN% user + MM% kernel"
        m = re.search(r"TOTAL:\s*([\d.]+)%\s*user\s*\+\s*([\d.]+)%\s*kernel", out)
        if m:
            d["sys_cpu_user_pct"] = float(m.group(1))
            d["sys_cpu_kernel_pct"] = float(m.group(2))

        return Sample(ts, self.name, "cpu", d, out[:30000])

    # ---------- lifecycle ----------
    def _activity_processes(self, ts: datetime) -> Sample:
        rc, out, _ = self.adb_shell(f"dumpsys activity processes {self.package}", timeout=20)
        d: dict[str, object] = {}
        # "*APP* UID 10234 ProcessRecord{... com.solodevlab.solara/u0a234}"
        m = re.search(r"UID\s+(\d+)\s+ProcessRecord", out)
        if m:
            d["uid"] = int(m.group(1))
        m = re.search(r"oom:\s*adj=(-?\d+)", out)
        if m:
            d["oom_adj"] = int(m.group(1))
        m = re.search(r"foregroundActivities=(true|false)", out)
        if m:
            d["foreground_activities"] = m.group(1) == "true"
        m = re.search(r"procState=(\d+)", out)
        if m:
            d["proc_state"] = int(m.group(1))
        m = re.search(r"lastPss=([\d.]+)([KMG]?B)?", out)
        if m:
            d["last_pss_raw"] = m.group(1) + (m.group(2) or "")
        return Sample(ts, self.name, "lifecycle", d, out[:30000])
