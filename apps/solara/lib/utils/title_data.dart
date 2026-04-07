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
