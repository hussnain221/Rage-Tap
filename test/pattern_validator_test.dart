import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/game/components/obstacle.dart';
import 'package:rage_tap/game/systems/pattern.dart';
import 'package:rage_tap/game/systems/pattern_library.dart';
import 'package:rage_tap/game/systems/pattern_validator.dart';

void main() {
  group('PatternValidator formula tests', () {
    test('clearTime(H) matches spec §8.2 values', () {
      // H=22 (spike) -> ~0.567 s
      expect(PatternValidator.clearTime(22), closeTo(0.5671, 0.002));

      // H=53 (barrier) -> ~0.4445 s
      expect(PatternValidator.clearTime(53), closeTo(0.4445, 0.002));

      // H=30 (charging) -> ~0.538 s
      expect(PatternValidator.clearTime(30), closeTo(0.5381, 0.002));
    });

    test('groupHitboxWidth formula matches 24n + 6(n-1) for spikes, 24 barrier, 26 charging', () {
      expect(PatternValidator.groupHitboxWidth(ObstacleType.spike, 1), 24);
      expect(PatternValidator.groupHitboxWidth(ObstacleType.spike, 2), 54);
      expect(PatternValidator.groupHitboxWidth(ObstacleType.spike, 3), 84);
      expect(PatternValidator.groupHitboxWidth(ObstacleType.barrier, 1), 24);
      expect(PatternValidator.groupHitboxWidth(ObstacleType.charging, 1), 26);
    });

    test('timingWindow calculates window and satisfies >= 0.12s for single spikes at 190', () {
      final window = PatternValidator.timingWindow(
        type: ObstacleType.spike,
        count: 1,
        sRel: 190,
      );
      // clearTime(22) = 0.5671s, (24 + 28)/190 = 0.2737s => window = 0.2934s
      expect(window, closeTo(0.2934, 0.01));
      expect(window, greaterThanOrEqualTo(0.12));
    });
  });

  group('Pattern library validation tests', () {
    test('Every pattern in the library is valid at speeds 190, 230, 260, 300', () {
      const testSpeeds = [190.0, 230.0, 260.0, 300.0];

      for (final pattern in PatternLibrary.patterns) {
        for (final speed in testSpeeds) {
          if (speed < pattern.minSpeed) continue; // Skip speeds below pattern's minSpeed

          final violations = PatternValidator.validatePattern(
            pattern,
            minSpeed: speed,
            maxSpeed: speed,
          );
          expect(
            violations,
            isEmpty,
            reason: 'Pattern ${pattern.id} failed validation at speed $speed: ${violations.join("; ")}',
          );
        }
      }
    });

    test('Unfair pattern (two barriers 0.5 s apart) reports dead-zone violation', () {
      const unfairPattern = Pattern(
        id: 'UNFAIR_B1B1',
        minSpeed: 190,
        tierStart: 0,
        weight: 1,
        items: [
          PatternItem(type: ObstacleType.barrier, dxSeconds: 0.0),
          PatternItem(type: ObstacleType.barrier, dxSeconds: 0.5),
        ],
      );

      final violations = PatternValidator.validatePattern(unfairPattern);
      expect(violations, isNotEmpty);
      expect(
        violations.any((v) => v.contains('< 0.89s') || v.contains('gap between')),
        isTrue,
        reason: 'Expected dead-zone gap violation but got: $violations',
      );
    });
  });
}
