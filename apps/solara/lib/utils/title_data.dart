/// Solara Title System data — matches SPEC.md exactly.
/// 144 titles = 12 sun parts × 12 moon parts + 25 classes

// ── Sun Sign → External Pattern (太陽星座 → 外面パーツ) ──
const sunParts = <String, String>{
  'aries':       '思い立ったら即行動する猪突猛進型',
  'taurus':      '一度決めたらテコでも動かないマイペース',
  'gemini':      '話題が3秒で変わるおしゃべり好き',
  'cancer':      '身内には甘いけど外には壁を作りがち',
  'leo':         '調子に乗って自由に表現しちゃう',
  'virgo':       '細かいところが気になって仕方ない完璧主義',
  'libra':       'みんなに良い顔しすぎて疲れる八方美人',
  'scorpio':     '好きなものへの執着がすごい一途タイプ',
  'sagittarius': '楽しそうなことに飛びつく自由人',
  'capricorn':   'コツコツ積み上げないと気が済まない努力家',
  'aquarius':    '人と同じが嫌で逆張りしがち',
  'pisces':      '妄想が止まらないロマンチスト',
};

// ── Moon Sign → Internal Pattern (月星座 → 内面パーツ) ──
const moonParts = <String, String>{
  'aries':       '実はすぐカッとなって後悔する',
  'taurus':      '実は変化が怖くてしがみつく',
  'gemini':      '実は考えすぎて頭の中が忙しい',
  'cancer':      '実はナイーブで反省会が欠かせない',
  'leo':         '実は褒められないと不安になる',
  'virgo':       '実は自分にダメ出しが止まらない',
  'libra':       '実は本音を隠すのが上手すぎる',
  'scorpio':     '実は傷つきやすくて根に持つ',
  'sagittarius': '実は飽きっぽくて続かない',
  'capricorn':   '実は弱みを見せるのが怖い',
  'aquarius':    '実は寂しがり屋なのに素直になれない',
  'pisces':      '実は現実逃避が得意すぎる',
};

