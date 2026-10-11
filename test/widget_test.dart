import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/app.dart';

void main() {
  testWidgets('App shell and route navigation test', (WidgetTester tester) async {
    await tester.pumpWidget(const RageTapApp());

    // Initially on Splash screen
    expect(find.text('RAGE TAP'), findsOneWidget);

    // Wait for splash timer (800ms) and route transition (180ms)
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    // Now on Home screen
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('One tap. One mistake. One more try.'), findsOneWidget);

    // Tap PLAY -> navigate to Game screen
    await tester.tap(find.text('PLAY'));
    await tester.pumpAndSettle();
    expect(find.text('Game'), findsOneWidget);

    // Go back to Home screen
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(find.text('PLAY'), findsOneWidget);

    // Tap Settings icon -> navigate to Settings screen
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsNWidgets(2)); // AppBar title + body
  });
}


