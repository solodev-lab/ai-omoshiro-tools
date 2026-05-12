"""
Solara クラスカード PNG → WebP 変換 + Flutter assets 配置

class-cards/*.png → assets/class-cards/*.webp に変換配置。
品質80%、長辺1024pxにリサイズ（Flutter assets 軽量化）。

Usage: python convert_to_webp.py
"""

from pathlib import Path
from PIL import Image

SRC_DIR = Path(__file__).resolve().parent
DST_DIR = SRC_DIR.parent / "assets" / "class-cards"
DST_DIR.mkdir(parents=True, exist_ok=True)

# サンプル・テスト用の knight_*.png は除外（本番25枚のみ変換）
EXCLUDE_PATTERNS = [
    "knight_vermeer", "knight_mtg", "knight_hearthstone",
    "knight_ff", "knight_hybrid_ff_mtg",
    "knight_art_nouveau", "knight_silhouette",
]

# 本番ファイル命名規約: <axis>_<court>_<name>.png
# (例: power_page_knight.png)

MAX_DIM = 1024  # 長辺
QUALITY = 82

converted, skipped = [], []

for png in sorted(SRC_DIR.glob("*.png")):
    stem = png.stem
    if any(stem.startswith(p) or stem == p for p in EXCLUDE_PATTERNS):
        skipped.append(png.name)
        continue

    # 本番命名規約に従うものだけ変換
    parts = stem.split("_")
    if len(parts) < 3 or parts[0] not in ("power", "mind", "spirit", "shadow", "heart"):
        skipped.append(png.name)
        continue

    dst = DST_DIR / f"{stem}.webp"

    img = Image.open(png)
    # アスペクト維持リサイズ
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

print(f"\n=== Summary ===")
print(f"Converted: {len(converted)}")
print(f"Skipped (samples/non-class): {len(skipped)}")
if converted:
    total_src = sum(p.stat().st_size for p, _, _ in [(SRC_DIR/c[0], c[1], c[2]) for c in converted])
    total_dst = sum(c[2] for c in converted)
    print(f"Source total: {total_src // 1024} KB")
    print(f"WebP total:   {total_dst // 1024} KB")
    print(f"Compression:  {(1 - total_dst / total_src) * 100:.0f}%")
