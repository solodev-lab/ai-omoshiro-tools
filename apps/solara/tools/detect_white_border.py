"""
constellation-art/*.webp の白枠検出（RGBA厳密版）。
透明ピクセルは無視し、実際のRGB値だけで端の明度を計算。
"""
import os
from PIL import Image
import numpy as np

folder = "E:/AppCreate/apps/solara/assets/constellation-art/"
results = []

def edge_brightness(img_rgba, region):
    """region: (y0, y1, x0, x1)"""
    y0, y1, x0, x1 = region
    slice_ = img_rgba[y0:y1, x0:x1]
    rgb = slice_[:, :, :3]
    alpha = slice_[:, :, 3]
    mask = alpha > 0
    if mask.sum() == 0:
        return None, 0
    return rgb[mask].mean(), mask.sum()

for f in sorted(os.listdir(folder)):
    if not f.endswith('.webp'):
        continue
    img = np.array(Image.open(os.path.join(folder, f)).convert('RGBA'))
    h, w, _ = img.shape
    regions = [
        (0, 5, 0, w),           # top
        (h-5, h, 0, w),         # bottom
        (0, h, 0, 5),           # left
        (0, h, w-5, w),         # right
    ]
    edge_vals = [edge_brightness(img, r) for r in regions]
    has_alpha = any(v[1] < (r[1]-r[0])*(r[3]-r[2]) for v, r in zip(edge_vals, regions))

    edge_avg_vals = [v[0] for v in edge_vals if v[0] is not None]
    edge_avg = np.mean(edge_avg_vals) if edge_avg_vals else 0

    # center brightness
    center = img[h//4:3*h//4, w//4:3*w//4, :3].mean()

    diff = edge_avg - center
    results.append((f, edge_avg, center, diff, has_alpha))

results.sort(key=lambda x: -x[1])

print(f"{'file':<25} {'edge':>8} {'center':>8} {'diff':>8} {'alpha':>6}")
for r in results:
    marker = " *" if r[1] > 60 else ""
    alpha_mark = "yes" if r[4] else "no"
    print(f"{r[0]:<25} {r[1]:>8.1f} {r[2]:>8.1f} {r[3]:>8.1f} {alpha_mark:>6}{marker}")
