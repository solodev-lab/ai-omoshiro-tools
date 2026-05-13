"""
Solara 称号診断 PART遷移 背景画像生成 (Mucha 風 9:16 縦長)

3 PART 用の背景画像を生成:
- PART 1: MINOR ARCANA (日常の選択・場面)
- PART 2: MAJOR ARCANA (運命的瞬間・原型)
- PART 3: COURT CARDS (人物像)

クラスカードと統一感のあるアール・ヌーヴォー (Mucha) 画風。
中央に空白を残してタイトル文字を被せられるよう構成。

Usage: python generate_diagnosis_backgrounds.py
"""

import os
import sys
import time
from pathlib import Path


def _load_env():
    here = Path(__file__).resolve()
    for parent in [here, *here.parents]:
        candidate = parent / ".env"
        if candidate.exists():
            for line in candidate.read_text(encoding="utf-8").splitlines():
                if "=" in line and not line.startswith("#"):
                    key, val = line.split("=", 1)
                    os.environ.setdefault(key.strip(), val.strip())
            return candidate
    return None


_loaded = _load_env()
if _loaded:
    print(f"Loaded .env from: {_loaded}")

from google import genai
from google.genai import types

API_KEY = os.environ.get("GEMINI_API_KEY")
if not API_KEY:
    print("ERROR: GEMINI_API_KEY not found in .env")
    sys.exit(1)

client = genai.Client(api_key=API_KEY)
output_dir = Path(__file__).parent
MODEL = "gemini-3.1-flash-image-preview"

# ============================================================
# 共通: Mucha 画風 + 技術仕様 (9:16 縦長)
# ============================================================

MUCHA_STYLE = """
ART STYLE — Art Nouveau (Alphonse Mucha tradition):
- Render in iconic Art Nouveau / Mucha decorative illustration style
- Bold elegant LINE WORK with flowing curvilinear contours
- Stylized botanical motifs (laurel, roses, lily, vines) integrated into ornamental panels
- Stained-glass-like decorative panels framing the composition
- FLAT, decorative use of color rather than deep chiaroscuro
- Soft pastel palette with metallic GOLD accents and gold scrollwork
- The composition feels DESIGNED and SYMBOLIC, like a vintage poster or talisman
- NO HUMAN FIGURES — pure ornamental and symbolic composition only
- Reference: Mucha's "Job" tobacco posters, decorative ornament panels, "The Seasons"
"""

TECHNICAL = """
TECHNICAL:
- Image dimensions 9:16 portrait orientation (1080×1920 ratio)
- LEAVE THE CENTER VERTICALLY EMPTY — the upper-middle and lower-middle areas should have dense decoration, but the EXACT CENTER (around 30%-60% of vertical height) must be visually quieter so a title text can be overlaid in the center
- Solid black or very dark background base — no white areas anywhere
- High detail, museum quality decorative art
- ABSOLUTELY NO text, no numbers, no letters, no calligraphy, no inscriptions, no symbols resembling letters anywhere in the image — including on ribbons, banners, shields, scrolls, plaques, or any rectangular surface. The image must be PURELY pictorial and decorative
"""

# ============================================================
# 3 PART 背景プロンプト
# ============================================================

