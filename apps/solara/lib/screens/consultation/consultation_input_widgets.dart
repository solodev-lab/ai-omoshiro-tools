// Consultation Input Screen — Stage 1 サブウィジェット + 選択肢定数部
// (part of '../consultation_input_screen.dart')
//
// Stage 1 入力画面の内部ウィジェット + テーマ/モード/スコープ定数を分離。
// consultation_input_screen.dart は orchestration + state、本ファイルは
// presentation + 定数を担当。
// (Solara は horoscope_screen.dart と同じ part-of パターンを採用)

part of 'consultation_input_screen.dart';

/// _SpecificPicker からの選択結果を持ち回す軽量レコード。
class _PickedSpecific {
  final LatLng position;
  final String name;
  final String region;
  final String country;
  const _PickedSpecific({
    required this.position,
    required this.name,
    this.region = '',
    this.country = '',
  });
}

// ── 選択肢定数 ───────────────────────────────────────────

// テーマ定義 (id, 表示名, ヒント例文)
const _themeChoices = <_ThemeChoice>[
  _ThemeChoice('love', '恋愛・関係', '近くにいる人とのつながりを深めたい'),
  _ThemeChoice('money', '豊かさ・お金', '生活基盤を整えたい・流れを変えたい'),
  _ThemeChoice('work', '仕事・キャリア', '次のキャリアの方向を探している'),
  _ThemeChoice('communication', '対話・学び', '言葉を磨きたい・新しいことを学びたい'),
  _ThemeChoice('healing', '癒し・休息', '一度立ち止まって自分を整えたい'),
  _ThemeChoice('newStart', '変化・新たな出発', '心機一転、別のステージに進みたい'),
];

const _modeChoices = <_ModeChoice>[
  _ModeChoice('migration', '移住', '大陸・国・年単位の場所選び'),
  _ModeChoice('travel', '旅行', '地域・都市・期間ありの滞在'),
  _ModeChoice('daily', 'おでかけ', '今日の現在地周辺・方角ベース'),
];

// scope 選択肢はモード別に異なる:
//   - migration / travel: specific / region / world (世界全体まで含める)
//   - daily (おでかけ):    specific / bearings / region (世界全体は対象外)
// daily だけ bearings (現在地からの方角別) が選べる代わりに world が外れる。
const _scopeChoicesNonDaily = <_ScopeChoice>[
  _ScopeChoice('specific', '具体地点', '特定の場所を 1 つ吟味'),
  _ScopeChoice('region', '範囲指定', '地域ブロックから 3 候補'),
  _ScopeChoice('world', '世界全体', '地球規模で 3 候補'),
];

const _scopeChoicesDaily = <_ScopeChoice>[
  _ScopeChoice('specific', '具体地点', '行きたい場所を 1 つ'),
  _ScopeChoice('bearings', '方角ベース', '現在地から方角別 3 候補'),
  _ScopeChoice('region', '範囲指定', '地域ブロックから 3 候補'),
];

List<_ScopeChoice> _scopeChoicesFor(String mode) =>
    mode == 'daily' ? _scopeChoicesDaily : _scopeChoicesNonDaily;

// 大ブロック region picker (worldCityRegionGroups の値で識別)
const _regionPickerGroups = <String>[
  '日本',
  '北米',
  'ヨーロッパ',
  'アジア',
  '中東',
  'アフリカ',
  '中南米',
  'オセアニア',
];

class _ThemeChoice {
  final String id;
  final String label;
  final String hint;
  const _ThemeChoice(this.id, this.label, this.hint);
}

class _ModeChoice {
  final String id;
  final String label;
  final String hint;
  const _ModeChoice(this.id, this.label, this.hint);
}

class _ScopeChoice {
  final String id;
  final String label;
  final String hint;
  const _ScopeChoice(this.id, this.label, this.hint);
}

// ── サブウィジェット ───────────────────────────────────────

