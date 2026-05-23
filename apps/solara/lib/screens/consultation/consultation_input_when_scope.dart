// Consultation Input — ③ いつ / 半径 セレクタ
// (part of 'consultation_input_screen.dart')

part of 'consultation_input_screen.dart';

class _WhenChoice {
  final String key;
  final String label;
  const _WhenChoice(this.key, this.label);
}

const _whenChoicesDaily = <_WhenChoice>[
  _WhenChoice('today', '今日'),
  _WhenChoice('date', '日付指定'),
];

const _whenChoicesTravel = <_WhenChoice>[
  _WhenChoice('date', '特定の日'),
  _WhenChoice('range', '期間'),
];

const _whenChoicesMigration = <_WhenChoice>[
  _WhenChoice('undecided', '時期未定'),
  _WhenChoice('date', '日付指定'),
  _WhenChoice('within6mo', '半年以内'),
  _WhenChoice('within1yr', '1年以内'),
  _WhenChoice('in3yr', '3年後くらい'),
  _WhenChoice('in5yrPlus', '5年以上先'),
];

List<_WhenChoice> _whenChoicesFor(String mode) {
  switch (mode) {
    case 'daily':
      return _whenChoicesDaily;
    case 'travel':
      return _whenChoicesTravel;
    default:
      return _whenChoicesMigration;
  }
}

/// ③ いつ。場面別の選択肢を Wrap で出し、date/range は選んだ日付を下に表示する。
class _WhenSelector extends StatelessWidget {
  final String mode;
  final String? selectedKind;
  final String? dateLabel;
  final ValueChanged<String> onTapKind;
  const _WhenSelector({
    required this.mode,
    required this.selectedKind,
    required this.dateLabel,
    required this.onTapKind,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _whenChoicesFor(mode)
              .map((c) => _PillChip(
                    label: c.label,
                    active: selectedKind == c.key,
                    onTap: () => onTapKind(c.key),
                  ))
              .toList(growable: false),
        ),
        if (dateLabel != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.event,
                  size: 14, color: SolaraColors.solaraGoldLight),
              const SizedBox(width: 6),
              Text(
                dateLabel!,
                style: const TextStyle(
                  color: SolaraColors.solaraGoldLight,
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// 自宅から半径の距離選択 (場面別 km 候補)。
class _RadiusChips extends StatelessWidget {
  final List<int> options;
  final double selected;
  final ValueChanged<double> onSelect;
  const _RadiusChips({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map((km) => _PillChip(
                label: '${km}km',
                active: selected.round() == km,
                onTap: () => onSelect(km.toDouble()),
              ))
          .toList(growable: false),
    );
  }
}
