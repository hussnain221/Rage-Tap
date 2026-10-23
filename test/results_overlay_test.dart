import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/game/systems/hazard_geometry.dart';
import 'package:rage_tap/game/game_state.dart';
import 'package:rage_tap/game/rage_tap_game.dart';
import 'package:rage_tap/game/systems/result_messages.dart';
import 'package:rage_tap/ui/widgets/results_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'best_score': 100});
  });

  group('ResultMessages pure selector unit tests', () {
    test('New best selects from newBestPool and respects lastMessage', () {
      final msg1 = ResultMessages.select(
        isNewBest: true,
        score: 150,
        bestScore: 100,
        random: math.Random(1),
      );
      expect(ResultMessages.newBestPool, contains(msg1));

      // With lastMessage, selects alternative
      final msg2 = ResultMessages.select(
        isNewBest: true,
        score: 150,
        bestScore: 100,
        lastMessage: msg1,
        random: math.Random(1),
      );
      expect(msg2, isNot(equals(msg1)));
      expect(ResultMessages.newBestPool, contains(msg2));
    });

    test('Near-best selects near-best message when score >= 80% of best', () {
      final msg = ResultMessages.select(
        isNewBest: false,
        score: 85,
        bestScore: 100,
        random: math.Random(1),
      );
      expect(msg, equals(ResultMessages.nearBestMessage));
    });

    test('Spike death cause selects spike message when chosen', () {
      final fixedRand = math.Random(42);
      bool sawSpikeMsg = false;
      for (int i = 0; i < 20; i++) {
        final msg = ResultMessages.select(
          isNewBest: false,
          score: 20,
          bestScore: 100,
          deathCause: DeathCause.spike,
          random: fixedRand,
        );
        if (ResultMessages.spikePool.contains(msg)) {
          sawSpikeMsg = true;
          break;
        }
      }
      expect(sawSpikeMsg, isTrue);
    });

    test('Barrier death cause selects barrier message when chosen', () {
      final fixedRand = math.Random(42);
      bool sawBarrierMsg = false;
      for (int i = 0; i < 20; i++) {
        final msg = ResultMessages.select(
          isNewBest: false,
          score: 20,
          bestScore: 100,
          deathCause: DeathCause.barrier,
          random: fixedRand,
        );
        if (ResultMessages.barrierPool.contains(msg)) {
          sawBarrierMsg = true;
          break;
        }
      }
      expect(sawBarrierMsg, isTrue);
    });

    test('Charging block death cause selects charging message when chosen', () {
      final fixedRand = math.Random(42);
      bool sawChargeMsg = false;
      for (int i = 0; i < 20; i++) {
        final msg = ResultMessages.select(
          isNewBest: false,
          score: 20,
          bestScore: 100,
          deathCause: DeathCause.charging,
          random: fixedRand,
        );
        if (ResultMessages.chargingPool.contains(msg)) {
          sawChargeMsg = true;
          break;
        }
      }
      expect(sawChargeMsg, isTrue);
    });

    test('Tall wall death cause selects tall wall message when chosen', () {
      final fixedRand = math.Random(42);
      bool sawTallWallMsg = false;
      for (int i = 0; i < 20; i++) {
        final msg = ResultMessages.select(
          isNewBest: false,
          score: 20,
          bestScore: 100,
          deathCause: DeathCause.tallWall,
          random: fixedRand,
        );
        if (ResultMessages.tallWallPool.contains(msg)) {
          sawTallWallMsg = true;
          break;
        }
      }
      expect(sawTallWallMsg, isTrue);
    });

    test('Beam death cause selects beam message when chosen', () {
      final fixedRand = math.Random(42);
      bool sawBeamMsg = false;
      for (int i = 0; i < 20; i++) {
        final msg = ResultMessages.select(
          isNewBest: false,
          score: 20,
          bestScore: 100,
          deathCause: DeathCause.beam,
          random: fixedRand,
        );
        if (ResultMessages.beamPool.contains(msg)) {
          sawBeamMsg = true;
          break;
        }
      }
      expect(sawBeamMsg, isTrue);
    });
  });

  group('ResultsOverlay widget tests', () {
    testWidgets('ResultsOverlay renders standard game over layout and retries', (tester) async {
      final game = RageTapGame(seed: 42);
      game.score.value = 50;
      game.bestScore.value = 100;
      game.isNewBest.value = false;
      game.state.value = GameState.results;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResultsOverlay(game: game),
          ),
        ),
      );

      // Verify header and elements
      expect(find.text('GAME OVER'), findsOneWidget);
      expect(find.text('RETRY'), findsOneWidget);
      expect(find.text('HOME'), findsOneWidget);
      expect(find.text('BEST  '), findsOneWidget);

      // Score counter counts up
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('50'), findsOneWidget);

      // Tapping RETRY immediately starts new run
      await tester.tap(find.text('RETRY'));
      expect(game.state.value, equals(GameState.playing));
    });

    testWidgets('ResultsOverlay renders NEW BEST badge and confetti when isNewBest is true', (tester) async {
      final game = RageTapGame(seed: 42);
      game.score.value = 150;
      game.bestScore.value = 150;
      game.isNewBest.value = true;
      game.state.value = GameState.results;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResultsOverlay(game: game),
          ),
        ),
      );

      expect(find.text('GAME OVER'), findsOneWidget);
      expect(find.text('★ NEW BEST! ★'), findsOneWidget);

      // Confetti custom painter is present
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('ResultsOverlay HOME button triggers navigation', (tester) async {
      final game = RageTapGame(seed: 42);
      game.state.value = GameState.results;
      bool homePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResultsOverlay(
              game: game,
              onHomePressed: () => homePressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('HOME'));
      expect(homePressed, isTrue);
    });
  });
}
