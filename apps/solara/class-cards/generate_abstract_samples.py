"""
Solara クラスカード 抽象画風サンプル生成 (Knight × 2 styles)

女性ユーザー受容性向上のため、より抽象的・神秘的な画風を試作:
- A: アール・ヌーヴォー風 (ミュシャ風、装飾フレーム + 美麗線画 + 植物文様)
- E: シルエット + 象徴 (顔をぼかし、後ろ姿や横顔 + 象徴オブジェ、想像余地)

Usage: python generate_abstract_samples.py
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
# Knight (power axis) のサブジェクト
# ============================================================

KNIGHT_ART_NOUVEAU = """
SUBJECT — Knight (Power axis, Page court) in ART NOUVEAU STYLE:
A noble knight figure, full-body or three-quarter portrait, posed in a decorative tableau.
The knight holds a longsword vertically before the body, both hands on the hilt.
Polished armor with elegant filigree engravings.
A flowing cape that curves into ornamental ribbon-like lines.
Expression is serene, idealized — the face is beautiful, refined, slightly stylized in the Mucha tradition.
"""

ART_NOUVEAU_STYLE = """
ART STYLE — Art Nouveau (Alphonse Mucha tradition):
- Render in the iconic Art Nouveau / Mucha decorative illustration style
- Bold elegant LINE WORK with flowing curvilinear contours
- The figure is integrated into an ORNAMENTAL FRAME-WITHIN-THE-FRAME: a halo-like ARCH or MEDALLION behind the head and shoulders, decorated with stylized roses, laurel leaves, and gold scrollwork
- Stylized botanical motifs: roses, vines, laurel, lily, intertwining around the figure
- Stained-glass-like decorative panels at the top and bottom of the composition (NOT photographic environment)
- FLAT, decorative use of color rather than deep chiaroscuro — soft pastel palette with metallic gold accents
- Limited color range, muted and elegant: ivory, soft rose, sage green, dusty crimson, gold leaf
- The composition feels DESIGNED and SYMBOLIC rather than illustrative — like a poster or talisman
- Slightly androgynous, idealized human figure — appealing to all genders
- Mature and dignified, NOT cartoonish, NOT chibi, NOT anime
- Reference: Alphonse Mucha's "The Seasons", "The Four Arts", "Job" tobacco posters
"""

KNIGHT_SILHOUETTE = """
SUBJECT — Knight (Power axis, Page court) in SILHOUETTE STYLE:
A knight figure shown as a partial SILHOUETTE — either from BEHIND (back view, looking toward distance), or in PROFILE with the face mostly in shadow.
Long sword held at the side, or planted in the ground before them.
A flowing cape catches a strong rim light.
Around the figure: SYMBOLIC OBJECTS floating elegantly — a sword icon, a shield emblem, a crown of laurels, drifting petals or ember sparks.
The setting is dreamy and abstract: a stylized horizon, a setting sun, soft mist.
The viewer cannot see the knight's face clearly — they should be able to imagine themselves as this figure.
"""

SILHOUETTE_STYLE = """
ART STYLE — Mystical Silhouette with Symbolic Overlay:
- The figure is rendered primarily in elegant SILHOUETTE or partial silhouette — the face is intentionally obscured by shadow, hood, hair, or rim light
- Painted in a soft, dreamy oil-illustration style — emotional, evocative, NOT photographic
- A limited, harmonious palette dominated by ONE accent color (here, crimson and gold) with soft gradients
- Strong sense of ATMOSPHERE: backlight, mist, glow, petals or embers in the air
- SYMBOLIC ICONS float around the figure: small, stylized representations of the class's essence
- The composition feels POETIC and OPEN — invites the viewer to project themselves into the role
- Mature, dignified, mysterious — NOT cartoonish, NOT cute, NOT overly detailed
- Reference: Jean Giraud (Moebius) silhouettes, modern fantasy book covers, atmospheric concept art
"""

# ============================================================
# Frame (power 軸: 赤金) — 抽象画風用にやや調整
# ============================================================

FRAME_POWER_REFINED = """
CARD FRAME (Power axis — refined for abstract style):
- Deep BLACK background outside the painting
- Thin GOLD double-line border with a soft CRIMSON RED accent inset between the two gold lines
- ELEGANT corner ornaments in gold leaf — small stylized flame-or-rose motif
- A delicate thin gold decorative line on the top and bottom edges between corners
- Sides clean double-line — no decoration on left/right
- The frame should feel like a JEWELRY-BOX or VINTAGE TALISMAN — refined, restrained, beautiful
"""

TECHNICAL = """
TECHNICAL:
- Card dimensions 2:3 ratio (portrait orientation)
- No text, no numbers, no letters anywhere on the image
- Solid black or very dark background outside the painting — absolutely NO white borders
- High detail, museum quality
"""


def generate_with_retry(prompt: str, max_attempts: int = 12):
    for attempt in range(max_attempts):
        try:
            return client.models.generate_content(
                model=MODEL,
                contents=[prompt],
                config=types.GenerateContentConfig(
                    response_modalities=["TEXT", "IMAGE"],
                ),
            )
        except Exception as e:
            msg = str(e)
            if any(k in msg for k in ["503", "UNAVAILABLE", "429", "RESOURCE_EXHAUSTED"]):
                wait = min(2 ** attempt * 3, 60)
                print(f"  [retry] busy. wait {wait}s, attempt {attempt+2}/{max_attempts}")
                time.sleep(wait)
                continue
            raise
    raise RuntimeError("max retries exceeded")


samples = [
    ("knight_art_nouveau", KNIGHT_ART_NOUVEAU, ART_NOUVEAU_STYLE),
    ("knight_silhouette", KNIGHT_SILHOUETTE, SILHOUETTE_STYLE),
]

for i, (filename, subject, style) in enumerate(samples, 1):
    print(f"\n[{i}/{len(samples)}] {filename}...")

    prompt = "\n".join([
        f'Generate a single class card image: "Knight".',
        subject,
        style,
        FRAME_POWER_REFINED,
        TECHNICAL,
    ])

    try:
        response = generate_with_retry(prompt)
        saved = False
        for part in response.parts:
            if part.text is not None and part.text.strip():
                print(f"  note: {part.text[:100]}")
            elif part.inline_data is not None:
                out_path = output_dir / f"{filename}.png"
                image = part.as_image()
                image.save(str(out_path))
                print(f"  [OK] {out_path}")
                saved = True
        if not saved:
            print(f"  [WARN] no image returned")
    except Exception as e:
        print(f"  [ERR] {str(e)[:150]}")

    if i < len(samples):
        time.sleep(5)

print("\nDone.")
