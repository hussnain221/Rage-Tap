import 'package:flutter_test/flutter_test.dart';

import 'package:rage_tap/main.dart';

void main() {
  testWidgets('RageTapApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RageTapApp());
    expect(find.text('Rage Tap'), findsOneWidget);
  });
}

