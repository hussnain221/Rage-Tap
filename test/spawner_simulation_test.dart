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
  double? pitEnterTime;
  double? pitExitTime;

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
  // Assert: no beam adjacent to charging block or pit
  if (a.type == HazardType.beam) {
    expect(
      b.type != HazardType.charging && b.type != HazardType.pit,
      isTrue,
      reason: 'Seed $seed pair #$index: beam immediately followed by ${b.type.name}',
    );
  }
  if (b.type == HazardType.beam) {
    expect(
      a.type != HazardType.charging && a.type != HazardType.pit,
      isTrue,
      reason: 'Seed $seed pair #$index: ${a.type.name} immediately followed by beam',
    );
  }

  if (a.type == HazardType.pit && b.type == HazardType.pit) {
    final gap = b.pitEnterTime! - a.pitExitTime!;
    expect(
      gap,
      greaterThanOrEqualTo(PatternValidator.minGapTime - 0.03),
      reason:
          'Seed $seed pair #$index (pit -> pit) gap ${gap.toStringAsFixed(4)}s < ${PatternValidator.minGapTime}s',
    );
    return;
  }

  if (a.type == HazardType.pit && b.type != HazardType.pit && b.type != HazardType.beam) {
    final gap = b.arrivalTime! - a.pitExitTime!;
    expect(
      gap,
      greaterThanOrEqualTo(PatternValidator.minGapTime - 0.03),
      reason:
          'Seed $seed pair #$index (pit -> ${b.type.name}) gap ${gap.toStringAsFixed(4)}s < ${PatternValidator.minGapTime}s',
    );
    return;
  }

  if (a.type != HazardType.pit && a.type != HazardType.beam && b.type == HazardType.pit) {
    final aPassDuration = a.hitboxWidth / a.arrivalSpeed!;
    final gap = b.pitEnterTime! - (a.arrivalTime! + aPassDuration);
    expect(
      gap,
      greaterThanOrEqualTo(PatternValidator.minGapTime - 0.03),
      reason:
          'Seed $seed pair #$index (${a.type.name} -> pit) gap ${gap.toStringAsFixed(4)}s < ${PatternValidator.minGapTime}s',
    );
    return;
  }

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

