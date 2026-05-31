"""
Generate the "Stella に相談" (consult Stella) map button icon — 3 candidate motifs.

Same antique woodblock style as generate_menu_icons_v2.py (BASE_STYLE reused
verbatim) so the new icon sits naturally beside love/money/work/healing/etc.
Accent wash is a muted amethyst violet — distinct from every existing icon
(love=rose, money=amber, work=slate, healing=silver-blue, comm=verdigris,
fortune=copper, location=sepia, forecast=ivory) and on-theme for Stella/Solara.

3 candidates (owner picks one → copy to consult.webp):
  consult_a  導きの星 + アストロラーベ環   (guiding pole-star + astrolabe arc)
  consult_b  三日月に抱かれた星             (crescent cradling a bright star)
  consult_c  水晶玉に星座                   (crystal orb with a constellation)

Usage:
  python generate_consult_icons.py            # generate all 3 PNG + convert to webp
  python generate_consult_icons.py a          # single (test): a | b | c
  python generate_consult_icons.py convert     # only (re)convert existing PNG -> webp
  python generate_consult_icons.py list        # print prompts

Output:
  PNG  -> mockup/share-assets/menu-icons/v2/consult_{a,b,c}.png   (original, protected)
  WEBP -> assets/menu_icons/consult_{a,b,c}.webp                   (preview, 256, alpha)
"""
import os
import sys
import time
import io
from pathlib import Path


# ── Load .env by walking up (works in main checkout and worktree alike) ──
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


# ── BASE_STYLE: copied verbatim from generate_menu_icons_v2.py ──
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
    return (
        f"Apply a soft desaturated {color_desc} watercolor wash and hand-tinted "
        f"highlights directly on the central symbol's decorative parts. "
        f"The accent color is gently visible (saturation around 35%) but never "
        f"bright, never neon, never vivid. The outer dotted ring stays pure gold. "
    )


_AMETHYST = "muted aged amethyst violet (#B0A0D0)"

ICONS = {
    # 導きの星 + アストロラーベ環
    "consult_a": (
        "A single large radiant guiding star (a prominent eight-pointed pole star) "
        "at exact center occupying ~70% of the canvas: four long slender primary rays "
        "(up/down/left/right) alternating with four shorter diagonal rays, drawn with "
        "thick bold gold strokes, emanating fine hairline light lines. "
        "Encircling the star, set just inside the outer dotted ring: a delicate "
        "astrolabe arc — a single thin graduated quarter-arc with small even tick "
        "graduations, like an antique navigational instrument. "
        "Three or four tiny five-pointed stars scattered in the surrounding black space. "
        "Evoking seeking quiet guidance from the stars, an oracle's counsel. "
        "NO human figure, NO face, NO eye, NO planetary glyphs, NO zodiac symbols. "
        + accent(_AMETHYST)
        + "The astrolabe arc and small scattered stars carry the amethyst tint; "
        "the central guiding star and the outer dotted ring stay gold."
    ),
    # 三日月に抱かれた星
    "consult_b": (
        "A large crescent moon at exact center, opening upward like a cradle, "
        "occupying ~70% of the canvas, drawn with a thick bold gold outline. "
        "Nestled within the curve of the crescent: a single bright radiant "
        "five-pointed star, emitting soft gentle hairline light rays upward. "
        "Calm, protective, oracle-guidance atmosphere — as if the night sky is "
        "offering counsel. "
        "NO leaves, NO water droplets, NO wheat, NO human figure, NO face, "
        "NO planetary glyphs, NO zodiac symbols. "
        + accent(_AMETHYST)
        + "The crescent carries the amethyst tint; the cradled star and the outer "
        "dotted ring stay gold."
    ),
    # 水晶玉に星座
    "consult_c": (
        "A large crystal orb (a perfect sphere) at exact center occupying ~65% of "
        "the canvas, resting on a small ornate three-legged stand, drawn with thick "
        "bold gold outline and a couple of curved highlight lines to read as glass. "
        "Inside the sphere: a delicate constellation — five or six small dots joined "
        "by thin straight lines forming a simple star pattern, gently glowing. "
        "Mystic oracle consultation atmosphere. "
        "NO human figure, NO face, NO eye, NO hands, NO planetary glyphs, "
        "NO zodiac symbols, NO smoke. "
        + accent(_AMETHYST)
        + "The constellation inside and the stand carry the amethyst tint; the orb "
        "outline and the outer dotted ring stay gold."
    ),
}

