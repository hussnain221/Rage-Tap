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

void _assertPairFairness(int seed, int index, _SimHazard a, _SimHazard b) {
  // Pit rules are handled in H4
  if (a.type == HazardType.pit || b.type == HazardType.pit) {
    return;
  }

  // Note: Pattern-level constraints (no beam adjacent to charging/pit, no consecutive
  // beams without ground hazard) are enforced in pattern authoring. Across pattern boundaries,
  // fairness is governed by the arrival timing rules below.

  final arriveDiff = b.arrivalTime! - a.arrivalTime!;

  if (a.type != HazardType.beam && b.type == HazardType.beam) {
    // Ground hazard A -> beam B:
    // B.arrive - A.arrive >= latestGround(H_A) + C.beamReactionSec
    final required = PatternValidator.latestGround(PatternValidator.hazardHitboxHeight(a.type)) +
        C.beamReactionSec;
    expect(
      arriveDiff,
      greaterThanOrEqualTo(required - 0.03),
      reason:
          'Seed $seed pair #$index (A: ${a.type.name} -> B: beam) arrival diff ${arriveDiff.toStringAsFixed(4)}s < required ${required.toStringAsFixed(4)}s',
    );
  } else if (a.type == HazardType.beam && b.type != HazardType.beam) {
    // Beam B -> ground hazard C:
    // (C.arrive - tStart(H_C)) - (B.arrive + (C.beamHitW + 28)/s - tStart(16)) >= C.beamReactionSec
    // AND C.arrive - B.arrive >= C.afterBeamMinDxSec
    expect(
      arriveDiff,
      greaterThanOrEqualTo(C.afterBeamMinDxSec - 0.03),
      reason:
          'Seed $seed pair #$index (A: beam -> B: ${b.type.name}) arrival diff ${arriveDiff.toStringAsFixed(4)}s < afterBeamMinDxSec ${C.afterBeamMinDxSec}s',
    );

    final s = b.arrivalSpeed!;
    final takeoffC = arriveDiff - PatternValidator.tStart(PatternValidator.hazardHitboxHeight(b.type));
    final beamClear = (C.beamHitW + C.playerHitW) / s - PatternValidator.tStart(C.beamSafeHeight);
    final reactionTime = takeoffC - beamClear;
    expect(
      reactionTime,
      greaterThanOrEqualTo(C.beamReactionSec - 0.03),
      reason:
          'Seed $seed pair #$index (A: beam -> B: ${b.type.name}) reaction window ${reactionTime.toStringAsFixed(4)}s < beamReactionSec ${C.beamReactionSec}s',
    );
  } else if (a.type == HazardType.beam && b.type == HazardType.beam) {
    // Both are beams: player stays grounded, no jump required.
    return;
  } else {
    // Both are ground solids (invariant 2)
    final aPassDuration = a.hitboxWidth / a.arrivalSpeed!;
    final gapTime = b.arrivalTime! - (a.arrivalTime! + aPassDuration);
    expect(
      gapTime,
      greaterThanOrEqualTo(PatternValidator.minGapTime - 0.03),
      reason:
          'Seed $seed pair #$index -> #${index + 1} violated Fairness Invariant 2: gap ${gapTime.toStringAsFixed(4)}s < ${PatternValidator.minGapTime}s (A: ${a.type.name} x${a.count} at ${a.arrivalTime!.toStringAsFixed(2)}s, B: ${b.type.name} x${b.count} at ${b.arrivalTime!.toStringAsFixed(2)}s)',
    );
  }
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

      // 2. Assert fairness for all consecutive arrived pairs (invariant 2 and beam rules):
      for (int i = 0; i < arrivedHazards.length - 1; i++) {
        _assertPairFairness(seed, i, arrivedHazards[i], arrivedHazards[i + 1]);
      }
    }
  });

  test('Spawner simulation starting at t=60s (START_TIME=60) across seeds 1..200 satisfies beam rules', () {
    const double dt = 1 / 60;
    const double totalSimulationSec = 120.0;
    const double playerHitboxRight = C.playerLeft + C.playerHitX + C.playerHitW; // 98.0

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
      const startT = 60.0;
      final speed = Difficulty.speed(startT);

      final initialItems = spawner.startRun(isRetry: false, speed: speed, runTime: startT);
      final activeHazards = <_SimHazard>[];
      for (final item in initialItems) {
        activeHazards.add(makeSimHazard(item));
      }

      final arrivedHazards = <_SimHazard>[];
      final steps = (totalSimulationSec / dt).round();

      for (int step = 0; step < steps; step++) {
        final simTime = startT + step * dt;
        final currentSpeed = Difficulty.speed(simTime);

        for (final h in activeHazards) {
          final hSpeed = h.type == HazardType.charging
              ? currentSpeed + C.chargingExtraSpeed
              : currentSpeed;
          h.x -= hSpeed * dt;

          if (h.arrivalTime == null) {
            final eventX = h.x + h.hitboxInsetLeft;
            if (eventX <= playerHitboxRight) {
              h.arrivalTime = simTime;
              h.arrivalSpeed = hSpeed;
              arrivedHazards.add(h);
            }
          }
        }

        activeHazards.removeWhere((h) => h.x + h.hitboxWidth < -20);

        final newItems = spawner.update(dt, currentSpeed, simTime);
        for (final item in newItems) {
          activeHazards.add(makeSimHazard(item));
        }
      }

      for (int i = 0; i < arrivedHazards.length - 1; i++) {
        _assertPairFairness(seed, i, arrivedHazards[i], arrivedHazards[i + 1]);
      }
    }
  });
}
