"""
Generate 10 realistic planet images on pure black background.
- 1:1 square, 1024x1024
- NASA-style photorealistic, warm light from upper right
- Pure solid black background (will be alpha-keyed later)

Usage:
  python generate_tarot_planets.py            # all 10 (skip existing)
  python generate_tarot_planets.py sun        # single planet
  python generate_tarot_planets.py --force    # overwrite all
  python generate_tarot_planets.py list       # list prompts
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
    " isolated on PURE SOLID BLACK background (#000000), centered perfect sphere, "
    "warm key light from upper right creating deep shadow on lower-left side, "
    "subtle rim light on shadow edge, "
    "NO text, NO labels, NO stars around, NO nebula, NO decoration, "
    "NO captions, NO watermarks. "
    "Studio astronomy photograph quality, NASA/ESA scientific visualization style, "
    "ultra high detail, photorealistic 3D rendered celestial body. "
    "1:1 square composition."
)

PLANETS = {
    "sun": (
        "Realistic 3D rendered SUN — massive fiery radiant plasma sphere, "
        "orange-yellow turbulent surface, granulation patterns, solar flares "
        "and prominences arcing at the edges, bright corona glow around the disk, "
        "intense luminous self-emission."
        + COMMON_TAIL
    ),
    "moon": (
        "Realistic 3D rendered MOON — cratered lunar surface with maria "
        "(dark basalt plains) and highlands, cold grey-white regolith, "
        "Tycho and Copernicus craters visible, sharp terminator shadow "
        "between day and night side."
        + COMMON_TAIL
    ),
    "mercury": (
        "Realistic 3D rendered MERCURY — heavily cratered grey-brown surface, "
        "dense impact basins, Caloris-like large crater system, "
        "dry airless regolith with subtle warm tan tones."
        + COMMON_TAIL
    ),
    "venus": (
        "Realistic 3D rendered VENUS — thick swirling yellow-cream cloud layers, "
        "sulfuric acid atmospheric bands, smooth uniform cloudtops with "
        "subtle variations, no visible surface features, pale golden haze."
        + COMMON_TAIL
    ),
    "mars": (
        "Realistic 3D rendered MARS — rust red-orange regolith, visible polar "
        "ice cap in white, Valles Marineris canyon as dark scar, Olympus Mons "
        "shield volcano, dust storm tinted atmosphere at limb."
        + COMMON_TAIL
    ),
    "jupiter": (
        "Realistic 3D rendered JUPITER — massive gas giant with distinct "
        "horizontal cloud bands in cream, beige, orange and rust, prominent "
        "GREAT RED SPOT storm visible, turbulent atmospheric swirls, "
        "subtle banded shadows."
        + COMMON_TAIL
    ),
    "saturn": (
        "Realistic 3D rendered SATURN, centered composition — pale gold gas "
        "giant with subtle cream and tan horizontal cloud bands, "
        "ONE SINGLE FLAT EQUATORIAL RING PLANE (not multiple, not crossed) "
        "tilted at approximately 20 degrees of perspective, the ring cuts "
        "across the planet as a thin horizontal ellipse. "
        "THE ENTIRE RING SYSTEM IS COMFORTABLY INSIDE THE FRAME with a small "
        "uniform margin (about 8-10% of image width) between the ring tips "
        "and the left/right image edges — rings must NOT touch or be cropped "
        "by the edges. Cassini Division gap clearly visible as a dark line "
        "within the ring, pale icy ring particles, the ring casts a soft "
        "shadow on the planet's equator. "
        "ABSOLUTELY NO double rings, NO crossed rings, NO X-shaped rings, "
        "NO multiple ring planes, NO vertical ring, NO halo, NO cropping. "
        "Photorealistic NASA Cassini mission photo reference style, elegant."
        + COMMON_TAIL
    ),
    "uranus": (
        "Realistic 3D rendered URANUS — smooth pale cyan-teal ice giant, "
        "uniform featureless atmosphere with extremely faint bands, "
        "tilted axis, subtle ring hint at equator."
        + COMMON_TAIL
    ),
    "neptune": (
        "Realistic 3D rendered NEPTUNE — deep azure blue ice giant, "
        "visible white storm systems and cloud streaks, "
        "Great Dark Spot storm feature, vivid cobalt atmosphere."
        + COMMON_TAIL
    ),
    "pluto": (
        "Realistic 3D rendered PLUTO — icy dwarf planet, brown-grey surface "
        "with lighter heart-shaped Tombaugh Regio region, nitrogen ice plains, "
        "cold desolate frozen world, subtle haze at limb."
        + COMMON_TAIL
    ),
}

OUT_DIR = Path(__file__).parent / "share-assets" / "tarot_scene" / "planets"
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


def main():
    args = sys.argv[1:]
    force = "--force" in args
    args = [a for a in args if not a.startswith("-")]

    if args and args[0] == "list":
        for name, prompt in PLANETS.items():
            print(f"\n[{name}]")
            print(f"  {prompt[:160]}...")
        return

    if args:
        targets = [(a, PLANETS[a]) for a in args if a in PLANETS]
        if not targets:
            print(f"Valid: {', '.join(PLANETS.keys())}")
            return
    else:
        targets = list(PLANETS.items())

    print(f"=== Generating {len(targets)} planets (1:1) ===")
    print(f"Output: {OUT_DIR}\n")
    ok = 0
    for name, prompt in targets:
        if generate_one(name, prompt, force=force):
            ok += 1
        time.sleep(2)
    print(f"\n=== Done: {ok}/{len(targets)} succeeded ===")


if __name__ == "__main__":
    main()
