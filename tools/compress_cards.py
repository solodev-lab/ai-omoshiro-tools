"""
タロットカード画像圧縮スクリプト
848x1264 PNG → 320x477 WebP (quality 80)
"""
import os
from PIL import Image

SRC = "E:/AppCreate/apps/solara/card-images"
DST = "E:/AppCreate/apps/solara/assets/card-images"

os.makedirs(DST, exist_ok=True)

count = 0
for f in sorted(os.listdir(SRC)):
    if not f.endswith(".png"):
        continue
    # Skip variants (_v2, _v3 etc) and copies
    if "_v" in f and f.split("_v")[1].split(".")[0].isdigit():
        continue
    if "コピー" in f:
        continue

    src_path = os.path.join(SRC, f)
    # Output as webp
    out_name = f.replace(".png", ".webp")
    dst_path = os.path.join(DST, out_name)

    img = Image.open(src_path)
    # Resize to 320px width, maintaining aspect ratio
    w, h = img.size
    new_w = 320
    new_h = int(h * new_w / w)
    img = img.resize((new_w, new_h), Image.LANCZOS)
    img.save(dst_path, "WEBP", quality=80)

    src_size = os.path.getsize(src_path) / 1024
    dst_size = os.path.getsize(dst_path) / 1024
    count += 1

# Also remove old PNGs from assets
for f in os.listdir(DST):
    if f.endswith(".png"):
        os.remove(os.path.join(DST, f))

print(f"Done: {count} cards compressed")
print(f"Total size: {sum(os.path.getsize(os.path.join(DST, f)) for f in os.listdir(DST)) / 1024 / 1024:.1f} MB")
