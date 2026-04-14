"""
Solara タロットカード画像生成スクリプト (Nanobanana2 / Gemini API)
Usage: python generate_card.py
"""

import os
import sys
from pathlib import Path

# .env読み込み
env_path = Path(__file__).resolve().parents[3] / ".env"
if env_path.exists():
    for line in env_path.read_text(encoding="utf-8").splitlines():
        if "=" in line and not line.startswith("#"):
            key, val = line.split("=", 1)
            os.environ.setdefault(key.strip(), val.strip())

from google import genai
from google.genai import types

API_KEY = os.environ.get("GEMINI_API_KEY")
if not API_KEY:
    print("ERROR: GEMINI_API_KEY not found in .env")
    sys.exit(1)

client = genai.Client(api_key=API_KEY)

# --- Solara Vermeer風 プロンプト ---
prompt = """
Generate a single tarot card image: "The Fool" (Major Arcana 0).

COMPOSITION (Rider-Waite based):
A young man in colorful medieval clothing stands at the edge of a cliff, gazing upward at the sky with a carefree expression. A small white dog leaps playfully at his feet. He carries a small bundle tied to a stick over his shoulder. A bright sun shines behind him. He holds a white rose in one hand.

ART STYLE — Johannes Vermeer:
- Render in the style of Johannes Vermeer's oil paintings
- Soft, luminous light pouring from the upper left, creating Vermeer's signature warm golden glow
- Rich, deep color palette: ultramarine blue, vermilion red, ochre yellow, lead white
- Vermeer's characteristic pointillé technique for highlights (tiny dots of light on surfaces)
- Subtle chiaroscuro with smooth tonal gradations
- Meticulous attention to fabric textures: silk, velvet, linen rendered with photorealistic detail
- Atmospheric perspective in the background landscape
- The scene should feel like a Dutch Golden Age painting come to life

CARD FRAME (Major Arcana — between Minor Arcana and baroque):
- The card background and border area must be DARK — deep black, NO white or cream margins anywhere
- Thin gold double-line border as the base, same thickness as Minor Arcana
- The painting area must remain large — do NOT shrink the image to make room for heavy decoration
- ADD: elegant gold corner ornaments at all four corners (slightly larger than Minor Arcana, with small leaf/curl motif)
- ADD: a subtle thin gold decorative line or tiny repeating dot pattern running along the top and bottom edges ONLY, between the corner ornaments
- The sides remain clean double-line only — no decoration on left/right edges
- This should feel like a refined picture frame upgrade, NOT a heavy baroque border
- Inner border has a fine dark line, outer border is burnished gold
- Narrow gap between the image and the frame, filled with black

TECHNICAL:
- Card dimensions 2:3 ratio (portrait orientation)
- No text, no numbers, no letters, no card name anywhere on the image
- High detail, museum quality
- The entire card including frame must be on a SOLID BLACK or very dark background — absolutely NO white borders or light-colored margins
"""

print("Generating The Fool (Vermeer style) via Nanobanana2...")
print("Model: gemini-3.1-flash-image-preview")

response = client.models.generate_content(
    model="gemini-3.1-flash-image-preview",
    contents=[prompt],
    config=types.GenerateContentConfig(
        response_modalities=["TEXT", "IMAGE"],
    ),
)

output_dir = Path(__file__).parent
output_dir.mkdir(parents=True, exist_ok=True)

saved = False
for part in response.parts:
    if part.text is not None:
        print(f"Model response: {part.text}")
    elif part.inline_data is not None:
        out_path = output_dir / "00_the_fool_v4.png"
        image = part.as_image()
        image.save(str(out_path))
        print(f"Saved: {out_path}")
        saved = True

if not saved:
    print("WARNING: No image was generated. Check the response above.")
    print(f"Full response: {response}")
