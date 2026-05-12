/// Solara Title System data — matches SPEC.md exactly.
/// 144 titles = 12 sun parts × 12 moon parts + 25 classes
library;

// sunParts / moonParts / connectors 削除 (audit dead-symbol cascade, 2026-05-06):
// buildTitle (上で削除) のサポート定数だったが、buildTitle 削除により参照
// ゼロ化。Title 称号システム再開時は git log から復元可能。

// ── 25 Classes (5 axes × 5 court types) ──
class TitleClass {
  final String axis;      // power/mind/spirit/shadow/heart
  final String court;     // page/knight/queen/king/mixed
  final String nameEN;
  final String nameJP;
  final String lightJP;
  final String shadowJP;
  final String lightEN;
  final String shadowEN;

  const TitleClass({
    required this.axis, required this.court,
    required this.nameEN, required this.nameJP,
    required this.lightJP, required this.shadowJP,
    required this.lightEN, required this.shadowEN,
  });
}

const allClasses = <TitleClass>[
  // Power axis
  TitleClass(axis:'power',court:'page',nameEN:'Knight',nameJP:'騎士',
    lightJP:'「守る」と決めたら迷わない',shadowJP:'守りたいものが多すぎて忙しい',
    lightEN:'Never hesitates when someone needs protecting',shadowEN:'Too many people to protect, not enough hours'),
  TitleClass(axis:'power',court:'knight',nameEN:'Dragoon',nameJP:'突撃手',
    lightJP:'とりあえず飛んでから考える',shadowJP:'飛び込みすぎて毎回びっくりされる',
    lightEN:'Leaps first, thinks later',shadowEN:'Keeps surprising everyone by diving in headfirst'),
  TitleClass(axis:'power',court:'queen',nameEN:'Paladin',nameJP:'聖騎士',
    lightJP:'困ってる人を見ると体が動く',shadowJP:'正義感が強すぎて頼られがち',
    lightEN:'Body moves before brain when someone\'s in trouble',shadowEN:'Too reliable — everyone\'s go-to hero'),
  TitleClass(axis:'power',court:'king',nameEN:'Overlord',nameJP:'覇者',
    lightJP:'気づいたら全部仕切っている',shadowJP:'リーダーになりすぎて休めない',
    lightEN:'Somehow ends up running everything',shadowEN:'Can\'t stop leading long enough to rest'),
  TitleClass(axis:'power',court:'mixed',nameEN:'Spellblade',nameJP:'魔剣士',
    lightJP:'なんでもそこそこできてしまう',shadowJP:'器用すぎて自分の専門が決められない',
    lightEN:'Annoyingly good at everything',shadowEN:'Too versatile to pick a specialty'),

  // Mind axis
  TitleClass(axis:'mind',court:'page',nameEN:'Sage',nameJP:'求道者',
    lightJP:'「なぜ？」が止まらない',shadowJP:'知りたいことが多すぎて夜更かしする',
    lightEN:'Can\'t stop asking "but why?"',shadowEN:'Too many rabbit holes, not enough sleep'),
  TitleClass(axis:'mind',court:'knight',nameEN:'Strategist',nameJP:'軍師',
    lightJP:'三手先まで自然と見えている',shadowJP:'先が見えすぎて一人で心配する',
    lightEN:'Sees three moves ahead without trying',shadowEN:'Worries alone because they see too far'),
  TitleClass(axis:'mind',court:'queen',nameEN:'Chancellor',nameJP:'司書',
    lightJP:'誰が何を求めているか分かる',shadowJP:'気配り上手すぎて自分を後回しにする',
    lightEN:'Knows what everyone needs before they ask',shadowEN:'So busy reading the room, forgets to read themselves'),
  TitleClass(axis:'mind',court:'king',nameEN:'Judge',nameJP:'裁定者',
    lightJP:'おかしいことはおかしいと言える',shadowJP:'筋が通らないと気になって眠れない',
    lightEN:'Calls out what\'s wrong without flinching',shadowEN:'Can\'t sleep when something doesn\'t add up'),
  TitleClass(axis:'mind',court:'mixed',nameEN:'Wizard',nameJP:'魔術師',
    lightJP:'好きなことなら永遠にやれる',shadowJP:'没頭すると時間を忘れてご飯を忘れる',
    lightEN:'Could do the thing they love forever',shadowEN:'Gets so absorbed they forget to eat'),

  // Spirit axis
  TitleClass(axis:'spirit',court:'page',nameEN:'Cleric',nameJP:'神官',
    lightJP:'いるだけで周りが安心する',shadowJP:'優しすぎて全員の相談役になる',
    lightEN:'People feel safe just being around them',shadowEN:'Too kind — becomes everyone\'s therapist'),
  TitleClass(axis:'spirit',court:'knight',nameEN:'Astrologer',nameJP:'星読み',
    lightJP:'見えないつながりを見つけるのが得意',shadowJP:'星が気になりすぎて空ばかり見ている',
    lightEN:'Finds invisible connections others miss',shadowEN:'Spends too much time gazing at the sky'),
  TitleClass(axis:'spirit',court:'queen',nameEN:'Oracle',nameJP:'預言者',
    lightJP:'言葉にする前に空気で分かる',shadowJP:'感受性が高すぎて映画で毎回泣く',
    lightEN:'Reads the room before a word is spoken',shadowEN:'Too sensitive — cries at every movie'),
  TitleClass(axis:'spirit',court:'king',nameEN:'Mentor',nameJP:'導師',
    lightJP:'人の才能を見抜いて背中を押せる',shadowJP:'おせっかいが止まらない',
    lightEN:'Sees people\'s gifts and pushes them forward',shadowEN:'Can\'t stop meddling'),
  TitleClass(axis:'spirit',court:'mixed',nameEN:'Druid',nameJP:'祭司',
    lightJP:'自然の中にいると充電できる',shadowJP:'一人の時間が好きすぎて誘いを忘れる',
    lightEN:'Recharges in nature',shadowEN:'Loves alone time so much they forget invitations'),

  // Shadow axis
  TitleClass(axis:'shadow',court:'page',nameEN:'Performer',nameJP:'旅芸人',
    lightJP:'退屈な場の空気を一瞬で変える',shadowJP:'面白いことを思いつくと黙っていられない',
    lightEN:'Changes boring vibes in a heartbeat',shadowEN:'Can\'t keep a good joke to themselves'),
  TitleClass(axis:'shadow',court:'knight',nameEN:'Revolutionary',nameJP:'革命家',
    lightJP:'「おかしい」と思ったら声を上げる',shadowJP:'自由すぎてスケジュールが守れない',
    lightEN:'Speaks up when something feels wrong',shadowEN:'Too free to keep a schedule'),
  TitleClass(axis:'shadow',court:'queen',nameEN:'Ninja',nameJP:'忍者',
    lightJP:'気配を消すのが天才的にうまい',shadowJP:'存在感を消すのが上手すぎて探される',
    lightEN:'Genius at disappearing',shadowEN:'So good at hiding that people come looking'),
  TitleClass(axis:'shadow',court:'king',nameEN:'Rogue',nameJP:'冒険家',
    lightJP:'自分のやり方で結果を出す',shadowJP:'マイペースすぎて周りがハラハラする',
    lightEN:'Gets results their own way',shadowEN:'So independent it makes others nervous'),
  TitleClass(axis:'shadow',court:'mixed',nameEN:'Alchemist',nameJP:'錬金術師',
    lightJP:'関係なさそうなものを組み合わせて化ける',shadowJP:'好奇心が強すぎて余計なものまで作る',
    lightEN:'Combines unrelated things into gold',shadowEN:'Too curious — makes stuff nobody asked for'),

  // Heart axis
  TitleClass(axis:'heart',court:'page',nameEN:'Bard',nameJP:'語り手',
    lightJP:'その場にいる人を全員笑顔にする',shadowJP:'共感力が高すぎてもらい泣きする',
    lightEN:'Makes everyone in the room smile',shadowEN:'So empathic they cry when others cry'),
  TitleClass(axis:'heart',court:'knight',nameEN:'Sorcerer',nameJP:'召喚士',
    lightJP:'感情のエネルギーがそのまま力になる',shadowJP:'感情豊かすぎて表情が忙しい',
    lightEN:'Turns raw emotion into power',shadowEN:'Face is always doing too many things at once'),
  TitleClass(axis:'heart',court:'queen',nameEN:'Enchanter',nameJP:'詩人',
    lightJP:'会った人がなぜか好きになる',shadowJP:'魅力的すぎて誤解される',
    lightEN:'People just... like them',shadowEN:'Too charming — gets misunderstood'),
  TitleClass(axis:'heart',court:'king',nameEN:'Emperor',nameJP:'君主',
    lightJP:'人が自然と集まってくる',shadowJP:'理想が高すぎて妥協できない',
    lightEN:'People naturally gravitate toward them',shadowEN:'Standards too high to compromise'),
  TitleClass(axis:'heart',court:'mixed',nameEN:'Chronomancer',nameJP:'歴史家',
    lightJP:'「あの瞬間」を大事にできる',shadowJP:'思い出を大事にしすぎてアルバムが増え続ける',
    lightEN:'Treasures "that moment"',shadowEN:'Too nostalgic — photo albums keep multiplying'),
];

