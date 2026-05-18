"""Generate 81 Naura card images using Nanobanana2 (nano-banana-pro-preview)
- Same style as tarot major arcana (copper engraving)
- 5 second delay between requests
- Auto retry up to 3 times
- Skips existing files
- Usage: python generate_all_cards.py [batch]
  batch: 1 (sei 1-3), 2 (sei 4-6), 3 (sei 7-9), all
"""
import os
import sys
import time
from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.dirname(__file__), '..', '..', '.env'))

from google import genai
from google.genai import types

client = genai.Client(api_key=os.getenv('GEMINI_API_KEY'))
MODEL = 'models/nano-banana-pro-preview'

STYLE = (
    "Antique copper engraving style with hand-colored tinting. "
    "All human figures have a stoic, unreadable, emotionally ambiguous face "
    "with fully detailed eyes including pupils and iris, but showing no clear emotion. "
    "Ornate gold baroque frame border. Deep jewel tones, aged parchment background. "
    "Cracked gold leaf border texture. Card dimensions 2:3 ratio. "
    "No text, no numbers, no letters."
)

# Base scene descriptions for each guardian card (9 types)
# Each card gets a unique twist based on its 二つ名
GUARDIAN_SCENES = {
    "魔術師": (
        "A robed figure stands behind a table with a cup, sword, pentacle coin, and wand. "
        "One hand points to sky, other to earth. Infinity symbol above his head."
    ),
    "女教皇": (
        "A woman in flowing robes sits between two pillars, one black and one white. "
        "She holds a sacred scroll. Crescent moon at her feet. A mysterious veil behind her."
    ),
    "女帝": (
        "A crowned woman sits on a luxurious throne in a lush garden. "
        "Flowing robes with pomegranates. Crown of twelve stars. Wheat and nature around her."
    ),
    "皇帝": (
        "A man in red robes sits on a stone throne with ram heads. "
        "Golden scepter in hand. Crown on head. Mountains behind. Armor beneath robes."
    ),
    "教皇": (
        "A religious figure in ornate robes on a throne between two pillars. "
        "Raises hand in blessing. Golden keys at feet. Followers kneel before him."
    ),
    "恋人": (
        "A man and woman stand beneath a great angel with wings. "
        "Angel blesses them from above. Trees and garden surround them. Radiant light above."
    ),
    "戦車": (
        "A warrior in a chariot pulled by one black and one white sphinx. "
        "Armor with celestial symbols. Canopy of stars above. City behind."
    ),
    "正義": (
        "A crowned figure on stone throne between two pillars. "
        "Raised sword in right hand. Golden balanced scales in left. Symmetrical composition."
    ),
    "隠者": (
        "An old man in hooded robes stands atop a mountain peak. "
        "Holds a glowing lantern with a star and a long wooden staff. Deep night sky."
    ),
}

