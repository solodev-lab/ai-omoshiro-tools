"""Back up a file into a sibling `_backup/` directory with a timestamp prefix.

Call this BEFORE overwriting any generated asset so the previous version is
preserved and recoverable. Mandated by CLAUDE.md "元絵の保護ルール".
"""
from __future__ import annotations
from datetime import datetime
from pathlib import Path
import shutil


def backup_if_exists(path, log=True):
    """If `path` exists, copy it into `<parent>/_backup/<timestamp>_<name>`.

    Returns the backup Path (or None if nothing was backed up).
    """
    p = Path(path)
    if not p.exists() or not p.is_file():
        return None
    backup_dir = p.parent / "_backup"
    backup_dir.mkdir(exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    dest = backup_dir / f"{stamp}_{p.name}"
    shutil.copy2(p, dest)
    if log:
        print(f"  BACKUP: {p.name} -> _backup/{dest.name}")
    return dest


def snapshot_dir(dir_path, log=True):
    """Snapshot every file in `dir_path` (non-recursive, skip hidden) to
    `<dir>/_backup/<timestamp>/`. Used for one-shot protection of existing
    assets before risky batch overwrites.
    """
    d = Path(dir_path)
    if not d.exists():
        return None
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    snapshot = d / "_backup" / stamp
    snapshot.mkdir(parents=True, exist_ok=True)
    count = 0
    for f in d.iterdir():
        if f.is_file() and not f.name.startswith("."):
            shutil.copy2(f, snapshot / f.name)
            count += 1
    if log:
        print(f"  SNAPSHOT: {count} files -> {snapshot.relative_to(d.parent)}")
    return snapshot
