"""
Generate the Tarot altar background image (斜め見下ろし占卓) using Gemini 3.1 Flash Image.
- 9:16 portrait, 768x1376
- Single ornate celestial wheel seen from overhead at 30° angle
- Museum-grade gold/bronze engraving, no planet symbols, no figures

Usage:
  python generate_tarot_altar.py           # generate (skip if exists)
  python generate_tarot_altar.py --force   # overwrite
"""
import os
import sys
import io
from pathlib import Path

from backup_util import backup_if_exists

env_path = Path(__file__).resolve().parents[3] / ".env"
if env_path.exists():
    for line in env_path.read_text(encoding="utf-8").splitlines():
        if "=" in line and not line.startswith("#"):
            key, val = line.split("=", 1)
            os.environ.setdefault(key.strip(), val.strip())

PROMPT = (
    "Ornate celestial altar wheel viewed from a STEEP 45-DEGREE TILTED ANGLE "
    "FROM ABOVE, as if looking down at a physical circular table from the "
    "side in strong three-dimensional perspective. The circular wheel "
    "therefore appears as a WIDE HORIZONTAL ELLIPSE — much wider than it is "
    "tall, clearly squashed vertically by the perspective foreshortening. "
    "The front edge of the wheel (closer to the viewer, at the bottom of "
    "the image) appears larger, and the back edge (further away, at the top) "
    "appears smaller and receding into distance. Dramatic depth. "
    "THE ENTIRE ELLIPTICAL WHEEL IS FULLY INSIDE THE SQUARE FRAME with a "
    "comfortable margin (at least 5% of the image width) on every side — "
    "the LEFT and RIGHT edges of the ellipse MUST be clearly visible inside "
    "the image, NOT touching or cropped by the frame. "
    "The rim is PLAIN ENGRAVED METAL with intricate gold filigree and floral "
    "ornamental patterns — NO symbols, NO letters, NO characters of any kind. "
    "Twelve radiating dividing lines from a shimmering central polaris point "
    "split the wheel into twelve equal sectors. TWELVE small golden candles "
    "evenly spaced around the rim — one candle at each of the twelve sector "
    "boundaries, ALL TWELVE candles visible including the leftmost and "
    "rightmost (at the widest points of the ellipse). "
    "The rim has REFINED, UNDERSTATED gold engraving — elegant filigree "
    "lines and subtle carved accents, NOT overcrowded with decoration. "
    "A clean substantial rim band with simple engraved line patterns and "
    "delicate minimal floral highlights. Tasteful, restrained craftsmanship. "
    "Surrounding the altar: deep cosmic void above and behind, subtle "
    "starfield, faint nebula whispers in deep navy and midnight blue. "
    "Candlelight warm glow on the rim, ceremonial mystical atmosphere. "
    "ABSOLUTELY NO zodiac symbols, NO astrological glyphs, NO Roman numerals, "
    "NO Arabic numerals, NO letters of any alphabet, NO Japanese or Chinese "
    "characters, NO planet symbols, NO human figures, NO tarot cards, "
    "NO watermark, NO signature, NO border, NO cropping. "
    "The rim is a pure ornamental band — NO writing of any kind. "
    "Square 1:1 composition, ultra detailed, photorealistic ritual art, "
    "cinematic tabletop studio lighting."
)

OUT_DIR = Path(__file__).parent / "share-assets" / "tarot_scene"
OUT_DIR.mkdir(parents=True, exist_ok=True)
OUT_PATH = OUT_DIR / "altar.png"


def generate():
    force = "--force" in sys.argv
    if OUT_PATH.exists() and not force:
        print(f"SKIP: {OUT_PATH.name} already exists (use --force to overwrite)")
        return True
    # Protect the existing file before overwriting.
    if OUT_PATH.exists():
        backup_if_exists(OUT_PATH)

    try:
        from google import genai
        from google.genai import types
        from PIL import Image
    except ImportError as e:
        print(f"ERROR: missing library — {e}")
        print("  pip install google-genai Pillow")
        return False

    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("ERROR: GEMINI_API_KEY not set")
        return False

    print("Generating tarot altar (9:16)...")
    client = genai.Client(api_key=api_key)
    try:
        response = client.models.generate_content(
            model="gemini-3.1-flash-image-preview",
            contents=[PROMPT],
            config=types.GenerateContentConfig(
                response_modalities=["TEXT", "IMAGE"],
                image_config=types.ImageConfig(aspect_ratio="1:1"),
            ),
        )
        for part in response.parts:
            if part.inline_data is not None:
                img = Image.open(io.BytesIO(part.inline_data.data))
                img.save(str(OUT_PATH), "PNG")
                size_kb = OUT_PATH.stat().st_size // 1024
                print(f"OK: {OUT_PATH} ({img.width}x{img.height}, {size_kb}KB)")
                return True
        print("WARN: No image returned")
        return False
    except Exception as e:
        print(f"ERROR: {e}")
        return False


if __name__ == "__main__":
    generate()
