"""
Draw Roman numerals I–XII directly onto altar.png so they sit BETWEEN
the candles (so the 1 lands between the 9-o'clock and 8-o'clock candles,
then every 30° counter-clockwise from there).

Backs up the existing altar.png via backup_util first.

Usage:
  python draw_house_numerals_on_altar.py
"""
from pathlib import Path
import math

from PIL import Image, ImageDraw, ImageFont

from backup_util import backup_if_exists

ALTAR_PATH = (
    Path(__file__).parent / "share-assets" / "tarot_scene" / "altar.png"
)

# Image-relative wheel geometry — MUST match the values in
# tarot_altar_scene.dart (_altarCenterYInImg / _altarRingRxInImg / _altarRingRyInImg)
CENTER_X_RATIO = 0.50
CENTER_Y_RATIO = 0.56
RX_RATIO = 0.45
RY_RATIO = 0.22

# Numerals sit on the rim (same ellipse as the candles).
TEXT_RX_FACTOR = 1.00
TEXT_RY_FACTOR = 1.00

# First numeral offset: halfway between 9-o'clock (180°) and 8-o'clock (150°)
# candles → 165°. After that, subtract 30° each step (CCW in house order).
START_ANGLE_DEG = 165.0
STEP_DEG = 30.0

NUMERALS = ['I', 'II', 'III', 'IV', 'V', 'VI',
            'VII', 'VIII', 'IX', 'X', 'XI', 'XII']

FONT_CANDIDATES = [
    "C:/Windows/Fonts/timesbd.ttf",   # Times New Roman Bold
    "C:/Windows/Fonts/times.ttf",     # Times New Roman
    "C:/Windows/Fonts/cambria.ttc",
    "C:/Windows/Fonts/georgia.ttf",
]


def load_font(size):
    for path in FONT_CANDIDATES:
        try:
            return ImageFont.truetype(path, size=size)
        except Exception:
            pass
    return ImageFont.load_default()


def main():
    if not ALTAR_PATH.exists():
        print(f"ERROR: {ALTAR_PATH} not found.")
        return
    backup_if_exists(ALTAR_PATH)

    img = Image.open(ALTAR_PATH).convert("RGBA")
    w, h = img.size
    cx = w * CENTER_X_RATIO
    cy = h * CENTER_Y_RATIO
    rx = w * RX_RATIO * TEXT_RX_FACTOR
    ry = h * RY_RATIO * TEXT_RY_FACTOR

    font_px = max(24, int(w * 0.035))
    font = load_font(font_px)

    overlay = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    gold = (238, 217, 160, 255)
    shadow = (0, 0, 0, 190)

    for i, numeral in enumerate(NUMERALS):
        angle_deg = START_ANGLE_DEG - i * STEP_DEG
        angle_rad = math.radians(angle_deg)
        x = cx + rx * math.cos(angle_rad)
        y = cy + ry * math.sin(angle_rad)

        bbox = draw.textbbox((0, 0), numeral, font=font)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        tx = x - tw / 2 - bbox[0]
        ty = y - th / 2 - bbox[1]

        # Drop shadow (4 direction outline for crisp readability)
        for ox in (-2, -1, 1, 2):
            draw.text((tx + ox, ty), numeral, fill=shadow, font=font)
        for oy in (-2, -1, 1, 2):
            draw.text((tx, ty + oy), numeral, fill=shadow, font=font)

        # Main glyph
        draw.text((tx, ty), numeral, fill=gold, font=font)

    result = Image.alpha_composite(img, overlay)
    result.save(ALTAR_PATH, "PNG")
    size_kb = ALTAR_PATH.stat().st_size // 1024
    print(f"OK: wrote numerals to {ALTAR_PATH.name} ({w}×{h}, {size_kb} KB)")


if __name__ == "__main__":
    main()
