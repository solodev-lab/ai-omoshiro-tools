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

// ── 相談例 (テーマ × モード × スコープで 3 つ提示) ──────────────
//
// オーナー指摘 (2026-05-16):
//   1. 旧版は theme+mode のみで scope を見ておらず、scope='世界全体' でも
//      'daily+bearings' でも同じ例文が出ていた。意味的にズレる。
//   2. 特に「おでかけ × 方角ベース」は「場所を決め打ちで行く」ではなく
//      「どの方角に動こうか」という日常の悩み。例文をその文脈に統一する。
//
// データ構造: theme → mode → scope → 3 例文
//   非 daily mode: scope は specific / region / world
//   daily mode:    scope は specific / bearings / region (world は無い)
//   合計 6 × 3 × 3 = 54 例文
//
// テキスト方針 (project_solara_message_tone + design philosophy):
// - 「したい」「ほしい」など 1 人称の願望文 (吉凶/良し悪し言及なし)
// - 状況描写 + 願望の 2 ブロック (40〜100 字、200 字制限内で具体性確保)
// - scope 別の粒度:
//   - specific: 具体的な地名/施設名がすでに頭にある (「京都に移住検討中」)
//   - region:   範囲は決まっているが場所はまだ ('日本/関西/関東のどこか')
//   - world:    地球規模、海外も視野
//   - bearings: 行き先を決め打たず「方角」を相談 (おでかけ専用)