// ── Connectors (接続詞) ──
const connectors = ['けど', 'のに', 'したあとに', 'だし'];

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
  TitleClass(axis:'mind',court:'queen',nameEN:'Chancellor',nameJP:'知恵者',
    lightJP:'誰が何を求めているか分かる',shadowJP:'気配り上手すぎて自分を後回しにする',
    lightEN:'Knows what everyone needs before they ask',shadowEN:'So busy reading the room, forgets to read themselves'),
  TitleClass(axis:'mind',court:'king',nameEN:'Judge',nameJP:'裁定者',
    lightJP:'おかしいことはおかしいと言える',shadowJP:'筋が通らないと気になって眠れない',
    lightEN:'Calls out what\'s wrong without flinching',shadowEN:'Can\'t sleep when something doesn\'t add up'),
  TitleClass(axis:'mind',court:'mixed',nameEN:'Wizard',nameJP:'魔術師',
    lightJP:'好きなことなら永遠にやれる',shadowJP:'没頭すると時間を忘れてご飯を忘れる',
    lightEN:'Could do the thing they love forever',shadowEN:'Gets so absorbed they forget to eat'),

  // Spirit axis
  TitleClass(axis:'spirit',court:'page',nameEN:'Cleric',nameJP:'祈り手',
    lightJP:'いるだけで周りが安心する',shadowJP:'優しすぎて全員の相談役になる',
    lightEN:'People feel safe just being around them',shadowEN:'Too kind — becomes everyone\'s therapist'),
  TitleClass(axis:'spirit',court:'knight',nameEN:'Astrologer',nameJP:'星読み',
    lightJP:'見えないつながりを見つけるのが得意',shadowJP:'星が気になりすぎて空ばかり見ている',
    lightEN:'Finds invisible connections others miss',shadowEN:'Spends too much time gazing at the sky'),
  TitleClass(axis:'spirit',court:'queen',nameEN:'Oracle',nameJP:'預言者',
    lightJP:'言葉にする前に空気で分かる',shadowJP:'感受性が高すぎて映画で毎回泣く',
    lightEN:'Reads the room before a word is spoken',shadowEN:'Too sensitive — cries at every movie'),
  TitleClass(axis:'spirit',court:'king',nameEN:'Fate Weaver',nameJP:'運命紡ぎ',
    lightJP:'人の才能を見抜いて背中を押せる',shadowJP:'おせっかいが止まらない',
    lightEN:'Sees people\'s gifts and pushes them forward',shadowEN:'Can\'t stop meddling'),
  TitleClass(axis:'spirit',court:'mixed',nameEN:'Druid',nameJP:'調和の番人',
    lightJP:'自然の中にいると充電できる',shadowJP:'一人の時間が好きすぎて誘いを忘れる',
    lightEN:'Recharges in nature',shadowEN:'Loves alone time so much they forget invitations'),

  // Shadow axis
  TitleClass(axis:'shadow',court:'page',nameEN:'Trickster',nameJP:'いたずら者',
    lightJP:'退屈な場の空気を一瞬で変える',shadowJP:'面白いことを思いつくと黙っていられない',
    lightEN:'Changes boring vibes in a heartbeat',shadowEN:'Can\'t keep a good joke to themselves'),
  TitleClass(axis:'shadow',court:'knight',nameEN:'Liberator',nameJP:'解放者',
    lightJP:'「おかしい」と思ったら声を上げる',shadowJP:'自由すぎてスケジュールが守れない',
    lightEN:'Speaks up when something feels wrong',shadowEN:'Too free to keep a schedule'),
  TitleClass(axis:'shadow',court:'queen',nameEN:'Phantom',nameJP:'影の者',
    lightJP:'気配を消すのが天才的にうまい',shadowJP:'存在感を消すのが上手すぎて探される',
    lightEN:'Genius at disappearing',shadowEN:'So good at hiding that people come looking'),
  TitleClass(axis:'shadow',court:'king',nameEN:'Rogue',nameJP:'我が道の者',
    lightJP:'自分のやり方で結果を出す',shadowJP:'マイペースすぎて周りがハラハラする',
    lightEN:'Gets results their own way',shadowEN:'So independent it makes others nervous'),
  TitleClass(axis:'shadow',court:'mixed',nameEN:'Alchemist',nameJP:'錬金術師',
    lightJP:'関係なさそうなものを組み合わせて化ける',shadowJP:'好奇心が強すぎて余計なものまで作る',
    lightEN:'Combines unrelated things into gold',shadowEN:'Too curious — makes stuff nobody asked for'),

  // Heart axis
  TitleClass(axis:'heart',court:'page',nameEN:'Bard',nameJP:'語り手',
    lightJP:'その場にいる人を全員笑顔にする',shadowJP:'共感力が高すぎてもらい泣きする',
    lightEN:'Makes everyone in the room smile',shadowEN:'So empathic they cry when others cry'),
  TitleClass(axis:'heart',court:'knight',nameEN:'Sorcerer',nameJP:'魔力の者',
    lightJP:'感情のエネルギーがそのまま力になる',shadowJP:'感情豊かすぎて表情が忙しい',
    lightEN:'Turns raw emotion into power',shadowEN:'Face is always doing too many things at once'),
  TitleClass(axis:'heart',court:'queen',nameEN:'Enchanter',nameJP:'魅了の者',
    lightJP:'会った人がなぜか好きになる',shadowJP:'魅力的すぎて誤解される',
    lightEN:'People just... like them',shadowEN:'Too charming — gets misunderstood'),
  TitleClass(axis:'heart',court:'king',nameEN:'Emperor',nameJP:'王',
    lightJP:'人が自然と集まってくる',shadowJP:'理想が高すぎて妥協できない',
    lightEN:'People naturally gravitate toward them',shadowEN:'Standards too high to compromise'),
  TitleClass(axis:'heart',court:'mixed',nameEN:'Chronomancer',nameJP:'時を操る者',
    lightJP:'「あの瞬間」を大事にできる',shadowJP:'思い出を大事にしすぎてアルバムが増え続ける',
    lightEN:'Treasures "that moment"',shadowEN:'Too nostalgic — photo albums keep multiplying'),
];

