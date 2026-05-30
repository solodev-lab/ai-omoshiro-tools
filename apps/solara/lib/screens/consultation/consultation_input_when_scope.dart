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

/// 時間帯チップ (おでかけのみ・任意)。キーは Worker BUCKET_JP と一致させる。
/// もう一度タップで解除 (= 未指定)。
const _timeBandChoices = <_WhenChoice>[
  _WhenChoice('morning', '朝'),
  _WhenChoice('midday', '昼'),
  _WhenChoice('evening', '夕方'),
  _WhenChoice('night', '夜'),
  _WhenChoice('lateNight', '夜更け'),
];

class _TimeBandSelector extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onTap; // 同じものを再タップで解除する判定は親側
  const _TimeBandSelector({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _timeBandChoices
          .map((c) => _PillChip(
                label: c.label,
                active: selected == c.key,
                onTap: () => onTap(c.key),
              ))
          .toList(growable: false),
    );
  }
}

/// 自宅から半径の距離選択 (場面別 km 候補)。
/// [bandMinFor] を渡すと「下限〜上限km」のバンド表示 (旅行/移住)。返り値 0 か
/// null のままなら従来の「Nkm」表示 (おでかけ=「以内」)。
class _RadiusChips extends StatelessWidget {
  final List<int> options;
  final double selected;
  final ValueChanged<double> onSelect;
  final int Function(int maxKm)? bandMinFor;
  const _RadiusChips({
    required this.options,
    required this.selected,
    required this.onSelect,
    this.bandMinFor,
  });

  String _label(int km) {
    final min = bandMinFor?.call(km) ?? 0;
    return min > 0 ? '$min〜${km}km' : '${km}km';
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map((km) => _PillChip(
                label: _label(km),
                active: selected.round() == km,
                onTap: () => onSelect(km.toDouble()),
              ))
          .toList(growable: false),
    );
  }
}
