"""
Generate 11 zodiac color/element variants for a given base shape.
Slow-paced execution with auto-retry for 503 errors.

Usage:
  python generate_base_variants.py leo          # all 11 leo variants
  python generate_base_variants.py pisces       # all 11 pisces variants
  python generate_base_variants.py scorpio      # all 11 scorpio variants
  python generate_base_variants.py virgo        # all 11 virgo variants
  python generate_base_variants.py leo aries,taurus  # specific signs
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

# Each base defines a fixed shape/composition description
BASE_SHAPES = {
    "leo": (
        "radiating sunburst composition, majestic rays spreading outward from center "
        "like a solar corona, beams of light extending in all directions across space"
    ),
    "pisces": (
        "flowing wave composition, fluid horizontal currents undulating softly across space, "
        "dreamlike ribbon patterns, gentle oceanic swells"
    ),
    "scorpio": (
        "abyssal vortex composition, swirling streams being pulled inward toward "
        "a deep dark center, intense whirlpool energy, dramatic inward spiral"
    ),
    "virgo": (
        "sacred geometry composition, precise geometric star patterns with crystalline grid lines "
        "forming mathematical order, intricate constellation lattice, refined symmetric structure"
    ),
}

# Each sign defines color palette, element descriptor, and mood
# Format: (element_noun, color_phrase, glow_phrase, mood_phrase)
SIGN_PALETTES = {
    "aries": (
        "fire",
        "crimson and orange",
        "blazing red and amber",
        "aggressive volcanic",
    ),
    "taurus": (
        "earth",
        "deep emerald and copper",
        "jade and bronze metallic",
        "grounded powerful",
    ),
    "gemini": (
        "air",
        "silver and sapphire twin",
        "mercury and electric blue",
        "airy communicative dual",
    ),
    "cancer": (
        "aquatic",
        "pearlescent silver-blue",
        "iridescent pearl white and deep ocean blue",
        "nurturing gentle",
    ),
    "leo": (
        "solar",
        "radiant gold and amber",
        "royal gold and deep purple",
        "commanding theatrical regal",
    ),
    "virgo": (
        "crystal",
        "sage green and wheat gold",
        "warm silver and muted sage",
        "analytical refined",
    ),
    "libra": (
        "harmony",
        "rose pink and lavender",
        "pastel rose and amethyst purple",
        "elegant romantic balanced",
    ),
    "scorpio": (
        "abyssal",
        "deep crimson and dark purple",
        "obsidian black with burgundy and violet",
        "mysterious intense transformative",
    ),
    "sagittarius": (
        "cosmic",
        "indigo and fiery orange",
        "deep blue with orange cosmic trails",
        "expansive adventurous philosophical",
    ),
    "capricorn": (
        "iron",
        "slate grey and icy blue",
        "dark stone with subtle gold highlights",
        "ambitious enduring",
    ),
    "aquarius": (
        "electric",
        "neon cyan and electric blue",
        "ultraviolet accents and bright cyan",
        "innovative revolutionary",
    ),
    "pisces": (
        "ocean",
        "teal and sea-green",
        "deep Neptune blue with bioluminescent accents",
        "mystical dreamlike transcendent",
    ),
}


def build_prompt(base, sign):
    """Compose: {sign palette} + {base shape} + common style."""
    element, color, glow, mood = SIGN_PALETTES[sign]
    base_shape = BASE_SHAPES[base]
    prompt = (
        f"{color.capitalize()} {element} nebula with {mood} atmosphere, {base_shape}, "
        f"{glow} glow, dynamic cosmic energy. "
        f"{SOLARA_STYLE}"
    )
    return prompt


def generate_one(base, sign, out_dir, max_retries=3):
    out_path = out_dir / f"{base}_{sign}.png"
    if out_path.exists():
        print(f"  SKIP: {base}_{sign}.png (exists)")
        return True

    prompt = build_prompt(base, sign)

    for attempt in range(1, max_retries + 1):
        label = f"{base}_{sign}" + (f" (retry {attempt})" if attempt > 1 else "")
        print(f"  Generating: {label} ...")
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
                    print(f"  OK: {base}_{sign}.png ({img.width}x{img.height}, {size_kb}KB)")
                    return True

            print(f"  WARN: No image returned for {base}_{sign}")

        except Exception as e:
            msg = str(e)
            print(f"  ERROR ({attempt}/{max_retries}): {msg[:120]}")
            if "503" in msg or "UNAVAILABLE" in msg or "Deadline" in msg:
                wait = 30 * attempt  # 30s, 60s, 90s backoff
                print(f"  Waiting {wait}s before retry...")
                time.sleep(wait)
                continue
            else:
                # Non-503 error, don't retry
                return False

    print(f"  FAIL: {base}_{sign} after {max_retries} retries")
    return False


def main():
    if len(sys.argv) < 2:
        print("Usage: python generate_base_variants.py <base> [signs]")
        print(f"Valid bases: {', '.join(BASE_SHAPES.keys())}")
        return

    base = sys.argv[1]
    if base not in BASE_SHAPES:
        print(f"Unknown base: {base}")
        print(f"Valid: {', '.join(BASE_SHAPES.keys())}")
        return

    # Exclude the base sign itself (e.g., leo variants = 11 non-leo signs)
    all_signs = [s for s in SIGN_PALETTES.keys() if s != base]

    if len(sys.argv) >= 3:
        names = [s.strip() for s in sys.argv[2].split(",")]
        targets = [s for s in names if s in SIGN_PALETTES and s != base]
    else:
        targets = all_signs

    out_dir = Path(__file__).parent / "share-assets" / f"backgrounds_{base}_variants"
    out_dir.mkdir(parents=True, exist_ok=True)

    print(f"\n=== Generating {len(targets)} {base} variants ===")
    print(f"Output: {out_dir}")
    print(f"Base shape: {BASE_SHAPES[base][:80]}...\n")

    ok = 0
    for sign in targets:
        if generate_one(base, sign, out_dir):
            ok += 1
        # Long sleep between images to avoid 503 from high demand
        time.sleep(10)

    print(f"\n=== Done: {ok}/{len(targets)} succeeded ===")


if __name__ == "__main__":
    main()
