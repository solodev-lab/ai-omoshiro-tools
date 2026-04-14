"""chalice の端の実際のピクセル値を表示"""
from PIL import Image
import numpy as np

for name in ['chalice', 'arrow', 'anchor', 'sword']:
    img = np.array(Image.open(f"E:/AppCreate/apps/solara/assets/constellation-art/{name}.webp").convert('RGBA'))
    h, w, _ = img.shape
    print(f"\n=== {name}.webp ({w}x{h}) ===")
    # top 1行の最初の10px
    print(f"top[0] first 10px R: {img[0, :10, 0]}")
    # 左1列の最初の10px
    print(f"left col first 10 rows R: {img[:10, 0, 0]}")
    # 5行目中央
    print(f"row[5] center 10px R: {img[5, w//2-5:w//2+5, 0]}")
    # row 10, 20, 30 の最初の5px
    for y in [10, 20, 30, 50]:
        print(f"row[{y}] first 5px R: {img[y, :5, 0]}")
