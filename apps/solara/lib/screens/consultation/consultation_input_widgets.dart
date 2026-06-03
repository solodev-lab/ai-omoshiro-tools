// Consultation Input — 基本サブウィジェット + 選択肢定数
// (part of 'consultation_input_screen.dart')

part of 'consultation_input_screen.dart';

// ── 選択肢定数 ───────────────────────────────────────────

// ラベルはロケール連動 (t.*) のため getter。id は不変 (Worker mode/scope key)。
List<_ThemeChoice> get _themeChoices => [
      _ThemeChoice('love', t.consultInput.theme.love),
      _ThemeChoice('money', t.consultInput.theme.money),
      _ThemeChoice('work', t.consultInput.theme.work),
      _ThemeChoice('communication', t.consultInput.theme.communication),
      _ThemeChoice('healing', t.consultInput.theme.healing),
      _ThemeChoice('newStart', t.consultInput.theme.newStart),
    ];

// 2026-05-29: 'daily' のラベルを 2 行表記に変更。
//   おでかけ = 自分がその場所に指定時刻に行く
//   イベント = 自分が動かずにその場所で始まる事も含む
// 例えば「自宅での出来事」を相談したい時、「おでかけ」だけでは設定しにくいので
// 「イベント」を併記して概念を広げる。Worker 側 mode key は 'daily' のまま不変。
List<_ModeChoice> get _modeChoices => [
      _ModeChoice('daily', t.consultInput.mode.daily),
      _ModeChoice('travel', t.consultInput.mode.travel),
      _ModeChoice('migration', t.consultInput.mode.migration),
    ];

// scope 選択肢は場面別:
//   - daily:           具体地点 / 方角 / 現住所から半径
//   - travel/migration: 具体地点 / 地域 / 自国内 / 現住所から半径 / 世界全体
List<_ScopeChoice> get _scopeChoicesDaily => [
      _ScopeChoice('point', t.consultInput.scope.point),
      _ScopeChoice('bearing', t.consultInput.scope.bearing),
      _ScopeChoice('radius', t.consultInput.scope.radius),
    ];

List<_ScopeChoice> get _scopeChoicesWide => [
      _ScopeChoice('point', t.consultInput.scope.point),
      _ScopeChoice('region', t.consultInput.scope.region),
      _ScopeChoice('country', t.consultInput.scope.country),
      _ScopeChoice('radius', t.consultInput.scope.radius),
      _ScopeChoice('world', t.consultInput.scope.world),
    ];

List<_ScopeChoice> _scopeChoicesFor(String mode) =>
    mode == 'daily' ? _scopeChoicesDaily : _scopeChoicesWide;

// 大ブロック region picker。値は worldCityRegionGroups の照合キー (日本語) の
// ため不変。表示名のみ _regionLabel でロケール連動 (en は英語地域名)。
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

/// region picker の表示名 (id=日本語の照合キーは保持、表示のみ localize)。
String _regionLabel(String jpId) {
  if (!isEnLocale()) return jpId;
  const en = {
    '日本': 'Japan',
    '北米': 'North America',
    'ヨーロッパ': 'Europe',
    'アジア': 'Asia',
    '中東': 'Middle East',
    'アフリカ': 'Africa',
    '中南米': 'Latin America',
    'オセアニア': 'Oceania',
  };
  return en[jpId] ?? jpId;
}

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
                label: _regionLabel(g),
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
          t.consultInput.noHomeNote,
          style: const TextStyle(
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
              t.consultInput.presetCard(
                  name:
                      '${target.nameJP}${target.region.isNotEmpty ? " (${target.region})" : ""}'),
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
          child: Text(t.consultInput.submit),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        t.consultInput.introNote,
        style: const TextStyle(
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
    final a = t.consultInput.about;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(a.title, style: head),
        const SizedBox(height: 8),
        Text(a.intro, style: body),
        const SizedBox(height: 8),
        Text(a.bullets, style: bullet),
        const SizedBox(height: 18),
        Text(a.dataTitle, style: head),
        const SizedBox(height: 8),
        Text(a.dataIntro, style: body),
        const SizedBox(height: 10),
        Text(a.freeHead, style: sub),
        const SizedBox(height: 4),
        Text(a.freeList, style: bullet),
        const SizedBox(height: 10),
        Text(a.proHead, style: sub),
        const SizedBox(height: 4),
        Text(a.proList, style: bullet),
        const SizedBox(height: 18),
        Text(a.devHead, style: sub),
        const SizedBox(height: 4),
        Text(a.devBody, style: body),
      ],
    );
  }
}
