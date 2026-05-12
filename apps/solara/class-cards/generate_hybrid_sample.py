"""
Solara クラスカード ハイブリッド画風サンプル生成 (Knight × FF+MTG融合)

オーナーフィードバック:
- FF だけだと子供っぽい
- FF の優雅な造形 + MTG の油彩タッチ + 大人っぽさ がベスト

Usage: python generate_hybrid_sample.py
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

# ============================================================
# 共通: Knight シーン + Power 軸フレーム
# ============================================================

KNIGHT_SCENE = """
SUBJECT: A noble knight class character, full-body portrait, heroic pose.
The knight wears polished armor with intricate engravings, holds a longsword pointed upward with both hands or one hand at the hilt and one resting on the pommel. A flowing cape billows behind. Determined, calm expression — the gaze of someone who has already decided to protect.
SETTING: Standing on weathered stone ground at the edge of a battlefield or castle ramparts. Banners flutter behind. Dramatic sky with sunlit golden clouds breaking through. A faint glow surrounds the knight, as if blessed.
"""

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

TECHNICAL = """
TECHNICAL:
- Card dimensions 2:3 ratio (portrait orientation)
- No text, no numbers, no letters, no card name anywhere on the image
- Solid black or very dark background outside the painting — absolutely NO white borders
- High detail, museum quality character art
"""

# ============================================================
# ハイブリッド画風（FF優雅 × MTG油彩 × 大人っぽさ）
# ============================================================

STYLE_HYBRID = """
ART STYLE — Hybrid (Final Fantasy elegance × Magic: The Gathering painterly oil):
- The CHARACTER DESIGN follows Final Fantasy tradition (Tetsuya Nomura / Yoshitaka Amano influence):
  * Ornate, intricate armor with fantastical filigree and engraved details
  * Elegant flowing lines on cape, hair, and metalwork
  * Refined, dignified facial features — slightly stylized but pulled toward realism
  * Heroic proportions with weight and presence
- The EXECUTION follows Magic: The Gathering painterly oil tradition (Greg Staples, Todd Lockwood):
  * Painterly oil-painting fantasy illustration with visible mature brushwork
  * Rich, saturated palette with strong dramatic contrast
  * Cinematic composition with slight low angle for heroic emphasis
  * Atmospheric depth: distant glints of fire, weather, environmental storytelling
  * Painterly texture on fabric, leather, and steel
  * Chiaroscuro lighting — vivid highlights on metalwork with deep atmospheric shadows
- CRITICAL — Adult, mature, serious atmosphere:
  * NOT anime-cartoonish, NOT childlike, NOT chibi
  * NOT overly large eyes — keep facial proportions realistic and mature
  * The knight is a seasoned warrior who has seen battle, NOT a teenage hero
  * The aesthetic should feel like Magic: The Gathering art directed by a Final Fantasy art team
  * Think: a senior FF protagonist (Auron, Basch, Cid) rendered in MTG oil painting style
"""

# ============================================================
# 503/429 リトライ + モデルフォールバック
# ============================================================

MODEL = "gemini-3.1-flash-image-preview"


def generate_with_retry(prompt: str, max_attempts: int = 10):
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
            return response, MODEL
        except Exception as e:
            last_err = e
            msg = str(e)
            if any(k in msg for k in ["503", "UNAVAILABLE", "429", "RESOURCE_EXHAUSTED"]):
                wait = min(2 ** attempt * 3, 60)
                print(f"  [retry] {MODEL} busy. wait {wait}s, attempt {attempt+2}/{max_attempts}")
                time.sleep(wait)
                continue
            raise
    raise last_err or RuntimeError("max retries exceeded")


# ============================================================
# 生成
# ============================================================

filename = "knight_hybrid_ff_mtg"

print(f"Generating: {filename} (FF elegance × MTG painterly oil, mature tone)\n")

prompt = "\n".join([
    'Generate a single class card image: "Knight" (Power axis, Page court).',
    KNIGHT_SCENE,
    STYLE_HYBRID,
    FRAME_POWER,
    TECHNICAL,
])

try:
    response, used_model = generate_with_retry(prompt)
    print(f"Model used: {used_model}")

    saved = False
    for part in response.parts:
        if part.text is not None and part.text.strip():
            print(f"Model says: {part.text[:120]}...")
        elif part.inline_data is not None:
            out_path = output_dir / f"{filename}.png"
            image = part.as_image()
            image.save(str(out_path))
            print(f"[OK] Saved: {out_path}")
            saved = True

    if not saved:
        print(f"[WARN] No image generated")
except Exception as e:
    print(f"[ERR] {str(e)[:200]}")
