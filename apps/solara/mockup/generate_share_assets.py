"""
Generate share card assets for Solara Title System using fal.ai Nanobanana2.

Assets:
  - 12 background images (sun signs, 9:16, 2K)
  - 25 class icons (1:1, 1K)
  - 12 zodiac symbol images (1:1, 1K)
"""

import os
import sys
import time
import urllib.request

import fal_client

# Load API key from .env
ENV_PATH = os.path.join(os.path.dirname(__file__), "..", "..", "..", ".env")
with open(ENV_PATH, "r") as f:
    for line in f:
        line = line.strip()
        if line.startswith("FAL_KEY="):
            os.environ["FAL_KEY"] = line.split("=", 1)[1]
            break

BASE_DIR = os.path.join(os.path.dirname(__file__), "share-assets")

# ─────────────────────────────────────────────────
#  STYLE CONSTANTS
# ─────────────────────────────────────────────────

SOLARA_STYLE = (
    "Dark cosmic mystical atmosphere, deep space background, "
    "subtle starfield, ethereal glow, no text, no letters, no numbers, "
    "no watermark, no signature, painterly digital art, premium quality"
)

# ─────────────────────────────────────────────────
#  1. BACKGROUND IMAGES (12 sun signs)
# ─────────────────────────────────────────────────

SIGN_BACKGROUNDS = {
    "aries": (
        "Blazing fire nebula in deep space, vivid crimson and orange plasma streams, "
        "a ram's horn silhouette formed by cosmic fire, intense energy radiating outward, "
        "volcanic red and amber glow, aggressive dynamic composition, "
        + SOLARA_STYLE
    ),
    "taurus": (
        "Ancient earth and emerald nebula, rich deep green and warm brown cosmic dust, "
        "a majestic bull silhouette formed by golden stardust, grounded and powerful, "
        "fertile soil tones with jade and copper metallic shimmer, "
        + SOLARA_STYLE
    ),
    "gemini": (
        "Two ethereal twin figures facing each other in deep space, mirrored silhouettes "
        "made of silver stardust and electric blue light, connected by swirling ribbons of "
        "cosmic wind between them, duality and communication theme, "
        "mercury-silver and sapphire blue palette, airy and intellectual atmosphere, "
        + SOLARA_STYLE
    ),
    "cancer": (
        "Luminous full moon reflected in a cosmic ocean, pearlescent silver-blue nebula, "
        "a crab silhouette formed by moonlit coral formations, nurturing and protective, "
        "iridescent pearl white and deep ocean blue atmosphere, "
        + SOLARA_STYLE
    ),
    "leo": (
        "Radiant golden sun corona in deep space, majestic lion's mane formed by solar flares, "
        "royal amber and brilliant gold cosmic light, commanding and theatrical, "
        "warm golden rays with purple cosmic background, regal atmosphere, "
        + SOLARA_STYLE
    ),
    "virgo": (
        "Pristine crystal nebula with precise geometric star patterns, "
        "delicate wheat-gold and forest green cosmic dust formations, "
        "a maiden silhouette formed by organized constellation lines, analytical beauty, "
        "muted sage green and warm silver tones, "
        + SOLARA_STYLE
    ),
    "libra": (
        "Perfectly balanced cosmic scales formed by two mirrored nebulae, "
        "rose pink and lavender harmonious gradient, symmetrical composition, "
        "elegant and refined atmosphere, Venus-inspired soft romantic glow, "
        "pastel rose and amethyst purple cosmic dust, "
        + SOLARA_STYLE
    ),
    "scorpio": (
        "Deep abyssal nebula in crimson and dark purple, intense and mysterious, "
        "a scorpion tail silhouette formed by dark matter streams, hidden power, "
        "obsidian black with deep burgundy and violet undertones, transformative energy, "
        + SOLARA_STYLE
    ),
    "sagittarius": (
        "A blazing arrow of light shooting across a vast indigo cosmos, "
        "adventurous and expansive composition with distant galaxies, "
        "Jupiter-inspired deep blue and fiery orange cosmic trail, philosophical wanderlust, "
        + SOLARA_STYLE
    ),
    "capricorn": (
        "Mountain peak piercing through cosmic clouds, dark granite and iron nebula, "
        "a goat silhouette formed by ancient stone and starlight, ambitious and enduring, "
        "slate grey and icy blue with subtle gold highlights, Saturn-inspired authority, "
        + SOLARA_STYLE
    ),
    "aquarius": (
        "Electric blue lightning nebula with futuristic energy patterns, "
        "water-bearer pouring streams of starlight, innovative and revolutionary, "
        "neon cyan and electric blue with ultraviolet accents, Uranus-inspired rebellion, "
        + SOLARA_STYLE
    ),
    "pisces": (
        "Two luminous fish swimming in a dreamy ocean nebula, "
        "soft teal and mystical sea-green cosmic currents, fluid and ethereal, "
        "Neptune-inspired deep ocean blue with bioluminescent accents, transcendent beauty, "
        + SOLARA_STYLE
    ),
}

