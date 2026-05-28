"""
Generate 3 background image candidates for AiConsentScreen.
Gemini 3.1 Flash Image, 9:16 portrait (768x1376).

Usage:
  python generate_ai_consent_bg.py        # all 3
  python generate_ai_consent_bg.py p1     # single
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

CANDIDATES = {
    "p1_forging_welcome": (
        "A vast cosmic galaxy spiraling in deep violet, indigo, and rose tones, "
        "with a brilliant warm golden star core at the center radiating gentle "
        "welcoming light. Ornate art nouveau golden frames at the top and bottom "
        "corners featuring delicate astrological symbols and rose motifs. Star "
        "clusters scattered throughout. Mystical and inviting atmosphere, perfect "
        "for an introduction screen. Vertical 9:16 portrait orientation. "
        "Painterly digital art, premium quality, cinematic lighting. "
        "No text, no letters, no numbers, no watermark."
    ),
    "p2_dawn_encounter": (
        "A serene cosmic vista with a swirling nebula in deep purple, midnight "
        "blue, and soft dawn pink. At the center, a luminous golden orb glows "
        "softly like the first light of dawn. Decorated with intricate gold art "
        "nouveau borders at the corners featuring constellation motifs and lily "
        "flowers. Stars sparkle gently across the canvas. A welcoming, peaceful "
        "atmosphere inviting quiet contemplation. Vertical 9:16 portrait. "
        "Painterly digital art, premium quality, cinematic lighting. "
        "No text, no letters, no numbers, no watermark."
    ),
    "p3_window_to_universe": (
        "An expansive cosmic galaxy with sweeping spiral arms in violet, indigo, "
        "and rose. A bright golden star at the center of the spiral, with soft "
        "rays of light extending outward. Surrounded by an ornate art nouveau "
        "frame in gold, with delicate floral and astrological symbol motifs in "
        "the corners. The composition feels both vast and intimate, like a window "
        "into the universe. Vertical 9:16 portrait orientation. "
        "Painterly digital art, premium quality, cinematic lighting. "
        "No text, no letters, no numbers, no watermark."
    ),
}

OUT_DIR = Path(__file__).parent / "ai_consent_bg_drafts"
OUT_DIR.mkdir(parents=True, exist_ok=True)


def generate_one(name, prompt):
    out_path = OUT_DIR / f"{name}.png"
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
                print(f"  OK: {name}.png ({img.width}x{img.height}, {size_kb}KB)")
                return True

        print(f"  WARN: No image returned for {name}")
        return False

    except Exception as e:
        print(f"  ERROR: {e}")
        return False


def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else "all"

    if arg == "all":
        targets = list(CANDIDATES.items())
    elif arg in CANDIDATES:
        targets = [(arg, CANDIDATES[arg])]
    else:
        # short form: p1/p2/p3
        match = [(k, v) for k, v in CANDIDATES.items() if k.startswith(arg + "_")]
        if match:
            targets = match
        else:
            print(f"Unknown: {arg}")
            print(f"Valid: all, {', '.join(CANDIDATES.keys())}")
            return

    print(f"\n=== Generating {len(targets)} AiConsent background candidates ===")
    print(f"Output: {OUT_DIR}\n")

    ok = 0
    for name, prompt in targets:
        if generate_one(name, prompt):
            ok += 1
        time.sleep(2)

    print(f"\n=== Done: {ok}/{len(targets)} succeeded ===")


if __name__ == "__main__":
    main()
