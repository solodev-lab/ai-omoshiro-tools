// ============================================================
// Solara Planet Introduction — Map 画面の惑星マーカータップ説明
//
// Phase: 2026-05-07 全 10 惑星対応完了
//   第1弾: 月 / 金星 / 木星 / 土星
//   第2弾: 太陽 / 水星 / 火星 / 天王星 / 海王星 / 冥王星
//
// トーン規約 (Solara らしさ):
//   - 詩的な短文と改行のリズム
//   - 「あなた」呼称・優しく語りかける
//   - 占星術用語より、体験的な比喩 (光・風・種・地層など)
//   - 「司る」「課題」より「授ける」「贈る」「灯す」
//   - 静かな伴走感 (Stella/Solara が見守っているニュアンス)
//
// フレームの定義:
//   natal      = 出生時のホロスコープ → 生まれ持って授かったもの
//   transit    = 今この瞬間の空 → 訪れる風・潮の流れ
//   progressed = 内なる暦 (1日=1年法) → ゆっくり熟成する内面
// ============================================================

import 'solara_i18n.dart' show isEnLocale;

class PlanetIntroFrame {
  /// 1行サマリ (popup ヘッダ直下に出す)
  final String summary;

  /// 詳細解説 (5-8 行程度、詩的な改行を含む)
  final String detail;

  /// 英語版 (STYLE_VOICE_EN 準拠・英語化 Phase 2)
  final String summaryEN;
  final String detailEN;

  const PlanetIntroFrame({
    required this.summary,
    required this.detail,
    required this.summaryEN,
    required this.detailEN,
  });

  /// ロケール連動表示 (en ロケールなら英語、それ以外は日本語)
  String get summaryDisplay => isEnLocale() ? summaryEN : summary;
  String get detailDisplay => isEnLocale() ? detailEN : detail;
}

class PlanetIntro {
  /// 日本語名 (例: '月')
  final String jp;

  /// 惑星のコア機能 (1行)
  final String coreSummary;

  /// 惑星のコア機能 (詳細)
  final String coreDetail;

  /// 英語版 (STYLE_VOICE_EN 準拠・英語化 Phase 2)
  final String coreSummaryEN;
  final String coreDetailEN;

  final PlanetIntroFrame natal;
  final PlanetIntroFrame transit;
  final PlanetIntroFrame progressed;

  const PlanetIntro({
    required this.jp,
    required this.coreSummary,
    required this.coreDetail,
    required this.coreSummaryEN,
    required this.coreDetailEN,
    required this.natal,
    required this.transit,
    required this.progressed,
  });

  /// ロケール連動表示
  String get coreSummaryDisplay => isEnLocale() ? coreSummaryEN : coreSummary;
  String get coreDetailDisplay => isEnLocale() ? coreDetailEN : coreDetail;

  /// frame キー ('natal' / 'transit' / 'progressed') から該当 frame を返す。
  /// 未知フレームは natal を返す。
  PlanetIntroFrame frameOf(String frameKey) {
    switch (frameKey) {
      case 'transit':
        return transit;
      case 'progressed':
        return progressed;
      default:
        return natal;
    }
  }
}

