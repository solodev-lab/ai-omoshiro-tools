"""Analyzers package — sample aggregation, report generation, and comparison."""
from .compare import build_compare_md
from .report import write_markdown_report

__all__ = ["write_markdown_report", "build_compare_md"]
