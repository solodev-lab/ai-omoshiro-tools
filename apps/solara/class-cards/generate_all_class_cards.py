"""
Solara 25 クラスカード本番生成 (アール・ヌーヴォー画風 — Mucha tradition)

- 5軸 (power/mind/spirit/shadow/heart) × 5コート (page/knight/queen/king/mixed) = 25枚
- 共通画風: Alphonse Mucha 風アール・ヌーヴォー（装飾フレーム + 美麗線画 + 植物文様）
- 軸別フレームカラー
- 各クラス: 職業を象徴するタブロー構成（人物 + 象徴オブジェ + 植物 + medallion arch）
- 既存PNG はスキップ（レジューム可能）

Usage:
  python generate_all_class_cards.py         # 全25枚
  python generate_all_class_cards.py Knight  # 1枚だけ
  python generate_all_class_cards.py power   # 1軸 (5枚)
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
# アール・ヌーヴォー共通画風
# ============================================================

ART_NOUVEAU_STYLE = """
ART STYLE — Art Nouveau (Alphonse Mucha tradition):
- Render in the iconic Art Nouveau / Mucha decorative illustration style
- Bold elegant LINE WORK with flowing curvilinear contours
- The figure is integrated into an ORNAMENTAL FRAME-WITHIN-THE-FRAME: a halo-like ARCH or MEDALLION behind the head and shoulders, decorated with stylized botanical motifs and gold scrollwork
- Stylized botanical motifs intertwining around the figure
- Stained-glass-like decorative panels at the top and bottom of the composition (NOT photographic environment)
- FLAT, decorative use of color rather than deep chiaroscuro — soft pastel palette with metallic gold accents
- Limited harmonious color range — muted, elegant, refined
- The composition feels DESIGNED and SYMBOLIC rather than illustrative — like a poster or talisman
- Slightly androgynous, idealized human figure — appealing to all genders
- Mature and dignified, NOT cartoonish, NOT chibi, NOT anime
- Reference: Alphonse Mucha's "The Seasons", "The Four Arts", "Job" tobacco posters
"""

TECHNICAL = """
TECHNICAL:
- Card dimensions 2:3 ratio (portrait orientation)
- No text, no numbers, no letters anywhere on the image
- Solid black or very dark background outside the painting — absolutely NO white borders
- High detail, museum quality decorative art
"""

# ============================================================
# 軸別フレーム (5種)
# ============================================================

FRAMES = {
    "power": """
CARD FRAME (Power axis — crimson and gold):
- Deep BLACK background outside the painting
- Thin GOLD double-line border with soft CRIMSON RED accent inset between the two gold lines
- Elegant gold corner ornaments — small stylized flame/sword/rose motif
- Thin gold decorative line on top and bottom edges between corners
- Sides clean double-line — no decoration on left/right
- Frame feels like a jewelry-box or vintage talisman — refined, restrained, beautiful
""",
    "mind": """
CARD FRAME (Mind axis — sapphire and silver):
- Deep BLACK background outside the painting
- Thin SILVER double-line border with DEEP SAPPHIRE BLUE accent inset between the two silver lines
- Silver corner ornaments — small stylized book/quill/key motif
- Thin silver decorative line on top and bottom edges between corners
- Sides clean double-line
- Frame feels refined and intellectual, like an antique illuminated manuscript
""",
    "spirit": """
CARD FRAME (Spirit axis — violet and pearl-white):
- Deep BLACK background outside the painting
- Thin PEARL-WHITE double-line border with DEEP VIOLET accent inset between the two lines
- Pearl-white corner ornaments — small stylized crescent moon/star/lily motif
- Thin pearl decorative line on top and bottom edges between corners
- Sides clean double-line
- Frame feels mystical and sacred, like a temple amulet
""",
    "shadow": """
CARD FRAME (Shadow axis — obsidian and amethyst):
- Deep BLACK background outside the painting
- Thin DARK GOLD double-line border with DEEP AMETHYST PURPLE accent inset between the two lines (the purple is dark, almost black-purple)
- Obsidian-black corner ornaments — small stylized crescent/blade/raven motif
- Thin dark-purple decorative line on top and bottom edges between corners
- Sides clean double-line
- Frame feels mysterious and elegant, like a midnight talisman
""",
    "heart": """
