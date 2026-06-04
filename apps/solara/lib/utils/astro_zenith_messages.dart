// 天頂点 (Zenith Point) 解説メッセージ辞書。
// 天頂点 = 各惑星のMCライン上で 緯度=惑星赤緯δ となる唯一の地点。
// 「観測者が立つと惑星が物理的に頭上(高度90°)に来る」場所。
// MCライン全体の中でも特に強い「シャワー直下」「ノズル先端」のスポット。
// Astro*Carto*Graphy モードで天頂点マーカータップ時に表示。
//
// 英語化Phase 2: 日本語マップを正典に、astroZenithMessagesEN/astroNadirMessagesEN を
// STYLE_VOICE_EN で併設 (ファイル末尾)。zenithMessageFor() が isEnLocale() で選択。
// Hard エネルギー (土星/冥王星等) は吉凶でなく「質の違い」として中立に再表現。

import 'solara_i18n.dart' show isEnLocale;

class ZenithMessage {
  final String title;     // 「太陽天頂点」等
  final String summary;   // 1行サマリ (~30字)
  final String detail;    // 詳述 (~100字、特徴と注意点)
  final List<String> tags; // タグ ['存在感', '創造', 'リーダー']
  const ZenithMessage({
    required this.title,
    required this.summary,
    required this.detail,
    required this.tags,
  });
}

const Map<String, ZenithMessage> astroZenithMessages = {
  'sun': ZenithMessage(
    title: '太陽天頂点',
    summary: '本質と存在感が物理的に強化される',
    detail: '自己表現のエネルギーが天頂から直降する地点。オーラが拡大し、自分軸が研ぎ澄まされる。'
        'リーダーシップ・名声・創造性が表れやすい土地です。',
    tags: ['存在感', '創造', 'リーダー'],
  ),
  'moon': ZenithMessage(
    title: '月天頂点',
    summary: '感情と無意識が大地と共鳴する',
    detail: '心の深層が天頂と繋がる地点。直感・感受性・母性的な保護が増幅される。'
        '家族との繋がり、内面の癒し、過去との和解に深い影響を与える土地です。',
    tags: ['感情', '直感', '癒し'],
  ),
  'mercury': ZenithMessage(
    title: '水星天頂点',
    summary: '言葉と思考が天から降る',
    detail: '情報伝達と知性のエネルギーが直降する地点。学習・執筆・交渉・スピーチで本領発揮。'
        '閃きと言語化能力が研ぎ澄まされます。',
    tags: ['学び', '伝達', '知性'],
  ),
  'venus': ZenithMessage(
    title: '金星天頂点',
    summary: '美と愛のエネルギーが頭上から降る',
    detail: '引き寄せ力と関係性のエネルギーが天頂から直降する地点。出会い・芸術・調和・豊かさが花開く。'
        '美的感覚と魅力が引き出されやすい土地です。',
    tags: ['愛', '美', '魅力'],
  ),
  'mars': ZenithMessage(
    title: '火星天頂点',
    summary: '情熱と行動力が直降する',
    detail: '突破力・闘志・身体エネルギーが天頂から降る地点。スポーツ・起業・武術・競争で行動力や闘志が高まりやすい。'
        'ただし衝突や勢い余りも起きやすい土地です。',
    tags: ['行動', '情熱', '突破'],
  ),
  'jupiter': ZenithMessage(
    title: '木星天頂点',
    summary: '拡大と恵みが頭上から降る',
    detail: '豊かさと成長機会の象徴。視野が広がり、寛大さ・楽観性・哲学的洞察が深まる地点。'
        '海外・教育・出版・宗教との縁が生まれやすい土地です。',
    tags: ['恩恵', '拡大', '学び'],
  ),
  'saturn': ZenithMessage(
    title: '土星天頂点',
    summary: '結晶化と達成のエネルギー',
    detail: '覚悟と責任が試され、磨かれる地点。試練を通じて本物の力と地位を築ける土地。'
        '短期的には重圧、長期的には不動の達成をもたらす磁場です。',
    tags: ['達成', '責任', '構築'],
  ),
  'uranus': ZenithMessage(
    title: '天王星天頂点',
    summary: '突然の覚醒と自由化',
    detail: '革新と独立のエネルギーが直降する地点。突如の閃き・既存からの解放・既成概念の破壊が起きやすい土地。'
        'テクノロジー・先端分野で道が開けます。',
    tags: ['革新', '自由', '覚醒'],
  ),
  'neptune': ZenithMessage(
    title: '海王星天頂点',
    summary: '夢と霊性が大地に滲む',
    detail: '境界が溶け、無形のエネルギーと繋がる地点。芸術・霊性・癒し・深い慈愛が花開く土地。'
        '一方で混乱・依存・現実逃避も起きやすい面があります。',
    tags: ['霊性', '夢', '芸術'],
  ),
  'pluto': ZenithMessage(
    title: '冥王星天頂点',
    summary: '変容と再生の根源と直結',
    detail: '深層意識・タブー・力の問題が表面化する地点。人生を根本から作り変える試練と、その先の不可逆の再生。'
        '覚悟がある者にだけ訪れる土地です。',
    tags: ['変容', '再生', '深層'],
  ),
};

