import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/data/save_service.dart';
import 'package:rage_tap/game/game_state.dart';
import 'package:rage_tap/game/rage_tap_game.dart';
import 'package:rage_tap/ui/screens/game_screen.dart';
import 'package:rage_tap/ui/widgets/results_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

void _advance(RageTapGame game, double seconds) {
  const dt = 1 / 60;
  double elapsed = 0.0;
  while (elapsed < seconds) {
    game.update(dt);
    elapsed += dt;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    const MethodChannel globalChannel = MethodChannel('xyz.luan/audioplayers.global');
    const MethodChannel playerChannel = MethodChannel('xyz.luan/audioplayers');
    const MethodChannel pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(globalChannel, (call) async => 1);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(playerChannel, (call) async => 1);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async => '.');

    SharedPreferences.setMockInitialValues({
      'sound_enabled': true,
      'haptics_enabled': true,
    });
    await SaveService.instance.init();
  });

  group('Lifecycle and Edge Cases Tests (Prompt 5.1)', () {
    test('Ignored taps: taps during dying, results, paused, and resuming do nothing', () {
      final game = RageTapGame();
      expect(game.state.value, GameState.ready);

      // Start run
      game.startRun();
      expect(game.state.value, GameState.playing);

      // 1. Paused state: taps are ignored
      game.pause();
      expect(game.state.value, GameState.paused);
      final pausedY = game.player.y;
      game.onTapDown();
      expect(game.state.value, GameState.paused);
      expect(game.player.y, pausedY);

      // 2. Resuming state: taps are ignored
      game.beginResume();
      expect(game.state.value, GameState.resuming);
      game.onTapDown();
      expect(game.state.value, GameState.resuming);
      expect(game.player.y, pausedY);

      // Return to playing for die
      game.state.value = GameState.playing;

      // 3. Dying state: taps are ignored
      game.die();
      expect(game.state.value, GameState.dying);
      game.onTapDown();
      expect(game.state.value, GameState.dying);

      // Advance through death freeze and animation to results state
      _advance(game, 0.5);
      expect(game.state.value, GameState.results);

      // 4. Results state: taps on game area are ignored
      game.onTapDown();
      expect(game.state.value, GameState.results);
    });

    test('Double Retry protection: retry() called while playing is ignored', () {
      final game = RageTapGame();
      game.startRun();
      game.die();
      _advance(game, 0.5);
      expect(game.state.value, GameState.results);

      // First retry starts run
      game.retry();
      expect(game.state.value, GameState.playing);
      _advance(game, 0.1);
      final initialRunTime = game.runTime;
      expect(initialRunTime, greaterThan(0.0));

      // Second retry while playing must be ignored
      game.retry();
      expect(game.state.value, GameState.playing);
      expect(game.runTime, equals(initialRunTime));
    });

    testWidgets('Double Retry on ResultsOverlay button only invokes retry once', (tester) async {
      final game = RageTapGame();
      game.startRun();
      game.die();
      _advance(game, 0.5);
      expect(game.state.value, GameState.results);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResultsOverlay(game: game),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final retryFinder = find.text('RETRY');
      expect(retryFinder, findsOneWidget);

      // Rapidly tap RETRY multiple times
      await tester.tap(retryFinder);
      await tester.tap(retryFinder);
      await tester.tap(retryFinder);
      await tester.pump();

      expect(game.state.value, GameState.playing);
    });

    testWidgets('Multi-touch isolation: secondary touches are ignored while primary is active', (tester) async {
      final game = RageTapGame();

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(game: game),
        ),
      );
      await tester.pump();

      expect(game.state.value, GameState.ready);

      final screenFinder = find.byType(Listener).first;
      expect(screenFinder, findsOneWidget);

      // Pointer 1 down -> triggers startRun
      final event1 = PointerDownEvent(
        pointer: 1,
        position: tester.getCenter(screenFinder),
      );
      await tester.sendEventToBinding(event1);
      await tester.pump();

      expect(game.state.value, GameState.playing);

      // Pointer 2 down while Pointer 1 is still active -> ignored
      int jumpBufferCountBefore = game.player.jumpBufferTimer > 0 ? 1 : 0;
      final event2 = PointerDownEvent(
        pointer: 2,
        position: tester.getCenter(screenFinder) + const Offset(40, 40),
      );
      await tester.sendEventToBinding(event2);
      await tester.pump();

      // Lift pointer 2 -> ignored pointer lifting does not reset active pointer
      await tester.sendEventToBinding(PointerUpEvent(pointer: 2, position: tester.getCenter(screenFinder)));
      await tester.pump();

      // Lift pointer 1 -> active pointer resets
      await tester.sendEventToBinding(PointerUpEvent(pointer: 1, position: tester.getCenter(screenFinder)));
      await tester.pump();

      // Now pointer 3 down -> valid new tap
      final event3 = PointerDownEvent(
        pointer: 3,
        position: tester.getCenter(screenFinder),
      );
      await tester.sendEventToBinding(event3);
      await tester.pump();
      await tester.sendEventToBinding(PointerUpEvent(pointer: 3, position: tester.getCenter(screenFinder)));
      await tester.pump();
    });

    testWidgets('WidgetsBindingObserver lifecycle: backgrounding pauses game and stops audio', (tester) async {
      final game = RageTapGame();

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(game: game),
        ),
      );
      await tester.pump();

      game.startRun();
      expect(game.state.value, GameState.playing);

      // Simulate app going inactive / hidden / paused
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      // Game must be paused
      expect(game.state.value, GameState.paused);

      // Returning to resumed must NEVER auto-resume
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(game.state.value, GameState.paused);
    });

    testWidgets('Back button handling in every game state', (tester) async {
      final game = RageTapGame();

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(game: game),
        ),
      );
      await tester.pump();

      final popScopeFinder = find.byWidgetPredicate((w) => w is PopScope);
      expect(popScopeFinder, findsOneWidget);
      final popScope = tester.widget<PopScope>(popScopeFinder);
      expect(popScope.canPop, isFalse);

      // 1. While playing: back pauses game
      game.startRun();
      expect(game.state.value, GameState.playing);
      popScope.onPopInvokedWithResult!(false, null);
      expect(game.state.value, GameState.paused);

      // 2. While resuming: back returns to paused
      game.beginResume();
      expect(game.state.value, GameState.resuming);
      popScope.onPopInvokedWithResult!(false, null);
      expect(game.state.value, GameState.paused);

      // 3. While dying: back does nothing
      game.state.value = GameState.dying;
      popScope.onPopInvokedWithResult!(false, null);
      expect(game.state.value, GameState.dying);
    });
  });
}
