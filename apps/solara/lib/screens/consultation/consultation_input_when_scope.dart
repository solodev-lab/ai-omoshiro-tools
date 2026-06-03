// Consultation Input — ③ いつ / 半径 セレクタ
// (part of 'consultation_input_screen.dart')

part of 'consultation_input_screen.dart';

class _WhenChoice {
  final String key;
  final String label;
  const _WhenChoice(this.key, this.label);
}

List<_WhenChoice> get _whenChoicesDaily => [
      _WhenChoice('today', t.consultInput.when.today),
      _WhenChoice('date', t.consultInput.when.date),
    ];

List<_WhenChoice> get _whenChoicesTravel => [
      _WhenChoice('date', t.consultInput.when.specificDay),
      _WhenChoice('range', t.consultInput.when.range),
    ];

List<_WhenChoice> get _whenChoicesMigration => [
      _WhenChoice('undecided', t.consultInput.when.undecided),
      _WhenChoice('date', t.consultInput.when.date),
      _WhenChoice('within6mo', t.consultInput.when.within6mo),
      _WhenChoice('within1yr', t.consultInput.when.within1yr),
      _WhenChoice('in3yr', t.consultInput.when.in3yr),
      _WhenChoice('in5yrPlus', t.consultInput.when.in5yrPlus),
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
List<_WhenChoice> get _timeBandChoices => [
      _WhenChoice('morning', t.consultInput.timeBand.morning),
      _WhenChoice('midday', t.consultInput.timeBand.midday),
      _WhenChoice('evening', t.consultInput.timeBand.evening),
      _WhenChoice('night', t.consultInput.timeBand.night),
      _WhenChoice('lateNight', t.consultInput.timeBand.lateNight),
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

/// 時刻 (0〜23) → 現地太陽時バケット。worker consultation_engine.timeOfDayBucket と一致。
String bandFromHour(int h) {
  final hh = ((h % 24) + 24) % 24;
  if (hh >= 5 && hh < 10) return 'morning';
  if (hh >= 10 && hh < 15) return 'midday';
  if (hh >= 15 && hh < 19) return 'evening';
  if (hh >= 19 && hh < 23) return 'night';
  return 'lateNight';
}

/// Pro 時刻ドラム (1 時間刻み)。0〜23 時のホイールを bottom sheet で出し、決定で hour を返す。
Future<int?> showConsultationHourPicker(BuildContext context, int initialHour) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: const Color(0xEE0C0C1A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _HourDrumSheet(initialHour: initialHour),
  );
}

class _HourDrumSheet extends StatefulWidget {
  final int initialHour;
  const _HourDrumSheet({required this.initialHour});
  @override
  State<_HourDrumSheet> createState() => _HourDrumSheetState();
}

class _HourDrumSheetState extends State<_HourDrumSheet> {
  late int _hour = widget.initialHour.clamp(0, 23);
  late final FixedExtentScrollController _ctrl =
      FixedExtentScrollController(initialItem: _hour);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.consultInput.hourPicker.title,
                style: const TextStyle(
                    color: SolaraColors.solaraGoldLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4)),
            const SizedBox(height: 4),
            Text(t.consultInput.hourPicker.sub,
                style: const TextStyle(
                    color: SolaraColors.textSecondary, fontSize: 11)),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: ListWheelScrollView.useDelegate(
                controller: _ctrl,
                itemExtent: 40,
                perspective: 0.004,
                diameterRatio: 1.4,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (i) => setState(() => _hour = i),
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 24,
                  builder: (ctx, i) {
                    final active = i == _hour;
                    return Center(
                      child: Text(
                        '${i.toString().padLeft(2, '0')}:00',
                        style: TextStyle(
                          color: active
                              ? SolaraColors.solaraGoldLight
                              : SolaraColors.textSecondary,
                          fontSize: active ? 22 : 18,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_hour),
                style: FilledButton.styleFrom(
                  backgroundColor: SolaraColors.solaraGoldLight,
                  foregroundColor: SolaraColors.celestialBlueDark,
                ),
                child: Text(t.consultInput.hourPicker
                    .confirm(time: '${_hour.toString().padLeft(2, '0')}:00')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pro 時刻指定の行。未選択=「時刻を指定（1時間刻み）」/ 選択中=「15:00 を指定中」+×。
/// Free はロック表示でタップすると Pro 案内 ([onLockedTap])。
class _TimeHourRow extends StatelessWidget {
  final bool isPro;
  final int? hour;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final VoidCallback onLockedTap;
  const _TimeHourRow({
    required this.isPro,
    required this.hour,
    required this.onPick,
    required this.onClear,
    required this.onLockedTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = hour != null;
    return GestureDetector(
      onTap: isPro ? onPick : onLockedTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? const Color(0x22F6BD60) : const Color(0x11FFFFFF),
          border: Border.all(
            color: selected
                ? const Color(0xAAF6BD60)
                : (isPro ? const Color(0x44F6BD60) : const Color(0x33FFFFFF)),
          ),
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.schedule : Icons.more_time,
                size: 16,
                color: isPro
                    ? SolaraColors.solaraGoldLight
                    : const Color(0x77F6BD60)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selected
                    ? t.consultInput.timeRowSelected(
                        time: '${hour.toString().padLeft(2, '0')}:00')
                    : t.consultInput.hourPicker.title,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFFF9D976)
                      : SolaraColors.textPrimary,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isPro)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child:
                    Icon(Icons.lock_outline, size: 13, color: Color(0x99F9D976)),
              )
            else if (selected)
              GestureDetector(
                onTap: onClear,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child:
                      Icon(Icons.close, size: 15, color: Color(0x99ACACAC)),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0x33F9D976),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Pro',
                    style: TextStyle(
                        color: Color(0xFFF9D976),
                        fontSize: 9,
                        fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
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
    return min > 0
        ? t.consultInput.radiusBand(min: min, max: km)
        : t.consultInput.radiusSingle(km: km);
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