// axisColors / getClassesForAxis / buildTitle 削除 (audit dead-symbol, 2026-05-06):
// Title 称号システムは未実装フェーズで、現状 UI から呼ばれない。
// 必要になったら git log から復元可能 (project_solara_title_system.md 参照)。

/// Get class by axis + court type
TitleClass? getClassByAxisCourt(String axis, String court) {
  for (final c in allClasses) {
    if (c.axis == axis && c.court == court) return c;
  }
  return null;
}

// ══════════════════════════════════════════════
// HTML sanctuary.html: SUN_ADJ, MOON_NOUN
// ══════════════════════════════════════════════

const sunAdj = <String, Map<String, String>>{
  'aries':       {'jp':'炎を纏う','en':'Blazing'},
  'taurus':      {'jp':'大地に根ざす','en':'Rooted'},
  'gemini':      {'jp':'風を駆ける','en':'Windborne'},
  'cancer':      {'jp':'潮に抱かれし','en':'Tidebound'},
  'leo':         {'jp':'黄金に輝く','en':'Golden'},
  'virgo':       {'jp':'星を数える','en':'Starlit'},
  'libra':       {'jp':'均衡を保つ','en':'Balanced'},
  'scorpio':     {'jp':'深淵を覗く','en':'Abyssal'},
  'sagittarius': {'jp':'地平を射る','en':'Horizonshot'},
  'capricorn':   {'jp':'頂に立つ','en':'Crownward'},
  'aquarius':    {'jp':'天を覆す','en':'Skybreaker'},
  'pisces':      {'jp':'夢に漂う','en':'Dreamdrift'},
};

