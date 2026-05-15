// Consultation Input Screen — Stage 1 サブウィジェット + 選択肢定数部
// (part of '../consultation_input_screen.dart')
//
// Stage 1 入力画面の内部ウィジェット + テーマ/モード/スコープ定数を分離。
// consultation_input_screen.dart は orchestration + state、本ファイルは
// presentation + 定数を担当。
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

const _scopeChoices = <_ScopeChoice>[
  _ScopeChoice('specific', '具体地点', '特定の場所を 1 つ吟味'),
  _ScopeChoice('region', '範囲指定', '地域ブロックから 3 候補'),
  _ScopeChoice('world', '世界全体', '地球規模で 3 候補'),
];

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
    return Row(
      children: _modeChoices.map((m) {
        final active = selected == m.id;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(m.id),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
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
              child: Column(
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
                    style: TextStyle(
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
    );
  }
}

class _ScopeRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  final bool hasPreset;
  final bool hasCurrent;
  const _ScopeRow({
    required this.selected,
    required this.onSelect,
    required this.hasPreset,
    required this.hasCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _scopeChoices.map((s) {
        final active = selected == s.id;
        final disabled =
            s.id == 'specific' && !hasPreset && !hasCurrent;
        return Expanded(
          child: GestureDetector(
            onTap: disabled ? null : () => onSelect(s.id),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: disabled
                    ? const Color(0x08FFFFFF)
                    : active
                        ? const Color(0x33F6BD60)
                        : const Color(0x10FFFFFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active && !disabled
                      ? SolaraColors.solaraGold
                      : SolaraColors.glassBorder,
                ),
              ),
              child: Opacity(
                opacity: disabled ? 0.4 : 1,
                child: Column(
                  children: [
                    Text(
                      s.label,
                      style: TextStyle(
                        color: active && !disabled
                            ? SolaraColors.solaraGoldLight
                            : SolaraColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.hint,
                      style: TextStyle(
                        color: SolaraColors.textSecondary,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(growable: false),
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
  final String hint;
  const _FreeTextField({required this.controller, required this.hint});

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
        hintText: '例: $hint',
        hintStyle: TextStyle(
          color: SolaraColors.textSecondary.withValues(alpha: 0.6),
          fontSize: 12,
        ),
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
