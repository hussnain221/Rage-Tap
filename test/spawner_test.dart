import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/core/constants.dart';
import 'package:rage_tap/game/components/obstacle.dart';
import 'package:rage_tap/game/systems/spawner.dart';

void main() {
  group('Spawner unit tests', () {
    test('Seed reproducibility: same seed gives identical sequence and positions', () {
      final spawner1 = Spawner(seed: 42);
      final spawner2 = Spawner(seed: 42);

      final initial1 = spawner1.startRun(isRetry: false, speed: C.baseSpeed);
      final initial2 = spawner2.startRun(isRetry: false, speed: C.baseSpeed);

      expect(initial1.length, initial2.length);
      expect(initial1.first.x, initial2.first.x);
      expect(initial1.first.type, initial2.first.type);
      expect(initial1.first.count, initial2.first.count);

      // Advance both spawners identically
      const dt = 1 / 60;
      for (int i = 0; i < 300; i++) {
        final items1 = spawner1.update(dt, C.baseSpeed, i * dt);
        final items2 = spawner2.update(dt, C.baseSpeed, i * dt);
        expect(items1.length, items2.length);
        for (int j = 0; j < items1.length; j++) {
          expect(items1[j].x, items2[j].x);
          expect(items1[j].type, items2[j].type);
          expect(items1[j].count, items2[j].count);
        }
      }
    });

    test('Safe opening: first hazard arrives after safeOpening seconds', () {
      final spawner = Spawner(seed: 12345);

      // First run: safeOpeningFirstRun (3.0s)
      final firstRunItems = spawner.startRun(isRetry: false, speed: 190);
      expect(firstRunItems.isNotEmpty, isTrue);
      final expectedFirstX = C.playerLeft + C.safeOpeningFirstRun * 190;
      expect(firstRunItems.first.x, expectedFirstX);
      expect(firstRunItems.first.x, greaterThanOrEqualTo(C.worldW + 40));

      // Retry: safeOpeningRetry (2.0s)
      final retryItems = spawner.startRun(isRetry: true, speed: 190);
      expect(retryItems.isNotEmpty, isTrue);
      final expectedRetryX = C.playerLeft + C.safeOpeningRetry * 190;
      expect(retryItems.first.x, expectedRetryX);
      expect(retryItems.first.x, greaterThanOrEqualTo(C.worldW + 40));
    });

    test('Tier unlock: at t < 8s only S1 is chosen; at t >= 8s S2 and B1 unlock', () {
      final spawner = Spawner(seed: 999);

      // At t = 0 to 7.9s, only S1 (spikes count 1) is unlocked
      for (double t = 0.0; t < 8.0; t += 1.0) {
        final pattern = spawner.pickPattern(runTime: t, speed: C.baseSpeed);
        expect(pattern.id, 'S1');
        expect(pattern.items.first.count, 1);
        expect(pattern.items.first.type, ObstacleType.spike);
      }

      // At t >= 8.0s, B1 and S2 unlock
      bool s2Seen = false;
      bool b1Seen = false;
      for (int i = 0; i < 40; i++) {
        final pattern = spawner.pickPattern(runTime: 10.0, speed: C.baseSpeed);
        if (pattern.id == 'S2') s2Seen = true;
        if (pattern.id == 'B1') b1Seen = true;
      }
      expect(s2Seen, isTrue);
      expect(b1Seen, isTrue);
    });

    test('S3 requires minSpeed 255 and t >= 24s', () {
      final spawner = Spawner(seed: 123);

      // At t = 25s but speed = 250 px/s, S3 must NOT be selected
      for (int i = 0; i < 20; i++) {
        final pattern = spawner.pickPattern(runTime: 25.0, speed: 250.0);
        expect(pattern.id != 'S3', isTrue);
      }

      // At t = 25s and speed = 260 px/s (>= 255), S3 can be selected
      bool s3Seen = false;
      for (int i = 0; i < 60; i++) {
        final pattern = spawner.pickPattern(runTime: 25.0, speed: 260.0);
        if (pattern.id == 'S3') {
          s3Seen = true;
          expect(pattern.items.first.count, 3);
          break;
        }
      }
      expect(s3Seen, isTrue);
    });

    test('Consecutive rule: avoids picking same pattern more than twice in a row', () {
      final spawner = Spawner(seed: 777);

      String? lastId;
      int consecutive = 0;
      // Test 100 selections at t = 10s (where S1, S2, B1 are available)
      for (int i = 0; i < 100; i++) {
        final pattern = spawner.pickPattern(runTime: 10.0, speed: C.baseSpeed);
        if (pattern.id == lastId) {
          consecutive++;
          expect(consecutive, lessThanOrEqualTo(2), reason: 'Pattern ${pattern.id} picked > 2 times consecutively');
        } else {
          lastId = pattern.id;
          consecutive = 1;
        }
      }
    });

    test('All spawned items are placed off-screen right (x >= 400)', () {
      final spawner = Spawner(seed: 555);
      final initial = spawner.startRun(isRetry: true, speed: C.baseSpeed);
      for (final item in initial) {
        expect(item.x, greaterThanOrEqualTo(C.worldW + 40));
      }

      const dt = 1 / 60;
      for (int i = 0; i < 600; i++) {
        final items = spawner.update(dt, C.baseSpeed, i * dt);
        for (final item in items) {
          expect(item.x, greaterThanOrEqualTo(C.worldW + 40));
          expect([ObstacleType.spike, ObstacleType.barrier], contains(item.type));
        }
      }
    });
    test('C1 pattern is never picked directly after another C1', () {
      final spawner = Spawner(seed: 42);
      String? lastId;

      for (int i = 0; i < 200; i++) {
        final pattern = spawner.pickPattern(runTime: 30.0, speed: C.baseSpeed);
        if (lastId == 'C1') {
          expect(pattern.id, isNot('C1'), reason: 'C1 was picked immediately after C1');
        }
        lastId = pattern.id;
      }
    });

    test('C1 pattern spawns at telegraphX (360 + 0.7 * chargingSpeed)', () {
      final spawner = Spawner(seed: 12345);
      const speed = 190.0;
      const chargingSpeed = speed + C.chargingExtraSpeed;
      final expectedTelegraphX = C.worldW + C.chargingTelegraphSec * chargingSpeed; // 535.0

      // Run until a charging block is spawned
      const dt = 1 / 60;
      SpawnItem? chargingItem;
      for (int i = 0; i < 2500; i++) {
        final items = spawner.update(dt, speed, 25.0 + i * dt);
        for (final item in items) {
          if (item.type == ObstacleType.charging) {
            chargingItem = item;
            break;
          }
        }
        if (chargingItem != null) break;
      }

      expect(chargingItem, isNotNull);
      expect(chargingItem!.x, expectedTelegraphX);
    });
  });
}