// 天底点 (Nadir Point) 解説メッセージ辞書。
// 天底点 = 各惑星の IC ライン上で 緯度=-δ となる地点。
// 「観測者が立つと惑星が真下(地球の裏側、高度-90°)にある」場所。
// 天頂点と地球中心を挟んで対称、Lewis 理論では「裏側に在る天体」として
// 内面・ルーツ・無意識・家庭の基盤に深く効くとされる。
// 同じ緯度の都市は経度を問わず影響を受ける、というのが Lewis の見立て。
const Map<String, ZenithMessage> astroNadirMessages = {
  'sun': ZenithMessage(
    title: '太陽天底点',
    summary: '自我の核と家系の根が共鳴する',
    detail: 'アイデンティティが内面深くから組み直される地点。私的な領域・家庭・先祖と'
        'のつながりが活性化し、表向きの自分よりも本来の核と向き合う磁場が立つ。',
    tags: ['ルーツ', '内核', '基盤'],
  ),
  'moon': ZenithMessage(
    title: '月天底点',
    summary: '無意識の海が大地と接続する',
    detail: '記憶・母性・情緒の根が深く揺れる地点。安らぎと懐かしさ、あるいは古い感情の'
        '再浮上が訪れる。心のホームを問い直す土地。',
    tags: ['無意識', '母性', '安住'],
  ),
  'mercury': ZenithMessage(
    title: '水星天底点',
    summary: '内なる対話と思考の地下水脈',
    detail: '声に出さない思考、内省、母語の根に響く地点。執筆・研究・系譜の整理に静かに'
        '深く向き合える磁場が立つ。',
    tags: ['内省', '記述', '系譜'],
  ),
  'venus': ZenithMessage(
    title: '金星天底点',
    summary: '内なる美と愛着の土壌',
    detail: '愛し方の根・心地よさの基準が問い直される地点。家庭の美意識、自分が大切に'
        'したいものの輪郭が静かに浮かび上がる。',
    tags: ['愛着', '土壌', '内面の美'],
  ),
  'mars': ZenithMessage(
    title: '火星天底点',
    summary: '内なる衝動と意志の地下層',
    detail: '怒り・闘志・原始的エネルギーの根が動く地点。表に出ない衝動と向き合い、'
        '私的な領域から行動の燃料を組み直す磁場が立つ。',
    tags: ['衝動', '意志', '燃料'],
  ),
  'jupiter': ZenithMessage(
    title: '木星天底点',
    summary: '信仰と豊かさの根が拡がる',
    detail: '信じているもの・価値観の根が広がる地点。家庭の哲学、内面の豊かさ、見えない'
        '恵みの脈が活性化される土地。',
    tags: ['信仰', '内的豊かさ', '哲学の根'],
  ),
  'saturn': ZenithMessage(
    title: '土星天底点',
    summary: '構造の根と家系の責任',
    detail: '家系から受け継いだ責任・構造・限界が露わになる地点。私的領域での覚悟と、'
        '根本的な作り直しを促す磁場が立つ。',
    tags: ['基盤', '責任', '家系'],
  ),
  'uranus': ZenithMessage(
    title: '天王星天底点',
    summary: '根本からの離脱と再起動',
    detail: '家系・既存の枠組みから内面を切り離し、原型を再起動する地点。私的領域での'
        '突発的変化、独立的な再構築が起こりやすい。',
    tags: ['離脱', '独立', '再起動'],
  ),
  'neptune': ZenithMessage(
    title: '海王星天底点',
    summary: '無意識と霊的記憶の海',
    detail: '個と家系の境界が溶け、より大きな流れに接続する地点。霊的なルーツ・夢・'
        '過去世感覚が浮かび上がる土地。',
    tags: ['霊性', '溶解', '記憶'],
  ),
  'pluto': ZenithMessage(
    title: '冥王星天底点',
    summary: '深層の根源と変容の核',
    detail: '家系のタブー・抑圧・力の問題が深層から動く地点。内側の根本を問い直す'
        '不可逆の変容、その先の純化が訪れる磁場。',
    tags: ['根源', '深層変容', 'タブー'],
  ),
};

