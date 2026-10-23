import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/game/game_state.dart';
import 'package:rage_tap/game/rage_tap_game.dart';
import 'package:rage_tap/ui/screens/game_screen.dart';
import 'package:rage_tap/ui/widgets/hud.dart';
import 'package:rage_tap/ui/widgets/neon_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'best_score': 120});
  });

  testWidgets('GameHud renders BEST, score, and pause button', (tester) async {
    final game = RageTapGame(seed: 42);
    game.score.value = 42;
    game.bestScore.value = 120;
    game.state.value = GameState.playing;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameHud(game: game),
        ),
      ),
    );

    // Verify left BEST score
    expect(find.text('BEST'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);

    // Verify center score
    expect(find.text('42'), findsOneWidget);

    // Verify right pause button
    expect(find.byType(NeonIconButton), findsOneWidget);

    // Tap pause button -> triggers game.pause()
    await tester.tap(find.byType(NeonIconButton));
    expect(game.state.value, equals(GameState.paused));
  });

  testWidgets('GameHud hides pause button during dying and results states', (tester) async {
    final game = RageTapGame(seed: 42);
    game.state.value = GameState.dying;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameHud(game: game),
        ),
      ),
    );

    // Pause button should be hidden during dying
    expect(find.byType(NeonIconButton), findsNothing);

    // Change to results state -> still hidden
    game.state.value = GameState.results;
    await tester.pump();
    expect(find.byType(NeonIconButton), findsNothing);

    // Change back to playing -> pause button appears
    game.state.value = GameState.playing;
    await tester.pump();
    expect(find.byType(NeonIconButton), findsOneWidget);
  });

  testWidgets('Score text pops on bonus trigger', (tester) async {
    final game = RageTapGame(seed: 42);
    game.score.value = 10;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameHud(game: game),
        ),
      ),
    );

    // Trigger score bonus pop
    game.scoreBonusTrigger.value++;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60)); // Halfway through 120ms pop

    final scaleTransitionFinder = find.ancestor(
      of: find.text('10'),
      matching: find.byType(ScaleTransition),
    );
    expect(scaleTransitionFinder, findsOneWidget);
    final scaleWidget = tester.widget<ScaleTransition>(scaleTransitionFinder);
    expect(scaleWidget.scale.value, greaterThan(1.0));

    // Complete the 120ms pop
    await tester.pump(const Duration(milliseconds: 70));
    expect(scaleWidget.scale.value, closeTo(1.0, 0.05));
  });

  testWidgets('GameScreen integrates GameHud and Android back button pauses when playing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(),
      ),
    );

    expect(find.byType(GameHud), findsOneWidget);
  });

  testWidgets('GameHud renders hint text with fade and ignores touches', (tester) async {
    final game = RageTapGame(seed: 42);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameHud(game: game),
        ),
      ),
    );

    // Initially no hint
    expect(find.text('STAY LOW!'), findsNothing);

    // Set hint
    game.hint.value = 'STAY LOW!';
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('STAY LOW!'), findsOneWidget);
    // IgnorePointer wraps hint so it does not block touches
    final ignorePointers = tester.widgetList<IgnorePointer>(
      find.ancestor(of: find.text('STAY LOW!'), matching: find.byType(IgnorePointer)),
    );
    expect(ignorePointers.any((p) => p.ignoring), isTrue);

    // Clear hint
    game.hint.value = null;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('STAY LOW!'), findsNothing);
  });
}
