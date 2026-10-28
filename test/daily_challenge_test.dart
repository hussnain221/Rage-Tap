import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/data/save_service.dart';
import 'package:rage_tap/game/model/daily_challenge.dart';
import 'package:rage_tap/ui/screens/daily_challenge_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyChallenge seeding and deterministic goals per spec §20.4', () {
    test('seedFromDate and dateKeyFromDate format yyyyMMdd correctly', () {
      final date = DateTime(2026, 10, 28);
      expect(DailyChallenge.seedFromDate(date), 20261028);
      expect(DailyChallenge.dateKeyFromDate(date), '20261028');

      final dateWithSingleDigit = DateTime(2026, 5, 4);
      expect(DailyChallenge.seedFromDate(dateWithSingleDigit), 20260504);
      expect(DailyChallenge.dateKeyFromDate(dateWithSingleDigit), '20260504');
    });

    test('Same date always yields identical seed and goal', () {
      final dateA = DateTime(2026, 10, 28, 8, 30);
      final dateB = DateTime(2026, 10, 28, 22, 15);

      final challengeA = DailyChallenge.forDate(dateA);
      final challengeB = DailyChallenge.forDate(dateB);

      expect(challengeA.seed, challengeB.seed);
      expect(challengeA.dateKey, challengeB.dateKey);
      expect(challengeA.goalType, challengeB.goalType);
      expect(challengeA.targetValue, challengeB.targetValue);
      expect(challengeA.rewardCoins, challengeB.rewardCoins);
      expect(challengeA.goalDescription, challengeB.goalDescription);
    });

    test('Goal validation logic', () {
      const scoreGoal = DailyChallenge(
        dateKey: '20261028',
        seed: 20261028,
        goalType: DailyGoalType.score,
        targetValue: 30,
      );
      expect(scoreGoal.isGoalMet(score: 29, nearMisses: 10, durationSeconds: 60), isFalse);
      expect(scoreGoal.isGoalMet(score: 30, nearMisses: 0, durationSeconds: 5), isTrue);

      const nearMissGoal = DailyChallenge(
        dateKey: '20261028',
        seed: 20261028,
        goalType: DailyGoalType.nearMisses,
        targetValue: 5,
      );
      expect(nearMissGoal.isGoalMet(score: 100, nearMisses: 4, durationSeconds: 60), isFalse);
      expect(nearMissGoal.isGoalMet(score: 0, nearMisses: 5, durationSeconds: 5), isTrue);

      const survivalGoal = DailyChallenge(
        dateKey: '20261028',
        seed: 20261028,
        goalType: DailyGoalType.survival,
        targetValue: 25,
      );
      expect(survivalGoal.isGoalMet(score: 100, nearMisses: 10, durationSeconds: 24.9), isFalse);
      expect(survivalGoal.isGoalMet(score: 0, nearMisses: 0, durationSeconds: 25.0), isTrue);
    });
  });

  group('One-claim-per-day persistence and reward logic per spec §20.4', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({'total_coins': 100});
      await SaveService.instance.init();
    });

    test('Reward is granted exactly once per day and blocks duplicate claims', () async {
      final saveService = SaveService.instance;
      final challenge = DailyChallenge.forDate(DateTime(2026, 10, 28));

      expect(saveService.isDailyCompleted(challenge.dateKey), isFalse);
      expect(saveService.totalCoins, 100);

      // Claim first time -> succeeds
      final firstClaim = await saveService.claimDailyReward(challenge);
      expect(firstClaim, isTrue);
      expect(saveService.totalCoins, 150); // +50 coins
      expect(saveService.isDailyCompleted(challenge.dateKey), isTrue);
      expect(saveService.lastDailyCompletedDate, challenge.dateKey);

      // Second claim attempt on same date -> rejected
      final secondClaim = await saveService.claimDailyReward(challenge);
      expect(secondClaim, isFalse);
      expect(saveService.totalCoins, 150); // no extra coins

      // Next day challenge can be claimed
      final nextDayChallenge = DailyChallenge.forDate(DateTime(2026, 10, 29));
      expect(saveService.isDailyCompleted(nextDayChallenge.dateKey), isFalse);
      final nextDayClaim = await saveService.claimDailyReward(nextDayChallenge);
      expect(nextDayClaim, isTrue);
      expect(saveService.totalCoins, 200); // +50 coins
    });

    test('Completed date persists across SaveService re-initialization', () async {
      final saveService = SaveService.instance;
      final challenge = DailyChallenge.forDate(DateTime(2026, 10, 28));

      await saveService.claimDailyReward(challenge);
      expect(saveService.isDailyCompleted('20261028'), isTrue);

      // Re-initialize from SharedPreferences
      await saveService.init();
      expect(saveService.isDailyCompleted('20261028'), isTrue);
      expect(saveService.lastDailyCompletedDate, '20261028');
    });
  });

  group('DailyChallengeScreen UI tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({'total_coins': 50});
      await SaveService.instance.init();
    });

    testWidgets('Renders goal of the day, device date note, and START RUN button', (tester) async {
      final testDate = DateTime(2026, 10, 28);
      await tester.pumpWidget(
        MaterialApp(
          home: DailyChallengeScreen(currentDate: testDate),
        ),
      );

      expect(find.text('DAILY'), findsOneWidget);
      expect(find.text('DATE: 2026-10-28'), findsOneWidget);
      expect(find.text('Seed #20261028'), findsOneWidget);
      expect(find.text('GOAL OF THE DAY'), findsOneWidget);
      expect(find.text('+50 coins reward'), findsOneWidget);
      expect(find.text('START RUN'), findsOneWidget);
      expect(find.textContaining('Note: Daily Challenge uses device date'), findsOneWidget);
    });

    testWidgets('Shows COMPLETED TODAY badge when already claimed', (tester) async {
      final testDate = DateTime(2026, 10, 28);
      final challenge = DailyChallenge.forDate(testDate);
      await SaveService.instance.claimDailyReward(challenge);

      await tester.pumpWidget(
        MaterialApp(
          home: DailyChallengeScreen(currentDate: testDate),
        ),
      );

      expect(find.text('COMPLETED TODAY'), findsOneWidget);
      expect(find.text('START RUN'), findsNothing);
    });
  });
}