// ── 英語版 (英語化Phase 2) ──

const Map<String, ZenithMessage> astroZenithMessagesEN = {
  'sun': ZenithMessage(
    title: 'Sun Zenith Point',
    summary: 'Essence and presence are physically amplified',
    detail: 'A place where the energy of self-expression descends straight from the zenith. '
        'Your aura widens and your sense of self sharpens. A land where leadership, '
        'recognition, and creativity surface readily.',
    tags: ['Presence', 'Creativity', 'Leadership'],
  ),
  'moon': ZenithMessage(
    title: 'Moon Zenith Point',
    summary: 'Emotion and the unconscious resonate with the land',
    detail: 'A place where the depths of the heart connect with the zenith. Intuition, '
        'sensitivity, and a nurturing, protective quality are amplified. A land that touches '
        'family bonds, inner healing, and reconciliation with the past.',
    tags: ['Emotion', 'Intuition', 'Healing'],
  ),
  'mercury': ZenithMessage(
    title: 'Mercury Zenith Point',
    summary: 'Words and thought descend from above',
    detail: 'A place where the energy of communication and intellect comes straight down. '
        'You find your stride in learning, writing, negotiation, and speech. Insight and the '
        'gift for putting things into words grow keen.',
    tags: ['Learning', 'Communication', 'Intellect'],
  ),
  'venus': ZenithMessage(
    title: 'Venus Zenith Point',
    summary: 'The energy of beauty and love descends overhead',
    detail: 'A place where the power of attraction and connection descends straight from the '
        'zenith. Encounters, art, harmony, and abundance come into bloom. A land that draws '
        'out aesthetic sense and charm.',
    tags: ['Love', 'Beauty', 'Charm'],
  ),
  'mars': ZenithMessage(
    title: 'Mars Zenith Point',
    summary: 'Passion and drive descend directly',
    detail: 'A place where breakthrough power, fighting spirit, and physical energy pour down '
        'from the zenith. Drive and resolve rise in sport, enterprise, martial arts, and '
        'competition. Collisions and overreach can come easily here too.',
    tags: ['Action', 'Passion', 'Breakthrough'],
  ),
  'jupiter': ZenithMessage(
    title: 'Jupiter Zenith Point',
    summary: 'Expansion and grace descend overhead',
    detail: 'A symbol of abundance and room to grow. A place where your horizons widen and '
        'generosity, optimism, and philosophical insight deepen. A land where ties to travel '
        'abroad, education, publishing, and faith tend to form.',
    tags: ['Grace', 'Expansion', 'Learning'],
  ),
  'saturn': ZenithMessage(
    title: 'Saturn Zenith Point',
    summary: 'The energy of crystallization and achievement',
    detail: 'A place where resolve and responsibility are tested and refined. Through trial, '
        'you can build genuine strength and standing here. A field that brings pressure in the '
        'short term and an unshakable sense of achievement over the long run.',
    tags: ['Achievement', 'Responsibility', 'Building'],
  ),
  'uranus': ZenithMessage(
    title: 'Uranus Zenith Point',
    summary: 'Sudden awakening and liberation',
    detail: 'A place where the energy of innovation and independence descends directly. Sudden '
        'insight, release from the established, and the breaking of old assumptions come '
        'easily. A land where paths open in technology and frontier fields.',
    tags: ['Innovation', 'Freedom', 'Awakening'],
  ),
  'neptune': ZenithMessage(
    title: 'Neptune Zenith Point',
    summary: 'Dreams and spirit seep into the land',
    detail: 'A place where boundaries dissolve and you connect with formless energy. A land '
        'where art, spirituality, healing, and deep compassion come into bloom. At the same '
        'time, confusion, dependence, and escapism can arise more easily.',
    tags: ['Spirit', 'Dreams', 'Art'],
  ),
  'pluto': ZenithMessage(
    title: 'Pluto Zenith Point',
    summary: 'A direct line to the source of transformation and rebirth',
    detail: 'A place where the depths of the psyche, taboo, and questions of power rise to the '
        'surface. A trial that remakes life from its foundations, and the irreversible rebirth '
        'beyond it. A land that opens to those who are ready for it.',
    tags: ['Transformation', 'Rebirth', 'Depths'],
  ),
};

