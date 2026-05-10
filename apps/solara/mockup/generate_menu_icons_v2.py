"""
Generate Solara map menu icons V2 (simple woodblock style).

V2 changes from V1:
- Central motif occupies 80-85% (V1 was 70%) for better readability at 32px
- Thick clear lines (woodblock print style) instead of filigree fine linework
- Outer frame: ONE simple dotted ring (no double rings, no zodiac ticks)
- Astrological planet glyphs (Venus/Jupiter/Saturn/Mercury) removed
  per owner request (one planet doesn't define a category anyway).

11 icons (healing has 2 variants: with/without moon):
  unsealed         — Daily 未開封 (大 9芒星 + 中央封蝋)
  all              — Daily 汎用 (大 8芒星)
  love             — ハート + 薔薇蔓
  money            — 月桂樹の冠 + 中央コイン (惑星 ♃ なし)
  work             — masonic コンパス & 定規 (惑星 ♄ なし)
  healing_moon     — 三日月 + 葉 + 水滴 (月あり版)
  healing_no_moon  — 麦穂 + 葉 + 水滴 (月なし版)
  communication    — 広げた一対の翼 (惑星 ☿ なし)
  fortune          — 8方位コンパスローズ + 中央矢印
  location         — 地図ピン
  forecast         — 12 spoke 円 + 時計針

Usage:
  python generate_menu_icons_v2.py            # all 11
  python generate_menu_icons_v2.py unsealed   # single (test)
  python generate_menu_icons_v2.py list       # show prompts
"""
import os
import sys
import time
import io
from pathlib import Path

# Load .env by walking up from this script (works in main repo and worktree alike)
def _find_env():
    cur = Path(__file__).resolve().parent
    for _ in range(10):
        candidate = cur / ".env"
        if candidate.exists():
            return candidate
        if cur.parent == cur:
            break
        cur = cur.parent
    return None

env_path = _find_env()
if env_path is not None:
    for line in env_path.read_text(encoding="utf-8").splitlines():
        if "=" in line and not line.startswith("#"):
            key, val = line.split("=", 1)
            os.environ.setdefault(key.strip(), val.strip())

# V2 base style — simple woodblock, large central motif
BASE_STYLE = (
    "Bold simple antique mystical icon. "
    "Warm gold (#C9A84C) engraving on pure solid black background (#000000). "
    "The central symbol occupies about 80-85% of the canvas - LARGE and easily "
    "readable even at small sizes. Thick, clear lines like a 19th-century "
    "woodblock print, NOT delicate filigree. "
    "Outer frame is just ONE simple thin dotted circular ring near the canvas edge "
    "(NO double rings, NO 12 zodiac tick marks, NO filigree swirls). "
    "Generous black whitespace between the central symbol and the outer dotted ring. "
    "ABSOLUTELY NO text, NO letters, NO numbers, NO rectangular border, "
    "NO watermark, NO modern UI elements. "
    "Square 1:1 composition, central symbol perfectly centered. "
    "Engraving aesthetic, but heavily simplified — emphasize boldness and clarity."
)


def accent(color_desc):
    """Apply muted accent watercolor wash directly on the central symbol."""
    return (
        f"Apply a soft desaturated {color_desc} watercolor wash and hand-tinted "
        f"highlights directly on the central symbol's decorative parts. "
        f"The accent color is gently visible (saturation around 35%) but never "
        f"bright, never neon, never vivid. The outer dotted ring stays pure gold. "
    )