# Unique visual modifiers for each 二つ名
# Format: (sei, mei, guardian_jp, futatsuna_jp, english_name, visual_modifier)
CARDS = [
    # 姓数1
    (1, 1, "女教皇", "双炎の女教皇", "High Priestess of Twin Flames",
     "Two flames burn at the crown of her head. Dual candles flank the pillars, flames leaning toward each other."),
    (1, 2, "女帝", "真実を育む女帝", "Empress Who Nurtures Truth",
     "She cradles a glowing crystal orb of truth. Vines of light grow from where she touches the earth."),
    (1, 3, "皇帝", "閃光を統べる皇帝", "Emperor Who Commands Lightning",
     "Lightning bolts arc from his scepter. Electric energy crackles around his throne."),
    (1, 4, "教皇", "礎を説く教皇", "Hierophant Who Teaches Foundations",
     "Stone tablets of wisdom float before him. His throne is built on ancient bedrock with visible layers."),
    (1, 5, "恋人", "自由を選ぶ恋人", "Lovers Who Choose Freedom",
     "One figure reaches toward an open door of light. Birds fly free around them. Broken chains at feet."),
    (1, 6, "戦車", "渇望の戦車", "Chariot of Yearning",
     "The chariot charges toward a distant burning star. Flames trail behind the wheels."),
    (1, 7, "正義", "挑戦する正義", "Justice Who Challenges",
     "The sword is raised in a striking pose rather than held still. Sparks fly from the scales."),
    (1, 8, "隠者", "星を追う隠者", "Hermit Who Chases Stars",
     "He reaches toward a brilliant star above. His lantern projects star maps onto the mountain."),
    (1, 9, "魔術師", "始原の魔術師", "Primordial Magician",
     "Ancient cosmic energy swirls around him. The table items glow with primordial fire. Genesis light."),

    # 姓数2
    (2, 1, "女帝", "静寂に芽吹く女帝", "Empress Who Blooms in Silence",
     "Flowers bloom silently around her in still air. A quiet pond reflects her image perfectly."),
    (2, 2, "皇帝", "共鳴する皇帝", "Resonating Emperor",
     "Sound waves ripple visibly from his throne. Twin tuning forks on the armrests vibrate in harmony."),
    (2, 3, "教皇", "感性を伝える教皇", "Hierophant of Sensibility",
     "Rainbow light emanates from his blessing hand. Musical notes float in the air around him."),
    (2, 4, "恋人", "心を映す恋人", "Lovers Who Mirror Hearts",
     "A large mirror between the two figures reflects their inner selves. Heart-shaped light above."),
    (2, 5, "戦車", "調和を駆る戦車", "Chariot of Harmony",
     "The two sphinxes move in perfect synchrony. Gentle music notes trail the chariot path."),
    (2, 6, "正義", "慈愛の正義", "Justice of Compassion",
     "The sword is sheathed. Both hands hold the scales gently. Soft golden light emanates from heart."),
    (2, 7, "隠者", "霧中の隠者", "Hermit in the Mist",
     "Dense fog surrounds the mountain. His lantern cuts through the mist. Ghostly shapes in the fog."),
    (2, 8, "魔術師", "鏡映しの魔術師", "Mirror Magician",
     "A large ornate mirror behind him shows a reversed reflection. The table items are doubled."),
    (2, 9, "女教皇", "夢渡りの女教皇", "High Priestess Who Walks Dreams",
     "Dreamlike clouds swirl around her feet. Stars fall like snow. The veil shows dream visions."),

    # 姓数3
    (3, 1, "皇帝", "華やぐ皇帝", "Flourishing Emperor",
     "Flowers and vines grow up his throne. Cherry blossoms fall around him. Colorful banners."),
    (3, 2, "教皇", "彩りの教皇", "Hierophant of Colors",
     "Stained glass windows cast rainbow light. His robes shimmer with many colors."),
    (3, 3, "恋人", "万華鏡の恋人", "Kaleidoscope Lovers",
     "Kaleidoscope patterns radiate from between the two figures. Prismatic light everywhere."),
    (3, 4, "戦車", "創造を駆る戦車", "Chariot of Creation",
     "Paint and color splash from the chariot wheels. The path behind blooms with flowers."),
    (3, 5, "正義", "物語を紡ぐ正義", "Justice Who Weaves Stories",
     "Instead of a sword, holds a golden quill pen. The scales weigh open books. Story scrolls unfurl."),
    (3, 6, "隠者", "花園の隠者", "Hermit of the Garden",
     "The mountain peak is replaced by a lush secret garden. Roses grow around his staff."),
    (3, 7, "魔術師", "舞台を創る魔術師", "Magician Who Creates the Stage",
     "A theater curtain frames the scene. Spotlights illuminate him. The table is a stage prop."),
    (3, 8, "女教皇", "虹を映す女教皇", "High Priestess of Rainbows",
     "A rainbow arc crowns her head instead of the moon. Prismatic light through the veil."),
    (3, 9, "女帝", "幻想の女帝", "Empress of Fantasy",
     "Fantastical creatures peek from behind her throne. Unicorn, phoenix feathers. Dreamlike garden."),

    # 姓数4
    (4, 1, "教皇", "礎を据える教皇", "Hierophant Who Lays Foundations",
     "He places a cornerstone with ceremonial gravitas. Architectural blueprints float around him."),
    (4, 2, "恋人", "鉄壁の恋人", "Ironclad Lovers",
     "Both figures wear partial armor. A strong shield between them. Fortress wall behind."),
    (4, 3, "戦車", "秩序の戦車", "Chariot of Order",
     "The chariot moves along perfectly straight rails. Geometric patterns on the ground. Grid lines."),
    (4, 4, "正義", "不動の正義", "Immovable Justice",
     "The throne is carved from a single massive stone. Roots grow from its base deep into earth."),
    (4, 5, "隠者", "規律を超えし隠者", "Hermit Beyond Discipline",
     "He walks past a broken wall of rules. Behind him is rigid structure, ahead is wild mountain."),
    (4, 6, "魔術師", "盾を持つ魔術師", "Magician with Shield",
     "One hand holds a shield instead of pointing up. Protective barrier glows around the table."),
    (4, 7, "女教皇", "要塞の女教皇", "Fortress High Priestess",
     "The two pillars are fortress towers. Castle walls extend behind the veil. Iron gate."),
    (4, 8, "女帝", "鋼鉄の女帝", "Steel Empress",
     "Her throne is made of polished steel. Iron roses instead of organic ones. Strong and elegant."),
    (4, 9, "皇帝", "永劫の皇帝", "Eternal Emperor",
     "Ancient beyond measure. Hourglass with frozen sand. Eternal flame on throne. Timeless landscape."),

    # 姓数5
    (5, 1, "恋人", "風に乗る恋人", "Lovers on the Wind",
     "Both figures float slightly above ground. Wind carries flower petals around them. Flowing hair."),
    (5, 2, "戦車", "旅する戦車", "Traveling Chariot",
     "The chariot is on a winding road through diverse landscapes. Maps and compass on the chariot."),
    (5, 3, "正義", "自由なる正義", "Free Justice",
     "The figure stands rather than sits. No throne. Open sky behind. The scales balance freely in wind."),
    (5, 4, "隠者", "放浪の隠者", "Wandering Hermit",
     "Walking stick and travel pack. Many paths branch from where he stands. Worn boots. Map in hand."),
    (5, 5, "魔術師", "境界なき魔術師", "Boundless Magician",
     "No table, items float freely around him. The floor dissolves into starfield. No walls, no limits."),
    (5, 6, "女教皇", "冒険する女教皇", "Adventurous High Priestess",
     "She stands instead of sitting. One foot steps forward past the pillars. Explorer's compass in hand."),
    (5, 7, "女帝", "疾風の女帝", "Empress of Swift Wind",
     "Strong wind blows through her garden. Her robes and hair stream dramatically. Birds in flight."),
    (5, 8, "皇帝", "自由を統べる皇帝", "Emperor Who Commands Freedom",
     "His throne has no back, open to the sky. Eagles soar behind him. Broken chains as decoration."),
    (5, 9, "教皇", "果てなき教皇", "Limitless Hierophant",
     "The pillars extend infinitely upward. The ceiling is open sky. Endless staircase behind."),

    # 姓数6
    (6, 1, "戦車", "愛を貫く戦車", "Chariot of Devoted Love",
     "A heart emblem blazes on the chariot front. Rose garlands wrap the reins. Warm golden light."),
    (6, 2, "正義", "慈愛を量る正義", "Justice Who Weighs Compassion",
     "One scale holds a heart, the other a feather. Gentle expression. Warm light from the scales."),
    (6, 3, "隠者", "花を知る隠者", "Hermit Who Knows Flowers",
     "Flowers grow where his staff touches. His lantern projects flower patterns. Garden on the peak."),
    (6, 4, "魔術師", "絆を紡ぐ魔術師", "Magician Who Weaves Bonds",
     "Golden threads connect his hands to each item on the table. Web of connections radiates outward."),
    (6, 5, "女教皇", "愛の女教皇", "High Priestess of Love",
     "Heart-shaped moonlight. The scroll shows love poems. Rose petals fall like snow around her."),
    (6, 6, "女帝", "薔薇の女帝", "Empress of Roses",
     "Surrounded entirely by red and white roses. Rose crown. Rose patterns on throne. Rose garden."),
    (6, 7, "皇帝", "美しき皇帝", "Beautiful Emperor",
     "Exceptionally ornate and elegant throne. Fine art on walls. Aesthetic beauty in every detail."),
    (6, 8, "教皇", "愛を説く教皇", "Hierophant Who Teaches Love",
     "He holds hands of the two kneeling figures. Heart-shaped light from blessing hand. Warm glow."),
    (6, 9, "恋人", "慈悲深き恋人", "Deeply Compassionate Lovers",
     "The angel's wings wrap protectively around both figures. Healing light. Tears of joy falling."),

    # 姓数7
    (7, 1, "正義", "勝利の正義", "Victorious Justice",
     "Laurel wreath on sword. Trophy at feet. Victory banner behind the throne."),
    (7, 2, "隠者", "戦場を超えし隠者", "Hermit Beyond the Battlefield",
     "Behind him, a distant battlefield with smoke. He walks away from war toward peaceful mountain."),
    (7, 3, "魔術師", "閃光の魔術師", "Flash Magician",
     "Lightning speed lines around his hands. The items on table blur with motion. Electric energy."),
    (7, 4, "女教皇", "戦場の女教皇", "Battlefield High Priestess",
     "The pillars bear sword marks. A shield leans against one pillar. She remains calm amid chaos."),
    (7, 5, "女帝", "勝利を育む女帝", "Empress Who Nurtures Victory",
     "Laurel trees grow in her garden. Victory trophies among the flowers. Golden crown of triumph."),
    (7, 6, "皇帝", "覇道の皇帝", "Emperor of Conquest",
     "Military banners and conquered flags behind throne. Sword and scepter both in hands. War map."),
    (7, 7, "教皇", "孤高の教皇", "Solitary Hierophant",
     "Empty space around him, no followers. He preaches to the wind alone. Single candle. Austere."),
    (7, 8, "恋人", "剣を捧げる恋人", "Lovers Who Offer a Sword",
     "One figure offers a sword to the other as a gift. The angel holds an olive branch. Solemn vow."),
    (7, 9, "戦車", "覇王の戦車", "Conqueror's Chariot",
     "Massive war chariot with blade wheels. Crown of thorns and gold. Army behind. Epic scale."),

    # 姓数8
    (8, 1, "隠者", "正義を超えし隠者", "Hermit Beyond Justice",
     "Broken scales at his feet as he ascends. He has moved past judgment into pure wisdom."),
    (8, 2, "魔術師", "公正なる魔術師", "Fair Magician",
     "Small scales balance on the table alongside the four items. Even light on both sides."),
    (8, 3, "女教皇", "真実を映す女教皇", "High Priestess Who Reflects Truth",
     "Her scroll is a mirror that shows true reflections. Crystal clear water at her feet."),
    (8, 4, "女帝", "法を育む女帝", "Empress Who Nurtures Law",
     "Law books grow like plants in her garden. Gavel among the flowers. Order within nature."),
    (8, 5, "皇帝", "正道の皇帝", "Emperor of the Right Path",
     "A single straight golden path leads to his throne. No detours. Pure righteous light."),
    (8, 6, "教皇", "義と愛の教皇", "Hierophant of Justice and Love",
     "One hand holds scales, the other blesses. Heart and sword crossed on his chest."),
    (8, 7, "恋人", "裁きの恋人", "Lovers of Judgment",
     "The angel holds scales instead of blessing. Both figures accept the judgment willingly."),
    (8, 8, "戦車", "因果を駆る戦車", "Chariot of Karma",
     "Wheel of karma symbols on the chariot. Past and future merge in the path. Cause and effect."),
    (8, 9, "正義", "究極の正義", "Ultimate Justice",
     "The largest throne, the brightest sword. Perfect geometric symmetry. Absolute balance."),

    # 姓数9
    (9, 1, "魔術師", "悟りの魔術師", "Enlightened Magician",
     "Third eye open on forehead. Lotus flower blooms above. The items on table levitate. Zen circles."),
    (9, 2, "女教皇", "万象の女教皇", "High Priestess of All Phenomena",
     "The veil shows all seasons simultaneously. Four elements swirl around her. Cosmic patterns."),
    (9, 3, "女帝", "夢幻の女帝", "Empress of Dreams",
     "Reality dissolves into dream around her throne. Butterflies made of light. Surreal garden."),
    (9, 4, "皇帝", "悠久の皇帝", "Emperor of Eternity",
     "His throne floats in space among stars. Infinite landscape. Ageless face. Cosmic crown."),
    (9, 5, "教皇", "叡智の教皇", "Hierophant of Wisdom",
     "Ancient library surrounds him. Floating books. Owl on shoulder. Wisdom light from eyes."),
    (9, 6, "恋人", "無償の恋人", "Selfless Lovers",
     "Both figures give everything to each other. Empty hands, full hearts. Pure white light."),
    (9, 7, "戦車", "超越の戦車", "Transcendent Chariot",
     "The chariot ascends into the sky, leaving the ground behind. Cloud road. Stars as destination."),
    (9, 8, "正義", "天命の正義", "Justice of Divine Destiny",
     "Heavenly light descends onto the scales. Divine symbols on the sword. Celestial court."),
    (9, 9, "隠者", "輪廻の隠者", "Hermit of Reincarnation",
     "Circular path spiraling upward. Multiple ghostly past selves on the path behind. Infinite loop."),
]

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), 'card-images')
os.makedirs(OUTPUT_DIR, exist_ok=True)