const Map<String, ZenithMessage> astroNadirMessagesEN = {
  'sun': ZenithMessage(
    title: 'Sun Nadir Point',
    summary: 'The core of self resonates with ancestral roots',
    detail: 'A place where identity is rebuilt from deep within. Ties to the private sphere, '
        'home, and ancestry come alive, and a field arises for meeting your true core rather '
        'than your outward self.',
    tags: ['Roots', 'Inner core', 'Foundation'],
  ),
  'moon': ZenithMessage(
    title: 'Moon Nadir Point',
    summary: 'The sea of the unconscious meets the land',
    detail: 'A place where the roots of memory, the maternal, and emotion stir deeply. Comfort '
        'and nostalgia arrive — or old feelings resurface. A land that asks you to reconsider '
        'where your heart calls home.',
    tags: ['Unconscious', 'Maternal', 'Belonging'],
  ),
  'mercury': ZenithMessage(
    title: 'Mercury Nadir Point',
    summary: 'Inner dialogue and the underground stream of thought',
    detail: 'A place that resonates with unspoken thought, introspection, and the roots of '
        'your mother tongue. A field where you can quietly and deeply attend to writing, '
        'research, and the sorting of lineage.',
    tags: ['Introspection', 'Writing', 'Lineage'],
  ),
  'venus': ZenithMessage(
    title: 'Venus Nadir Point',
    summary: 'The soil of inner beauty and attachment',
    detail: 'A place where the roots of how you love, and your sense of comfort, come into '
        'question. The aesthetics of home and the outline of what you most want to cherish '
        'rise quietly into view.',
    tags: ['Attachment', 'Soil', 'Inner beauty'],
  ),
  'mars': ZenithMessage(
    title: 'Mars Nadir Point',
    summary: 'The underground layer of inner drive and will',
    detail: 'A place where the roots of anger, fighting spirit, and primal energy move. A '
        'field for meeting the impulses you keep hidden, and rebuilding the fuel for action '
        'from within the private sphere.',
    tags: ['Impulse', 'Will', 'Fuel'],
  ),
  'jupiter': ZenithMessage(
    title: 'Jupiter Nadir Point',
    summary: 'The roots of faith and abundance spread wide',
    detail: 'A place where the roots of what you believe and value spread out. A land where a '
        'home\'s philosophy, inner abundance, and unseen veins of grace are activated.',
    tags: ['Faith', 'Inner abundance', 'Roots of belief'],
  ),
  'saturn': ZenithMessage(
    title: 'Saturn Nadir Point',
    summary: 'The root of structure and ancestral responsibility',
    detail: 'A place where responsibility, structure, and limits inherited from your lineage '
        'come into the open. A field that calls for resolve in the private sphere and a '
        'fundamental rebuilding.',
    tags: ['Foundation', 'Responsibility', 'Lineage'],
  ),
  'uranus': ZenithMessage(
    title: 'Uranus Nadir Point',
    summary: 'Departure and reboot from the foundations',
    detail: 'A place to separate your inner life from lineage and existing frameworks, and '
        'reboot the original pattern. Sudden change and independent rebuilding in the private '
        'sphere come easily.',
    tags: ['Departure', 'Independence', 'Reboot'],
  ),
  'neptune': ZenithMessage(
    title: 'Neptune Nadir Point',
    summary: 'The sea of the unconscious and spiritual memory',
    detail: 'A place where the boundary between self and lineage dissolves and connects to a '
        'larger current. A land where spiritual roots, dreams, and a sense of past lives rise '
        'to the surface.',
    tags: ['Spirit', 'Dissolving', 'Memory'],
  ),
  'pluto': ZenithMessage(
    title: 'Pluto Nadir Point',
    summary: 'The deep source and the core of transformation',
    detail: 'A place where a lineage\'s taboos, repression, and questions of power move from '
        'the depths. A field of irreversible transformation that asks you to reexamine your '
        'innermost foundation, and the purification beyond it.',
    tags: ['Source', 'Deep transformation', 'Taboo'],
  ),
};

/// ロケール連動アクセサ。en では英語マップ、それ以外は日本語マップを引く。
/// isNadir=true で天底点、false で天頂点。
ZenithMessage? zenithMessageFor(String planetKey, {required bool isNadir}) {
  if (isEnLocale()) {
    return (isNadir ? astroNadirMessagesEN : astroZenithMessagesEN)[planetKey];
  }
  return (isNadir ? astroNadirMessages : astroZenithMessages)[planetKey];
}
