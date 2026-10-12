import '../../core/constants.dart';

class Difficulty {
  const Difficulty._();

  /// Computes scroll speed at run time [t] seconds.
  /// speed(t) = clamp(190 + 3.0 * t, 190, 300)
  static double speed(double t) {
    final s = C.baseSpeed + C.speedRampPerSec * t;
    return s.clamp(C.baseSpeed, C.maxSpeed).toDouble();
  }

  /// Computes difficulty tier (1..5) at run time [t] seconds.
  /// Tier 1: t < 8
  /// Tier 2: t < 16
  /// Tier 3: t < 24
  /// Tier 4: t < 36
  /// Tier 5: t >= 36
  static int tier(double t) {
    if (t < C.tierStarts[1]) return 1;
    if (t < C.tierStarts[2]) return 2;
    if (t < C.tierStarts[3]) return 3;
    if (t < C.tierStarts[4]) return 4;
    return 5;
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
