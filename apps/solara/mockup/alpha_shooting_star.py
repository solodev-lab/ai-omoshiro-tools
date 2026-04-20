"""
Transparent background for meteor/shooting-star images.
Unlike planets, meteors have free-form streaks on a black background,
so a luminance threshold is the right tool here.

Usage:
  python alpha_shooting_star.py --dir share-assets/tarot_scene/shooting_stars
"""
import sys
from pathlib import Path


def alpha_luminance(img, threshold=10, soft=12):
    """Alpha = smoothed luminance above threshold."""
    from PIL import Image
    import numpy as np

    img = img.convert("RGBA")
    arr = np.array(img)
    rgb = arr[:, :, :3].astype(np.float32)
    lum = (0.2126 * rgb[:, :, 0] + 0.7152 * rgb[:, :, 1]
           + 0.0722 * rgb[:, :, 2])

    alpha = (lum - threshold) / soft
    alpha = alpha.clip(0.0, 1.0)
    # Boost — once clearly above the threshold, go fully opaque quickly
    alpha = (alpha ** 0.6) * 255.0
    arr[:, :, 3] = alpha.clip(0, 255).astype(np.uint8)
    return Image.fromarray(arr)


def process_file(src: Path, dst: Path):
    from PIL import Image
    img = Image.open(src)
    out = alpha_luminance(img)
    out.save(dst, "PNG")
    print(f"  OK: {src.name} -> {dst.name}")


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        return
    if args[0] == "--dir":
        d = Path(args[1])
        for src in sorted(d.glob("*.png")):
            if src.name.endswith("_alpha.png"):
                continue
            dst = src.with_name(src.stem + "_alpha.png")
            process_file(src, dst)
        return
    if len(args) >= 2:
        process_file(Path(args[0]), Path(args[1]))


if __name__ == "__main__":
    main()
