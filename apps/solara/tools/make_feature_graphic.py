# -*- coding: utf-8 -*-
"""
Google Play フィーチャーグラフィック (1024×500) デザイン案ジェネレータ。
3 構図 (A: 紋章左+テキスト右 / B: 中央シンメトリ / C: アストロカートグラフィ地図) を出力。
- 文字はクッキリ出すため手組み (AI 生成だと文字化けするため)。
- 出力: docs/store_compliance_assets/feature_graphic/feature_graphic_[A|B|C]_*.png (RGB / 透過なし)
- ブランド: 見出し Cinzel / 和文 Noto Serif JP / ゴールド+アイボリー on 紺〜黒。
- 背景は手描き procedural (無料・即時)。気に入った構図は背景を Gemini ネビュラに差し替え可。
"""
import os, math, random
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)  # apps/solara
SRC = os.path.join(ROOT, "mockup", "share-assets", "menu-icons", "v2", "unsealed.png")
OUTDIR = os.path.join(ROOT, "docs", "store_compliance_assets", "feature_graphic")
os.makedirs(OUTDIR, exist_ok=True)

W, H = 1024, 500
# Cinzel (OFL) は git 管理外 (.gitignore: tools/_fonts_*.ttf)。無ければ以下で取得:
#   curl -sL -o tools/_fonts_Cinzel.ttf \
#     "https://github.com/google/fonts/raw/main/ofl/cinzel/Cinzel%5Bwght%5D.ttf"
CINZEL = os.path.join(HERE, "_fonts_Cinzel.ttf")
NOTO_SERIF = r"C:/Windows/Fonts/NotoSerifJP-VF.ttf"

# パレット
GOLD = (212, 178, 112)
GOLD_HI = (240, 214, 150)
GOLD_LO = (170, 132, 70)
IVORY = (242, 236, 223)
CYAN = (130, 170, 200)

WORDMARK = "SOLARA"
TAGLINE = "占星術でひもとく自己探求"


def font(path, size, wght=None):
    f = ImageFont.truetype(path, size)
    if wght is not None:
        try:
            f.set_variation_by_axes([wght])
        except Exception:
            pass
    return f


def bg_gradient(top, bot):
    g1 = Image.new("RGB", (1, H))
    for y in range(H):
        t = y / (H - 1)
        g1.putpixel((0, y), tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3)))
    return g1.resize((W, H))


def starfield(img, seed=7, n=320):
    rnd = random.Random(seed)
    d = ImageDraw.Draw(img, "RGBA")
    for _ in range(n):
        x = rnd.randint(0, W); y = rnd.randint(0, H)
        r = rnd.choice([0.5, 0.7, 1.0, 1.0, 1.4, 1.8])
        b = rnd.randint(70, 235)
        tint = rnd.choice([(b, b, b), (b, b, min(255, b + 20)), (min(255, b + 15), b, b - 10 if b > 10 else b)])
        d.ellipse([x - r, y - r, x + r, y + r], fill=tint + (b,))
    # 大きめの煌めき数個 (十字スパーク)
    for _ in range(7):
        x = rnd.randint(60, W - 60); y = rnd.randint(40, H - 40)
        L = rnd.randint(7, 16); a = rnd.randint(120, 210)
        d.line([x - L, y, x + L, y], fill=(255, 250, 235, a), width=1)
        d.line([x, y - L, x, y + L], fill=(255, 250, 235, a), width=1)
    return img


def glow_layer(center, radius, color, alpha):
    g = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(g)
    cx, cy = center
    d.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=color + (alpha,))
    return g.filter(ImageFilter.GaussianBlur(radius * 0.55))


def emblem_medallion(diameter):
    src = Image.open(SRC).convert("RGB")
    # 中身 bbox に切り、円マスクで角の黒を透明化 → 宇宙背景に乗るメダルにする
    from PIL import ImageChops
    corner = src.getpixel((0, 0))
    diff = ImageChops.difference(src, Image.new("RGB", src.size, corner)).convert("L")
    bbox = diff.point(lambda p: 255 if p > 18 else 0).getbbox()
    em = src.crop(bbox).convert("RGBA")
    s = em.size[0]
    mask = Image.new("L", em.size, 0)
    ImageDraw.Draw(mask).ellipse([0, 0, s, s], fill=255)
    # 縁を少しだけソフトに
    mask = mask.filter(ImageFilter.GaussianBlur(1.2))
    em.putalpha(mask)
    return em.resize((diameter, diameter), Image.LANCZOS)