def generate_card(card_data, max_retries=3):
    sei, mei, guardian_jp, futatsuna, eng_name, visual_mod = card_data
    filename = f"{sei}_{mei}_{guardian_jp}.png"
    filepath = os.path.join(OUTPUT_DIR, filename)

    if os.path.exists(filepath):
        print(f"  SKIP (exists): {filename}")
        return True

    base_scene = GUARDIAN_SCENES[guardian_jp]
    prompt = (
        f'"{eng_name}" original tarot card. '
        f'{base_scene} '
        f'{visual_mod} '
        f'{STYLE}'
    )

    for attempt in range(1, max_retries + 1):
        print(f"  [{attempt}/{max_retries}] {futatsuna} ({len(prompt)} chars)...", end=' ', flush=True)

        try:
            response = client.models.generate_content(
                model=MODEL,
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_modalities=['IMAGE'],
                )
            )

            if response.candidates and response.candidates[0].content.parts:
                for part in response.candidates[0].content.parts:
                    if part.inline_data and part.inline_data.data:
                        with open(filepath, 'wb') as f:
                            f.write(part.inline_data.data)
                        print(f"OK ({len(part.inline_data.data)//1024}KB)")
                        return True
            print("FAIL (no image)")

        except Exception as e:
            err = str(e)
            print(f"ERROR: {err[:100]}")

        if attempt < max_retries:
            wait = 10 * attempt
            print(f"  Retrying in {wait}s...")
            time.sleep(wait)

    return False


def main():
    batch = sys.argv[1] if len(sys.argv) > 1 else 'all'

    if batch == '1':
        cards = [c for c in CARDS if c[0] in (1, 2, 3)]
    elif batch == '2':
        cards = [c for c in CARDS if c[0] in (4, 5, 6)]
    elif batch == '3':
        cards = [c for c in CARDS if c[0] in (7, 8, 9)]
    elif batch == 'all':
        cards = CARDS
    else:
        print(f"Usage: python generate_all_cards.py [1|2|3|all]")
        sys.exit(1)

    print(f"\n{'='*50}")
    print(f"  Generating {len(cards)} Naura cards (batch: {batch})")
    print(f"{'='*50}")

    success = 0
    fail = 0
    for card in cards:
        ok = generate_card(card)
        if ok:
            success += 1
        else:
            fail += 1
        time.sleep(5)

    print(f"\n{'='*50}")
    print(f"  TOTAL: {success} OK, {fail} FAIL")
    print(f"{'='*50}")


if __name__ == '__main__':
    main()
