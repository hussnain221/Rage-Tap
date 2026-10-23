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
      // Fairness Invariant 1: timingWindow >= 0.12s
      for (int i = 0; i < pattern.items.length; i++) {
        final item = pattern.items[i];
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

      // Fairness Invariant 2 & Dead Zone rule: gapTime >= 0.89s
      for (int i = 0; i < pattern.items.length - 1; i++) {
        final a = pattern.items[i];
        final b = pattern.items[i + 1];
        final gap = intraPatternGapTime(a: a, b: b, speed: speed);
        if (gap < minGapTime - 0.0001) {
          violations.add(
            'Pattern ${pattern.id} gap between item #$i and #${i + 1} is ${gap.toStringAsFixed(4)}s < ${minGapTime}s at speed ${speed.toStringAsFixed(1)}',
          );
        }
      }
    }

    return violations;
  }
}
