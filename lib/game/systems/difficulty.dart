import '../../core/constants.dart';

class Difficulty {
  const Difficulty._();

  /// Computes scroll speed at run time [t] seconds.
  /// speed(t) = clamp(190 + 3.0 * t, 190, 300)
  static double speed(double t) {
    final s = C.baseSpeed + C.speedRampPerSec * t;
    return s.clamp(C.baseSpeed, C.maxSpeed).toDouble();
  }

  /// Computes difficulty tier (1..8) at run time [t] seconds.
  /// Uses C.tierStarts: [0, 8, 16, 24, 36, 45, 60, 80].
  /// tier = number of starts <= t (clamped to 1..8).
  static int tier(double t) {
    int count = 0;
    for (final start in C.tierStarts) {
      if (t >= start) {
        count++;
      } else {
        break;
      }
    }
    return count.clamp(1, C.tierStarts.length);
  }

  /// Computes the rest gap range [min, max] (in seconds) at run time [t] seconds.
  /// Linearly lerps from [1.30, 1.90] at t=0 to [0.95, 1.25] at t=45, constant afterward; never below 0.95.
  static ({double min, double max}) restGapRange(double t) {
    if (t >= C.restRampSeconds) {
      return (min: C.restMinEnd, max: C.restMaxEnd);
    }
    final progress = (t / C.restRampSeconds).clamp(0.0, 1.0);
    final minVal = C.restMinStart + (C.restMinEnd - C.restMinStart) * progress;
    final maxVal = C.restMaxStart + (C.restMaxEnd - C.restMaxStart) * progress;
    return (
      min: minVal < C.restMinEnd ? C.restMinEnd : minVal,
      max: maxVal < C.restMinEnd ? C.restMinEnd : maxVal,
    );
  }
}
