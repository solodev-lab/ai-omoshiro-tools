"""
Solara クラスカード サンプル生成（騎士 Knight で 4 画風を比較）
- vermeer: ヨハネス・フェルメール風（既存タロットと統一）
- mtg: Magic the Gathering 風（写実ファンタジー油彩）
- hearthstone: Hearthstone 風（カートゥーン・ペインタリー）
- ff: Final Fantasy 職業画風（半リアル・天野喜孝/野村哲也風）

軸別カラーは「枠」のみに適用。絵自体の配色は自由。
power 軸 = 深紅・燃える金（Knight が属する軸）

Usage: python generate_sample_styles.py
"""

import os
import sys
import time
from pathlib import Path

# worktree／main どちらから実行しても動くよう、親方向に .env を探す
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
output_dir.mkdir(parents=True, exist_ok=True)

# ============================================================
# 共通定義
# ============================================================

# 騎士 Knight 共通シーン（人物描写は固定 → 画風で見比べる）
KNIGHT_SCENE = """
SUBJECT: A noble knight class character, full-body portrait, heroic pose.
The knight wears polished armor with intricate engravings, holds a longsword pointed upward with both hands or one hand at the hilt and one resting on the pommel. A flowing cape billows behind. Determined, calm expression — the gaze of someone who has already decided to protect.
SETTING: Standing on weathered stone ground at the edge of a battlefield or castle ramparts. Banners flutter behind. Dramatic sky with sunlit golden clouds breaking through. A faint glow surrounds the knight, as if blessed.
"""

# power 軸の枠カラー（深紅 + 燃える金）
FRAME_POWER = """
CARD FRAME (Power axis — Knight):
- The card background OUTSIDE the painting area must be DEEP BLACK — no white or cream anywhere
- Thin gold double-line border, with subtle CRIMSON RED accent inset between the two gold lines
- Elegant gold corner ornaments at all four corners, with small flame/sword motif
- A thin gold decorative line along the top and bottom edges ONLY (between corners)
- The sides remain clean double-line — no decoration on left/right edges
- The frame should evoke power, valor, and crimson glory — NOT baroque excess
- Inner border has a fine dark line, outer border is burnished gold
- Narrow gap between the image and the frame, filled with black
"""

# 技術仕様
TECHNICAL = """
TECHNICAL:
- Card dimensions 2:3 ratio (portrait orientation)
- No text, no numbers, no letters, no card name anywhere on the image
- Solid black or very dark background outside the painting — absolutely NO white borders
- High detail, museum quality character art
"""

# ============================================================
# 4 画風プロンプト
# ============================================================

STYLE_VERMEER = """
ART STYLE — Johannes Vermeer (Dutch Golden Age oil painting):
- Render in the style of Johannes Vermeer's oil paintings
- Soft, luminous light pouring from the upper left, creating Vermeer's signature warm golden glow on the armor
- Rich, deep color palette: ultramarine blue, vermilion red, ochre yellow, lead white
- Vermeer's characteristic pointillé technique for highlights (tiny dots of light on metal surfaces)
- Subtle chiaroscuro with smooth tonal gradations
- Meticulous attention to fabric textures: silk cape, polished armor, leather grip rendered with photorealistic detail
- Atmospheric perspective in the background landscape
- The scene should feel like a Dutch Golden Age painting come to life
"""

STYLE_MTG = """
ART STYLE — Magic: The Gathering (high fantasy painterly oil):
- Render in the style of Magic: The Gathering creature/planeswalker card art
- Painterly oil-painting fantasy illustration with strong, dramatic composition
- Rich, saturated palette with bold contrast — vibrant highlights and deep shadows
- Dynamic perspective and cinematic camera angle (slight low angle to emphasize heroism)
- Visible brushwork in the painterly tradition of Wizards of the Coast illustrators (Greg Staples, Todd Lockwood, Jaime Jones)
- Detailed environment storytelling: glints of distant fire, hints of conflict, weather
- The character feels mythic and powerful, captured in a moment of action or resolve
- Slightly desaturated atmosphere with selectively vivid focal points
"""

