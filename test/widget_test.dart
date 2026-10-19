import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/app.dart';
import 'package:rage_tap/game/rage_tap_game.dart';
import 'package:rage_tap/ui/widgets/neon_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App shell and route navigation test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const RageTapApp());

    // Initially on Splash screen
    expect(find.text('RAGE'), findsOneWidget);
    expect(find.text('TAP'), findsOneWidget);

    // Wait for splash timer (800ms) and route transition (180ms)
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 300));

    // Now on Home screen
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('One tap. One mistake. One more try.'), findsOneWidget);

    // Tap Settings icon -> navigate to Settings screen
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('Sound Effects'), findsOneWidget);

    // Go back to Home screen
    await tester.tap(find.byType(NeonIconButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('PLAY'), findsOneWidget);

    // Tap PLAY -> navigate to Game screen
    await tester.tap(find.text('PLAY'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(GameWidget<RageTapGame>), findsOneWidget);
    expect(find.text('TAP TO JUMP'), findsOneWidget);

    // Tap on game screen to start playing
    await tester.tapAt(const Offset(200, 400));
    await tester.pump();

    // In playing state: TAP TO JUMP hint is gone, but BEST score is STILL VISIBLE!
    expect(find.text('TAP TO JUMP'), findsNothing);
    expect(find.textContaining('BEST'), findsOneWidget);

    // Pump frames during playing state
    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 33));
    }

    // BEST score is still visible throughout gameplay!
    expect(find.textContaining('BEST'), findsOneWidget);
  });
}





