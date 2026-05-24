"""
Generate the Cosmic Pro Sanctuary background (1 image) with the free
Gemini 3.1 Flash Image model (gemini-3.1-flash-image-preview).

Style: Art Nouveau temple / sanctuary (like assets/diagnosis-bg/reveal.webp)
but tuned for a FAINT background over a dark UI — deep midnight indigo +
antique gold, vignette edges.

Output: apps/solara/assets/sanctuary-bg/pro.webp  (9:16 portrait)

Usage:
  python generate_sanctuary_pro_bg.py          # generate
  python generate_sanctuary_pro_bg.py list     # show prompt only
"""
import os
import sys
import io
from pathlib import Path

# Load .env from repo root (E:/AppCreate/.env)
env_path = Path(__file__).resolve().parents[3] / ".env"
if env_path.exists():
    for line in env_path.read_text(encoding="utf-8").splitlines():
        if "=" in line and not line.startswith("#"):
            key, val = line.split("=", 1)
            os.environ.setdefault(key.strip(), val.strip())

PROMPT = (
    "Vertical 9:16 portrait background for a mystical 'sanctuary' app screen. "
    "Art Nouveau sacred temple interior: an ornate, perfectly symmetrical golden "
    "arch and slender decorative columns, delicate gold filigree and floral "
    "ornamental borders framing the edges like an antique frame, a soft radiant "
    "warm glow of light at the very center as if from an altar. "
    "Deep midnight indigo and dark navy background with antique gold and pale "
    "cream accents, faint starlight, reverent luxurious mystical atmosphere. "
    "The edges are noticeably darker (strong vignette) and the whole scene is "
    "subdued and atmospheric so it reads well as a FAINT background behind UI. "
    "Painterly digital art, premium elegant quality, cinematic soft lighting. "
    "No text, no letters, no numbers, no watermark, no signature, no human figures."
)

OUT_DIR = Path(__file__).resolve().parents[1] / "assets" / "sanctuary-bg"
OUT_DIR.mkdir(parents=True, exist_ok=True)
OUT_PATH = OUT_DIR / "pro.webp"


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "list":
        print(PROMPT)
        return

    print(f"Generating Cosmic Pro Sanctuary background -> {OUT_PATH}")
    from google import genai
    from google.genai import types

    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("ERROR: GEMINI_API_KEY not set in .env")
        sys.exit(1)

    client = genai.Client(api_key=api_key)
    response = client.models.generate_content(
        model="gemini-3.1-flash-image-preview",
        contents=[PROMPT],
        config=types.GenerateContentConfig(
            response_modalities=["TEXT", "IMAGE"],
            image_config=types.ImageConfig(aspect_ratio="9:16"),
        ),
    )
    for part in response.parts:
        if part.inline_data is not None:
            from PIL import Image

            img = Image.open(io.BytesIO(part.inline_data.data)).convert("RGB")
            img.save(str(OUT_PATH), "WEBP", quality=85)
            size_kb = OUT_PATH.stat().st_size // 1024
            print(f"OK: {OUT_PATH.name} ({img.width}x{img.height}, {size_kb}KB)")
            return

    print("WARN: no image returned (try again — 503/high demand is common)")
    sys.exit(2)


if __name__ == "__main__":
    main()
