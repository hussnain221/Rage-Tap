import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/core/constants.dart';
import 'package:rage_tap/game/components/obstacle.dart';
import 'package:rage_tap/game/systems/difficulty.dart';
import 'package:rage_tap/game/systems/pattern_validator.dart';
import 'package:rage_tap/game/systems/spawner.dart';

class _SimHazard {
  final ObstacleType type;
  final int count;
  double x;
  final double hitboxWidth;
  double? arrivalTime;
  double? arrivalSpeed;

  _SimHazard({
    required this.type,
    required this.count,
    required this.x,
    required this.hitboxWidth,
  });
}

void main() {
  test('Spawner headless simulation over 120s across seeds 1..200 satisfies fairness invariant 2 and safe opening', () {
    const double dt = 1 / 60;
    const double totalSimulationSec = 120.0;
    const double playerHitboxRight = C.playerLeft + C.playerHitX + C.playerHitW; // 98.0
    const double requiredGap = PatternValidator.minGapTime; // 0.89 s

    for (int seed = 1; seed <= 200; seed++) {
      final spawner = Spawner(seed: seed, enableLogging: false);
      final activeHazards = <_SimHazard>[];
      final arrivedHazards = <_SimHazard>[];

      double simTime = 0.0;
      double speed = Difficulty.speed(simTime);

      // Start run with safe opening
      final initialItems = spawner.startRun(isRetry: false, speed: speed);
      for (final item in initialItems) {
        activeHazards.add(_SimHazard(
          type: item.type,
          count: item.count,
          x: item.x,
          hitboxWidth: PatternValidator.groupHitboxWidth(item.type, item.count),
        ));
      }

      while (simTime < totalSimulationSec) {
        simTime += dt;
        speed = Difficulty.speed(simTime);

        // Move active hazards
        for (final h in activeHazards) {
          final hSpeed = h.type == ObstacleType.charging
              ? speed + C.chargingExtraSpeed
              : speed;
          h.x -= hSpeed * dt;
          if (h.arrivalTime == null && h.x <= playerHitboxRight) {
            h.arrivalTime = simTime;
            h.arrivalSpeed = hSpeed;
            arrivedHazards.add(h);
          }
        }

        // Remove hazards that have moved off-screen to keep active list tiny
        activeHazards.removeWhere((h) => h.x + h.hitboxWidth < -20);

        // Update spawner
        final newItems = spawner.update(dt, speed, simTime);
        for (final item in newItems) {
          activeHazards.add(_SimHazard(
            type: item.type,
            count: item.count,
            x: item.x,
            hitboxWidth: PatternValidator.groupHitboxWidth(item.type, item.count),
          ));
        }
      }

      // 1. Assert safe opening time: first hazard arrives after ~3.0s (>= 2.7s allowing hitbox inset and acceleration)
      expect(
        arrivedHazards.isNotEmpty,
        isTrue,
        reason: 'Seed $seed spawned no hazards',
      );
      final firstArrival = arrivedHazards.first.arrivalTime!;
      expect(
        firstArrival,
        greaterThanOrEqualTo(2.7),
        reason: 'Seed $seed first hazard arrived too early at ${firstArrival.toStringAsFixed(3)}s (expected ~3.0s safe opening)',
      );

      // 2. Assert Fairness Invariant 2 for every consecutive hazard pair:
      // gapTime = B.arrivalTime - (A.arrivalTime + A.width / A.s_rel) >= 0.89s
      for (int i = 0; i < arrivedHazards.length - 1; i++) {
        final a = arrivedHazards[i];
        final b = arrivedHazards[i + 1];

        final aPassDuration = a.hitboxWidth / a.arrivalSpeed!;
        final gapTime = b.arrivalTime! - (a.arrivalTime! + aPassDuration);

        // Allow 0.03s tolerance for discrete 1/60s simulation dt steps
        expect(
          gapTime,
          greaterThanOrEqualTo(requiredGap - 0.03),
          reason: 'Seed $seed pair #$i -> #${i + 1} violated Fairness Invariant 2: gap ${gapTime.toStringAsFixed(4)}s < ${requiredGap}s (A: ${a.type.name} x${a.count} at ${a.arrivalTime!.toStringAsFixed(2)}s, B: ${b.type.name} x${b.count} at ${b.arrivalTime!.toStringAsFixed(2)}s)',
        );
      }
    }
  });
}
