import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_management_system/app.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.byType(App), findsOneWidget);
  });
}
