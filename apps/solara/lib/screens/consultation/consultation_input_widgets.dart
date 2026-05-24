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

const _modeChoices = <_ModeChoice>[
  _ModeChoice('daily', 'おでかけ'),
  _ModeChoice('travel', '旅行'),
  _ModeChoice('migration', '移住'),
];

// scope 選択肢は場面別:
//   - daily:           具体地点 / 方角 / 自宅から半径
//   - travel/migration: 具体地点 / 地域 / 自国内 / 自宅から半径 / 世界全体
const _scopeChoicesDaily = <_ScopeChoice>[
  _ScopeChoice('point', '具体地点'),
  _ScopeChoice('bearing', '方角'),
  _ScopeChoice('radius', '自宅から半径'),
];

const _scopeChoicesWide = <_ScopeChoice>[
  _ScopeChoice('point', '具体地点'),
  _ScopeChoice('region', '地域'),
  _ScopeChoice('country', '自国内'),
  _ScopeChoice('radius', '自宅から半径'),
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
                    style: TextStyle(
                      color: active
                          ? SolaraColors.solaraGoldLight
                          : SolaraColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
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
          '自宅の場所が未設定です。「方角・自宅から半径・自国内」は自宅を設定すると使えます。',
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
