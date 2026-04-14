"""
Solara タロットカード全78枚一括生成 (Nanobanana2 / Gemini API)
- 大アルカナ: v4フレーム（コーナー装飾＋上下ライン）
- 小アルカナ: シンプルフレーム
- 画風: ヨハネス・フェルメール
Usage: python generate_all_cards.py
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

from google import genai
from google.genai import types

API_KEY = os.environ.get("GEMINI_API_KEY")
if not API_KEY:
    print("ERROR: GEMINI_API_KEY not found")
    sys.exit(1)

client = genai.Client(api_key=API_KEY)
output_dir = Path(__file__).parent
output_dir.mkdir(parents=True, exist_ok=True)

# ============================================================
# スタイル定義
# ============================================================

VERMEER_STYLE = """
ART STYLE — Johannes Vermeer:
- Render in the style of Johannes Vermeer's oil paintings
- Soft, luminous light pouring from the upper left, creating Vermeer's signature warm golden glow
- Rich, deep color palette: ultramarine blue, vermilion red, ochre yellow, lead white
- Vermeer's characteristic pointillé technique for highlights (tiny dots of light on surfaces)
- Subtle chiaroscuro with smooth tonal gradations
- Meticulous attention to fabric textures: silk, velvet, linen rendered with photorealistic detail
- Atmospheric perspective in the background landscape
- The scene should feel like a Dutch Golden Age painting come to life
"""

FRAME_MAJOR = """
CARD FRAME (Major Arcana):
- The card background and border area must be DARK — deep black, NO white or cream margins anywhere
- Thin gold double-line border as the base
- The painting area must remain large — do NOT shrink the image to make room for heavy decoration
- Elegant gold corner ornaments at all four corners (with small leaf/curl motif)
- A subtle thin gold decorative line or tiny repeating dot pattern running along the top and bottom edges ONLY
- The sides remain clean double-line only — no decoration on left/right edges
- This should feel like a refined picture frame upgrade, NOT a heavy baroque border
- Inner border has a fine dark line, outer border is burnished gold
- Narrow gap between the image and the frame, filled with black
"""

FRAME_MINOR = """
CARD FRAME (Minor Arcana):
- The card background and border area must be DARK — deep black, NO white or cream margins anywhere
- Simple but luxurious thin gold border
- Clean elegant double-line frame with subtle corner ornaments
- Inner border has a fine dark line, outer border is burnished gold
- No baroque excess — refined and minimal elegance
- Narrow gap between the image and the frame, filled with black
"""

TECHNICAL = """
TECHNICAL:
- Card dimensions 2:3 ratio (portrait orientation)
- No text, no numbers, no letters, no card name anywhere on the image
- High detail, museum quality
- The entire card including frame must be on a SOLID BLACK or very dark background — absolutely NO white borders or light-colored margins
"""

# ============================================================
# 全78枚カード定義
# ============================================================

MAJOR_ARCANA = [
    ("00_the_fool", "The Fool", "A young man in colorful medieval clothing stands at the edge of a cliff, gazing upward at the sky with a carefree expression. A small white dog leaps playfully at his feet. He carries a small bundle tied to a stick over his shoulder. A bright sun shines behind him. He holds a white rose in one hand."),
    ("01_the_magician", "The Magician", "A robed figure stands behind a table with a cup, sword, pentacle coin, and wand. One hand points to sky, other to earth. Infinity symbol above his head. Red roses and white lilies surround him."),
    ("02_the_high_priestess", "The High Priestess", "A woman in blue and white robes sits between two pillars, one black and one white. She holds a scroll partially hidden by her cloak. Crescent moon at her feet. A veil with pomegranates behind her. Lunar crown."),
    ("03_the_empress", "The Empress", "A crowned woman sits on a luxurious throne in a lush garden. Flowing robes with pomegranates. Crown of twelve stars. Heart-shaped shield with Venus symbol. Wheat field and waterfall in background."),
    ("04_the_emperor", "The Emperor", "A bearded man in red robes sits on a stone throne with four ram heads. Golden scepter and orb. Crown on head. Barren mountains behind. Armor beneath robes. Commanding pose."),
    ("05_the_hierophant", "The Hierophant", "A religious figure in red and gold papal robes on a throne between two grey pillars. Raises hand in blessing. Two crossed golden keys at feet. Two acolytes kneel before him. Triple crown tiara."),
    ("06_the_lovers", "The Lovers", "A man and woman stand beneath a large angel with purple wings. Angel blesses them from above. Behind woman, tree with fruit and serpent. Behind man, tree with flames. Radiant sun above. Garden of Eden."),
    ("07_the_chariot", "The Chariot", "A warrior in a golden chariot pulled by one black and one white sphinx. Armor with crescent moons and stars. Canopy of stars above. City skyline behind. Laurel crown."),
    ("08_strength", "Strength", "A gentle woman in white robes calmly opens the jaws of a golden lion. Infinity symbol above her head. Garland of flowers in her hair. Green meadow and mountains in background."),
    ("09_the_hermit", "The Hermit", "An old man in grey hooded robes stands atop a snowy mountain peak. Holds a glowing lantern with six-pointed star and a long wooden staff. Deep blue night sky. Alone in contemplation."),
    ("10_wheel_of_fortune", "Wheel of Fortune", "A large golden wheel in cloudy sky with symbols around its rim. Sphinx atop holding sword. Red serpent descends left. Anubis figure rises right. Four winged creatures in corners with books."),
    ("11_justice", "Justice", "A crowned figure on stone throne between two pillars. Raised double-edged sword in right hand. Golden balanced scales in left. Red and green robes. Purple veil behind. Symmetrical composition."),
    ("12_the_hanged_man", "The Hanged Man", "A man hangs upside down from a wooden T-cross of living wood with green leaves. Right foot tied, left leg crosses behind right knee. Hands behind back. Golden halo around head."),
    ("13_death", "Death", "A skeleton in black armor rides a white horse carrying a black flag with white rose. A king lies fallen, bishop prays, maiden turns away, child offers flowers. River with ship. Sun rises between two towers."),
    ("14_temperance", "Temperance", "A winged angel in white and blue robes pours water between two golden cups. One foot on land, one in water. Path leads to distant mountains with golden light. Irises at water's edge."),
    ("15_the_devil", "The Devil", "A mythological horned figure with wings sits on a dark pedestal in a classical art style. Two small figures stand below with loose chains. A pentagram symbol above. Dark atmospheric background."),
    ("16_the_tower", "The Tower", "A tall stone tower struck by lightning. Crown-shaped top blown off in flames. Two figures fall from tower. Flames from windows. Golden drops fall through dark stormy sky."),
    ("17_the_star", "The Star", "A woman kneels at edge of a pool under starlit sky. Pours water from two jugs onto land and into pool. One large eight-pointed golden star above, seven smaller white stars. Bird in tree behind."),
    ("18_the_moon", "The Moon", "A large golden moon with face in dark blue sky. Path between two grey towers into mountains. Dog and wolf howl at moon from either side. Crayfish emerges from pool in foreground."),
    ("19_the_sun", "The Sun", "A child rides a white horse under a huge bright golden sun with a face. Child holds a red banner. Tall sunflowers behind a grey stone wall. Golden rays radiate from sun."),
    ("20_judgement", "Judgement", "A great angel with golden wings blows trumpet from a cloud. Red cross flag on trumpet. Below, people rise from coffins with arms outstretched toward angel. Snowy mountains in background."),
    ("21_the_world", "The World", "A dancing figure in purple sash holds a wand in each hand inside an oval laurel wreath with red ribbons. Four winged creatures in corners: angel, eagle, bull, lion. Starry sky background."),
]

MINOR_ARCANA = [
    # Wands (22-35)
    ("22_ace_of_wands", "Ace of Wands", "A hand emerges from a cloud holding a single living wooden wand with green leaves sprouting from it. A castle on a distant hill. Rolling green landscape below. Leaves falling from the wand."),
    ("23_two_of_wands", "Two of Wands", "A man stands on a castle battlement holding a small globe in one hand and a tall wand in the other. A second wand is fixed to the wall beside him. He gazes out over a vast sea and distant mountains."),
    ("24_three_of_wands", "Three of Wands", "A man stands on a cliff overlooking the sea, holding one wand with two more planted beside him. Ships sail on the distant water. He watches from a high vantage point. Golden cloak."),
    ("25_four_of_wands", "Four of Wands", "Four tall wands form a canopy decorated with garlands of flowers and fruit. Two figures in the foreground raise bouquets in celebration. A castle or large estate in the background."),
    ("26_five_of_wands", "Five of Wands", "Five young men brandish wands in a chaotic skirmish. Each person holds a wand at different angles, appearing to clash with each other. No one is clearly winning. Open ground beneath them."),
    ("27_six_of_wands", "Six of Wands", "A man rides a white horse through a crowd, holding a wand with a laurel wreath on top. Five other wands are raised by the crowd around him. Triumphal victory procession. The rider wears a laurel crown."),
    ("28_seven_of_wands", "Seven of Wands", "A man stands on a hilltop defending his position with a single wand against six wands rising from below. He has the high ground advantage. Determined defensive stance."),
    ("29_eight_of_wands", "Eight of Wands", "Eight wands fly diagonally through the air over a green landscape with a river below. The wands are in parallel formation, soaring swiftly across a clear sky. No human figures. Rolling hills and water."),
    ("30_nine_of_wands", "Nine of Wands", "A weary man leans on a wand, looking over his shoulder with suspicion. Eight other wands stand upright behind him like a fence. He has a bandage on his head. Battle-worn but still standing."),
    ("31_ten_of_wands", "Ten of Wands", "A man struggles to carry ten heavy wands bundled together, walking toward a distant town. He is bent over under the weight, barely able to see ahead. A village with houses in the background."),
    ("32_page_of_wands", "Page of Wands", "A young person in a feathered hat and tunic stands in a desert landscape, holding a tall wand with both hands and gazing up at it with curiosity. Pyramids or mountains in the far background. Salamanders decorate the tunic."),
    ("33_knight_of_wands", "Knight of Wands", "An armored knight rides a rearing horse at full gallop, holding a wand high. His armor and horse's trappings are decorated with salamanders. Desert landscape with pyramids in background. The horse is fiery and energetic."),
    ("34_queen_of_wands", "Queen of Wands", "A queen sits on a throne decorated with lions and sunflowers, holding a wand in one hand and a sunflower in the other. A black cat sits at her feet. Yellow robes. Sunflowers surround the throne."),
    ("35_king_of_wands", "King of Wands", "A king sits on a throne decorated with lions and salamanders, holding a living wand with leaves. He wears a crown and cape with salamander symbols. A small salamander sits at his feet. Desert background."),
    # Cups (36-49)
    ("36_ace_of_cups", "Ace of Cups", "A hand emerges from a cloud holding a golden chalice overflowing with five streams of water. A dove descends into the cup carrying a communion wafer. Water lilies float on the water below."),
    ("37_two_of_cups", "Two of Cups", "A young man and woman face each other, exchanging golden cups. A winged lion head with a caduceus floats above them. They pledge to each other in a garden setting. Harmonious equal partnership."),
    ("38_three_of_cups", "Three of Cups", "Three women raise their cups together in a toast, standing in a garden surrounded by fruits and flowers on the ground. Garlands in their hair. Celebration and harvest. They dance together in a circle."),
    ("39_four_of_cups", "Four of Cups", "A young man sits under a tree with arms crossed, staring at three cups on the ground before him. A hand from a cloud offers a fourth cup, but he does not notice or ignores it. Meditative discontent."),
    ("40_five_of_cups", "Five of Cups", "A cloaked figure in black stands before three spilled cups on the ground, with red and green liquid flowing out. Two cups remain standing behind the figure, unnoticed. A bridge leads to a distant castle over a river."),
    ("41_six_of_cups", "Six of Cups", "A young boy offers a cup filled with white flowers to a younger girl in a garden. Six cups arranged around them, each filled with flowers. An old stone house and village in the background. Nostalgic scene."),
    ("42_seven_of_cups", "Seven of Cups", "A silhouetted figure stands before seven cups floating in clouds. Each cup contains a different vision: a castle, jewels, a laurel wreath, a dragon, a glowing figure, a snake, and a veiled mysterious head."),
    ("43_eight_of_cups", "Eight of Cups", "A man walks away from eight neatly stacked cups, heading toward mountains under a crescent moon in a dark sky. He carries a walking staff. The cups are arranged in two rows with a gap. Rocky terrain."),
    ("44_nine_of_cups", "Nine of Cups", "A well-dressed man sits on a wooden bench with arms crossed in satisfaction. Behind him on a curved shelf, nine golden cups are displayed in a neat row. Blue draped cloth behind the cups."),
    ("45_ten_of_cups", "Ten of Cups", "A couple stands together with arms raised toward a rainbow of ten cups in the sky. Two children dance and play beside them. A cozy cottage and rolling green hills with a river in the background."),
    ("46_page_of_cups", "Page of Cups", "A young person in a blue tunic and beret stands by the sea, holding a cup from which a small fish pops out. He looks at the fish with wonder. Waves on the shore behind."),
    ("47_knight_of_cups", "Knight of Cups", "A knight in shining armor rides a calm white horse at a slow graceful pace, holding a golden cup forward as if offering it. Wings on his helmet. A river and green landscape."),
    ("48_queen_of_cups", "Queen of Cups", "A queen sits on an ornate throne at the edge of the sea, gazing at a beautiful elaborate covered cup she holds with both hands. The throne is decorated with sea nymphs and fish. Pebbles and water at her feet."),
    ("49_king_of_cups", "King of Cups", "A king sits on a stone throne floating on a turbulent sea, holding a cup in one hand and a scepter in the other. He remains calm despite the rough waters. A ship sails on one side, a dolphin leaps on the other."),
    # Swords (50-63)
    ("50_ace_of_swords", "Ace of Swords", "A hand emerges from a cloud gripping a great upright sword. A golden crown sits on the sword tip with an olive branch on one side and a palm frond on the other. Rocky mountains below. Grey dramatic sky."),
    ("51_two_of_swords", "Two of Swords", "A blindfolded woman sits on a stone bench holding two crossed swords over her chest. A crescent moon in the sky. Calm sea with rocky islands behind her. Perfect balance and stillness. White robes."),
    ("52_three_of_swords", "Three of Swords", "A large red heart pierced by three swords. Heavy rain falls from dark grey storm clouds behind the heart. No human figures. Simple powerful symbolic image of heartbreak and sorrow."),
    ("53_four_of_swords", "Four of Swords", "A knight lies in repose on a stone tomb inside a chapel, hands clasped in prayer. Three swords hang on the wall above, one sword lies beneath the tomb. A stained glass window shows a scene of blessing. Peaceful rest."),
    ("54_five_of_swords", "Five of Swords", "A man holds three swords and looks back at two retreating figures who have dropped their swords on the ground. Stormy sky with jagged clouds. The victor stands alone with a sense of hollow triumph. Sea in background."),
    ("55_six_of_swords", "Six of Swords", "A boatman ferries a cloaked woman and child across calm water in a small boat. Six swords stand upright in the bow of the boat. The water is rough on one side and calm on the other. Moving toward a distant shore."),
    ("56_seven_of_swords", "Seven of Swords", "A man sneaks away from a military camp carrying five swords, leaving two behind still stuck in the ground. He looks back over his shoulder. Colorful tents in the background. Stealthy tiptoeing pose."),
    ("57_eight_of_swords", "Eight of Swords", "A blindfolded and bound woman stands surrounded by eight swords stuck in the muddy ground around her. A castle on a rocky cliff in the distance. Water puddles at her feet. She appears trapped but the bindings are loose."),
    ("58_nine_of_swords", "Nine of Swords", "A person sits up in bed in the dark, covering their face with their hands in despair. Nine swords hang horizontally on the black wall behind them. A quilt decorated with roses and astrological symbols covers the bed."),
    ("59_ten_of_swords", "Ten of Swords", "A figure lies face down on the ground with ten swords in their back. A dark sky above but golden dawn light appears on the distant horizon over calm water. Red cloak draped over the lower body."),
    ("60_page_of_swords", "Page of Swords", "A young person stands on windswept high ground holding a sword upright with both hands, looking over their shoulder alertly. Wind blows through their hair. Clouds race across the sky. Birds fly in the distance."),
    ("61_knight_of_swords", "Knight of Swords", "An armored knight charges forward on a galloping horse at full speed, sword raised high. His cape flies behind him. Storm clouds and wind-bent trees in the background. Butterflies on the horse's trappings."),
    ("62_queen_of_swords", "Queen of Swords", "A queen sits on a stone throne high in the clouds, holding a sword upright in her right hand, left hand extended. Her throne is decorated with butterflies and a cherub. She faces to the side in profile. Crown with butterfly motif."),
    ("63_king_of_swords", "King of Swords", "A king sits on a high throne holding a large sword in his right hand, slightly tilted. Blue robes over armor. His throne is decorated with butterflies and crescent moons. Trees bend in the wind behind him."),
    # Pentacles (64-77)
    ("64_ace_of_pentacles", "Ace of Pentacles", "A hand emerges from a cloud holding a large golden pentacle coin with a star engraved on it. Below is a lush garden with an archway of hedges leading to distant mountains. White lilies bloom in the garden."),
    ("65_two_of_pentacles", "Two of Pentacles", "A young man dances while juggling two pentacle coins connected by an infinity-shaped ribbon. He wears a tall hat. Two ships ride enormous waves on the sea behind him. Playful balancing act."),
    ("66_three_of_pentacles", "Three of Pentacles", "A stonemason works on a cathedral arch while a monk and a nobleman consult architectural plans nearby. Three pentacles are carved into the stone arch above. Gothic church interior. Collaborative craftsmanship."),
    ("67_four_of_pentacles", "Four of Pentacles", "A man sits on a stone block clutching a pentacle tightly to his chest. One pentacle balances on his head, and one sits under each foot. A city skyline behind him. Possessive guarded posture."),
    ("68_five_of_pentacles", "Five of Pentacles", "Two ragged figures walk through snow past a lit stained glass church window showing five pentacles. One person is on crutches with a bandaged foot, the other is barefoot and shivering in a thin shawl. Cold winter night."),
    ("69_six_of_pentacles", "Six of Pentacles", "A wealthy merchant in fine robes holds balanced scales in one hand and gives gold coins to two kneeling beggars with the other. Six pentacles float in the air around the scene. Generous giving and receiving."),
    ("70_seven_of_pentacles", "Seven of Pentacles", "A young farmer leans on his hoe, gazing at a bush bearing seven pentacles like fruit. He pauses from work to assess his harvest. Green garden setting. Patient contemplation of results."),
    ("71_eight_of_pentacles", "Eight of Pentacles", "A craftsman sits at a workbench carefully carving a pentacle on a coin. Six finished pentacles hang on a post beside him, one more sits on the bench. A town visible in the far distance. Diligent focused craftsmanship."),
    ("72_nine_of_pentacles", "Nine of Pentacles", "An elegant woman stands alone in a lush vineyard garden with nine pentacles growing on the vines around her. A hooded falcon perches on her gloved left hand. She wears fine robes. A snail at her feet. A manor house in the background."),
    ("73_ten_of_pentacles", "Ten of Pentacles", "An elderly man in ornate robes sits in an archway of a grand estate with two dogs at his feet. A young couple and a child stand nearby. Ten pentacles are arranged in a Tree of Life pattern across the scene. Family wealth and legacy."),
    ("74_page_of_pentacles", "Page of Pentacles", "A young person stands in a green meadow, holding up a single pentacle coin and gazing at it with fascination. Plowed fields and trees in the background. Mountains in the distance. Green tunic and cap."),
    ("75_knight_of_pentacles", "Knight of Pentacles", "A knight in heavy dark armor sits on a sturdy black workhorse that stands completely still. He holds a single pentacle before him, studying it carefully. Plowed farmland stretches behind him. Oak leaves on his helmet."),
    ("76_queen_of_pentacles", "Queen of Pentacles", "A queen sits on a stone throne decorated with fruit, angels, and goats, cradling a golden pentacle in her lap. She is surrounded by a lush rose garden. A rabbit hops near her feet. Abundant nature."),
    ("77_king_of_pentacles", "King of Pentacles", "A king in luxurious robes decorated with grape vines sits on a throne adorned with bull heads. He holds a golden scepter in one hand and rests a pentacle on his knee with the other. A castle and abundant gardens behind him."),
]


def build_prompt(card_name, scene, is_major):
    frame = FRAME_MAJOR if is_major else FRAME_MINOR
    return f"""Generate a single tarot card image: "{card_name}".

