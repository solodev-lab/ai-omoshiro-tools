"""
Convert menu icons (1024x1024 PNG) to compact WebP (256x256) for Flutter assets.

Adds a feathered circular alpha mask so the four black corners of each
emblem are transparent. This prevents the chip background gradient from
being interrupted by hard black squares.

Source: apps/solara/mockup/share-assets/menu-icons/v2/  (V2 woodblock style)
Dest:   apps/solara/assets/menu_icons/

V1 PNG (assets/menu_icons/{V1}.webp は v1 vivid 由来) は元絵が
mockup/share-assets/menu-icons/{name}.png に元絵保護されており、
webp 上書きしても元絵は失われない。

Mapping (V2 採用版、healing は moon 採用、healing_no_moon は不採用):
  v2/unsealed.png       ->  unsealed.webp
  v2/all.png            ->  all.webp
  v2/love.png           ->  love.webp
  v2/money.png          ->  money.webp
  v2/work.png           ->  work.webp           (大樹)
  v2/healing_moon.png   ->  healing.webp        (月採用)
  v2/communication.png  ->  communication.webp
  v2/fortune.png        ->  fortune.webp        (文字なし)
  v2/location.png       ->  location.webp
  v2/forecast.png       ->  forecast.webp
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

SRC_DIR = Path(__file__).parent / "share-assets" / "menu-icons"
DST_DIR = Path(__file__).resolve().parents[1] / "assets" / "menu_icons"
DST_DIR.mkdir(parents=True, exist_ok=True)

MAPPING = {
    "v2/unsealed.png": "unsealed.webp",
    "v2/all.png": "all.webp",
    "v2/love.png": "love.webp",
    "v2/money.png": "money.webp",
    "v2/work.png": "work.webp",
    "v2/healing_moon.png": "healing.webp",
    "v2/communication.png": "communication.webp",
    "v2/fortune.png": "fortune.webp",
    "v2/location.png": "location.webp",
    "v2/forecast.png": "forecast.webp",
}

TARGET_SIZE = 256
QUALITY = 90  # alpha 入りで少し品質を上げる

# Circular mask params
# 全 emblem は外周フレームを正円で持つので、半径 ~48% のマスクで
# フレームちょうど内側まで残し、四隅の黒は完全透明にする。
# feather (羽根ぼかし) で境界をスムーズに。
MASK_RADIUS_RATIO = 0.495   # 中心から半径 = サイズ * 0.495
FEATHER_PIXELS = 4          # マスクのぼかし量 (px @ 256)


def make_circular_mask(size: int) -> Image.Image:
    """Returns a feathered circular alpha mask (mode L)."""
    # 高解像度で描画して supersampling 風に
    upsample = 4
    big = size * upsample
    mask = Image.new("L", (big, big), 0)
    draw = ImageDraw.Draw(mask)
    cx = cy = big / 2
    r = big * MASK_RADIUS_RATIO
    draw.ellipse(
        [cx - r, cy - r, cx + r, cy + r],
        fill=255,
    )
    mask = mask.resize((size, size), Image.LANCZOS)
    mask = mask.filter(ImageFilter.GaussianBlur(radius=FEATHER_PIXELS))
    return mask


def main() -> None:
    print(f"Source: {SRC_DIR}")
    print(f"Dest:   {DST_DIR}\n")

    mask = make_circular_mask(TARGET_SIZE)

    total_src = 0
    total_dst = 0
    for src_name, dst_name in MAPPING.items():
        src = SRC_DIR / src_name
        dst = DST_DIR / dst_name
        if not src.exists():
            print(f"  MISS: {src_name}")
            continue
        img = Image.open(src).convert("RGB")
        img = img.resize((TARGET_SIZE, TARGET_SIZE), Image.LANCZOS)
        img = img.convert("RGBA")
        # Apply circular alpha mask (replace, not multiply, since RGB is opaque)
        img.putalpha(mask)
        img.save(str(dst), "WEBP", quality=QUALITY, method=6)
        src_kb = src.stat().st_size // 1024
        dst_kb = dst.stat().st_size // 1024
        total_src += src_kb
        total_dst += dst_kb
        print(f"  OK: {src_name} ({src_kb}KB) -> {dst_name} ({dst_kb}KB)")

    print(
        f"\nTotal: {total_src}KB -> {total_dst}KB "
        f"({100 * total_dst // max(total_src, 1)}% of original)"
    )
    print("Done.")


if __name__ == "__main__":
    main()
