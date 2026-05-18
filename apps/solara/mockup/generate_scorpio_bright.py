"""
Generate 'bright scorpio' variations with a dreamlike phantasmal scorpion form
softly emerging from the nebula. 10 adjective-pair color themes.
Auto-retry on 503.

Key design: the scorpion shape IS visible (recognizable anatomy) but rendered
softly/ghostly/translucent so it never feels threatening. The scorpion itself
takes on the adjective pair's color theme.

Usage:
  python generate_scorpio_bright.py                # all 10
  python generate_scorpio_bright.py golden,crimson # specific
  python generate_scorpio_bright.py list           # show prompts
"""
import os
import sys
import time
import io
from pathlib import Path

env_path = Path(__file__).resolve().parents[3] / ".env"
if env_path.exists():
    for line in env_path.read_text(encoding="utf-8").splitlines():
        if "=" in line and not line.startswith("#"):
            key, val = line.split("=", 1)
            os.environ.setdefault(key.strip(), val.strip())

# Common style v1.7 — tail = single subtle swirl (v1.6 level),
# claws = two soft visible pincer curves (v1.5 level, slightly more defined).
# NO body, NO legs, NO head, NO segments, NO eyes — only these 3 gas formations.
COMMON_STYLE = (
    "Vertical 9:16 portrait orientation, tall vertical cosmic scene. "
    "The image is primarily a beautiful abstract cosmic nebula filling the entire frame — "
    "swirling cosmic gas, stardust patterns, luminous clouds. "
    "ABSOLUTELY NO scorpion body, NO legs, NO head, NO eyes, NO body segments — "
    "ZERO body anatomy must be visible. "
    "Within the nebula, exactly THREE separate cosmic gas formations naturally emerge: "
    "(1) In the upper area, ONE single elegant curling swirl of cosmic gas — "
    "a graceful spiral curve like the curl of a scorpion's tail, soft and integrated into the mist. "
    "(2) and (3) In the lower or side areas, TWO soft curved pincer-shaped swirls of cosmic gas — "
    "each forming a graceful forked claw curve, slightly more defined than the tail swirl "
    "but still rendered as glowing cosmic gas with soft dissolved edges. "
    "These two claw swirls are recognizable as pincer shapes when pointed out, "
    "but still emerge organically from the nebula, not drawn as solid objects. "
    "ABSOLUTELY NO connecting body between the tail and claws — "
    "the three formations float independently within the abstract nebula with empty space between them. "
    "NO legs, NO body segments anywhere — just three floating gas curves: one tail spiral + two pincer curves. "
    "Soft dissolved edges throughout, no sharp lines, no anatomy beyond these three curves. "
    "A casual viewer sees an abstract nebula with three elegant cosmic swirls. "
    "When told 'this is scorpio', the viewer notices the two pincer curves easily "
    "and finds the tail swirl after a moment of looking. "
    "No text, no letters, no numbers, no watermark, no signature, no border, no frame. "
    "Painterly digital art, premium quality, cinematic lighting, ethereal mystical atmosphere."
)

