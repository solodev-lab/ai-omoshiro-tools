"""Android-specific collectors using adb."""
from .dumpsys import DumpsysCollector
from .proc import ProcCollector

__all__ = ["DumpsysCollector", "ProcCollector"]
