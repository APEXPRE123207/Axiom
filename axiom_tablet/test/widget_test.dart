import 'package:flutter_test/flutter_test.dart';
import 'package:axiom_tablet/main.dart';

void main() {
  testWidgets('Axiom App launches and renders title smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AxiomApp());
    await tester.pumpAndSettle();
    expect(find.text('AXIOM'), findsOneWidget);
  });
}
