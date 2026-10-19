import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/data/save_service.dart';
import 'package:rage_tap/game/game_state.dart';
import 'package:rage_tap/game/rage_tap_game.dart';
import 'package:rage_tap/ui/widgets/ready_hint.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('ReadyHint shows first run caption when firstRunDone is false', (tester) async {
    SharedPreferences.setMockInitialValues({'first_run_done': false});
    await SaveService.instance.init();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReadyHint(),
        ),
      ),
    );

    expect(find.text('TAP TO JUMP'), findsOneWidget);
    expect(find.byIcon(Icons.touch_app), findsOneWidget);
    expect(find.text("Jump over the hazards. Don't touch them."), findsOneWidget);
  });

  testWidgets('ReadyHint hides tutorial caption when firstRunDone is true', (tester) async {
    SharedPreferences.setMockInitialValues({'first_run_done': true});
    await SaveService.instance.init();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReadyHint(),
        ),
      ),
    );

    expect(find.text('TAP TO JUMP'), findsOneWidget);
    expect(find.byIcon(Icons.touch_app), findsOneWidget);
    expect(find.text("Jump over the hazards. Don't touch them."), findsNothing);
  });

  testWidgets('First tap starts run, performs first jump, and sets firstRunDone = true', (tester) async {
    SharedPreferences.setMockInitialValues({'first_run_done': false});
    await SaveService.instance.init();

    final game = RageTapGame(seed: 42);
    expect(game.state.value, equals(GameState.ready));
    expect(SaveService.instance.firstRunDone, isFalse);

    // Tap to start
    game.onTapDown();

    expect(game.state.value, equals(GameState.playing));
    expect(game.player.grounded, isFalse); // Jumped immediately!
    expect(SaveService.instance.firstRunDone, isTrue);
  });

  testWidgets('Retry skips ready state and transitions directly to playing', (tester) async {
    final game = RageTapGame(seed: 42);
    game.state.value = GameState.results;

    game.retry();

    expect(game.state.value, equals(GameState.playing));
  });
}
