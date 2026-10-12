import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/core/constants.dart';
import 'package:rage_tap/game/components/obstacle.dart';
import 'package:rage_tap/game/components/popup_text.dart';
import 'package:rage_tap/game/game_state.dart';
import 'package:rage_tap/game/rage_tap_game.dart';
import 'package:rage_tap/game/systems/near_miss.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NearMiss pure decision logic', () {
    test('Threshold 0: valid near-miss (player bottom exactly touches obstacle top without overlapping)', () {
      expect(
        NearMiss.isNearMiss(minClearance: 0.0, cooldownRemaining: 0.0),
        isTrue,
      );
    });

    test('Threshold 14: valid near-miss at upper clearance boundary', () {
      expect(
        NearMiss.isNearMiss(minClearance: 14.0, cooldownRemaining: 0.0),
        isTrue,
      );
    });

    test('Threshold 15: beyond clearance limit (clean jump, not a near-miss)', () {
      expect(
        NearMiss.isNearMiss(minClearance: 15.0, cooldownRemaining: 0.0),
        isFalse,
      );
    });

    test('Negative clearance: not a near-miss', () {
      expect(
        NearMiss.isNearMiss(minClearance: -1.0, cooldownRemaining: 0.0),
        isFalse,
      );
    });

    test('Cooldown: blocks near-miss when cooldownRemaining > 0', () {
      expect(
        NearMiss.isNearMiss(minClearance: 8.0, cooldownRemaining: 0.1),
        isFalse,
      );
      expect(
        NearMiss.isNearMiss(minClearance: 8.0, cooldownRemaining: 0.0),
        isTrue,
      );
    });
  });

  group('NearMiss game integration', () {
    test('Near-miss awards +5 bonus, spawns PopupText, starts 0.4s cooldown, increments nearMisses', () async {
      final game = RageTapGame();
      await game.onLoad();
      game.startRun();

      // Clear any spawned obstacles from startRun
      for (final obs in game.world.children.whereType<Obstacle>().toList()) {
        obs.removeFromParent();
      }

      // Position a single spike unit so that player barely clears it
      // Spike unit hitbox top: C.groundTopY - C.spikeH + C.spikeHitY = 500 - 28 + 6 = 478
      // Player hitbox bottom: player.y + C.playerHitY + C.playerHitH = player.y + 40
      // For clearance = 10, player hitbox bottom must be 468, so player.y = 428
      final spike = Obstacle.spike(x: 200);
      await game.world.add(spike);

      // Place player in air above spike
      game.player.y = 428;
      game.player.grounded = false;
      game.player.vy = 0.0; // frozen in air for this step

      // Move spike past player: player hitbox is [70, 98]
      // Spike hitbox is [x + 3, x + 27]
      // First frame: spike horizontally overlaps player (e.g. spike hitbox right = 90, left = 66)
      spike.x = 63;
      game.update(1 / 60);

      expect(spike.minClearance, closeTo(10.0, 1.5));
      expect(game.nearMissCount, 0);

      // Second frame: spike right edge moves past player left edge (spike.x = 30 -> hitbox right = 57 < 70)
      spike.x = 30;
      game.update(1 / 60);

      expect(spike.passed, isTrue);
      expect(game.nearMissCount, 1);
      expect(game.bonusScore, C.nearMissBonus);
      expect(game.score.value, greaterThanOrEqualTo(C.nearMissBonus));
      expect(game.nearMissCooldown, closeTo(C.nearMissCooldownSec, 0.02));
      expect(game.world.children.whereType<PopupText>().isNotEmpty, isTrue);
    });

    test('Once per hazard: subsequent updates do not award near-miss again for same hazard', () async {
      final game = RageTapGame();
      await game.onLoad();
      game.startRun();

      for (final obs in game.world.children.whereType<Obstacle>().toList()) {
        obs.removeFromParent();
      }

      final spike = Obstacle.spike(x: 63);
      await game.world.add(spike);
      game.player.y = 428;
      game.player.grounded = false;
      game.player.vy = 0.0;

      // Overlap
      game.update(1 / 60);
      // Pass
      spike.x = 30;
      game.update(1 / 60);

      expect(game.nearMissCount, 1);

      // Update multiple more frames
      for (int i = 0; i < 10; i++) {
        game.update(1 / 60);
      }
      expect(game.nearMissCount, 1);
      expect(game.bonusScore, C.nearMissBonus);
    });

    test('Cooldown prevents second near-miss award within 0.4s', () async {
      final game = RageTapGame();
      await game.onLoad();
      game.startRun();

      for (final obs in game.world.children.whereType<Obstacle>().toList()) {
        obs.removeFromParent();
      }

      // First spike passes with near-miss
      final spike1 = Obstacle.spike(x: 63);
      await game.world.add(spike1);
      game.player.y = 428;
      game.player.grounded = false;
      game.player.vy = 0.0;

      game.update(1 / 60);
      spike1.x = 30;
      game.update(1 / 60);
      expect(game.nearMissCount, 1);

      // Second spike immediately passes within cooldown (cooldown is ~0.38s)
      final spike2 = Obstacle.spike(x: 63);
      await game.world.add(spike2);
      game.update(1 / 60);
      spike2.x = 30;
      game.update(1 / 60);

      // Cooldown should have blocked the second award
      expect(game.nearMissCount, 1);
      expect(game.bonusScore, C.nearMissBonus);
    });

    test('No near-miss award when collision occurs', () async {
      final game = RageTapGame();
      await game.onLoad();
      game.startRun();

      for (final obs in game.world.children.whereType<Obstacle>().toList()) {
        obs.removeFromParent();
      }

      // Place spike directly overlapping player
      final spike = Obstacle.spike(x: C.playerLeft);
      await game.world.add(spike);

      game.update(1 / 60);

      expect(game.state.value, GameState.dying);
      expect(game.nearMissCount, 0);
      expect(game.bonusScore, 0);
      expect(game.world.children.whereType<PopupText>().isEmpty, isTrue);
    });
  });
}