// ── Axis Colors (SPEC.md exact) ──
const axisColors = <String, int>{
  'power': 0xFFFF4444,
  'mind': 0xFF6BB5FF,
  'spirit': 0xFF9B6BFF,
  'shadow': 0xFFC06BFF,
  'heart': 0xFFF9D976,
};

/// Get class by axis + court type
TitleClass? getClassByAxisCourt(String axis, String court) {
  for (final c in allClasses) {
    if (c.axis == axis && c.court == court) return c;
  }
  return null;
}

/// Get all classes for an axis (5 classes)
List<TitleClass> getClassesForAxis(String axis) {
  return allClasses.where((c) => c.axis == axis).toList();
}

/// Build full title text: [sun part] + [connector] + [moon part]
String buildTitle(String sunSign, String moonSign, {int? connectorIndex}) {
  final sun = sunParts[sunSign] ?? sunParts['aries']!;
  final moon = moonParts[moonSign] ?? moonParts['aries']!;
  final idx = connectorIndex ?? (sunSign.hashCode + moonSign.hashCode).abs() % connectors.length;
  return '$sun${connectors[idx]}$moon';
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
    'aries':       {'light':'不屈なる','shadow':'誰より先に飛び出して、誰より先に後悔する'},
    'taurus':      {'light':'揺るがぬ','shadow':'待てないし止まらない暴走機関車なのに、いざの変化が怖くてしがみつく'},
    'gemini':      {'light':'閃光を纏う','shadow':'思い立ったら即行動するけど、頭の中はいつも脳内会議中な'},
    'cancer':      {'light':'守護に燃ゆる','shadow':'グイグイ来るくせに、ちょっと冷たくされると一人閉じこもって出てこない'},
    'leo':         {'light':'誇り高き','shadow':'先頭を走ってないと落ち着かないけど、それを褒められないと不安になる'},
    'virgo':       {'light':'己に克つ','shadow':'勢いだけでやってしまったあとで、自分にダメ出しが止まらない'},
    'libra':       {'light':'義に殉ずる','shadow':'勢いで本音をぶちまけたあと、全員の顔色をしっかり確認する'},
    'scorpio':     {'light':'魂を貫く','shadow':'勝つまでやめないヒーロー気質なのに、心の傷はこっそり数えて忘れない'},
    'sagittarius': {'light':'果てを知らぬ','shadow':'スタートダッシュだけは誰にも負けないけど、だいたい飽きて続かない'},
    'capricorn':   {'light':'鉄心の','shadow':'猪突猛進で傷だらけなのに、"全然平気"って笑いながらまた突っ込み死にかける'},
    'aquarius':    {'light':'孤高にして気高き','shadow':'勢いで人の懐に飛び込むくせに、親しくなりすぎると逃げたくなる'},
    'pisces':      {'light':'慈悲深き','shadow':'思い立ったら即行動するけど、気づいたら夢の中に逃げ込んでる'},
  },
  'taurus': {
    'aries':       {'light':'泰然たる','shadow':'一度決めたらテコでも動かないが、急に爆発して別の星に着地する'},
    'taurus':      {'light':'不動の','shadow':'マイペースを貫く頑固さで、"いつも通り"じゃないと世界が終わると信じる'},
    'gemini':      {'light':'深慮に満ちた','shadow':'のんびりしてるようで実は計算してる、頭の中はいつも忙しい'},
    'cancer':      {'light':'慈しみの','shadow':'ゆっくりでいいよ、大丈夫って言いながら、好きな人の返信だけは秒で欲しがる'},
    'leo':         {'light':'堂々たる','shadow':'自分のペースは絶対に守って、認めてもらえないとこっそり凹む'},
    'virgo':       {'light':'実直なる','shadow':'"これでいい"と決めたのに、"本当にこれでよかったのか"が止まらない'},
    'libra':       {'light':'調和を守る','shadow':'ルーティンが崩れると自分が崩壊するのに、嫌われるのが怖くて合わせて結局崩壊する'},
    'scorpio':     {'light':'一途なる','shadow':'"これが好き"への執着がすごいし、"あれが許せない"への執念もすごい'},
    'sagittarius': {'light':'豊穣を求める','shadow':'安心の巣から出たくないくせに、楽しそうなことを見つけるとついつい出て行ってしまう'},
    'capricorn':   {'light':'信義に厚き','shadow':'信頼を積み上げるのに時間がかかる職人気質で、感情を出すのが恥ずかしい'},
    'aquarius':    {'light':'寡黙にして誠実なる','shadow':'好きな事には全力でしがみつくくせに、好きな人には全力でそっけない'},
    'pisces':      {'light':'悠久を抱く','shadow':'どっしり構えてるように見えて、心の中はいつもどこか別の世界にいる'},
  },
  'gemini': {
    'aries':       {'light':'雄弁にして烈火の','shadow':'軽快なトークで場を作る天才だが、キレると世界まで壊す天才でもある'},
    'taurus':      {'light':'博識なる','shadow':'興味の対象が多すぎて、いつのまにか変わってしまった自分に気が付き泣きたくなる'},
    'gemini':      {'light':'千変万化の','shadow':'器用に何でもこなすのに、自分の気持ちだけはいつも迷子な'},
    'cancer':      {'light':'聡明にして温かき','shadow':'誰とでも話せるコミュ力おばけなのに、家に帰ると一人で布団にくるまる'},
    'leo':         {'light':'才気煥発なる','shadow':'退屈が一番の敵で、「すごいね」が一番の栄養になる'},
    'virgo':       {'light':'明察の','shadow':'要領よく何でもできてるのに、自分にだけは永遠に合格を出さない'},
    'libra':       {'light':'機知に富む','shadow':'言葉の引き出しは無限のはずが、断る言葉は何故かもっていない'},
    'scorpio':     {'light':'洞察深き','shadow':'広く浅くがモットーなのに、好きな人にだけ底なしに深くなる'},
    'sagittarius': {'light':'天衣無縫の','shadow':'"これ最高！"と"もう飽きた！"が同じ日に来る'},
    'capricorn':   {'light':'知勇兼備の','shadow':'誰とでも軽く話せるくせに、しんどいときほど一人で黙る'},
    'aquarius':    {'light':'玲瓏なる','shadow':'誰とでも盛り上がるけど、全員と薄いガラス一枚隔ててる'},
    'pisces':      {'light':'万象を映す','shadow':'広く浅く付き合う派なのに、なぜか共感しすぎて泣いてる'},
  },
  'cancer': {
    'aries':       {'light':'護りの烈火を宿す','shadow':'仲間を守る気持ちが強すぎて、キレ方が本気すぎて仲間がドン引きする'},
    'taurus':      {'light':'慈愛に満ちた','shadow':'大事な人と大事なものに囲まれてないと、呼吸の仕方を忘れる'},
    'gemini':      {'light':'心を読み解く','shadow':'顔が全部しゃべっちゃってるのに、口からは"別に"しか出ない'},
    'cancer':      {'light':'無償の愛を注ぐ','shadow':'みんなを心配し大丈夫？と聞いている時の本人が全然大丈夫じゃない'},
    'leo':         {'light':'気高き守り手たる','shadow':'誰から見ても甘えているのに、絶対に"甘えてない"って言い張る'},
    'virgo':       {'light':'献身を尽くす','shadow':'心配性が行きすぎてお母さん化、ここまでやる？が止まらない'},
    'libra':       {'light':'寛容なる','shadow':'心の中では壁を作ってるのに、表面上はニコニコしている'},
    'scorpio':     {'light':'誓約を結ぶ','shadow':'他人になかなか心を開かない、開いた瞬間"この人だけは絶対"になる'},
    'sagittarius': {'light':'郷愁を抱きし','shadow':'家に帰りたい気持ちと、どこか遠くに行きたい気持ちが常に戦ってる'},
    'capricorn':   {'light':'静謐なる盾の','shadow':'"みんな大丈夫？"って聞くくせに、本当は自分が泣きたい'},
    'aquarius':    {'light':'遥かなる絆の','shadow':'仲間がいないとダメなくせに、仲間が来ると急にシャッター下ろす'},
    'pisces':      {'light':'夢を抱く守護の','shadow':'他人を守る手段は完璧なのに、自分を守る手段が現実逃避な'},
  },
  'leo': {
    'aries':       {'light':'燦然と輝く','shadow':'華やかに振る舞う自信家なのに、沸点が低すぎて後悔する'},
    'taurus':      {'light':'威風堂々たる','shadow':'注目されてナンボの表現者なのに、注目されすぎた変化が怖くてしがみつく'},
    'gemini':      {'light':'華麗なる','shadow':'キラキラした自分で場を回すのに、ふとした瞬間"これ本当の自分かな？"ってなる'},
    'cancer':      {'light':'仁愛の炎を灯す','shadow':'調子に乗って自由に表現しちゃったあとの一人反省会が長すぎる'},
    'leo':         {'light':'至高の','shadow':'自分が輝いてないと機嫌が悪くなる、いつも「すごいね」を欲しがる'},
    'virgo':       {'light':'精励なる','shadow':'全力で楽しむお祭り人間のくせに、あとで自分に全力ダメ出し'},
    'libra':       {'light':'高潔なる','shadow':'自由に生きたいカリスマ気取りなのに、やりすぎが気になって夜眠れない'},
    'scorpio':     {'light':'灼熱の意志を秘めた','shadow':'褒められると無敵ヒーローだけど、褒められないとモブキャラになる'},
    'sagittarius': {'light':'天空を駆ける','shadow':'全力で楽しむお祭り人間、祭りが終わった瞬間の暗闘が深すぎる'},
    'capricorn':   {'light':'威厳に満ちた','shadow':'本当は死にそうなのに、私に任せとけ！が口癖な'},
    'aquarius':    {'light':'凛然たる','shadow':'派手に盛り上げるドラマチストなのに、一番伝えたい人にだけ冷たくなる'},
    'pisces':      {'light':'天恵の光を放つ','shadow':'自分を信じて突き進む情熱家だけど、いつのまにか後ろに全力疾走'},
  },
  'virgo': {
    'aries':       {'light':'峻烈なる','shadow':'段取りを完璧に組むのに、怒りだけはノープランで爆発する'},
    'taurus':      {'light':'篤実なる','shadow':'几帳面に整えた毎日を手放せない、それが執着だと気づいてない'},
    'gemini':      {'light':'慧眼の','shadow':'何でも見抜く分析力があるのに、自分の気持ちだけ永遠に分析中'},
    'cancer':      {'light':'奉仕の心を持つ','shadow':'地味に全部やってくれる縁の下の力持ちだけど、"ありがとう"がないと静かに壊れる'},
    'leo':         {'light':'至誠の','shadow':'完璧にこなして当たり前の顔してるくせに、心の中では拍手を永遠に待っている'},
    'virgo':       {'light':'求道の','shadow':'自分にダメ出しする天才、自分を許す以外のことは全て完璧にできる'},
    'libra':       {'light':'思慮深き','shadow':'他人への的確なアドバイスが全部見えてるのに、指摘して嫌われるのが怖くて黙っている'},
    'scorpio':     {'light':'真贋を見極める','shadow':'感情に左右されずに冷静に分析してるふりして、許せない人の言動リストが100万ページある'},
    'sagittarius': {'light':'清廉なる','shadow':'"ちゃんとしなきゃ"が口癖なのに、楽しいことを見つけると全部投げ出しちゃんとできない'},
    'capricorn':   {'light':'克己の極みたる','shadow':'完璧を目指して走り続け、"もう十分だよ"が自分にだけ言えなくて倒れるまで走ってしまう'},
    'aquarius':    {'light':'洞察に優れた','shadow':'誰よりも他人に気遣いができる人なのに、自分が壊れかけてることだけ気づかない'},
    'pisces':      {'light':'仁徳の','shadow':'ちゃんとやる力は誰にも負けないのに、心の電池が切れると音もなく消える'},
  },
  'libra': {
    'aries':       {'light':'正義を秘めた','shadow':'平和主義で争いを避けてきたのに、溜め込みすぎてある日突然世界滅亡を企てる'},
    'taurus':      {'light':'雅なる','shadow':'センス抜群で何でもおしゃれ、でも着る服決めるのに３日かかる'},
    'gemini':      {'light':'叡智を宿す','shadow':'場の空気を読むプロなのに、自分の気持ちは永遠に謎だらけな'},
    'cancer':      {'light':'博愛の','shadow':'誰にでもニコニコ社交上手なのに、本当に甘えたい人の前では石像になる'},
    'leo':         {'light':'気品に溢れた','shadow':'「どっちでもいいよ」が口癖だけど、じつは自分の思いと違うと静かに拗ねる'},
    'virgo':       {'light':'端麗なる','shadow':'美しく完璧に整えたいが為に、小さなほころびを永遠と気にする'},
    'libra':       {'light':'均衡を司る','shadow':'みんなに好かれようとしすぎて、本当の自分が分からない'},
    'scorpio':     {'light':'裁きの天秤を持つ','shadow':'笑顔で何でも丸く収める裏側で、不届き者の名前は永久保存する'},
    'sagittarius': {'light':'自在なる','shadow':'バランスよく生きてきた調整役なのに、ふと全部投げ出して旅に出ちゃう'},
    'capricorn':   {'light':'献身の','shadow':'自己犠牲を伴い場を丸く収める笑顔の裏で、実は自分のしんどさを隠すプロ'},
    'aquarius':    {'light':'美を極めし','shadow':'調和を大事にするのに、本当に親しくなりそうになるとなぜか自分から壊してしまう'},
    'pisces':      {'light':'夢幻の調べを奏でる','shadow':'空気を読みすぎて自分を消して、消えたまま夢の中で暮らし始める'},
  },
  'scorpio': {
    'aries':       {'light':'烈火の意志を持つ','shadow':'普段はミステリアスに黙ってるのに、我慢の限界が突然すぎて周囲が崩壊する'},
    'taurus':      {'light':'永劫の','shadow':'沼にハマる才能と沼から出ない才能の両方を持ってる'},
    'gemini':      {'light':'深淵を見通す','shadow':'何も言わない、知らない顔して全部見ていて、脳内では全員のプロファイリングが走ってる'},
    'cancer':      {'light':'慈しみに満ちた','shadow':'信頼した人にしか見せない顔があって、その顔がびっくりするほど甘い'},
    'leo':         {'light':'玉座に座す','shadow':'興味ないふりが完璧なのに、好きな人に素通りされると夜中に枕を殴る'},
    'virgo':       {'light':'省察に長けた','shadow':'何考えてるかわからないって言われるけど、自分へのダメ出ししか考えていない'},
    'libra':       {'light':'静寂の威を放つ','shadow':'沈黙で強烈な圧をかけながら、嫌われたくなくて急に変な笑顔になる'},
    'scorpio':     {'light':'覚悟を決めた','shadow':'愛するか無視するかの二択、全部本気で全部重い'},
    'sagittarius': {'light':'誓いと自由を併せ持つ','shadow':'愛が深すぎて全部ささげたいのに、自由も全部ほしい矛盾の塊な'},
    'capricorn':   {'light':'鋼の秘めたる','shadow':'全部感じてるのに全部隠す、感情の金庫の鍵を自分で捨てちゃった'},
    'aquarius':    {'light':'孤絶にして純粋なる','shadow':'全力で愛したいのに、全力で愛されるのが怖くて逃げる'},
    'pisces':      {'light':'深海の祈りを捧げる','shadow':'100%で愛して100%で沈む、浮上するボタンを無くしてしまった'},
  },
  'sagittarius': {
    'aries':       {'light':'破天荒なる','shadow':'考える前にもう走ってる冒険家、ブレーキも当然ついてないから止まれない'},
    'taurus':      {'light':'大地を踏みしめる','shadow':'「なんとかなるっしょ」で生きてたつもりが、いつもの枕がないと眠れない'},
    'gemini':      {'light':'真実を射る','shadow':'人には正直すぎるくらい正直なのに、自分に対してだけ嘘をつく'},
    'cancer':      {'light':'故郷を想う','shadow':'知らない場所を夢中で追いかけるくせに、帰る場所が見えないと泣いてしまう'},
    'leo':         {'light':'栄光を纏う','shadow':'人生まるごとエンタメにしたいタイプで、「すごいね」が燃料源な'},
    'virgo':       {'light':'志を正す','shadow':'計画を華麗に無視して楽しむ天才が、夜中に計画通りにしなかった自分を裁き続ける'},
    'libra':       {'light':'風雅なる','shadow':'縛られたくないくせに、"あの人どう思ったかな"で自分を縛り続ける自虐'},
    'scorpio':     {'light':'運命に身を捧げる','shadow':'束縛されると死んでしまうのに、好きになると"私を縛って"って差し出す変な'},
    'sagittarius': {'light':'天涯を翔ける','shadow':'楽しいの上に楽しいを重ねて、いままで何をしてきたかを忘れる'},
    'capricorn':   {'light':'大志を抱く','shadow':'楽天家の顔で堂々と大きい夢を語るが、裏で必死に積み上げてないと眠れない努力家な'},
    'aquarius':    {'light':'彼方を見据える','shadow':'旅先では誰とでも打ち解けるのに、帰ってきたら誰も隣にいない謎な'},
    'pisces':      {'light':'星に導かれし','shadow':'力強く走って走って走り続けられるが、気がついたら夢の中にいる不思議な'},
  },
  'capricorn': {
    'aries':       {'light':'剛毅なる','shadow':'100段積み上げた努力を、1秒のキレで吹き飛ばす才能がある'},
    'taurus':      {'light':'不撓不屈の','shadow':'高みを目指して全てを拾う、まだ持つの？と言われても持ち続けることができる筋肉'},
    'gemini':      {'light':'深謀遠慮の','shadow':'冷静に判断したいのに、脳内の議論が白熱しすぎて結論が出ない'},
    'cancer':      {'light':'温情の','shadow':'全部一人で背負い込むくせに、本当は誰かに甘えたくてたまらない'},
    'leo':         {'light':'威光を隠す','shadow':'認められたい気持ちを隠すのが上手すぎて、誰にも気づいてもらえない'},
    'virgo':       {'light':'精進を極めた','shadow':'「ちゃんとした人」でいたいプライドに、「もっとちゃんとしなきゃ」が永遠に追いつかない'},
    'libra':       {'light':'堅忍の','shadow':'石橋を叩いて渡る慎重さなのに、頼まれると断れなくて結局渡らされる'},
    'scorpio':     {'light':'静謐なる怒りの','shadow':'サボってる人を見ると静かに腹が立つ、でもその怒りは誰にも見せない'},
    'sagittarius': {'light':'求道者たる','shadow':'目標に向かって走り続けるストイックなのに、ときどき全部捨てて旅に出たくなる'},
    'capricorn':   {'light':'峻厳なる','shadow':'自分に課したルールが厳しすぎて、泣きたくても泣き方を忘れてる'},
    'aquarius':    {'light':'朴訥にして誠の','shadow':'背中で語るタイプなのに、背中じゃ伝わらないことが多すぎる'},
    'pisces':      {'light':'黎明を待つ','shadow':'ストイックに走り続けて、限界を超えた瞬間ふっといなくなる'},
  },
  'aquarius': {
    'aries':       {'light':'革新の炎を灯す','shadow':'常識を疑う頭脳があるのに、自分の衝動だけは疑わない'},
    'taurus':      {'light':'理想を守る','shadow':'世の中を変えたい革命家なのに、自分の生活は一切変えたくない'},
    'gemini':      {'light':'星霜を超える知の','shadow':'常識に疑問を持つ頭脳が優秀すぎて、自分自身の存在に疑問を持ち始める'},
    'cancer':      {'light':'人を照らす','shadow':'人類を愛する理想家なのに、目の前の大事な人にだけ不器用になる'},
    'leo':         {'light':'天命を負う','shadow':'誰にも合わせたくないくせに、誰からも認められたい矛盾の塊'},
    'virgo':       {'light':'先見の明を持つ','shadow':'大きな夢を描ける完璧な頭で、自分の小さな傷を数え続ける'},
    'libra':       {'light':'自由を貫く','shadow':'"俺は俺だ"と思ってるくせに、既読スルーされると気になって仕方ない'},
    'scorpio':     {'light':'深き渇望の','shadow':'"執着しない主義"なのに、好きな人のSNSだけ秒でチェックする'},
    'sagittarius': {'light':'未踏を拓く','shadow':'未来ばかり見てる理想家で、足元の現実はいつも見て見ぬふりする'},
    'capricorn':   {'light':'信念を曲げぬ','shadow':'世のルールなんて壊せると思ってるのに、自分に課したルールだけ壊せない'},
    'aquarius':    {'light':'唯一無二の','shadow':'人と違うことを選び続けて、気づいたら誰もいない場所にいて寂しい'},
    'pisces':      {'light':'衆生を憂う','shadow':'独りで考える時間が好きだけど、誰かの心配をして一日が終わっている'},
  },
  'pisces': {
    'aries':       {'light':'静寂に秘めた烈火の','shadow':'ふわふわ優しく見えるのに、地雷を踏まれると豹変する'},
    'taurus':      {'light':'安寧を愛する','shadow':'夢見がちでふわっとしてるくせに、お気に入りのものへのこだわりだけガチ'},
    'gemini':      {'light':'万象を感じ取る','shadow':'人の気持ちは手に取るようにわかるのに、自分の気持ちだけ整理がつかない'},
    'cancer':      {'light':'無垢なる慈愛の','shadow':'他人全員の面倒を見ようとするのに、自分の面倒をみる方法を知らない'},
    'leo':         {'light':'天与の才を持つ','shadow':'天性の芸術的センスがあるのに、認めてもらえないと一瞬で自信が消える'},
    'virgo':       {'light':'清浄なる','shadow':'日中は"なんとかなる"で笑ってるのに、深夜2時に自分対自分の裁判が始まる'},
    'libra':       {'light':'共感の涙を知る','shadow':'泣いてる人の隣には必ずいるのに、自分が泣きたいとき隣に誰もいない'},
    'scorpio':     {'light':'深淵の愛を宿す','shadow':'どこまでも柔らかい人なのに、愛情の深さだけナイフみたいに鋭い'},
    'sagittarius': {'light':'運命を信じる','shadow':'"この人しかいない"が毎回本気で、毎回違う人をみている'},
    'capricorn':   {'light':'鋼の夢を見る','shadow':'夢見がちな顔の裏に、誰にも見せない鋼のプライドをもっている'},
    'aquarius':    {'light':'月光を纏う','shadow':'恋に落ちるまではロマンチスト全開なのに、落ちた瞬間に急に冷静になる'},
    'pisces':      {'light':'透明なる祈りの','shadow':'誰かのために泣いて、誰かのために笑って、気づいたら自分が透明になってる'},
  },
};

// ══════════════════════════════════════════════
// HTML sanctuary.html: TITLE_CLASSES
// ══════════════════════════════════════════════
const titleClasses = <String, Map<String, String>>{
  'power':  {'page':'Knight','knight':'Dragoon','queen':'Paladin','king':'Overlord','mixed':'Spellblade'},
  'mind':   {'page':'Sage','knight':'Strategist','queen':'Chancellor','king':'Judge','mixed':'Wizard'},
  'spirit': {'page':'Cleric','knight':'Astrologer','queen':'Oracle','king':'Fate Weaver','mixed':'Druid'},
  'shadow': {'page':'Trickster','knight':'Liberator','queen':'Phantom','king':'Rogue','mixed':'Alchemist'},
  'heart':  {'page':'Bard','knight':'Sorcerer','queen':'Enchanter','king':'Emperor','mixed':'Chronomancer'},
};

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
