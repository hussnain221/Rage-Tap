import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/data/save_service.dart';
import 'package:rage_tap/game/components/obstacle.dart';
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

  test('Teaching hint "STAY LOW!" triggers once on first beam and persists beamHintShown', () async {
    SharedPreferences.setMockInitialValues({'beam_hint_shown': false});
    await SaveService.instance.init();

    final game = RageTapGame(seed: 42);
    game.startRun();

    expect(game.hint.value, isNull);
    expect(SaveService.instance.beamHintShown, isFalse);

    // Add a beam far off screen (x = 400)
    final beam = Obstacle.beam(x: 400);
    game.world.add(beam);

    // Update 1 frame - beam is at x > 360, no hint yet
    game.update(1 / 60);
    expect(game.hint.value, isNull);

    // Move beam to x = 350 (< 360)
    beam.x = 350;
    game.update(1 / 60);

    // Hint should now be active
    expect(game.hint.value, 'STAY LOW!');
    expect(SaveService.instance.beamHintShown, isTrue);

    // Advance 1.5s - still active
    double elapsed = 0.0;
    while (elapsed < 1.5) {
      game.update(1 / 60);
      elapsed += 1 / 60;
    }
    expect(game.hint.value, 'STAY LOW!');

    // Advance 0.2s more (total 1.7s > 1.6s) - hint cleared
    for (int i = 0; i < 15; i++) {
      game.update(1 / 60);
    }
    expect(game.hint.value, isNull);

    // Add second beam: hint does not trigger again
    final beam2 = Obstacle.beam(x: 350);
    game.world.add(beam2);
    game.update(1 / 60);
    expect(game.hint.value, isNull);

    game.disposeGame();
  });
}