const moonNoun = <String, Map<String, String>>{
  'aries':       {'jp':'開拓者','en':'Pioneer'},
  'taurus':      {'jp':'守り手','en':'Keeper'},
  'gemini':      {'jp':'語り部','en':'Narrator'},
  'cancer':      {'jp':'揺り籠','en':'Cradle'},
  'leo':         {'jp':'玉座','en':'Throne'},
  'virgo':       {'jp':'灯台','en':'Lighthouse'},
  'libra':       {'jp':'天秤','en':'Scales'},
  'scorpio':     {'jp':'深淵','en':'Abyss'},
  'sagittarius': {'jp':'矢','en':'Arrow'},
  'capricorn':   {'jp':'砦','en':'Citadel'},
  'aquarius':    {'jp':'嵐','en':'Tempest'},
  'pisces':      {'jp':'泉','en':'Spring'},
};

// ══════════════════════════════════════════════
// HTML sanctuary.html: TITLE_144 — 144個の個別Light/Shadowテキスト
// title144[sunSign][moonSign] = {light, shadow}
// ══════════════════════════════════════════════

const title144 = <String, Map<String, Map<String, String>>>{
  'aries': {
    'aries':       {'light':'不屈なる','shadow':'秒で突っ込み秒で凹む','shadowEN':'Charges in fast, regrets faster'},
    'taurus':      {'light':'揺るがぬ','shadow':'暴走するくせに変化が怖い','shadowEN':'Wild engine but scared of change'},
    'gemini':      {'light':'閃光を纏う','shadow':'即行動なのに脳内会議中な','shadowEN':'Acts on impulse, mind in meetings'},
    'cancer':      {'light':'守護に燃ゆる','shadow':'グイグイ来て即引きこもる','shadowEN':'Comes on strong, then ghosts'},
    'leo':         {'light':'誇り高き','shadow':'先頭を走って褒め待ちする','shadowEN':'Runs first, then waits for praise'},
    'virgo':       {'light':'己に克つ','shadow':'勢いで動いて自分を裁く','shadowEN':'Acts on impulse, then trial by self'},
    'libra':       {'light':'義に殉ずる','shadow':'本音ぶちまけて顔色を伺う','shadowEN':'Spills truth, then reads the room'},
    'scorpio':     {'light':'魂を貫く','shadow':'勝つまでやめず傷も忘れない','shadowEN':'Never quits, never forgets a wound'},
    'sagittarius': {'light':'果てを知らぬ','shadow':'ダッシュは速いが秒で飽きる','shadowEN':'Best at the dash, worst at the rest'},
    'capricorn':   {'light':'鉄心の','shadow':'傷だらけで「平気」と突っ込む','shadowEN':'Bleeding, smiling, charging again'},
    'aquarius':    {'light':'孤高にして気高き','shadow':'飛び込むくせに親密で逃げる','shadowEN':'Dives in fast, runs when close'},
    'pisces':      {'light':'慈悲深き','shadow':'即行動して夢に逃げる','shadowEN':'Acts on impulse, escapes to dreams'},
  },
  'taurus': {
    'aries':       {'light':'泰然たる','shadow':'動かないが急に爆発する','shadowEN':'Doesn\'t move, then suddenly explodes'},
    'taurus':      {'light':'不動の','shadow':'いつも通り厳守、変化で滅亡する','shadowEN':'"Same as usual" or the world ends'},
    'gemini':      {'light':'深慮に満ちた','shadow':'のんびり顔で脳内は忙しい','shadowEN':'Chill face, busy brain'},
    'cancer':      {'light':'慈しみの','shadow':'のんびり装い返信は秒で欲しい','shadowEN':'Acts chill but wants reply in seconds'},
    'leo':         {'light':'堂々たる','shadow':'ペースを守り認められず凹む','shadowEN':'Sticks to pace, sulks when ignored'},
    'virgo':       {'light':'実直なる','shadow':'決めても永遠に問い直す','shadowEN':'Decides, then questions forever'},
    'libra':       {'light':'調和を守る','shadow':'合わせすぎてリズムが崩壊する','shadowEN':'Adapts so much, the rhythm breaks'},
    'scorpio':     {'light':'一途なる','shadow':'好きも憎しみも一生引きずる','shadowEN':'Loves and grudges, both forever'},
    'sagittarius': {'light':'豊穣を求める','shadow':'家に居たいのに楽しさに釣られる','shadowEN':'Wants to stay home, lured by fun'},
    'capricorn':   {'light':'信義に厚き','shadow':'信頼は遅く感情は奥にしまう','shadowEN':'Trust comes slow, feelings locked deep'},
    'aquarius':    {'light':'寡黙にして誠実なる','shadow':'好きな事に全力、好きな人に塩対応な','shadowEN':'All-in on things, cold to crushes'},
    'pisces':      {'light':'悠久を抱く','shadow':'どっしり見えて心は別世界みてる','shadowEN':'Looks grounded, mind\'s in another world'},
  },
  'gemini': {
    'aries':       {'light':'雄弁にして烈火の','shadow':'トークも破壊力も天才な','shadowEN':'Genius at talking, genius at wrecking'},
    'taurus':      {'light':'博識なる','shadow':'興味が散って気づけば別人な','shadowEN':'So many interests, suddenly someone else'},
    'gemini':      {'light':'千変万化の','shadow':'何でもこなせて気持ちだけ迷子な','shadowEN':'Aces everything, lost in own feelings'},
    'cancer':      {'light':'聡明にして温かき','shadow':'布団依存な','shadowEN':'Blanket-dependent type'},
    'leo':         {'light':'才気煥発なる','shadow':'退屈は敵、「すごいね」が栄養な','shadowEN':'Boredom is the enemy, praise is fuel'},
    'virgo':       {'light':'明察の','shadow':'上手くこなすのに自分に不合格な','shadowEN':'Pulls it off, still gives self an F'},
    'libra':       {'light':'機知に富む','shadow':'弁が立つのに断れない','shadowEN':'Great speaker, can\'t say no'},
    'scorpio':     {'light':'洞察深き','shadow':'広く浅く、好きな人にだけ底なしな','shadowEN':'Wide and shallow, except for the one'},
    'sagittarius': {'light':'天衣無縫の','shadow':'「最高」と「飽きた」が同日に来る','shadowEN':'"Best ever" and "bored" same day'},
    'capricorn':   {'light':'知勇兼備の','shadow':'普段は軽口、しんどい時は黙る','shadowEN':'Jokes all day, silent when hurt'},
    'aquarius':    {'light':'玲瓏なる','shadow':'皆と盛り上がり誰も入れない','shadowEN':'Hypes everyone, lets no one in'},
    'pisces':      {'light':'万象を映す','shadow':'広く浅く派なのに共感で泣く','shadowEN':'Plays it casual, then cries from empathy'},
  },
  'cancer': {
    'aries':       {'light':'護りの烈火を宿す','shadow':'守りたくてキレすぎて仲間が引く','shadowEN':'Protects so hard, scares the squad'},
    'taurus':      {'light':'慈愛に満ちた','shadow':'大事な人と物がないと窒息する','shadowEN':'Suffocates without their people and stuff'},
    'gemini':      {'light':'心を読み解く','shadow':'嬉しいくせに言葉は冷めてる','shadowEN':'Heart says yes, words say "whatever"'},
    'cancer':      {'light':'無償の愛を注ぐ','shadow':'全員を心配して自分が壊れる','shadowEN':'Worries for all, breaks alone'},
    'leo':         {'light':'気高き守り手たる','shadow':'甘えてるのに絶対認めない','shadowEN':'Clearly dependent, never admits it'},
    'virgo':       {'light':'献身を尽くす','shadow':'心配性が暴走してお母さん的な','shadowEN':'Worry on max, full mom energy'},
    'libra':       {'light':'寛容なる','shadow':'内心は壁、表面はニコニコな','shadowEN':'Wall inside, smile outside'},
    'scorpio':     {'light':'誓約を結ぶ','shadow':'心は固いが開いたら一生ものな','shadowEN':'Hard to open, forever once opened'},
    'sagittarius': {'light':'郷愁を抱きし','shadow':'帰りたいけど遠くも行きたい','shadowEN':'Wants home AND wants away'},
    'capricorn':   {'light':'静謐なる盾の','shadow':'他人を案じて自分が泣きたい','shadowEN':'Comforts others, secretly wants to cry'},
    'aquarius':    {'light':'遥かなる絆の','shadow':'仲間欲しいくせに来たら拒む','shadowEN':'Wants people, pushes them away'},
    'pisces':      {'light':'夢を抱く守護の','shadow':'他人は救うが自分には逃げ腰な','shadowEN':'Saves others, dodges own struggles'},
  },
  'leo': {
    'aries':       {'light':'燦然と輝く','shadow':'華やかなのに沸点低くて後悔する','shadowEN':'Shines bright, snaps quick, regrets later'},
    'taurus':      {'light':'威風堂々たる','shadow':'注目欲しいくせに変化が怖い','shadowEN':'Craves the spotlight, fears the change'},
    'gemini':      {'light':'華麗なる','shadow':'キラキラ演じて自分を見失う','shadowEN':'Plays sparkly, loses self'},
    'cancer':      {'light':'仁愛の炎を灯す','shadow':'派手に表現してから反省会が長い','shadowEN':'Goes big, then long self-roast session'},
    'leo':         {'light':'至高の','shadow':'「すごいね」が燃料な','shadowEN':'"You\'re amazing" is fuel'},
    'virgo':       {'light':'精励なる','shadow':'お祭り人間が自分に全力ダメ出しする','shadowEN':'Party mode max, self-critique max'},
    'libra':       {'light':'高潔なる','shadow':'カリスマぶって夜は反省で眠れない','shadowEN':'Plays charisma, can\'t sleep at night'},
    'scorpio':     {'light':'灼熱の意志を秘めた','shadow':'褒められて主役、無いと脇役な','shadowEN':'Praised = lead, ignored = extra'},
    'sagittarius': {'light':'天空を駆ける','shadow':'祭りに全力、終われば闇が深い','shadowEN':'All-in on the party, deep void after'},
    'capricorn':   {'light':'威厳に満ちた','shadow':'死にそうでも「任せて」が口癖な','shadowEN':'Half-dead, still says "I got this"'},
    'aquarius':    {'light':'凛然たる','shadow':'盛り上げ屋なのに本命に冷たい','shadowEN':'Hypes the crowd, cold to the one'},
    'pisces':      {'light':'天恵の光を放つ','shadow':'突き進んで気付けば逆に走ってる','shadowEN':'Charges ahead, ends up running back'},
  },
  'virgo': {
    'aries':       {'light':'峻烈なる','shadow':'段取りは完璧、怒りはノープランな','shadowEN':'Plans on point, anger has no plan'},
    'taurus':      {'light':'篤実なる','shadow':'几帳面の裏に執着が隠れてる','shadowEN':'Tidy outside, obsession inside'},
    'gemini':      {'light':'慧眼の','shadow':'他人を見抜けて自分の気持ちは謎な','shadowEN':'Reads everyone, clueless about self'},
    'cancer':      {'light':'奉仕の心を持つ','shadow':'黙々と尽くして感謝なしで壊れる','shadowEN':'Quietly serves, breaks without thanks'},
    'leo':         {'light':'至誠の','shadow':'涼しい顔で心は拍手を待ってる','shadowEN':'Cool face, heart waits for applause'},
    'virgo':       {'light':'求道の','shadow':'自分を裁くプロ、許すのが苦手な','shadowEN':'Pro at self-judgment, bad at self-forgiveness'},
    'libra':       {'light':'思慮深き','shadow':'正解見えても嫌われたくなくて黙る','shadowEN':'Sees the truth, stays quiet to be liked'},
    'scorpio':     {'light':'真贋を見極める','shadow':'冷静ぶってるが許せないリスト膨大な','shadowEN':'Acts calm, holds endless grudge list'},
    'sagittarius': {'light':'清廉なる','shadow':'ちゃんと派なのに楽しいで脱線する','shadowEN':'"Be proper" until fun shows up'},
    'capricorn':   {'light':'克己の極みたる','shadow':'自分に休みを許さず限界まで走る','shadowEN':'Never lets self rest, runs till broken'},
    'aquarius':    {'light':'洞察に優れた','shadow':'他人には敏感、自分には鈍感な','shadowEN':'Sharp on others, blind to self'},
    'pisces':      {'light':'仁徳の','shadow':'ちゃんとやりすぎて電池切れで消えてる','shadowEN':'Goes too hard, then vanishes empty'},
  },
  'libra': {
    'aries':       {'light':'正義を秘めた','shadow':'平和主義の裏で世界滅亡を企てる','shadowEN':'Peace lover, secret apocalypse planner'},
    'taurus':      {'light':'雅なる','shadow':'センス抜群、服選びに3日かかる','shadowEN':'Great taste, 3 days to pick an outfit'},
    'gemini':      {'light':'叡智を宿す','shadow':'空気読みの達人、自分は謎だらけな','shadowEN':'Reads every room, can\'t read self'},
    'cancer':      {'light':'博愛の','shadow':'社交はプロ、本命の前で石像な','shadowEN':'Social pro, frozen near the crush'},
    'leo':         {'light':'気品に溢れた','shadow':'「どっちでも」派なのに静かに拗ねる','shadowEN':'Says "either\'s fine," sulks quietly'},
    'virgo':       {'light':'端麗なる','shadow':'完璧美の為に小さな乱れが許せない','shadowEN':'Perfection or one stray thread breaks them'},
    'libra':       {'light':'均衡を司る','shadow':'好かれようとして自分を見失う','shadowEN':'Trying to be liked, lost own self'},
    'scorpio':     {'light':'裁きの天秤を持つ','shadow':'笑顔の裏で怨念リスト永久保存な','shadowEN':'Smiling face, grudge list saved forever'},
    'sagittarius': {'light':'自在なる','shadow':'調整役なのに突然旅に出る','shadowEN':'Group mediator, then suddenly bolts on a trip'},
    'capricorn':   {'light':'献身の','shadow':'自己犠牲で円満、辛さは隠すプロな','shadowEN':'Sacrifices for harmony, pro at hiding pain'},
    'aquarius':    {'light':'美を極めし','shadow':'調和派なのに親密になると壊す','shadowEN':'Wants harmony, breaks it when intimate'},
    'pisces':      {'light':'夢幻の調べを奏でる','shadow':'空気を読んで自分を消し夢に住む','shadowEN':'Reads the room, erases self, lives in dreams'},
  },
  'scorpio': {
    'aries':       {'light':'烈火の意志を持つ','shadow':'普段は無言、爆発で周囲崩壊させる','shadowEN':'Silent usually, nukes everything when blown'},
    'taurus':      {'light':'永劫の','shadow':'沼住人の才能を持つ','shadowEN':'Born to live in the swamp'},
    'gemini':      {'light':'深淵を見通す','shadow':'知らん顔で全員を精密分析中な','shadowEN':'Blank face, profiling everyone'},
    'cancer':      {'light':'慈しみに満ちた','shadow':'身内にだけ見せる顔がびっくり甘い','shadowEN':'Inner circle gets shockingly sweet face'},
    'leo':         {'light':'玉座に座す','shadow':'無関心装って夜中に枕を殴ってる','shadowEN':'Plays "couldn\'t care less," punches pillow at 2am'},
    'virgo':       {'light':'省察に長けた','shadow':'謎キャラぶって脳内ダメ出し中な','shadowEN':'Mystery vibes outside, nitpicks self inside'},
    'libra':       {'light':'静寂の威を放つ','shadow':'沈黙で圧かけ急に愛想笑いする','shadowEN':'Silent pressure, then sudden fake smile'},
    'scorpio':     {'light':'覚悟を決めた','shadow':'ゼロか百か、全部重い','shadowEN':'Zero or hundred, all heavy'},
    'sagittarius': {'light':'誓いと自由を併せ持つ','shadow':'愛も自由も全部欲しい','shadowEN':'Wants all the love AND all the freedom'},
    'capricorn':   {'light':'鋼の秘めたる','shadow':'感情を金庫にしまって鍵を捨てた','shadowEN':'Locked feelings in a vault, threw the key'},
    'aquarius':    {'light':'孤絶にして純粋なる','shadow':'全力で愛したいのに愛されると逃げる','shadowEN':'Wants to love hard, runs when loved hard'},
    'pisces':      {'light':'深海の祈りを捧げる','shadow':'100%愛して100%沈む浮上不能な','shadowEN':'Loves 100%, sinks 100%, no surface key'},
  },
  'sagittarius': {
    'aries':       {'light':'破天荒なる','shadow':'走ってから考える、止まれない','shadowEN':'Runs first, thinks later, can\'t stop'},
    'taurus':      {'light':'大地を踏みしめる','shadow':'楽天家のつもりが枕を濡らす','shadowEN':'Plays optimist, cries into the pillow'},
    'gemini':      {'light':'真実を射る','shadow':'他人に正直、自分には嘘つきな','shadowEN':'Brutally honest with others, lies to self'},
    'cancer':      {'light':'故郷を想う','shadow':'未知を追って帰り道見えずに泣く','shadowEN':'Chases the unknown, cries when lost'},
    'leo':         {'light':'栄光を纏う','shadow':'人生まるごとエンタメショーに乗せたい','shadowEN':'Wants their whole life on a show'},
    'virgo':       {'light':'志を正す','shadow':'計画無視で楽しみ夜中に自分を裁く','shadowEN':'Ditches the plan, judges self at 2am'},
    'libra':       {'light':'風雅なる','shadow':'自由派なのに人目で自分を縛る','shadowEN':'Free spirit, but ties self up for the gaze'},
    'scorpio':     {'light':'運命に身を捧げる','shadow':'束縛で死ぬのに恋すると「縛って」','shadowEN':'Hates being tied down, asks crush to tie them up'},
    'sagittarius': {'light':'天涯を翔ける','shadow':'楽しい重ねすぎて記憶が飛ぶ','shadowEN':'Stacks too much fun, memory wipes out'},
    'capricorn':   {'light':'大志を抱く','shadow':'楽天家の顔、裏は必死な努力家な','shadowEN':'Optimist face, secretly grinding hard'},
    'aquarius':    {'light':'彼方を見据える','shadow':'旅先で皆と仲良し、帰宅後は孤独な','shadowEN':'Best friends on the road, lonely at home'},
    'pisces':      {'light':'星に導かれし','shadow':'走り続けて気付けば夢の中な','shadowEN':'Keeps running, ends up in a dream'},
  },
  'capricorn': {
    'aries':       {'light':'剛毅なる','shadow':'積み上げた努力を1秒で吹き飛ばす','shadowEN':'1 second of rage erases years of work'},
    'taurus':      {'light':'不撓不屈の','shadow':'全てを拾い決して手放さない','shadowEN':'Picks up everything, lets go of nothing'},
    'gemini':      {'light':'深謀遠慮の','shadow':'冷静派なのに脳内議論が終わらない','shadowEN':'Acts cool, brain never stops debating'},
    'cancer':      {'light':'温情の','shadow':'全部一人で背負うが本当は甘えたい','shadowEN':'Carries it alone, secretly wants to lean'},
    'leo':         {'light':'威光を隠す','shadow':'承認欲求を隠しすぎて気付かれない','shadowEN':'Hides the craving so well, no one notices'},
    'virgo':       {'light':'精進を極めた','shadow':'「もっとちゃんと」に永遠に追われる','shadowEN':'"Try harder" chasing them forever'},
    'libra':       {'light':'堅忍の','shadow':'石橋叩く派が頼まれて結局渡る','shadowEN':'Tests the bridge, gets asked, crosses anyway'},
    'scorpio':     {'light':'静謐なる怒りの','shadow':'サボリーに無言の怒りを溜める','shadowEN':'Silent rage builds up at lazy people'},
    'sagittarius': {'light':'求道者たる','shadow':'ストイックだが時々全部投げ出したくなる','shadowEN':'Stoic mode on, sometimes wants to dump it all'},
    'capricorn':   {'light':'峻厳なる','shadow':'自分に厳しすぎて泣き方を忘れる','shadowEN':'So strict with self, forgot how to cry'},
    'aquarius':    {'light':'朴訥にして誠の','shadow':'背中で語るが伝わらない','shadowEN':'Speaks with the back, nothing gets through'},
    'pisces':      {'light':'黎明を待つ','shadow':'走り続けて限界の瞬間ふっと消える','shadowEN':'Runs forever, then poof at the limit'},
  },
  'aquarius': {
    'aries':       {'light':'革新の炎を灯す','shadow':'常識は疑うが自分の衝動だけ信じる','shadowEN':'Doubts norms, trusts own impulses 100%'},
    'taurus':      {'light':'理想を守る','shadow':'革命家なのに自分の生活は変えない','shadowEN':'Wants to change the world, not own routine'},
    'gemini':      {'light':'星霜を超える知の','shadow':'常識を疑い自分の存在まで疑う','shadowEN':'Doubts norms, ends up doubting own existence'},
    'cancer':      {'light':'人を照らす','shadow':'人類は愛せるが本命には不器用な','shadowEN':'Loves humanity, awkward with the actual one'},
    'leo':         {'light':'天命を負う','shadow':'染まらないのに認められたい','shadowEN':'Won\'t conform, wants to be seen'},
    'virgo':       {'light':'先見の明を持つ','shadow':'大きな夢の頭で小さな傷を数える','shadowEN':'Big-dream brain, counts tiny scars'},
    'libra':       {'light':'自由を貫く','shadow':'「俺は俺」なのに既読スルーで動揺する','shadowEN':'"I do me" until they get left on read'},
    'scorpio':     {'light':'深き渇望の','shadow':'執着しない派だが本命SNSは秒で見る','shadowEN':'"No attachments," yet stalks their crush\'s IG'},
    'sagittarius': {'light':'未踏を拓く','shadow':'未来を見すぎて足元は見ない','shadowEN':'Eyes on the future, blind to the floor'},
    'capricorn':   {'light':'信念を曲げぬ','shadow':'世のルールは壊し自分ルールは壊せない','shadowEN':'Breaks society\'s rules, can\'t break own'},
    'aquarius':    {'light':'唯一無二の','shadow':'人と違う道を選び気付けば孤独な','shadowEN':'Picks the road less taken, lonely there'},
    'pisces':      {'light':'衆生を憂う','shadow':'独り好きなのに他人の心配で日が暮れる','shadowEN':'Loves solitude, spends day worrying for others'},
  },
  'pisces': {
    'aries':       {'light':'静寂に秘めた烈火の','shadow':'ふわふわ優しいが地雷で豹変する','shadowEN':'Soft and sweet, until you hit the mine'},
    'taurus':      {'light':'安寧を愛する','shadow':'夢見がちだけど推しにはガチ','shadowEN':'Daydreamer in general, hardcore for the fave'},
    'gemini':      {'light':'万象を感じ取る','shadow':'他人の心は読めて自分の心は迷子な','shadowEN':'Reads everyone\'s heart, can\'t find own'},
    'cancer':      {'light':'無垢なる慈愛の','shadow':'他人の世話して自分の世話できない','shadowEN':'Takes care of all, no clue how to care for self'},
    'leo':         {'light':'天与の才を持つ','shadow':'センス天才、承認ないと一瞬で消える','shadowEN':'Genius taste, vanishes without applause'},
    'virgo':       {'light':'清浄なる','shadow':'昼は楽天家、深夜2時に自分を裁く','shadowEN':'Day mode chill, 2am mode prosecutor'},
    'libra':       {'light':'共感の涙を知る','shadow':'他人の涙は拭うが自分は独りぼっちな','shadowEN':'Wipes others\' tears, cries alone'},
    'scorpio':     {'light':'深淵の愛を宿す','shadow':'ふわふわなのに愛だけナイフな','shadowEN':'Fluffy in everything, love sharp as a knife'},
    'sagittarius': {'light':'運命を信じる','shadow':'毎回本気の「運命の人」が毎回違う','shadowEN':'"The one" every time, different one every time'},
    'capricorn':   {'light':'鋼の夢を見る','shadow':'ふわふわ顔の裏に隠れた鋼をもつ','shadowEN':'Soft face, steel underneath'},
    'aquarius':    {'light':'月光を纏う','shadow':'恋する前は熱、落ちた瞬間に冷静な','shadowEN':'Hot pre-fall, cold the moment they fall'},
    'pisces':      {'light':'透明なる祈りの','shadow':'他人に染まりすぎて自分が消える','shadowEN':'Soaks in others until self disappears'},
  },
};

