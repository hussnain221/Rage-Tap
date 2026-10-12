import '../../core/constants.dart';

class NearMiss {
  const NearMiss._();

  /// Pure decision function for near-miss per spec §9.2.
  /// Valid when 0 <= minClearance <= C.nearMissClearance (14) and cooldown is ready (<= 0).
  static bool isNearMiss({
    required double minClearance,
    required double cooldownRemaining,
  }) {
    return cooldownRemaining <= 0.0 &&
        minClearance >= 0.0 &&
        minClearance <= C.nearMissClearance;
  }
}
