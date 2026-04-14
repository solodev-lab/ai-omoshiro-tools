"""
白枠がある10枚の星座絵webpの枠を黒塗りして除去する。
各辺から「行/列のほぼ全体(≥95%)が白(R>240)」な部分を検出し黒で塗りつぶす。
元画像はバックアップフォルダに保存。
"""
import os
import shutil
import numpy as np
from PIL import Image

SRC = "E:/AppCreate/apps/solara/assets/constellation-art/"
BACKUP = "E:/AppCreate/apps/solara/assets/constellation-art-backup/"

TARGETS = [
    'chalice', 'arrow', 'griffin', 'anchor', 'wing',
    'serpent', 'unicorn', 'sword', 'jewel', 'mirror',
]

THRESHOLD = 240   # pixel R value above this is considered "white"
RATIO = 0.95      # row/col must have >= 95% white pixels to be a border

def row_is_white(row, thr, ratio):
    return (row[:, 0] > thr).sum() / len(row) >= ratio

def col_is_white(col, thr, ratio):
    return (col[:, 0] > thr).sum() / len(col) >= ratio

def fix_borders(path_in, path_out):
    img = np.array(Image.open(path_in).convert('RGB'))
    h, w, _ = img.shape

    # detect from each edge
    top = 0
    while top < h and row_is_white(img[top, :, :], THRESHOLD, RATIO):
        top += 1

    bottom = 0
    while bottom < h and row_is_white(img[h-1-bottom, :, :], THRESHOLD, RATIO):
        bottom += 1

    left = 0
    while left < w and col_is_white(img[:, left, :], THRESHOLD, RATIO):
        left += 1

    right = 0
    while right < w and col_is_white(img[:, w-1-right, :], THRESHOLD, RATIO):
        right += 1

    # fill borders with black
    if top > 0:
        img[0:top, :, :] = 0
    if bottom > 0:
        img[h-bottom:h, :, :] = 0
    if left > 0:
        img[:, 0:left, :] = 0
    if right > 0:
        img[:, w-right:w, :] = 0

    Image.fromarray(img).save(path_out, 'WEBP', quality=90)
    return (top, bottom, left, right)


def main():
    os.makedirs(BACKUP, exist_ok=True)
    print(f"{'noun':<15} {'top':>5} {'bot':>5} {'left':>5} {'right':>5}")
    for name in TARGETS:
        src = os.path.join(SRC, f"{name}.webp")
        bkp = os.path.join(BACKUP, f"{name}.webp")
        if not os.path.exists(src):
            print(f"MISS: {name}")
            continue
        # backup
        if not os.path.exists(bkp):
            shutil.copy2(src, bkp)
        # fix
        top, bot, left, right = fix_borders(src, src)
        print(f"{name:<15} {top:>5} {bot:>5} {left:>5} {right:>5}")

if __name__ == "__main__":
    main()
