"""
Generate constellation illustration art using Gemini (free).
Style: White line art on black background, 512x512.
All prompts aligned to NOUN_TEMPLATES orientations in galaxy.html.

Usage:
  python generate_constellation_art.py          # all 61
  python generate_constellation_art.py 0-5      # range
  python generate_constellation_art.py 19       # single (Arrow)
  python generate_constellation_art.py list      # show all nouns
"""
import os
import sys
import time
from pathlib import Path

env_path = Path(__file__).resolve().parents[3] / ".env"
if env_path.exists():
    for line in env_path.read_text(encoding="utf-8").splitlines():
        if "=" in line and not line.startswith("#"):
            key, val = line.split("=", 1)
            os.environ.setdefault(key.strip(), val.strip())

STYLE = (
    "White line art illustration on pure black background. "
    "Elegant, detailed linework with fine white contours only. No color, no fill, only white lines and subtle white shading on black. "
    "Ethereal, celestial, mystical atmosphere like a constellation guide book illustration. "
    "No text, no letters, no numbers, no watermark. "
    "Semi-transparent feeling, delicate strokes, astronomical art style. "
    "Square 512x512 composition, subject centered."
)

# All 61 nouns with orientation-matched prompts
# Format: (index, filename, prompt_description)
NOUNS = [
    # === 天体・宇宙 ===
    (0, "orbit", "Concentric elliptical orbital rings viewed slightly from above, centered in frame"),
    (1, "comet", "A comet with bright nucleus at upper-right, long glowing tail streaming to lower-left"),
    (2, "meteor", "A meteor streaking diagonally from lower-left to upper-right, with trail of sparks behind it"),
    (3, "nova", "An exploding star at center radiating brilliant light beams outward in all directions symmetrically"),
    (4, "crescent", "A crescent moon opening to the RIGHT side, with detailed crater texture on the lit surface, dark side on left"),
    (5, "singularity", "A point of infinite density at center warping space-time, gravitational lensing pulling surrounding matter inward from all directions"),

    # === 神話の生き物 ===
    (6, "phoenix", "A phoenix bird with wings spread wide, head at top center, wing tips extending left and right, tail feathers flowing downward"),
    (7, "dragon", "A serpentine dragon with head at upper-RIGHT, body curving in S-shape flowing to lower-left, wings suggested"),
    (8, "griffin", "A griffin with eagle head at upper-RIGHT looking left, lion body flowing to lower-left, wings spread"),
    (9, "unicorn", "A unicorn in profile facing RIGHT, horn pointing upper-right, body flowing diagonally to lower-left"),
    (10, "pegasus", "A winged horse with body at center, large wings spread wide to left and right, head at top"),
    (11, "kraken", "A kraken viewed from above, central body with tentacles radiating outward in all directions"),
    (12, "ouroboros", "A serpent biting its own tail forming a complete circle, head at top consuming tail"),

    # === 動物・鳥 → 混合 ===
    (13, "serpent", "A snake with head at upper-RIGHT, body undulating in S-curves flowing to lower-left"),
    (14, "trident", "A trident weapon pointing UPWARD, three prongs at top spreading slightly, long shaft going down, centered"),
    (15, "anchor", "A nautical anchor, ring at TOP center, vertical shaft going down, curved flukes (hooks) at BOTTOM spreading left and right"),
    (16, "bow", "An archery bow oriented horizontally, curved arc bowing UPWARD, string connecting the two endpoints at left and right"),
    (17, "butterfly", "A butterfly viewed from above with wings spread symmetrically, body at center, left wing mirroring right wing"),
    (18, "leviathan", "A massive sea creature with head at upper-RIGHT, body arcing in a great curve to lower-left, emerging from water"),

    # === 武器・道具 ===
    (19, "arrow", "A single arrow flying diagonally from lower-left to upper-right, arrowhead pointing upper-right, fletching at lower-left"),
    (20, "sword", "A sword pointing UPWARD, sharp blade tip at top, straight blade going down, short crossguard (横鍔) at LOWER third of blade, handle and pommel at very bottom"),
    (21, "shield", "A heraldic shield with flat top edge and pointed bottom, ornate surface decoration, centered"),
    (22, "key", "An ornate key, decorative bow (ring) at TOP, long shaft going DOWN, teeth/wards at the BOTTOM right"),
    (23, "lantern", "A hanging lantern, hook at TOP, diamond-shaped glass body in center, base at bottom, light glowing from within"),
    (24, "excalibur", "A legendary long sword pointing UPWARD, narrow blade at top, wide ornate crossguard at LOWER portion, jeweled handle at bottom"),

    # === 王権・宝物 ===
    (25, "crown", "A royal crown with three pointed peaks at TOP, curved band at BOTTOM, jewels on the band, centered"),
    (26, "chalice", "A ceremonial chalice/goblet, wide cup opening at TOP, narrowing to a thin stem, flat base at BOTTOM, centered"),
    (27, "throne", "An ornate throne, tall decorative backrest at TOP, seat in middle, legs at BOTTOM, viewed from front"),
    (28, "scepter", "A royal scepter vertical, ornate orb/jewel at TOP, long shaft going DOWN, centered"),
    (29, "jewel", "A brilliant cut gemstone, diamond shape with facets, pointed at top and bottom, centered, radiating light"),
    (30, "philosophers_stone", "An alchemical symbol: a triangle inscribed in a circle with a horizontal line through center, mystical glow"),

    # === 自然・植物 ===
    (31, "flame", "A single flame, narrow base at BOTTOM center, flickering tongues of fire rising UPWARD, widening then tapering at top"),
    (32, "tempest", "A swirling storm vortex viewed from the side, spiral winds rotating, center of storm at middle"),
    (33, "pyramid", "An Egyptian pyramid with sharp apex at TOP center, two sloping sides meeting at a flat base at BOTTOM"),
    (34, "ember", "Scattered glowing embers and sparks, densest at BOTTOM, floating and rising UPWARD, dispersing at top"),
    (35, "glacier", "A mountain glacier ridge stretching horizontally from LEFT to RIGHT, jagged ice peaks along the top"),
    (36, "yggdrasil", "The world tree Yggdrasil, trunk vertical at center, branches spreading left and right at TOP, roots spreading left and right at BOTTOM"),

    # === 建造物・場所 ===
    (37, "gate", "A grand archway gate, two pillars on left and right rising from BOTTOM, connected by an arch at TOP, doorway open in center"),
    (38, "tower", "A tall narrow tower, spire at TOP center, slightly wider at BOTTOM, viewed straight on"),
    (39, "lighthouse", "A lighthouse, narrow top with beacon light glowing at TOP, tower widening slightly toward BOTTOM, light rays emanating from top"),
    (40, "citadel", "A fortified castle with multiple towers and battlements, tallest towers at left and right of center near TOP, walls at BOTTOM"),
    (41, "babel", "The Tower of Babel, narrow top tier at TOP, progressively wider tiers stepping down to wide base at BOTTOM"),

    # === 象徴・紋章 ===
    (42, "emblem", "A hexagonal heraldic emblem/crest, six-sided symmetrical shape with ornate detailing inside, centered"),
    (43, "mirror", "An ornate hand mirror, oval reflective surface at TOP, decorative handle extending DOWN to BOTTOM"),
    (44, "hourglass", "An hourglass, upper triangle chamber at TOP, narrow pinch at CENTER, lower triangle chamber at BOTTOM, sand flowing"),
    (45, "scale", "A balance scale, fulcrum/pivot point at TOP center, horizontal beam, two hanging pans at lower-LEFT and lower-RIGHT"),
    (46, "mask", "A theatrical or ceremonial mask viewed from FRONT, oval face shape, two eye holes, centered, mysterious expression"),
    (47, "pandora", "Pandora's box, a rectangular chest with lid slightly open at TOP, wisps of energy escaping upward, box body at BOTTOM"),

    # === 楽器・芸術 ===
    (48, "harp", "A standing harp, curved neck at TOP-LEFT, pillar on LEFT side, soundboard at BOTTOM, strings stretching from left frame to right"),
    (49, "bell", "A large temple bell, attachment point at TOP center, dome curving outward, wide flared rim at BOTTOM"),
    (50, "lyre", "A lyre instrument, two curved arms rising from BOTTOM spreading outward and meeting crossbar near TOP, strings between arms"),
    (51, "compass", "A compass rose, NORTH point at top, SOUTH at bottom, EAST at right, WEST at left, ornate circular border, directional star in center"),

    # === 身体・翼 ===
    (52, "wing", "A single large feathered wing, attached at lower-LEFT, spreading and fanning out to upper-RIGHT, detailed individual feathers"),
    (53, "feather", "A single feather, quill tip at BOTTOM, shaft running diagonally up to upper-right, barbs on both sides of shaft"),
    (54, "eye", "A single all-seeing eye viewed from FRONT, horizontal almond shape, detailed iris at CENTER with cosmic pattern inside"),
    (55, "halo", "A luminous ring/halo, circular ring floating horizontally, viewed slightly from below so it appears as an ellipse, centered"),
    (56, "third_eye", "A mystical vertical third eye, diamond/vesica piscis shape, vertical orientation, iris at CENTER, radiating cosmic vision"),

    # === 幾何・抽象 ===
    (57, "crux", "A cross/crux shape, vertical beam from top to bottom, horizontal beam crossing at CENTER, clean geometric proportions"),
    (58, "prism", "A triangular prism on LEFT side, beam of light entering from LEFT, splitting into spectral rays fanning out to the RIGHT"),
    (59, "ring", "A perfect circle ring, simple and elegant, even thickness, centered, subtle glow along the ring"),
    (60, "mobius", "A Möbius strip forming a figure-eight / infinity symbol (∞), oriented horizontally, twisted surface visible, centered"),
]