BACKGROUNDS = [
    ("share_card_bg", """
SUBJECT — SHARE CARD ELEGANT BACKDROP (汎用フレーム、全クラス共通):
A subtle universal Art Nouveau (Mucha) decorative composition for a share card backdrop.
COMPOSITION:
- 9:16 portrait orientation
- Deep velvet midnight background (almost pure black) covering the entire canvas
- Discrete Mucha-style gold filigree borders along all four edges (thin elegant lines)
- Stylized botanical garlands (laurel, vines, lily silhouettes) curling subtly at the four corners only
- Very faint floating gold particles / dust scattered throughout at low opacity
- A dim radial halo of warm gold at the absolute center, very soft, low contrast
- The entire interior (about 75%-80% of the canvas) MUST BE VISUALLY EMPTY — no figures, no specific symbols, only the faint center halo and edge ornaments
- NO HUMAN FIGURES, NO ZODIAC SYMBOLS, NO CLASS-SPECIFIC MOTIFS — must be universal so it works with any of the 25 class cards
PALETTE:
- Almost pure black / midnight black base
- Soft warm gold accents on borders and particles (low saturation)
- A whisper of dim amber at the center halo
- Overall feeling: 神秘的、上品、ニュートラル、汎用的、どのクラスにも合う中性色
"""),

    ("ceremony", """
SUBJECT — THE CEREMONY (召喚演出: 暗黒の中に金色の粒子と神秘):
A pure darkness composition with subtle gold particles and mystical lighting.
COMPOSITION:
- Deep velvety black background filling the entire canvas
- Floating golden particles, light dust, and ember sparks drifting slowly upward
- A faint central glow as if a star is being born in the void
- Subtle Mucha-style gold filigree at the very top and bottom edges only (NOT framing the whole image)
- The center area is mostly empty pure black
PALETTE:
- Pure black, deep void
- Warm gold particles
- Faint amber central glow
- Overall feeling: 召喚直前の静謐な暗闇、神秘の予感
"""),

    ("intro", """
SUBJECT — INTRO (儀式の祭壇: タロット+5軸シンボル+ろうそく):
A decorative Art Nouveau ceremonial altar composition.
COMPOSITION:
- Top section: ornamental arch with FIVE elemental symbols arranged in pentagonal pattern — flame (power/red), open book (mind/blue), crescent moon (spirit/violet), eye (shadow/dark-purple), heart (heart/rose-gold)
- Middle section: empty (deep velvet midnight space with subtle stars) — for title overlay
- Bottom section: TWO ornate ceremonial candles burning, with curling smoke rising into stylized incense patterns, decorated tarot cards fanned out across the bottom
- Frame: thin gold ornamental borders with corner ornaments
PALETTE:
- Deep velvet midnight blue background
- Gold accents on candles, symbols, and tarot cards
- Soft amber candlelight glow at the bottom
- Overall feeling: 神秘的な祭壇、儀式が始まる前の厳粛な空気
"""),

    ("forging", """
SUBJECT — FORGING (称号鍛造中: 銀河・星雲・コズミック):
A cosmic galaxy/nebula composition for the moment a title is being forged.
COMPOSITION:
- Deep cosmic space filling the entire image
- Center: a swirling spiral galaxy or vortex of nebula clouds with bright core (this will be where the forging orb appears, so it must blend with a pulsing center)
- Stars and constellations scattered throughout
- Wispy nebula clouds in deep purple, violet, indigo, with hints of pink and gold
- Mucha-style minimal gold filigree at very top and bottom edges (subtle, not dominant)
PALETTE:
- Deep cosmic palette: indigo, violet, ultramarine, with bright golden-white core
- Stars: silver-white and gold
- Nebula: soft purple/pink gradients
- Overall feeling: コズミックな鍛造、宇宙の力で称号が生まれる
"""),

    ("reveal", """
SUBJECT — REVEAL (称号公開: 神殿・栄光・荘厳):
A grand temple/sanctuary composition for the title revelation moment.
COMPOSITION:
- Top section: ornate dome ceiling with rays of divine light streaming down through stylized openings
- Two tall pillars at left and right, ornamented Art Nouveau columns with botanical capitals
- Bottom section: marble floor or altar steps with rose petals scattered, laurel wreaths at the base
- Center: empty space with subtle radiant glow (for ClassCard to be displayed)
- Frame: ornamental gold borders
PALETTE:
- Warm ivory, gold, soft cream, with hints of rose
- Radiant golden light beams from above
- Pearl-white highlights on pillars
- Overall feeling: 荘厳な神殿、称号が授けられる神聖な瞬間
"""),

    ("part_1_minor_arcana", """
SUBJECT — PART 1: MINOR ARCANA (daily life situations, four elemental suits):
A decorative Art Nouveau composition for the introduction to "Minor Arcana" — themes of daily life, choice, growth.
COMPOSITION:
- Top section: ornamental arch with four stylized suit symbols arranged symmetrically — a WAND (with leaves/sprout), a CUP (overflowing), a SWORD (upright with laurel), and a PENTACLE (with botanical wreath)
- Bottom section: lush stylized botanical garland (laurel, ivy, small wildflowers) with gold scrollwork
- The center area is mostly empty (deep midnight-blue void with subtle gold dust)
- Frame edges: thin gold filigree borders
PALETTE:
- Warm earthy with gold: sage green, soft terracotta, ochre yellow, deep night-blue background
- Gold leaf accents on the suit symbols and ornaments
- Overall feeling: humble, daily, foundational — but elegantly decorated
"""),

    ("part_2_major_arcana", """
SUBJECT — PART 2: MAJOR ARCANA (cosmic archetypes, fateful moments):
A decorative Art Nouveau composition for the introduction to "Major Arcana" — themes of cosmic forces, archetypal turning points.
COMPOSITION:
- Top section: ornamental arch with celestial symbols arranged symmetrically — a CRESCENT MOON, a RADIANT SUN with flame-like rays, and small CONSTELLATIONS of seven-pointed stars
- Bottom section: stylized wheel-of-fortune-like mandala with zodiac glyphs around the perimeter, lotus or lily petals
- The center area is mostly empty (deep cosmic violet void with subtle nebula glow and scattered stars)
- Frame edges: thin gold filigree borders with star motifs at corners
PALETTE:
- Mystical and rich: deep violet, indigo, ultramarine blue, gold leaf
- Silver-white highlights on stars and moon
- Hint of crimson on the sun and central mandala
- Overall feeling: cosmic, fated, archetypal — gorgeous and significant
"""),

    ("part_3_court_cards", """
SUBJECT — PART 3: COURT CARDS (royal characters, archetypal personalities):
A decorative Art Nouveau composition for the introduction to "Court Cards" — themes of personality, role, archetypal characters.
COMPOSITION:
- Top section: ornamental arch with regal symbols arranged symmetrically — a CROWN at top center, twin SCEPTERS crossed behind it, FLEUR-DE-LIS motifs at the sides
- Bottom section: heraldic stylized lion silhouette on the LEFT and eagle silhouette on the RIGHT in profile, each framed by small laurel wreaths
- STRICTLY FORBIDDEN ELEMENTS: any banners, ribbons, scrolls, shields, plaques, books, or rectangular surfaces — these auto-fill with letters in image generation. Use ONLY pure ornamental motifs (crown, scepters, lion, eagle, laurel, fleur-de-lis, damask pattern)
- The EXACT CENTER (vertical 30%–65%) MUST BE VISUALLY EMPTY — a deep crimson-and-gold void with only an extremely subtle damask wallpaper pattern (very low opacity). NO objects, symbols, or motifs in the center area
- Frame edges: thin gold filigree borders with small crown motifs at the four corners
PALETTE:
- Royal and warm: deep crimson, burgundy, rich gold, ivory white
- Bold gold leaf accents on crown, scepters, lion, eagle
- Overall feeling: regal, character, identity — gorgeous and noble
"""),
]


