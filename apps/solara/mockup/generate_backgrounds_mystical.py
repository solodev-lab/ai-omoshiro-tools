"""
Generate 12 mystical zodiac background images using Gemini 2.5 Flash Image.
- NO zodiac symbols/silhouettes (no ram horns, bull, twins, crab, lion mane,
  maiden, scales, scorpion, arrow, goat, water-bearer, fish)
- Keep each sign's color palette and mystical atmosphere
- Vertical 9:16 composition for share graphics
- Output to share-assets/backgrounds_mystical/ (backgrounds_original untouched)

Usage:
  python generate_backgrounds_mystical.py           # all 12
  python generate_backgrounds_mystical.py aries     # single
  python generate_backgrounds_mystical.py list      # show prompts
"""
import os
import sys
import time
import io
from pathlib import Path

# Load .env from repo root
env_path = Path(__file__).resolve().parents[3] / ".env"
if env_path.exists():
    for line in env_path.read_text(encoding="utf-8").splitlines():
        if "=" in line and not line.startswith("#"):
            key, val = line.split("=", 1)
            os.environ.setdefault(key.strip(), val.strip())

SOLARA_STYLE = (
    "Vertical 9:16 portrait orientation composition, tall vertical cosmic scene. "
    "Dark cosmic mystical atmosphere, deep space background, "
    "subtle starfield, ethereal glow, abstract nebula forms only. "
    "Absolutely NO zodiac symbols, NO animal shapes, NO human figures, NO silhouettes. "
    "No text, no letters, no numbers, no watermark, no signature, no border, no frame. "
    "Painterly digital art, premium quality, cinematic lighting."
)

SIGN_BACKGROUNDS = {
    "aries": (
        "Blazing crimson and orange fire nebula, swirling plasma streams radiating outward, "
        "explosive cosmic energy, volcanic red and amber glow, dynamic spiraling composition. "
        + SOLARA_STYLE
    ),
    "taurus": (
        "Ancient emerald and deep green nebula with warm copper dust, "
        "crystalline mineral formations floating in space, grounded mystical atmosphere, "
        "jade and bronze metallic shimmer. "
        + SOLARA_STYLE
    ),
    "gemini": (
        "Two parallel streams of silver stardust and electric blue light dancing in deep space, "
        "mirrored cosmic waves, mercury-silver and sapphire palette, "
        "airy ethereal motion, abstract dual energy flow. "
        + SOLARA_STYLE
    ),
    "cancer": (
        "Luminous pearlescent silver-blue nebula reflecting moonlight, "
        "gentle cosmic ripples like water surface, iridescent pearl white and deep ocean blue mist, "
        "soft nurturing glow. "
        + SOLARA_STYLE
    ),
    "leo": (
        "Radiant golden solar corona in deep space, majestic sunburst rays spreading outward, "
        "royal amber and brilliant gold light, purple cosmic background, "
        "regal luminous atmosphere. "
        + SOLARA_STYLE
    ),
    "virgo": (
        "Pristine crystal nebula with precise geometric star patterns, "
        "delicate wheat-gold and forest green cosmic dust, sacred geometry lines, "
        "muted sage and warm silver tones, analytical beauty. "
        + SOLARA_STYLE
    ),
    "libra": (
        "Perfectly symmetrical twin nebulae mirroring each other, "
        "rose pink and lavender harmonious gradient, elegant balanced composition, "
        "soft romantic Venus glow, pastel cosmic dust. "
        + SOLARA_STYLE
    ),
    "scorpio": (
        "Deep abyssal nebula in crimson and dark purple, swirling dark matter streams, "
        "obsidian black with burgundy and violet undertones, "
        "mysterious transformative energy, hidden power atmosphere. "
        + SOLARA_STYLE
    ),
    "sagittarius": (
        "Streaking beams of light shooting across vast indigo cosmos, "
        "distant galaxies and star clusters, deep blue and fiery orange cosmic trails, "
        "expansive adventurous composition, philosophical wanderlust. "
        + SOLARA_STYLE
    ),
    "capricorn": (
        "Dark granite and iron nebula with piercing starlight, "
        "ancient cosmic stone formations, slate grey and icy blue with subtle gold highlights, "
        "Saturn-inspired authority, enduring ambitious atmosphere. "
        + SOLARA_STYLE
    ),
    "aquarius": (
        "Electric blue lightning nebula with futuristic energy patterns, "
        "streams of starlight cascading through space, "
        "neon cyan and electric blue with ultraviolet accents, "
        "innovative revolutionary atmosphere. "
        + SOLARA_STYLE
    ),
    "pisces": (
        "Dreamy ocean nebula with soft teal and mystical sea-green cosmic currents, "
        "fluid ethereal waves, deep Neptune blue with bioluminescent accents, "
        "transcendent flowing beauty, mystical dreamlike atmosphere. "
        + SOLARA_STYLE
    ),
}

OUT_DIR = Path(__file__).parent / "share-assets" / "backgrounds_mystical"
OUT_DIR.mkdir(parents=True, exist_ok=True)


def generate_one(sign, prompt):
    out_path = OUT_DIR / f"{sign}.png"
    if out_path.exists():
        print(f"  SKIP: {sign}.png (exists)")
        return True

    print(f"  Generating: {sign} ...")
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
            contents=[prompt],
            config=types.GenerateContentConfig(
                response_modalities=["TEXT", "IMAGE"],
                image_config=types.ImageConfig(aspect_ratio="9:16"),
            ),
        )
        for part in response.parts:
            if part.inline_data is not None:
                from PIL import Image

                img_data = part.inline_data.data
                img = Image.open(io.BytesIO(img_data))
                img.save(str(out_path), "PNG")
                size_kb = out_path.stat().st_size // 1024
                print(f"  OK: {sign}.png ({img.width}x{img.height}, {size_kb}KB)")
                return True

        print(f"  WARN: No image returned for {sign}")
        return False

    except Exception as e:
        print(f"  ERROR: {e}")
        return False


def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else "all"

    if arg == "list":
        for sign, prompt in SIGN_BACKGROUNDS.items():
            print(f"\n[{sign}]")
            print(f"  {prompt[:120]}...")
        return

    if arg == "all":
        targets = list(SIGN_BACKGROUNDS.items())
    elif arg in SIGN_BACKGROUNDS:
        targets = [(arg, SIGN_BACKGROUNDS[arg])]
    else:
        print(f"Unknown sign: {arg}")
        print(f"Valid: {', '.join(SIGN_BACKGROUNDS.keys())}")
        return

    print(f"\n=== Generating {len(targets)} mystical backgrounds ===")
    print(f"Output: {OUT_DIR}\n")

    ok = 0
    for sign, prompt in targets:
        if generate_one(sign, prompt):
            ok += 1
        time.sleep(2)

    print(f"\n=== Done: {ok}/{len(targets)} succeeded ===")


if __name__ == "__main__":
    main()