def tracked_width(f, text, tr):
    return sum(f.getlength(c) for c in text) + tr * (len(text) - 1)


def draw_tracked(draw, xy, text, f, fill, tr):
    x, y = xy
    for c in text:
        draw.text((x, y), c, font=f, fill=fill)
        x += f.getlength(c) + tr


def draw_kicker(draw, x, y, left, right, f, fill, tr, gap=20, r=5):
    """左語 ◆ 右語 を描く。区切りは手描きの金ダイヤ (Cinzel に ✦ が無く豆腐化するため)。"""
    draw_tracked(draw, (x, y), left, f, fill, tr)
    asc, desc = f.getmetrics()
    cy = y + asc * 0.52
    dx = x + tracked_width(f, left, tr) + gap
    draw.polygon([(dx, cy - r), (dx + r, cy), (dx, cy + r), (dx - r, cy)], fill=GOLD)
    draw_tracked(draw, (dx + gap, y), right, f, fill, tr)


def gradient_text(text, f, tr, ctop, cbot, shadow=True):
    """縦グラデで塗った字 + 影 の RGBA レイヤを返す。"""
    asc, desc = f.getmetrics()
    w = int(tracked_width(f, text, tr)) + 4
    h = asc + desc + 4
    mask = Image.new("L", (w, h), 0)
    draw_tracked(ImageDraw.Draw(mask), (2, 2), text, f, 255, tr)
    g1 = Image.new("RGB", (1, h))
    for y in range(h):
        t = y / (h - 1)
        g1.putpixel((0, y), tuple(int(ctop[i] + (cbot[i] - ctop[i]) * t) for i in range(3)))
    grad = g1.resize((w, h)).convert("RGBA")
    grad.putalpha(mask)
    layer = Image.new("RGBA", (w + 16, h + 16), (0, 0, 0, 0))
    if shadow:
        sh = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        sh.putalpha(mask)
        sh = Image.composite(Image.new("RGBA", (w, h), (0, 0, 0, 200)), Image.new("RGBA", (w, h), (0, 0, 0, 0)), mask)
        sh = sh.filter(ImageFilter.GaussianBlur(4))
        layer.alpha_composite(sh, (8 + 2, 8 + 3))
    layer.alpha_composite(grad, (8, 8))
    return layer


def astro_graticule(alpha_scale=1.0):
    """equirectangular 風グリッド + 惑星ラインのサイン曲線。低 alpha。"""
    g = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(g)
    # 緯度経度グリッド
    for gx in range(0, W + 1, 64):
        d.line([gx, 60, gx, H - 40], fill=GOLD + (int(26 * alpha_scale),), width=1)
    for gy in range(60, H - 39, 56):
        d.line([60, gy, W - 60, gy], fill=GOLD + (int(26 * alpha_scale),), width=1)
    # 惑星ライン (great-circle 風サイン曲線)
    curves = [(70, 1.4, 0.0, CYAN, 70), (120, 1.0, 1.1, GOLD_HI, 80), (95, 1.8, 2.3, GOLD, 70)]
    for amp, freq, ph, col, a in curves:
        pts = []
        for x in range(40, W - 40, 4):
            y = H / 2 + amp * math.sin(freq * (x / W) * 2 * math.pi + ph)
            pts.append((x, y))
        d.line(pts, fill=col + (int(a * alpha_scale),), width=2)
        # 交点っぽい光点
        for i in range(0, len(pts), 60):
            x, y = pts[i]
            d.ellipse([x - 2, y - 2, x + 2, y + 2], fill=(255, 245, 225, int(150 * alpha_scale)))
    return g.filter(ImageFilter.GaussianBlur(0.4))


def vignette_and_border(img):
    # ヴィネット
    v = Image.new("L", (W, H), 0)
    ImageDraw.Draw(v).rectangle([0, 0, W, H], fill=0)
    vg = Image.new("L", (W, H), 0)
    dd = ImageDraw.Draw(vg)
    dd.ellipse([-W * 0.3, -H * 0.4, W * 1.3, H * 1.4], fill=255)
    vg = vg.filter(ImageFilter.GaussianBlur(120))
    dark = Image.new("RGB", (W, H), (0, 0, 0))
    img = Image.composite(img, Image.blend(img, dark, 0.55), vg)
    # 細い金枠
    d = ImageDraw.Draw(img)
    d.rectangle([6, 6, W - 7, H - 7], outline=GOLD + (255,) if False else GOLD, width=2)
    return img


