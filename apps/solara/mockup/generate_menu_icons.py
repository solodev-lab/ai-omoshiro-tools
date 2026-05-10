"""
Generate Solara map menu icons using Gemini 3.1 Flash Image (Nano Banana 2).

10 icons:
  unsealed       — Daily 未開封 (アンティーク 8芒星)
  all            — Daily 未確定/汎用
  love / money / work / healing / communication — 各カテゴリ
  fortune        — 運勢方位 chip (羅針盤)
  location       — LOCATION chip (地図ピン)
  forecast       — 予報 chip (ホロスコープ円)

Style: warm-gold engraving on black + dusty muted accent watercolor wash
       only on decorative elements (not on structural lines/glyphs).

Usage:
  python generate_menu_icons.py            # all 10
  python generate_menu_icons.py unsealed   # single (test)
  python generate_menu_icons.py list       # show prompts
"""
import os
import sys
import time
import io
from pathlib import Path

# Load .env from repo root (E:/AppCreate/.env)
env_path = Path(__file__).resolve().parents[3] / ".env"
if env_path.exists():
    for line in env_path.read_text(encoding="utf-8").splitlines():
        if "=" in line and not line.startswith("#"):
            key, val = line.split("=", 1)
            os.environ.setdefault(key.strip(), val.strip())

# Common base style — applied to every icon
BASE_STYLE = (
    "Antique mystical talisman emblem icon. "
    "Fine warm-gold engraving (#C9A84C) as the primary linework on pure solid black background (#000000). "
    "Single circular emblem perfectly centered, ornate concentric circular frame "
    "with delicate dotted ring and 12 small zodiacal tick marks (these stay pure gold). "
    "Art nouveau filigree swirls, Renaissance occult grimoire aesthetic, sacred geometry, "
    "museum-quality engraving detail, ethereal mystical glow. "
    "ABSOLUTELY NO text, NO letters, NO numbers, NO rectangular border, "
    "NO watermark, NO signature, NO modern UI elements. "
    "The black background extends fully to all four edges. "
    "Square 1:1 composition, central emblem occupies about 70% of canvas."
)

# Accent washes — desaturated, dusty, low-saturation hand-tinted illumination
def accent(color_desc):
    return (
        f"Apply soft desaturated {color_desc} watercolor washes and hand-tinted highlights "
        f"ONLY on the decorative ornamental elements, keeping all structural lines, "
        f"frames, dotted rings, tick marks, and central glyphs in pure warm gold. "
        f"The accent color appears like aged hand-painted illumination on a medieval grimoire — "
        f"soft, dusty, low-saturation around 30%, never bright, never vivid, never neon. "
    )

