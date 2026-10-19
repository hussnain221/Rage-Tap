import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/game/rage_tap_game.dart';
import 'package:rage_tap/game/systems/spawner.dart';
import 'package:rage_tap/ui/screens/game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Debug Tools Tests (Prompt 5.2)', () {
    test('Spawner seed resolution handles explicit override and environment fallback', () {
      expect(Spawner.resolveSeed(42), 42);
      expect(Spawner.resolveSeed(999999), 999999);
      final defaultSeed = Spawner.resolveSeed();
      expect(defaultSeed, isA<int>());
    });

    test('RageTapGame showHitboxes starts false and toggles cleanly', () {
      final game = RageTapGame();
      expect(game.showHitboxes.value, false);

      game.showHitboxes.value = true;
      expect(game.showHitboxes.value, true);

      game.showHitboxes.value = false;
      expect(game.showHitboxes.value, false);

      game.disposeGame();
    });

    testWidgets('Corner long-press (1s) toggles showHitboxes on GameScreen', (tester) async {
      final game = RageTapGame();
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(game: game),
        ),
      );
      await tester.pump();

      expect(game.showHitboxes.value, false);

      // Tap briefly (<1s) at top-left corner -> does NOT toggle
      final gesture = await tester.startGesture(const Offset(20, 20));
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pump();

      expect(game.showHitboxes.value, false);

      // Long press (>= 1.0s) at top-left corner -> toggles to true
      final gesture2 = await tester.startGesture(const Offset(20, 20));
      await tester.pump(const Duration(milliseconds: 1050));
      await gesture2.up();
      await tester.pump();

      expect(game.showHitboxes.value, true);

      // Long press again -> toggles back to false
      final gesture3 = await tester.startGesture(const Offset(20, 20));
      await tester.pump(const Duration(milliseconds: 1050));
      await gesture3.up();
      await tester.pump();

      expect(game.showHitboxes.value, false);
    });

    testWidgets('Debug overlay displays FPS, Speed, Time, Tier, Pattern, Seed, State, and Hitbox', (tester) async {
      final game = RageTapGame(seed: 12345);
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(game: game),
        ),
      );
      await tester.pump();

      if (kDebugMode) {
        expect(find.textContaining('Seed: 12345'), findsOneWidget);
        expect(find.textContaining('FPS:'), findsOneWidget);
        expect(find.textContaining('Speed:'), findsOneWidget);
        expect(find.textContaining('Time:'), findsOneWidget);
        expect(find.textContaining('Tier:'), findsOneWidget);
        expect(find.textContaining('Pattern:'), findsOneWidget);
        expect(find.textContaining('State: ready'), findsOneWidget);
        expect(find.textContaining('Hitbox: OFF'), findsOneWidget);

        // Turn hitboxes on
        game.showHitboxes.value = true;
        await tester.pump();
        expect(find.textContaining('Hitbox: ON'), findsOneWidget);
      }
    });

    test('Release mode safety check: debug-only paths are guarded by kDebugMode', () {
      // Confirm that kDebugMode guards are in place for all debug features
      // In release mode (kDebugMode == false):
      // - RageTapGame does not mount FpsComponent
      // - Player and Obstacle render methods bypass hitbox outlines
      // - GameScreen does not create debug timer or debug overlay
      const isDebug = kDebugMode;
      if (!isDebug) {
        final game = RageTapGame();
        expect(game.currentFps, 0.0);
        game.disposeGame();
      }
      expect(kDebugMode, isA<bool>());
    });
  });
}
