"""
Generate catasterism (刻星化) background images using Gemini 3.1 Flash Image.
Two variants: 'void' (A案) and 'pillar' (C案), both 9:16 vertical.

Usage:
  python generate_catasterism_bg.py           # both
  python generate_catasterism_bg.py void      # A only
  python generate_catasterism_bg.py pillar    # C only
  python generate_catasterism_bg.py list      # show prompts
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

OUT_DIR = Path(__file__).resolve().parent.parent / "assets"

PROMPTS = {
    "void": (
        "A mystical vertical cosmic portrait, deep indigo to obsidian-black "
        "gradient void filling the entire frame, faint scattered stardust motes "
        "slowly converging near the compositional center, a subtle golden-amber "
        "pinprick of light beginning to crystallize at the heart, serene cosmic "
        "emptiness with barely visible nebular wisps drifting in far background, "
        "muted palette of deep navy / midnight violet / soft gold highlight, "
        "no moon, no planets, no constellation lines, no silhouettes of people "
        "or animals, purely abstract celestial void, ultra-minimal composition, "
        "dreamlike stillness, elegant quietude, 9:16 vertical orientation."
    ),
    "void2": (
        "A mystical vertical cosmic portrait, deep indigo and midnight-violet "
        "void filling the entire frame, a radiant amber-golden light core "
        "glowing at the compositional center with soft concentric halos "
        "reaching outward, dense scattered stardust filling the upper two-thirds "
        "of the frame with visible sparkle and varied brightness, subtle "
        "spiraling motion of cosmic dust gently converging toward the center, "
        "delicate nebular wisps of deep violet and teal drifting through the "
        "background, a gentle radial composition with the golden heart as "
        "focal point, muted palette of deep navy / midnight violet / amber "
        "gold / subtle teal mist, no moon, no planets, no constellation lines, "
        "no silhouettes of people or animals, purely abstract celestial nebula "
        "composition, cinematic yet minimal, reverent and dreamlike, "
        "9:16 vertical orientation."
    ),
    "pillar": (
        "A mystical vertical cosmic portrait, deep indigo-to-obsidian sky with "
        "a faint ethereal vertical luminance rising through the center, soft "
        "golden-amber aura column dissolving into stardust haze at top and "
        "bottom, tiny scattered star particles drifting around the central "
        "glow, sacred sanctuary-like atmosphere of ascent and arrival, "
        "no architectural structures, no moon, no planets, no human figures, "
        "purely abstract celestial light phenomenon, reverent and majestic yet "
        "minimal, muted palette of deep navy / midnight violet / ethereal "
        "golden light, 9:16 vertical orientation."
    ),
}


def generate_one(name, prompt):
    out_path = OUT_DIR / f"catasterism_bg_{name}.webp"
    if out_path.exists():
        print(f"  SKIP: catasterism_bg_{name}.webp (exists)")
        return True

    print(f"  Generating: catasterism_bg_{name} ...")
    try:
        from google import genai
        from google.genai import types

        api_key = os.environ.get("GEMINI_API_KEY")
        if not api_key:
            print("  ERROR: GEMINI_API_KEY not set in .env")
            return False

        client = genai.Client(api_key=api_key)
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
                img.save(str(out_path), "WEBP", quality=88, method=6)
                size_kb = out_path.stat().st_size // 1024
                print(f"  OK: catasterism_bg_{name}.webp ({img.width}x{img.height}, {size_kb}KB)")
                return True

        print(f"  WARN: No image returned for {name}")
        return False

    except Exception as e:
        print(f"  ERROR: {e}")
        return False


def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else "all"

    if arg == "list":
        for name, prompt in PROMPTS.items():
            print(f"\n[{name}]")
            print(f"  {prompt[:160]}...")
        return

    if arg == "all":
        targets = list(PROMPTS.items())
    elif arg in PROMPTS:
        targets = [(arg, PROMPTS[arg])]
    else:
        print(f"Unknown name: {arg}")
        print(f"Valid: {', '.join(PROMPTS.keys())}")
        return

    print(f"\n=== Generating {len(targets)} catasterism backgrounds ===")
    print(f"Output: {OUT_DIR}\n")

    ok = 0
    for name, prompt in targets:
        if generate_one(name, prompt):
            ok += 1
        time.sleep(2)

    print(f"\n=== Done: {ok}/{len(targets)} succeeded ===")


if __name__ == "__main__":
    main()
