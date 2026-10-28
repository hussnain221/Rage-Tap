import 'dart:math' as math;

enum DailyGoalType {
  score,
  nearMisses,
  survival,
}

/// Daily challenge model with deterministic seeding from device date (yyyyMMdd)
/// per spec §20.4.
class DailyChallenge {
  final String dateKey; // yyyyMMdd
  final int seed;
  final DailyGoalType goalType;
  final int targetValue;
  final int rewardCoins;

  const DailyChallenge({
    required this.dateKey,
    required this.seed,
    required this.goalType,
    required this.targetValue,
    this.rewardCoins = 50,
  });

  static int seedFromDate(DateTime date) {
    return int.parse(dateKeyFromDate(date));
  }

  static String dateKeyFromDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  static DailyChallenge forDate(DateTime date) {
    final key = dateKeyFromDate(date);
    final seed = seedFromDate(date);
    final rand = math.Random(seed);

    final typeIndex = rand.nextInt(3);
    final type = DailyGoalType.values[typeIndex];
    int target;
    switch (type) {
      case DailyGoalType.score:
        target = 20 + (rand.nextInt(4) * 10); // 20, 30, 40, or 50
        break;
      case DailyGoalType.nearMisses:
        target = 3 + (rand.nextInt(3) * 2); // 3, 5, or 7
        break;
      case DailyGoalType.survival:
        target = 20 + (rand.nextInt(3) * 10); // 20, 30, or 40s
        break;
    }

    return DailyChallenge(
      dateKey: key,
      seed: seed,
      goalType: type,
      targetValue: target,
      rewardCoins: 50,
    );
  }

  String get goalDescription {
    switch (goalType) {
      case DailyGoalType.score:
        return 'Reach a score of $targetValue';
      case DailyGoalType.nearMisses:
        return 'Get $targetValue near-misses';
      case DailyGoalType.survival:
        return 'Survive for $targetValue seconds';
    }
  }

  bool isGoalMet({
    required int score,
    required int nearMisses,
    required double durationSeconds,
  }) {
    switch (goalType) {
      case DailyGoalType.score:
        return score >= targetValue;
      case DailyGoalType.nearMisses:
        return nearMisses >= targetValue;
      case DailyGoalType.survival:
        return durationSeconds >= targetValue;
    }
  }
}
