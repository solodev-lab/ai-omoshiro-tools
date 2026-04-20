"""Take a timestamped snapshot of every current Tarot Scene asset.

Run once to preserve the current "known-good" state before any further
overwrites. Safe to run again — each snapshot lives under its own
timestamp directory.

Usage:
  python snapshot_tarot_scene.py
"""
from pathlib import Path
from backup_util import snapshot_dir

BASE = Path(__file__).parent / "share-assets" / "tarot_scene"

TARGETS = [
    BASE,                          # altar.png
    BASE / "planets",              # per-planet PNGs
    BASE / "shooting_stars",       # meteors
    BASE / "planet_textures",      # equirectangular maps
    BASE / "planet_rotations",     # animated WebPs
]

for d in TARGETS:
    if d.exists():
        snapshot_dir(d)
    else:
        print(f"  (skip non-existent: {d})")

print("Done.")
