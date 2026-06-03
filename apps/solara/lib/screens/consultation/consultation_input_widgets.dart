// Consultation Input — 基本サブウィジェット + 選択肢定数
// (part of 'consultation_input_screen.dart')

part of 'consultation_input_screen.dart';

// ── 選択肢定数 ───────────────────────────────────────────

const _themeChoices = <_ThemeChoice>[
  _ThemeChoice('love', '恋愛・関係'),
  _ThemeChoice('money', '豊かさ・お金'),
  _ThemeChoice('work', '仕事・キャリア'),
  _ThemeChoice('communication', '対話・学び'),
  _ThemeChoice('healing', '癒し・休息'),
  _ThemeChoice('newStart', '変化・新たな出発'),
];

// 2026-05-29: 'daily' のラベルを 2 行表記に変更。
//   おでかけ = 自分がその場所に指定時刻に行く
//   イベント = 自分が動かずにその場所で始まる事も含む
// 例えば「自宅での出来事」を相談したい時、「おでかけ」だけでは設定しにくいので
// 「イベント」を併記して概念を広げる。Worker 側 mode key は 'daily' のまま不変。
const _modeChoices = <_ModeChoice>[
  _ModeChoice('daily', 'おでかけ\nイベント'),
  _ModeChoice('travel', '旅行'),
  _ModeChoice('migration', '移住'),
];

// scope 選択肢は場面別:
//   - daily:           具体地点 / 方角 / 現住所から半径
//   - travel/migration: 具体地点 / 地域 / 自国内 / 現住所から半径 / 世界全体
const _scopeChoicesDaily = <_ScopeChoice>[
  _ScopeChoice('point', '具体地点'),
  _ScopeChoice('bearing', '方角'),
  _ScopeChoice('radius', '現住所から半径'),
];

const _scopeChoicesWide = <_ScopeChoice>[
  _ScopeChoice('point', '具体地点'),
  _ScopeChoice('region', '地域'),
  _ScopeChoice('country', '自国内'),
  _ScopeChoice('radius', '現住所から半径'),
  _ScopeChoice('world', '世界全体'),
];

List<_ScopeChoice> _scopeChoicesFor(String mode) =>
    mode == 'daily' ? _scopeChoicesDaily : _scopeChoicesWide;

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
  const _ThemeChoice(this.id, this.label);
}

class _ModeChoice {
  final String id;
  final String label;
  const _ModeChoice(this.id, this.label);
}

class _ScopeChoice {
  final String id;
  final String label;
  const _ScopeChoice(this.id, this.label);
}

// ── 汎用チップ ──────────────────────────────────────────

/// 単一選択の pill チップ (Wrap 用)。
class _PillChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _PillChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0x33F6BD60) : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? SolaraColors.solaraGold : SolaraColors.glassBorder,
          ),
        ),
        child: Text(
          label,
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
  }
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
      children: _themeChoices
          .map((t) => _PillChip(
                label: t.label,
                active: selected == t.id,
                onTap: () => onSelect(t.id),
              ))
          .toList(growable: false),
    );
  }
}

class _ModeRow extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  const _ModeRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
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
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                decoration: BoxDecoration(
                  color:
                      active ? const Color(0x33F6BD60) : const Color(0x10FFFFFF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: active
                        ? SolaraColors.solaraGold
                        : SolaraColors.glassBorder,
                  ),
                ),
                child: Center(
                  child: Text(
                    m.label,
                    // 2026-05-29: 'daily' が 2 行ラベル (おでかけ\nイベント) に
                    // なったため textAlign center + height 1.25 で中央寄せ統一。
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: active
                          ? SolaraColors.solaraGoldLight
                          : SolaraColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

/// ④ どこで のスコープ選択 (Wrap、場面で 3〜5 個)。
class _ScopeWrap extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  final List<_ScopeChoice> choices;
  const _ScopeWrap({
    required this.selected,
    required this.onSelect,
    required this.choices,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: choices
          .map((s) => _PillChip(
                label: s.label,
                active: selected == s.id,
                onTap: () => onSelect(s.id),
              ))
          .toList(growable: false),
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
      children: _regionPickerGroups
          .map((g) => _PillChip(
                label: g,
                active: selected == g,
                onTap: () => onSelect(g),
              ))
          .toList(growable: false),
    );
  }
}

class _FreeTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final int maxLength;
  const _FreeTextField({
    required this.controller,
    this.hint,
    this.maxLines = 3,
    this.maxLength = 200,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      style: const TextStyle(
        color: SolaraColors.textPrimary,
        fontSize: 13,
        height: 1.6,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: SolaraColors.textSecondary,
          fontSize: 12,
        ),
        filled: true,
        fillColor: const Color(0x10FFFFFF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        // 入力欄の枠は記入例チップ (0x14FFFFFF) より明るくして区別する。
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0x40FFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0x40FFFFFF)),
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

/// 自宅未設定で 方角/半径/自国内 が使えないときの注記。
class _NoHomeNote extends StatelessWidget {
  const _NoHomeNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x14D6915C),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x44D6915C)),
        ),
        child: Text(
          '現住所が未設定です。「方角・現住所から半径・自国内」は現住所を設定すると使えます。「具体地点」は今すぐ使えます。',
          style: TextStyle(
            color: SolaraColors.energyHardLight,
            fontSize: 11.5,
            height: 1.5,
          ),
        ),
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

