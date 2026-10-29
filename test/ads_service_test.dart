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
    AdsService.instance.testShowHandler = null;
  });

  tearDown(() {
    AdsService.instance.dispose();
    AdsService.instance.testShowHandler = null;
  });

  group('AdsService unit tests (§20.6)', () {
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
}