V2_DIR = Path(__file__).parent / "share-assets" / "menu-icons" / "v2"
V2_DIR.mkdir(parents=True, exist_ok=True)
ASSET_DIR = Path(__file__).resolve().parents[1] / "assets" / "menu_icons"

# ── circular alpha mask params (copied from convert_menu_icons_to_webp.py) ──
TARGET_SIZE = 256
QUALITY = 90
MASK_RADIUS_RATIO = 0.495
FEATHER_PIXELS = 4


def make_circular_mask(size):
    from PIL import Image, ImageDraw, ImageFilter

    upsample = 4
    big = size * upsample
    mask = Image.new("L", (big, big), 0)
    draw = ImageDraw.Draw(mask)
    cx = cy = big / 2
    r = big * MASK_RADIUS_RATIO
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
    mask = mask.resize((size, size), Image.LANCZOS)
    mask = mask.filter(ImageFilter.GaussianBlur(radius=FEATHER_PIXELS))
    return mask


def generate_one(name, body_prompt):
    out_path = V2_DIR / f"{name}.png"
    if out_path.exists():
        print(f"  SKIP: {name}.png (exists - delete to regenerate)")
        return True

    full_prompt = f"{body_prompt} {BASE_STYLE}"
    print(f"  Generating: {name} ...")
    try:
        from google import genai
        from google.genai import types
        from PIL import Image

        api_key = os.environ.get("GEMINI_API_KEY")
        if not api_key:
            print("  ERROR: GEMINI_API_KEY not set in .env")
            return False

        client = genai.Client(api_key=api_key)
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
                img = Image.open(io.BytesIO(part.inline_data.data))
                img.save(str(out_path), "PNG")
                size_kb = out_path.stat().st_size // 1024
                print(f"  OK: {name}.png ({img.width}x{img.height}, {size_kb}KB)")
                return True
        print(f"  WARN: No image returned for {name}")
        return False
    except Exception as e:
        print(f"  ERROR: {e}")
        return False


def convert_one(name, mask):
    from PIL import Image

    src = V2_DIR / f"{name}.png"
    dst = ASSET_DIR / f"{name}.webp"
    if not src.exists():
        print(f"  MISS png: {name}.png")
        return False
    ASSET_DIR.mkdir(parents=True, exist_ok=True)
    img = Image.open(src).convert("RGB").resize((TARGET_SIZE, TARGET_SIZE), Image.LANCZOS)
    img = img.convert("RGBA")
    img.putalpha(mask)
    img.save(str(dst), "WEBP", quality=QUALITY, method=6)
    print(f"  OK: {name}.png -> {dst.name} ({dst.stat().st_size // 1024}KB, alpha)")
    return True


def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else "all"

    if arg == "list":
        for name, body in ICONS.items():
            print(f"\n[{name}]\n  {body[:200]}...")
        return

    names = {"a": "consult_a", "b": "consult_b", "c": "consult_c"}
    if arg in names:
        targets = [names[arg]]
        do_gen = True
    elif arg == "convert":
        targets = list(ICONS.keys())
        do_gen = False
    elif arg == "all":
        targets = list(ICONS.keys())
        do_gen = True
    else:
        print(f"Unknown arg: {arg}  (valid: all | a | b | c | convert | list)")
        return

    if do_gen:
        print(f"\n=== Generating {len(targets)} consult icon candidate(s) ===")
        for name in targets:
            generate_one(name, ICONS[name])
            time.sleep(2)

    print("\n=== Converting to WebP (256, circular alpha) ===")
    mask = make_circular_mask(TARGET_SIZE)
    for name in targets:
        convert_one(name, mask)

    print("\n=== Done ===")
    print(f"PNG : {V2_DIR}")
    print(f"WEBP: {ASSET_DIR} (consult_a/b/c.webp)")


if __name__ == "__main__":
    main()
