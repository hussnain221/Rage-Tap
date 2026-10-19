import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/core/constants.dart';
import 'package:rage_tap/data/save_service.dart';
import 'package:rage_tap/game/game_state.dart';
import 'package:rage_tap/game/rage_tap_game.dart';
import 'package:rage_tap/ui/widgets/pause_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'sound_enabled': true,
      'haptics_enabled': true,
    });
    await SaveService.instance.init();
  });

  testWidgets('PauseOverlay renders all elements and handles actions', (tester) async {
    final game = RageTapGame(seed: 42);
    game.state.value = GameState.paused;
    bool homePressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PauseOverlay(
            game: game,
            onHomePressed: () => homePressed = true,
          ),
        ),
      ),
    );

    // Title and buttons
    expect(find.text('PAUSED'), findsOneWidget);
    expect(find.text('RESUME'), findsOneWidget);
    expect(find.text('RESTART'), findsOneWidget);
    expect(find.text('HOME'), findsOneWidget);

    // Tapping HOME
    await tester.tap(find.text('HOME'));
    expect(homePressed, isTrue);

    // Tapping RESTART
    await tester.tap(find.text('RESTART'));
    expect(game.state.value, equals(GameState.playing));

    // Pause again and test RESUME
    game.state.value = GameState.paused;
    await tester.pump();
    await tester.tap(find.text('RESUME'));
    expect(game.state.value, equals(GameState.resuming));
    expect(game.resumeCountdown.value, equals(3));
  });

  testWidgets('PauseOverlay sound and haptics toggle SaveService', (tester) async {
    final game = RageTapGame(seed: 42);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PauseOverlay(game: game),
        ),
      ),
    );

    expect(SaveService.instance.soundEnabled, isTrue);
    expect(SaveService.instance.hapticsEnabled, isTrue);

    // Tap sound toggle
    await tester.tap(find.byTooltip('Sound On'));
    await tester.pump();
    expect(SaveService.instance.soundEnabled, isFalse);
    expect(find.byTooltip('Sound Off'), findsOneWidget);

    // Tap vibration toggle
    await tester.tap(find.byTooltip('Vibration On'));
    await tester.pump();
    expect(SaveService.instance.hapticsEnabled, isFalse);
    expect(find.byTooltip('Vibration Off'), findsOneWidget);
  });

  testWidgets('ResumeCountdownOverlay steps 3-2-1 and resumes playing', (tester) async {
    final game = RageTapGame(seed: 42);
    game.state.value = GameState.paused;
    game.beginResume();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResumeCountdownOverlay(game: game),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);

    void stepTime(double seconds) {
      final steps = (seconds / C.maxDt).ceil();
      for (int i = 0; i < steps; i++) {
        game.update(C.maxDt);
      }
    }

    // Advance 0.4s -> step 2
    stepTime(0.42);
    await tester.pump();
    expect(game.resumeCountdown.value, equals(2));
    expect(find.text('2'), findsOneWidget);

    // Advance 0.4s -> step 1
    stepTime(0.42);
    await tester.pump();
    expect(game.resumeCountdown.value, equals(1));
    expect(find.text('1'), findsOneWidget);

    // Advance 0.4s -> completes to 0, transitions to playing
    stepTime(0.42);
    await tester.pump();
    expect(game.state.value, equals(GameState.playing));
  });
}
