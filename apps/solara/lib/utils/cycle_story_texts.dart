/// 月齢サイクルのストーリーテキスト（JP/EN）
/// 翻訳ではなく、それぞれの言語でネイティブに書かれたテキスト。

class CycleStoryTexts {
  CycleStoryTexts._();

  // ── New Moon ──

  static const newMoonJP = [
    '太陽と月が重なる。\nすべての光が一つになるこの瞬間、\nあなたの星もまた、原初の輝きに戻る。',
    '完全なあなたを覆い隠しているもの。\nそれは外から来たのではなく、\nいつの間にか自分自身が纏ってしまった霧のようなもの。\n纏ってしまう事はあなたの責任ではありません。\n社会環境、家族関係、仕事上の付き合い、恋愛など。あなたを覆い隠す事柄はたくさんあります。\nでもね、纏ってしまう事を悪い事だとは思わないで。私たちはそんなあなたを愛おしく感じ、いつまでも見守っています。そして、私たちはいつでも、完全なあなたを見ています。',
    '自分自身が気付かないうちに纏ってしまった霧を晴らそうとする事。とても素晴らしいです。あなたの本当の輝きが解き放たれる事を、あなたの世界は望んでいます。さぁ自信を持って。私たちはいつもあなたを応援しています。',
    'このサイクルで、一枚の霧を手放そう。\n手放すほど、あなたの光は透けて見えるようになる。',
    'Stellaがあなたを見守っている。',
  ];

  static const newMoonEN = [
    'The sun and moon align.\nIn this moment where all light becomes one,\nyour star returns to its original radiance.',
    'What conceals the whole you \u2014\nit didn\'t come from the outside.\nIt\'s like a mist you unknowingly wrapped around yourself over time.\nAnd that\'s not your fault.\nSocial expectations, family dynamics, work relationships, love \u2014 so many things can dim your light.\nBut please, don\'t see it as something wrong. We find you endearing through all of it, and we will watch over you always. And we always see the complete you.',
    'Choosing to clear the mist you didn\'t even realize you\'d gathered \u2014 that is something truly beautiful. Your world is waiting for your true radiance to shine through. So stand tall. We are always cheering you on.',
    'This cycle, let go of one layer of mist.\nThe more you release, the more your light shines through.',
    'Stella is watching over you.',
  ];

  // ── Full Moon ──

  static const fullMoonJP = [
    '月が満ちた。\nこれは何かが「完成した」のではない。\n太陽の光が、月の全面を照らしている。\n隠れる場所がなくなった、ということ。',
    // {chosen} は呼び出し側で差し替え
    'あなたが手放そうとしたもの \u2014\n\u300c{chosen}\u300d',
    '今、その霧はどうなっている？\n満月の光は嘘をつけない。\n薄くなったか、まだそこにあるか。\nどちらでも、あなたはすでに完全なまま。',
    'ただ、見つめることが光になる。',
  ];

  static const fullMoonEN = [
    'The moon is full.\nThis doesn\'t mean something is "complete."\nIt means the sun\'s light is illuminating every surface of the moon.\nThere is nowhere left to hide.',
    'What you chose to release \u2014\n\u201C{chosen}\u201D',
    'How is that mist now?\nThe full moon cannot lie.\nWhether it has thinned or still lingers \u2014\neither way, you are already whole.',
    'Simply looking is itself a light.',
  ];

  // ── Catasterism ──

