"""
Generate constellation illustration art using Gemini direct ($0).
Style: White line art on black background, 512x512.
Usage: python generate_constellation_art.py [category]
"""
import os
import sys
import time
from pathlib import Path

env_path = Path(__file__).resolve().parents[3] / ".env"
if env_path.exists():
    for line in env_path.read_text(encoding="utf-8").splitlines():
        if "=" in line and not line.startswith("#"):
            key, val = line.split("=", 1)
            os.environ.setdefault(key.strip(), val.strip())

from google import genai
from google.genai import types

API_KEY = os.environ.get("GEMINI_API_KEY")
client = genai.Client(api_key=API_KEY)

STYLE = (
    "White line art illustration on pure black background. "
    "Elegant, detailed linework with fine contours. No color, only white lines and subtle white shading on black. "
    "Ethereal, celestial, mystical atmosphere. "
    "No text, no letters, no numbers, no watermark. "
    "The illustration should look like a constellation guide book overlay. "
    "Semi-transparent feeling, delicate strokes, astronomical art style. "
    "Square composition, centered subject."
)

CATEGORIES = {
    "celestial": {
        "name": "天体・宇宙",
        "nouns": {
            "comet": "A comet with a long glowing tail streaking across space",
            "orbit": "Concentric orbital rings with small planets at different positions",
            "eclipse": "A solar eclipse with corona rays emerging around a dark moon",
            "nova": "An exploding star radiating brilliant light outward in all directions",
            "meteor": "A meteor burning through atmosphere with a trail of sparks",
            "nebula": "A swirling cloud of cosmic gas and dust forming new stars",
            "crescent": "A detailed crescent moon with subtle crater textures",
            "horizon": "A curved planetary horizon with stars rising above it",
            "starfall": "Multiple shooting stars falling in graceful arcs",
            "corona": "A radiant solar corona with delicate flame-like projections",
            "zenith": "A single brilliant star at the apex with radiating light beams",
            "aurora": "Flowing curtains of aurora borealis light dancing in waves",
            "solstice": "The sun at its highest point with radiating geometric light patterns",
            "equinox": "Two equal halves of light and dark in perfect balance",
            "meridian": "A great circle line across the celestial sphere with star markers",
            "void": "An empty dark region surrounded by distant stars at the edges",
            "pulsar": "A rapidly spinning neutron star emitting twin beams of light",
            "perihelion": "A planet at its closest approach to a radiant sun",
            "aphelion": "A distant planet far from a small sun, cold and isolated",
            "parallax": "Two viewpoints showing shifted star positions with connecting geometry",
            "singularity": "A point of infinite density warping space-time around it, gravitational lensing effect",
        }
    },
    "music": {
        "name": "楽器・芸術",
        "nouns": {
            "harp": "An elegant celestial harp with strings that glow like starlight",
            "bell": "A large ornate temple bell with resonating sound wave rings",
            "flute": "A delicate flute with flowing musical notes transforming into stars",
            "drum": "A ceremonial drum with vibration patterns radiating from the skin",
            "bugle": "A military bugle horn with a clear call echoing outward",
            "lyre": "An ancient Greek lyre with constellation strings between the arms",
            "chime": "Wind chimes hanging from a branch with gentle rings of sound",
            "verse": "An open scroll with flowing calligraphic lines forming a poem shape",
            "aria": "A singing figure with voice manifesting as spiraling light",
            "sonata": "Musical staff lines curving through space with notes as stars",
            "hymn": "Sacred musical notation forming a cathedral-like shape",
            "requiem": "A solemn arrangement of fading musical notes dissolving into darkness",
            "orpheus": "A mythological musician playing a lyre that commands the stars themselves",
        }
    },
    "body": {
        "name": "身体・翼",
        "nouns": {
            "wing": "A single large angelic wing spread wide with detailed feathers",
            "feather": "A single floating feather with intricate barb detail",
            "fang": "A pair of curved predator fangs, sharp and gleaming",
            "claw": "A powerful eagle-like talon gripping empty space",
            "antler": "A majestic branching deer antler like a bare winter tree",
            "tail": "A long serpentine tail curving elegantly through space",
            "horn_body": "A spiral ram horn with textured ridges",
            "eye": "A single all-seeing eye with a cosmic iris containing galaxies",
            "skull": "An ornate decorated skull with celestial patterns carved into bone",
            "bone": "Ancient bones arranged in a ritualistic pattern",
            "heart": "An anatomical heart with veins branching like constellation lines",
            "halo": "A luminous ring of divine light floating above an invisible head",
            "third_eye": "A mystical third eye opening vertically on a forehead, radiating cosmic vision",
        }
    },
    "geometry": {
        "name": "幾何・抽象",
        "nouns": {
            "spiral": "A perfect golden ratio spiral expanding outward",
            "prism": "A triangular prism splitting light into spectral rays",
            "crystal": "A geometric crystal cluster with sharp faceted surfaces",
            "arc": "A graceful mathematical arc curving through starfield",
            "helix": "A DNA-like double helix spiraling vertically",
            "axis": "Three intersecting axes forming a cosmic coordinate system",
            "fractal": "A Mandelbrot-like fractal pattern with infinite recursive detail",
            "vortex": "A spiraling vortex pulling matter inward to a central point",
            "infinity_symbol": "A figure-eight infinity symbol made of flowing light",
            "tesseract": "A four-dimensional hypercube rotating in space, wireframe style",
            "paradox": "An impossible Escher-like staircase that loops endlessly",
            "nexus": "Multiple lines converging to a single bright junction point",
            "mobius": "A Mobius strip twisting through space with a single continuous surface",
        }
    },
}