class _Section extends StatelessWidget {
  final String label;
  final Widget child;
  const _Section({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: SolaraColors.textSecondary,
              fontSize: 12,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ThemeGrid extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  const _ThemeGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _themeChoices.map((t) {
        final active = selected == t.id;
        return GestureDetector(
          onTap: () => onSelect(t.id),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: active ? const Color(0x33F6BD60) : const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active
                    ? SolaraColors.solaraGold
                    : SolaraColors.glassBorder,
              ),
            ),
            child: Text(
              t.label,
              style: TextStyle(
                color: active
                    ? SolaraColors.solaraGoldLight
                    : SolaraColors.textPrimary,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _ModeRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _ModeRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight + Column.mainAxisSize.max でタイル高さを最高にそろえる。
    // hint の文字数差で「おでかけだけ低い / 移住だけ高い」等の凸凹を防ぐ。
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _modeChoices.map((m) {
          final active = selected == m.id;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(m.id),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0x33F6BD60)
                      : const Color(0x10FFFFFF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: active
                        ? SolaraColors.solaraGold
                        : SolaraColors.glassBorder,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      m.label,
                      style: TextStyle(
                        color: active
                            ? SolaraColors.solaraGoldLight
                            : SolaraColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.hint,
                      style: const TextStyle(
                        color: SolaraColors.textSecondary,
                        fontSize: 10,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _ScopeRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  /// モード別の scope 選択肢。caller が `_scopeChoicesFor(mode)` で渡す。
  final List<_ScopeChoice> choices;
  const _ScopeRow({
    required this.selected,
    required this.onSelect,
    required this.choices,
  });

  @override
  Widget build(BuildContext context) {
    // Phase: specific スコープも常時選択可。preset が無くても inline picker で
    // 地点選択できるようになったので「disabled」状態は廃止。
    //
    // IntrinsicHeight + Column.mainAxisSize.max でタイル高さを最高にそろえる。
    // hint テキスト長の差で発生する縦方向の凸凹を防ぐ。
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: choices.map((s) {
          final active = selected == s.id;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(s.id),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0x33F6BD60)
                      : const Color(0x10FFFFFF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: active
                        ? SolaraColors.solaraGold
                        : SolaraColors.glassBorder,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      s.label,
                      style: TextStyle(
                        color: active
                            ? SolaraColors.solaraGoldLight
                            : SolaraColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.hint,
                      style: const TextStyle(
                        color: SolaraColors.textSecondary,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _RegionPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _RegionPicker({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _regionPickerGroups.map((g) {
        final active = selected == g;
        return GestureDetector(
          onTap: () => onSelect(g),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: active ? const Color(0x33F6BD60) : const Color(0x12FFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active
                    ? SolaraColors.solaraGold
                    : SolaraColors.glassBorder,
              ),
            ),
            child: Text(
              g,
              style: TextStyle(
                color: active
                    ? SolaraColors.solaraGoldLight
                    : SolaraColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _FreeTextField extends StatelessWidget {
  final TextEditingController controller;
  const _FreeTextField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      maxLength: 200,
      style: const TextStyle(
        color: SolaraColors.textPrimary,
        fontSize: 13,
        height: 1.6,
      ),
      decoration: InputDecoration(
        // hintText は出さない (オーナー指示 2026-05-16)。
        // 例文は _ConsultExamples セクションで自由記述の下に独立表示する。
        filled: true,
        fillColor: const Color(0x10FFFFFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: SolaraColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: SolaraColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: SolaraColors.solaraGold),
        ),
        counterStyle: TextStyle(
          color: SolaraColors.textSecondary.withValues(alpha: 0.6),
          fontSize: 10,
        ),
      ),
    );
  }
}

// ── 相談例 (テーマ × モードで 3 つ提示) ─────────────────────────
//
// オーナー指摘 (2026-05-16): 旧版は「今日は心を癒す方角に動きたい」のように
// 既選択 (テーマ + モード) を言い換えるだけで自由記述の存在意義が薄かった。
// 自由記述 200 字をきちんと使い切るような「本人の具体的な状況 + 願望」に
// 全 18 組書き換え。Stella にコンテキストが伝わるレベルを目指す。
//
// テキスト方針 (project_solara_message_tone + design philosophy):
// - 「したい」「ほしい」など 1 人称の願望文 (吉凶/良し悪し言及なし)
// - 状況描写 + その状況からの願い、の 2 ブロック構成 (40〜80 字目安)
// - 関係呼称 (友人/夫婦/同僚/家族 等) を入れて具体性を持たせる
// - モード別に粒度を変える (移住=年単位 / 旅行=期間 / おでかけ=今日)
// - 18 通り全てを Solara 世界観に合わせる (Stella 文体ではなくユーザー声)

const Map<String, Map<String, List<String>>> _consultExamples = {
  'love': {
    'migration': [
      '結婚して 5 年、夫婦で次の暮らし方を相談中。今後 10 年を一緒に過ごせる場所を選びたい。',
      '子どもが小学校に上がる前に、家族で穏やかに暮らせる土地に引っ越したい。学校選びも兼ねて。',
      '親元を離れて自分の家族をつくるタイミング。新しいスタートを切れる街を探している。',
    ],
    'travel': [
      '最近恋人とすれ違いが続いている。二人の時間を作り直したくて、久しぶりに旅行を計画中。',
      '離れて暮らす家族に会いに行く予定。お互いの心が少しずつ近づく時間にしたい。',
      'ずっと片想いをしている人がいる。気持ちを整理するための一人旅を考えている。',
    ],
    'daily': [
      '同僚との関係がギクシャクして気持ちが沈んでいる。今日はどこで切り替えたら自然体に戻れるか知りたい。',
      '気になる人と週末に会う予定。今日のうちに自分を整える時間を取りたい。',
      '最近誰とも深く話していない気がする。今日は心を開けそうな場所に出かけたい。',
    ],
  },
  'money': {
    'migration': [
      'フリーランス 3 年目、収入が安定してきたので生活拠点を見直したい。家賃と暮らしの質のバランスを取りたい。',
      '副業で始めた事業が軌道に乗ってきた。本格化させるのに合う土地を選びたい。',
      '貯金が思うように増えない。生活リズムごと変えたくて、環境を変える選択肢を考えている。',
    ],
    'travel': [
      '半年仕事を頑張ってきたご褒美旅行。次の半年に向けてお金の流れを整え直したい。',
      '資産運用の勉強を始めたばかり。一度立ち止まって自分のお金観を考え直す旅にしたい。',
      'ボーナスをどう使うか迷っている。自分への投資につながる旅先を選びたい。',
    ],
    'daily': [
      '今日は大きな買い物の決断をする日。判断力が冴える方角で午前を過ごしたい。',
      '最近お金の使い方が荒れている気がする。今日はリセットの一日にしたい。',
      '副業の収益化について考える作業日。集中できそうな場所に出かけたい。',
    ],
  },
  'work': {
    'migration': [
      'リモートワークが定着して、もう東京にいる必要が無くなった。仕事の質が上がる土地を選びたい。',
      '転職を機に住む場所も変えたい。次のキャリアを伸ばせる環境を探している。',
      '会社員を辞めて独立する予定。新しい働き方に合う場所を選びたい。',
    ],
    'travel': [
      'プロジェクトが一段落した。次の方向性を考えるために視野を広げる旅をしたい。',
      'ずっと迷っている転職について、頭を切り替える時間がほしい。',
      '資格試験前のリフレッシュ旅。試験までの集中力をリセットしたい。',
    ],
    'daily': [
      '大事なプレゼンが午後にある。集中力と落ち着きが上がる方角で午前を過ごしたい。',
      '仕事の流れが詰まっている感じがする。一旦外に出て頭をほぐしたい。',
      '在宅勤務続きで頭が固くなっている。新しいアイデアが浮かびそうな場所に行きたい。',
    ],
  },
  'communication': {
    'migration': [
      '子育てを通じて自分も学び直したい気持ちが強くなった。教育環境が整った街に移りたい。',
      '英語を本気で身につけたい。日常的に英語と接する街に住むことを考えている。',
      '同世代と話す機会が減って孤独を感じている。コミュニティが活発な土地を探している。',
    ],
    'travel': [
      'ずっと興味があった国の文化に触れる旅にしたい。言葉の壁も恐れず飛び込みたい。',
      '人と話すのが苦手だが、旅先で自分から声をかける練習をしてみたい。',
      '読書ばかりしていた数ヶ月、実際に人と会って学ぶ機会を取り戻したい。',
    ],
    'daily': [
      '気になる勉強会が今日ある。新しい人と話す場面で緊張しがちなので、自然体で居られる時間がほしい。',
      '家族との会話が事務的になっている。今日はゆっくり話せる雰囲気を作りたい。',
      '友達からの誘いを断り続けていた。今日は思い切って誰かと会う方に動きたい。',
    ],
  },
  'healing': {
    'migration': [
      '都会の人混みと音に疲れた。自然と静けさのある土地で暮らし直したい。',
      '介護で実家に戻る予定。家族を支えながら自分の心も大切にできる場所を探している。',
      'コロナ以降ずっと張り詰めていた。腰を据えて休める土地に移りたい。',
    ],
    'travel': [
      '3 ヶ月のプロジェクトをようやく終えた。今度の連休は心と体を深く休める旅にしたい。',
      '家族の介護で気持ちが沈んでいる。一人で何もしない時間を作る旅に行きたい。',
      '失恋から半年、まだ立ち直れない自分を労る旅にしたい。',
    ],
    'daily': [
      '友人関係で精神的に疲れている。今日は誰にも会わず、静かに自分の時間を過ごしたい。',
      '連日課題の提出に追われて寝不足が続いている。心と体を休める数時間を確保したい。',
      '親との関係でストレスがたまっている。今日だけは自分を労れる場所に出かけたい。',
    ],
  },
  'newStart': {
    'migration': [
      '10 年勤めた会社を辞めて別の働き方を始めたい。土地ごと変えてリセットしたい。',
      '離婚を機に住む場所も変える予定。新しい自分を始められる場所を探している。',
      '親の介護が一区切り。これから自分の人生をやり直すための土地を選びたい。',
    ],
    'travel': [
      '30 歳を迎える区切りの旅。これまでの自分を見送り、次の自分と出会いたい。',
      '長く付き合った相手と別れた直後。新しい風景に身を置いて気持ちを切り替えたい。',
      '卒業旅行で人生の節目を作りたい。学生時代を綺麗に閉じたい。',
    ],
    'daily': [
      'ずっと続けていた習慣をやめると決めた日。今日から違うルートで動いてみたい。',
      '気持ちが落ち込んでいた数日間。今日こそ一歩外に出て、自分を切り替えたい。',
      '面接の後、新しい自分を試す気持ちで街に出たい。',
    ],
  },
};

class _ConsultExamples extends StatelessWidget {
  final String? theme;
  final String mode;
  final ValueChanged<String> onPick;

  const _ConsultExamples({
    required this.theme,
    required this.mode,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    if (t == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Text(
          'テーマを選ぶと、こんな相談ができる例が出てきます',
          style: TextStyle(
            color: SolaraColors.textSecondary,
            fontSize: 11,
            height: 1.5,
          ),
        ),
      );
    }
    final list = _consultExamples[t]?[mode] ?? const <String>[];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < list.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          _ExampleRow(text: list[i], onTap: () => onPick(list[i])),
        ],
      ],
    );
  }
}

class _ExampleRow extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _ExampleRow({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // オーナー指摘 (2026-05-16) の長文化に合わせ、行を複数行折返し前提に変更:
    // - crossAxisAlignment: start (icon が上端、テキストが下に伸びるレイアウト)
    // - leading icon を少し上にオフセット (テキスト 1 行目の中心と視覚的に揃える)
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0x0CFFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SolaraColors.glassBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.auto_awesome,
                  size: 14, color: SolaraColors.solaraGoldLight),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: SolaraColors.textPrimary,
                  fontSize: 12,
                  height: 1.6,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(Icons.arrow_forward,
                  size: 12, color: SolaraColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// inline 地点ピッカー (A)。検索 + LOCATION quick-pick + 「地図で選ぶ」(B) を集約。
///
/// presetTarget が null の specific スコープ専用。プリセットがあるときは
/// _PresetLocationCard で「✓ 京都 を見ます」を表示するだけで本 picker は出さない。
class _SpecificPicker extends StatefulWidget {
  final _PickedSpecific? selected;
  final ValueChanged<_PickedSpecific> onSelect;
  final VoidCallback onClear;
  final Future<_PickedSpecific?> Function() onOpenMapPicker;

  /// 検索時の bias center (Google Places の locationBias 15km、Nominatim には影響なし)。
  /// 現在地 or プリセットの座標を渡すと、曖昧クエリ ('スターバックス' 等) が
  /// その周辺に寄る。null なら従来の bias 無し検索。
  final LatLng? biasCenter;

  const _SpecificPicker({
    required this.selected,
    required this.onSelect,
    required this.onClear,
    required this.onOpenMapPicker,
    this.biasCenter,
  });

  @override
  State<_SpecificPicker> createState() => _SpecificPickerState();
}

class _SpecificPickerState extends State<_SpecificPicker> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _searching = false;
  List<map_search.SearchHit> _hits = const [];

  bool _loadingSlots = true;
  List<VPSlot> _locationSlots = const [];

  final SlotManager _locMgr =
      SlotManager(storageKey: 'solara_locations');

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    final slots = await _locMgr.load();
    if (!mounted) return;
    setState(() {
      _locationSlots = slots;
      _loadingSlots = false;
    });
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    final q = v.trim();
    if (q.length < 2) {
      setState(() {
        _hits = const [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _runSearch(q));
  }

  Future<void> _runSearch(String q) async {
    setState(() => _searching = true);
    // biasCenter があれば Google Places 経由で周辺優先 (Nominatim 経由は無視される)。
    // Daily Transit 起点で具体地点を選ぶときは「現在地周辺」のクエリが多いため、
    // 現在地を bias に使うことで「スタバ」「コンビニ」のような曖昧語が地理的に絞れる。
    final hits =
        await map_search.searchPlaces(q, biasCenter: widget.biasCenter);
    if (!mounted) return;
    setState(() {
      _hits = hits;
      _searching = false;
    });
  }

  void _onHitTap(map_search.SearchHit h) {
    final parts = h.name.split(',').map((s) => s.trim()).toList();
    final short = parts.isNotEmpty ? parts.first : h.name;
    // hit.country は Worker レスポンスでは ISO code (大文字小文字混在の可能性)。
    // CandidateLocation.country は大文字慣習なので合わせる。
    final cc = h.country?.toUpperCase() ?? '';
    widget.onSelect(_PickedSpecific(
      position: LatLng(h.lat, h.lng),
      name: short,
      country: cc,
    ));
    _searchCtrl.clear();
    setState(() => _hits = const []);
  }

  void _onSlotTap(VPSlot s) {
    widget.onSelect(_PickedSpecific(
      position: LatLng(s.lat, s.lng),
      name: s.name,
    ));
  }

  Future<void> _openMapPicker() async {
    final picked = await widget.onOpenMapPicker();
    if (picked != null) {
      widget.onSelect(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 選択中表示 (あれば最上段に出す)
        if (selected != null) ...[
          _SelectedSpecificCard(picked: selected, onClear: widget.onClear),
          const SizedBox(height: 12),
        ],

        // 検索フィールド
        Container(
          decoration: BoxDecoration(
            color: const Color(0x10FFFFFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: SolaraColors.glassBorder),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              const Icon(Icons.search,
                  size: 18, color: SolaraColors.solaraGold),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(
                    color: SolaraColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                    hintText: '住所 / 店名で検索',
                    hintStyle: TextStyle(
                      color: SolaraColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              if (_searching)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: SolaraColors.solaraGold,
                    ),
                  ),
                ),
              if (_searchCtrl.text.isNotEmpty && !_searching) ...[
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 14, color: SolaraColors.textSecondary),
                  onPressed: () {
                    _searchCtrl.clear();
                    _onSearchChanged('');
                  },
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  tooltip: 'クリア',
                ),
              ],
            ],
          ),
        ),

        // 検索結果 (最大 5 件、scroll なし)
        if (_hits.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: const Color(0x10FFFFFF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SolaraColors.glassBorder),
            ),
            child: Column(
              children: [
                for (int i = 0; i < _hits.length && i < 5; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, color: Color(0x11FFFFFF)),
                  _SearchHitRow(
                    index: i + 1,
                    hit: _hits[i],
                    onTap: () => _onHitTap(_hits[i]),
                  ),
                ],
              ],
            ),
          ),
        ],

        // LOCATION 保存地点 (chips)
        if (_loadingSlots == false && _locationSlots.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text(
            '📍 保存地点から',
            style: TextStyle(
              color: SolaraColors.textSecondary,
              fontSize: 11,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < _locationSlots.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  _LocationChip(
                    slot: _locationSlots[i],
                    onTap: () => _onSlotTap(_locationSlots[i]),
                  ),
                ],
              ],
            ),
          ),
        ],

        // 「地図で選ぶ」 (B picker へ push)
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: _openMapPicker,
          icon: const Icon(Icons.map_outlined,
              size: 18, color: SolaraColors.solaraGoldLight),
          label: const Text(
            '地図で選ぶ',
            style: TextStyle(
              color: SolaraColors.solaraGoldLight,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: const BorderSide(color: Color(0x66F6BD60)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchHitRow extends StatelessWidget {
  final int index;
  final map_search.SearchHit hit;
  final VoidCallback onTap;
  const _SearchHitRow(
      {required this.index, required this.hit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // 場所名 + 住所行を組み立てる。
    // Google Places 経路: hit.name = 短い場所名 (例 'Tokyo Tower')、hit.address に formattedAddress
    // Nominatim 経路: hit.name = 'A, B, C, D, ...' の display_name、hit.address は null
    final String short;
    final String sub;
    if (hit.address != null && hit.address!.isNotEmpty) {
      short = hit.name;
      sub = hit.address!;
    } else {
      final parts = hit.name.split(',').map((s) => s.trim()).toList();
      short = parts.isNotEmpty ? parts.first : hit.name;
      sub = parts.length > 1 ? parts.skip(1).join(', ') : '';
    }
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: SolaraColors.solaraGold,
              ),
              alignment: Alignment.center,
              child: Text(
                '$index',
                style: const TextStyle(
                  fontSize: 12,
                  color: SolaraColors.celestialBlueDark,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    short,
                    style: const TextStyle(
                      color: SolaraColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: const TextStyle(
                        color: SolaraColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  final VPSlot slot;
  final VoidCallback onTap;
  const _LocationChip({required this.slot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x10FFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SolaraColors.glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(slot.icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              slot.name,
              style: const TextStyle(
                color: SolaraColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedSpecificCard extends StatelessWidget {
  final _PickedSpecific picked;
  final VoidCallback onClear;
  const _SelectedSpecificCard({required this.picked, required this.onClear});

  String? _addressLine() {
    final parts = <String>[
      if (picked.region.isNotEmpty) picked.region,
      if (picked.country.isNotEmpty) picked.country,
    ];
    return parts.isEmpty ? null : parts.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: const Color(0x14F6BD60),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x66F6BD60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              size: 18, color: SolaraColors.solaraGold),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    picked.name,
                    style: const TextStyle(
                      color: SolaraColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_addressLine() != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '(${_addressLine()})',
                      style: const TextStyle(
                        color: SolaraColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close,
                size: 14, color: SolaraColors.textSecondary),
            onPressed: onClear,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: '選択を解除',
          ),
        ],
      ),
    );
  }
}

class _PresetLocationCard extends StatelessWidget {
  final ConsultationPresetTarget target;
  const _PresetLocationCard({required this.target});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x14F6BD60),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x44F6BD60)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            color: SolaraColors.solaraGold,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${target.nameJP}${target.region.isNotEmpty ? " (${target.region})" : ""} を見ます',
              style: const TextStyle(
                color: SolaraColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  final bool enabled;
  final Future<void> Function() onSubmit;
  const _SubmitBar({required this.enabled, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: SolaraColors.glassBorder, width: 1),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: enabled ? () => onSubmit() : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: SolaraColors.solaraGold,
            foregroundColor: SolaraColors.celestialBlueDark,
            disabledBackgroundColor: SolaraColors.glassBorder,
            disabledForegroundColor: SolaraColors.textSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          child: const Text('相談を始める'),
        ),
      ),
    );
  }
}
