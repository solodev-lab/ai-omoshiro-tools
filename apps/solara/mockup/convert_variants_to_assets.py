"""
Convert "variants" PNGs (mockup) -> WEBP into apps/solara/assets/catasterism-bg/variants_*.

Sources (each folder contains 11 PNGs, named `{base}_{themeZodiac}.png`):
  - share-assets/backgrounds_leo_variants/      (★4 layer, side A)
  - share-assets/backgrounds_virgo_variants/    (★4 layer, side B)
  - share-assets/backgrounds_scorpio_variants/  (★3 layer, side A)
  - share-assets/backgrounds_aquarius_variants/ (★3 layer, side B)
  - share-assets/backgrounds_pisces_variants/   (★1-2 layer, side A)
  - share-assets/backgrounds_aries_variants/    (★1-2 layer, side B)

themeZodiac → 形容詞グループ対応:
  leo→golden / gemini→silver / aries→crimson / cancer→ethereal / scorpio→mystic
  capricorn→silent / aquarius→frozen / taurus→ancient / virgo→infinite / libra→radiant
  (sagittarius→未使用、PNG は存在しても削除される)

Output:
  apps/solara/assets/catasterism-bg/variants_leo/     (11 WEBPs)
  apps/solara/assets/catasterism-bg/variants_virgo/   (11 WEBPs)
  apps/solara/assets/catasterism-bg/variants_scorpio/ (11 WEBPs)
  apps/solara/assets/catasterism-bg/variants_aquarius/(11 WEBPs)
  apps/solara/assets/catasterism-bg/variants_pisces/  (11 WEBPs)
  apps/solara/assets/catasterism-bg/variants_aries/   (11 WEBPs)

Usage:
  python convert_variants_to_assets.py            # convert all (skip if WEBP exists)
  python convert_variants_to_assets.py --force    # overwrite existing WEBPs
"""
import sys
from pathlib import Path
from PIL import Image

WORKTREE_MOCKUP = Path(__file__).resolve().parent
WORKTREE_SHARE = WORKTREE_MOCKUP / "share-assets"
MAIN_SHARE = Path("E:/AppCreate/apps/solara/mockup/share-assets")
ASSETS_OUT = WORKTREE_MOCKUP.parent / "assets" / "catasterism-bg"

WEBP_QUALITY = 85

# (folder_name_suffix, base_zodiac)
BASE_ZODIACS = [
    "leo", "virgo",      # ★4
    "scorpio", "aquarius",  # ★3
    "pisces", "aries",    # ★1-2
]


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
    print(f"  {src.name} ({src_kb}KB) -> variants_{dst.parent.name.split('_')[1]}/{dst.name} ({dst_kb}KB, {100*dst_kb//max(src_kb,1)}%)")
    return True


def main():
    force = "--force" in sys.argv

    ok = 0
    fail = 0
    skipped = 0

    for base in BASE_ZODIACS:
        src_dir_candidates = [
            WORKTREE_SHARE / f"backgrounds_{base}_variants",
            MAIN_SHARE / f"backgrounds_{base}_variants",
        ]
        src_dir = next((c for c in src_dir_candidates if c.exists()), None)
        if src_dir is None:
            print(f"\n=== {base} -> MISSING source folder ({src_dir_candidates}) ===")
            fail += 1
            continue
        dst_dir = ASSETS_OUT / f"variants_{base}"
        print(f"\n=== {base} -> {dst_dir} ===")
        # Iterate over all PNGs in src_dir
        for src_png in sorted(src_dir.glob("*.png")):
            # Filename: e.g. leo_aquarius.png  -> theme=aquarius
            stem = src_png.stem
            if "_" not in stem:
                print(f"  SKIP (bad name): {src_png.name}")
                skipped += 1
                continue
            theme = stem.split("_", 1)[1]
            # sagittarius は未使用 — 形容詞グループに対応しないので除外
            if theme == "sagittarius":
                print(f"  SKIP (sagittarius unused): {src_png.name}")
                skipped += 1
                continue
            # base zodiac 自身も除外 (例: pisces_variants 内に pisces_pisces.png は無いはず)
            if theme == base:
                print(f"  SKIP (self-theme): {src_png.name}")
                skipped += 1
                continue
            dst = dst_dir / f"{stem}.webp"
            if convert(src_png, dst, force):
                ok += 1
            else:
                fail += 1

    print(f"\n=== Done: {ok} converted, {fail} failed, {skipped} skipped ===")


if __name__ == "__main__":
    main()
