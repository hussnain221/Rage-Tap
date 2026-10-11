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

  test('Obstacle hitboxes and sizes match spec for all types', () {
    final spike1 = Obstacle.spike(x: 100, count: 1);
    expect(spike1.size.x, C.spikeW);
    expect(spike1.size.y, C.spikeH);
    expect(spike1.y, C.groundTopY - C.spikeH);
    expect(spike1.relativeHitbox.left, C.spikeHitX);
    expect(spike1.relativeHitbox.top, C.spikeHitY);
    expect(spike1.relativeHitbox.width, 24); // 30 - 6
    expect(spike1.relativeHitbox.height, C.spikeHitH);

    final spike3 = Obstacle.spike(x: 100, count: 3);
    expect(spike3.size.x, C.spikeW * 3);
    expect(spike3.relativeHitbox.width, 90 - 6);

    final barrier = Obstacle.barrier(x: 100);
    expect(barrier.size.x, C.barrierW);
    expect(barrier.size.y, C.barrierH);
    expect(barrier.y, C.groundTopY - C.barrierH);
    expect(barrier.relativeHitbox.left, C.barrierHitX);
    expect(barrier.relativeHitbox.top, C.barrierHitY);
    expect(barrier.relativeHitbox.width, C.barrierHitW);
    expect(barrier.relativeHitbox.height, C.barrierHitH);

    final charging = Obstacle.charging(x: 100);
    expect(charging.size.x, C.chargeW);
    expect(charging.size.y, C.chargeH);
    expect(charging.y, C.groundTopY - C.chargeH);
    expect(charging.relativeHitbox.left, C.chargeHitX);
    expect(charging.relativeHitbox.top, C.chargeHitY);
    expect(charging.relativeHitbox.width, C.chargeHitW);
    expect(charging.relativeHitbox.height, C.chargeHitH);
  });

  test('Obstacle moves at correct speed and charging has extra speed', () {
    final spike = Obstacle.spike(x: 200);
    spike.move(190, 0.1);
    expect(spike.x, closeTo(200 - 190 * 0.1, 0.001));

    final charging = Obstacle.charging(x: 200);
    charging.move(190, 0.1);
    expect(charging.x, closeTo(200 - (190 + C.chargingExtraSpeed) * 0.1, 0.001));
  });

  test('Collision with spike causes death and transitions to results', () {
    final game = RageTapGame();
    game.startRun();
    expect(game.state.value, GameState.playing);

    // Place obstacle directly colliding with player (at x = 64)
    final collidingSpike = Obstacle.spike(x: C.playerLeft);
    game.world.add(collidingSpike);

    // Make player grounded at impact position
    game.player.y = Player.groundY;
    game.player.grounded = true;

    // Step 1 frame
    game.update(1 / 60);

    // Player should immediately enter dying state
    expect(game.state.value, GameState.dying);
    expect(game.lastDeathCause, ObstacleType.spike);

    // After 0.40s death sequence (hit freeze 0.10s + death anim 0.30s), transition to results
    _advance(game, 0.41);
    expect(game.state.value, GameState.results);

    game.disposeGame();
  });

  test('Player jumping over spike avoids collision and continues playing', () {
    final game = RageTapGame();
    game.startRun(); // This calls player.jump()

    // Place spike at x = 120, well ahead of player (at x = 64)
    final spike = Obstacle.spike(x: 120);
    game.world.add(spike);

    // Advance 0.25 seconds while player is near jump apex
    _advance(game, 0.25);

    // Apex height is ~102, player y is ~358, well above spike top at 472
    expect(game.player.y, lessThan(400));
    expect(game.state.value, GameState.playing); // Did not die!

    game.disposeGame();
  });
}
