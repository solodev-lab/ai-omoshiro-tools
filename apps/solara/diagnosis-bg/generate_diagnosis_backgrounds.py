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
- No text, no numbers, no letters anywhere in the image
"""

# ============================================================
# 3 PART 背景プロンプト
# ============================================================

BACKGROUNDS = [
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
- Top section: ornamental arch with regal symbols arranged symmetrically — a CROWN, twin SCEPTERS crossed behind it, FLEUR-DE-LIS motifs at the sides
- Bottom section: heraldic stylized lion and eagle silhouettes in profile, framed by laurel wreaths, royal banner ribbons
- The center area is mostly empty (deep crimson-and-gold void with subtle damask pattern)
- Frame edges: thin gold filigree borders with small crown motifs at corners
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