// ── タイトル下の簡単説明 + i ボタンの詳細ポップアップ (2026-05-31) ──────────
// この機能が「何に使えるか」を一目で伝える。簡単版は常時表示、詳細版は
// AppBar の i ボタンから showInfoPopup で開く (データ量で凄さを伝える)。

/// タイトル直下に常時表示する短い説明 (グレー小文字)。
class _ConsultIntroNote extends StatelessWidget {
  const _ConsultIntroNote();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Text(
        'いつ・どこで・何をするか を選ぶと、その時その場所で“どんなエネルギーが働くか”を、'
        '膨大な占星術データから Stella が分かりやすく読み解きます。',
        style: TextStyle(
          color: SolaraColors.textSecondary,
          fontSize: 12,
          height: 1.6,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// i ボタンの詳細ポップアップ (導入 → 読み解くデータ → 開発者より)。
Future<void> showConsultAboutPopup(BuildContext context) {
  return showInfoPopup(context: context, child: const _ConsultAboutContent());
}

class _ConsultAboutContent extends StatelessWidget {
  const _ConsultAboutContent();

  @override
  Widget build(BuildContext context) {
    const head = TextStyle(
        color: SolaraColors.solaraGoldLight,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6);
    const sub = TextStyle(
        color: SolaraColors.solaraGoldLight,
        fontSize: 12,
        fontWeight: FontWeight.w600);
    const body =
        TextStyle(color: SolaraColors.textPrimary, fontSize: 13, height: 1.7);
    const bullet =
        TextStyle(color: SolaraColors.textPrimary, fontSize: 12.5, height: 1.7);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Stella 相談とは', style: head),
        SizedBox(height: 8),
        Text(
          '「いつ・どこで・何をするか」を選ぶだけ。その予定に、地球規模の星の地図を重ね、'
          'その時・その場所であなたに働くエネルギーを読み解く——Solara の中核機能です。\n'
          '本来は占星術師が長い時間をかけて読み解く膨大な天体計算を Stella が瞬時に行い、'
          '専門用語ではなく、あなたに寄り添う言葉でお渡しします。',
          style: body,
        ),
        SizedBox(height: 8),
        Text(
          '・「どこで・何をすると、どんな作用が得られるか」を、あなたの願いに照らして描きます。\n'
          '・吉凶やランキングはしません。「良い/悪い」ではなく“どんな質の流れか'
          '（後押しになる質か、向き合う質か）”として伝えます。\n'
          '・おでかけ・旅行・移住——スケールに合わせて。Cosmic Pro なら時刻を1時間刻みで'
          '指定でき、「30分後にその場の流れがどう動くか」まで読めます。',
          style: bullet,
        ),
        SizedBox(height: 18),
        Text('Stella 相談が読み解くデータ', style: head),
        SizedBox(height: 8),
        Text(
          'Solara の星のライン計算は 10天体 × 4アングル(ASC・MC・DSC・IC) × '
          '3アスペクト(合・スクエア・トライン／セクスタイル)＝1フレーム120本。'
          'これを複数フレーム重ね、緯度帯・12ハウス・進行図まで計算します。',
          style: body,
        ),
        SizedBox(height: 10),
        Text('― おでかけ・イベント（Free）でも、ここまで ―', style: sub),
        SizedBox(height: 4),
        Text(
          '・出生図（ネイタル）の 10 天体／今日の経過天体（トランジット）の 10 天体\n'
          '・アストロカートグラフィ（Astro*Carto*Graphy／出生のライン）\n'
          '・サイクロカートグラフィ（Cyclo*Carto*Graphy／今この瞬間の動くライン）\n'
          '・合・スクエア・トライン・セクスタイルの全アスペクトライン'
          '（テーマ天体 × 4アングル × 3アスペクト）\n'
          '・天頂帯・天底帯（緯度のエネルギー帯）\n'
          '・その土地のリロケーション（ASC／MC／12ハウスの組み替え＋テーマ天体の在室）\n'
          '・内的季節（進行の月・太陽、ソーラーアークの節目）／'
          '現地の時間帯（天体が角を通過する時刻）\n'
          '…これを世界中の候補地点に重ね、あなたの願いに響く場所・方角を Stella が描きます。',
          style: bullet,
        ),
        SizedBox(height: 10),
        Text('― Cosmic Pro なら、さらに ―', style: sub),
        SizedBox(height: 4),
        Text(
          '・移住スケール＝生涯不変のネイタル ACG ＋ 進行（プログレス）の人生の章\n'
          '・旅行スケール＝旅行日ごとの動くライン（期間を複数日サンプリング）\n'
          '・時刻を1時間刻みで指定 → 30分後に線がどう動くかまで',
          style: bullet,
        ),
        SizedBox(height: 18),
        Text('― Solara 開発者より ―', style: sub),
        SizedBox(height: 4),
        Text(
          'このきめ細かさは、占星術を実践してきた私自身が、設計から開発まで直接'
          '手がけているからこそ実現できました。「ここをこう汲んでほしい」と誰かに'
          '頼むのではなく、占星術師がそのまま形にする——だから、細部のひとつひとつに'
          '星の意味を宿せています。あなたの毎日のそばに、この星の地図が寄り添えますように。',
          style: body,
        ),
      ],
    );
  }
}
