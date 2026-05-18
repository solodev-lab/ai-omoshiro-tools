"""
Generate 'bright {zodiac}' background variations for the catasterism finale
using nano-banana-pro-preview via Gemini API (free tier).

Prompt structure mirrors share-assets/backgrounds_original generator
(generate_share_assets.py SIGN_BACKGROUNDS lines 42-118):
  "{nebula} in deep space, {streams},
   {silhouette} formed by cosmic {material},
   intense energy radiating outward, {glow},
   {mood} composition, " + SOLARA_STYLE

Symbol is VISIBLE — unlike scorpio_bright which softens scorpion shape for
fear-avoidance, the other 11 zodiacs show the creature/figure clearly,
matching the high-detail atmospheric look of backgrounds_original/.

10 adjective-pair color themes × 11 visible zodiacs (12 minus scorpio).

Output: share-assets/backgrounds_{zodiac}_bright/bright_{color}_{zodiac}.png

Usage:
  python generate_zodiac_bright.py aries
  python generate_zodiac_bright.py aries golden,crimson
  python generate_zodiac_bright.py aries list
  python generate_zodiac_bright.py list
"""
import os
import sys
import time
import io
from pathlib import Path


def _find_env_file() -> "Path | None":
    here = Path(__file__).resolve()
    for parent in [here.parent, *here.parents]:
        candidate = parent / ".env"
        if candidate.exists():
            return candidate
    return None


_env = _find_env_file()
if _env is not None:
    for line in _env.read_text(encoding="utf-8").splitlines():
        if "=" in line and not line.startswith("#"):
            key, val = line.split("=", 1)
            os.environ.setdefault(key.strip(), val.strip())


# === Common style trailer — mirrors SOLARA_STYLE in generate_share_assets.py ===
# Same string + explicit 9:16 (nano-banana-pro doesn't take aspect_ratio param).
SOLARA_STYLE = (
    "Dark cosmic mystical atmosphere, deep space background, subtle starfield, "
    "ethereal glow, no text, no letters, no numbers, no watermark, no signature, "
    "painterly digital art, premium quality. Vertical 9:16 portrait orientation."
)


# === Per-color palette (nebula / streams / material / glow) ===
# `material` is the SHORT noun phrase used in "silhouette formed by cosmic {material}"
# (matches the FAL-original phrasing pattern: "cosmic fire", "cosmic gold", etc.).
COLORS = {
    "golden": {
        "nebula": "Radiant golden nebula",
        "streams": "brilliant gold and amber plasma streams",
        "material": "gold",
        "glow": "warm amber and gold glow",
    },
    "silver": {
        "nebula": "Moonlit silver nebula",
        "streams": "pearlescent silver plasma streams",
        "material": "silver light",
        "glow": "soft silver and pale blue glow",
    },
    "crimson": {
        "nebula": "Blazing fire nebula",
        "streams": "vivid crimson and orange plasma streams",
        "material": "fire",
        "glow": "volcanic red and amber glow",
    },
    "ethereal": {
        "nebula": "Pale blue-white spirit nebula",
        "streams": "ghostly spectral plasma streams",
        "material": "spectral light",
        "glow": "soft phantasmal pale blue glow",
    },
    "mystic": {
        "nebula": "Violet sacred nebula",
        "streams": "amethyst purple plasma streams",
        "material": "violet light",
        "glow": "deep amethyst and violet glow",
    },
    "silent": {
        "nebula": "Misty silver-grey nebula",
        "streams": "subdued cool grey starlight streams",
        "material": "muted starlight",
        "glow": "serene silver-grey glow",
    },
    "frozen": {
        "nebula": "Icy crystalline nebula",
        "streams": "blue-white frost light streams",
        "material": "ice and frost",
        "glow": "arctic blue-white glow",
    },
    "ancient": {
        "nebula": "Emerald crystalline nebula",
        "streams": "green and gold sacred light streams",
        "material": "emerald light",
        "glow": "primordial verdant and gold glow",
    },
    "infinite": {
        "nebula": "Brilliant white sacred geometry nebula",
        "streams": "dazzling white and gold transcendent light streams",
        "material": "celestial white light",
        "glow": "transcendent white-gold glow",
    },
    "radiant": {
        "nebula": "Rainbow prismatic nebula",
        "streams": "multicolored iridescent light streams",
        "material": "rainbow light",
        "glow": "dazzling spectral glow",
    },
}


