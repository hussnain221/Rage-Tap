import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/core/constants.dart';
import 'package:rage_tap/data/ads_service.dart';
import 'package:rage_tap/data/save_service.dart';
import 'package:rage_tap/game/game_state.dart';
import 'package:rage_tap/game/rage_tap_game.dart';
import 'package:rage_tap/game/systems/scoring.dart';
import 'package:rage_tap/ui/widgets/results_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'total_coins': 100});
    await SaveService.instance.init();
    AdsService.instance.dispose();
  });

  tearDown(() {
    AdsService.instance.dispose();
  });

  group('AdsService Rewarded unit tests (§20.6)', () {
    test('Initial state: no ad loaded', () {
      expect(AdsService.instance.isRewardedLoaded, isFalse);
    });

    test('showRewardedAd returns false when no ad is loaded', () async {
      bool rewardGranted = false;
      final result = await AdsService.instance.showRewardedAd(
        onUserEarnedReward: () => rewardGranted = true,
      );
      expect(result, isFalse);
      expect(rewardGranted, isFalse);
    });

    test('showRewardedAd calls reward callback strictly once when using test handler', () async {
      int rewardCount = 0;
      AdsService.instance.isRewardedLoadedNotifier.value = true;
      AdsService.instance.testShowHandler = ({required VoidCallback onUserEarnedReward}) async {
        onUserEarnedReward();
        return true;
      };

      final result = await AdsService.instance.showRewardedAd(
        onUserEarnedReward: () => rewardCount++,
      );
      expect(result, isTrue);
      expect(rewardCount, 1);
      expect(AdsService.instance.isRewardedLoaded, isFalse);
    });

    test('C contains valid AdMob test IDs per spec §20.6', () {
      expect(C.admobAppId, 'ca-app-pub-3940256099942544~3347511713');
      expect(C.rewardedAdUnitId, 'ca-app-pub-3940256099942544/5224354917');
      expect(C.interstitialAdUnitId, 'ca-app-pub-3940256099942544/1033173712');
      expect(C.interstitialsEnabled, isTrue);
      expect(C.interstitialMinRuns, 4);
      expect(C.interstitialMinIntervalSec, 180);
    });
  });

  group('AdsService Interstitial unit tests (§20.6)', () {
    test('Initial state: no interstitial loaded, runs = 0', () {
      expect(AdsService.instance.isInterstitialLoaded, isFalse);
      expect(AdsService.instance.completedRunsSinceLastInterstitial, 0);
      expect(AdsService.instance.interstitialsEnabled, isTrue);
    });

    test('canShowInterstitial returns false when not loaded', () {
      AdsService.instance.resetTrackingForTesting(
        completedRuns: 10,
        lastTime: DateTime.now().subtract(const Duration(minutes: 10)),
        isLoaded: false,
      );
      expect(AdsService.instance.canShowInterstitial(), isFalse);
    });

    test('canShowInterstitial respects strict limits (runs >= minRuns and time >= minInterval)', () {
      final baseTime = DateTime(2026, 10, 30, 12, 0, 0);

      // 1. Not loaded -> false
      AdsService.instance.resetTrackingForTesting(
        completedRuns: 4,
        lastTime: baseTime,
        isLoaded: false,
      );
      expect(AdsService.instance.canShowInterstitial(now: baseTime.add(const Duration(minutes: 5))), isFalse);

      // 2. Loaded, but completed runs < 4 -> false
      AdsService.instance.resetTrackingForTesting(
        completedRuns: 3,
        lastTime: baseTime,
        isLoaded: true,
      );
      expect(AdsService.instance.canShowInterstitial(now: baseTime.add(const Duration(minutes: 5))), isFalse);

      // 3. Loaded, runs >= 4, but elapsed time < 180s (e.g. 179s) -> false
      AdsService.instance.resetTrackingForTesting(
        completedRuns: 4,
        lastTime: baseTime,
        isLoaded: true,
      );
      expect(AdsService.instance.canShowInterstitial(now: baseTime.add(const Duration(seconds: 179))), isFalse);

      // 4. Loaded, runs >= 4, and elapsed time >= 180s -> true
      expect(AdsService.instance.canShowInterstitial(now: baseTime.add(const Duration(seconds: 180))), isTrue);
      expect(AdsService.instance.canShowInterstitial(now: baseTime.add(const Duration(minutes: 5))), isTrue);
    });

    test('showInterstitialIfEligible executes action immediately when ineligible', () async {
      AdsService.instance.setInterstitialsEnabledForTesting(true);
      // Not eligible (runs = 0)
      bool actionExecuted = false;
      final shown = await AdsService.instance.showInterstitialIfEligible(
        onAction: () => actionExecuted = true,
      );
      expect(shown, isFalse);
      expect(actionExecuted, isTrue);
    });

    test('showInterstitialIfEligible shows ad, resets counters, and executes action upon dismissal', () async {
      AdsService.instance.setInterstitialsEnabledForTesting(true);
      final startTime = DateTime(2026, 10, 30, 12, 0, 0);
      AdsService.instance.resetTrackingForTesting(
        completedRuns: 5,
        lastTime: startTime,
        isLoaded: true,
      );

      bool actionExecuted = false;
      AdsService.instance.testInterstitialShowHandler = ({required VoidCallback onDismissed}) async {
        // simulate ad display and user dismiss
        onDismissed();
        return true;
      };

      final adTime = startTime.add(const Duration(minutes: 4));
      final shown = await AdsService.instance.showInterstitialIfEligible(
        onAction: () => actionExecuted = true,
        now: adTime,
      );

      expect(shown, isTrue);
      expect(actionExecuted, isTrue);
      expect(AdsService.instance.completedRunsSinceLastInterstitial, 0);
      expect(AdsService.instance.lastInterstitialTime, adTime);
      expect(AdsService.instance.isInterstitialLoaded, isFalse);
    });
  });

  group('ResultsOverlay Rewarded Ad UI integration (§20.6)', () {
    testWidgets('Watch an ad button is hidden when ad is not loaded', (tester) async {
      final game = RageTapGame(seed: 42);
      game.state.value = GameState.results;
      game.score.value = 50;
      game.lastResult = const RunResult(
        score: 50,
        best: 100,
        isNewBest: false,
        durationSeconds: 15.0,
        coinsEarned: 5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResultsOverlay(game: game),
          ),
        ),
      );

      expect(find.textContaining('Watch an ad'), findsNothing);
      expect(find.text('RETRY'), findsOneWidget);
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('Watch an ad button appears when ad is loaded, grants reward once on callback, and does not block retry', (tester) async {
      final game = RageTapGame(seed: 42);
      game.state.value = GameState.results;
      game.score.value = 60;
      game.lastResult = const RunResult(
        score: 60,
        best: 100,
        isNewBest: false,
        durationSeconds: 20.0,
        coinsEarned: 6,
      );

      // Preload ad & set test handler
      AdsService.instance.isRewardedLoadedNotifier.value = true;
      AdsService.instance.testShowHandler = ({required VoidCallback onUserEarnedReward}) async {
        onUserEarnedReward();
        return true;
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResultsOverlay(game: game),
          ),
        ),
      );

      expect(find.text('Watch an ad: double your coins (+6)'), findsOneWidget);

      final initialCoins = SaveService.instance.totalCoins; // 100

      // Tap watch ad
      await tester.tap(find.text('Watch an ad: double your coins (+6)'));
      await tester.pump();

      // Verified: coins doubled (+6 bonus coins)
      expect(SaveService.instance.totalCoins, initialCoins + 6);

      // Verified: UI updates to "Coins doubled!" badge and button is gone
      expect(find.text('Coins doubled! (+6 coins)'), findsOneWidget);
      expect(find.text('Watch an ad: double your coins (+6)'), findsNothing);

      // Verified: RETRY still works immediately without delay
      await tester.tap(find.text('RETRY'));
      expect(game.state.value, equals(GameState.playing));
    });
  });

  group('ResultsOverlay Interstitial Ad UI integration (§20.6)', () {
    testWidgets('Mounting ResultsOverlay records a completed run', (tester) async {
      final initialRuns = AdsService.instance.completedRunsSinceLastInterstitial;
      final game = RageTapGame(seed: 42);
      game.state.value = GameState.results;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResultsOverlay(game: game),
          ),
        ),
      );

      expect(AdsService.instance.completedRunsSinceLastInterstitial, initialRuns + 1);
    });

    testWidgets('Tapping RETRY when interstitials are disabled works instantly', (tester) async {
      AdsService.instance.setInterstitialsEnabledForTesting(false);
      final game = RageTapGame(seed: 42);
      game.state.value = GameState.results;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResultsOverlay(game: game),
          ),
        ),
      );

      await tester.tap(find.text('RETRY'));
      expect(game.state.value, equals(GameState.playing));
    });

    testWidgets('Tapping RETRY when interstitial is eligible shows ad before retrying', (tester) async {
      AdsService.instance.setInterstitialsEnabledForTesting(true);
      AdsService.instance.resetTrackingForTesting(
        completedRuns: 4,
        lastTime: DateTime.now().subtract(const Duration(minutes: 5)),
        isLoaded: true,
      );

      int adShownCount = 0;
      AdsService.instance.testInterstitialShowHandler = ({required VoidCallback onDismissed}) async {
        adShownCount++;
        onDismissed();
        return true;
      };

      final game = RageTapGame(seed: 42);
      game.state.value = GameState.results;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResultsOverlay(game: game),
          ),
        ),
      );

      await tester.tap(find.text('RETRY'));
      await tester.pump();

      expect(adShownCount, 1);
      expect(game.state.value, equals(GameState.playing));
      expect(AdsService.instance.completedRunsSinceLastInterstitial, 0);
    });

    testWidgets('Tapping HOME triggers interstitial if eligible and proceeds to home callback', (tester) async {
      AdsService.instance.setInterstitialsEnabledForTesting(true);
      AdsService.instance.resetTrackingForTesting(
        completedRuns: 4,
        lastTime: DateTime.now().subtract(const Duration(minutes: 5)),
        isLoaded: true,
      );

      int adShownCount = 0;
      AdsService.instance.testInterstitialShowHandler = ({required VoidCallback onDismissed}) async {
        adShownCount++;
        onDismissed();
        return true;
      };

      final game = RageTapGame(seed: 42);
      game.state.value = GameState.results;
      bool homeTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResultsOverlay(
              game: game,
              onHomePressed: () => homeTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('HOME'));
      await tester.pump();

      expect(adShownCount, 1);
      expect(homeTapped, isTrue);
      expect(AdsService.instance.completedRunsSinceLastInterstitial, 0);
    });
  });
}
