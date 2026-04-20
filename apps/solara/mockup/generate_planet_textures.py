"""
Generate equirectangular planet texture maps (2:1 ratio) using Gemini.
These flat maps are used by generate_planet_rotations.py to produce
rotating sphere WebP animations.

Gemini 3.1 Flash Image does NOT support a 2:1 aspect ratio directly,
so we generate at 21:9 (closest wide ratio) and letterbox/crop to exact 2:1.

Output size after processing: 2048×1024 equirectangular PNG.

Usage:
  python generate_planet_textures.py            # all 10
  python generate_planet_textures.py jupiter    # single
  python generate_planet_textures.py --force
"""
import os
import sys
import time
import io
from pathlib import Path

from backup_util import backup_if_exists

env_path = Path(__file__).resolve().parents[3] / ".env"
if env_path.exists():
    for line in env_path.read_text(encoding="utf-8").splitlines():
        if "=" in line and not line.startswith("#"):
            key, val = line.split("=", 1)
            os.environ.setdefault(key.strip(), val.strip())

COMMON_TAIL = (
    " EQUIRECTANGULAR flat 2D projection map of the planet surface, fully "
    "UNWRAPPED and unrolled onto a flat rectangle, NO sphere, NO curvature, "
    "NO shadow, NO lighting, NO 3D rendering. "
    "Pure albedo surface texture only (as if photographed under uniform flat "
    "diffuse light), edges wrap seamlessly left to right. "
    "NO stars, NO space background, NO labels, NO text, NO grid. "
    "The entire frame is filled with the planet surface only — no black borders. "
    "Scientific cartography / NASA Visible Earth style planetary surface map. "
    "Ultra wide 2:1 ratio (width twice the height), ultra high detail."
)

TEXTURES = {
    "sun": (
        "Equirectangular surface texture map of the SUN, photosphere granulation "
        "pattern, turbulent bright yellow-orange plasma, subtle sunspots scattered "
        "irregularly, fine cellular convection detail."
        + COMMON_TAIL
    ),
    "moon": (
        "Equirectangular surface texture map of the MOON, cratered lunar regolith "
        "with dark maria (Mare Tranquillitatis, Mare Imbrium), bright highland "
        "regions, named craters visible (Tycho, Copernicus), cold grey-white "
        "photographic realism."
        + COMMON_TAIL
    ),
    "mercury": (
        "Equirectangular surface texture map of MERCURY, heavily cratered grey-brown "
        "regolith, impact basins (Caloris Basin), smooth plains, warm tan undertones."
        + COMMON_TAIL
    ),
    "venus": (
        "Equirectangular surface texture map of VENUS cloud tops, thick sulfuric "
        "acid yellow-cream swirling cloud bands, subtle atmospheric variations, "
        "pale golden haze, smooth cloud blanket pattern."
        + COMMON_TAIL
    ),
    "mars": (
        "Equirectangular surface texture map of MARS, rust red-orange regolith, "
        "polar ice caps at top and bottom edges, Valles Marineris canyon as a "
        "long dark east-west scar, Olympus Mons shield volcano, dusty terrain detail."
        + COMMON_TAIL
    ),
    "jupiter": (
        "Equirectangular surface texture map of JUPITER, distinct horizontal cloud "
        "bands in cream, beige, orange and rust colors, prominent GREAT RED SPOT "
        "storm, turbulent atmospheric swirls and eddies, gas giant weather detail."
        + COMMON_TAIL
    ),
    "saturn": (
        "Equirectangular surface texture map of SATURN planet body only (NO rings), "
        "pale gold gas giant with subtle cream and tan horizontal cloud bands, "
        "delicate atmospheric patterns, featureless elegance."
        + COMMON_TAIL
    ),
    "uranus": (
        "Equirectangular surface texture map of URANUS, smooth pale cyan-teal "
        "ice giant cloud layer, extremely subtle horizontal bands, uniform "
        "featureless atmosphere."
        + COMMON_TAIL
    ),
    "neptune": (
        "Equirectangular surface texture map of NEPTUNE, deep azure blue ice "
        "giant, visible white storm systems (Great Dark Spot), subtle cloud "
        "streaks, vivid cobalt atmosphere bands."
        + COMMON_TAIL
    ),
    "pluto": (
        "Equirectangular surface texture map of PLUTO, icy dwarf planet surface, "
        "brown-grey with lighter heart-shaped Tombaugh Regio region, nitrogen "
        "ice plains, patchy tholin-stained terrain."
        + COMMON_TAIL
    ),
}

OUT_DIR = Path(__file__).parent / "share-assets" / "tarot_scene" / "planet_textures"
OUT_DIR.mkdir(parents=True, exist_ok=True)


def generate_one(name, prompt, force=False):
    out_path = OUT_DIR / f"{name}.png"
    if out_path.exists() and not force:
        print(f"  SKIP: {name}.png (exists)")
        return True
    if out_path.exists():
        backup_if_exists(out_path)

    try:
        from google import genai
        from google.genai import types
        from PIL import Image
    except ImportError as e:
        print(f"  ERROR: missing library — {e}")
        return False

    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("  ERROR: GEMINI_API_KEY not set")
        return False

    print(f"  Generating: {name} ...")
    client = genai.Client(api_key=api_key)
    try:
        response = client.models.generate_content(
            model="gemini-3.1-flash-image-preview",
            contents=[prompt],
            config=types.GenerateContentConfig(
                response_modalities=["TEXT", "IMAGE"],
                image_config=types.ImageConfig(aspect_ratio="21:9"),
            ),
        )
        for part in response.parts:
            if part.inline_data is not None:
                img = Image.open(io.BytesIO(part.inline_data.data)).convert("RGB")
                # Crop to exact 2:1 (center-crop horizontally)
                target_w = img.height * 2
                if img.width > target_w:
                    x0 = (img.width - target_w) // 2
                    img = img.crop((x0, 0, x0 + target_w, img.height))
                # Resize to 2048x1024 for consistent rotation output
                img = img.resize((2048, 1024), Image.LANCZOS)
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
    args = sys.argv[1:]
    force = "--force" in args
    args = [a for a in args if not a.startswith("-")]

    if args:
        targets = [(a, TEXTURES[a]) for a in args if a in TEXTURES]
        if not targets:
            print(f"Valid: {', '.join(TEXTURES.keys())}")
            return
    else:
        targets = list(TEXTURES.items())

    print(f"=== Generating {len(targets)} planet textures (21:9 → 2:1 cropped) ===")
    print(f"Output: {OUT_DIR}\n")
    ok = 0
    for name, prompt in targets:
        if generate_one(name, prompt, force=force):
            ok += 1
        time.sleep(2)
    print(f"\n=== Done: {ok}/{len(targets)} succeeded ===")


if __name__ == "__main__":
    main()
