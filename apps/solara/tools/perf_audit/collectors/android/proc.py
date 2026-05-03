"""
/proc/<pid>/* direct-read collector.

Provides metrics not exposed via dumpsys:
  - File descriptor count + breakdown by symlink target  (fd leak indicator)
  - VmPeak / VmSize / VmRSS / VmHWM / Threads via /proc/<pid>/status
  - Per-process I/O bytes via /proc/<pid>/io
  - Aggregated memory map via /proc/<pid>/smaps_rollup

Requires `run-as` to read inside the package's /proc entry. This is only
permitted for debuggable APKs. On release builds, is_available() returns
False with a clear reason.
"""
from __future__ import annotations

import re
from datetime import datetime

from ..base import AndroidCollector, CollectionResult, Sample


_SUBCOLLECTORS = ("fd", "status", "io", "smaps_rollup")


class ProcCollector(AndroidCollector):
    """Collect metrics by reading /proc/<pid>/* entries via run-as."""

    name = "proc"
    categories = ["fd", "memory", "io", "process"]

    def __init__(self, adb_path: str, serial: str, package: str,
                 sub: list[str] | None = None):
        super().__init__(adb_path, serial, package)
        self.sub = sub if sub is not None else list(_SUBCOLLECTORS)

    def is_available(self) -> tuple[bool, str]:
        ok, reason = super().is_available()
        if not ok:
            return ok, reason
        rc, out, _ = self.adb_shell(f"run-as {self.package} echo ok", timeout=5)
        if rc != 0 or "ok" not in out:
            return False, "run-as not available (release/non-debuggable build?)"
        return True, ""

    def collect(self) -> CollectionResult:
        result = CollectionResult(name=self.name)
        ts = datetime.now()
        pid = self.get_pid()
        if not pid:
            result.errors.append(f"{self.package} not running (no pid)")
            return result

        dispatch = {
            "fd": self._fd,
            "status": self._status,
            "io": self._io,
            "smaps_rollup": self._smaps_rollup,
        }
        for s in self.sub:
            fn = dispatch.get(s)
            if not fn:
                result.errors.append(f"unknown proc sub-collector: {s}")
                continue
            try:
                sample = fn(ts, pid)
                if sample is not None:
                    result.samples.append(sample)
            except Exception as e:
                result.errors.append(f"{s}: {e!r}")
        return result

    # ---------- fd ----------
    def _fd(self, ts: datetime, pid: int) -> Sample:
        # Detail: ls -la to read symlink targets for category breakdown
        rc, out, _ = self.adb_shell(
            f"run-as {self.package} ls -la /proc/{pid}/fd 2>/dev/null", timeout=20
        )
        # Total count: separate `ls | wc -l` to avoid counting "." and ".."
        rc2, count_out, _ = self.adb_shell(
            f"run-as {self.package} sh -c 'ls /proc/{pid}/fd 2>/dev/null | wc -l'",
            timeout=10,
        )
        try:
            total = int(count_out.strip().splitlines()[-1])
        except (ValueError, IndexError):
            total = -1

        # Categorize by symlink target type
        category: dict[str, int] = {}
        for line in out.splitlines():
            if "->" not in line:
                continue
            target = line.split("->", 1)[1].strip()
            # Normalize: strip inode numbers, hex addresses, port numbers
            tgt = re.sub(r"\d+", "N", target)
            tgt = tgt.split("[")[0]
            tgt = tgt.split(":")[0] if not tgt.startswith("/") else tgt
            tgt = tgt.strip()
            category[tgt] = category.get(tgt, 0) + 1

        return Sample(
            timestamp=ts,
            collector=self.name,
            category="fd",
            data={"total": total, "by_target": category},
            raw=out,
        )

    # ---------- status ----------
    def _status(self, ts: datetime, pid: int) -> Sample:
        rc, out, _ = self.adb_shell(
            f"run-as {self.package} cat /proc/{pid}/status", timeout=10
        )
        d: dict[str, object] = {}
        for k in [
            "Name", "State", "Tgid", "Pid", "PPid", "Threads", "FDSize",
            "VmPeak", "VmSize", "VmLck", "VmPin", "VmHWM", "VmRSS",
            "RssAnon", "RssFile", "RssShmem", "VmData", "VmStk",
            "VmExe", "VmLib", "VmPTE", "VmSwap",
            "voluntary_ctxt_switches", "nonvoluntary_ctxt_switches",
        ]:
            m = re.search(rf"^{re.escape(k)}:\s+(.+)$", out, re.MULTILINE)
            if m:
                v = m.group(1).strip()
                # Trailing "kB" → strip and store as int
                if v.endswith(" kB"):
                    try:
                        d[f"{k}_kb"] = int(v[:-3].strip())
                    except ValueError:
                        d[k] = v
                else:
                    try:
                        d[k] = int(v)
                    except ValueError:
                        d[k] = v
        return Sample(ts, self.name, "process", d, out)

    # ---------- io ----------
    def _io(self, ts: datetime, pid: int) -> Sample:
        rc, out, _ = self.adb_shell(
            f"run-as {self.package} cat /proc/{pid}/io", timeout=10
        )
        d: dict[str, object] = {}
        for k in [
            "rchar", "wchar", "syscr", "syscw",
            "read_bytes", "write_bytes", "cancelled_write_bytes",
        ]:
            m = re.search(rf"^{re.escape(k)}:\s+(\d+)", out, re.MULTILINE)
            if m:
                d[k] = int(m.group(1))
        return Sample(ts, self.name, "io", d, out)

    # ---------- smaps_rollup ----------
    def _smaps_rollup(self, ts: datetime, pid: int) -> Sample:
        rc, out, _ = self.adb_shell(
            f"run-as {self.package} cat /proc/{pid}/smaps_rollup", timeout=10
        )
        d: dict[str, object] = {}
        for k in [
            "Rss", "Pss", "Pss_Anon", "Pss_File", "Pss_Shmem",
            "Shared_Clean", "Shared_Dirty", "Private_Clean", "Private_Dirty",
            "Referenced", "Anonymous", "LazyFree", "AnonHugePages",
            "ShmemPmdMapped", "Shared_Hugetlb", "Private_Hugetlb",
            "Swap", "SwapPss", "Locked",
        ]:
            m = re.search(rf"^{re.escape(k)}:\s+(\d+)\s*kB", out, re.MULTILINE)
            if m:
                d[f"{k}_kb"] = int(m.group(1))
        return Sample(ts, self.name, "memory_smaps", d, out)
