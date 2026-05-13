"""
Solara 称号診断 背景画像 PNG → WebP 変換 + assets 配置

part_X_<name>.png → assets/diagnosis-bg/part_X.webp
(Flutter コードと合わせるためファイル名を `part_<num>.webp` に簡素化)

長辺 1080px、品質 80。

Usage: python convert_to_webp.py
"""

import re
from pathlib import Path
from PIL import Image

SRC_DIR = Path(__file__).resolve().parent
DST_DIR = SRC_DIR.parent / "assets" / "diagnosis-bg"
DST_DIR.mkdir(parents=True, exist_ok=True)

MAX_DIM = 1080
QUALITY = 80

part_pattern = re.compile(r"^part_(\d+)(?:_.*)?$")
# シーン背景は filename と同じで OK
SCENE_NAMES = {"ceremony", "intro", "forging", "reveal", "share_card_bg"}

converted = []
for png in sorted(SRC_DIR.glob("*.png")):
    stem = png.stem
    if stem in SCENE_NAMES:
        dst = DST_DIR / f"{stem}.webp"
    else:
        m = part_pattern.match(stem)
        if not m:
            print(f"skip: {png.name} (unknown pattern)")
            continue
        part_num = m.group(1)
        dst = DST_DIR / f"part_{part_num}.webp"

    img = Image.open(png)
    w, h = img.size
    if max(w, h) > MAX_DIM:
        if w > h:
            new_w, new_h = MAX_DIM, int(h * MAX_DIM / w)
        else:
            new_w, new_h = int(w * MAX_DIM / h), MAX_DIM
        img = img.resize((new_w, new_h), Image.LANCZOS)

    img.save(dst, "WEBP", quality=QUALITY, method=6)
    converted.append((png.name, dst.name, dst.stat().st_size))
    print(f"[OK] {png.name} ({png.stat().st_size//1024}KB) -> {dst.name} ({dst.stat().st_size//1024}KB)")

print(f"\n=== Summary ===\nConverted: {len(converted)}")
