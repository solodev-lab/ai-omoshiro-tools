// Consultation Input — だれと / 願い の記入例 (テーマ別)
// (part of 'consultation_input_screen.dart')
//
// 自由記述 (⑤ だれと / ⑥ 願い) はタップで埋まる記入例を添えて誘導する。
// 候補は選択中のテーマ (恋愛/豊かさ/仕事/対話/癒し/変化) に沿ったものだけを出す。

part of 'consultation_input_screen.dart';

// ── だれと (テーマ別) ──
const _whomByTheme = <String, List<String>>{
  'love': ['ひとりで', 'パートナーと', '気になる人と'],
  'money': ['ひとりで', '家族と', 'パートナーと'],
  'work': ['ひとりで', '同僚と', '仲間と'],
  'communication': ['友人と', '仲間と', 'ひとりで'],
  'healing': ['ひとりで', 'パートナーと', '家族と'],
  'newStart': ['ひとりで', 'パートナーと', '家族と'],
};
const _whomDefault = <String>['ひとりで', 'パートナーと', '友人と', '家族と'];

List<String> _whomExamplesFor(String? theme) =>
    _whomByTheme[theme] ?? _whomDefault;

// ── 願い (テーマ別) ──
const _wishByTheme = <String, List<String>>{
  'love': ['関係を深めたい', 'いい出会いがほしい', '心を通わせたい'],
  'money': ['豊かさを引き寄せたい', '仕事の基盤を築きたい', '安定した暮らしがしたい'],
  'work': ['仕事で前進したい', '新しい挑戦をしたい', '集中できる場所がほしい'],
  'communication': ['視野を広げたい', '学びを深めたい', 'いい刺激がほしい'],
  'healing': ['心を休めたい', '気分転換したい', '穏やかに過ごしたい'],
  'newStart': ['流れを変えたい', '新たな一歩を踏み出したい', '心機一転したい'],
};
const _wishDefault = <String>['今より一歩進みたい', '流れを変えたい'];

List<String> _wishExamplesFor(String? theme) =>
    _wishByTheme[theme] ?? _wishDefault;

/// タップで自由記述を埋める記入例チップ群。
/// 枠はテキストフィールドより薄く + 右矢じりで「タップで入る候補」と分かるように。
class _ExampleChips extends StatelessWidget {
  final List<String> examples;
  final ValueChanged<String> onPick;
  const _ExampleChips({required this.examples, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: examples
            .map((e) => GestureDetector(
                  onTap: () => onPick(e),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
                    decoration: BoxDecoration(
                      color: const Color(0x08FFFFFF),
                      borderRadius: BorderRadius.circular(14),
                      // テキストフィールド (0x40FFFFFF) より薄い枠で区別。
                      border: Border.all(color: const Color(0x14FFFFFF)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          e,
                          style: const TextStyle(
                            color: SolaraColors.textSecondary,
                            fontSize: 11.5,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: Color(0x99ACACAC),
                        ),
                      ],
                    ),
                  ),
                ))
            .toList(growable: false),
      ),
    );
  }
}

class _WhomExamples extends StatelessWidget {
  final String? theme;
  final ValueChanged<String> onPick;
  const _WhomExamples({required this.theme, required this.onPick});

  @override
  Widget build(BuildContext context) =>
      _ExampleChips(examples: _whomExamplesFor(theme), onPick: onPick);
}

class _WishExamples extends StatelessWidget {
  final String? theme;
  final ValueChanged<String> onPick;
  const _WishExamples({required this.theme, required this.onPick});

  @override
  Widget build(BuildContext context) =>
      _ExampleChips(examples: _wishExamplesFor(theme), onPick: onPick);
}
