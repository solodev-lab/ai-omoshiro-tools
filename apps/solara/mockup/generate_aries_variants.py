"""
Generate zodiac color/element variants based on the aries nebula shape.
- Keep aries' swirling spiral composition
- Change only color palette and elemental attribute per sign

Usage:
  python generate_aries_variants.py              # all 11
  python generate_aries_variants.py taurus       # single
  python generate_aries_variants.py taurus,gemini,cancer,leo  # multiple
  python generate_aries_variants.py list         # show prompts
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
    "taurus": (
        "Deep emerald and copper earth nebula, swirling mineral dust streams radiating outward, "
        "grounded cosmic energy, jade and bronze metallic glow, "
        "dynamic spiraling composition. "
        + SOLARA_STYLE
    ),
    "gemini": (
        "Silver and electric blue air nebula, swirling dual wind streams radiating outward in mirrored pairs, "
        "communicative cosmic energy, mercury and sapphire glow, "
        "dynamic spiraling composition. "
        + SOLARA_STYLE
    ),
    "cancer": (
        "Pearlescent silver-blue aquatic nebula, swirling fluid currents radiating outward, "
        "nurturing cosmic energy, iridescent pearl white and deep ocean blue glow, "
        "dynamic spiraling composition. "
        + SOLARA_STYLE
    ),
    "leo": (
        "Radiant gold and amber solar nebula, swirling flame streams radiating outward like a sun corona, "
        "regal cosmic energy, royal gold and deep purple glow, "
        "dynamic spiraling composition. "
        + SOLARA_STYLE
    ),
    "virgo": (
        "Sage green and wheat gold crystal nebula, swirling geometric star patterns radiating outward "
        "with sacred geometry lines, analytical cosmic energy, warm silver and muted sage glow, "
        "dynamic spiraling composition. "
        + SOLARA_STYLE
    ),
    "libra": (
        "Rose pink and lavender harmony nebula, swirling balanced streams radiating outward in perfect symmetry, "
        "elegant cosmic energy, pastel rose and amethyst purple glow, "
        "dynamic spiraling composition. "
        + SOLARA_STYLE
    ),
    "scorpio": (
        "Deep crimson and dark purple abyssal nebula, swirling dark matter streams radiating outward, "
        "mysterious transformative cosmic energy, obsidian black with burgundy and violet glow, "
        "dynamic spiraling composition. "
        + SOLARA_STYLE
    ),
    "sagittarius": (
        "Indigo and fiery orange cosmos nebula, swirling light beam streams radiating outward across distant galaxies, "
        "adventurous cosmic energy, deep blue with orange cosmic trails glow, "
        "dynamic spiraling composition. "
        + SOLARA_STYLE
    ),
    "capricorn": (
        "Slate grey and icy blue iron nebula, swirling granite dust streams radiating outward, "
        "ambitious enduring cosmic energy, dark stone with subtle gold highlights glow, "
        "dynamic spiraling composition. "
        + SOLARA_STYLE
    ),
    "aquarius": (
        "Neon cyan and electric blue lightning nebula, swirling futuristic energy streams radiating outward, "
        "innovative revolutionary cosmic energy, ultraviolet accents glow, "
        "dynamic spiraling composition. "
        + SOLARA_STYLE
    ),
    "pisces": (
        "Teal and sea-green ocean nebula, swirling fluid currents radiating outward, "
        "dreamy transcendent cosmic energy, deep Neptune blue with bioluminescent accents glow, "
        "dynamic spiraling composition. "
        + SOLARA_STYLE
    ),
}

OUT_DIR = Path(__file__).parent / "share-assets" / "backgrounds_aries_variants"
OUT_DIR.mkdir(parents=True, exist_ok=True)


def generate_one(sign, prompt):
    out_path = OUT_DIR / f"aries_{sign}.png"
    if out_path.exists():
        print(f"  SKIP: aries_{sign}.png (exists)")
        return True

    print(f"  Generating: aries_{sign} ...")
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
                print(f"  OK: aries_{sign}.png ({img.width}x{img.height}, {size_kb}KB)")
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
            print(f"\n[aries_{sign}]")
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

    print(f"\n=== Generating {len(targets)} aries variants ===")
    print(f"Output: {OUT_DIR}\n")

    ok = 0
    for sign, prompt in targets:
        if generate_one(sign, prompt):
            ok += 1
        time.sleep(2)

    print(f"\n=== Done: {ok}/{len(targets)} succeeded ===")


if __name__ == "__main__":
    main()
