import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/core/constants.dart';
import 'package:rage_tap/game/components/obstacle.dart';
import 'package:rage_tap/game/components/player.dart';
import 'package:rage_tap/game/game_state.dart';
import 'package:rage_tap/game/rage_tap_game.dart';
import 'package:rage_tap/game/systems/hazard_geometry.dart';

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
    expect(game.lastDeathCause, DeathCause.spike);

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

  test('Player colliding with tall wall sets DeathCause.tallWall', () {
    final game = RageTapGame();
    game.startRun();

    final wall = Obstacle.tallWall(x: C.playerLeft);
    game.world.add(wall);

    game.player.y = Player.groundY;
    game.player.grounded = true;

    game.update(1 / 60);

    expect(game.state.value, GameState.dying);
    expect(game.lastDeathCause, DeathCause.tallWall);

    game.disposeGame();
  });

  test('Standing player under beam passes safely (clearance 16)', () {
    final game = RageTapGame();
    game.startRun();

    // Beam horizontally overlapping with player hitbox [70, 98]
    final beam = Obstacle.beam(x: 54); // hitbox left = 54 + 16 = 70, right = 82
    game.world.add(beam);

    game.player.y = Player.groundY; // 460, hitbox top = 466
    game.player.grounded = true;

    game.update(1 / 60);

    // Standing clearance = 466 - 450 = 16 units; survives
    expect(game.state.value, GameState.playing);
    expect(game.player.hitbox.top, 466.0);
    expect(beam.hitbox.bottom, 450.0);

    game.disposeGame();
  });

  test('Player rising < 16 units (15 units) survives beam', () {
    final game = RageTapGame();
    game.startRun();

    final beam = Obstacle.beam(x: 54);
    game.world.add(beam);

    // Rising 15 units: player.y = 445 -> hitbox top = 451 > beam.bottom (450) -> survives
    game.player.y = 445.0;
    game.player.vy = -30.0;
    game.player.grounded = false;
    game.update(1 / 60);
    expect(game.state.value, GameState.playing);

    game.disposeGame();
  });

  test('Player rising >= 16 units (17 units) collides with beam and sets DeathCause.beam', () {
    final game = RageTapGame();
    game.startRun();

    final beam = Obstacle.beam(x: 54);
    game.world.add(beam);

    // Rising 17 units: player.y = 443 -> hitbox top = 449 < beam.bottom (450) -> collision
    game.player.y = 443.0;
    game.player.vy = -30.0;
    game.player.grounded = false;
    game.update(1 / 60);
    expect(game.state.value, GameState.dying);
    expect(game.lastDeathCause, DeathCause.beam);

    game.disposeGame();
  });

  test('Buffered jump executed under beam collides once player rises >= 16 units', () {
    final game = RageTapGame();
    game.startRun();

    // Place beam directly above player
    final beam = Obstacle.beam(x: 54);
    game.world.add(beam);

    // Player just landed and buffers a jump
    game.player.y = Player.groundY;
    game.player.grounded = true;
    game.player.jumpBufferTimer = C.jumpBufferSec;
    // Execute jump
    game.player.jump();
    game.update(1 / 60);

    // vy = -490, after dt=1/60, dy ~ -8.16, player.y ~ 451.84, rising ~8 units (<16)
    // At this first sub-frame, player hasn't reached 16 units yet
    // If still < 16 units, state is playing
    if (game.player.hitbox.top > beam.hitbox.bottom) {
      expect(game.state.value, GameState.playing);
    }

    // Step next frame: player rises further (dy > 16 units total, player.y <= 444)
    game.update(1 / 60);

    // Now player has risen >= 16 units while overlapping beam -> dies
    expect(game.state.value, GameState.dying);
    expect(game.lastDeathCause, DeathCause.beam);

    game.disposeGame();
  });
}