STYLE_HEARTHSTONE = """
ART STYLE — Hearthstone (Blizzard stylized painterly cartoon):
- Render in the iconic Hearthstone card art style by Blizzard Entertainment
- Stylized painterly cartoon — exaggerated proportions: slightly larger head and hands, expressive features, broad shoulders
- Warm, inviting palette with rich saturated colors and warm rim lighting
- Confident hand-painted brushwork — visible textured strokes
- Slightly cartoonish but heroic and dignified — never childish
- Strong gesture and silhouette readability
- Background suggested with simple bold shapes rather than detailed environment
- The character should feel approachable and charismatic, like a beloved card from the game
"""

STYLE_FF = """
ART STYLE — Final Fantasy job class portrait (Tetsuya Nomura / Yoshitaka Amano influence):
- Render in the iconic Final Fantasy character illustration style
- Semi-realistic anime aesthetic with elegant flowing lines and refined proportions
- Detailed and ornate armor and costume design — fantastical elements, intricate filigree
- Slightly elongated figure proportions, refined facial features with anime-influenced eyes (but not overly large)
- Cool ethereal palette with mystical undertones — silver, sapphire, faint violet on the metalwork
- Delicate sharp linework combined with soft painted shading
- Mystical, slightly otherworldly atmosphere — the knight feels like a summoned hero from another world
- Background atmospheric and dreamlike rather than gritty realistic
"""

# ============================================================
# 生成ループ
# ============================================================

samples = [
    ("knight_vermeer", STYLE_VERMEER),
    ("knight_mtg", STYLE_MTG),
    ("knight_hearthstone", STYLE_HEARTHSTONE),
    ("knight_ff", STYLE_FF),
]

# 503/混雑時のフォールバックモデル候補
MODELS = [
    "gemini-3.1-flash-image-preview",
    "gemini-2.5-flash-image-preview",
    "gemini-2.0-flash-preview-image-generation",
]


def generate_with_retry(prompt: str, max_attempts: int = 6):
    """503/UNAVAILABLE 時は指数バックオフ + モデルフォールバック"""
    last_err = None
    for attempt in range(max_attempts):
        model = MODELS[min(attempt // 2, len(MODELS) - 1)]
        try:
            response = client.models.generate_content(
                model=model,
                contents=[prompt],
                config=types.GenerateContentConfig(
                    response_modalities=["TEXT", "IMAGE"],
                ),
            )
            return response, model
        except Exception as e:
            last_err = e
            msg = str(e)
            # 503/UNAVAILABLE/RESOURCE_EXHAUSTED の場合のみリトライ
            if any(k in msg for k in ["503", "UNAVAILABLE", "429", "RESOURCE_EXHAUSTED"]):
                wait = min(2 ** attempt * 5, 60)  # 5,10,20,40,60,60 秒
                print(f"  [retry] {model} busy ({msg[:80]}). wait {wait}s, attempt {attempt+2}/{max_attempts}")
                time.sleep(wait)
                continue
            raise
    raise last_err or RuntimeError("max retries exceeded")


print(f"Generating {len(samples)} Knight class cards in different styles...\n")

for i, (filename, style) in enumerate(samples, 1):
    print(f"[{i}/{len(samples)}] {filename}...")
    prompt = "\n".join([
        f'Generate a single class card image: "Knight" (Power axis, Page court).',
        KNIGHT_SCENE,
        style,
        FRAME_POWER,
        TECHNICAL,
    ])

    try:
        response, used_model = generate_with_retry(prompt)
        print(f"  Model used: {used_model}")

        saved = False
        for part in response.parts:
            if part.text is not None and part.text.strip():
                print(f"  Model says: {part.text[:120]}...")
            elif part.inline_data is not None:
                out_path = output_dir / f"{filename}.png"
                image = part.as_image()
                image.save(str(out_path))
                print(f"  [OK] Saved: {out_path.name}")
                saved = True

        if not saved:
            print(f"  [WARN] No image generated for {filename}")
    except Exception as e:
        print(f"  [ERR] {filename}: {str(e)[:200]}")

    # rate limit 配慮（無料枠）
    if i < len(samples):
        print("  (waiting 6s)\n")
        time.sleep(6)

print("\nDone. Compare:")
for filename, _ in samples:
    print(f"  - {output_dir / filename}.png")
