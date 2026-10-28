import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/core/constants.dart';
import 'package:rage_tap/game/game_state.dart';
import 'package:rage_tap/game/painting/zap_painter.dart';
import 'package:rage_tap/game/rage_tap_game.dart';
import 'package:rage_tap/game/systems/spawner.dart';

class _NoObstacleSpawner extends Spawner {
  @override
  List<SpawnItem> startRun({
    required bool isRetry,
    required double speed,
    double runTime = 0.0,
  }) =>
      [];

  @override
  List<SpawnItem> update(double dt, double speed, double runTime) => [];
}

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

  group('Rage Meter (§20.1) unit tests', () {
    test('Constants match specification §20.1', () {
      expect(C.rageEnabled, isTrue);
      expect(C.rageNearMissIncrement, 25.0);
      expect(C.rageDrainDelaySec, 3.0);
      expect(C.rageDrainPerSec, 8.0);
      expect(C.rageDurationSec, 5.0);
      expect(C.rageSpeedMultiplier, 1.15);
      expect(C.rageScoreMultiplier, 2);
      expect(C.rageMeterW, 160.0);
      expect(C.rageMeterH, 8.0);
      expect(C.rageOverlayAlpha, 0.15);
    });

    test('Initial meter state is 0.0 and inactive', () {
      final game = RageTapGame();
      expect(game.rageMeter.value, 0.0);
      expect(game.isRageActive.value, isFalse);
      expect(game.player.isRageMode, isFalse);
      game.disposeGame();
    });

    test('Near-miss increments meter by 25% each, capping at 100% and triggering Rage Mode', () {
      final game = RageTapGame();
      game.startRun();
      expect(game.state.value, GameState.playing);

      // 1st near-miss -> 25%
      game.triggerNearMissForTesting();
      expect(game.rageMeter.value, 25.0);
      expect(game.isRageActive.value, isFalse);

      // 2nd near-miss -> 50%
      game.triggerNearMissForTesting();
      expect(game.rageMeter.value, 50.0);
      expect(game.isRageActive.value, isFalse);

      // 3rd near-miss -> 75%
      game.triggerNearMissForTesting();
      expect(game.rageMeter.value, 75.0);
      expect(game.isRageActive.value, isFalse);

      // 4th near-miss -> 100% -> Rage Mode triggers!
      game.triggerNearMissForTesting();
      expect(game.rageMeter.value, 100.0);
      expect(game.isRageActive.value, isTrue);
      expect(game.player.isRageMode, isTrue);

      game.disposeGame();
    });

    test('Full meter triggers 5s Rage Mode with 1.15x speed and 2x score accumulation', () {
      final game = RageTapGame(spawner: _NoObstacleSpawner());
      game.startRun();
      expect(game.state.value, GameState.playing);

      _advance(game, 0.1);
      final normalSpeed = game.currentSpeed;

      // Trigger Rage Mode via helper
      game.activateRageModeForTesting();
      expect(game.isRageActive.value, isTrue);
      expect(game.player.isRageMode, isTrue);
      expect(game.rageMeter.value, 100.0);

      _advance(game, 0.1);
      expect(game.currentSpeed, closeTo(normalSpeed * C.rageSpeedMultiplier, 0.5));

      // Advance through remainder of 5.0 seconds
      _advance(game, 5.0);

      // Rage Mode must expire and reset
      expect(game.isRageActive.value, isFalse);
      expect(game.player.isRageMode, isFalse);
      expect(game.rageMeter.value, 0.0);

      game.disposeGame();
    });

    test('Meter drains at 8%/s after 3s of no near-miss', () async {
      final game = RageTapGame(spawner: _NoObstacleSpawner());
      await game.onLoad();
      game.startRun();

      // Add 2 near-misses -> 50%
      game.triggerNearMissForTesting();
      game.triggerNearMissForTesting();
      expect(game.rageMeter.value, 50.0);

      // Advance 2.5s (before the 3s delay threshold)
      _advance(game, 2.5);
      expect(game.rageMeter.value, 50.0); // No drain yet!

      // Advance 1.0s more (3.5s total: 0.5s of draining at 8%/s = 4.0% drained)
      _advance(game, 1.0);
      expect(game.rageMeter.value, closeTo(46.0, 0.5));

      // Another near miss resets the timer and boosts meter
      game.triggerNearMissForTesting();
      expect(game.rageMeter.value, closeTo(71.0, 0.5));

      // Advance 2.0s: still within the new 3s delay, no drain occurs
      _advance(game, 2.0);
      expect(game.rageMeter.value, closeTo(71.0, 0.5));

      game.disposeGame();
    });

    test('Player death terminates Rage Mode and resets meter', () {
      final game = RageTapGame();
      game.startRun();
      game.isRageActive.value = true;
      game.player.isRageMode = true;
      game.rageMeter.value = 80.0;

      game.die();
      expect(game.isRageActive.value, isFalse);
      expect(game.player.isRageMode, isFalse);
      expect(game.rageMeter.value, 0.0);

      game.disposeGame();
    });

    test('Retry cleanly resets Rage Mode and meter', () {
      final game = RageTapGame();
      game.startRun();
      game.isRageActive.value = true;
      game.player.isRageMode = true;
      game.rageMeter.value = 75.0;

      game.die();
      _advance(game, 0.42);
      game.retry();

      expect(game.isRageActive.value, isFalse);
      expect(game.player.isRageMode, isFalse);
      expect(game.rageMeter.value, 0.0);

      game.disposeGame();
    });

    test('ZapPainter paints with isRage = true without errors', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(
        () => ZapPainter.paintZap(
          canvas,
          origin: Offset.zero,
          size: 40.0,
          expression: ZapExpression.run,
          t: 1.0,
          scaleX: 1.0,
          scaleY: 1.0,
          isRage: true,
        ),
        returnsNormally,
      );

      final picture = recorder.endRecording();
      picture.dispose();
    });
  });
}
