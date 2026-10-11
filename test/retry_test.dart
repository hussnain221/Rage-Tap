import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/core/constants.dart';
import 'package:rage_tap/game/components/obstacle.dart';
import 'package:rage_tap/game/components/player.dart';
import 'package:rage_tap/game/game_state.dart';
import 'package:rage_tap/game/rage_tap_game.dart';

void _advance(RageTapGame game, double seconds) {
  const dt = 1 / 60;
  double elapsed = 0.0;
  while (elapsed < seconds) {
    game.update(dt);
    elapsed += dt;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('retry() cleanly resets run data, skips ready, and preserves bestScore', () {
    final game = RageTapGame();
    game.bestScore.value = 999;
    game.startRun();
    expect(game.state.value, GameState.playing);

    // Simulate play progress
    _advance(game, 1.5);
    game.score.value = 45;
    expect(game.runTime, greaterThan(1.0));
    expect(game.distance, greaterThan(0));

    // Force collision & transition to results
    game.die();
    _advance(game, 0.41);
    expect(game.state.value, GameState.results);

    // Tapping on game area while in results does NOT start run or jump
    game.onTapDown();
    expect(game.state.value, GameState.results);

    // Call retry
    game.retry();

    // Verify state machine
    expect(game.state.value, GameState.playing); // Skips ready
    expect(game.runTime, 0.0);
    expect(game.distance, 0.0);
    expect(game.score.value, 0);
    expect(game.currentSpeed, C.baseSpeed);
    expect(game.bestScore.value, 999); // Preserved!

    // Verify player reset
    expect(game.player.y, Player.groundY);
    expect(game.player.vy, 0.0);
    expect(game.player.grounded, isTrue);
    expect(game.player.jumpBufferTimer, 0.0);

    // Verify obstacles: only the single retry safe opening spike exists
    final obstacles = game.world.children.whereType<Obstacle>().toList();
    expect(obstacles.length, 1);
    final expectedSpawnX = C.playerLeft + C.safeOpeningRetry * C.baseSpeed;
    expect(obstacles.first.x, expectedSpawnX);

    game.disposeGame();
  });

  test('Die and retry 20 times in a row without glitches', () {
    final game = RageTapGame();
    game.bestScore.value = 1200;
    game.startRun();

    for (int i = 1; i <= 20; i++) {
      expect(game.state.value, GameState.playing);

      // Advance time until the spike reaches player and causes collision
      // Initial spike is at x = 64 + 2.0*190 = 444 on retry, takes ~2.0s to arrive
      // We advance in chunks until player dies
      double elapsed = 0.0;
      while (game.state.value == GameState.playing && elapsed < 4.0) {
        game.update(1 / 60);
        elapsed += 1 / 60;
      }

      expect(game.state.value, GameState.dying, reason: 'Failed to die on run $i');

      // Complete death animation to reach results
      _advance(game, 0.41);
      expect(game.state.value, GameState.results, reason: 'Failed to reach results on run $i');

      // Tap on game area must be ignored
      game.onTapDown();
      expect(game.state.value, GameState.results);

      // Retry
      game.retry();
      expect(game.state.value, GameState.playing, reason: 'Failed to retry on run $i');
      expect(game.runTime, 0.0);
      expect(game.distance, 0.0);
      expect(game.score.value, 0);
      expect(game.bestScore.value, 1200);

      // Exactly 1 obstacle exists for the new run
      expect(game.world.children.whereType<Obstacle>().length, 1);
    }

    game.disposeGame();
  });
}
