// Consultation Input — だれと / 願い の記入例 (テーマ別)
// (part of 'consultation_input_screen.dart')
//
// 自由記述 (⑤ だれと / ⑥ 願い) はタップで埋まる記入例を添えて誘導する。
// 候補は選択中のテーマ (恋愛/豊かさ/仕事/対話/癒し/変化) に沿ったものだけを出す。

part of 'consultation_input_screen.dart';

// ── だれと (テーマ別) ──
// 記入例はタップで自由記述欄に入り、その文字列が Worker に送られる
// (lang に応じて ja/en の例文を選ぶ)。正典は i18n consultInput.whomExamples。
List<String> _whomExamplesFor(String? theme) => switch (theme) {
      'love' => t.consultInput.whomExamples.love,
      'money' => t.consultInput.whomExamples.money,
      'work' => t.consultInput.whomExamples.work,
      'communication' => t.consultInput.whomExamples.communication,
      'healing' => t.consultInput.whomExamples.healing,
      'newStart' => t.consultInput.whomExamples.newStart,
      _ => t.consultInput.whomExamples.fallback,
    };

// ── 願い (テーマ別) ──
List<String> _wishExamplesFor(String? theme) => switch (theme) {
      'love' => t.consultInput.wishExamples.love,
      'money' => t.consultInput.wishExamples.money,
      'work' => t.consultInput.wishExamples.work,
      'communication' => t.consultInput.wishExamples.communication,
      'healing' => t.consultInput.wishExamples.healing,
      'newStart' => t.consultInput.wishExamples.newStart,
      _ => t.consultInput.wishExamples.fallback,
    };

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