// titleClasses 削除 (audit dead-symbol, 2026-05-06):
// 上記 axisColors 等と同様、Title 称号システム未実装で参照ゼロ。

// ══════════════════════════════════════════════
// HTML: ZODIAC_DATES + getSunSign + getMoonSign
// ══════════════════════════════════════════════

const _zodiacDates = [
  (sign: 'capricorn',   m: 1,  d: 1),
  (sign: 'aquarius',    m: 1,  d: 20),
  (sign: 'pisces',      m: 2,  d: 19),
  (sign: 'aries',       m: 3,  d: 21),
  (sign: 'taurus',      m: 4,  d: 20),
  (sign: 'gemini',      m: 5,  d: 21),
  (sign: 'cancer',      m: 6,  d: 22),
  (sign: 'leo',         m: 7,  d: 23),
  (sign: 'virgo',       m: 8,  d: 23),
  (sign: 'libra',       m: 9,  d: 23),
  (sign: 'scorpio',     m: 10, d: 23),
  (sign: 'sagittarius', m: 11, d: 22),
  (sign: 'capricorn',   m: 12, d: 22),
];

/// HTML: getSunSign(dateStr) — birthDate → 太陽星座
String getSunSign(String dateStr) {
  if (dateStr.isEmpty) return 'aries';
  final parts = dateStr.split('-');
  if (parts.length < 3) return 'aries';
  final m = int.tryParse(parts[1]) ?? 1;
  final d = int.tryParse(parts[2]) ?? 1;
  final doy = m * 100 + d;
  for (int i = _zodiacDates.length - 1; i >= 0; i--) {
    if (doy >= _zodiacDates[i].m * 100 + _zodiacDates[i].d) return _zodiacDates[i].sign;
  }
  return 'capricorn';
}

/// HTML: getMoonSign(dateStr, timeStr) — birthDate+Time → 月星座（近似計算）
String getMoonSign(String dateStr, String timeStr) {
  if (dateStr.isEmpty) return 'cancer';
  final parts = dateStr.split('-');
  if (parts.length < 3) return 'cancer';
  final ref = DateTime(2000, 1, 1);
  final target = DateTime(
    int.tryParse(parts[0]) ?? 2000,
    int.tryParse(parts[1]) ?? 1,
    int.tryParse(parts[2]) ?? 1,
  );
  double hours = 12;
  if (timeStr.isNotEmpty) {
    final tp = timeStr.split(':');
    hours = (int.tryParse(tp[0]) ?? 12) + (tp.length > 1 ? (int.tryParse(tp[1]) ?? 0) / 60.0 : 0);
  }
  final days = target.difference(ref).inDays + hours / 24;
  double deg = (28 + days * 13.176) % 360;
  if (deg < 0) deg += 360;
  const signs = ['aries','taurus','gemini','cancer','leo','virgo','libra','scorpio','sagittarius','capricorn','aquarius','pisces'];
  return signs[(deg / 30).floor()];
}