def generate_with_retry(prompt: str, max_attempts: int = 12):
    last_err = None
    for attempt in range(max_attempts):
        try:
            response = client.models.generate_content(
                model=MODEL,
                contents=[prompt],
                config=types.GenerateContentConfig(
                    response_modalities=["TEXT", "IMAGE"],
                ),
            )
            return response
        except Exception as e:
            last_err = e
            msg = str(e)
            if any(k in msg for k in ["503", "UNAVAILABLE", "429", "RESOURCE_EXHAUSTED"]):
                wait = min(2 ** attempt * 3, 60)
                print(f"  [retry] busy. wait {wait}s, attempt {attempt+2}/{max_attempts}")
                time.sleep(wait)
                continue
            raise
    raise last_err or RuntimeError("max retries exceeded")


for i, (filename, subject) in enumerate(BACKGROUNDS, 1):
    out_path = output_dir / f"{filename}.png"
    if out_path.exists():
        print(f"[{i}/{len(BACKGROUNDS)}] {filename}: already exists, skip")
        continue

    print(f"[{i}/{len(BACKGROUNDS)}] {filename}: generating...")

    prompt = "\n".join([
        f"Generate a single background image for: {filename}",
        subject,
        MUCHA_STYLE,
        TECHNICAL,
    ])

    try:
        response = generate_with_retry(prompt)
        saved = False
        for part in response.parts:
            if part.text is not None and part.text.strip():
                print(f"    note: {part.text[:100]}")
            elif part.inline_data is not None:
                image = part.as_image()
                image.save(str(out_path))
                print(f"    [OK] {filename}.png")
                saved = True
        if not saved:
            print(f"    [WARN] no image returned")
    except Exception as e:
        print(f"    [ERR] {filename}: {str(e)[:150]}")

    if i < len(BACKGROUNDS):
        time.sleep(4)

print("\nDone.")
