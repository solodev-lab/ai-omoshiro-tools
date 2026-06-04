import 'package:flutter_test/flutter_test.dart';
import 'package:solara/main.dart';

void main() {
  // `const SolaraApp()` は initialConsented=false (= AI 生成同意 未取得) なので、
  // 起動時は SolaraHome ではなく AiConsentScreen を表示する
  // (main() 本体は SolaraStorage.hasAiConsent() の結果で initialConsented を渡すが、
  //  本テストは default false の起動経路 = 初回起動相当を検証する)。
  testWidgets('Solara app launches to AI consent screen', (tester) async {
    await tester.pumpWidget(const SolaraApp());
    // SOLARA ワードマークはロケール非依存で常に出る (consent 画面の指標)。
    expect(find.text('SOLARA'), findsOneWidget);
  });
}
