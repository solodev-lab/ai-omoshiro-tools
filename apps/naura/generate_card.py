"""Generate a single Naura tarot card image using Gemini Imagen."""
import os
import sys
from google import genai
from google.genai import types

# Load API key
api_key = os.environ.get("GEMINI_API_KEY")
if not api_key:
    # Try loading from .env
    env_path = os.path.join(os.path.dirname(__file__), "..", "..", ".env")
    if os.path.exists(env_path):
        with open(env_path) as f:
            for line in f:
                if line.startswith("GEMINI_API_KEY="):
                    api_key = line.strip().split("=", 1)[1]
                    break

if not api_key:
    print("ERROR: GEMINI_API_KEY not found")
    sys.exit(1)

client = genai.Client(api_key=api_key)

prompt = sys.argv[1] if len(sys.argv) > 1 else """\"The Mirror Magician\" original tarot card. A robed figure stands before a large ornate mirror. One hand reaches toward the mirror surface, the other holds a glowing wand. In the mirror's reflection, the figure appears different - reversed, shadow-like, an alternate self. The table before the figure holds a cup, sword, pentacle, and wand. Infinity symbol reflected and doubled in the mirror. Soft moonlight illuminates the scene, casting dual shadows. Antique copper engraving style with hand-colored tinting. All human figures have a stoic, unreadable, emotionally ambiguous face with fully detailed eyes including pupils and iris, but showing no clear emotion. Ornate gold baroque frame border. Deep jewel tones, aged parchment background. Cracked gold leaf border texture. Card dimensions 2:3 ratio. No text, no numbers, no letters."""

filename = sys.argv[2] if len(sys.argv) > 2 else "test_mirror_magician.png"

print(f"Generating image: {filename}")
print(f"Prompt: {prompt[:80]}...")

response = client.models.generate_content(
    model="gemini-2.5-flash-image",
    contents=prompt,
    config=types.GenerateContentConfig(
        response_modalities=["image", "text"],
    ),
)

output_path = os.path.join(os.path.dirname(__file__), "card-images", filename)
os.makedirs(os.path.dirname(output_path), exist_ok=True)

saved = False
for part in response.candidates[0].content.parts:
    if part.inline_data and part.inline_data.mime_type.startswith("image/"):
        ext = part.inline_data.mime_type.split("/")[-1]
        if not filename.endswith(f".{ext}"):
            filename = filename.rsplit(".", 1)[0] + f".{ext}"
            output_path = os.path.join(os.path.dirname(output_path), filename)
        with open(output_path, "wb") as f:
            f.write(part.inline_data.data)
        print(f"Saved: {output_path} ({len(part.inline_data.data)} bytes)")
        saved = True
        break
    elif part.text:
        print(f"Text response: {part.text[:200]}")

if not saved:
    print("ERROR: No image in response")
    sys.exit(1)
