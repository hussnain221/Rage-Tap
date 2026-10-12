import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/data/save_service.dart';
import 'package:rage_tap/game/components/obstacle.dart';
import 'package:rage_tap/game/game_state.dart';
import 'package:rage_tap/game/rage_tap_game.dart';
import 'package:rage_tap/game/systems/scoring.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  group('Scoring pure functions', () {
    test('pointsFromDistance converts distance correctly per C.distancePerPoint', () {
      expect(Scoring.pointsFromDistance(-10), 0);
      expect(Scoring.pointsFromDistance(0), 0);
      expect(Scoring.pointsFromDistance(39.9), 0);
      expect(Scoring.pointsFromDistance(40.0), 1);
      expect(Scoring.pointsFromDistance(79.9), 1);
      expect(Scoring.pointsFromDistance(80.0), 2);
      expect(Scoring.pointsFromDistance(400.0), 10);
    });

    test('isNewBest rules per spec §9.1', () {
      expect(Scoring.isNewBest(0, 0), isFalse);
      expect(Scoring.isNewBest(1, 0), isTrue);
      expect(Scoring.isNewBest(10, 5), isTrue);
      expect(Scoring.isNewBest(5, 5), isFalse);
      expect(Scoring.isNewBest(4, 5), isFalse);
    });
  });

  group('Game scoring and persistence integration', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({'best_score': 50, 'total_runs': 5});
      await SaveService.instance.init();
    });

    test('Score counts up while playing and pauses with game', () {
      final game = RageTapGame();
      expect(game.bestScore.value, 50);
      expect(game.score.value, 0);

      game.startRun();
      expect(game.state.value, GameState.playing);

      _advance(game, 2.0); // 2s at ~190-196 px/s => ~380+ px => score >= 9
      final scorePlaying = game.score.value;
      expect(scorePlaying, greaterThan(0));

      // Pausing freezes score
      game.pause();
      _advance(game, 1.0);
      expect(game.score.value, scorePlaying);

      game.disposeGame();
    });

    test('Death transitions to results and records RunResult and saves new best', () {
      final game = RageTapGame();
      game.startRun();

      // Advance 10s clearing spawned obstacles so player runs freely without colliding
      double elapsed = 0.0;
      while (elapsed < 10.0) {
        for (final obs in game.world.children.whereType<Obstacle>().toList()) {
          obs.removeFromParent();
        }
        game.update(1 / 60);
        elapsed += 1 / 60;
      }
      expect(game.score.value, greaterThan(50));
      final finalScore = game.score.value;

      game.die(ObstacleType.spike);
      _advance(game, 0.41);
      expect(game.state.value, GameState.results);

      expect(game.isNewBest.value, isTrue);
      expect(game.bestScore.value, finalScore);
      expect(SaveService.instance.bestScore, finalScore);
      expect(SaveService.instance.totalRuns, 6);

      final result = game.lastResult;
      expect(result, isNotNull);
      expect(result!.score, finalScore);
      expect(result.best, finalScore);
      expect(result.isNewBest, isTrue);
      expect(result.deathCause, ObstacleType.spike);
      expect(result.durationSeconds, game.runTime);

      game.disposeGame();
    });
  });
}