ICONS = {
    "unsealed": (
        "A large nine-pointed star (enneagram) at exact center occupying ~80% of the canvas: "
        "nine equal pointed rays radiating outward in perfect 9-fold rotational symmetry, "
        "with thick bold gold strokes. "
        "A small wax-seal-like circular medallion at the very center of the star. "
        "Sealed, closed, mysterious atmosphere — as if hiding a secret message. "
        + accent("aged silver moonlight with a hint of pale violet (#B8B0C8)")
    ),

    "all": (
        "A large eight-pointed star (octogram) at exact center occupying ~80% of the canvas: "
        "four large pointed rays alternating with four smaller rays, drawn with thick bold gold strokes. "
        "A small dot at the very center. Balanced, harmonious, universal atmosphere. "
        "Pure warm gold throughout, no other color tints, monochromatic gold-on-black engraving. "
    ),

    "love": (
        "A large bold heart shape at exact center occupying ~70% of the canvas, "
        "drawn as a thick gold outline (NOT filled). "
        "On the left and right sides of the heart, a single rose vine on each side curves up and around it, "
        "with one or two small rose buds visible. NO Venus glyph, NO astrological symbols. "
        + accent("dusty muted antique rose pink (#C99A9A)")
        + "The rose vines and buds carry the rose tint; the heart and dotted ring stay gold."
    ),

    "money": (
        "A large laurel wreath (circular crown of laurel leaves) at exact center occupying ~80% of the canvas, "
        "with thick bold gold leaves. The wreath opens slightly at the top with a small ribbon detail. "
        "At the very center inside the wreath: a single small five-pointed star "
        "(NOT a coin, NOT a Jupiter glyph). "
        "NO astrological symbols, NO planetary glyphs. "
        + accent("muted aged amber honey (#B8985A)")
        + "The laurel leaves carry the amber tint; the central star and dotted ring stay gold."
    ),

    "work": (
        "A large majestic oak tree at exact center occupying ~80% of the canvas, "
        "drawn with thick bold gold strokes. The tree has wide spreading branches "
        "at the top with detailed foliage and a few visible acorns, a strong trunk, "
        "and visible roots spreading symmetrically at the bottom — "
        "Tree of Life style with branches and roots in balanced proportion. "
        "NO masonic compass, NO carpenter's square, NO Freemason emblem, "
        "NO letters of any kind (especially NO 'G'), "
        "NO astrological symbols, NO planetary glyphs, "
        "NO numbers, NO text inside or around the tree. "
        "The tree symbolizes growth, social presence, and accumulated effort - "
        "applicable to students, workers, and retirees alike. "
        + accent("dusty slate-blue indigo grey (#7B8B9E)")
        + "The foliage and roots carry the slate-blue tint; the trunk and dotted ring stay gold."
    ),

    "healing_moon": (
        "A large crescent moon at exact center occupying ~60% of the canvas, opening to the right side, "
        "drawn with thick bold gold outline. "
        "Below and around the crescent: a single olive branch leaf on the left, "
        "a single sprig of three small water droplets on the right. "
        "Simple, calm, restorative atmosphere. "
        + accent("pale silver-blue moonlight (#A8B8C8)")
        + "The leaf and droplets carry the silver-blue tint; the moon and dotted ring stay gold."
    ),

    "healing_no_moon": (
        "A single large wheat sprig at exact center occupying ~75% of the canvas, "
        "vertical orientation with detailed grain heads at the top, "
        "drawn with thick bold gold outline. "
        "On either side of the wheat: a small olive branch leaf (one each), "
        "and three small water droplets near the base. "
        "NO moon, NO crescent, NO astrological symbols, NO planetary glyphs. "
        "Simple, calm, restorative atmosphere. "
        + accent("pale silver-blue dewdrop (#A8B8C8)")
        + "The leaves and water droplets carry the silver-blue tint; the wheat and dotted ring stay gold."
    ),

    "communication": (
        "A large pair of outspread feathered wings at exact center occupying ~80% of the canvas, "
        "symmetrically spread to the left and right, drawn with thick bold gold outlines "
        "showing individual feather details. "
        "At the center where the wings meet: a small vertical feather quill or thin staff. "
        "NO Mercury glyph, NO serpents, NO astrological symbols. "
        + accent("muted aged copper-verdigris green (#7BA098)")
        + "The feathers carry the verdigris tint; the central quill and dotted ring stay gold."
    ),

    "fortune": (
        "A large compass rose at exact center occupying ~80% of the canvas: "
        "8 prominent radiating triangular points - 4 cardinal directions at the "
        "topmost / rightmost / bottommost / leftmost positions, plus 4 intermediate "
        "diagonal directions. Drawn with thick bold gold strokes. "
        "A small upward-pointing arrow or fleur-de-lis ornament at the topmost position. "
        "ABSOLUTELY NO LETTERS anywhere on the image. "
        "NO compass direction abbreviations, NO labels, NO writing, NO characters, "
        "NO text of any kind. The directional points are visually distinct by their "
        "angular position only - NOT by any letter, symbol, or character. "
        "Simplified cartographic engraving aesthetic. "
        + accent("aged copper bronze (#9A6F4A)")
        + "The compass points carry the copper tint; the central rose lines and dotted ring stay gold."
    ),

    "location": (
        "A large vintage map pin at exact center occupying ~70% of the canvas: "
        "a bold teardrop shape with a sharp point at the bottom, "
        "drawn with thick gold outline. "
        "Inside the pin's upper round portion: a small filled circle (the gem). "
        "NO crosshair, NO map gridlines, NO astrological symbols. "
        "Simple, clear, geographic. "
        + accent("warm sepia parchment ink (#A88E66)")
        + "The pin body carries a subtle sepia tint; the central gem and dotted ring stay gold."
    ),

    "forecast": (
        "A large circle divided into 12 equal pie segments by radiating spoke lines from the center, "
        "occupying ~85% of the canvas, drawn with thick bold gold strokes. "
        "A single prominent clock-hand-like arrow extending from the center upward, "
        "pointing to the 12 o'clock position. "
        "A small filled circle at the very center. "
        "NO zodiac glyphs, NO astrological symbols, NO ornamental marks at the cusps. "
        + accent("yellowed parchment ivory (#BFA070)")
        + "The 12 spokes carry the parchment tint; the clock-hand, central pivot, and dotted ring stay gold."
    ),
}