ICONS = {
    "unsealed": (
        "An eight-pointed Star of Lakshmi (octogram) at exact center: "
        "four large pointed rays alternating with four smaller rays. "
        "A small wax-seal-like circular medallion at the very center of the star. "
        "Outer double dotted ring, eight tiny spark dots placed between the star rays. "
        "Sealed, closed, mysterious atmosphere — as if hiding a secret message. "
        + accent("aged silver moonlight with a hint of pale violet (#B8B0C8)")
    ),

    # 9芒星バリエーション (オーナー要望、2026-05-10)
    # A: subtle = 既存 unsealed と同じ抑制強度、星だけ 8→9
    "unsealed_9pt_subtle": (
        "A nine-pointed star (enneagram) at exact center: nine equal pointed rays "
        "radiating outward in perfect 9-fold rotational symmetry. "
        "A small wax-seal-like circular medallion at the very center of the star. "
        "Outer double dotted ring, nine tiny spark dots placed between the star rays. "
        "Sealed, closed, mysterious atmosphere — as if hiding a secret message. "
        + accent("aged silver moonlight with a hint of pale violet (#B8B0C8)")
    ),

    # B: vivid = アクセント強め (saturation up、装飾フィリグリーに色がはっきり乗る)
    "unsealed_9pt_vivid": (
        "A nine-pointed star (enneagram) at exact center: nine equal pointed rays "
        "radiating outward in perfect 9-fold rotational symmetry. "
        "A small wax-seal-like circular medallion at the very center of the star. "
        "Outer double dotted ring, nine tiny spark dots placed between the star rays. "
        "Sealed, closed, mysterious atmosphere — as if hiding a secret message. "
        # vivid 用カスタム accent (saturation 50%, 装飾に色がはっきり見える)
        "Apply gently visible desaturated aged silver-violet moonlight watercolor washes "
        "(#B8B0C8) on all decorative ornamental elements — the filigree swirls, "
        "the dotted rings, the spark dots between rays, and the outer frame ornaments. "
        "Keep the structural lines, the central glyph (9-pointed star), and the "
        "central medallion in pure warm gold. "
        "The accent color is clearly perceptible like a hand-tinted aquatint print, "
        "saturation around 50%, soft and dusty but not faint. Never bright, never neon, never vivid. "
    ),

    "all": (
        "A four-pointed compass star (✦) at exact center, elongated diamond shape, "
        "four equal radiating points. "
        "Twelve evenly spaced tick marks on the outer ring, four small dots in the diagonals, "
        "subtle radiating beams of light extending from the central star. "
        "Balanced, harmonious, universal atmosphere. "
        # all stays pure gold (no accent) — represents balance
        "Pure warm gold throughout, no other color tints, monochromatic gold-on-black engraving. "
    ),

    "love": (
        "The astrological Venus glyph at exact center: a circle with a small cross below it, "
        "drawn as elegant engraved lines. "
        "Two intertwining rose vines emerging from below, curving up around the glyph "
        "to form a heart-shaped arc embracing it from the sides. "
        "Tiny rose buds along the vines. "
        + accent("dusty muted antique rose pink (#C99A9A)")
        + "The rose vines and buds carry the rose tint; the Venus glyph and frame stay gold."
    ),

    "money": (
        "The astrological Jupiter glyph at exact center (resembling the numeral 4 with curved top): "
        "drawn as engraved lines. "
        "A circular laurel wreath ring surrounding the glyph just inside the outer frame. "
        "Four diagonal radiating beams of light extending outward from the corners. "
        + accent("muted aged amber honey (#B8985A)")
        + "The laurel leaves and radiating beams carry the amber tint; the Jupiter glyph and frame stay gold."
    ),

    "work": (
        "The astrological Saturn glyph at exact center (cross with curved tail at bottom): "
        "drawn as engraved lines. "
        "A subtle Saturnian planetary ring (ellipse) cutting horizontally through the glyph. "
        "Below the glyph, a small masonic-style geometric base of compass and square symbols. "
        + accent("dusty slate-blue indigo grey (#7B8B9E)")
        + "The planetary ring and the geometric base carry the slate-blue tint; "
        "the Saturn glyph and frame stay gold."
    ),

    "healing": (
        "A crescent moon at exact center, opening to the right side, drawn as engraved lines. "
        "Eight tiny moon phase circles arranged in a circle around the central crescent. "
        "Two delicate wheat sprigs on the left and right sides flanking the moon. "
        + accent("pale silver-blue moonlight (#A8B8C8)")
        + "The moon phases and wheat sprigs carry the silver-blue tint; "
        "the central crescent and frame stay gold."
    ),

    "communication": (
        "The astrological Mercury glyph at exact center: a circle with two small horns above "
        "and a cross below, drawn as engraved lines. "
        "Two outspread feathered wings on the left and right sides. "
        "Two intertwining serpents (caduceus style) flanking the glyph from below. "
        + accent("muted aged copper-verdigris green (#7BA098)")
        + "The wings feathers and serpent scales carry the verdigris tint; "
        "the Mercury glyph and frame stay gold."
    ),

    "fortune": (
        "An ornate 16-point compass rose at exact center: prominent fleur-de-lis at the North point, "
        "smaller decorated cardinal points (E, S, W), 8 minor intermediate points. "
        "A concentric inner ring with tiny stars at each direction (no letters). "
        "Cartographic engraving style, 17th-century atlas aesthetic. "
        + accent("aged copper bronze (#9A6F4A)")
        + "The cardinal direction ornaments carry the copper tint; "
        "the central rose lines and frame stay gold."
    ),

    "location": (
        "A vintage cartographer's location pin at exact center: ornate teardrop shape, "
        "engraved decorative lines on the surface, a small jewel-like circle in the middle of the pin. "
        "Behind the pin: a faint latitude/longitude crosshair extending to the frame, "
        "very faint world-map gridlines suggested. "
        + accent("warm sepia parchment ink (#A88E66)")
        + "The crosshair and gridlines carry the sepia tint; "
        "the pin engraving and frame stay gold."
    ),

    "forecast": (
        "An astrological horoscope wheel at exact center: a circle divided into 12 equal house segments "
        "by radiating spoke lines from the center. "
        "A clock-hand pointing upward from the central pivot. "
        "At each of the 12 house cusps: a tiny abstract decorative mark (NOT actual zodiac glyphs, "
        "just small ornamental dots or stars). "
        "A central pivot dot. "
        + accent("yellowed parchment ivory (#BFA070)")
        + "The 12 spoke lines and house cusp ornaments carry the parchment tint; "
        "the clock-hand, central pivot, and frame stay gold."
    ),
}

OUT_DIR = Path(__file__).parent / "share-assets" / "menu-icons"
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
            print(f"  {body[:140]}...")
        return

    if arg == "all":
        targets = list(ICONS.items())
    elif arg in ICONS:
        targets = [(arg, ICONS[arg])]
    else:
        print(f"Unknown icon: {arg}")
        print(f"Valid: {', '.join(ICONS.keys())}")
        return

    print(f"\n=== Generating {len(targets)} menu icons ===")
    print(f"Output: {OUT_DIR}\n")

    ok = 0
    for name, body in targets:
        if generate_one(name, body):
            ok += 1
        time.sleep(2)

    print(f"\n=== Done: {ok}/{len(targets)} succeeded ===")


if __name__ == "__main__":
    main()
