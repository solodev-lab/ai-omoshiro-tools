"""
Generate mystical/antique backgrounds for Horo screen.
- parchment_base: aged parchment texture behind the chart wheel (center tile)
- cosmic_nebula: deep space nebula for full-screen background
- ornament_corners: Art-Nouveau/filigree decorative corner

Usage:
  python generate_horo_backgrounds.py test           # generate 1 test (parchment)
  python generate_horo_backgrounds.py all            # generate all
  python generate_horo_backgrounds.py parchment      # single
"""
import os
import sys
import io
from pathlib import Path
from google import genai
from google.genai import types
from PIL import Image

# Load .env
env_path = Path(__file__).resolve().parents[3] / ".env"
if env_path.exists():
    for line in env_path.read_text(encoding="utf-8").splitlines():
        if "=" in line and not line.startswith("#"):
            key, val = line.split("=", 1)
            os.environ.setdefault(key.strip(), val.strip())

OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "horo-bg"
OUT_DIR.mkdir(parents=True, exist_ok=True)

IMAGES = {
    "parchment_base": {
        "aspect": "1:1",
        "prompt": (
            "Ancient plain mystical parchment texture, aged vellum paper, "
            "weathered and stained, deep midnight blue and indigo tones "
            "with soft gold flecks and copper patina burned edges, "
            "subtle organic fiber texture, cosmic dust and tiny scattered golden sparkles, "
            "dark navy to deep purple soft radial gradient from center, "
            "mystical occult aesthetic, dark academia mood, antique vellum feel. "
            "Ultra-dark background tones suitable as circular chart backdrop. "
            "ABSOLUTELY NO diagrams, NO astrology symbols, NO zodiac wheels, NO circles, "
            "NO charts, NO drawings, NO lines, NO geometry, NO patterns, "
            "NO text, NO letters, NO numbers, NO watermark, NO border, NO frame, NO signature. "
            "Just pure textured parchment background only, completely blank of any drawn content, "
            "premium painterly digital art."
        ),
    },
    "cosmic_nebula": {
        "aspect": "9:16",
        "prompt": (
            "Deep cosmic nebula background, vast mystical starfield, "
            "swirling dark purple indigo and midnight blue clouds, "
            "scattered golden and copper stars, antique gold dust, "
            "ethereal subtle glow, Renaissance star map aesthetic mixed with deep space photography, "
            "dark academia occult mood, mystical and cinematic, "
            "abstract nebula forms, no figures, no symbols, no text, no letters, no watermark, "
            "painterly digital art, ultra-high detail, premium quality, "
            "very dark overall tone so UI overlays remain readable."
        ),
    },
    "new_moon_bg": {
        "aspect": "9:16",
        "prompt": (
            "Mystical new moon night scene, deep indigo and midnight blue cosmic sky, "
            "a thin crescent moon silhouette with a subtle faint golden rim in the UPPER portion, "
            "visible swirling nebula clouds in rich purple, indigo and golden tones in the upper third, "
            "scattered bright stars and cosmic dust throughout, "
            "soft glowing stars with noticeable luminance, "
            "antique celestial manuscript style, dark academia and occult mood, "
            "sense of fresh beginning and quiet intention, "
            "Lower portion transitions to darker tones for overlay text readability. "
            "NO text, NO letters, NO numbers, NO watermark, NO border, NO frame, NO signature, "
            "painterly digital art, premium quality, cinematic, mystical elegance."
        ),
    },
    "full_moon_bg": {
        "aspect": "9:16",
        "prompt": (
            "Mystical full moon night, luminous full moon partially hidden behind "
            "soft silver and golden nebula clouds in the UPPER portion, "
            "deep midnight blue starfield, golden dust particles, "
            "ethereal bright glow radiating outward from moon, "
            "antique celestial illumination manuscript style, dark academia mood, "
            "sense of culmination, fulfillment and reflection, "
            "Ultra-dark in the lower portion for overlay text readability, "
            "moon positioned in top third of image. "
            "NO text, NO letters, NO numbers, NO watermark, NO border, NO frame, NO signature, "
            "painterly digital art, premium quality, cinematic."
        ),
    },
    "ornament_frame": {
        "aspect": "1:1",
        "prompt": (
            "Ornamental Art Nouveau filigree corner decoration, "
            "thin elegant gold line work on pure black background, "
            "intricate swirling vines, celestial motifs, tiny stars and crescent moon details, "
            "symmetrical vintage astrological chart border ornament, "
            "Renaissance alchemical manuscript illumination style, "
            "antique brass and gold color, no color fill only thin outlined linework, "
            "no text, no letters, no watermark, no signature, "
            "transparent-looking black background, flat 2D illustration, "
            "premium quality decorative element suitable for overlay."
        ),
    },
}

def generate(key: str):
    cfg = IMAGES[key]
    print(f"[generate] {key} (aspect={cfg['aspect']})")
    client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])
    response = client.models.generate_content(
        model="gemini-3.1-flash-image-preview",
        contents=[cfg["prompt"]],
        config=types.GenerateContentConfig(
            response_modalities=["TEXT", "IMAGE"],
            image_config=types.ImageConfig(aspect_ratio=cfg["aspect"]),
        ),
    )
    for part in response.parts:
        if part.inline_data is not None:
            img = Image.open(io.BytesIO(part.inline_data.data))
            out_path = OUT_DIR / f"{key}.webp"
            img.save(out_path, "WEBP", quality=88)
            print(f"  -> saved: {out_path} ({img.size})")
            return
    print(f"  !! no image returned for {key}")

def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else "test"
    if arg == "test":
        generate("parchment_base")
    elif arg == "all":
        for k in IMAGES:
            generate(k)
    elif arg in IMAGES:
        generate(arg)
    else:
        print(f"unknown: {arg}")
        print(f"options: test, all, {', '.join(IMAGES.keys())}")

if __name__ == "__main__":
    main()