OUT_DIR = Path(__file__).parent / "share-assets" / "constellation-art"
OUT_DIR.mkdir(parents=True, exist_ok=True)


def generate_one(noun_key, description):
    """Generate a single constellation illustration."""
    # Fix filename for special cases
    filename = noun_key.replace("horn_body", "horn").replace("infinity_symbol", "infinity")
    out_path = OUT_DIR / f"{filename}.webp"

    if out_path.exists():
        print(f"  SKIP: {filename}.webp")
        return True

    prompt = f"{description}. {STYLE}"
    print(f"  Generating: {filename} ...")

    try:
        response = client.models.generate_content(
            model="gemini-3.1-flash-image-preview",
            contents=[prompt],
            config=types.GenerateContentConfig(
                response_modalities=["TEXT", "IMAGE"],
            ),
        )
        for part in response.parts:
            if part.inline_data is not None:
                image = part.as_image()
                # Resize to 512x512 and save as WebP
                from PIL import Image
                import io
                img = image.copy()
                img.thumbnail((512, 512), Image.LANCZOS)
                # Pad to 512x512 if not square
                padded = Image.new("RGB", (512, 512), (0, 0, 0))
                x = (512 - img.width) // 2
                y = (512 - img.height) // 2
                padded.paste(img, (x, y))
                padded.save(str(out_path), "WEBP", quality=85)
                size_kb = out_path.stat().st_size // 1024
                print(f"  OK: {filename}.webp ({size_kb}KB)")
                return True

        print(f"  WARN: No image returned for {filename}")
        return False

    except Exception as e:
        print(f"  ERROR: {e}")
        return False


def generate_category(cat_key):
    """Generate all nouns in a category."""
    if cat_key not in CATEGORIES:
        print(f"Unknown category: {cat_key}")
        print(f"Available: {', '.join(CATEGORIES.keys())}")
        return

    cat = CATEGORIES[cat_key]
    print(f"\n=== {cat['name']} ({len(cat['nouns'])} images) ===\n")

    success = 0
    for noun_key, description in cat["nouns"].items():
        if generate_one(noun_key, description):
            success += 1
        time.sleep(3)  # Rate limit

    print(f"\n  Done: {success}/{len(cat['nouns'])} generated")


if __name__ == "__main__":
    cat = sys.argv[1] if len(sys.argv) > 1 else "all"

    if cat == "all":
        for key in CATEGORIES:
            generate_category(key)
    elif cat == "list":
        for key, val in CATEGORIES.items():
            print(f"  {key}: {val['name']} ({len(val['nouns'])} nouns)")
    else:
        generate_category(cat)
