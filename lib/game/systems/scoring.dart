import '../../core/constants.dart';
import 'hazard_geometry.dart';

export 'hazard_geometry.dart' show DeathCause;

class RunResult {
  final int score;
  final int best;
  final bool isNewBest;
  final DeathCause? deathCause;
  final int nearMisses;
  final double durationSeconds;
  final int coinsEarned;
  final bool isDailyChallenge;
  final bool dailyGoalMet;
  final bool dailyRewardClaimed;

  const RunResult({
    required this.score,
    required this.best,
    required this.isNewBest,
    this.deathCause,
    this.nearMisses = 0,
    required this.durationSeconds,
    this.coinsEarned = 0,
    this.isDailyChallenge = false,
    this.dailyGoalMet = false,
    this.dailyRewardClaimed = false,
  });
}

class Scoring {
  static int pointsFromDistance(double distance) {
    if (distance <= 0) return 0;
    return (distance / C.distancePerPoint).floor();
  }

  static bool isNewBest(int finalScore, int bestAtStart) {
    return finalScore > bestAtStart && (bestAtStart > 0 || finalScore > 0);
  }

  /// Calculates coins earned at run end per spec §20.2:
  /// coins = floor(score / 10) + 2 * nearMisses
  static int coinsEarned({required int score, required int nearMisses}) {
    final validScore = score < 0 ? 0 : score;
    final validNearMisses = nearMisses < 0 ? 0 : nearMisses;
    return (validScore ~/ 10) + (2 * validNearMisses);
  }
}