# ─────────────────────────────────────────────────
#  2. CLASS ICONS (25 classes)
# ─────────────────────────────────────────────────

CLASS_ICON_STYLE = (
    "Single iconic emblem centered on pure black background, "
    "glowing metallic symbol, clean minimal design, "
    "no text, no letters, no border, no frame, "
    "fantasy RPG class crest style, luminous edges"
)

CLASS_ICONS = {
    # Power axis
    "Knight":     "A shield with a single sword, silver and steel glow, protective guardian emblem, " + CLASS_ICON_STYLE,
    "Dragoon":    "A dragon wing and spear crossed, crimson and gold glow, aerial warrior emblem, " + CLASS_ICON_STYLE,
    "Paladin":    "A radiant sun-cross shield, holy white and gold glow, divine protector emblem, " + CLASS_ICON_STYLE,
    "Overlord":   "A crown with crossed scepters, dark gold and iron glow, commanding ruler emblem, " + CLASS_ICON_STYLE,
    "Spellblade": "A sword wrapped in arcane energy spiral, blue and silver glow, magic warrior emblem, " + CLASS_ICON_STYLE,
    # Mind axis
    "Sage":       "An open ancient book with glowing pages, blue and white light, wisdom seeker emblem, " + CLASS_ICON_STYLE,
    "Strategist": "A chess knight piece with geometric lines, silver and blue glow, tactical mind emblem, " + CLASS_ICON_STYLE,
    "Chancellor": "A balanced scale with an all-seeing eye above, gold and blue glow, diplomatic emblem, " + CLASS_ICON_STYLE,
    "Judge":      "A gavel striking with justice lightning, white and silver glow, law and truth emblem, " + CLASS_ICON_STYLE,
    "Wizard":     "A spiraling arcane vortex with a central crystal, deep blue and violet glow, mastery emblem, " + CLASS_ICON_STYLE,
    # Spirit axis
    "Cleric":     "Hands cupped holding a gentle flame, warm white and gold glow, healer emblem, " + CLASS_ICON_STYLE,
    "Astrologer": "A celestial armillary sphere with orbiting stars, purple and gold glow, stargazer emblem, " + CLASS_ICON_STYLE,
    "Oracle":     "A third eye with cosmic iris radiating light, indigo and silver glow, seer emblem, " + CLASS_ICON_STYLE,
    "Fate_Weaver":"A spinning wheel with interwoven golden threads, amber and purple glow, destiny emblem, " + CLASS_ICON_STYLE,
    "Druid":      "A tree of life with roots and branches forming a circle, green and earth-brown glow, nature emblem, " + CLASS_ICON_STYLE,
    # Shadow axis
    "Trickster":  "A jester's mask split in two with a mischievous grin, purple and green glow, chaos emblem, " + CLASS_ICON_STYLE,
    "Liberator":  "Broken chains with a rising phoenix feather, orange and red glow, freedom emblem, " + CLASS_ICON_STYLE,
    "Phantom":    "A hooded figure dissolving into smoke wisps, dark blue and grey glow, stealth emblem, " + CLASS_ICON_STYLE,
    "Rogue":      "Twin crossed daggers with a shadow aura, dark silver and violet glow, independence emblem, " + CLASS_ICON_STYLE,
    "Alchemist":  "A bubbling alchemical flask with transmutation circle, green and gold glow, transformation emblem, " + CLASS_ICON_STYLE,
    # Heart axis
    "Bard":       "A lyre with sound waves radiating outward, warm gold and rose glow, music and joy emblem, " + CLASS_ICON_STYLE,
    "Sorcerer":   "A heart-shaped flame with raw magical energy, crimson and pink glow, emotion power emblem, " + CLASS_ICON_STYLE,
    "Enchanter":  "A glowing rose with mesmerizing spiral petals, pink and gold glow, charm emblem, " + CLASS_ICON_STYLE,
    "Emperor":    "A throne with a radiating heart-crown, royal purple and gold glow, charisma emblem, " + CLASS_ICON_STYLE,
    "Chronomancer":"An hourglass with swirling time-sand galaxies, blue and amber glow, time-keeper emblem, " + CLASS_ICON_STYLE,
}

# ─────────────────────────────────────────────────
#  3. ZODIAC SYMBOLS (12 signs)
# ─────────────────────────────────────────────────

