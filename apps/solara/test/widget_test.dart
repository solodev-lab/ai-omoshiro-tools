import 'package:flutter_test/flutter_test.dart';
import 'package:solara/main.dart';

void main() {
  testWidgets('Solara app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const SolaraApp());
    expect(find.text('Map'), findsOneWidget);
  });
}
