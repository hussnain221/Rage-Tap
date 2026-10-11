import 'package:flame/camera.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/core/constants.dart';
import 'package:rage_tap/game/game_state.dart';
import 'package:rage_tap/game/rage_tap_game.dart';
import 'package:rage_tap/ui/screens/game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('GameState enum values are complete', () {
    expect(GameState.values, [
      GameState.ready,
      GameState.playing,
      GameState.paused,
      GameState.resuming,
      GameState.dying,
      GameState.results,
    ]);
  });

  test('RageTapGame initializes with fixed resolution camera and notifiers', () async {
    final game = RageTapGame();
    expect(game.state.value, GameState.ready);
    expect(game.score.value, 0);
    expect(game.bestScore.value, 0);
    expect(game.isNewBest.value, false);
    expect(game.resumeCountdown.value, 0);

    final viewport = game.camera.viewport;
    expect(viewport, isA<FixedResolutionViewport>());
    final fixedViewport = viewport as FixedResolutionViewport;
    expect(fixedViewport.resolution.x, C.worldW);
    expect(fixedViewport.resolution.y, C.worldH);

    game.disposeGame();
  });

  testWidgets('GameScreen mounts with GameWidget and debug overlay', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(),
      ),
    );
    await tester.pump();
    expect(find.byType(GameWidget<RageTapGame>), findsOneWidget);
    expect(find.textContaining('State: ready'), findsOneWidget);
  });
}
