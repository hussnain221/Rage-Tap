import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/core/constants.dart';
import 'package:rage_tap/game/components/player.dart';

void main() {
  test('Player jump apex height and air time match spec physics', () {
    final player = Player();
    expect(player.grounded, isTrue);
    expect(player.y, Player.groundY);

    player.jump();
    expect(player.grounded, isFalse);
    expect(player.vy, -C.jumpVelocity);

    const dt = 1 / 240;
    double minY = player.y;
    double airTime = 0.0;

    while (!player.grounded) {
      player.step(dt);
      airTime += dt;
      if (player.y < minY) {
        minY = player.y;
      }
    }

    final apexHeight = Player.groundY - minY;

    // Spec §5.2: air time = 2v/g = 0.64 s, apex height ≈ 102
    expect(apexHeight, closeTo(102.4, 2.0));
    expect(airTime, closeTo(0.64, 0.02));
  });

  test('Player cannot double jump mid-air', () {
    final player = Player();
    player.jump();

    const dt = 1 / 60;
    // Step forward 0.2 seconds into the air
    for (int i = 0; i < 12; i++) {
      player.step(dt);
    }

    expect(player.grounded, isFalse);
    final vyBefore = player.vy;

    // Mid-air tap should not reset velocity
    player.jump();
    expect(player.vy, vyBefore);
    expect(player.jumpBufferTimer, C.jumpBufferSec);
  });

  test('Jump buffer triggers jump immediately upon landing if tapped <= 0.10s before', () {
    final player = Player();
    player.jump();

    const dt = 1 / 200;
    double elapsed = 0.0;

    // Step until ~0.58s (airborne, ~0.06s before landing at 0.64s)
    while (elapsed < 0.58) {
      player.step(dt);
      elapsed += dt;
    }
    expect(player.grounded, isFalse);

    // Buffer a tap right before landing
    player.jump();
    expect(player.jumpBufferTimer, C.jumpBufferSec);

    // Continue stepping frame-by-frame until the buffered jump triggers
    bool bufferedJumpTriggered = false;
    while (!bufferedJumpTriggered && elapsed < 1.0) {
      player.step(dt);
      elapsed += dt;
      if (player.jumpBufferTimer == 0 && player.vy == -C.jumpVelocity) {
        bufferedJumpTriggered = true;
      }
    }

    expect(bufferedJumpTriggered, isTrue);
    expect(player.grounded, isFalse);
    expect(player.vy, -C.jumpVelocity);
  });


  test('Jump buffer expires if tapped too early and does not trigger jump on landing', () {
    final player = Player();
    player.jump();

    const dt = 1 / 200;
    double elapsed = 0.0;

    // Step to 0.20s (well before landing)
    while (elapsed < 0.20) {
      player.step(dt);
      elapsed += dt;
    }

    // Tap early (0.44s before landing)
    player.jump();
    expect(player.jumpBufferTimer, C.jumpBufferSec);

    // Step until landing
    while (!player.grounded && elapsed < 1.0) {
      player.step(dt);
      elapsed += dt;
    }

    // Buffer expired, so player stays grounded
    expect(player.grounded, isTrue);
    expect(player.vy, 0.0);
  });

  test('Player hitbox conforms to spec dimensions and world position', () {
    final player = Player();
    final hitbox = player.hitbox;

    expect(hitbox.left, C.playerLeft + C.playerHitX);
    expect(hitbox.top, Player.groundY + C.playerHitY);
    expect(hitbox.width, C.playerHitW);
    expect(hitbox.height, C.playerHitH);
    expect(hitbox.bottom, Player.groundY + C.playerHitY + C.playerHitH);
  });
}