ZODIAC_STYLE = (
    "Single zodiac glyph symbol centered on pure black background, "
    "glowing celestial energy, elegant calligraphic astrology symbol, "
    "no text, no letters, no border, luminous ethereal edges, "
    "minimal composition, mystical golden light"
)

ZODIAC_SYMBOLS = {
    "aries":       "The Aries zodiac glyph (ram horns V shape), fiery red and gold glow, " + ZODIAC_STYLE,
    "taurus":      "The Taurus zodiac glyph (circle with horns), earthy green and copper glow, " + ZODIAC_STYLE,
    "gemini":      "The Gemini zodiac glyph (Roman numeral II shape), silver and blue glow, " + ZODIAC_STYLE,
    "cancer":      "The Cancer zodiac glyph (69 sideways shape), pearlescent white and blue glow, " + ZODIAC_STYLE,
    "leo":         "The Leo zodiac glyph (lion tail curl), golden and amber glow, " + ZODIAC_STYLE,
    "virgo":       "The Virgo zodiac glyph (M with tail), sage green and silver glow, " + ZODIAC_STYLE,
    "libra":       "The Libra zodiac glyph (balanced scales line), rose pink and lavender glow, " + ZODIAC_STYLE,
    "scorpio":     "The Scorpio zodiac glyph (M with arrow tail), deep crimson and purple glow, " + ZODIAC_STYLE,
    "sagittarius": "The Sagittarius zodiac glyph (arrow pointing up-right), indigo and orange glow, " + ZODIAC_STYLE,
    "capricorn":   "The Capricorn zodiac glyph (V with curled tail), dark grey and icy blue glow, " + ZODIAC_STYLE,
    "aquarius":    "The Aquarius zodiac glyph (two wavy lines), electric cyan and blue glow, " + ZODIAC_STYLE,
    "pisces":      "The Pisces zodiac glyph (two arcs with line), teal and sea-green glow, " + ZODIAC_STYLE,
}


def generate_image(prompt, output_path, aspect_ratio="9:16", resolution="2K"):
    """Generate a single image using fal.ai Nanobanana2."""
    if os.path.exists(output_path):
        print(f"  SKIP (exists): {output_path}")
        return True

    print(f"  Generating: {os.path.basename(output_path)} ...")
    try:
        result = fal_client.subscribe(
            "fal-ai/nano-banana-2",
            arguments={
                "prompt": prompt,
                "resolution": resolution,
                "aspect_ratio": aspect_ratio,
                "output_format": "png",
                "num_images": 1,
            },
        )
        images = result.get("images", [])
        if not images:
            print(f"  ERROR: No images returned for {output_path}")
            return False

        url = images[0]["url"]
        urllib.request.urlretrieve(url, output_path)
        print(f"  OK: {output_path} ({images[0].get('width', '?')}x{images[0].get('height', '?')})")
        return True

    except Exception as e:
        print(f"  ERROR: {e}")
        return False


def generate_backgrounds():
    print("\n=== Generating 12 Background Images (9:16, 2K) ===\n")
    out_dir = os.path.join(BASE_DIR, "backgrounds")
    for sign, prompt in SIGN_BACKGROUNDS.items():
        path = os.path.join(out_dir, f"{sign}.png")
        generate_image(prompt, path, aspect_ratio="9:16", resolution="2K")
        time.sleep(2)


def generate_class_icons():
    print("\n=== Generating 25 Class Icons (1:1, 1K) ===\n")
    out_dir = os.path.join(BASE_DIR, "class-icons")
    for cls_name, prompt in CLASS_ICONS.items():
        filename = cls_name.lower().replace(" ", "_")
        path = os.path.join(out_dir, f"{filename}.png")
        generate_image(prompt, path, aspect_ratio="1:1", resolution="1K")
        time.sleep(2)


def generate_zodiac_symbols():
    print("\n=== Generating 12 Zodiac Symbols (1:1, 1K) ===\n")
    out_dir = os.path.join(BASE_DIR, "zodiac-symbols")
    for sign, prompt in ZODIAC_SYMBOLS.items():
        path = os.path.join(out_dir, f"{sign}.png")
        generate_image(prompt, path, aspect_ratio="1:1", resolution="1K")
        time.sleep(2)


def main():
    what = sys.argv[1] if len(sys.argv) > 1 else "all"

    if what in ("all", "bg", "backgrounds"):
        generate_backgrounds()
    if what in ("all", "icons", "class"):
        generate_class_icons()
    if what in ("all", "zodiac", "symbols"):
        generate_zodiac_symbols()

    print("\n=== Done! ===")


if __name__ == "__main__":
    main()
