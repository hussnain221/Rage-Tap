import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/core/constants.dart';
import 'package:rage_tap/game/systems/hazard_geometry.dart';
import 'package:rage_tap/game/systems/pattern.dart';
import 'package:rage_tap/game/systems/pattern_library.dart';
import 'package:rage_tap/game/systems/pattern_validator.dart';

void main() {
  group('PatternValidator formula tests', () {
    test('clearTime(H) matches spec values', () {
      // H=22 (spike) -> ~0.567 s
      expect(PatternValidator.clearTime(22), closeTo(0.5671, 0.002));

      // H=53 (barrier) -> ~0.4445 s
      expect(PatternValidator.clearTime(53), closeTo(0.4445, 0.002));

      // H=30 (charging) -> ~0.538 s
      expect(PatternValidator.clearTime(30), closeTo(0.5381, 0.002));

      // H=65 (tall wall) -> ~0.3868 s
      expect(PatternValidator.clearTime(65), closeTo(0.3868, 0.002));
    });

    test('tStart(H) reference values match addendum section 2 within ±0.002', () {
      expect(PatternValidator.tStart(22), closeTo(0.0365, 0.002));
      expect(PatternValidator.tStart(53), closeTo(0.0978, 0.002));
      expect(PatternValidator.tStart(65), closeTo(0.1266, 0.002));
      expect(PatternValidator.tStart(16), closeTo(0.0261, 0.002));
    });

    test('Tall wall window reference values at s=190, 210, 300 match addendum section 2', () {
      final window190 = PatternValidator.timingWindow(
        type: HazardType.tallWall,
        count: 1,
        sRel: 190,
      );
      expect(window190, closeTo(0.1131, 0.002));
      expect(window190 < 0.12, isTrue, reason: 'Must be invalid at 190');

      final window210 = PatternValidator.timingWindow(
        type: HazardType.tallWall,
        count: 1,
        sRel: 210,
      );
      expect(window210, closeTo(0.1392, 0.002));
      expect(window210 >= 0.12, isTrue, reason: 'Must be valid at 210');

      final window300 = PatternValidator.timingWindow(
        type: HazardType.tallWall,
        count: 1,
        sRel: 300,
      );
      expect(window300, closeTo(0.2135, 0.002));
      expect(window300 >= 0.12, isTrue, reason: 'Must be valid at 300');
    });

    test('pitWindow reference values match addendum section 2 within ±0.002', () {
      expect(PatternValidator.pitWindow(80, 190), closeTo(0.2758, 0.002));
      expect(PatternValidator.pitWindow(110, 190), closeTo(0.1179, 0.002));
      expect(PatternValidator.pitWindow(110, 200), closeTo(0.1437, 0.002));
      expect(PatternValidator.pitWindow(140, 255), closeTo(0.1317, 0.002));
    });

    test('groupHitboxWidth formula matches hazard geometry', () {
      expect(PatternValidator.groupHitboxWidth(HazardType.spike, 1), 24);
      expect(PatternValidator.groupHitboxWidth(HazardType.spike, 2), 54);
      expect(PatternValidator.groupHitboxWidth(HazardType.spike, 3), 84);
      expect(PatternValidator.groupHitboxWidth(HazardType.barrier, 1), 24);
      expect(PatternValidator.groupHitboxWidth(HazardType.tallWall, 1), 24);
      expect(PatternValidator.groupHitboxWidth(HazardType.charging, 1), 26);
      expect(PatternValidator.groupHitboxWidth(HazardType.beam, 1), 12);
      expect(PatternValidator.groupHitboxWidth(HazardType.pit, 1, 80), 80);
    });

    test('timingWindow calculates window and satisfies >= 0.12s for single spikes at 190', () {
      final window = PatternValidator.timingWindow(
        type: HazardType.spike,
        count: 1,
        sRel: 190,
      );
      expect(window, closeTo(0.2934, 0.01));
      expect(window, greaterThanOrEqualTo(0.12));
    });
  });

  group('Pattern library validation tests', () {
    test('Every pattern in the library is valid at speeds 190, 230, 260, 300, and boosted 345', () {
      final boostedSpeed = C.maxSpeed * C.rageSpeedMultiplier;
      final testSpeeds = [190.0, 230.0, 260.0, 300.0, boostedSpeed];

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

    test('Every pattern remains fair at boosted Rage speed (300 * 1.15 = 345 px/s)', () {
      final boostedSpeed = C.maxSpeed * C.rageSpeedMultiplier;
      for (final pattern in PatternLibrary.patterns) {
        final violations = PatternValidator.validatePattern(
          pattern,
          minSpeed: boostedSpeed,
          maxSpeed: boostedSpeed,
        );
        expect(
          violations,
          isEmpty,
          reason: 'Pattern ${pattern.id} invalid at boosted speed: ${violations.join("; ")}',
        );
      }
    });

    test('Unfair pattern (two barriers 0.5 s apart) reports dead-zone violation', () {
      const unfairPattern = Pattern(
        id: 'UNFAIR_B1B1',
        minSpeed: 190,
        tierStart: 0,
        weight: 1,
        items: [
          PatternItem(type: HazardType.barrier, dxSeconds: 0.0),
          PatternItem(type: HazardType.barrier, dxSeconds: 0.5),
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

    test('Tall wall patterns (W1, W1S1, B1W1, S2W1, W1W1) are valid at speeds 210, 240, 270, 300', () {
      const tallWallPatterns = [
        PatternLibrary.w1,
        PatternLibrary.w1s1,
        PatternLibrary.b1w1,
        PatternLibrary.s2w1,
        PatternLibrary.w1w1,
      ];
      const speeds = [210.0, 240.0, 270.0, 300.0];

      for (final pattern in tallWallPatterns) {
        for (final speed in speeds) {
          final violations = PatternValidator.validatePattern(
            pattern,
            minSpeed: speed,
            maxSpeed: speed,
          );
          expect(
            violations,
            isEmpty,
            reason: 'Tall wall pattern ${pattern.id} failed validation at speed $speed: ${violations.join("; ")}',
          );
        }
      }
    });

    test('Hypothetical tallWall pattern with minSpeed 190 is REJECTED', () {
      const invalidTallWallPattern = Pattern(
        id: 'INVALID_W1',
        minSpeed: 190,
        tierStart: 45,
        weight: 1,
        items: [
          PatternItem(type: HazardType.tallWall, count: 1, dxSeconds: 0),
        ],
      );
      final violations = PatternValidator.validatePattern(
        invalidTallWallPattern,
        minSpeed: 190,
        maxSpeed: 190,
      );
      expect(violations, isNotEmpty);
      expect(
        violations.any((v) => v.contains('timing window') && v.contains('< 0.12')),
        isTrue,
        reason: 'Expected timing window violation < 0.12s at speed 190 but got: $violations',
      );
    });

    test('Rhythm packs (R3, R3S, R4, R5) are valid at speeds 285, 290, 300 and satisfy invariant 2', () {
      const rhythmPatterns = [
        PatternLibrary.r3,
        PatternLibrary.r3s,
        PatternLibrary.r4,
        PatternLibrary.r5,
      ];
      const speeds = [285.0, 290.0, 300.0];

      for (final pattern in rhythmPatterns) {
        for (final speed in speeds) {
          final violations = PatternValidator.validatePattern(
            pattern,
            minSpeed: speed,
            maxSpeed: speed,
          );
          expect(
            violations,
            isEmpty,
            reason: 'Rhythm pattern ${pattern.id} failed validation at speed $speed: ${violations.join("; ")}',
          );

          // Assert invariant 2 for each consecutive pair
          for (int i = 0; i < pattern.items.length - 1; i++) {
            final a = pattern.items[i];
            final b = pattern.items[i + 1];
            final widthA = PatternValidator.groupHitboxWidth(a.type, a.count, a.pitWidth);
            final dxSec = b.dxSeconds - a.dxSeconds;
            final gapTime = dxSec - (widthA / speed);
            expect(
              gapTime,
              greaterThanOrEqualTo(PatternValidator.minGapTime - 0.0001),
              reason: 'Pattern ${pattern.id} pair $i->${i+1} gap $gapTime < ${PatternValidator.minGapTime} at speed $speed',
            );
          }
        }
      }
    });

    test('Overhead beam patterns (D1–D7) are valid at speeds 190, 230, 260, 300 and satisfy beam rules', () {
      const beamPatterns = [
        PatternLibrary.d1,
        PatternLibrary.d2,
        PatternLibrary.d3,
        PatternLibrary.d4,
        PatternLibrary.d5,
        PatternLibrary.d6,
        PatternLibrary.d7,
      ];
      const speeds = [190.0, 230.0, 260.0, 300.0];

      for (final pattern in beamPatterns) {
        for (final speed in speeds) {
          if (speed < pattern.minSpeed) continue;
          final violations = PatternValidator.validatePattern(
            pattern,
            minSpeed: speed,
            maxSpeed: speed,
          );
          expect(
            violations,
            isEmpty,
            reason: 'Beam pattern ${pattern.id} failed validation at speed $speed: ${violations.join("; ")}',
          );
        }
      }
    });

    test('Deliberately unfair pattern (spikes@0, beam@0.60) is REJECTED', () {
      const unfairSpikeBeam = Pattern(
        id: 'UNFAIR_S1_BEAM',
        minSpeed: 190,
        tierStart: 60,
        weight: 1,
        items: [
          PatternItem(type: HazardType.spike, count: 1, dxSeconds: 0),
          PatternItem(type: HazardType.beam, count: 1, dxSeconds: 0.60),
        ],
      );

      final violations = PatternValidator.validatePattern(
        unfairSpikeBeam,
        minSpeed: 190,
        maxSpeed: 190,
      );
      expect(violations, isNotEmpty);
      expect(
        violations.any((v) => v.contains('beam') && v.contains('arrival diff')),
        isTrue,
        reason: 'Expected arrival diff violation for unfair spike->beam pattern but got: $violations',
      );
    });

    test('Pit patterns (PIT1, PIT2, PIT3, PS1, SP1, PM1, MB1, PP, G1) are valid at speeds 190, 200, 230, 255, 300', () {
      final pitPatterns = [
        PatternLibrary.pit1,
        PatternLibrary.pit2,
        PatternLibrary.pit3,
        PatternLibrary.ps1,
        PatternLibrary.sp1,
        PatternLibrary.pm1,
        PatternLibrary.mb1,
        PatternLibrary.pp,
        PatternLibrary.g1,
      ];
      const speeds = [190.0, 200.0, 230.0, 255.0, 300.0];

      for (final pattern in pitPatterns) {
        for (final speed in speeds) {
          if (speed < pattern.minSpeed) continue;
          final violations = PatternValidator.validatePattern(
            pattern,
            minSpeed: speed,
            maxSpeed: speed,
          );
          expect(
            violations,
            isEmpty,
            reason: 'Pit pattern ${pattern.id} failed validation at speed $speed: ${violations.join("; ")}',
          );
        }
      }
    });

    test('PIT2 (medium pit) with minSpeed 190 is REJECTED (timing window 0.1179 < 0.12)', () {
      const unfairPit2 = Pattern(
        id: 'UNFAIR_PIT2_190',
        minSpeed: 190,
        tierStart: 80,
        weight: 1,
        items: [
          PatternItem(type: HazardType.pit, count: 1, dxSeconds: 0, pitWidth: C.pitMediumW),
        ],
      );

      final violations = PatternValidator.validatePattern(
        unfairPit2,
        minSpeed: 190,
        maxSpeed: 190,
      );
      expect(violations, isNotEmpty);
      expect(
        violations.any((v) => v.contains('timing window') && v.contains('0.1179')),
        isTrue,
        reason: 'Expected 0.1179 timing window violation at speed 190 but got: $violations',
      );
    });

    test('PIT3 (long pit) with minSpeed 190 is REJECTED', () {
      const unfairPit3 = Pattern(
        id: 'UNFAIR_PIT3_190',
        minSpeed: 190,
        tierStart: 80,
        weight: 1,
        items: [
          PatternItem(type: HazardType.pit, count: 1, dxSeconds: 0, pitWidth: C.pitLongW),
        ],
      );

      final violations = PatternValidator.validatePattern(
        unfairPit3,
        minSpeed: 190,
        maxSpeed: 190,
      );
      expect(violations, isNotEmpty);
      expect(
        violations.any((v) => v.contains('timing window')),
        isTrue,
        reason: 'Expected timing window violation for long pit at speed 190 but got: $violations',
      );
    });

    test('Integration review table: all patterns have window >= 0.12s at minSpeed and at 300', () {
      debugPrint('\n| Pattern | TierStart | MinSpeed | Weight | Window @ minSpeed | Window @ 300 |');
      debugPrint('|---|---|---|---|---|---|');

      for (final p in PatternLibrary.patterns) {
        double? minWinAtMinSpeed;
        double? minWinAt300;

        for (final item in p.items) {
          if (item.type != HazardType.beam) {
            final winAtMin = PatternValidator.timingWindow(
              type: item.type,
              count: item.count,
              sRel: p.minSpeed,
              pitWidth: item.pitWidth,
            );
            final winAt300 = PatternValidator.timingWindow(
              type: item.type,
              count: item.count,
              sRel: 300.0,
              pitWidth: item.pitWidth,
            );
            minWinAtMinSpeed = minWinAtMinSpeed == null ? winAtMin : math.min(minWinAtMinSpeed, winAtMin);
            minWinAt300 = minWinAt300 == null ? winAt300 : math.min(minWinAt300, winAt300);
          }
        }

        final winMinStr = minWinAtMinSpeed != null ? minWinAtMinSpeed.toStringAsFixed(4) : 'N/A';
        final win300Str = minWinAt300 != null ? minWinAt300.toStringAsFixed(4) : 'N/A';
        debugPrint('| ${p.id.padRight(7)} | ${p.tierStart.toStringAsFixed(0).padRight(9)} | ${p.minSpeed.toStringAsFixed(0).padRight(8)} | ${p.weight.toString().padRight(6)} | ${winMinStr.padRight(17)} | ${win300Str.padRight(12)} |');

        if (minWinAtMinSpeed != null) {
          expect(minWinAtMinSpeed, greaterThanOrEqualTo(0.12 - 0.0001),
              reason: 'Pattern ${p.id} has timing window $minWinAtMinSpeed < 0.12 at minSpeed ${p.minSpeed}');
        }
        if (minWinAt300 != null) {
          expect(minWinAt300, greaterThanOrEqualTo(0.12 - 0.0001),
              reason: 'Pattern ${p.id} has timing window $minWinAt300 < 0.12 at speed 300');
        }
      }
    });
  });
}
