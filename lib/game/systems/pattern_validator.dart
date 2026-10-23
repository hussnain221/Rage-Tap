import 'dart:math' as math;

import '../../core/constants.dart';
import '../components/obstacle.dart';
import 'hazard_geometry.dart';
import 'pattern.dart';

class PatternValidator {
  static const double v = C.jumpVelocity;
  static const double g = C.gravity;
  static const double tAir = 2 * v / g; // 0.64s
  static const double minGapTime = tAir + C.separateJumpReactionSec; // 0.89s

  /// Time after takeoff when the player hitbox bottom rises above height H:
  /// tStart(H) = (v - sqrt(v^2 - 2 * g * H)) / g
  static double tStart(double h) {
    final discriminant = v * v - 2 * g * h;
    if (discriminant < 0) return double.infinity;
    return (v - math.sqrt(discriminant)) / g;
  }

  /// Time the player's hitbox bottom stays above height H:
  /// clearTime(H) = 2 * sqrt(v^2 - 2 * g * H) / g
  static double clearTime(double h) {
    final discriminant = v * v - 2 * g * h;
    if (discriminant <= 0) return 0.0;
    return 2 * math.sqrt(discriminant) / g;
  }

  /// Latest grounded time after clearing hazard of height H:
  /// latestGround(H) = T_air - tStart(H) - tStart(16)
  static double latestGround(double h) {
    return tAir - tStart(h) - tStart(C.beamSafeHeight);
  }

  /// Timing window for crossing a pit of width W at relative speed s:
  /// pitWindow(W, s) = (T_air - 2 * tStart(C.airborneThreshold)) - (W - 2 * C.pitCenterInset) / s
  static double pitWindow(double w, double s) {
    final airSpan = tAir - 2 * tStart(C.airborneThreshold);
    return airSpan - (w - 2 * C.pitCenterInset) / s;
  }

  /// Hitbox width of a hazard or hazard group:
  /// Spikes(n): 24n + 6(n - 1)
  /// Barrier: 24
  /// TallWall: 24
  /// Charging: 26
  /// Beam: 12
  /// Pit: W
  static double groupHitboxWidth(HazardType type, int count, [double pitWidth = 0.0]) {
    switch (type) {
      case HazardType.spike:
        return 24.0 * count + 6.0 * (count - 1);
      case HazardType.barrier:
        return C.barrierHitW;
      case HazardType.tallWall:
        return C.tallHitW;
      case HazardType.charging:
        return C.chargeHitW;
      case HazardType.beam:
        return C.beamHitW;
      case HazardType.pit:
        return pitWidth > 0 ? pitWidth : C.pitShortW;
    }
  }

  /// Hitbox inset left relative to component origin
  static double hitboxInsetLeft(HazardType type) {
    switch (type) {
      case HazardType.spike:
      case HazardType.barrier:
      case HazardType.tallWall:
        return 3.0;
      case HazardType.charging:
        return 4.0;
      case HazardType.beam:
        return 16.0;
      case HazardType.pit:
        return 0.0;
    }
  }

  /// Hitbox height of hazard
  static double hazardHitboxHeight(HazardType type) {
    switch (type) {
      case HazardType.spike:
        return C.spikeHitH; // 22
      case HazardType.barrier:
        return C.barrierHitH; // 53
      case HazardType.tallWall:
        return C.tallHitH; // 65
      case HazardType.charging:
        return C.chargeHitH; // 30
      case HazardType.beam:
        return C.beamBottomY - C.beamHitTopY; // 324
      case HazardType.pit:
        return 0.0;
    }
  }

  /// Relative speed sRel = scroll speed (or scroll + 60 for charging block)
  static double relativeSpeed(HazardType type, double scrollSpeed) {
    switch (type) {
      case HazardType.spike:
      case HazardType.barrier:
      case HazardType.tallWall:
      case HazardType.beam:
      case HazardType.pit:
        return scrollSpeed;
      case HazardType.charging:
        return scrollSpeed + C.chargingExtraSpeed;
    }
  }

  /// Timing window (seconds) for clearing a single-jump group:
  /// window = clearTime(H) - (groupHitboxWidth + 28) / sRel
  static double timingWindow({
    required HazardType type,
    required int count,
    required double sRel,
    double pitWidth = 0.0,
  }) {
    if (type == HazardType.pit) {
      return pitWindow(pitWidth > 0 ? pitWidth : C.pitShortW, sRel);
    }
    final h = hazardHitboxHeight(type);
    final w = groupHitboxWidth(type, count, pitWidth);
    return clearTime(h) - (w + C.playerHitW) / sRel;
  }

  /// Gap time between consecutive hazards A and B that require separate jumps:
  /// gapTime = B.arrivalTime - (A.arrivalTime + A.width / A.sRel)
  static double separateJumpGapTime({
    required double aArrivalTime,
    required double aWidth,
    required double aRelSpeed,
    required double bArrivalTime,
  }) {
    return bArrivalTime - (aArrivalTime + aWidth / aRelSpeed);
  }

  /// Calculates gap time between two items within the same pattern at a given speed
  static double intraPatternGapTime({
    required PatternItem a,
    required PatternItem b,
    required double speed,
  }) {
    final sRelA = relativeSpeed(a.type, speed);
    final sRelB = relativeSpeed(b.type, speed);
    final dxSec = b.dxSeconds - a.dxSeconds;
    final widthA = groupHitboxWidth(a.type, a.count, a.pitWidth);

    if (sRelA == sRelB) {
      return dxSec - (widthA / sRelA);
    } else {
      final dxPx = dxSec * speed;
      final arrivalB = dxPx / sRelB;
      return arrivalB - (widthA / sRelA);
    }
  }

