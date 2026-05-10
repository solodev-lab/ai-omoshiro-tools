"""
Convert menu icons (1024x1024 PNG) to compact WebP (256x256) for Flutter assets.

Source: apps/solara/mockup/share-assets/menu-icons/
Dest:   apps/solara/assets/menu_icons/

Mapping (only adopted versions; 8-pointed and subtle 9-pointed PNGs are
kept in source as backup but NOT copied to assets):
  unsealed_9pt_vivid.png  ->  unsealed.webp
  all.png                 ->  all.webp
  love.png                ->  love.webp
  money.png               ->  money.webp
  work.png                ->  work.webp
  healing.png             ->  healing.webp
  communication.png       ->  communication.webp
  fortune.png             ->  fortune.webp
  location.png            ->  location.webp
  forecast.png            ->  forecast.webp
"""
from pathlib import Path
from PIL import Image

SRC_DIR = Path(__file__).parent / "share-assets" / "menu-icons"
DST_DIR = Path(__file__).resolve().parents[1] / "assets" / "menu_icons"
DST_DIR.mkdir(parents=True, exist_ok=True)

MAPPING = {
    "unsealed_9pt_vivid.png": "unsealed.webp",
    "all.png": "all.webp",
    "love.png": "love.webp",
    "money.png": "money.webp",
    "work.png": "work.webp",
    "healing.png": "healing.webp",
    "communication.png": "communication.webp",
    "fortune.png": "fortune.webp",
    "location.png": "location.webp",
    "forecast.png": "forecast.webp",
}

TARGET_SIZE = 256
QUALITY = 88

print(f"Source: {SRC_DIR}")
print(f"Dest:   {DST_DIR}\n")

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
    img.save(str(dst), "WEBP", quality=QUALITY, method=6)
    src_kb = src.stat().st_size // 1024
    dst_kb = dst.stat().st_size // 1024
    total_src += src_kb
    total_dst += dst_kb
    print(f"  OK: {src_name} ({src_kb}KB) -> {dst_name} ({dst_kb}KB)")

print(f"\nTotal: {total_src}KB -> {total_dst}KB "
      f"({100 * total_dst // max(total_src, 1)}% of original)")
print("Done.")
