/// 月齢サイクルのストーリーテキスト（JP/EN）
/// 翻訳ではなく、それぞれの言語でネイティブに書かれたテキスト。
library;

class CycleStoryTexts {
  CycleStoryTexts._();

  // ── New Moon ──

  static const newMoonJP = [
    '太陽と月が重なる。\nすべての光が一つになるこの瞬間、\nあなたもまた、原初の輝きに戻る。',
    '完全なあなたを覆い隠しているもの。\nそれは外から来たのではなく、\nいつの間にか自分自身が纏ってしまった霧のようなもの。\n纏ってしまう事はあなたの責任ではありません。\n社会環境、家族関係、仕事上の付き合い、恋愛など。あなたを覆い隠す事柄はたくさんあります。\nでもね、纏ってしまう事を悪い事だとは思わないで。私たちはそんなあなたを愛おしく感じ、いつまでも見守っています。そして、私たちはいつでも、完全なあなたを見ています。',
    'あなたが、気付かないうちに纏ってしまった霧を晴らそうとする事。\n\n本当の輝きが解き放たれる事を、あなたの作る世界は望んでいます。',
    'このサイクルで、一枚の霧を手放しましょう。\n手放すほど、あなたの輝きがよく見えるようになりますよ。\n私たちはあなたを、いつでも見守っています。',
    'Stellaがあなたを見守っている。',
  ];

  static const newMoonEN = [
    'The sun and moon align.\nIn this moment where all light becomes one,\nyour star returns to its original radiance.',
    'What conceals the whole you —\nit didn\'t come from the outside.\nIt\'s like a mist you unknowingly wrapped around yourself over time.\nAnd that\'s not your fault.\nSocial expectations, family dynamics, work relationships, love — so many things can dim your light.\nBut please, don\'t see it as something wrong. We find you endearing through all of it, and we will watch over you always. And we always see the complete you.',
    'Choosing to clear the mist you didn\'t even realize you\'d gathered — that is something truly beautiful. Your world is waiting for your true radiance to shine through. So stand tall. We are always cheering you on.',
    'This cycle, let go of one layer of mist.\nThe more you release, the more your light shines through.',
    'Stella is watching over you.',
  ];

  // ── Full Moon ──

  static const fullMoonJP = [
    '月が満ちた。\nこれは何かが「完成した」のではない。\n太陽の光が、月の全面を照らしている。\n隠れる場所がなくなった、ということ。',
    // {chosen} は呼び出し側で差し替え
    'あなたが手放そうとしたもの —\n「{chosen}」',
    '今、その霧はどうなっている?\n満月の光は嘘をつけない。\n薄くなったか、まだそこにあるか。\nどちらでも、あなたはすでに完全なまま。',
    'ただ、見つめることが光になる。',
  ];

  static const fullMoonEN = [
    'The moon is full.\nThis doesn\'t mean something is "complete."\nIt means the sun\'s light is illuminating every surface of the moon.\nThere is nowhere left to hide.',
    'What you chose to release —\n“{chosen}”',
    'How is that mist now?\nThe full moon cannot lie.\nWhether it has thinned or still lingers —\neither way, you are already whole.',
    'Simply looking is itself a light.',
  ];

  // ── Catasterism ──

  static List<String> catasterismJP(int totalDays) => [
    '$totalDays日間、あなたは毎日１つの星を作ってきました。\nその光の粒がStellaの周りに集まりました。',
    '古代の人々は空を見上げて、\n散らばった星を線で結び、物語を見出しました。\n星座とは「発見」ではなく「意味づけ」。\n星はずっとそこにあり、そして人々が物語を与えました。',
    'あなたの日々もそう。あなたの日々をどんな物語、星座にしますか?自由にあなたが決められます。\nあなたの人生に物語を与える力は、あなたの中にあります。\n愛に溢れ、ワクワクした意味を付けてみませんか?\n愛とワクワクを見つけられるこの世界。\n\nあなたを愛とワクワクに、私たちは導きます。',
    '毎日作った一つ一つの星は小さな光。\nでも振り返ると、そこに形が現れる。あなたが歩んだ形がある。',
    // {chosen} は呼び出し側で差し替え
    'この月齢サイクルであなたが手放そうとしたもの —\n「{chosen}」',
    '手放せただろうか?\nどちらの答えも正しい。\n手放せたなら、あなたの星座はその解放の形を刻む。\nまだ途中なら、あなたの星座はその旅路の形を刻む。',
    'どちらも、あなたが生きた証です。\n星座は永遠に消えない。あなたはすでに完全な存在。あなたが日々行った全ての選択や決定を私たちは尊重し、応援します。',
    'そしてあなたは、また新しい新月を迎える。あなたが生きていることに\n\nおめでとう',
  ];

  static List<String> catasterismEN(int totalDays) => [
    'For $totalDays days, you created a star each day.\nThose grains of light have gathered around Stella.',
    'The ancients looked up at the sky\nand drew lines between scattered stars, finding stories within them.\nA constellation is not a "discovery" — it is a "meaning."\nThe stars were always there. It was people who gave them stories.',
    'Your days are the same. What story will you make of them? What constellation will they become? That is entirely yours to decide.\nThe power to shape your story lives within you.\nFill it with love and wonder.\nA world where love and joy can be found.\nWe will guide you toward them.',
    'Each star you created is a small light.\nBut looking back, a shape appears — the shape of the path you walked.',
    'What you chose to release this lunar cycle —\n“{chosen}”',
    'Were you able to let it go?\nEither answer is right.\nIf you released it, your constellation carves the shape of liberation.\nIf you\'re still on the way, your constellation carves the shape of the journey.',
    'Both are proof that you lived.\nConstellations never fade. You are already whole. We honor and support every choice and decision you made along the way.',
    'And now, you welcome a new moon. Congratulations on being alive.',
  ];

  /// 端末の言語設定に基づいてJP/ENを選択
  static bool _isJapanese(String locale) =>
      locale.startsWith('ja');

  static List<String> getNewMoon(String locale) =>
      _isJapanese(locale) ? newMoonJP : newMoonEN;

  static List<String> getFullMoon(String locale, String chosenText) {
    final texts = _isJapanese(locale) ? fullMoonJP : fullMoonEN;
    return texts.map((t) => t.replaceAll('{chosen}', chosenText)).toList();
  }

  static List<String> getCatasterism(String locale, int totalDays, String chosenText) {
    final texts = _isJapanese(locale)
        ? catasterismJP(totalDays)
        : catasterismEN(totalDays);
    return texts.map((t) => t.replaceAll('{chosen}', chosenText)).toList();
  }
}