void _runHeadlessSimulation({
  required int seed,
  required double startTime,
  required double totalSimulationSec,
}) {
  const double dt = 1 / 60;
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

  final spawner = Spawner(seed: seed, enableLogging: false);
  final speed = Difficulty.speed(startTime);
  final initialItems = spawner.startRun(isRetry: false, speed: speed, runTime: startTime);
  final activeHazards = <_SimHazard>[];
  for (final item in initialItems) {
    activeHazards.add(makeSimHazard(item));
  }

  final arrivedHazards = <_SimHazard>[];
  final steps = (totalSimulationSec / dt).round();

  for (int step = 0; step < steps; step++) {
    final simTime = startTime + step * dt;
    final currentSpeed = Difficulty.speed(simTime);

    for (final h in activeHazards) {
      final hSpeed = h.type == HazardType.charging
          ? currentSpeed + C.chargingExtraSpeed
          : currentSpeed;
      h.x -= hSpeed * dt;

      if (h.type == HazardType.pit) {
        if (h.pitEnterTime == null && (h.x + C.pitCenterInset <= playerCenter)) {
          h.pitEnterTime = simTime;
          h.arrivalTime = simTime;
          h.arrivalSpeed = hSpeed;
          arrivedHazards.add(h);
        }
        if (h.pitExitTime == null && (h.x + h.pitWidth - C.pitCenterInset <= playerCenter)) {
          h.pitExitTime = simTime;
        }
      } else {
        if (h.arrivalTime == null) {
          final eventX = h.x + h.hitboxInsetLeft;
          if (eventX <= playerHitboxRight) {
            h.arrivalTime = simTime;
            h.arrivalSpeed = hSpeed;
            arrivedHazards.add(h);
          }
        }
      }
    }

    activeHazards.removeWhere((h) => h.x + h.hitboxWidth < -20);

    final newItems = spawner.update(dt, currentSpeed, simTime);
    for (final item in newItems) {
      activeHazards.add(makeSimHazard(item));
    }
  }

  // 1. Safe opening check (runs starting at 0)
  if (startTime == 0.0 && arrivedHazards.isNotEmpty) {
    final firstArrival = arrivedHazards.first.arrivalTime!;
    expect(
      firstArrival,
      greaterThanOrEqualTo(2.7),
      reason:
          'Seed $seed first hazard arrived too early at ${firstArrival.toStringAsFixed(3)}s (expected >= 2.7s safe opening)',
    );
  }

  // 2. Pattern repetition: no pattern repeated more than twice in a row
  // 2. Pattern repetition: no pattern repeated more than twice in a row (once alternatives exist at t >= 8s)
  final history = spawner.patternHistory;
  for (int i = 0; i < history.length - 2; i++) {
    final p1 = history[i];
    final p2 = history[i + 1];
    final p3 = history[i + 2];
    if (startTime == 0.0 && p1 == 'S1' && i < 6) {
      // S1 is the only pattern in Tier 0 (0..8s)
      continue;
    }
    expect(
      p1 == p2 && p2 == p3,
      isFalse,
      reason:
          'Seed $seed (start $startTime) pattern $p1 repeated 3 times in a row at index $i: $history',
    );
  }

  // 3. Intro rule: first occurrence of tallWall, beam, pit in a run must be its intro pattern
  String? firstTallWallPattern;
  String? firstBeamPattern;
  String? firstPitPattern;
  for (final id in history) {
    final pattern = spawner.library.firstWhere((p) => p.id == id);
    if (firstTallWallPattern == null && pattern.items.any((i) => i.type == HazardType.tallWall)) {
      firstTallWallPattern = id;
    }
    if (firstBeamPattern == null && pattern.items.any((i) => i.type == HazardType.beam)) {
      firstBeamPattern = id;
    }
    if (firstPitPattern == null && pattern.items.any((i) => i.type == HazardType.pit)) {
      firstPitPattern = id;
    }
  }
  if (firstTallWallPattern != null) {
    expect(firstTallWallPattern, equals('W1'),
        reason:
            'Seed $seed (start $startTime) first tall wall pattern was $firstTallWallPattern, expected W1');
  }
  if (firstBeamPattern != null) {
    expect(firstBeamPattern, equals('D1'),
        reason:
            'Seed $seed (start $startTime) first beam pattern was $firstBeamPattern, expected D1');
  }
  if (firstPitPattern != null) {
    expect(firstPitPattern, equals('PIT1'),
        reason:
            'Seed $seed (start $startTime) first pit pattern was $firstPitPattern, expected PIT1');
  }

  // 4. Consecutive hazard pair fairness and adjacency
  for (int i = 0; i < arrivedHazards.length - 1; i++) {
    _assertPairFairness(seed, i, arrivedHazards[i], arrivedHazards[i + 1]);
  }
}

void main() {
  test('Master simulation: Spawner over 180s across seeds 1..300 satisfies all rules', () {
    for (int seed = 1; seed <= 300; seed++) {
      _runHeadlessSimulation(seed: seed, startTime: 0.0, totalSimulationSec: 180.0);
    }
  });

  test('Master simulation starting at START_TIME=28s (Tall Wall) across seeds 1..100 satisfies all rules', () {
    for (int seed = 1; seed <= 100; seed++) {
      _runHeadlessSimulation(seed: seed, startTime: 28.0, totalSimulationSec: 60.0);
    }
  });

  test('Master simulation starting at START_TIME=36s (Beam) across seeds 1..100 satisfies all rules', () {
    for (int seed = 1; seed <= 100; seed++) {
      _runHeadlessSimulation(seed: seed, startTime: 36.0, totalSimulationSec: 60.0);
    }
  });

  test('Master simulation starting at START_TIME=45s (Pit) across seeds 1..100 satisfies all rules', () {
    for (int seed = 1; seed <= 100; seed++) {
      _runHeadlessSimulation(seed: seed, startTime: 45.0, totalSimulationSec: 60.0);
    }
  });

  test('Master simulation starting at START_TIME=60s across seeds 1..100 satisfies all rules', () {
    for (int seed = 1; seed <= 100; seed++) {
      _runHeadlessSimulation(seed: seed, startTime: 60.0, totalSimulationSec: 60.0);
    }
  });

  test('Master simulation starting at START_TIME=80s across seeds 1..100 satisfies all rules', () {
    for (int seed = 1; seed <= 100; seed++) {
      _runHeadlessSimulation(seed: seed, startTime: 80.0, totalSimulationSec: 60.0);
    }
  });
}