const Map<String, Map<String, Map<String, List<String>>>> _consultExamples = {
  'love': {
    'migration': {
      'specific': [
        '結婚を機に夫婦で京都への移住を検討中。この街で家庭をつくっていけるか相性を見たい。',
        '彼の地元、福岡への移住を考えている。私もそこで根を張れるか不安があり、後押しになる視点がほしい。',
        '実家近くに戻ろうか迷っている。親との距離と自分の家族の時間、両立できる土地か知りたい。',
      ],
      'region': [
        '結婚して 5 年、夫婦で次の暮らし方を相談中。日本のどこかで穏やかに暮らせる土地を探したい。',
        '子どもが小学校に上がる前に家族で引っ越し予定。関東圏のどこかで子育てしやすい街を選びたい。',
        '親元を離れて自分の家族をつくるタイミング。関西で新しいスタートを切れる街を探している。',
      ],
      'world': [
        'パートナーと海外移住を視野に入れている。お互いが心地よく暮らせる国を選びたい。',
        '国際結婚で相手の国に住むかこちらに住むか議論中。二人の関係が育つ環境を見極めたい。',
        '子どもをグローバルに育てたい。家族で長く暮らせる海外の街を探している。',
      ],
    },
    'travel': {
      'specific': [
        '最近恋人とすれ違いが続いている。来月の沖縄旅行で関係を見つめ直したい。',
        '離れて暮らす両親に会いに広島へ行く予定。心が少し近づく時間にしたい。',
        '彼との 10 周年記念で温泉旅館を予約済み。二人の節目になる旅にしたい。',
      ],
      'region': [
        '最近恋人とすれ違いが続いている。週末に関西方面のどこかへ二人の時間を取りに行きたい。',
        '結婚記念日に九州を巡る旅を計画中。穏やかに過ごせる場所を選びたい。',
        'ずっと片想いをしている人がいる。気持ちを整理するために東北のどこかへ一人旅したい。',
      ],
      'world': [
        '結婚 10 周年に海外旅行を計画中。長く一緒にいられる関係性を確認できる旅にしたい。',
        '別れた相手の影をまだ引きずっている。誰も知らない海外で気持ちを切り替えたい。',
        'パートナーと初めての海外、お互いの相性をもう一段深く知る旅にしたい。',
      ],
    },
    'daily': {
      'specific': [
        '気になる人とランチで初めて二人で会う約束。表参道の予約済カフェで自然体に話せるか知りたい。',
        '夫婦喧嘩から数日、今日近所の公園で話し合おうと思っている。和解につながる場か見たい。',
        '友達の結婚式に出る日。会場で過去の自分の恋愛と向き合えるか、心の準備をしたい。',
      ],
      'bearings': [
        '同僚との関係がギクシャクして気持ちが沈んでいる。今日どの方角に動いたら自然体に戻れるか知りたい。',
        '最近誰とも深く話していない気がする。今日はどの方角に出かければ心が開ける時間が持てるか相談したい。',
        '気になる人と週末に会う予定。今日のうちに自分を整えるなら、どの方角がいいか教えてほしい。',
      ],
      'region': [
        '最近誰とも深く話していない気がする。今日は都内のどこかで心を開けそうな場所に出かけたい。',
        '夫と最近会話が事務的。今日は都内のどこかで二人で過ごす時間を取り直したい。',
        '友達からの誘いを断り続けていた。今日は近隣のどこかで思い切って誰かに会いたい。',
      ],
    },
  },
  'money': {
    'migration': {
      'specific': [
        'フリーランス 3 年目、福岡への移住を検討中。家賃と仕事の機会のバランスを見たい。',
        '事業拡大を機に大阪へ拠点を移すか考えている。事業が育つ土地か知りたい。',
        '実家のある地方都市に戻って起業しようか迷っている。経済的に成り立つか客観的に見たい。',
      ],
      'region': [
        '貯金が思うように増えない。日本のどこかで生活コストが落ち着く土地に移りたい。',
        '副業で始めた事業が軌道に乗ってきた。関東圏のどこかで本格化させたい。',
        'リモートワーカーとして関西方面に移住したい。生活費を下げて投資に回したい。',
      ],
      'world': [
        '海外居住で資産形成を考えている。物価と収入のバランスが取れる国を選びたい。',
        '日本の税制から離れる選択肢として海外移住を検討中。長く暮らせる国を探している。',
        'ノマドワーカーとして数年単位の海外拠点を作りたい。お金の流れが整う場所を選びたい。',
      ],
    },
    'travel': {
      'specific': [
        '半年仕事を頑張ったご褒美に箱根温泉を予約済み。お金の流れを整える区切りにしたい。',
        'ボーナスを使ってシンガポール出張兼旅行を計画中。投資先として相性を見たい。',
        '貯めたマイルで初めての一人旅、京都行きを決めた。自分への投資になる旅か知りたい。',
      ],
      'region': [
        '半年仕事を頑張ったご褒美旅行。東日本のどこかで自分を労いたい。',
        '副業を立ち上げた節目に九州を一周したい。新しいお金の流れを呼び込む旅にしたい。',
        'ボーナスをどう使うか迷っている。北海道のどこかで自分への投資になる場所を選びたい。',
      ],
      'world': [
        '資産運用の勉強を始めたばかり。海外で視野を広げて自分のお金観を整え直したい。',
        '次の海外旅行で投資先の現地を見たい。実体験で判断できる国を選びたい。',
        '退職金を使ってじっくり旅をする予定。お金との付き合い方を考え直す国を選びたい。',
      ],
    },
    'daily': {
      'specific': [
        '今日は大きな投資判断をする日。新宿の馴染みのカフェで決めたいが、その選択でいいか知りたい。',
        '高額な買い物を今日するか迷っている。新宿の家電量販店に行く予定、判断のための後押しがほしい。',
        '副業のクライアントと初の対面ミーティング。指定された渋谷のオフィスで自分を発揮できるか知りたい。',
      ],
      'bearings': [
        '最近お金の使い方が荒れている気がする。今日はどの方角に動いたら判断力が戻るか知りたい。',
        '今日大きな買い物の決断をする予定。判断力が冴える方角で午前を過ごしたい。',
        '副業の収益化について集中して考える日。今日どの方角に出かけるのが頭が回るか教えてほしい。',
      ],
      'region': [
        '副業の収益化を考える作業日。都内のどこかで集中できる場所に出かけたい。',
        '最近の浪費グセを断ち切りたい。今日は近郊のどこかで気持ちを引き締められる場所がほしい。',
        '今日はマネー系のセミナーが何件かある。都内のどこに行くのが自分の流れに合うか知りたい。',
      ],
    },
  },
  'work': {
    'migration': {
      'specific': [
        'リモートワーカーとして札幌移住を検討中。仕事の質が上がる土地か相性を見たい。',
        '転職先が決まり、転勤で名古屋への引っ越しが確定。その地で自分のキャリアが育つか知りたい。',
        '独立を機に拠点を福岡へ移す計画。事業として根を張れる土地か見極めたい。',
      ],
      'region': [
        '転職を機に住む場所も変えたい。日本のどこかで次のキャリアを伸ばせる環境を探している。',
        'リモートワークが定着し、東京にいる必要が無くなった。地方のどこかで仕事の質が上がる土地を選びたい。',
        '会社員を辞めて独立予定。関西のどこかで新しい働き方を始めたい。',
      ],
      'world': [
        '会社員を辞めて独立する予定。海外で新しい働き方を始められる国を探している。',
        '英語環境でキャリアを積み直したい。グローバルに通用する仕事ができる国に移りたい。',
        'リモート前提のキャリア。海外居住で時差を活かした働き方ができる国を選びたい。',
      ],
    },
    'travel': {
      'specific': [
        '次の出張先、シンガポールでのプロジェクトキックオフ。新しい挑戦のヒントが得られるか知りたい。',
        '転職活動の合間に京都で 3 日間のリトリート予定。頭を切り替えて方向性を考えたい。',
        '資格試験前のリフレッシュで沖縄旅行を予約済み。試験後の集中力につながるか見たい。',
      ],
      'region': [
        'プロジェクトが一段落。九州のどこかで頭を切り替えるリトリート旅をしたい。',
        'ずっと迷っている転職について、北海道のどこかで一人時間を取って考えたい。',
        '資格試験前のリフレッシュ旅。東北のどこかで集中力をリセットしたい。',
      ],
      'world': [
        'キャリアの転機を控えている。次の海外旅行で視野を広げて方向性を考えたい。',
        '海外勤務のオファーを受けるか迷っている。下見を兼ねた旅でその地と相性を見たい。',
        '退職後のギャップ期間、海外で次の働き方のヒントを探す旅にしたい。',
      ],
    },
    'daily': {
      'specific': [
        '大事なプレゼンが午後にある。会社近くのスタバで準備するつもりだが、集中力が上がるか確認したい。',
        '転職面接が今日午後、渋谷のオフィスで。自分らしく振る舞える場面になるか知りたい。',
        '上司との 1on1 がある。会議室での話し合いがキャリアの転機につながるか見ておきたい。',
      ],
      'bearings': [
        '在宅勤務続きで頭が固くなっている。今日はどの方角に出かけたら新しいアイデアが浮かぶか知りたい。',
        '大事なプレゼンが午後にある。集中力と落ち着きが上がる方角で午前を過ごしたい。',
        '仕事の流れが詰まっている。今日どの方角に外出すれば頭がほぐれるか教えてほしい。',
      ],
      'region': [
        '仕事の流れが詰まっている感じがする。都内のどこかで気分を変えられる場所に出かけたい。',
        '在宅勤務続きでアイデアが枯渇。近郊のどこかで思考が動く場所を探している。',
        '新規プロジェクトの構想を練る日。近隣のどこかで集中して書ける場所がほしい。',
      ],
    },
  },
  'communication': {
    'migration': {
      'specific': [
        '英語環境で子育てしたく、シンガポール移住を検討中。家族で言葉と文化を深められるか知りたい。',
        '同郷の人が多い福岡に移住したい。話せる相手が増えそうか、土地との相性を見たい。',
        '学び直しのために京都の大学院近くに住む計画。学びの環境として相性が合うか知りたい。',
      ],
      'region': [
        '同世代と話す機会が減って孤独を感じる。日本のどこかでコミュニティが活発な土地に移りたい。',
        '子育てを通じて自分も学び直したい。関東圏のどこかで教育環境が整った街に移りたい。',
        '人付き合いをやり直したい。新しい人間関係を作れる場所を探している。',
      ],
      'world': [
        '30 代で本気で語学を身につけたい。日常的に英語と接する国に住みたい。',
        '海外でしか得られない出会いに飛び込みたい。多言語が交わる都市に住みたい。',
        '異文化のなかで自分の表現を磨きたい。芸術や思想の交流が活発な国に移りたい。',
      ],
    },
    'travel': {
      'specific': [
        '次の旅行で初めてポルトガル語圏のリスボンに行く予定。言葉の壁を恐れず飛び込みたい。',
        '英語学校の短期留学でメルボルンへ行く。実践の場として自分が伸びる旅になるか知りたい。',
        '友人と京都で 3 日間のワークショップに参加予定。自分の表現が広がる時間になるか見たい。',
      ],
      'region': [
        '人と話すのが苦手だが、東北のどこかで自分から声をかける練習をしたい。',
        '読書ばかりしていた数ヶ月、関西のどこかで人と会って学ぶ機会を取り戻したい。',
        '家族との会話を取り戻したい。九州のどこかで一緒に過ごす旅を計画したい。',
      ],
      'world': [
        'ずっと興味があった国の文化に触れる旅にしたい。言葉の壁も恐れず飛び込みたい。',
        '海外で人と話すのが苦手。初めての一人海外旅行で自分の殻を破りたい。',
        '読書だけでは届かない学びを求めて、研究者やアーティストの集まる国を訪ねたい。',
      ],
    },
    'daily': {
      'specific': [
        '気になる勉強会が今日渋谷である。新しい人と話す場面で自然体で居られるか知りたい。',
        '苦手な親戚と表参道で会う予定。話が穏やかに進む時間になるか見たい。',
        '面接で問われた英語を実地で試したく、今日恵比寿の英会話カフェに行く予定。',
      ],
      'bearings': [
        '友達からの誘いを断り続けていた。今日はどの方角に動いたら、思い切って誰かに会えそうか知りたい。',
        '気になる勉強会の候補が複数。今日どの方角の会場に行くのが自分の流れに合うか教えてほしい。',
        '家族との会話が事務的になっている。今日どの方角に出かけたらゆっくり話せそうか相談したい。',
      ],
      'region': [
        '家族との会話が事務的になっている。今日は都内のどこかでゆっくり話せる場所を選びたい。',
        '友達からの誘いを断り続けていた。今日は近隣のどこかで思い切って誰かに会いたい。',
        '人見知りを直したい。都内の交流イベント候補が複数あるが、自分に合う場所を選びたい。',
      ],
    },
  },
  'healing': {
    'migration': {
      'specific': [
        '都会の人混みに疲れた。鎌倉への移住を検討中で、自分の心と相性が合うか見たい。',
        '介護のため実家のある長野に戻る予定。家族を支えつつ自分も整えられる土地か知りたい。',
        '療養のため海辺の街、葉山への引っ越しを考えている。心が深く休めるか相性を見たい。',
      ],
      'region': [
        'コロナ以降ずっと張り詰めていた。日本のどこかで腰を据えて休める土地に移りたい。',
        '都会の人混みと音に疲れた。自然と静けさのある土地で暮らし直したい。',
        '燃え尽き気味で休職中。次の暮らしは静かに自分を取り戻せる場所にしたい。',
      ],
      'world': [
        'バーンアウト寸前。物価が安く時間の流れがゆっくりな国で長期療養したい。',
        '日本の働き方が合わなくなった。海外でゆっくり生きられるライフスタイルを始めたい。',
        '人生をリセットしたい。誰も自分を知らない国で 1 から始めたい。',
      ],
    },
    'travel': {
      'specific': [
        '3 ヶ月のプロジェクトをようやく終えた。次の連休に箱根温泉で深く休む予定、相性を見たい。',
        '家族の介護で疲れている。来週京都で一人 3 日間を取る、心が緩む時間になるか知りたい。',
        '失恋から半年、まだ立ち直れない。週末に予約した熱海の温泉宿が転機になるか見たい。',
      ],
      'region': [
        '家族の介護で気持ちが沈んでいる。九州のどこかで一人で何もしない時間を作りたい。',
        '3 ヶ月のプロジェクトをようやく終えた。東北のどこかで深く休める旅をしたい。',
        '燃え尽き寸前で短い休みが取れた。北陸のどこかで静けさに浸りたい。',
      ],
      'world': [
        '失恋から半年、まだ立ち直れない。海外で誰も自分を知らない場所に身を置きたい。',
        'バーンアウト中で長めの休暇が取れた。物価が安くゆっくり過ごせる国でリセットしたい。',
        '介護を終えて自分の時間が戻ってきた。海外でゆったりと自分を取り戻す旅にしたい。',
      ],
    },
    'daily': {
      'specific': [
        '友人関係で精神的に疲れている。今日は表参道の馴染みの公園で静かに過ごす予定、合っているか見たい。',
        '連日の課題提出で寝不足。今日午後に近所の銭湯に行こうと思っている、心と体がほぐれるか知りたい。',
        '親との関係がストレスで、今日は新宿御苑に行く予定。気持ちが落ち着く場所になるか見たい。',
      ],
      'bearings': [
        '連日課題の提出に追われて寝不足。今日はどの方角に向かったら心と体が休まる時間が作れるか知りたい。',
        '友人関係で精神的に疲れている。今日はどの方角に出かけたら静かに過ごせるか相談したい。',
        '親との関係でストレスがたまっている。今日はどの方角に動いたら自分を労れるか教えてほしい。',
      ],
      'region': [
        '親との関係でストレスがたまっている。今日だけは都内のどこかで自分を労れる場所に出かけたい。',
        '友人関係で精神的に疲れている。今日は都内のどこかで誰にも会わず静かに過ごしたい。',
        '連日課題の提出に追われている。近郊のどこかで心と体を休める場所を探している。',
      ],
    },
  },
  'newStart': {
    'migration': {
      'specific': [
        '10 年勤めた会社を辞めて沖縄移住を考えている。新しい働き方が始められる土地か見たい。',
        '離婚を機に住む場所も変える予定。実家のある名古屋で新しい自分を始められるか知りたい。',
        '子育てが一区切り、第二の人生を京都で始めたい。リスタートに合う土地か相性を見たい。',
      ],
      'region': [
        '離婚を機に住む場所も変える予定。日本のどこかで新しい自分を始められる場所を探している。',
        '親の介護が一区切り。九州のどこかでこれから自分の人生をやり直したい。',
        '会社員生活を終えてフリーランスへ。関西のどこかで新しい働き方を始める拠点を選びたい。',
      ],
      'world': [
        '退職金を元手にギャップイヤー。海外移住も視野に、これから 10 年の人生を描き直したい。',
        '人生を一度リセットしたい。海外で誰も自分を知らない場所から始めたい。',
        '日本で続けてきた何もかもに行き詰まった。海外で新しいライフスタイルを始めたい。',
      ],
    },
    'travel': {
      'specific': [
        '30 歳を迎える節目に台湾一周旅を計画中。これまでの自分を見送る旅にしたい。',
        '退職直後、京都の禅寺で 1 週間過ごす予定。次の自分と出会える時間になるか知りたい。',
        '長く付き合った相手と別れた直後。来月沖縄で予約した一人旅が転機になるか見たい。',
      ],
      'region': [
        '長く付き合った相手と別れた直後。北海道のどこかで気持ちを切り替えたい。',
        '30 歳を迎える節目の旅。東北のどこかでこれまでの自分を見送りたい。',
        '退職して気持ちを整理したい。九州のどこかでリセットできる旅にしたい。',
      ],
      'world': [
        '退職してギャップイヤー旅行を計画。これからの 10 年を描き直すための旅にしたい。',
        '30 歳の節目に初めての海外一人旅。次の自分と出会う旅にしたい。',
        '長く一緒だった相手と別れた直後。海外で新しい風景に身を置いて切り替えたい。',
      ],
    },
    'daily': {
      'specific': [
        'ずっと続けていた習慣をやめると決めた日。代官山のいつもと違うカフェで仕切り直したい。',
        '気持ちが落ち込んでいた数日間。今日は表参道の本屋で気分を切り替えたい。',
        '面接の後、新しい自分を試す気持ちで渋谷に出る予定。流れに乗れるか確認したい。',
      ],
      'bearings': [
        '気持ちが落ち込んでいた数日間。今日こそ違う方角に動いて自分を切り替えたい。',
        'ずっと続けていた習慣をやめると決めた日。今日からどの方角に動くと違うリズムが作れるか知りたい。',
        '何かを変えたいが何を変えればいいか分からない。今日まずどの方角に動くべきか相談したい。',
      ],
      'region': [
        '面接の後、新しい自分を試す気持ちで都内のどこかに出かけたい。',
        '長年の習慣を変えたい。今日は近郊のどこかで普段行かない場所に動きたい。',
        '気持ちが落ち込んでいた数日間。近隣のどこかで一歩外に出て切り替えたい。',
      ],
    },
  },
};

class _ConsultExamples extends StatelessWidget {
  final String? theme;
  final String mode;
  final String scope;
  final ValueChanged<String> onPick;

  const _ConsultExamples({
    required this.theme,
    required this.mode,
    required this.scope,
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
    // scope 別に例文を引く。データ欠落時はモード default (中点) にフォールバック。
    final byMode = _consultExamples[t]?[mode];
    final list = byMode?[scope] ??
        byMode?['region'] ??
        byMode?.values.firstOrNull ??
        const <String>[];
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