# === Per-zodiac (silhouette, mood) ===
# `silhouette` is the noun phrase that follows "[X] silhouette formed by cosmic
# {material}". Echoes generate_share_assets.py SIGN_BACKGROUNDS forms.
# `mood` is the composition descriptor (no "intense", that's in template).
ZODIAC_DATA = {
    "aries": (
        "a ram with two large spiraling horns silhouette amid swirling blazing flames and floating stardust",
        "aggressive dynamic",
    ),
    "taurus": (
        "a majestic bull's head with powerful curving horns silhouette rising from an ancient earthen nebula with floating mineral crystals",
        "grounded powerful",
    ),
    "gemini": (
        "two ethereal twin figures facing each other with mirrored silhouettes connected by swirling ribbons of cosmic wind",
        "airy intellectual",
    ),
    "cancer": (
        "a crab silhouette with raised pincers floating above a glowing cosmic ocean that reflects a luminous full moon, surrounded by moonlit coral formations",
        "nurturing protective",
    ),
    "leo": (
        "a lion's head with majestic flowing mane silhouette amid a radiant solar corona with brilliant solar flares",
        "regal commanding",
    ),
    "virgo": (
        "a graceful maiden silhouette holding a sheaf of glowing stardust wheat in a crystalline field with floating geometric star patterns",
        "graceful analytical",
    ),
    "libra": (
        "perfectly balanced cosmic scales silhouette suspended between two mirrored swirling nebulae",
        "elegant balanced",
    ),
    "sagittarius": (
        "a centaur archer with drawn bow silhouette aiming a glowing arrow toward distant galaxies and star clusters",
        "expansive adventurous",
    ),
    # Capricorn: NO fish tail. Mountain goat on stone peak (matches
    # backgrounds_original SIGN_BACKGROUNDS["capricorn"] which used
    # "ancient stone and starlight" with mountain peak imagery).
    "capricorn": (
        "a majestic mountain goat with long spiraling horns silhouette standing atop a cosmic stone mountain peak, surrounded by floating ancient rocks and granite formations",
        "ambitious enduring",
    ),
    "aquarius": (
        "a water-bearer figure silhouette pouring cascading streams of starlight from an ornate urn into the cosmic void, with electric energy patterns around",
        "innovative futuristic",
    ),
    "pisces": (
        "two fish silhouettes swimming in opposing circular flow through a dreamy luminous ocean nebula",
        "fluid dreamlike",
    ),
}


def build_prompt(zodiac: str, color: str) -> str:
    palette = COLORS[color]
    silhouette, mood = ZODIAC_DATA[zodiac]
    return (
        f"{palette['nebula']} in deep space, {palette['streams']}, "
        f"{silhouette} formed by cosmic {palette['material']}, "
        f"intense energy radiating outward, {palette['glow']}, "
        f"{mood} composition, "
        + SOLARA_STYLE
    )


def generate_one(zodiac: str, color: str, out_dir: Path, max_retries: int = 3) -> bool:
    out_path = out_dir / f"bright_{color}_{zodiac}.png"
    if out_path.exists():
        print(f"  SKIP: bright_{color}_{zodiac}.png (exists)")
        return True

    prompt = build_prompt(zodiac, color)

    for attempt in range(1, max_retries + 1):
        label = f"bright_{color}_{zodiac}" + (f" (retry {attempt})" if attempt > 1 else "")
        print(f"  Generating: {label} ...", flush=True)
        try:
            from google import genai
            from google.genai import types

            api_key = os.environ.get("GEMINI_API_KEY")
            if not api_key:
                print("  ERROR: GEMINI_API_KEY not set in .env")
                return False

            client = genai.Client(api_key=api_key)
            response = client.models.generate_content(
                model="models/nano-banana-pro-preview",
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_modalities=["IMAGE"],
                ),
            )
            if response.candidates and response.candidates[0].content.parts:
                for part in response.candidates[0].content.parts:
                    if part.inline_data and part.inline_data.data:
                        from PIL import Image

                        img = Image.open(io.BytesIO(part.inline_data.data))
                        img.save(str(out_path), "PNG")
                        size_kb = out_path.stat().st_size // 1024
                        print(f"  OK: bright_{color}_{zodiac}.png ({img.width}x{img.height}, {size_kb}KB)", flush=True)
                        return True

            print(f"  WARN: No image returned for {color}_{zodiac}", flush=True)

        except Exception as e:
            msg = str(e)
            print(f"  ERROR ({attempt}/{max_retries}): {msg[:160]}", flush=True)
            if "503" in msg or "UNAVAILABLE" in msg or "Deadline" in msg:
                wait = 30 * attempt
                print(f"  Waiting {wait}s before retry...", flush=True)
                time.sleep(wait)
                continue
            else:
                return False

    print(f"  FAIL: {color}_{zodiac} after {max_retries} retries", flush=True)
    return False


def main():
    args = sys.argv[1:]

    if not args or args[0] == "list":
        print("Available zodiacs:")
        for z in ZODIAC_DATA:
            print(f"  {z}")
        print(f"\nAvailable colors: {', '.join(COLORS.keys())}")
        print("\nUsage:")
        print("  python generate_zodiac_bright.py <zodiac>")
        print("  python generate_zodiac_bright.py <zodiac> <c1,c2,...>")
        print("  python generate_zodiac_bright.py <zodiac> list")
        return

    zodiac = args[0]
    if zodiac not in ZODIAC_DATA:
        print(f"Unknown zodiac: {zodiac}")
        print(f"Valid: {', '.join(ZODIAC_DATA.keys())}")
        return

    colors_arg = args[1] if len(args) > 1 else "all"

    if colors_arg == "list":
        for c in COLORS:
            p = build_prompt(zodiac, c)
            print(f"\n[bright_{c}_{zodiac}]")
            print(f"  {p}")
        return

    if colors_arg == "all":
        colors = list(COLORS.keys())
    else:
        colors = [c.strip() for c in colors_arg.split(",")]
        bad = [c for c in colors if c not in COLORS]
        if bad:
            print(f"Unknown color(s): {bad}")
            print(f"Valid: {', '.join(COLORS.keys())}")
            return

    out_dir = Path(__file__).parent / "share-assets" / f"backgrounds_{zodiac}_bright"
    out_dir.mkdir(parents=True, exist_ok=True)

    print(f"\n=== Generating {len(colors)} bright {zodiac} variants ===")
    print(f"Output: {out_dir}\n")

    ok = 0
    for i, color in enumerate(colors):
        if generate_one(zodiac, color, out_dir):
            ok += 1
        if i < len(colors) - 1:
            time.sleep(10)

    print(f"\n=== Done: {ok}/{len(colors)} succeeded ===")


if __name__ == "__main__":
    main()
