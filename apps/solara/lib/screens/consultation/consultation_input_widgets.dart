// Consultation Input Screen — 基本サブウィジェット + 選択肢定数
// (part of 'consultation_input_screen.dart')
//
// Stage 1 入力画面の基本ウィジェット (テーマ/モード/スコープ選択 + 自由記述 +
// 自動補完カード + 送信ボタン) と、テーマ/モード/スコープ定数。
// 巨大化した相談例 (_consultExamples) と地点ピッカー (_SpecificPicker) は
// 別 part ファイルに分割した。
//
//   consultation_input_screen.dart        ← orchestration + state
//   consultation_input_widgets.dart       ← 本ファイル: 基本ウィジェット
//   consultation_input_examples.dart      ← 例文 (theme×mode×scope=54)
//   consultation_input_picker.dart        ← _PickedSpecific + _SpecificPicker
//
// (Solara は horoscope_screen.dart と同じ part-of パターンを採用)

part of 'consultation_input_screen.dart';

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
