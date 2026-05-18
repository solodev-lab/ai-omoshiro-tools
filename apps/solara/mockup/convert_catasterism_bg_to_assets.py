"""
Convert catasterism background PNGs (mockup) -> WEBP into apps/solara/assets/catasterism-bg/.

Sources:
  - share-assets/backgrounds_mystical/                  (12 PNGs, ★3 layer)
  - share-assets/backgrounds_pisces_variants/           (11 PNGs, ★1-2 layer)
  - share-assets/backgrounds_scorpio_bright/            (10 main PNGs, ★4-5 layer)
  - share-assets/backgrounds_{zodiac}_bright/           (110 PNGs for 11 visible zodiacs, ★4-5 layer)

Some scorpio_bright files are alternate renders (v1/v15/v16/v2) — skip those, keep
only the 10 canonical "bright_{color}_scorpio.png" files.

Output:
  apps/solara/assets/catasterism-bg/bright/    (120 WEBPs)
  apps/solara/assets/catasterism-bg/mystical/  (12 WEBPs)
  apps/solara/assets/catasterism-bg/lite/      (11 WEBPs)

Usage:
  python convert_catasterism_bg_to_assets.py            # convert all (skip if WEBP exists)
  python convert_catasterism_bg_to_assets.py --force    # overwrite existing WEBPs
"""
import sys
from pathlib import Path
from PIL import Image

ZODIACS = [
    "aries", "taurus", "gemini", "cancer", "leo", "virgo",
    "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces",
]
COLORS = [
    "golden", "silver", "crimson", "ethereal", "mystic", "silent",
    "frozen", "ancient", "infinite", "radiant",
]

WORKTREE_MOCKUP = Path(__file__).resolve().parent
WORKTREE_SHARE = WORKTREE_MOCKUP / "share-assets"
MAIN_SHARE = Path("E:/AppCreate/apps/solara/mockup/share-assets")
ASSETS_OUT = WORKTREE_MOCKUP.parent / "assets" / "catasterism-bg"

WEBP_QUALITY = 85  # subjectively indistinguishable from PNG at this quality, ~10% size

# Scorpio per-color source preference. The user mixes:
# - "old"/abstract (only 3 gas curls, no scorpion body) from backgrounds_scorpio_bright/
# - "new"/visible (subtle tail+claws with scene) from backgrounds_scorpio_bright_visible/
SCORPIO_SOURCE = {
    "golden": "new",
    "silver": "new",
    "crimson": "old",
    "ethereal": "new",
    "mystic": "new",
    "silent": "old",
    "frozen": "old",
    "ancient": "old",
    "infinite": "new",
    "radiant": "old",
}


def _read_png(src: Path) -> Image.Image | None:
    try:
        return Image.open(src).convert("RGB")
    except Exception as e:
        print(f"  ERROR read {src.name}: {e}")
        return None


def convert(src: Path, dst: Path, force: bool = False) -> bool:
    if dst.exists() and not force:
        return True
    img = _read_png(src)
    if img is None:
        return False
    dst.parent.mkdir(parents=True, exist_ok=True)
    img.save(str(dst), "WEBP", quality=WEBP_QUALITY, method=6)
    src_kb = src.stat().st_size // 1024
    dst_kb = dst.stat().st_size // 1024
    print(f"  {src.name} ({src_kb}KB) -> {dst.name} ({dst_kb}KB, {100*dst_kb//max(src_kb,1)}%)")
    return True


def find_source(name: str, *candidates: Path) -> Path | None:
    for c in candidates:
        if c.exists():
            return c
    print(f"  MISSING: {name} (tried: {', '.join(str(c) for c in candidates)})")
    return None


def main():
    force = "--force" in sys.argv

    ok = 0
    fail = 0

    # ===== ★4-5: bright/ =====
    bright_dst = ASSETS_OUT / "bright"
    print(f"\n=== ★4-5: bright/ -> {bright_dst} ===")
    for zodiac in ZODIACS:
        for color in COLORS:
            filename = f"bright_{color}_{zodiac}.png"
            # Scorpio uses a per-color source map (SCORPIO_SOURCE):
            # "new" -> backgrounds_scorpio_bright_visible/ (subtle tail+claws + scene)
            # "old" -> backgrounds_scorpio_bright/ (abstract 3 gas curls, no body)
            if zodiac == "scorpio":
                pick = SCORPIO_SOURCE.get(color, "new")
                if pick == "new":
                    src_candidates = [
                        WORKTREE_SHARE / "backgrounds_scorpio_bright_visible" / filename,
                        MAIN_SHARE / "backgrounds_scorpio_bright_visible" / filename,
                    ]
                else:  # "old"
                    src_candidates = [
                        WORKTREE_SHARE / "backgrounds_scorpio_bright" / filename,
                        MAIN_SHARE / "backgrounds_scorpio_bright" / filename,
                    ]
            else:
                src_candidates = [
                    WORKTREE_SHARE / f"backgrounds_{zodiac}_bright" / filename,
                    MAIN_SHARE / f"backgrounds_{zodiac}_bright" / filename,
                ]
            src = find_source(filename, *src_candidates)
            if src is None:
                fail += 1
                continue
            dst = bright_dst / f"bright_{color}_{zodiac}.webp"
            if convert(src, dst, force):
                ok += 1
            else:
                fail += 1

    # ===== ★3: mystical/ =====
    mystical_dst = ASSETS_OUT / "mystical"
    print(f"\n=== ★3: mystical/ -> {mystical_dst} ===")
    for zodiac in ZODIACS:
        filename = f"{zodiac}.png"
        src = find_source(
            filename,
            WORKTREE_SHARE / "backgrounds_mystical" / filename,
            MAIN_SHARE / "backgrounds_mystical" / filename,
        )
        if src is None:
            fail += 1
            continue
        dst = mystical_dst / f"{zodiac}.webp"
        if convert(src, dst, force):
            ok += 1
        else:
            fail += 1

    # ===== ★1-2: lite/ =====
    lite_dst = ASSETS_OUT / "lite"
    print(f"\n=== ★1-2: lite/ -> {lite_dst} ===")
    # pisces_variants has 11 files (one per other-zodiac, excluding pisces itself)
    for zodiac in [z for z in ZODIACS if z != "pisces"]:
        filename = f"pisces_{zodiac}.png"
        src = find_source(
            filename,
            WORKTREE_SHARE / "backgrounds_pisces_variants" / filename,
            MAIN_SHARE / "backgrounds_pisces_variants" / filename,
        )
        if src is None:
            fail += 1
            continue
        dst = lite_dst / f"pisces_{zodiac}.webp"
        if convert(src, dst, force):
            ok += 1
        else:
            fail += 1

    print(f"\n=== Done: {ok} OK, {fail} fail ===")
    print(f"Output dir: {ASSETS_OUT}")


if __name__ == "__main__":
    main()
