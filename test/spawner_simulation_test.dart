import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/core/constants.dart';
import 'package:rage_tap/game/systems/difficulty.dart';
import 'package:rage_tap/game/systems/hazard_geometry.dart';
import 'package:rage_tap/game/systems/pattern_validator.dart';
import 'package:rage_tap/game/systems/spawner.dart';

class _SimHazard {
  final HazardType type;
  final int count;
  final double pitWidth;
  double x;
  final double hitboxInsetLeft;
  final double hitboxWidth;
  double? arrivalTime;
  double? arrivalSpeed;

  _SimHazard({
    required this.type,
    required this.count,
    this.pitWidth = 0.0,
    required this.x,
    required this.hitboxInsetLeft,
    required this.hitboxWidth,
  });
}

double? _requiredMinGap(_SimHazard a, _SimHazard b) {
  // Beam and pit rules are handled in H3 and H4
  if (a.type == HazardType.beam ||
      b.type == HazardType.beam ||
      a.type == HazardType.pit ||
      b.type == HazardType.pit) {
    return null; // Not applicable yet
  }
  // Ground-solid rule (invariant 2)
  return PatternValidator.minGapTime; // 0.89s
}

void main() {
  test('Spawner headless simulation over 120s across seeds 1..200 satisfies fairness invariant 2 and safe opening', () {
    const double dt = 1 / 60;
    const double totalSimulationSec = 120.0;
    const double playerHitboxRight = C.playerLeft + C.playerHitX + C.playerHitW; // 98.0
    const double playerCenter = C.playerLeft + C.playerHitX + C.playerHitW / 2; // 84.0

    _SimHazard makeSimHazard(SpawnItem item) {
      final geo = geometryFor(item.type, count: item.count, pitWidth: item.pitWidth);
      return _SimHazard(
        type: item.type,
        count: item.count,
        pitWidth: item.pitWidth,
        x: item.x,
        hitboxInsetLeft: geo.relativeHitbox.left,
        hitboxWidth: PatternValidator.groupHitboxWidth(item.type, item.count, item.pitWidth),
      );
    }

    for (int seed = 1; seed <= 200; seed++) {
      final spawner = Spawner(seed: seed, enableLogging: false);
      final activeHazards = <_SimHazard>[];
      final arrivedHazards = <_SimHazard>[];

      double simTime = 0.0;
      double speed = Difficulty.speed(simTime);

      // Start run with safe opening
      final initialItems = spawner.startRun(isRetry: false, speed: speed);
      for (final item in initialItems) {
        activeHazards.add(makeSimHazard(item));
      }

      while (simTime < totalSimulationSec) {
        simTime += dt;
        speed = Difficulty.speed(simTime);

        // Move active hazards and track arrivals
        for (final h in activeHazards) {
          final hSpeed = h.type == HazardType.charging
              ? speed + C.chargingExtraSpeed
              : speed;
          h.x -= hSpeed * dt;

          if (h.arrivalTime == null) {
            final double arrivalThreshold;
            final double eventX;
            if (h.type == HazardType.pit) {
              arrivalThreshold = playerCenter;
              eventX = h.x + C.pitCenterInset; // pitEnter measured at player center
            } else {
              arrivalThreshold = playerHitboxRight;
              eventX = h.x + h.hitboxInsetLeft; // hitbox left edge reaching player hitbox right edge
            }

            if (eventX <= arrivalThreshold) {
              h.arrivalTime = simTime;
              h.arrivalSpeed = hSpeed;
              arrivedHazards.add(h);
            }
          }
        }

        // Remove hazards that have moved off-screen to keep active list tiny
        activeHazards.removeWhere((h) => h.x + h.hitboxWidth < -20);

        // Update spawner
        final newItems = spawner.update(dt, speed, simTime);
        for (final item in newItems) {
          activeHazards.add(makeSimHazard(item));
        }
      }

      // 1. Assert safe opening time: first hazard arrives after ~3.0s (>= 2.7s allowing discrete dt steps)
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

      // 2. Assert Fairness Invariant 2 for consecutive arrived pairs:
      for (int i = 0; i < arrivedHazards.length - 1; i++) {
        final a = arrivedHazards[i];
        final b = arrivedHazards[i + 1];

        final minGap = _requiredMinGap(a, b);
        if (minGap != null) {
          final aPassDuration = a.hitboxWidth / a.arrivalSpeed!;
          final gapTime = b.arrivalTime! - (a.arrivalTime! + aPassDuration);

          // Allow 0.03s tolerance for discrete 1/60s simulation dt steps
          expect(
            gapTime,
            greaterThanOrEqualTo(minGap - 0.03),
            reason: 'Seed $seed pair #$i -> #${i + 1} violated Fairness Invariant 2: gap ${gapTime.toStringAsFixed(4)}s < ${minGap}s (A: ${a.type.name} x${a.count} at ${a.arrivalTime!.toStringAsFixed(2)}s, B: ${b.type.name} x${b.count} at ${b.arrivalTime!.toStringAsFixed(2)}s)',
          );
        }
      }
    }
  });
}