# Key = adjective-pair shorthand → filename: bright_{key}_scorpio.png
PROMPTS = {
    "golden": (
        "A luminous golden nebula filling deep space — swirling warm gold and amber cosmic gas, "
        "brilliant stardust patterns, intricate sacred geometry grid lines shimmering softly, "
        "glowing celestial mist with warm amber radiance throughout. "
        + COMMON_STYLE
    ),
    "silver": (
        "A moonlit silver-blue nebula with cascading streams of pearlescent silver light "
        "flowing through deep space, ethereal silvery stardust, soft luminous shimmer. "
        "Hidden within the flowing patterns, only the faintest pareidolia-like hint "
        "of a curved scorpion tail and body shape can be barely discerned. "
        + COMMON_STYLE
    ),
    "crimson": (
        "A vibrant flame nebula filling deep space — brilliant red and orange cosmic gas streams, "
        "glowing crimson embers, fiery sparks scattered across the scene, swirling flame-like "
        "cosmic mist with brilliant red radiance throughout. "
        + COMMON_STYLE
    ),
    "ethereal": (
        "A pale blue-white spirit nebula filling deep space, ghostly luminous streams of "
        "spectral light flowing through ethereal mist, translucent shimmer, soft phantasmal glow. "
        "Hidden within the misty patterns, only the faintest pareidolia-like hint "
        "of a curved scorpion tail and body shape can be barely discerned. "
        + COMMON_STYLE
    ),
    "mystic": (
        "A violet sacred nebula filling deep space, intricate purple sacred geometry lattice, "
        "amethyst stardust swirling, brilliant violet and deep purple glow, mystical light patterns. "
        "Hidden within the geometric patterns, only the faintest pareidolia-like hint "
        "of a curved scorpion tail and body shape can be barely discerned. "
        + COMMON_STYLE
    ),
    "silent": (
        "A misty crystalline nebula filling deep space with soft subdued silver-grey luminous light, "
        "gentle cosmic veil, muted shimmer through cosmic mist, serene contemplative glow. "
        "Hidden within the misty patterns, only the faintest pareidolia-like hint "
        "of a curved scorpion tail and body shape can be barely discerned. "
        + COMMON_STYLE
    ),
    "frozen": (
        "An icy crystalline nebula filling deep space, brilliant blue-white frost lattice, "
        "ice crystal patterns scattered across the cosmic scene, arctic luminous glow. "
        "Hidden within the frost patterns, only the faintest pareidolia-like hint "
        "of a curved scorpion tail and body shape can be barely discerned. "
        + COMMON_STYLE
    ),
    "ancient": (
        "An emerald crystalline nebula filling deep space, brilliant green and warm gold light, "
        "sacred forest luminescence filtering through space, emerald stardust, primordial glow. "
        "Hidden within the verdant patterns, only the faintest pareidolia-like hint "
        "of a curved scorpion tail and body shape can be barely discerned. "
        + COMMON_STYLE
    ),
    "infinite": (
        "A brilliant white sacred geometry nebula filling deep space, radiant luminous grid extending forever, "
        "dazzling white and gold light, transcendent starlight, celestial cosmic patterns. "
        "Hidden within the radiant patterns, only the faintest pareidolia-like hint "
        "of a curved scorpion tail and body shape can be barely discerned. "
        + COMMON_STYLE
    ),
    "radiant": (
        "A rainbow prismatic nebula filling deep space, multicolored iridescent cascading streams, "
        "dazzling spectral glow, rainbow stardust scattered across the cosmic scene. "
        "Hidden within the prismatic patterns, only the faintest pareidolia-like hint "
        "of a curved scorpion tail and body shape can be barely discerned. "
        + COMMON_STYLE
    ),
}

OUT_DIR = Path(__file__).parent / "share-assets" / "backgrounds_scorpio_bright"
OUT_DIR.mkdir(parents=True, exist_ok=True)


def generate_one(key, prompt, max_retries=3):
    out_path = OUT_DIR / f"bright_{key}_scorpio.png"
    if out_path.exists():
        print(f"  SKIP: bright_{key}_scorpio.png (exists)")
        return True

    for attempt in range(1, max_retries + 1):
        label = f"bright_{key}_scorpio" + (f" (retry {attempt})" if attempt > 1 else "")
        print(f"  Generating: {label} ...")
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
                    img = Image.open(io.BytesIO(part.inline_data.data))
                    img.save(str(out_path), "PNG")
                    size_kb = out_path.stat().st_size // 1024
                    print(f"  OK: bright_{key}_scorpio.png ({img.width}x{img.height}, {size_kb}KB)")
                    return True

            print(f"  WARN: No image returned for {key}")

        except Exception as e:
            msg = str(e)
            print(f"  ERROR ({attempt}/{max_retries}): {msg[:120]}")
            if "503" in msg or "UNAVAILABLE" in msg or "Deadline" in msg:
                wait = 30 * attempt
                print(f"  Waiting {wait}s before retry...")
                time.sleep(wait)
                continue
            else:
                return False

    print(f"  FAIL: {key} after {max_retries} retries")
    return False


def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else "all"

    if arg == "list":
        for key, prompt in PROMPTS.items():
            print(f"\n[bright_{key}_scorpio]")
            print(f"  {prompt[:120]}...")
        return

    if arg == "all":
        targets = list(PROMPTS.items())
    elif "," in arg:
        names = [s.strip() for s in arg.split(",")]
        targets = [(n, PROMPTS[n]) for n in names if n in PROMPTS]
    elif arg in PROMPTS:
        targets = [(arg, PROMPTS[arg])]
    else:
        print(f"Unknown key: {arg}")
        print(f"Valid: {', '.join(PROMPTS.keys())}")
        return

    print(f"\n=== Generating {len(targets)} scorpio_bright variants ===")
    print(f"Output: {OUT_DIR}\n")

    ok = 0
    for key, prompt in targets:
        if generate_one(key, prompt):
            ok += 1
        time.sleep(10)

    print(f"\n=== Done: {ok}/{len(targets)} succeeded ===")


if __name__ == "__main__":
    main()
