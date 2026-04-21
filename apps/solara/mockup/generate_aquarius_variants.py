"""
Generate zodiac color/element variants based on the aquarius lightning/cascade shape.
- Keep aquarius' vertical cascading energy pattern composition
- Change only color palette and elemental attribute per sign

Usage:
  python generate_aquarius_variants.py              # all 11
  python generate_aquarius_variants.py aries        # single
  python generate_aquarius_variants.py aries,taurus,gemini,cancer  # multiple
  python generate_aquarius_variants.py list         # show prompts
"""
import os
import sys
import time
import io
from pathlib import Path

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

VARIANTS = {
    "aries": (
        "Crimson and orange fire lightning nebula with explosive energy patterns, "
        "streams of flame cascading through space, blazing red and amber glow, "
        "aggressive volcanic atmosphere, dynamic vertical flow composition. "
        + SOLARA_STYLE
    ),
    "taurus": (
        "Deep emerald and copper earth lightning nebula with mineral energy patterns, "
        "streams of golden dust cascading through space, jade and bronze metallic glow, "
        "grounded powerful atmosphere, dynamic vertical flow composition. "
        + SOLARA_STYLE
    ),
    "gemini": (
        "Silver and sapphire twin lightning nebula with dual mirrored energy patterns, "
        "paired streams cascading through space, mercury and electric blue glow, "
        "airy communicative atmosphere, dynamic vertical flow composition. "
        + SOLARA_STYLE
    ),
    "cancer": (
        "Pearlescent silver-blue aquatic lightning nebula with fluid energy patterns, "
        "streams of shimmering water cascading through space, "
        "iridescent pearl white and deep ocean blue glow, "
        "nurturing gentle atmosphere, dynamic vertical flow composition. "
        + SOLARA_STYLE
    ),
    "leo": (
        "Radiant gold and amber solar lightning nebula with regal energy patterns, "
        "streams of fire cascading through space like sun flares, "
        "royal gold and deep purple glow, "
        "commanding theatrical atmosphere, dynamic vertical flow composition. "
        + SOLARA_STYLE
    ),
    "virgo": (
        "Sage green and wheat gold crystal lightning nebula with precise geometric energy patterns, "
        "streams of sacred geometry cascading through space, "
        "warm silver and muted sage glow, "
        "analytical refined atmosphere, dynamic vertical flow composition. "
        + SOLARA_STYLE
    ),
    "libra": (
        "Rose pink and lavender harmony lightning nebula with balanced symmetrical energy patterns, "
        "streams of harmonious light cascading through space, "
        "pastel rose and amethyst purple glow, "
        "elegant romantic atmosphere, dynamic vertical flow composition. "
        + SOLARA_STYLE
    ),
    "scorpio": (
        "Deep crimson and dark purple abyssal lightning nebula with transformative energy patterns, "
        "streams of dark matter cascading through space, "
        "obsidian black with burgundy and violet glow, "
        "mysterious intense atmosphere, dynamic vertical flow composition. "
        + SOLARA_STYLE
    ),
    "sagittarius": (
        "Indigo and fiery orange cosmic lightning nebula with adventurous energy patterns, "
        "streams of light beams cascading through space across distant galaxies, "
        "deep blue with orange cosmic trails glow, "
        "expansive philosophical atmosphere, dynamic vertical flow composition. "
        + SOLARA_STYLE
    ),
    "capricorn": (
        "Slate grey and icy blue iron lightning nebula with structured energy patterns, "
        "streams of granite dust cascading through space, "
        "dark stone with subtle gold highlights glow, "
        "ambitious enduring atmosphere, dynamic vertical flow composition. "
        + SOLARA_STYLE
    ),
    "pisces": (
        "Teal and sea-green ocean lightning nebula with fluid dreamy energy patterns, "
        "streams of transcendent currents cascading through space, "
        "deep Neptune blue with bioluminescent accents glow, "
        "mystical dreamlike atmosphere, dynamic vertical flow composition. "
        + SOLARA_STYLE
    ),
}

OUT_DIR = Path(__file__).parent / "share-assets" / "backgrounds_aquarius_variants"
OUT_DIR.mkdir(parents=True, exist_ok=True)


def generate_one(sign, prompt):
    out_path = OUT_DIR / f"aquarius_{sign}.png"
    if out_path.exists():
        print(f"  SKIP: aquarius_{sign}.png (exists)")
        return True

    print(f"  Generating: aquarius_{sign} ...")
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
                img = Image.open(io.BytesIO(part.inline_data.data))
                img.save(str(out_path), "PNG")
                size_kb = out_path.stat().st_size // 1024
                print(f"  OK: aquarius_{sign}.png ({img.width}x{img.height}, {size_kb}KB)")
                return True

        print(f"  WARN: No image returned for {sign}")
        return False

    except Exception as e:
        print(f"  ERROR: {e}")
        return False


def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else "all"

    if arg == "list":
        for sign, prompt in VARIANTS.items():
            print(f"\n[aquarius_{sign}]")
            print(f"  {prompt[:120]}...")
        return

    if arg == "all":
        targets = list(VARIANTS.items())
    elif "," in arg:
        names = [s.strip() for s in arg.split(",")]
        targets = [(n, VARIANTS[n]) for n in names if n in VARIANTS]
    elif arg in VARIANTS:
        targets = [(arg, VARIANTS[arg])]
    else:
        print(f"Unknown sign: {arg}")
        print(f"Valid: {', '.join(VARIANTS.keys())}")
        return

    print(f"\n=== Generating {len(targets)} aquarius variants ===")
    print(f"Output: {OUT_DIR}\n")

    ok = 0
    for sign, prompt in targets:
        if generate_one(sign, prompt):
            ok += 1
        time.sleep(2)

    print(f"\n=== Done: {ok}/{len(targets)} succeeded ===")


if __name__ == "__main__":
    main()
