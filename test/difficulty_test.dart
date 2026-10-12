import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/core/constants.dart';
import 'package:rage_tap/game/game_state.dart';
import 'package:rage_tap/game/rage_tap_game.dart';
import 'package:rage_tap/game/systems/difficulty.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Difficulty curve exact numbers', () {
    test('t = 0s: base speed 190, tier 1, rest gap [1.30, 1.90]', () {
      expect(Difficulty.speed(0.0), 190.0);
      expect(Difficulty.tier(0.0), 1);
      final gap = Difficulty.restGapRange(0.0);
      expect(gap.min, 1.30);
      expect(gap.max, 1.90);
    });

    test('t = 10s: speed 220, tier 2, rest gap linear lerp values', () {
      expect(Difficulty.speed(10.0), 220.0);
      expect(Difficulty.tier(10.0), 2);
      final gap = Difficulty.restGapRange(10.0);
      // min = 1.30 + (0.95 - 1.30) * (10 / 45) = 1.2222...
      // max = 1.90 + (1.25 - 1.90) * (10 / 45) = 1.7555...
      expect(gap.min, closeTo(1.2222, 0.0001));
      expect(gap.max, closeTo(1.7556, 0.0001));
    });

    test('t = 36.7s: speed capped at 300, tier 5, rest gap linear lerp values', () {
      // 190 + 3.0 * 36.7 = 300.1 -> clamped to 300.0
      expect(Difficulty.speed(36.7), 300.0);
      expect(Difficulty.tier(36.7), 5);
      final gap = Difficulty.restGapRange(36.7);
      // min = 1.30 + (0.95 - 1.30) * (36.7 / 45) = 1.014555...
      // max = 1.90 + (1.25 - 1.90) * (36.7 / 45) = 1.369888...
      expect(gap.min, closeTo(1.0146, 0.0001));
      expect(gap.max, closeTo(1.3699, 0.0001));
    });

    test('t = 45s: speed 300, tier 5, rest gap reaches floor [0.95, 1.25]', () {
      expect(Difficulty.speed(45.0), 300.0);
      expect(Difficulty.tier(45.0), 5);
      final gap = Difficulty.restGapRange(45.0);
      expect(gap.min, 0.95);
      expect(gap.max, 1.25);
    });

    test('t = 100s: speed stays capped at 300, tier 5, rest gap stays at floor', () {
      expect(Difficulty.speed(100.0), 300.0);
      expect(Difficulty.tier(100.0), 5);
      final gap = Difficulty.restGapRange(100.0);
      expect(gap.min, 0.95);
      expect(gap.max, 1.25);
    });
  });

  group('RunTime excludes paused and resuming time', () {
    test('runTime and speed do not advance while paused or resuming', () async {
      final game = RageTapGame();
      await game.onLoad();

      game.startRun();
      expect(game.state.value, GameState.playing);
      expect(game.runTime, 0.0);
      expect(game.currentSpeed, C.baseSpeed);

      // Advance while playing for 2 seconds (using dt <= maxDt)
      for (int i = 0; i < 60; i++) {
        game.update(1 / 30);
      }
      expect(game.runTime, closeTo(2.0, 0.001));
      final speedAtPause = game.currentSpeed;
      expect(speedAtPause, closeTo(190.0 + 3.0 * 2.0, 0.01));

      // Pause the game
      game.pause();
      expect(game.state.value, GameState.paused);

      // Advance time while paused: runTime and currentSpeed must NOT advance
      for (int i = 0; i < 90; i++) {
        game.update(1 / 30);
      }
      expect(game.runTime, closeTo(2.0, 0.001));
      expect(game.currentSpeed, speedAtPause);

      // Resume countdown (resuming state)
      game.beginResume();
      expect(game.state.value, GameState.resuming);

      // Advance during countdown: runTime must still NOT advance
      game.update(1 / 30);
      expect(game.runTime, closeTo(2.0, 0.001));
      expect(game.currentSpeed, speedAtPause);
    });
  });
}
