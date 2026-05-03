"""
Abstract collector base classes for Solara perf_audit.

Design:
  Collector  ── ABC for any platform
   └ AndroidCollector  ── adb-based, used by dumpsys/proc collectors
   └ IOSCollector      ── (future) xctrace / idevice based
"""
from __future__ import annotations

import subprocess
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any


@dataclass
class Sample:
    """Single point-in-time measurement from a collector."""
    timestamp: datetime
    collector: str          # e.g. "dumpsys", "proc"
    category: str           # e.g. "memory", "frame", "battery", "fd"
    data: dict[str, Any]    # Parsed structured metrics
    raw: str = ""           # Original output (for debugging / re-parsing)


@dataclass
class CollectionResult:
    """Aggregated samples + errors from one collector run."""
    name: str
    samples: list[Sample] = field(default_factory=list)
    errors: list[str] = field(default_factory=list)


class Collector(ABC):
    """Abstract base for all platform-specific collectors."""

    name: str = "base"
    categories: list[str] = []

    @abstractmethod
    def is_available(self) -> tuple[bool, str]:
        """Return (ok, reason). reason is empty when ok is True."""

    @abstractmethod
    def collect(self) -> CollectionResult:
        """Run a single collection cycle."""


class AndroidCollector(Collector):
    """Base for Android collectors using adb."""

    def __init__(self, adb_path: str, serial: str, package: str):
        self.adb = adb_path
        self.serial = serial
        self.package = package

    def adb_shell(self, cmd: str, timeout: int = 30) -> tuple[int, str, str]:
        """Run an adb shell command, returns (returncode, stdout, stderr)."""
        argv: list[str] = [self.adb]
        if self.serial:
            argv += ["-s", self.serial]
        argv += ["shell", cmd]
        try:
            r = subprocess.run(
                argv,
                capture_output=True,
                text=True,
                timeout=timeout,
                encoding="utf-8",
                errors="replace",
            )
            return r.returncode, r.stdout, r.stderr
        except subprocess.TimeoutExpired:
            return 124, "", f"timeout after {timeout}s"
        except Exception as e:
            return 1, "", f"adb invocation failed: {e}"

    def adb_cmd(self, *args: str, timeout: int = 30) -> tuple[int, str, str]:
        """Run an adb (non-shell) command, e.g. `adb -s <serial> install`."""
        argv: list[str] = [self.adb]
        if self.serial:
            argv += ["-s", self.serial]
        argv += list(args)
        try:
            r = subprocess.run(
                argv,
                capture_output=True,
                text=True,
                timeout=timeout,
                encoding="utf-8",
                errors="replace",
            )
            return r.returncode, r.stdout, r.stderr
        except subprocess.TimeoutExpired:
            return 124, "", f"timeout after {timeout}s"
        except Exception as e:
            return 1, "", f"adb invocation failed: {e}"

    def get_pid(self) -> int | None:
        """Resolve PID for self.package via `pidof`. Returns None if not running."""
        rc, out, _ = self.adb_shell(f"pidof {self.package}")
        if rc == 0 and out.strip():
            try:
                return int(out.strip().split()[0])
            except ValueError:
                return None
        return None

    def is_available(self) -> tuple[bool, str]:
        rc, out, err = self.adb_cmd("get-state", timeout=5)
        if rc != 0:
            return False, f"device not connected ({err.strip() or out.strip()})"
        if "device" not in out:
            return False, f"device state: {out.strip()}"
        return True, ""