/// 惑星キー → 解説。Map 画面の PlanetSymbolsLayer タップで参照。
/// 全 10 惑星収録 (太陽 / 月 / 水星 / 金星 / 火星 / 木星 / 土星 / 天王星 / 海王星 / 冥王星)。
const Map<String, PlanetIntro> planetIntros = {
  // ─────────────────────────────────────────
  'sun': PlanetIntro(
    jp: '太陽',
    coreSummary: 'あなたという光が、なんのために灯されたかを照らす星。',
    coreSummaryEN:
        'The star that shows what the light that is you was ever lit for.',
    coreDetail:
        '太陽は、あなたの中心。\n'
        '人生という旅路で、どこへ向かおうとしているのか、\n'
        '本当のあなたはどんな顔をしているのか ―\n'
        'それを静かに照らし続ける光です。\n\n'
        '月が「夜の声」なら、\n'
        '太陽は「あなたが生まれる前から決めてきた、生きる方向」。',
    coreDetailEN:
        'The Sun is your center.\n'
        'On the journey called a life — where you are trying to go,\n'
        'what your true face looks like —\n'
        'it is the light that keeps quietly shining on it.\n\n'
        'If the Moon is "the voice of the night,"\n'
        'the Sun is "the direction of living you chose before you were even born."',
    natal: PlanetIntroFrame(
      summary: 'あなたが生まれた日、世界に贈った「私の本質」。',
      summaryEN:
          'The "essence of me" you offered to the world on the day you were born.',
      detail:
          'あなたが生まれた瞬間、太陽はあなたに「中心の灯」を授けました。\n'
          'なんのために生まれてきたのか、\n'
          'どんな自分でいるとき最も自分らしいのか ―\n'
          'その答えがここに、静かに記されています。\n\n'
          'まわりの期待に揺れたときは、\n'
          'この光に戻ってきてください。\n'
          'あなたを最初から知っているのは、ここの太陽だけです。',
      detailEN:
          'The moment you were born, the Sun gave you a "central flame."\n'
          'What you were born to do,\n'
          'when you are most yourself —\n'
          'the answer is written here, quietly.\n\n'
          'When the expectations around you sway you,\n'
          'you can come back to this light.\n'
          'The only one who has known you from the very start is this Sun.',
    ),
    transit: PlanetIntroFrame(
      summary: '空の太陽が、約1ヶ月ごとに季節の主題を運んでくる。',
      summaryEN:
          'The Sun in the sky carries a season\'s theme, about once a month.',
      detail:
          '空の太陽は、1年で12星座を一周します。\n'
          '滞在する1ヶ月のあいだ、その星座のテーマで\n'
          'あなたのまわりに季節が立ち上がります。\n\n'
          '誕生月のソーラーリターンは、\n'
          'その先1年に生きる主題が、静かに決まる時。\n\n'
          '誕生日が近づいたら、空を見上げてみてください。\n'
          'あなただけの一年が、また始まります。',
      detailEN:
          'The Sun in the sky circles all twelve signs in a year.\n'
          'During its month in each, the theme of that sign\n'
          'raises a season around you.\n\n'
          'The solar return of your birth month\n'
          'is when the theme you will live for the year ahead quietly settles.\n\n'
          'As your birthday nears, you might look up at the sky.\n'
          'A year that is yours alone is beginning again.',
    ),
    progressed: PlanetIntroFrame(
      summary: '内なる太陽が、約30年かけて人生の大章を替えていく。',
      summaryEN:
          'Your inner Sun turns the great chapters of a life, over about thirty years.',
      detail:
          'プログレスの太陽は1年で約1度進み、\n'
          '30年でひとつの星座を渡ります。\n\n'
          'ナタル太陽は「生まれ持った原型」。\n'
          'プログレス太陽は「いまここで生きている、現在の主役」。\n\n'
          '進行太陽が次の星座へ進んだとき、\n'
          '人生のテーマが静かに、しかし決定的に切り替わります。\n'
          '30歳前後、60歳前後 ― そんな大きな転機の正体は、\n'
          'たいてい、この星です。',
      detailEN:
          'The progressed Sun moves about one degree a year,\n'
          'crossing one sign in thirty.\n\n'
          'The natal Sun is "the archetype you were born with."\n'
          'The progressed Sun is "the lead role you are living, here and now."\n\n'
          'When the progressed Sun steps into the next sign,\n'
          'the theme of a life shifts — quietly, yet decisively.\n'
          'Around thirty, around sixty — the true face of those great turning points\n'
          'is, more often than not, this star.',
    ),
  ),

  // ─────────────────────────────────────────
  'moon': PlanetIntro(
    jp: '月',
    coreSummary: '夜のあなたの声。心がそっと休める場所を教えてくれる星。',
    coreSummaryEN:
        'Your voice in the night — the star that shows you where the heart can quietly rest.',
    coreDetail:
        '昼の太陽が「こうありたい自分」を照らすなら、\n'
        '月は「ふと感じてしまう本当のあなた」。\n\n'
        '静けさを欲した夕暮れ、\n'
        '誰にも見せずに泣いた夜、\n'
        '安心したくて手にしたもの ―\n'
        'そのすべてが、月のしずくです。',
    coreDetailEN:
        'If the daytime Sun lights the self you want to be,\n'
        'the Moon is the truer you that simply feels.\n\n'
        'The dusk when you longed for stillness,\n'
        'the night you cried where no one could see,\n'
        'the small thing you reached for to feel safe —\n'
        'all of it is a drop of the Moon.',
    natal: PlanetIntroFrame(
      summary: '生まれた瞬間、月があなたに刻んだ「安心のかたち」。',
      summaryEN:
          'The shape of comfort the Moon traced into you the moment you were born.',
      detail:
          '出生のとき、月はあなたに「心の休み場所」を授けました。\n'
          'なにに包まれると深く眠れるのか。\n'
          'なにを失うと心が冷えてしまうのか。\n'
          'そのかすかな信号が、あなたの月に書かれています。\n\n'
          '太陽が人生の旅路なら、\n'
          '月は途中で休める小さなベンチ。\n'
          '月の声に耳を澄ませた夜は、\n'
          '次の朝のあなたを、少しだけ優しくしてくれます。',
      detailEN:
          'At your birth, the Moon gave you a place for the heart to rest.\n'
          'What wraps around you lets you sleep most deeply.\n'
          'What, when lost, leaves the heart cold.\n'
          'That faint signal is written in your Moon.\n\n'
          'If the Sun is the journey of a life,\n'
          'the Moon is the small bench to rest on along the way.\n'
          'A night when you listened closely to the Moon\'s voice\n'
          'tends to leave the next morning\'s you a little gentler.',
    ),
    transit: PlanetIntroFrame(
      summary: '空をめぐる月が、今日の心に小さな潮を運ぶ。',
      summaryEN: 'The Moon crossing the sky brings a small tide to today\'s heart.',
      detail:
          '空の月は、約2.3日でひとつの星座を渡ります。\n'
          'なんとなく泣きたい夕方、\n'
          'なんとなくはしゃぎたい夜 ―\n'
          'それらは月が運ぶ、ささやかな潮の流れです。\n\n'
          '新月の夜、ひとつ種を蒔いてみましょう。\n'
          '満月の朝、隠れていたものが浮かんできます。\n'
          '大きな決断は満月の翌日以降へ。\n'
          'そのほうが、月がそっと味方をしてくれます。',
      detailEN:
          'The Moon in the sky crosses one sign in about 2.3 days.\n'
          'An evening you somehow want to cry,\n'
          'a night you somehow want to laugh out loud —\n'
          'these are the gentle tides the Moon carries.\n\n'
          'On the new-moon night, you might plant a single seed.\n'
          'On the full-moon morning, what was hidden tends to surface.\n'
          'Bigger decisions may rest until the day after the full moon —\n'
          'the Moon seems to lend its quiet support there.',
    ),
    progressed: PlanetIntroFrame(
      summary: '内なる月が、約2.3年ごとにあなたの章を切り替えていく。',
      summaryEN:
          'Your inner Moon turns the chapters of your life, about every 2.3 years.',
      detail:
          'プログレスの月は、ゆっくりとあなたの内側で章を変えていきます。\n'
          'およそ2.3年でひとつの星座を進む、内なる暦。\n\n'
          '気がつけば住む場所が変わっていた。\n'
          '気がつけば心の向く方角が変わっていた。\n'
          'そんなとき、内なる月が、あなたを次の物語へ連れていったのです。\n\n'
          '空の月ほど派手ではないけれど、\n'
          '「あの頃の私」と「いまの私」の景色を変えるのは、\n'
          'たいてい、この月です。',
      detailEN:
          'The progressed Moon slowly changes the chapters within you.\n'
          'An inner calendar, moving through one sign in about 2.3 years.\n\n'
          'Before you noticed, where you live had changed.\n'
          'Before you noticed, the direction your heart faced had changed.\n'
          'At such times, it was the inner Moon, carrying you into the next story.\n\n'
          'It is never as vivid as the Moon in the sky,\n'
          'yet what changes the scenery between \'the me of back then\' and \'the me of now\'\n'
          'is, more often than not, this Moon.',
    ),
  ),

  // ─────────────────────────────────────────
  'mercury': PlanetIntro(
    jp: '水星',
    coreSummary: 'あなたが世界と結ぶ、細くて素早い糸。言葉と好奇心の星。',
    coreSummaryEN:
        'The thin, quick thread that ties you to the world — the star of words and curiosity.',
    coreDetail:
        '水星は、つなぐ星。\n'
        'なにを考え、なにを語り、なにに好奇心が動くのか ―\n'
        'あなたと世界のあいだに細い橋をかける役目です。\n\n'
        'ニュース、おしゃべり、本、メール、ふとした疑問。\n'
        '軽やかに動くものはすべて、\n'
        '水星の領分にあります。',
    coreDetailEN:
        'Mercury is the star that connects.\n'
        'What you think, what you speak, what stirs your curiosity —\n'
        'its role is to lay a thin bridge between you and the world.\n\n'
        'News, chatter, books, messages, a passing question.\n'
        'Everything that moves lightly\n'
        'belongs to Mercury.',
    natal: PlanetIntroFrame(
      summary: 'あなたが生まれつき持っている、考え方と言葉のリズム。',
      summaryEN: 'The rhythm of thought and words you were born with.',
      detail:
          '生まれた瞬間、水星はあなたに「考えるための道具」を授けました。\n'
          'どんなふうに学ぶのか、\n'
          'どんな言葉が胸にすっと入るのか、\n'
          'なにに好奇心を引かれるのか ―\n'
          'その素質がここに記されています。\n\n'
          '人によって思考のテンポも、得意な伝え方も違います。\n'
          'あなたの水星のリズムを尊重するほど、\n'
          '言葉はあなたの味方になってくれます。',
      detailEN:
          'The moment you were born, Mercury gave you "tools for thinking."\n'
          'How you learn,\n'
          'which words slip easily into the heart,\n'
          'what draws your curiosity —\n'
          'that gift is written here.\n\n'
          'Everyone\'s pace of thought, their best way of telling, is different.\n'
          'The more you honor your Mercury\'s rhythm,\n'
          'the more words become your ally.',
    ),
    transit: PlanetIntroFrame(
      summary: '空の水星が、月ごとに会話と学びの風向きを変える。',
      summaryEN:
          'Mercury in the sky shifts the wind of conversation and learning, month by month.',
      detail:
          '空の水星は、約3週間でひとつの星座を渡ります (逆行を挟むと長引きます)。\n'
          '滞在中の星座のテーマで、\n'
          'やりとり、ニュース、学びごとに色がつきます。\n\n'
          '年に3回ある逆行 (約3週間) は、\n'
          'メッセージや書類が滞ったり、\n'
          '昔の人から連絡が来たりする時期。\n\n'
          '新しく始めるより、見直しと再会のほうが似合います。',
      detailEN:
          'Mercury in the sky crosses one sign in about three weeks (longer when it turns retrograde).\n'
          'In the theme of the sign it visits,\n'
          'exchanges, news, and learning take on color.\n\n'
          'The retrograde three times a year (about three weeks each)\n'
          'is a season when messages and papers may stall,\n'
          'or someone from the past gets back in touch.\n\n'
          'Less about starting new, more suited to review and reunion.',
    ),
    progressed: PlanetIntroFrame(
      summary: '内なる水星が、年単位で言葉と知性の深さを変えていく。',
      summaryEN:
          'Your inner Mercury changes the depth of words and mind, year by year.',
      detail:
          'プログレスの水星は1年で約1度ずつ進み、\n'
          'ひとつの星座を渡るのに、およそ30年かかります。\n\n'
          '若い頃に夢中だった本のジャンル、\n'
          'よく口にしていた言葉、\n'
          '― いま振り返ると、変わっていないでしょうか?\n\n'
          'それは、内なる水星が\n'
          'あなたの知性を次の段階へ連れていったしるしです。',
      detailEN:
          'The progressed Mercury moves about one degree a year,\n'
          'taking around thirty to cross a single sign.\n\n'
          'The genre of books you were lost in when young,\n'
          'the words you used to say often —\n'
          'looking back now, haven\'t they changed?\n\n'
          'That is a sign that your inner Mercury\n'
          'has carried your mind into its next stage.',
    ),
  ),

  // ─────────────────────────────────────────
  'venus': PlanetIntro(
    jp: '金星',
    coreSummary: '美しさを知っている星。あなたの「好き」のかたちを作る。',
    coreSummaryEN:
        'The star that knows beauty — it shapes the form of what you love.',
    coreDetail:
        '金星は、力ではなく調和で物事を動かす星。\n'
        'なにを美しいと感じるか、\n'
        'なにを心地よいと思うか、\n'
        'なにに価値を見いだすか ―\n'
        'その根源があなたの金星にあります。\n\n'
        '愛も、お金も、芸術も、\n'
        '根はおなじ「引き寄せの呼吸」。',
    coreDetailEN:
        'Venus moves things not by force but by harmony.\n'
        'What you find beautiful,\n'
        'what feels good to you,\n'
        'where you find worth —\n'
        'their source is in your Venus.\n\n'
        'Love, abundance, art —\n'
        'all share one root: the breath of attraction.',
    natal: PlanetIntroFrame(
      summary: '生まれた瞬間に授かった、愛と美のあなただけの流儀。',
      summaryEN: 'Your own way of love and beauty, granted the moment you were born.',
      detail:
          '生まれた瞬間、金星はあなたに「好き」のかたちを贈りました。\n'
          'どんな花を綺麗だと思うか、\n'
          'どんな言葉に胸が温かくなるか、\n'
          'どんな相手に自然と惹かれるか ―\n'
          'すべてがここに記されています。\n\n'
          '無理に好きになろうとしなくていい。\n'
          'あなたの金星を信じてください。\n'
          'それが、あなたを最も自然に輝かせる磁力です。',
      detailEN:
          'The moment you were born, Venus gave you the shape of "what you love."\n'
          'Which flowers you find lovely,\n'
          'which words warm the heart,\n'
          'whom you are naturally drawn to —\n'
          'all of it is written here.\n\n'
          'You don\'t have to force yourself to like anything.\n'
          'Trust your Venus.\n'
          'It is the magnetism that lets you shine most naturally.',
    ),
    transit: PlanetIntroFrame(
      summary: '空の金星が、出会いと喜びの風を運んでくる。',
      summaryEN: 'Venus in the sky carries a wind of encounter and delight.',
      detail:
          '空の金星は、約1ヶ月でひとつの星座を渡ります。\n'
          'その期間、その色合いの人や物事と、縁が結ばれやすくなります。\n\n'
          '誰かと笑った夕食、\n'
          '思いがけない贈り物、\n'
          '自分のために選んだ一着 ―\n'
          'すべて金星が運ぶ、小さなプレゼント。\n\n'
          '逆行の約40日は、過去の愛や価値観をそっと見直す静かな期間。\n'
          'なつかしい人を思い出したら、ありがとうと心で伝えてみて。',
      detailEN:
          'Venus in the sky crosses one sign in about a month.\n'
          'In that time, ties form more easily with people and things of that hue.\n\n'
          'A dinner where you laughed with someone,\n'
          'an unexpected gift,\n'
          'an outfit you chose just for yourself —\n'
          'each a small present Venus carries.\n\n'
          'Its retrograde of about forty days is a quiet spell to gently revisit past loves and values.\n'
          'If someone dear comes to mind, you might say thank you, in your heart.',
    ),
    progressed: PlanetIntroFrame(
      summary: '内なる金星が、年月をかけて「好き」の在りかを変えていく。',
      summaryEN:
          'Your inner Venus shifts where "what you love" lives, over the years.',
      detail:
          'プログレスの金星は1年で約1度ずつ進み、\n'
          'ひとつの星座を渡るのに、およそ30年かかります。\n\n'
          '若い頃に夢中だった人、欲しかったもの、憧れた生き方 ―\n'
          'そのどれもが、いまも同じ熱量とは限りません。\n'
          'それは、内なる金星があなたを次の「好き」へ導いた証です。\n\n'
          '長く続く恋や仕事の判断は、\n'
          '生まれたときの金星ではなく、\n'
          'いまここで動いている進行金星と相談を。',
      detailEN:
          'The progressed Venus moves about one degree a year,\n'
          'taking around thirty to cross a single sign.\n\n'
          'The person you adored when young, the things you wanted, the life you longed for —\n'
          'none of them necessarily burns at the same heat now.\n'
          'That is proof your inner Venus has led you toward your next "love."\n\n'
          'For lasting choices in love or work,\n'
          'consult not the Venus you were born with,\n'
          'but the progressed Venus moving here and now.',
    ),
  ),

  // ─────────────────────────────────────────
  'mars': PlanetIntro(
    jp: '火星',
    coreSummary: 'あなたの中の熱と、踏み出す勇気。意志の炎を灯す星。',
    coreSummaryEN:
        'The heat within you, and the courage to step out — the star that lights the flame of will.',
    coreDetail:
        '火星は、燃やす力。\n'
        '欲しいものを取りに行く瞬発力、\n'
        '守るために怒れる強さ、\n'
        '眠っていた身体に火を入れる原動力 ―\n'
        'それらは、あなたの火星の働きです。\n\n'
        '静止より行動を選ぶとき、\n'
        '人はみんな、自分の火星に火を入れています。',
    coreDetailEN:
        'Mars is the power that burns.\n'
        'The burst to go after what you want,\n'
        'the strength to grow angry in order to protect,\n'
        'the drive that sets a sleeping body alight —\n'
        'these are your Mars at work.\n\n'
        'Whenever we choose action over stillness,\n'
        'each of us is lighting our own Mars.',
    natal: PlanetIntroFrame(
      summary: 'あなたが生まれつき持っている、火の入れ方と闘い方。',
      summaryEN: 'How you catch fire and how you fight, born into you.',
      detail:
          '生まれた瞬間、火星はあなたに「踏み出すかたち」を授けました。\n'
          'なにに対してなら本気で動けるのか、\n'
          'どんなふうに怒り、どんなふうに欲しがるのか ―\n'
          'その固有のリズムがここに記されています。\n\n'
          '火星は、押さえつけるためにあるのではなく、\n'
          '正しく燃やすためにあります。\n'
          'あなたの火星が向く方向に、\n'
          '躊躇わず力を注いでいいのです。',
      detailEN:
          'The moment you were born, Mars gave you "the shape of stepping forward."\n'
          'What you can truly move for,\n'
          'how you anger, how you want —\n'
          'that particular rhythm is written here.\n\n'
          'Mars is not there to be held down,\n'
          'but to be burned well.\n'
          'You may pour your strength, without hesitation,\n'
          'in the direction your Mars faces.',
    ),
    transit: PlanetIntroFrame(
      summary: '空の火星が、約2ヶ月ごとに行動の的を変えていく。',
      summaryEN: 'Mars in the sky shifts the target of action, about every two months.',
      detail:
          '空の火星は、約2ヶ月でひとつの星座を渡ります。\n'
          '滞在中の星座のテーマで、\n'
          'あなたの中に「動きたい」という衝動が立ち上がります。\n\n'
          '2年に一度の逆行 (約2.5ヶ月) は、\n'
          '外向きの戦いを、内向きの整理へと変える時期。\n\n'
          '怒りの矛先を見つめ直すには、\n'
          'ちょうどいいタイミングです。',
      detailEN:
          'Mars in the sky crosses one sign in about two months.\n'
          'In the theme of the sign it visits,\n'
          'an urge to "move" rises within you.\n\n'
          'Its retrograde once every two years (about 2.5 months)\n'
          'is a season that turns outward battle into inward sorting.\n\n'
          'It is a fitting time to look again\n'
          'at where your anger is aimed.',
    ),
    progressed: PlanetIntroFrame(
      summary: '内なる火星が、年月をかけて闘い方を成熟させていく。',
      summaryEN: 'Your inner Mars matures the way you fight, over the years.',
      detail:
          'プログレスの火星は1年で約0.5度ずつ進み、\n'
          'ひとつの星座を渡るのに、およそ60年かかります。\n\n'
          '20代に向いていた怒りの方向と、\n'
          'いま心が動く方向 ―\n'
          '違っているなら、それは\n'
          '内なる火星があなたの戦い方を成熟させたしるし。\n\n'
          'いまのあなたが本気で守りたいものを、\n'
          '進行火星が静かに教えてくれます。',
      detailEN:
          'The progressed Mars moves about half a degree a year,\n'
          'taking around sixty to cross a single sign.\n\n'
          'The direction your anger faced in your twenties,\n'
          'and the direction your heart moves now —\n'
          'if they differ, that is\n'
          'a sign your inner Mars has matured the way you fight.\n\n'
          'What the you of now truly wants to protect,\n'
          'the progressed Mars quietly shows you.',
    ),
  ),

  // ─────────────────────────────────────────
  'jupiter': PlanetIntro(
    jp: '木星',
    coreSummary: '空を広げる星。あなたの世界に大きな余白を作ってくれる。',
    coreSummaryEN:
        'The star that widens the sky — it opens a great margin in your world.',
    coreDetail:
        '木星は、ふくらませる力。\n'
        '視野を広げ、希望を灯し、\n'
        '「もう少しいけるかも」と背中をそっと押す星。\n\n'
        '高い学び、遠い土地、寛大な心、\n'
        'そしてふいに訪れる恵み ―\n'
        'それらはすべて、木星があけてくれた余白から入ってきます。',
    coreDetailEN:
        'Jupiter is the power that expands.\n'
        'It widens your view, kindles hope,\n'
        'and gently nudges you — "maybe a little further."\n\n'
        'Higher learning, distant lands, a generous heart,\n'
        'and grace that arrives out of nowhere —\n'
        'all of it enters through the margin Jupiter opened for you.',
    natal: PlanetIntroFrame(
      summary: '生まれつき、ものごとが広がりやすい領域。',
      summaryEN: 'The area where things widen easily, by birth.',
      detail:
          '出生のとき、木星はあなたに「許される場所」を授けました。\n'
          'そこでは多少の失敗が許され、\n'
          '気がつけば誰かが手を貸してくれて、\n'
          '勝手に道が広がっていく ―\n'
          'そんな、不思議な領域です。\n\n'
          '謙虚に、しかし大胆に。\n'
          'ここで遠慮しすぎると、せっかくの広がりを活かしきれません。\n'
          'あなたが堂々と広がるとき、世界もそれを喜びます。',
      detailEN:
          'At your birth, Jupiter gave you "a place where you are allowed."\n'
          'There, a little failure is forgiven,\n'
          'before you know it someone lends a hand,\n'
          'and the path widens on its own —\n'
          'such a curious area.\n\n'
          'Humble, yet bold.\n'
          'Hold back too much here and you can\'t make the most of the opening.\n'
          'When you widen with confidence, the world delights in it too.',
    ),
    transit: PlanetIntroFrame(
      summary: '空の木星が、1年かけてあなたの世界を広げてくれる。',
      summaryEN: 'Jupiter in the sky widens your world over the course of a year.',
      detail:
          '空の木星は、1年でひとつの星座を渡ります。\n'
          'その1年、滞在中の星座が示すテーマで\n'
          '思いがけない縁、学び、機会が訪れます。\n\n'
          '「気がつけば、何かが大きくなっていた」 ―\n'
          'それが、木星が通り過ぎたしるし。\n\n'
          '12年に一度のジュピター・リターンは、\n'
          'あなたの人生に新しい章を開く節目の年。\n'
          'その風が吹いたら、舟を出してみて。',
      detailEN:
          'Jupiter in the sky crosses one sign in a year.\n'
          'Through that year, in the theme of the sign it visits,\n'
          'unexpected ties, learning, and chances arrive.\n\n'
          '"Before I knew it, something had grown larger" —\n'
          'that is the mark of Jupiter passing through.\n\n'
          'The Jupiter return, once every twelve years,\n'
          'is the milestone year that opens a new chapter in your life.\n'
          'When that wind blows, you might set your boat out.',
    ),
    progressed: PlanetIntroFrame(
      summary: '生涯をかけて、あなたの哲学をゆっくり熟成させていく星。',
      summaryEN: 'The star that ripens your philosophy slowly, across a lifetime.',
      detail:
          'プログレスの木星は、1年で約0.08度しか進みません。\n'
          'ひとつの星座 (30度) を渡るには、およそ360年かかる計算です。\n'
          'だから一生のあいだに星座を変えることは、ほとんどありません。\n\n'
          'だからこの星は、日々の流れを見るのではなく、\n'
          '人生全体での信念や哲学の地層変動を見る指標です。\n\n'
          '「私はもう、あの頃の自分とは違う世界を信じている」 ―\n'
          'そう感じた日があったなら、\n'
          'それが、内なる木星があなたの哲学を静かに深めたしるしです。',
      detailEN:
          'The progressed Jupiter moves only about 0.08 degrees a year.\n'
          'To cross one sign (30 degrees) would take some 360 years.\n'
          'So it almost never changes sign within a lifetime.\n\n'
          'For that reason, this star is read not for the flow of days,\n'
          'but for the slow tectonics of belief and philosophy across a whole life.\n\n'
          '"I now believe in a different world than the self of back then" —\n'
          'if there was a day you felt that,\n'
          'it is a sign your inner Jupiter has quietly deepened your philosophy.',
    ),
  ),

  // ─────────────────────────────────────────
  'saturn': PlanetIntro(
    jp: '土星',
    coreSummary: '輪郭を引く星。時間をかけて、本物だけを残してくれる。',
    coreSummaryEN:
        'The star that draws the outline — given time, it keeps only what is real.',
    coreDetail:
        '土星は、絞る力。\n'
        '境界を引き、約束を守らせ、\n'
        '時間という風化に耐えるものだけを残す星。\n\n'
        '若い頃は、重く感じられるかもしれません。\n'
        'けれど人があなたに敬意を払う場所は、\n'
        'いつもこの星のあった領域です。',
    coreDetailEN:
        'Saturn is the power that narrows.\n'
        'It draws boundaries, holds you to your promises,\n'
        'and keeps only what withstands the weathering of time.\n\n'
        'In youth, it may feel heavy.\n'
        'Yet the place where people come to respect you\n'
        'is always the area this star has stood in.',
    natal: PlanetIntroFrame(
      summary: '時間をかけて、あなたが手にする揺るがぬ実力の在りか。',
      summaryEN: 'Where the unshakable strength you earn over time will live.',
      detail:
          '出生のとき、土星はあなたに「磨くべき場所」を渡しました。\n'
          '最初は苦手で、できれば避けたい領域。\n'
          'けれど何度も向き合っていくうちに、\n'
          '誰にも真似できない強度を身につけていく ―\n'
          'それが、あなたの土星の在りかです。\n\n'
          '逃げなくていい。\n'
          '時間は、いつもあなたの味方をしています。\n'
          '焦らず、ゆっくりで構いません。',
      detailEN:
          'At your birth, Saturn handed you "a place to polish."\n'
          'At first it is hard, an area you\'d rather avoid.\n'
          'Yet as you face it again and again,\n'
          'you take on a strength no one can imitate —\n'
          'that is where your Saturn lives.\n\n'
          'You don\'t have to run.\n'
          'Time is always on your side.\n'
          'No need to rush; slow is fine.',
    ),
    transit: PlanetIntroFrame(
      summary: '空の土星が、2.5年かけて「本気か?」と静かに問いかける。',
      summaryEN:
          'Saturn in the sky asks, quietly, "Do you mean it?" — over two and a half years.',
      detail:
          '空の土星は、2.5年でひとつの星座を渡ります。\n'
          'その間、滞在中の星座が示すテーマで\n'
          '「これは、本物?」と問われる出来事が訪れます。\n\n'
          'つらく感じる時期もあるでしょう。\n'
          'けれどそれは、本物だけを残すための、静かな整理。\n\n'
          '29.5年に一度のサターン・リターンは、\n'
          '大人の自分を確立するための通過儀礼。\n'
          'その風が抜けたとき、あなたの輪郭ははっきりと残ります。',
      detailEN:
          'Saturn in the sky crosses one sign in 2.5 years.\n'
          'In that time, in the theme of the sign it visits,\n'
          'events arrive that ask, "Is this real?"\n\n'
          'There may be stretches that feel hard.\n'
          'Yet that is a quiet sorting, to keep only what is real.\n\n'
          'The Saturn return, once every 29.5 years,\n'
          'is a rite of passage for establishing your grown self.\n'
          'When that wind passes, your outline stands clearly.',
    ),
    progressed: PlanetIntroFrame(
      summary: '生涯ほぼ動かず、ナタル土星の課題を一生かけて磨いていく。',
      summaryEN:
          'Barely moving in a lifetime, it polishes the natal Saturn\'s task across all your years.',
      detail:
          'プログレスの土星は、1年で約0.03度しか進みません。\n'
          'ひとつの星座 (30度) を渡るには、およそ880年かかる計算です。\n'
          'だから一生のあいだに星座を変えることは、ほぼありません。\n\n'
          'だからこの星は、一回ごとのタイミングを見るのではなく、\n'
          '「人生を貫く課題が、いまどう熟成しているか」を見る指標。\n\n'
          'ナタルの土星と語り合うようにして、\n'
          '長い時間をかけて、あなたの輪郭を磨きあげていきます。\n'
          'その仕事には、終わりがありません。だから、急がなくていいのです。',
      detailEN:
          'The progressed Saturn moves only about 0.03 degrees a year.\n'
          'To cross one sign (30 degrees) would take some 880 years.\n'
          'So it almost never changes sign within a lifetime.\n\n'
          'For that reason, this star is read not for single moments of timing,\n'
          'but for "how the lifelong task is ripening, now."\n\n'
          'As if in dialogue with your natal Saturn,\n'
          'it polishes your outline over a long, long time.\n'
          'That work has no end — and so there is no need to hurry.',
    ),
  ),

  // ─────────────────────────────────────────
  'uranus': PlanetIntro(
    jp: '天王星',
    coreSummary: '世界の輪郭を一瞬で書き換える稲妻。自由への渇望の星。',
    coreSummaryEN:
        'Lightning that rewrites the world\'s outline in an instant — the star of the thirst for freedom.',
    coreDetail:
        '天王星は、ざわつかせる星。\n'
        '「いまのままではない私」を呼び覚まし、\n'
        '既存の枠を一瞬で書き換える稲妻です。\n\n'
        '予期せぬ出来事、突然のひらめき、\n'
        '手放されていく古い役割 ―\n'
        'すべて、天王星が運んでくる風です。\n\n'
        '公転 84 年。一生をかけて、ひとめぐり。',
    coreDetailEN:
        'Uranus is the star that stirs things up.\n'
        'It wakes "the me that isn\'t as I am now,"\n'
        'lightning that rewrites the existing frame in an instant.\n\n'
        'Unexpected events, sudden flashes of insight,\n'
        'old roles being let go —\n'
        'all of it is the wind Uranus carries.\n\n'
        'An orbit of 84 years: one circuit across a lifetime.',
    natal: PlanetIntroFrame(
      summary: '生まれつきあなたの中にある、譲れない個性と自由。',
      summaryEN: 'The uncompromising individuality and freedom within you, by birth.',
      detail:
          '生まれた瞬間、天王星はあなたに「異質さの種」を授けました。\n'
          'まわりに合わせきれない違和感、\n'
          'どうしても譲れない感覚 ―\n'
          'それはあなたの欠点ではなく、\n'
          '天王星があなたに任せた、特別な配役です。\n\n'
          'まわりに合わせて消そうとするほど、\n'
          'この星はざわつきます。\n'
          '異質さを大切に。\n'
          'それが、あなたを唯一にします。',
      detailEN:
          'The moment you were born, Uranus gave you "a seed of difference."\n'
          'The unease of never quite fitting in,\n'
          'a sense you simply cannot give up —\n'
          'that is not a flaw in you,\n'
          'but a special role Uranus entrusted to you.\n\n'
          'The more you try to erase it to fit in,\n'
          'the more this star grows restless.\n'
          'Cherish your difference.\n'
          'It is what makes you one of a kind.',
    ),
    transit: PlanetIntroFrame(
      summary: '空の天王星が、約7年かけてあなたの世界を一新していく。',
      summaryEN: 'Uranus in the sky renews your world over about seven years.',
      detail:
          '空の天王星は、7年でひとつの星座を渡ります。\n'
          '滞在中の星座のテーマで、\n'
          '予期せぬ自由化、突然の変化が訪れます。\n\n'
          '計画通りいかない時期に見えるかもしれません。\n'
          'けれど振り返ったとき、\n'
          'その変化があなたを古い殻から解放してくれていたと気づくはず。\n\n'
          '天王星に逆らわないこと。\n'
          'この星は、あなたの自由を願っています。',
      detailEN:
          'Uranus in the sky crosses one sign in seven years.\n'
          'In the theme of the sign it visits,\n'
          'unexpected liberation and sudden change arrive.\n\n'
          'It may look like a time when nothing goes to plan.\n'
          'Yet looking back, you will likely notice\n'
          'that the change had freed you from an old shell.\n\n'
          'Try not to fight Uranus.\n'
          'This star wishes for your freedom.',
    ),
    progressed: PlanetIntroFrame(
      summary: '進行はとてもゆっくり。一生をかけて天王星の課題を磨く。',
      summaryEN:
          'Its progression is very slow; the Uranus task is polished across a lifetime.',
      detail:
          'プログレスの天王星は、1年で約0.012度ほど。\n'
          '一生のあいだに、せいぜい1度ぶんしか進みません。\n\n'
          'だからこの星は、タイミングを見るのではなく、\n'
          '「人生を貫く異質さ」が、いまどんな形で現れているかを\n'
          '見るための指標です。\n\n'
          'ナタル天王星と同じ方向を向き続け、\n'
          '長い時間をかけて、あなたの自由の輪郭を磨いていきます。',
      detailEN:
          'The progressed Uranus moves about 0.012 degrees a year.\n'
          'Across a whole life, it advances barely a single degree.\n\n'
          'So this star is read not for timing,\n'
          'but for the form your "lifelong difference"\n'
          'is taking now.\n\n'
          'Holding the same direction as your natal Uranus,\n'
          'it polishes the outline of your freedom over a long, long time.',
    ),
  ),

  // ─────────────────────────────────────────
  'neptune': PlanetIntro(
    jp: '海王星',
    coreSummary: 'すべての境界が溶けていく時間。夢と祈りと芸術の星。',
    coreSummaryEN:
        'The hours where every boundary dissolves — the star of dream, prayer, and art.',
    coreDetail:
        '海王星は、溶かす星。\n'
        '現実と夢の薄い膜のあいだで、\n'
        'ふいに涙が出るほど美しいものに、\n'
        'あなたを出会わせる星です。\n\n'
        '音楽、香り、慈愛、霊性、酔い ―\n'
        '輪郭を持たないものはすべて、\n'
        '海王星の領分にあります。\n\n'
        '公転 165 年。あなたの一生で、ほんの少ししか動きません。',
    coreDetailEN:
        'Neptune is the star that dissolves.\n'
        'In the thin film between the real and the dreamed,\n'
        'it brings you to meet something so beautiful\n'
        'it suddenly draws tears.\n\n'
        'Music, scent, compassion, the spiritual, intoxication —\n'
        'everything without an outline\n'
        'belongs to Neptune.\n\n'
        'An orbit of 165 years: in your lifetime, it moves only a little.',
    natal: PlanetIntroFrame(
      summary: '生まれつき、あなたの中で霧が立ちのぼる場所。',
      summaryEN: 'The place where mist rises within you, by birth.',
      detail:
          '生まれた瞬間、海王星はあなたに「夢みる力」を授けました。\n'
          'なにに憧れるのか、\n'
          'なにに胸が震えるのか、\n'
          'どこで現実が美しい霧に包まれるのか ―\n'
          'その素質がここに記されています。\n\n'
          'この星は、ときに人を迷わせます。\n'
          'けれど芸術や祈りや、無条件の愛は、\n'
          'いつもこの星から生まれています。',
      detailEN:
          'The moment you were born, Neptune gave you "the power to dream."\n'
          'What you long for,\n'
          'what makes the heart tremble,\n'
          'where reality wraps in a beautiful mist —\n'
          'that gift is written here.\n\n'
          'This star can sometimes lead one astray.\n'
          'Yet art, and prayer, and unconditional love\n'
          'are always born from it.',
    ),
    transit: PlanetIntroFrame(
      summary: '空の海王星が、14年かけてあなたの夢の景色を変える。',
      summaryEN: 'Neptune in the sky changes the scenery of your dreams over fourteen years.',
      detail:
          '空の海王星は、14年でひとつの星座を渡ります。\n'
          '滞在中の星座のテーマで、\n'
          '長い時間をかけた憧れと、ぼんやりとした霧を贈ります。\n\n'
          'はっきりとした出来事として現れにくく、\n'
          '気づけば「いつのまにか、こちらの世界に来ていた」 ―\n'
          'そんな静かな移行を起こす星です。\n\n'
          '抗わずに、流れに身をあずけてみてください。',
      detailEN:
          'Neptune in the sky crosses one sign in fourteen years.\n'
          'In the theme of the sign it visits,\n'
          'it gives long, slow longing and a soft, vague mist.\n\n'
          'It rarely shows up as a clear-cut event;\n'
          'before you know it, "somehow I had come over to this world" —\n'
          'such a quiet shift is what this star brings.\n\n'
          'Without resisting, you might let yourself drift with the current.',
    ),
    progressed: PlanetIntroFrame(
      summary: '進行はほぼ止まって見える。一生かけて夢を熟成させていく。',
      summaryEN: 'Its progression looks all but still; it ripens the dream across a lifetime.',
      detail:
          'プログレスの海王星は、1年で約0.006度ほど。\n'
          '一生のあいだに、1度にも満たないほどしか進みません。\n\n'
          'だからこの星は、\n'
          '「あなたの一生を貫く憧れの方向」を見る指標です。\n\n'
          'ナタル海王星のとなりに、ずっと寄り添うようにいて、\n'
          'あなたの夢を、長い時間かけて、ゆっくりと熟成させていきます。',
      detailEN:
          'The progressed Neptune moves about 0.006 degrees a year.\n'
          'Across a whole life, it advances less than a single degree.\n\n'
          'So this star is read for\n'
          '"the direction of longing that runs through your whole life."\n\n'
          'Staying ever close beside your natal Neptune,\n'
          'it ripens your dream, slowly, over a long, long time.',
    ),
  ),

  // ─────────────────────────────────────────
  'pluto': PlanetIntro(
    jp: '冥王星',
    coreSummary: '奥底にある根源の力。壊して、生まれ変わるための星。',
    coreSummaryEN:
        'The root power in the depths — the star for breaking down, and being reborn.',
    coreDetail:
        '冥王星は、根を揺さぶる星。\n'
        '表面の取り繕いをはがし、\n'
        '本当の力、本当の執着、本当の恐れを露わにします。\n\n'
        '死と再生、隠された資源、深い変容 ―\n'
        'すべて、冥王星の領分にあります。\n\n'
        '公転 248 年。\n'
        '一生のうちで、ひとつかふたつの星座しか進みません。',
    coreDetailEN:
        'Pluto is the star that shakes the roots.\n'
        'It peels away the surface pretense,\n'
        'and lays bare the true power, the true attachment, the true fear.\n\n'
        'Death and rebirth, hidden resources, deep transformation —\n'
        'all of it belongs to Pluto.\n\n'
        'An orbit of 248 years.\n'
        'In a single lifetime, it moves through only one or two signs.',
    natal: PlanetIntroFrame(
      summary: '生まれつきあなたが抱えている、最も深い力と執着。',
      summaryEN: 'The deepest power and attachment you carry, by birth.',
      detail:
          '生まれた瞬間、冥王星はあなたに「奥底の力」を授けました。\n'
          'いちばん手放したくないもの、\n'
          'いちばん壊されたくないもの、\n'
          'けれど壊れたとき、いちばん深い場所から再生してくる力 ―\n'
          'その源がここにあります。\n\n'
          'この星は、軽く扱うことができません。\n'
          'けれど人生の本当の底力は、\n'
          'いつもここから湧いてきます。',
      detailEN:
          'The moment you were born, Pluto gave you "the power of the depths."\n'
          'What you least want to let go of,\n'
          'what you least want broken,\n'
          'yet the power that, once broken, regenerates from the deepest place —\n'
          'its source is here.\n\n'
          'This star cannot be handled lightly.\n'
          'Yet the true reserve strength of a life\n'
          'always wells up from here.',
    ),
    transit: PlanetIntroFrame(
      summary: '空の冥王星が、約20年かけてあなたの奥底を作り変える。',
      summaryEN: 'Pluto in the sky remakes your depths over about twenty years.',
      detail:
          '空の冥王星は、ひとつの星座を渡るのに平均およそ20年。\n'
          'ただし軌道が大きな楕円のため、星座によって12〜30年と幅があります。\n'
          '滞在中の星座のテーマで、\n'
          '長い時間をかけた変容が、静かに進みます。\n\n'
          '変化が始まったときには気づきません。\n'
          '振り返ったとき、\n'
          '「あの頃の私は、もうここにはいない」と分かる ―\n'
          'それが、冥王星の仕事です。\n\n'
          '通り過ぎたあと、あなたは別の人として立っています。',
      detailEN:
          'Pluto in the sky takes, on average, about twenty years to cross one sign.\n'
          'Its orbit is a wide ellipse, though, so it ranges from 12 to 30 years by sign.\n'
          'In the theme of the sign it visits,\n'
          'a long, slow transformation proceeds quietly.\n\n'
          'You don\'t notice when the change begins.\n'
          'Looking back, you understand —\n'
          '"the me of back then is no longer here."\n'
          'That is Pluto\'s work.\n\n'
          'After it passes through, you stand as someone else.',
    ),
    progressed: PlanetIntroFrame(
      summary: '進行はほぼ止まって見える。一生をかけて深まっていく主題。',
      summaryEN: 'Its progression looks all but still; a theme that deepens across a lifetime.',
      detail:
          'プログレスの冥王星は、1年で約0.005度ほど。\n'
          '一生のあいだに、1度にも満たないほどしか動きません。\n\n'
          'だからこの星は、タイミングを見る星ではなく、\n'
          '「あなたが一生をかけて深めていく主題」が\n'
          'いま、どう熟成しているかを見る指標です。\n\n'
          'ナタル冥王星と寄り添いながら、\n'
          'あなたの最も深いところを、\n'
          '長い時間をかけて成熟させていきます。',
      detailEN:
          'The progressed Pluto moves about 0.005 degrees a year.\n'
          'Across a whole life, it moves less than a single degree.\n\n'
          'So this star is read not for timing,\n'
          'but for how "the theme you deepen across a lifetime"\n'
          'is ripening, now.\n\n'
          'Staying close beside your natal Pluto,\n'
          'it matures your very deepest place\n'
          'over a long, long time.',
    ),
  ),
};
