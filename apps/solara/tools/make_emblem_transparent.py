"""app_icon_foreground.png の黒背景を透過にしたコピーを作る (タロット裏エンブレム用)。

ランチャーアイコン (adaptive_icon_foreground) 兼用の元画像は触らず、
透過版 assets/app_icon_emblem.png を新規生成する。
黒(暗)ピクセルを alpha=0、明るい(星/金環)を不透明にし、間をなだらかに。
"""
import os
from PIL import Image

HERE = os.path.dirname(__file__)
SRC = os.path.join(HERE, "..", "assets", "app_icon_foreground.png")
DST = os.path.join(HERE, "..", "assets", "app_icon_emblem.png")

LO, HI = 12, 60  # lum<=LO 完全透過 / lum>=HI 不透明 / 間は線形


def main():
    img = Image.open(SRC).convert("RGBA")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            lum = max(r, g, b)
            if lum <= LO:
                na = 0
            elif lum >= HI:
                na = a
            else:
                na = int(a * (lum - LO) / (HI - LO))
            px[x, y] = (r, g, b, na)
    img.save(DST)
    print(f"wrote {os.path.abspath(DST)} ({w}x{h})")


if __name__ == "__main__":
    main()
