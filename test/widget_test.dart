import 'package:flutter_test/flutter_test.dart';
import 'package:honeyyyb/main.dart';

void main() {
  testWidgets('Honeyyyb smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HoneyyybApp());
    expect(find.text('Honeyyyb'), findsWidgets);
  });
}