OUT_DIR = Path(__file__).parent / "share-assets" / "menu-icons" / "v2"
OUT_DIR.mkdir(parents=True, exist_ok=True)


def generate_one(name, body_prompt):
    out_path = OUT_DIR / f"{name}.png"
    if out_path.exists():
        print(f"  SKIP: {name}.png (exists - delete to regenerate)")
        return True

    full_prompt = f"{body_prompt} {BASE_STYLE}"
    print(f"  Generating: {name} ...")

    try:
        from google import genai
        from google.genai import types

        API_KEY = os.environ.get("GEMINI_API_KEY")
        if not API_KEY:
            print("  ERROR: GEMINI_API_KEY not set in .env")
            return False

        client = genai.Client(api_key=API_KEY)
        response = client.models.generate_content(
            model="gemini-3.1-flash-image-preview",
            contents=[full_prompt],
            config=types.GenerateContentConfig(
                response_modalities=["TEXT", "IMAGE"],
                image_config=types.ImageConfig(aspect_ratio="1:1"),
            ),
        )

        for part in response.parts:
            if part.inline_data is not None:
                from PIL import Image

                img_data = part.inline_data.data
                img = Image.open(io.BytesIO(img_data))
                img.save(str(out_path), "PNG")
                size_kb = out_path.stat().st_size // 1024
                print(f"  OK: {name}.png ({img.width}x{img.height}, {size_kb}KB)")
                return True

        print(f"  WARN: No image returned for {name}")
        return False

    except Exception as e:
        print(f"  ERROR: {e}")
        return False


def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else "all"

    if arg == "list":
        for name, body in ICONS.items():
            print(f"\n[{name}]")
            print(f"  {body[:160]}...")
        return

    if arg == "all":
        targets = list(ICONS.items())
    elif arg in ICONS:
        targets = [(arg, ICONS[arg])]
    else:
        print(f"Unknown icon: {arg}")
        print(f"Valid: {', '.join(ICONS.keys())}")
        return

    print(f"\n=== Generating {len(targets)} V2 menu icons ===")
    print(f"Output: {OUT_DIR}\n")

    ok = 0
    for name, body in targets:
        if generate_one(name, body):
            ok += 1
        time.sleep(2)

    print(f"\n=== Done: {ok}/{len(targets)} succeeded ===")


if __name__ == "__main__":
    main()
