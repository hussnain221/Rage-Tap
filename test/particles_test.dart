import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/core/constants.dart';
import 'package:rage_tap/game/components/particles.dart';
import 'package:rage_tap/game/game_state.dart';
import 'package:rage_tap/game/rage_tap_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ParticleEffects component unit tests', () {
    late RageTapGame game;
    late ParticleEffects effects;

    setUp(() {
      game = RageTapGame(seed: 42);
      effects = game.particles;
    });

    test('Initial state has no active particles, shake, or flash', () {
      expect(effects.activeParticleCount, equals(0));
      expect(effects.isShaking, isFalse);
      expect(effects.isFlashing, isFalse);
      expect(effects.isHitFreezeActive, isFalse);
      expect(effects.currentFlashAlpha, equals(0.0));
    });

    test('spawnLandingDust spawns 3 tiny muted particles at given position', () {
      effects.spawnLandingDust(Vector2(84, 500));

      expect(effects.activeParticleCount, equals(3));
      // Advance by 0.30s (past maxLife 0.25s)
      effects.update(0.30);
      expect(effects.activeParticleCount, equals(0));
    });

    test('triggerDeathEffect triggers immediate flash and shake, respects hit freeze', () {
      effects.triggerDeathEffect(Vector2(84, 480));

      expect(effects.isFlashing, isTrue);
      expect(effects.currentFlashAlpha, closeTo(0.35, 0.01));
      expect(effects.isShaking, isTrue);
      expect(effects.isHitFreezeActive, isTrue);
      // During hit freeze (0.0 to 0.10s), 0 death particles spawned yet
      expect(effects.activeParticleCount, equals(0));

      // Advance within hit freeze (0.05s)
      effects.update(0.05);
      expect(effects.isHitFreezeActive, isTrue);
      expect(effects.activeParticleCount, equals(0));
      expect(effects.isFlashing, isTrue);
      expect(effects.currentFlashAlpha, closeTo(0.35 * (1.0 - 0.05 / 0.15), 0.01));

      // Advance past hit freeze (0.06s more, total 0.11s > C.hitFreezeSec)
      effects.update(0.06);
      expect(effects.isHitFreezeActive, isFalse);
      expect(effects.activeParticleCount, equals(14));

      // Advance past flash duration (0.15s total)
      effects.update(0.05);
      expect(effects.isFlashing, isFalse);
      expect(effects.currentFlashAlpha, equals(0.0));

      // Advance past shake duration (0.25s)
      effects.update(0.10);
      expect(effects.isShaking, isFalse);
      expect(game.camera.viewfinder.position.x, equals(0.0));
      expect(game.camera.viewfinder.position.y, equals(0.0));

      // Advance past particle maxLife (0.50s)
      effects.update(0.40);
      expect(effects.activeParticleCount, equals(0));
    });

    test('spawnDeathParticles immediately activates 14 cyan square particles', () {
      effects.spawnDeathParticles(Vector2(100, 200));

      expect(effects.activeParticleCount, equals(14));
    });

    test('clear() cancels flash, shake, pending freeze, and resets viewfinder', () {
      effects.triggerDeathEffect(Vector2(84, 480));
      effects.update(0.12);
      expect(effects.activeParticleCount, equals(14));
      expect(effects.isShaking, isTrue);

      effects.clear();

      expect(effects.activeParticleCount, equals(0));
      expect(effects.isFlashing, isFalse);
      expect(effects.isShaking, isFalse);
      expect(effects.isHitFreezeActive, isFalse);
      expect(game.camera.viewfinder.position.x, equals(0.0));
      expect(game.camera.viewfinder.position.y, equals(0.0));
    });
  });

  group('Game death, landing, and retry integration tests', () {
    test('die() triggers death FX and switches Zap to dead', () {
      final game = RageTapGame(seed: 42);
      game.state.value = GameState.playing;

      game.die();

      expect(game.state.value, equals(GameState.dying));
      expect(game.player.currentExpression.name, equals('dead'));
      expect(game.particles.isFlashing, isTrue);
      expect(game.particles.isShaking, isTrue);
      expect(game.particles.isHitFreezeActive, isTrue);
    });

    test('retry() clears all particles and resets camera viewfinder', () {
      final game = RageTapGame(seed: 42);
      game.state.value = GameState.playing;
      game.die();
      // Step into dying past freeze
      game.particles.update(0.12);
      expect(game.particles.activeParticleCount, equals(14));

      game.retry();

      expect(game.particles.activeParticleCount, equals(0));
      expect(game.particles.isShaking, isFalse);
      expect(game.particles.isFlashing, isFalse);
      expect(game.camera.viewfinder.position.x, equals(0.0));
      expect(game.camera.viewfinder.position.y, equals(0.0));
    });

    test('Player landing spawns landing dust', () {
      final game = RageTapGame(seed: 42);
      // Simulate player landing
      game.spawnLandingDust(Vector2(C.playerLeft + C.playerSize / 2, C.groundTopY));
      expect(game.particles.activeParticleCount, equals(3));
    });
  });
}