COMPOSITION (Rider-Waite based):
{scene}

{VERMEER_STYLE}
{frame}
{TECHNICAL}
"""


def generate_card(filename, card_name, scene, is_major):
    out_path = output_dir / f"{filename}.png"
    if out_path.exists():
        print(f"SKIP (exists): {out_path.name}")
        return True

    prompt = build_prompt(card_name, scene, is_major)

    max_retries = 3
    for attempt in range(max_retries):
        try:
            response = client.models.generate_content(
                model="gemini-3.1-flash-image-preview",
                contents=[prompt],
                config=types.GenerateContentConfig(
                    response_modalities=["TEXT", "IMAGE"],
                ),
            )
            for part in response.parts:
                if part.inline_data is not None:
                    image = part.as_image()
                    image.save(str(out_path))
                    print(f"OK: {out_path.name}")
                    return True
                elif part.text is not None:
                    print(f"  (model: {part.text[:80]})")

            print(f"FAIL (no image): {filename}")
            return False

        except Exception as e:
            err_msg = str(e).encode("ascii", "replace").decode("ascii")
            print(f"ERROR (attempt {attempt+1}/{max_retries}): {filename} - {err_msg}")
            if attempt < max_retries - 1:
                wait = 10 * (attempt + 1)
                print(f"  Retrying in {wait}s...")
                time.sleep(wait)
            else:
                print(f"GIVE UP: {filename}")
                return False


def main():
    total = len(MAJOR_ARCANA) + len(MINOR_ARCANA)
    done = 0
    failed = []

    print(f"=== Solara Tarot Card Generation ===")
    print(f"Total: {total} cards (Major: {len(MAJOR_ARCANA)}, Minor: {len(MINOR_ARCANA)})")
    print(f"Style: Vermeer | Model: gemini-3.1-flash-image-preview")
    print(f"Output: {output_dir}")
    print()

    # 大アルカナ
    print("--- Major Arcana (22 cards) ---")
    for filename, name, scene in MAJOR_ARCANA:
        ok = generate_card(filename, name, scene, is_major=True)
        done += 1
        if not ok:
            failed.append(filename)
        print(f"  [{done}/{total}]")
        time.sleep(2)

    # 小アルカナ
    print("\n--- Minor Arcana (56 cards) ---")
    for filename, name, scene in MINOR_ARCANA:
        ok = generate_card(filename, name, scene, is_major=False)
        done += 1
        if not ok:
            failed.append(filename)
        print(f"  [{done}/{total}]")
        time.sleep(2)

    # サマリー
    print(f"\n=== DONE ===")
    print(f"Success: {total - len(failed)} / {total}")
    if failed:
        print(f"Failed ({len(failed)}):")
        for f in failed:
            print(f"  - {f}")
        print("\nRe-run the script to retry failed cards (existing files are skipped).")


if __name__ == "__main__":
    main()
