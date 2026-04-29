// ============================================================
// Solara Manifesto — 設計思想の言語化
//
// 占い的吉凶判定をしない、両面思想（陰陽・Jungian）でSolaraは構成される。
// ガイドページ章0（E5）から表示される、アプリの哲学的根幹。
//
// 設計根拠: project_solara_design_philosophy.md (2026-04-29 オーナー確定)
//
// 構成:
//   - sections: タイトル付きセクション3つ
//     1. 「☯ Solaraが信じる世界観」(opening)
//     2. 「2つのエネルギー」(soft/hardの説明)
//     3. 「Solaraからあなたへ」(closing — 判断はユーザーに委ねる宣言)
//
// 注意: このテキストはユーザーが推敲する前提のドラフト。
//       推敲後は同ファイルの定数を直接編集する。
// ============================================================
library;

class SolaraManifestoSection {
  final String title;
  final List<String> paragraphs;

  const SolaraManifestoSection({
    required this.title,
    required this.paragraphs,
  });
}

class SolaraManifesto {
  SolaraManifesto._();

  // ── 日本語版 ──

  static const List<SolaraManifestoSection> sectionsJP = [
    SolaraManifestoSection(
      title: '☯ Solara が信じる世界観',
      paragraphs: [
        'この世界は、両面で成立しています。',
        'ソフトとハードは、1つの軸の両端ではありません。\n'
            'それぞれが独立した、別のエネルギーです。',
        '良い・悪いではなく、性質の違い。\n'
            'どちらも、それぞれが「在る」もの。',
      ],
    ),
    SolaraManifestoSection(
      title: '2つのエネルギー',
      paragraphs: [
        '☯ ソフトエネルギー\n'
            '流れに乗る力。寛容、拡大、受容、安定。\n'
            '物事が滑らかに進み、出会いが生まれ、心が開かれる。',
        '☐ ハードエネルギー\n'
            '摩擦と変化の力。挑戦、変容、対峙、成長。\n'
            '葛藤の中で見えてくるものがあり、'
            '深い学びと、自分自身との出会いが起こる。',
        '両方とも、それぞれが美しいエネルギーです。\n'
            'そして、両方が同時に強く効くこともあります。\n'
            'そのとき、あなたは深い体験の中にいます。',
      ],
    ),
    SolaraManifestoSection(
      title: 'Solara からあなたへ',
      paragraphs: [
        'Solara は「どちらが正解か」を教えません。',
        '両方のエネルギーが、いつ、どこに、どれだけ在るか。\n'
            'それを事実として、あなたに伝えます。',
        'そこから先は、あなた自身の領域です。\n'
            'ソフトの流れに乗るのも、\n'
            'ハードの摩擦と向き合うのも、\n'
            '両方を同時に体験するのも、\n'
            'すべて、あなたの選択です。',
        'ときに、あなたは方角を選べないことがあるでしょう。\n'
            '行かざるを得ない場所がある。\n'
            ' 向こうから訪れる出来事がある。\n'
            'そのときも、Solara は判断しません。\n'
            '在るエネルギーを伝え、\n'
            'あなたが自分で読み取り、向き合うための材料を提供します。',
        'Solara は、判断する道具ではなく、\n'
            '理解するための道具でありたい。',
      ],
    ),
  ];

  // ── English version (draft, owner to refine) ──

  static const List<SolaraManifestoSection> sectionsEN = [
    SolaraManifestoSection(
      title: '☯ The Worldview Solara Believes In',
      paragraphs: [
        'This world is composed of two faces.',
        'Soft and Hard are not opposite ends of a single axis.\n'
            'They are independent energies, each existing on its own.',
        'Not good or bad, but different in nature.\n'
            'Both simply «are».',
      ],
    ),
    SolaraManifestoSection(
      title: 'Two Energies',
      paragraphs: [
        '☯ Soft Energy\n'
            'The power of flow. Tolerance, expansion, receptivity, stability.\n'
            'Things move smoothly, encounters arise, hearts open.',
      '☐ Hard Energy\n'
            'The power of friction and change. Challenge, transformation, '
            'confrontation, growth.\n'
            'Through tension, things become visible — '
            'deep learning, and encounters with yourself, occur.',
        'Both are beautiful, each in their own way.\n'
            'And sometimes, both are strongly active at the same time.\n'
            'In those moments, you are inside a profound experience.',
      ],
    ),
    SolaraManifestoSection(
      title: 'From Solara, to You',
      paragraphs: [
        'Solara will not tell you "which is the right answer."',
        'When, where, and how much each energy exists.\n'
            'That, we tell you as fact.',
        'From there, the territory is yours.\n'
            'Riding the flow of Soft,\n'
            'facing the friction of Hard,\n'
            'experiencing both at once —\n'
            'all of it is your choice.',
        'Sometimes you cannot choose your direction.\n'
            'There are places you must go.\n'
            'There are events that come to you.\n'
            'Even then, Solara does not judge.\n'
            'We tell you what energies are present,\n'
            'and offer you material to read and engage with on your own.',
        'Solara aspires to be a tool for understanding,\n'
            'not a tool for judgment.',
      ],
    ),
  ];

  /// 端末の言語設定に基づいて JP / EN を選択
  static bool _isJapanese(String locale) => locale.startsWith('ja');

  static List<SolaraManifestoSection> getSections(String locale) =>
      _isJapanese(locale) ? sectionsJP : sectionsEN;
}