def finalize(img):
    return vignette_and_border(img.convert("RGB"))


# ---------- 構図 A: 紋章左 + テキスト右 ----------
def concept_A():
    img = bg_gradient((13, 18, 38), (4, 6, 14)).convert("RGBA")
    img.alpha_composite(glow_layer((250, 250), 230, GOLD, 60))
    img.alpha_composite(glow_layer((760, 250), 300, (40, 60, 110), 50))
    starfield(img)
    em = emblem_medallion(300)
    img.alpha_composite(glow_layer((250, 250), 175, GOLD_HI, 70))
    img.alpha_composite(em, (250 - 150, 250 - 150))
    d = ImageDraw.Draw(img)
    tx = 462
    fk = font(CINZEL, 24, 600)
    draw_kicker(d, tx + 4, 150, "NATAL", "ASTROLOGY", fk, GOLD + (235,), 6, gap=22)
    wm = gradient_text(WORDMARK, font(CINZEL, 104, 680), 10, GOLD_HI, GOLD_LO)
    img.alpha_composite(wm, (tx - 8, 176))
    d.line([tx + 6, 300, tx + 350, 300], fill=GOLD + (200,), width=2)
    ft = font(NOTO_SERIF, 31, 600)
    d.text((tx + 6, 322), TAGLINE, font=ft, fill=IVORY)
    return finalize(img)


# ---------- 構図 B: 中央シンメトリ ----------
def concept_B():
    img = bg_gradient((12, 16, 34), (3, 5, 12)).convert("RGBA")
    img.alpha_composite(glow_layer((512, 180), 320, GOLD, 55))
    starfield(img, seed=21)
    img.alpha_composite(glow_layer((512, 175), 150, GOLD_HI, 75))
    em = emblem_medallion(232)
    img.alpha_composite(em, (512 - 116, 175 - 116))
    wm = gradient_text(WORDMARK, font(CINZEL, 86, 680), 14, GOLD_HI, GOLD_LO)
    img.alpha_composite(wm, (512 - wm.size[0] // 2, 296))
    d = ImageDraw.Draw(img)
    ft = font(NOTO_SERIF, 28, 600)
    tw = d.textlength(TAGLINE, font=ft)
    d.line([512 - 150, 392, 512 + 150, 392], fill=GOLD + (180,), width=1)
    d.text((512 - tw / 2, 406), TAGLINE, font=ft, fill=IVORY)
    return finalize(img)


# ---------- 構図 C: アストロカートグラフィ地図 ----------
def concept_C():
    img = bg_gradient((10, 16, 32), (3, 6, 16)).convert("RGBA")
    img.alpha_composite(astro_graticule(1.0))
    starfield(img, seed=33, n=220)
    img.alpha_composite(glow_layer((232, 250), 200, GOLD, 70))
    img.alpha_composite(glow_layer((232, 250), 150, GOLD_HI, 70))
    em = emblem_medallion(286)
    img.alpha_composite(em, (232 - 143, 250 - 143))
    d = ImageDraw.Draw(img)
    tx = 452
    fk = font(CINZEL, 23, 600)
    draw_kicker(d, tx + 4, 158, "RELOCATION", "ASTROLOGY", fk, GOLD + (235,), 4, gap=18)
    wm = gradient_text(WORDMARK, font(CINZEL, 100, 680), 10, GOLD_HI, GOLD_LO)
    img.alpha_composite(wm, (tx - 8, 184))
    d.line([tx + 6, 306, tx + 360, 306], fill=GOLD + (200,), width=2)
    ft = font(NOTO_SERIF, 30, 600)
    d.text((tx + 6, 328), TAGLINE, font=ft, fill=IVORY)
    return finalize(img)


def main():
    outs = [
        ("feature_graphic_A_emblem-left.png", concept_A()),
        ("feature_graphic_B_centered.png", concept_B()),
        ("feature_graphic_C_astromap.png", concept_C()),
    ]
    for name, im in outs:
        p = os.path.join(OUTDIR, name)
        im.save(p, "PNG")
        print("wrote", p, im.size, im.mode, f"{os.path.getsize(p)//1024}KB")


if __name__ == "__main__":
    main()
