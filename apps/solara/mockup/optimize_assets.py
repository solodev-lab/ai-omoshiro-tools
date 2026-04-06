"""
Optimize all share-assets: resize + convert to WebP.

Targets:
  backgrounds/     → 1080x1920 WebP quality 85 (share card use, needs full res)
  class-icons/      → 256x256 WebP quality 85 (overlay on share card, small)
  zodiac-symbols/   → 256x256 WebP quality 85 (overlay on share card, small)
  constellation-art/→ 512x512 WebP quality 85 (15% opacity background overlay)

Keeps originals in *_original/ backup folders.
"""
import os
import shutil
from PIL import Image

BASE = os.path.join(os.path.dirname(__file__), "share-assets")

CONFIGS = {
    "backgrounds":      {"size": (1080, 1920), "quality": 85, "mode": "cover"},
    "class-icons":      {"size": (256, 256),   "quality": 85, "mode": "cover"},
    "zodiac-symbols":   {"size": (256, 256),   "quality": 85, "mode": "cover"},
    "constellation-art":{"size": (512, 512),   "quality": 85, "mode": "contain"},
}


def resize_cover(img, target_w, target_h):
    """Resize to cover target, then center crop."""
    img_ratio = img.width / img.height
    target_ratio = target_w / target_h
    if img_ratio > target_ratio:
        new_h = target_h
        new_w = int(img.width * (target_h / img.height))
    else:
        new_w = target_w
        new_h = int(img.height * (target_w / img.width))
    img = img.resize((new_w, new_h), Image.LANCZOS)
    left = (new_w - target_w) // 2
    top = (new_h - target_h) // 2
    return img.crop((left, top, left + target_w, top + target_h))


def resize_contain(img, target_w, target_h):
    """Resize to fit within target, pad with black."""
    img.thumbnail((target_w, target_h), Image.LANCZOS)
    result = Image.new("RGB", (target_w, target_h), (0, 0, 0))
    x = (target_w - img.width) // 2
    y = (target_h - img.height) // 2
    result.paste(img, (x, y))
    return result


def optimize_folder(folder_name, config):
    folder = os.path.join(BASE, folder_name)
    if not os.path.exists(folder):
        print(f"  SKIP: {folder} not found")
        return 0, 0

    target_w, target_h = config["size"]
    quality = config["quality"]
    mode = config["mode"]

    # Backup originals
    backup = os.path.join(BASE, folder_name + "_original")
    if not os.path.exists(backup):
        shutil.copytree(folder, backup)
        print(f"  Backed up originals to {folder_name}_original/")

    before_total = 0
    after_total = 0
    count = 0

    for fname in sorted(os.listdir(folder)):
        if not fname.lower().endswith(('.png', '.jpg', '.jpeg', '.webp')):
            continue

        src_path = os.path.join(folder, fname)
        before_size = os.path.getsize(src_path)
        before_total += before_size

        img = Image.open(src_path).convert("RGB")

        if mode == "cover":
            img = resize_cover(img, target_w, target_h)
        else:
            img = resize_contain(img, target_w, target_h)

        # Save as WebP
        webp_name = os.path.splitext(fname)[0] + ".webp"
        webp_path = os.path.join(folder, webp_name)
        img.save(webp_path, "WEBP", quality=quality)
        after_size = os.path.getsize(webp_path)
        after_total += after_size

        # Remove original PNG if different name
        if webp_name != fname:
            os.remove(src_path)

        ratio = (1 - after_size / before_size) * 100
        count += 1
        print(f"    {fname} → {webp_name}: {before_size//1024}KB → {after_size//1024}KB ({ratio:.0f}% smaller)")

    return before_total, after_total


print("=" * 60)
print("  SHARE ASSET OPTIMIZATION")
print("=" * 60)

grand_before = 0
grand_after = 0

for folder_name, config in CONFIGS.items():
    print(f"\n--- {folder_name} ({config['size'][0]}x{config['size'][1]} WebP q{config['quality']}) ---")
    before, after = optimize_folder(folder_name, config)
    grand_before += before
    grand_after += after

print(f"\n{'=' * 60}")
print(f"  TOTAL: {grand_before // (1024*1024)}MB → {grand_after // (1024*1024)}MB")
print(f"  Reduction: {(1 - grand_after / grand_before) * 100:.0f}%")
print(f"{'=' * 60}")
