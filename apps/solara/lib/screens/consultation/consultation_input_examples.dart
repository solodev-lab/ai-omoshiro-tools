// Consultation Input — だれと / 願い の記入例
// (part of 'consultation_input_screen.dart')
//
// 自由記述 (⑤ だれと / ⑥ 願い) はタップで埋まる記入例を添えて誘導する。
// 願いは場面 (おでかけ/旅行/移住) で軽重を変える。

part of 'consultation_input_screen.dart';

const _whomExamples = <String>[
  'ひとりで',
  'パートナーと',
  '気になる人と',
  '友人と',
  '家族と',
  '同僚と',
];

const _wishExamplesDaily = <String>[
  '気分転換したい',
  'いい出会いがありそうな所へ',
  '集中できる場所がほしい',
];

const _wishExamplesTravel = <String>[
  '心が解放される旅にしたい',
  '関係を深めたい',
  '新しい刺激がほしい',
];

const _wishExamplesMigration = <String>[
  '腰を据えて暮らしたい',
  '仕事の基盤を築きたい',
  '穏やかに根を張りたい',
];

const _wishExamplesDefault = <String>[
  '今より一歩進みたい',
  '流れを変えたい',
];

List<String> _wishExamplesFor(String? mode) {
  switch (mode) {
    case 'daily':
      return _wishExamplesDaily;
    case 'travel':
      return _wishExamplesTravel;
    case 'migration':
      return _wishExamplesMigration;
    default:
      return _wishExamplesDefault;
  }
}

/// タップで自由記述を埋める記入例チップ群。
class _ExampleChips extends StatelessWidget {
  final List<String> examples;
  final ValueChanged<String> onPick;
  const _ExampleChips({required this.examples, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: examples
            .map((e) => GestureDetector(
                  onTap: () => onPick(e),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0x0DFFFFFF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: SolaraColors.glassBorder),
                    ),
                    child: Text(
                      e,
                      style: const TextStyle(
                        color: SolaraColors.textSecondary,
                        fontSize: 11.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ))
            .toList(growable: false),
      ),
    );
  }
}

class _WhomExamples extends StatelessWidget {
  final ValueChanged<String> onPick;
  const _WhomExamples({required this.onPick});

  @override
  Widget build(BuildContext context) =>
      _ExampleChips(examples: _whomExamples, onPick: onPick);
}

class _WishExamples extends StatelessWidget {
  final String? mode;
  final ValueChanged<String> onPick;
  const _WishExamples({required this.mode, required this.onPick});

  @override
  Widget build(BuildContext context) =>
      _ExampleChips(examples: _wishExamplesFor(mode), onPick: onPick);
}
