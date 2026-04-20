"""
Generate 3 realistic shooting star / meteor images on pure black.
- 16:9 landscape, 1376x768
- Diagonal streak, long glowing tail
- Pure black background (will be alpha-keyed)

Usage:
  python generate_tarot_shooting_stars.py            # all 3
  python generate_tarot_shooting_stars.py short      # single
  python generate_tarot_shooting_stars.py --force
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

COMMON = (
    " PURE SOLID BLACK background (#000000), NO stars in background, "
    "NO nebula, NO planets, NO text, NO labels. "
    "Cinematic astronomy photograph quality, ultra sharp, high detail, "
    "photorealistic. 16:9 landscape composition."
)

METEORS = {
    "short": (
        "A single realistic shooting star / meteor as a bright glowing head "
        "with a SHORT compact tail, the streak going diagonally from "
        "upper-right to lower-left, bright white-gold core fading through "
        "warm amber to deep orange at the tail tip, subtle spark particles "
        "along the trail, streak occupies about 40% of the frame width."
        + COMMON
    ),
    "mid": (
        "A single realistic shooting star / meteor streak going diagonally "
        "from upper-right to lower-left, MEDIUM LENGTH tail with smooth "
        "gradient from bright white-gold head through warm amber into deep "
        "orange fading to transparent black, delicate sparkle particles "
        "scattered along the trail, streak occupies about 65% of the frame width."
        + COMMON
    ),
    "long": (
        "A single realistic shooting star / meteor with LONG dramatic tail "
        "streaking from upper-right corner to lower-left corner, brilliant "
        "white-hot head with ionized blue-white leading edge, graceful long "
        "trailing tail fading from gold through amber to deep red-orange and "
        "into darkness, glowing sparks, cosmic fireball, streak spans nearly "
        "the full frame diagonal."
        + COMMON
    ),
}

OUT_DIR = Path(__file__).parent / "share-assets" / "tarot_scene" / "shooting_stars"
OUT_DIR.mkdir(parents=True, exist_ok=True)


def generate_one(name, prompt, force=False):
    out_path = OUT_DIR / f"meteor_{name}.png"
    if out_path.exists() and not force:
        print(f"  SKIP: meteor_{name}.png (exists)")
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

    print(f"  Generating: meteor_{name} ...")
    client = genai.Client(api_key=api_key)
    try:
        response = client.models.generate_content(
            model="gemini-3.1-flash-image-preview",
            contents=[prompt],
            config=types.GenerateContentConfig(
                response_modalities=["TEXT", "IMAGE"],
                image_config=types.ImageConfig(aspect_ratio="16:9"),
            ),
        )
        for part in response.parts:
            if part.inline_data is not None:
                img = Image.open(io.BytesIO(part.inline_data.data))
                img.save(str(out_path), "PNG")
                size_kb = out_path.stat().st_size // 1024
                print(f"  OK: meteor_{name}.png ({img.width}x{img.height}, {size_kb}KB)")
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

    if args:
        targets = [(a, METEORS[a]) for a in args if a in METEORS]
        if not targets:
            print(f"Valid: {', '.join(METEORS.keys())}")
            return
    else:
        targets = list(METEORS.items())

    print(f"=== Generating {len(targets)} shooting stars (16:9) ===")
    print(f"Output: {OUT_DIR}\n")
    ok = 0
    for name, prompt in targets:
        if generate_one(name, prompt, force=force):
            ok += 1
        time.sleep(2)
    print(f"\n=== Done: {ok}/{len(targets)} succeeded ===")


if __name__ == "__main__":
    main()
