import 'dart:math' as math;

import '../components/obstacle.dart';

/// Pure selection of post-game funny result messages per spec Appendix B.
class ResultMessages {
  const ResultMessages._();

  static const List<String> generalPool = [
    'That spike has been waiting for you.',
    'Gravity wins again.',
    'So close you could taste the neon.',
    'Your cube has filed a complaint.',
    'Jump earlier. Or later. Or not.',
    'The barrier did not move. You did.',
    'That was a warm-up. Probably.',
    'One more try. You know you want to.',
    'Nice try. Great crash.',
    'Tap. Tap. Oops.',
    'Your reflexes are buffering...',
    'Almost! Almost is a word.',
    'Even the cube felt that.',
  ];

  static const List<String> newBestPool = [
    'NEW BEST! Show-off.',
    'Personal record! Cube is proud.',
  ];

  static const String nearBestMessage = 'So close to your best. Again?';
  static const String warmUpMessage = 'Warm-up run. Now do it for real.';

  static const List<String> spikePool = [
    'Spikes: 1. You: 0.',
    'Pointy things are pointy.',
  ];

  static const List<String> barrierPool = [
    'The barrier did not move. You did.',
    'Wall. Meet face.',
  ];

  static const List<String> chargingPool = [
    'The block was fast. You were almost fast.',
    "It charged. You didn't dodge.",
  ];

  /// Pure function that chooses a result message according to selection order:
  /// 1. New best
  /// 2. Near-best (score >= 80% of best, score > 0, not new best)
  /// 3. Cause-specific (50% chance if hazard matches)
  /// 4. Score < 10 warm-up (if not picked yet)
  /// 5. General pool
  /// Never returns the same message twice in a row if alternatives exist.
  static String select({
    required bool isNewBest,
    required int score,
    required int bestScore,
    ObstacleType? deathCause,
    String? lastMessage,
    math.Random? random,
  }) {
    final rand = random ?? math.Random();

    // 1. New Best
    if (isNewBest) {
      final candidates = newBestPool.where((m) => m != lastMessage).toList();
      if (candidates.isNotEmpty) {
        return candidates[rand.nextInt(candidates.length)];
      }
      return newBestPool[rand.nextInt(newBestPool.length)];
    }

    // 2. Near Best (score >= 80% of best, best > 0)
    if (bestScore > 0 && score >= (bestScore * 0.80).floor() && score < bestScore) {
      if (nearBestMessage != lastMessage) {
        return nearBestMessage;
      }
    }

    // 3. Cause-specific (50% chance)
    if (deathCause != null && rand.nextBool()) {
      List<String>? pool;
      switch (deathCause) {
        case ObstacleType.spike:
          pool = spikePool;
          break;
        case ObstacleType.barrier:
          pool = barrierPool;
          break;
        case ObstacleType.charging:
          pool = chargingPool;
          break;
      }

      final candidates = pool.where((m) => m != lastMessage).toList();
      if (candidates.isNotEmpty) {
        return candidates[rand.nextInt(candidates.length)];
      }
    }

    // 4. Score < 10
    if (score < 10 && warmUpMessage != lastMessage && rand.nextBool()) {
      return warmUpMessage;
    }

    // 5. General pool
    final candidates = generalPool.where((m) => m != lastMessage).toList();
    if (candidates.isNotEmpty) {
      return candidates[rand.nextInt(candidates.length)];
    }
    return generalPool[rand.nextInt(generalPool.length)];
  }
}
