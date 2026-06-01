# -*- coding: utf-8 -*-
"""
Solara アプリアイコン生成スクリプト。
入力: mockup/share-assets/menu-icons/v2/unsealed.png (1024x1024, 黒背景の8芒星紋章)
出力:
  - assets/app_icon.png            … 紋章フル。iOS 全サイズ + Android レガシー(image_path)用
  - assets/app_icon_foreground.png … 紋章を縮小して透明キャンバス中央配置。Android アダプティブ前景用
                                     (金リング外縁を約66% = 円マスク径72dp相当に合わせ、丸マスクで切れない最大サイズ)
flutter_launcher_icons が後段で全解像度へ展開する。
"""
import os
from PIL import Image, ImageChops

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)  # apps/solara
SRC = os.path.join(ROOT, "mockup", "share-assets", "menu-icons", "v2", "unsealed.png")
OUT_FULL = os.path.join(ROOT, "assets", "app_icon.png")
OUT_FG = os.path.join(ROOT, "assets", "app_icon_foreground.png")

CANVAS = 1024
# アダプティブ前景: 紋章外縁の直径をキャンバスの何割にするか。
# 円マスク(viewport)は 72/108 = 0.6667。アンチエイリアス分の安全マージンを少し残して 0.66。
FG_RATIO = 0.66

im = Image.open(SRC).convert("RGB")
w, h = im.size
assert (w, h) == (CANVAS, CANVAS), f"想定外サイズ: {im.size}"

# --- app_icon.png: 紋章フルをそのまま (黒背景・不透明) ---
im.save(OUT_FULL, "PNG")
print("wrote", OUT_FULL, im.size, im.mode)

# --- app_icon_foreground.png: 黒背景との差分で紋章本体の bbox を取り、タイトに切って縮小 ---
corner = im.getpixel((0, 0))
bg = Image.new("RGB", im.size, corner)
diff = ImageChops.difference(im, bg).convert("L")
mask = diff.point(lambda p: 255 if p > 18 else 0)
bbox = mask.getbbox()
print("content bbox:", bbox)

emblem = im.crop(bbox)
ew, eh = emblem.size
side = max(ew, eh)
# 正方キャンバスに紋章を中央寄せ(余白は黒=元背景と同色)してから縮小、最後に透明キャンバスへ。
sq = Image.new("RGB", (side, side), corner)
sq.paste(emblem, ((side - ew) // 2, (side - eh) // 2))

target = int(round(CANVAS * FG_RATIO))
sq_resized = sq.resize((target, target), Image.LANCZOS)

# 透明キャンバス。アダプティブ背景色を #000000 にするので、紋章外の角は透明 → 黒背景が透けて継ぎ目なし。
fg = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
off = (CANVAS - target) // 2
fg.paste(sq_resized.convert("RGBA"), (off, off))
fg.save(OUT_FG, "PNG")
print("wrote", OUT_FG, fg.size, "emblem px:", target, f"({FG_RATIO:.0%})")

# --- ストア掲載用アイコン (docs/store_compliance_assets/icons/) ---
# ランチャーアイコン (上記) とは別物。各ストアの掲載仕様に厳密に合わせる。
STORE_DIR = os.path.join(ROOT, "docs", "store_compliance_assets", "icons")
os.makedirs(STORE_DIR, exist_ok=True)

# Google Play Console: 512×512 フルブリード正方形 PNG (32-bit / 不透明)。角丸・効果なし。
# Google 側が表示時に角丸マスクをかけるので、こちらは正方形のまま渡す。max 1MB。
gp = im.resize((512, 512), Image.LANCZOS).convert("RGBA")  # 32-bit (alpha は全 255 = 不透明)
GP_PATH = os.path.join(STORE_DIR, "google_play_icon_512.png")
gp.save(GP_PATH, "PNG")
print("wrote", GP_PATH, gp.size, gp.mode)

# Apple App Store Connect: 1024×1024 PNG、**透過なし (no alpha) / 角丸なし / フラット**。
# 透過があると審査で弾かれるため必ず RGB で書き出す。原画が既に 1024 RGB。
ap = im.convert("RGB")
AP_PATH = os.path.join(STORE_DIR, "apple_app_store_icon_1024.png")
ap.save(AP_PATH, "PNG")
print("wrote", AP_PATH, ap.size, ap.mode)
