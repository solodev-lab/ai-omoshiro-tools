"""
Generate 3 startup-splash background images (Art Nouveau / Mucha mystical altar)
matching the title-diagnosis intro.webp aesthetic, for Solara's cold-start splash.

- Vertical 9:16 (768x1376), saved as .webp into apps/solara/assets/splash-bg/
- CENTER kept calm/luminous & empty so "Solara" + subtitle can be overlaid in Flutter
- NO text in the image (title/subtitle are drawn by Flutter)
- 3 color moods: dawn (warm gold), twilight (amethyst), cosmic (sapphire)

Standard method per CLAUDE.md: Gemini API gemini-3.1-flash-image-preview (Flash).

Usage:
  python generate_splash_backgrounds.py            # all 3
  python generate_splash_backgrounds.py dawn        # single
  python generate_splash_backgrounds.py dawn,cosmic # comma-separated subset
  python generate_splash_backgrounds.py list         # show prompts
"""
import os
import sys
import time
import io
from pathlib import Path

# Load .env from repo root (apps/solara/mockup -> parents[3] = E:/AppCreate)
env_path = Path(__file__).resolve().parents[3] / ".env"
if env_path.exists():
    for line in env_path.read_text(encoding="utf-8").splitlines():
        if "=" in line and not line.startswith("#"):
            key, val = line.split("=", 1)
            os.environ.setdefault(key.strip(), val.strip())

# Based on the "ceremony" diagnosis background: pure black, ornate gold Art Nouveau
# filigree ONLY in the four corners, and a single glowing four-pointed star in the
# CENTER with a soft halo. Minimal & elegant. Title/subtitle are overlaid in Flutter
# (placed just below the star), so the lower-center stays calm dark space.
SPLASH_STYLE = (
    "Elegant Art Nouveau tarot-card design on a PURE DEEP BLACK background, vertical 9:16 "
    "portrait orientation. Ornate golden Art Nouveau filigree ONLY in the FOUR CORNERS: "
    "symmetrical gold flourishes with a small laurel wreath, roses and lilies in the top-left and "
    "top-right corners meeting near the top, mirrored by gold rose-and-lily flourishes in the "
    "bottom-left and bottom-right corners meeting near the bottom; thin elegant gold line accents. "
    "A single luminous FOUR-POINTED STAR with a soft radiant glow shining in the CENTER of the "
    "image, its gentle halo of light spreading into the surrounding darkness. A scattering of fine "
    "sparkles, faint floating embers and a subtle dust starfield drifting around the central star. "
    "VERY IMPORTANT: the large central and lower area is mostly EMPTY DEEP BLACK, with only the "
    "glowing star and soft sparkles - calm, minimal, lots of negative space, no objects, "
    "no ornament outside the corners. Elegant, premium, hand-drawn vintage gold-leaf line art. "
    "Absolutely NO text, NO letters, NO numbers, NO words, NO title, NO captions, "
    "NO watermark, NO signature."
)

SPLASH_BACKGROUNDS = {
    "gold": (
        "The central four-pointed star and its glow are warm radiant GOLD and champagne, "
        "with warm amber ember sparkles. Corner filigree is gold. Classic and regal. "
        + SPLASH_STYLE
    ),
    "azure": (
        "The central four-pointed star and its glow are cool luminous SILVER-AZURE and pale "
        "blue-white, with cool silver sparkles. The corner filigree stays gold. Serene and celestial. "
        + SPLASH_STYLE
    ),
    "rose": (
        "The central four-pointed star and its glow are soft warm ROSE-GOLD and gentle blush pink, "
        "with delicate rose-gold sparkles. The corner filigree stays gold. Tender and dreamy. "
        + SPLASH_STYLE
    ),
}

OUT_DIR = Path(__file__).resolve().parents[1] / "assets" / "splash-bg"
OUT_DIR.mkdir(parents=True, exist_ok=True)


def generate_one(name, prompt):
    out_path = OUT_DIR / f"{name}.webp"
    if out_path.exists():
        print(f"  SKIP: {name}.webp (exists)")
        return True

    print(f"  Generating: {name} ...")
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

                img = Image.open(io.BytesIO(part.inline_data.data)).convert("RGB")
                img.save(str(out_path), "WEBP", quality=86, method=6)
                size_kb = out_path.stat().st_size // 1024
                print(f"  OK: {name}.webp ({img.width}x{img.height}, {size_kb}KB)")
                return True

        print(f"  WARN: No image returned for {name}")
        return False

    except Exception as e:
        print(f"  ERROR: {e}")
        return False


def prune_stale():
    """SPLASH_BACKGROUNDS に無い古い .webp (旧 dawn/twilight/cosmic 等) を掃除する。"""
    known = {f"{name}.webp" for name in SPLASH_BACKGROUNDS}
    for p in OUT_DIR.glob("*.webp"):
        if p.name not in known:
            p.unlink()
            print(f"  PRUNED: {p.name} (stale)")


def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else "all"

    if arg == "list":
        for name, prompt in SPLASH_BACKGROUNDS.items():
            print(f"\n[{name}]")
            print(f"  {prompt}")
        return

    if arg == "all":
        targets = list(SPLASH_BACKGROUNDS.items())
    else:
        names = [n.strip() for n in arg.split(",") if n.strip()]
        unknown = [n for n in names if n not in SPLASH_BACKGROUNDS]
        if unknown:
            print(f"Unknown: {', '.join(unknown)}")
            print(f"Valid: {', '.join(SPLASH_BACKGROUNDS.keys())}")
            return
        targets = [(n, SPLASH_BACKGROUNDS[n]) for n in names]

    prune_stale()

    print(f"\n=== Generating {len(targets)} splash backgrounds ===")
    print(f"Output: {OUT_DIR}\n")

    ok = 0
    for name, prompt in targets:
        if generate_one(name, prompt):
            ok += 1
        time.sleep(2)

    print(f"\n=== Done: {ok}/{len(targets)} succeeded ===")


if __name__ == "__main__":
    main()
