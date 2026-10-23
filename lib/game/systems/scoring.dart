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

  const RunResult({
    required this.score,
    required this.best,
    required this.isNewBest,
    this.deathCause,
    this.nearMisses = 0,
    required this.durationSeconds,
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
}
