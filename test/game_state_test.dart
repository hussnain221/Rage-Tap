import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/core/constants.dart';
import 'package:rage_tap/game/game_state.dart';
import 'package:rage_tap/game/rage_tap_game.dart';
import 'package:rage_tap/game/systems/difficulty.dart';

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

  test('Difficulty pure functions compute speed and tiers correctly', () {
    expect(Difficulty.speed(0), C.baseSpeed);
    expect(Difficulty.speed(10), 190 + 3.0 * 10);
    expect(Difficulty.speed(36.7), closeTo(300.0, 0.2));
    expect(Difficulty.speed(100), C.maxSpeed);

    expect(Difficulty.tier(0), 1);
    expect(Difficulty.tier(7.9), 1);
    expect(Difficulty.tier(8.0), 2);
    expect(Difficulty.tier(15.9), 2);
    expect(Difficulty.tier(16.0), 3);
    expect(Difficulty.tier(23.9), 3);
    expect(Difficulty.tier(24.0), 4);
    expect(Difficulty.tier(35.9), 4);
    expect(Difficulty.tier(36.0), 5);
    expect(Difficulty.tier(100.0), 5);
  });

  test('RageTapGame legal transitions through full state machine', () {
    final game = RageTapGame();
    expect(game.state.value, GameState.ready);

    // ready -> playing via startRun()
    game.startRun();
    expect(game.state.value, GameState.playing);

    // playing -> paused
    game.pause();
    expect(game.state.value, GameState.paused);

    // paused -> resuming
    game.beginResume();
    expect(game.state.value, GameState.resuming);
    expect(game.resumeCountdown.value, C.resumeCountStart);

    // Step through 3-2-1 countdown (3 steps of 0.4s = 1.2s)
    _advance(game, 0.41);
    expect(game.resumeCountdown.value, 2);
    expect(game.state.value, GameState.resuming);

    _advance(game, 0.41);
    expect(game.resumeCountdown.value, 1);
    expect(game.state.value, GameState.resuming);

    _advance(game, 0.41);
    expect(game.resumeCountdown.value, 0);
    expect(game.state.value, GameState.playing);

    // playing -> dying
    game.die();
    expect(game.state.value, GameState.dying);

    // dying -> results after 0.40s
    _advance(game, 0.41);
    expect(game.state.value, GameState.results);

    // results -> retry -> playing immediately
    game.retry();
    expect(game.state.value, GameState.playing);

    game.disposeGame();
  });


  test('die() executes only once per run (guarded)', () {
    final game = RageTapGame();
    game.startRun();
    expect(game.state.value, GameState.playing);

    game.die();
    expect(game.state.value, GameState.dying);

    // Second call to die while dying should be ignored
    game.die();
    expect(game.state.value, GameState.dying);

    // Transition to results
    _advance(game, 0.41);
    expect(game.state.value, GameState.results);

    // Calling die while in results should be ignored
    game.die();
    expect(game.state.value, GameState.results);

    game.disposeGame();
  });

  test('retry() resets run data but preserves bestScore', () {
    final game = RageTapGame();
    game.bestScore.value = 750;
    game.startRun();

    // Advance 5 seconds of play
    _advance(game, 5.0);
    game.score.value = 120;
    expect(game.runTime, greaterThan(0));
    expect(game.distance, greaterThan(0));

    // Die and trigger results
    game.die();
    _advance(game, 0.41);
    expect(game.state.value, GameState.results);

    // Retry
    game.retry();
    expect(game.state.value, GameState.playing);
    expect(game.runTime, 0.0);
    expect(game.distance, 0.0);
    expect(game.score.value, 0);
    expect(game.currentSpeed, C.baseSpeed);
    expect(game.bestScore.value, 750); // Preserved!

    game.disposeGame();
  });

  test('paused and resuming states do not advance runTime or distance', () {
    final game = RageTapGame();
    game.startRun();

    // Run for 1.0 second
    _advance(game, 1.0);
    final recordedTime = game.runTime;
    final recordedDistance = game.distance;
    expect(recordedTime, closeTo(1.0, 0.05));
    expect(recordedDistance, greaterThan(0));

    // Pause and step 2 seconds
    game.pause();
    expect(game.state.value, GameState.paused);
    _advance(game, 2.0);
    expect(game.runTime, recordedTime);
    expect(game.distance, recordedDistance);

    // Resume and step during countdown
    game.beginResume();
    expect(game.state.value, GameState.resuming);
    _advance(game, 0.4);
    expect(game.runTime, recordedTime);
    expect(game.distance, recordedDistance);

    game.disposeGame();
  });
}

