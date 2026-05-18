"""
Waite版タロットカード サンプル生成 (Nanobanana2)
同じフェルメール画風、シンプルフレーム
"""

import os
import sys
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
if not API_KEY:
    print("ERROR: GEMINI_API_KEY not found")
    sys.exit(1)

client = genai.Client(api_key=API_KEY)

prompt = """
Generate a single tarot card image: "The Fool" (Major Arcana 0).

COMPOSITION (classic Rider-Waite-Smith):
A young man in an ornate floral tunic stands at the edge of a cliff, looking up at the sky. A small white dog jumps at his feet. He carries a small bundle on a stick over his right shoulder. A bright white sun shines in the upper right corner. He holds a white rose in his left hand. Mountains in the far background. Clear bright sky.

ART STYLE - Classic Rider-Waite-Smith tarot:
- Traditional tarot card illustration style, as commonly seen in standard Rider-Waite-Smith tarot decks
- Flat, bold, graphic illustration with clean outlines
- Bright, saturated colors: golden yellows, vivid reds, sky blues, leaf greens
- Simple flat backgrounds with minimal shading, bright yellow/golden sky
- Art Nouveau influenced line work from early 1900s
- NOT photorealistic, NOT oil painting — this is a printed card illustration
- Even, consistent coloring like a woodblock print with hand-applied watercolor tints
- The classic, iconic, universally recognized tarot card aesthetic

CARD BORDER:
- The card must have NO white margins or white border areas at all
- Solid black background behind and around the card
- The card image itself fills the full card area edge to edge
- If any border exists, it must be a thin black or very dark line only
- Absolutely NO white, cream, or light-colored borders anywhere on the output image

TECHNICAL:
- Card dimensions 2:3 ratio (portrait orientation)
- No text, no numbers, no letters, no card name anywhere on the image
- Clean, crisp illustration quality
- The output image background must be SOLID BLACK — no white padding
"""

print("Generating The Fool (Waite/Vermeer) via Nanobanana2...")

response = client.models.generate_content(
    model="gemini-3.1-flash-image-preview",
    contents=[prompt],
    config=types.GenerateContentConfig(
        response_modalities=["TEXT", "IMAGE"],
    ),
)

output_dir = Path(__file__).parent
for part in response.parts:
    if part.text is not None:
        print(f"Model: {part.text[:100]}")
    elif part.inline_data is not None:
        out_path = output_dir / "00_the_fool.png"
        image = part.as_image()
        image.save(str(out_path))
        print(f"Saved: {out_path}")