OUT_DIR = Path(__file__).parent / "share-assets" / "constellation-art"
OUT_DIR.mkdir(parents=True, exist_ok=True)


def generate_one(idx, filename, description):
    """Generate a single constellation illustration."""
    out_path = OUT_DIR / f"{filename}.webp"

    if out_path.exists():
        print(f"  [{idx:2d}] SKIP: {filename}.webp (exists)")
        return True

    prompt = f"{description}. {STYLE}"
    print(f"  [{idx:2d}] Generating: {filename} ...")

    try:
        from google import genai
        from google.genai import types

        API_KEY = os.environ.get("GEMINI_API_KEY")
        if not API_KEY:
            print("  ERROR: GEMINI_API_KEY not set")
            return False

        client = genai.Client(api_key=API_KEY)
        response = client.models.generate_content(
            model="gemini-2.5-flash-image",
            contents=[prompt],
            config=types.GenerateContentConfig(
                response_modalities=["TEXT", "IMAGE"],
            ),
        )
        for part in response.parts:
            if part.inline_data is not None:
                from PIL import Image
                import io

                img_data = part.inline_data.data
                img = Image.open(io.BytesIO(img_data))
                # Resize to 512x512
                padded = Image.new("RGB", (512, 512), (0, 0, 0))
                img.thumbnail((512, 512), Image.LANCZOS)
                x = (512 - img.width) // 2
                y = (512 - img.height) // 2
                padded.paste(img, (x, y))
                padded.save(str(out_path), "WEBP", quality=85)
                size_kb = out_path.stat().st_size // 1024
                print(f"  [{idx:2d}] OK: {filename}.webp ({size_kb}KB)")
                return True

        print(f"  [{idx:2d}] WARN: No image returned for {filename}")
        return False

    except Exception as e:
        print(f"  [{idx:2d}] ERROR: {e}")
        return False


def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else "all"

    if arg == "list":
        for idx, filename, desc in NOUNS:
            shape_note = desc[:60]
            print(f"  [{idx:2d}] {filename:20s} {shape_note}...")
        print(f"\n  Total: {len(NOUNS)} nouns")
        return

    if arg == "all":
        targets = NOUNS
    elif "-" in arg:
        lo, hi = arg.split("-")
        targets = [n for n in NOUNS if int(lo) <= n[0] <= int(hi)]
    else:
        targets = [n for n in NOUNS if n[0] == int(arg)]

    if not targets:
        print("No matching nouns found.")
        return

    print(f"\n=== Generating {len(targets)} constellation illustrations ===\n")
    success = 0
    for idx, filename, desc in targets:
        if generate_one(idx, filename, desc):
            success += 1
        time.sleep(4)  # Rate limit

    print(f"\n  Done: {success}/{len(targets)} generated")
    print(f"  Output: {OUT_DIR}")


if __name__ == "__main__":
    main()