CARD FRAME (Heart axis — rose-gold and pink):
- Deep BLACK background outside the painting
- Thin GOLD double-line border with WARM ROSE-PINK accent inset between the two gold lines
- Rose-gold corner ornaments — small stylized heart/petal/dove motif
- Thin rose-gold decorative line on top and bottom edges between corners
- Sides clean double-line
- Frame feels warm and emotional, like an Art Nouveau wedding portrait
""",
}

# ============================================================
# 25 クラス (Mucha 風タブロー構成)
# ============================================================
#
# 各シーン記述の構成:
#   - 人物のポーズ
#   - 主要オブジェ
#   - 周囲の植物・象徴
#   - 背後のメダリオン/アーチ
# ============================================================

CLASSES = [
    # axis, court, name_en, name_jp, scene
    ("power", "page", "Knight", "騎士",
     "A noble knight figure in a serene decorative tableau pose. Holds a longsword vertically before the body, both hands on the hilt. Polished armor with elegant filigree engravings. Flowing cape curving into ornamental ribbon-like lines. Idealized refined expression. Stylized roses and laurel leaves intertwining around the figure. A halo-like arch of laurels behind the head."),

    ("power", "knight", "Dragoon", "突撃手",
     "A dragoon figure in a stylized leaping pose adapted for decorative composition, long ornate spear held diagonally upward. Plate armor with wing-shaped pauldrons and ornate helmet. Cape flowing in elegant ribbon curves. Stylized iris and lily flowers around the figure. A medallion of stylized wings behind the head."),

    ("power", "queen", "Paladin", "聖騎士",
     "A holy paladin figure in a dignified standing pose, ornate shield emblazoned with a stylized sun emblem in one hand, the other hand resting on a heavy ornate mace. Gilded white-and-gold armor with filigree. Stylized white lilies and golden wheat around the figure. A halo arch of golden rays behind the head."),

    ("power", "king", "Overlord", "覇者",
     "A regal overlord figure seated on an ornate decorative throne. Crown-like helm with crimson crest. A massive ornate broadsword resting upright at the side. Heavy fur-trimmed cape curling into ornamental ribbons. Stylized dark roses and oak leaves around the figure. A medallion of empire emblem behind the head."),

    ("power", "mixed", "Spellblade", "魔剣士",
     "A spellblade figure in a poised stance, holding a longsword whose blade is wreathed in stylized curling magical motifs. Hybrid armor-robe with filigree. One hand glowing softly. Stylized vines mixed with curling flame patterns around the figure. A medallion of magical glyph behind the head."),

    ("mind", "page", "Sage", "求道者",
     "A scholar-wanderer figure in flowing dark blue robes with hood pushed back, holding a wooden staff carved with runes. A scroll in the other hand. Refined contemplative expression. Stylized ivy and starflowers around the figure. An owl silhouette in the medallion arch behind the head."),

    ("mind", "knight", "Strategist", "軍師",
     "A military commander figure in deep blue uniform with silver embroidery, holding a rolled parchment map ornately decorated. A fine sword at the hip. Stylized hawk wings and laurel around the figure. A medallion of compass rose behind the head."),

    ("mind", "queen", "Chancellor", "司書",
     "A librarian-scholar figure in long midnight-blue robes with silver trim, holding an enormous open tome whose pages emit a soft glowing script. Fine reading glasses. Stylized ferns and key motifs around the figure. A medallion of an open book behind the head. Mature dignified expression."),

    ("mind", "king", "Judge", "裁定者",
     "A stern judge figure in formal dark robes with silver chains of office, holding ornate scales of justice in one hand and a tall staff in the other. Stylized oak leaves and pillar motifs around the figure. A medallion of perfect scales behind the head. Composed authority."),

    ("mind", "mixed", "Wizard", "魔術師",
     "A wizard figure in dark blue and silver robes, holding a tall ornate staff that emits stylized arcane light. Hood pushed back showing sharp mature features. Stylized moonflowers and runic motifs around the figure. A medallion of star and rune behind the head."),

    ("spirit", "page", "Cleric", "神官",
     "A priest figure in white-and-violet robes with gold trim, holding a glowing chalice in both hands before the chest. Pearl-white halo behind the head. Stylized white lilies and pure flowers around the figure. A medallion of sacred symbol behind. Gentle resolute expression."),

    ("spirit", "knight", "Astrologer", "星読み",
     "An astrologer figure in violet starlit robes embroidered with constellations, holding an ornate brass astrolabe before them. Long cape flowing in starry ribbon-curves. Stylized stars and crescent moons around the figure. A medallion of zodiac wheel behind the head."),

    ("spirit", "queen", "Oracle", "預言者",
     "An oracle priestess figure with long flowing veil partially obscuring face, hands held open as if receiving a vision. Pale violet and white robes with silver embroidery. Stylized mistflowers and dove silhouettes around. A medallion of crescent moon behind the head. Mysterious aura."),

    ("spirit", "king", "Mentor", "導師",
     "A wise master figure in long violet-and-white robes, one hand raised palm-out with soft golden light emanating, the other resting on a tall ornate staff. Halo of light behind the head. Stylized sage plants and sunrise rays around. A medallion of opened palm behind."),

    ("spirit", "mixed", "Druid", "祭司",
     "A nature priest figure in earthy green-violet robes with leaf and antler motifs, holding a staff topped with a glowing crystal. Hair entwined with leaves and small branches. Stylized oak leaves and fern fronds around the figure. A stag silhouette in the medallion arch behind."),

    ("shadow", "page", "Performer", "旅芸人",
     "A traveling performer figure in colorful patchwork costume with theatrical mask held in one hand, ribbons and scarves whirling. Carries a small lute. Mysterious half-smile. Stylized ivy and theatrical curtain motifs around the figure. A medallion of comedy/tragedy mask behind the head."),

    ("shadow", "knight", "Revolutionary", "革命家",
     "A rebel leader figure holding a torn banner aloft, broken chains around the wrists. Practical garb mixed with cape that curves into decorative ribbons. Stylized thistles and ember sparks around the figure. A medallion of broken chain behind the head. Defiant dignified expression."),

    ("shadow", "queen", "Ninja", "忍者",
     "A shinobi figure in black, partially silhouetted with only the eyes visible above a cowl. Two ornate kunai held crossed before the body. Stylized bamboo and crescent moon around the figure. A medallion of shadow and moon behind the head. Composed stillness."),

    ("shadow", "king", "Rogue", "冒険家",
     "A lone adventurer figure in worn leather coat, hood half-up, an ornate dagger at the hip and a rolled map in hand. Mature confident gaze. Stylized cypress trees and raven silhouettes around the figure. A medallion of compass and map behind the head."),

    ("shadow", "mixed", "Alchemist", "錬金術師",
     "An alchemist figure in dark purple robes and leather apron, holding a glowing bubbling flask in one hand and an open notebook in the other. Goggles pushed up on the head. Stylized mandrake roots and curling smoke patterns around. A medallion of alembic behind the head."),

    ("heart", "page", "Bard", "語り手",
     "A bard figure with an ornate lute held in playing position. Mid-storytelling gesture with the other hand expressive. Warm rich costume of gold and rose. Stylized roses and songbird motifs around the figure. A medallion of musical lyre behind the head. Charismatic dignified smile."),

    ("heart", "knight", "Sorcerer", "召喚士",
     "A summoner figure with arms raised, a translucent spectral phoenix or guardian beast emerging from a glowing rose-gold circle. Robes of red and gold with arcane embroidery. Stylized peonies and phoenix feathers around the figure. A medallion of summoning sigil behind the head."),

    ("heart", "queen", "Enchanter", "詩人",
     "A poet enchanter figure in flowing rose-gold robes, quill in one hand and a luminous scroll trailing soft floating script in the other. Hair adorned with small flowers. Stylized jasmine and moth motifs around the figure. A medallion of open scroll behind the head. Inspired contemplative gaze."),

    ("heart", "king", "Emperor", "君主",
     "A regal monarch figure on an ornate gold throne, wearing a crown and heavy crimson-and-gold cape curling into decorative ribbons. Scepter in one hand. Stylized peonies and dove motifs around the figure. A medallion of imperial seal behind the head. Composed dignified gaze."),

    ("heart", "mixed", "Chronomancer", "歴史家",
     "A historian-chronomancer figure with an ornate hourglass held in one hand, ancient leather-bound chronicle tome in the other. Long coat of deep burgundy with gold buttons. Stylized clematis and clock mechanism motifs around the figure. A medallion of time wheel behind the head."),
]

# ============================================================
# 生成ロジック
# ============================================================

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
                print(f"    [retry] busy. wait {wait}s, attempt {attempt+2}/{max_attempts}")
                time.sleep(wait)
                continue
            raise
    raise last_err or RuntimeError("max retries exceeded")


def filename_for(axis: str, court: str, name_en: str) -> str:
    return f"{axis}_{court}_{name_en.lower()}.png"


def filter_classes(arg):
    if not arg:
        return CLASSES
    arg_lower = arg.lower()
    matched = [
        c for c in CLASSES
        if c[0].lower() == arg_lower or c[2].lower() == arg_lower
    ]
    if not matched:
        print(f"No match for '{arg}'. Available axes: power/mind/spirit/shadow/heart")
        print(f"Available classes: {', '.join(c[2] for c in CLASSES)}")
        sys.exit(1)
    return matched


def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else None
    targets = filter_classes(arg)

    print(f"Target: {len(targets)} card(s)\n")

    succeeded, skipped, failed = [], [], []

    for i, (axis, court, name_en, name_jp, scene) in enumerate(targets, 1):
        fname = filename_for(axis, court, name_en)
        out_path = output_dir / fname
        label = f"[{i}/{len(targets)}] {name_en} ({name_jp}) [{axis}/{court}]"

        if out_path.exists():
            print(f"{label}: already exists, skip")
            skipped.append(fname)
            continue

        print(f"{label}: generating...")

        prompt = "\n".join([
            f'Generate a single class card image: "{name_en}" ({axis} axis, {court} court).',
            f"SUBJECT: {scene}",
            ART_NOUVEAU_STYLE,
            FRAMES[axis],
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
                    print(f"    [OK] {fname}")
                    succeeded.append(fname)
                    saved = True
            if not saved:
                print(f"    [WARN] no image returned for {fname}")
                failed.append(fname)
        except Exception as e:
            print(f"    [ERR] {fname}: {str(e)[:150]}")
            failed.append(fname)

        if i < len(targets):
            time.sleep(4)

    print(f"\n=== Summary ===")
    print(f"Generated: {len(succeeded)}")
    print(f"Skipped (already existed): {len(skipped)}")
    print(f"Failed: {len(failed)}")
    if failed:
        print(f"Failed list: {', '.join(failed)}")
        print(f"Re-run the script to retry failed ones.")


if __name__ == "__main__":
    main()