  /// Validates a pattern across the specified speed range.
  /// Returns a list of violation strings (empty = valid).
  static List<String> validatePattern(
    Pattern pattern, {
    double minSpeed = C.baseSpeed,
    double maxSpeed = C.maxSpeed,
    double speedStep = 10.0,
  }) {
    final violations = <String>[];
    final effectiveMinSpeed = math.max(minSpeed, pattern.minSpeed);

    for (double speed = effectiveMinSpeed; speed <= maxSpeed + 0.001; speed += speedStep) {
      // Fairness Invariant 1: timingWindow >= 0.12s (for solid ground hazards and pits)
      for (int i = 0; i < pattern.items.length; i++) {
        final item = pattern.items[i];
        if (item.type == HazardType.beam) continue;

        final sRel = relativeSpeed(item.type, speed);
        final window = timingWindow(
          type: item.type,
          count: item.count,
          sRel: sRel,
          pitWidth: item.pitWidth,
        );
        if (window < C.minTimingWindowSec - 0.0001) {
          violations.add(
            'Pattern ${pattern.id} item #$i (${item.type.name} x${item.count}) timing window ${window.toStringAsFixed(4)}s < ${C.minTimingWindowSec}s at speed ${speed.toStringAsFixed(1)}',
          );
        }
      }

      // Fairness Invariant 2 & Beam / Pit gap rules
      for (int i = 0; i < pattern.items.length - 1; i++) {
        final a = pattern.items[i];
        final b = pattern.items[i + 1];

        // Rule: Beam is never adjacent to a charging block or pit
        if ((a.type == HazardType.beam && (b.type == HazardType.charging || b.type == HazardType.pit)) ||
            (b.type == HazardType.beam && (a.type == HazardType.charging || a.type == HazardType.pit))) {
          violations.add(
            'Pattern ${pattern.id} has beam adjacent to charging block or pit between #$i and #${i + 1}',
          );
          continue;
        }

        // Rule: Beam is never adjacent to another beam without a ground hazard between
        if (a.type == HazardType.beam && b.type == HazardType.beam) {
          violations.add(
            'Pattern ${pattern.id} has consecutive beams without ground hazard between #$i and #${i + 1}',
          );
          continue;
        }

        if (a.type != HazardType.beam && b.type == HazardType.beam) {
          // Ground hazard A -> beam B:
          // B.arrive - A.arrive >= latestGround(H_A) + C.beamReactionSec
          final bArriveMinusAArrive = (b.dxSeconds - a.dxSeconds) +
              (hitboxInsetLeft(b.type) - hitboxInsetLeft(a.type)) / speed;
          final required = latestGround(hazardHitboxHeight(a.type)) + C.beamReactionSec;
          if (bArriveMinusAArrive < required - 0.0001) {
            violations.add(
              'Pattern ${pattern.id} pair #$i (${a.type.name}) -> #${i + 1} (beam) arrival diff ${bArriveMinusAArrive.toStringAsFixed(4)}s < required ${required.toStringAsFixed(4)}s at speed ${speed.toStringAsFixed(1)}',
            );
          }
        } else if (a.type == HazardType.beam && b.type != HazardType.beam) {
          // Beam B -> ground hazard C:
          // (C.arrive - tStart(H_C)) - (B.arrive + (C.beamHitW + 28)/s - tStart(16)) >= C.beamReactionSec
          // AND C.arrive - B.arrive >= C.afterBeamMinDxSec
          final cArriveMinusBArrive = (b.dxSeconds - a.dxSeconds) +
              (hitboxInsetLeft(b.type) - hitboxInsetLeft(a.type)) / speed;
          if (cArriveMinusBArrive < C.afterBeamMinDxSec - 0.0001) {
            violations.add(
              'Pattern ${pattern.id} pair #$i (beam) -> #${i + 1} (${b.type.name}) arrival diff ${cArriveMinusBArrive.toStringAsFixed(4)}s < afterBeamMinDxSec ${C.afterBeamMinDxSec}s at speed ${speed.toStringAsFixed(1)}',
            );
          }

          final takeoffC = cArriveMinusBArrive - tStart(hazardHitboxHeight(b.type));
          final beamClear = (C.beamHitW + C.playerHitW) / speed - tStart(C.beamSafeHeight);
          final reactionTime = takeoffC - beamClear;
          if (reactionTime < C.beamReactionSec - 0.0001) {
            violations.add(
              'Pattern ${pattern.id} pair #$i (beam) -> #${i + 1} (${b.type.name}) reaction window ${reactionTime.toStringAsFixed(4)}s < beamReactionSec ${C.beamReactionSec}s at speed ${speed.toStringAsFixed(1)}',
            );
          }
        } else {
          // Both are ground solids (invariant 2)
          final gap = intraPatternGapTime(a: a, b: b, speed: speed);
          if (gap < minGapTime - 0.0001) {
            violations.add(
              'Pattern ${pattern.id} gap between item #$i and #${i + 1} is ${gap.toStringAsFixed(4)}s < ${minGapTime}s at speed ${speed.toStringAsFixed(1)}',
            );
          }
        }
      }
    }

    return violations;
  }
}
