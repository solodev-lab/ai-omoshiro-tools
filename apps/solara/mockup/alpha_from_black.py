"""
Convert pure-black backgrounds to alpha channel.
Used to post-process Gemini-generated images (planets, shooting stars)
that come with solid black backgrounds.

Algorithm:
  1. Load image, convert to RGBA.
  2. For each pixel: alpha = luminance (brightness-keyed).
     - pure black  → alpha = 0  (transparent)
     - bright pixel → alpha = 255 (opaque)
  3. Optional soft threshold to avoid grey halos.

Usage:
  python alpha_from_black.py <input.png> <output.png>
  python alpha_from_black.py --dir share-assets/tarot_scene/planets
"""
import sys
from pathlib import Path


# Planet-specific alpha mask shape: (rx_ratio, ry_ratio) relative to image size.
# Default is circular; Saturn uses a wide ellipse to include the rings.
PLANET_SHAPE = {
    "saturn": (0.49, 0.32),
}
DEFAULT_SHAPE = (0.46, 0.46)


def luminance_alpha(img, planet_name=None, feather=4.0):
    """
    Alpha mask based on a centered ellipse — robust against the planet's
    dark shadow side being indistinguishable from the black background.

    For Saturn (with rings that don't fill the ellipse), we also AND in
    a luminance mask so that the empty black void inside the bounding
    ellipse becomes transparent.

    The ellipse size is per-planet (Saturn has a wide one for its rings).
    """
    from PIL import Image, ImageDraw, ImageFilter
    import numpy as np

    img = img.convert("RGBA")
    w, h = img.size
    rx_ratio, ry_ratio = PLANET_SHAPE.get(planet_name, DEFAULT_SHAPE)
    cx, cy = w / 2, h / 2
    rx = w * rx_ratio
    ry = h * ry_ratio

    ell = Image.new("L", (w, h), 0)
    ImageDraw.Draw(ell).ellipse(
        (cx - rx, cy - ry, cx + rx, cy + ry), fill=255
    )
    if feather > 0:
        ell = ell.filter(ImageFilter.GaussianBlur(radius=feather))

    if planet_name == "saturn":
        arr = np.array(img)
        rgb = arr[:, :, :3].astype(np.float32)
        lum = (0.2126 * rgb[:, :, 0] + 0.7152 * rgb[:, :, 1]
               + 0.0722 * rgb[:, :, 2])
        # Smooth luminance ramp: fully transparent below 10, fully opaque by 40
        lum_a = np.clip((lum - 10.0) / 30.0, 0.0, 1.0) * 255.0
        lum_img = Image.fromarray(lum_a.astype(np.uint8), mode="L")
        # AND the two masks (element-wise minimum)
        combined = np.minimum(np.array(ell), np.array(lum_img))
        arr[:, :, 3] = combined
        return Image.fromarray(arr)

    arr = np.array(img)
    arr[:, :, 3] = np.array(ell)
    return Image.fromarray(arr)


def process_file(src: Path, dst: Path):
    from PIL import Image
    img = Image.open(src)
    out = luminance_alpha(img, planet_name=src.stem)
    out.save(dst, "PNG")
    print(f"  OK: {src.name} -> {dst.name}")


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        return

    if args[0] == "--dir":
        if len(args) < 2:
            print("Usage: --dir <directory>")
            return
        d = Path(args[1])
        for src in sorted(d.glob("*.png")):
            if src.name.endswith("_alpha.png"):
                continue
            dst = src.with_name(src.stem + "_alpha.png")
            process_file(src, dst)
        return

    if len(args) < 2:
        print("Usage: python alpha_from_black.py <input> <output>")
        return
    process_file(Path(args[0]), Path(args[1]))


if __name__ == "__main__":
    main()
