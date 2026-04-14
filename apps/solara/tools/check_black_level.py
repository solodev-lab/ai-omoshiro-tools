"""
各画像の「黒背景」の実際の輝度を調べる。
- min value (最暗ピクセル)
- 最頻値 (mode) と bottom 10%/25%/50% percentile
- 背景領域の中央値
"""
import os
import numpy as np
from PIL import Image

folder = "E:/AppCreate/apps/solara/assets/constellation-art/"

print(f"{'file':<20} {'min':>4} {'p10':>4} {'p25':>4} {'p50':>4} {'mode':>4}")
for f in sorted(os.listdir(folder)):
    if not f.endswith('.webp'):
        continue
    img = np.array(Image.open(os.path.join(folder, f)).convert('RGB'))
    luma = (img[:,:,0]*0.299 + img[:,:,1]*0.587 + img[:,:,2]*0.114).astype(np.int32)
    flat = luma.flatten()
    vmin = flat.min()
    p10 = int(np.percentile(flat, 10))
    p25 = int(np.percentile(flat, 25))
    p50 = int(np.percentile(flat, 50))
    # mode: 最頻値
    vals, counts = np.unique(flat, return_counts=True)
    mode = int(vals[counts.argmax()])
    print(f"{f:<20} {vmin:>4} {p10:>4} {p25:>4} {p50:>4} {mode:>4}")
