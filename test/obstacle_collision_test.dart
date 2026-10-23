import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/core/constants.dart';
import 'package:rage_tap/game/components/obstacle.dart';
import 'package:rage_tap/game/components/player.dart';
import 'package:rage_tap/game/game_state.dart';
import 'package:rage_tap/game/rage_tap_game.dart';
import 'package:rage_tap/game/systems/hazard_geometry.dart';
import 'package:rage_tap/game/systems/pattern.dart';
import 'package:rage_tap/game/systems/spawner.dart';

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

  test('Grounded player entering pit hole falls and dies with DeathCause.pit', () {
    final game = RageTapGame();
    game.state.value = GameState.playing;
    game.player.y = Player.groundY;
    game.player.vy = 0.0;
    game.player.grounded = true;
    expect(game.player.isFalling, isFalse);

    // Player center is at 84 (player.x = 64, hitX = 6, hitW = 28 -> center = 84)
    // Pit at x = 40, width = 80: hole is [40, 120], danger interval is (46, 114).
    final pit = Obstacle.pit(x: 40, width: C.pitShortW);
    game.world.add(pit);

    game.update(1 / 60);

    expect(game.state.value, GameState.dying);
    expect(game.lastDeathCause, DeathCause.pit);
    expect(game.player.isFalling, isTrue);

    // While dying from pit, player physics continues: vy increases with gravity and y drops below ground
    final yAtDeath = game.player.y;
    _advance(game, 0.20);
    expect(game.player.y, greaterThan(yAtDeath));
    expect(game.state.value, GameState.dying);

    // Results overlay appears after 0.55s
    _advance(game, 0.36);
    expect(game.state.value, GameState.results);

    game.disposeGame();
  });

  test('Airborne player crossing pit hole does not fall', () {
    final game = RageTapGame();
    game.state.value = GameState.playing;

    final pit = Obstacle.pit(x: 40, width: C.pitShortW);
    game.world.add(pit);

    game.player.y = 400.0;
    game.player.vy = -100.0;
    game.player.grounded = false;

    game.update(1 / 60);

    expect(game.state.value, GameState.playing);
    expect(game.player.isFalling, isFalse);

    game.disposeGame();
  });

  test('Player landing inside pit hole falls immediately', () {
    final game = RageTapGame();
    game.state.value = GameState.playing;

    final pit = Obstacle.pit(x: 40, width: C.pitShortW);
    game.world.add(pit);

    game.player.y = Player.groundY - 1.0;
    game.player.vy = 200.0;
    game.player.grounded = false;

    game.update(1 / 60);

    expect(game.state.value, GameState.dying);
    expect(game.lastDeathCause, DeathCause.pit);
    expect(game.player.isFalling, isTrue);

    game.disposeGame();
  });

  test('Buffered jump on landing inside pit hole prevents fall (intended forgiveness)', () {
    final game = RageTapGame();
    game.state.value = GameState.playing;

    final pit = Obstacle.pit(x: 40, width: C.pitShortW);
    game.world.add(pit);

    game.player.y = Player.groundY - 1.0;
    game.player.vy = 200.0;
    game.player.grounded = false;
    // Buffer a jump right before landing
    game.player.jumpBufferTimer = C.jumpBufferSec;

    game.update(1 / 60);

    // Player landed and buffered jump resolved in the same step, making player airborne before fall check
    expect(game.player.grounded, isFalse);
    expect(game.player.isFalling, isFalse);
    expect(game.state.value, GameState.playing);

    game.disposeGame();
  });

  test('Jump timing at window edges for short pit at speed 300', () {
    // Speed 300 (runTime >= 80). Short pit W = 80. Moves 5 units/frame (1/60s).
    // Starting pit at x = 300:
    // Danger interval is pit.x in (10, 78).
    // Frame 46: pit.x enters danger (< 78).
    // Frame 60: pit.x exits danger (< 10).
    // Jump airborne span is 39 frames (0.65s).
    const quietPattern = Pattern(
      id: 'QUIET',
      tierStart: 0,
      minSpeed: 0,
      weight: 1,
      items: [PatternItem(type: HazardType.spike, dxSeconds: 9999)],
    );

    // Case 1: Late edge just inside window -> jump at t = 0.70s (frame 42, before danger).
    // Lands at frame 81 (well past frame 60 exit). Survives.
    {
      final game = RageTapGame(spawner: Spawner(library: const [quietPattern], enableLogging: false));
      game.state.value = GameState.playing;
      game.runTime = 80.0;
      game.player.y = Player.groundY;
      game.player.vy = 0.0;
      game.player.grounded = true;
      final pit = Obstacle.pit(x: 300, width: C.pitShortW);
      game.world.add(pit);

      // Stand until 0.70s
      _advance(game, 0.70);
      expect(game.state.value, GameState.playing);
      // Jump before danger enters
      game.player.jump();
      // Advance past landing and danger exit
      _advance(game, 0.70);
      expect(game.state.value, GameState.playing);
      game.disposeGame();
    }

    // Case 2: Late edge just outside window -> no jump before danger -> falls at frame 46 (~0.77s)
    {
      final game = RageTapGame(spawner: Spawner(library: const [quietPattern], enableLogging: false));
      game.state.value = GameState.playing;
      game.runTime = 80.0;
      game.player.y = Player.groundY;
      game.player.vy = 0.0;
      game.player.grounded = true;
      final pit = Obstacle.pit(x: 300, width: C.pitShortW);
      game.world.add(pit);

      // Do not jump; advance past danger entry (0.80s > 0.767s)
      _advance(game, 0.80);
      expect(game.state.value, GameState.dying);
      expect(game.lastDeathCause, DeathCause.pit);
      game.disposeGame();
    }

    // Case 3: Early edge just outside window -> jump early at t = 0.30s (frame 18)
    // Lands at frame 57 (danger still active until frame 60) -> falls upon landing!
    {
      final game = RageTapGame(spawner: Spawner(library: const [quietPattern], enableLogging: false));
      game.state.value = GameState.playing;
      game.runTime = 80.0;
      game.player.y = Player.groundY;
      game.player.vy = 0.0;
      game.player.grounded = true;
      final pit = Obstacle.pit(x: 300, width: C.pitShortW);
      game.world.add(pit);

      _advance(game, 0.30);
      expect(game.state.value, GameState.playing);
      game.player.jump();
      // Advance to landing (0.66s later, frame 57)
      _advance(game, 0.68);
      expect(game.state.value, GameState.dying);
      expect(game.lastDeathCause, DeathCause.pit);
      game.disposeGame();
    }

    // Case 4: Early edge just inside window -> jump at t = 0.36s (frame 22)
    // Lands at frame 61 (after pit exited at frame 60) -> lands safely on solid ground!
    {
      final game = RageTapGame(spawner: Spawner(library: const [quietPattern], enableLogging: false));
      game.state.value = GameState.playing;
      game.runTime = 80.0;
      game.player.y = Player.groundY;
      game.player.vy = 0.0;
      game.player.grounded = true;
      final pit = Obstacle.pit(x: 300, width: C.pitShortW);
      game.world.add(pit);

      _advance(game, 0.36);
      expect(game.state.value, GameState.playing);
      game.player.jump();
      // Advance past landing (0.68s later, frame 62)
      _advance(game, 0.68);
      expect(game.state.value, GameState.playing);
      game.disposeGame();
    }
  });

  test('Retry after falling resets everything and best score is saved correctly', () async {
    final game = RageTapGame();
    game.state.value = GameState.playing;
    game.player.y = Player.groundY;
    game.player.vy = 0.0;
    game.player.grounded = true;

    // Accumulate score (2000 distance / 40 = 50 points)
    game.distance = 2000.0;
    game.score.value = 50;

    // Fall into pit
    final pit = Obstacle.pit(x: 40, width: C.pitShortW);
    game.world.add(pit);
    game.update(1 / 60);

    expect(game.state.value, GameState.dying);
    expect(game.player.isFalling, isTrue);

    // Transition to results
    _advance(game, 0.60);
    expect(game.state.value, GameState.results);
    expect(game.bestScore.value, greaterThanOrEqualTo(50));

    // Retry
    game.retry();
    expect(game.state.value, GameState.playing);
    expect(game.player.y, Player.groundY);
    expect(game.player.vy, 0.0);
    expect(game.player.grounded, isTrue);
    expect(game.player.isFalling, isFalse);

    game.disposeGame();
  });
}