  static List<String> catasterismJP(int totalDays) => [
    '$totalDays\u65e5\u9593\u3001\u3042\u306a\u305f\u306f\u6bce\u65e5\uff11\u3064\u306e\u661f\u3092\u4f5c\u3063\u3066\u304d\u307e\u3057\u305f\u3002\n\u305d\u306e\u5149\u306e\u7c92\u304cStella\u306e\u5468\u308a\u306b\u96c6\u307e\u308a\u307e\u3057\u305f\u3002',
    '\u53e4\u4ee3\u306e\u4eba\u3005\u306f\u7a7a\u3092\u898b\u4e0a\u3052\u3066\u3001\n\u6563\u3089\u3070\u3063\u305f\u661f\u3092\u7dda\u3067\u7d50\u3073\u3001\u7269\u8a9e\u3092\u898b\u51fa\u3057\u305f\u3002\n\u661f\u5ea7\u3068\u306f\u300c\u767a\u898b\u300d\u3067\u306f\u306a\u304f\u300c\u610f\u5473\u3065\u3051\u300d\u3002\n\u661f\u306f\u305a\u3063\u3068\u305d\u3053\u306b\u3042\u3063\u305f\u3002\u4eba\u304c\u7269\u8a9e\u3092\u4e0e\u3048\u305f\u3002',
    '\u3042\u306a\u305f\u306e\u65e5\u3005\u3082\u305d\u3046\u3002\u3042\u306a\u305f\u306e\u65e5\u3005\u3092\u3069\u3093\u306a\u7269\u8a9e\u3001\u661f\u5ea7\u306b\u3057\u307e\u3059\u304b\uff1f\u81ea\u7531\u306b\u3042\u306a\u305f\u304c\u6c7a\u3081\u3089\u308c\u307e\u3059\u3002\n\u3042\u306a\u305f\u306e\u4eba\u751f\u306b\u7269\u8a9e\u3092\u4e0e\u3048\u308b\u529b\u306f\u3001\u3042\u306a\u305f\u306e\u4e2d\u306b\u3042\u308b\u3002\n\u611b\u306b\u6ea2\u308c\u3001\u30ef\u30af\u30ef\u30af\u3057\u305f\u610f\u5473\u3092\u3064\u3051\u307e\u3057\u3087\u3046\u3002\n\u611b\u3068\u30ef\u30af\u30ef\u30af\u3092\u898b\u3064\u3051\u3089\u308c\u308b\u3053\u306e\u4e16\u754c\u3002\n\u611b\u3068\u30ef\u30af\u30ef\u30af\u306b\u79c1\u305f\u3061\u306f\u5c0e\u304d\u307e\u3059\u3002',
    '\u6bce\u65e5\u4f5c\u3063\u305f\u4e00\u3064\u4e00\u3064\u306e\u661f\u306f\u5c0f\u3055\u306a\u5149\u3002\n\u3067\u3082\u632f\u308a\u8fd4\u308b\u3068\u3001\u305d\u3053\u306b\u5f62\u304c\u73fe\u308c\u308b\u3002\u3042\u306a\u305f\u304c\u6b69\u3093\u3060\u5f62\u304c\u3042\u308b\u3002',
    // {chosen} は呼び出し側で差し替え
    '\u3053\u306e\u6708\u9f62\u30b5\u30a4\u30af\u30eb\u3067\u3042\u306a\u305f\u304c\u624b\u653e\u305d\u3046\u3068\u3057\u305f\u3082\u306e \u2014\n\u300c{chosen}\u300d',
    '\u624b\u653e\u305b\u305f\u3060\u308d\u3046\u304b\uff1f\n\u3069\u3061\u3089\u306e\u7b54\u3048\u3082\u6b63\u3057\u3044\u3002\n\u624b\u653e\u305b\u305f\u306a\u3089\u3001\u3042\u306a\u305f\u306e\u661f\u5ea7\u306f\u305d\u306e\u89e3\u653e\u306e\u5f62\u3092\u523b\u3080\u3002\n\u307e\u3060\u9014\u4e2d\u306a\u3089\u3001\u3042\u306a\u305f\u306e\u661f\u5ea7\u306f\u305d\u306e\u65c5\u8def\u306e\u5f62\u3092\u523b\u3080\u3002',
    '\u3069\u3061\u3089\u3082\u3001\u3042\u306a\u305f\u304c\u751f\u304d\u305f\u8a3c\u3002\n\u661f\u5ea7\u306f\u6c38\u9060\u306b\u6d88\u3048\u306a\u3044\u3002\u3042\u306a\u305f\u306f\u3059\u3067\u306b\u5b8c\u5168\u306a\u5b58\u5728\u3002\u3042\u306a\u305f\u304c\u65e5\u3005\u884c\u3063\u305f\u5168\u3066\u306e\u9078\u629e\u3084\u6c7a\u5b9a\u3092\u79c1\u305f\u3061\u306f\u5c0a\u91cd\u3057\u3001\u5fdc\u63f4\u3057\u307e\u3059\u3002',
    '\u305d\u3057\u3066\u3042\u306a\u305f\u306f\u3001\u307e\u305f\u65b0\u3057\u3044\u65b0\u6708\u3092\u8fce\u3048\u308b\u3002\u3042\u306a\u305f\u304c\u751f\u304d\u3066\u3044\u308b\u3053\u3068\u306b\u304a\u3081\u3067\u3068\u3046\u3002',
  ];

  static List<String> catasterismEN(int totalDays) => [
    'For $totalDays days, you created a star each day.\nThose grains of light have gathered around Stella.',
    'The ancients looked up at the sky\nand drew lines between scattered stars, finding stories within them.\nA constellation is not a "discovery" \u2014 it is a "meaning."\nThe stars were always there. It was people who gave them stories.',
    'Your days are the same. What story will you make of them? What constellation will they become? That is entirely yours to decide.\nThe power to shape your story lives within you.\nFill it with love and wonder.\nA world where love and joy can be found.\nWe will guide you toward them.',
    'Each star you created is a small light.\nBut looking back, a shape appears \u2014 the shape of the path you walked.',
    'What you chose to release this lunar cycle \u2014\n\u201C{chosen}\u201D',
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
