import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/data/save_service.dart';
import 'package:rage_tap/game/rage_tap_game.dart';
import 'package:rage_tap/ui/screens/home_screen.dart';
import 'package:rage_tap/ui/screens/settings_screen.dart';
import 'package:rage_tap/ui/widgets/results_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const targetSizes = [
    Size(320, 568),  // Compact (iPhone SE 1st gen)
    Size(360, 800),  // Standard Android
    Size(412, 915),  // Tall Android
    Size(800, 1280), // Tablet
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'best_score': 123,
      'sound_enabled': true,
      'haptics_enabled': true,
    });
    await SaveService.instance.init();
  });

  group('Prompt 3.9 Responsive Layout & No Overflow Tests', () {
    for (final size in targetSizes) {
      testWidgets('HomeScreen renders without overflow at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull, reason: 'Overflow exception on HomeScreen at $size');
        expect(find.text('PLAY'), findsOneWidget);
        expect(find.text('123'), findsOneWidget);
      });

      testWidgets('SettingsScreen renders without overflow at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          const MaterialApp(
            home: SettingsScreen(),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull, reason: 'Overflow exception on SettingsScreen at $size');
        expect(find.text('SETTINGS'), findsOneWidget);
        expect(find.text('Sound Effects'), findsOneWidget);
        expect(find.text('RESET PROGRESS'), findsOneWidget);
      });

      testWidgets('ResultsOverlay renders without overflow at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final game = RageTapGame();
        await game.onLoad();
        game.score.value = 88;
        game.bestScore.value = 123;
        game.isNewBest.value = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResultsOverlay(game: game),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull, reason: 'Overflow exception on ResultsOverlay at $size');
        expect(find.text('GAME OVER'), findsOneWidget);
        expect(find.text('RETRY'), findsOneWidget);
        expect(find.text('HOME'), findsOneWidget);
      });

      testWidgets('ResultsOverlay with NEW BEST badge renders without overflow at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final game = RageTapGame();
        await game.onLoad();
        game.score.value = 150;
        game.bestScore.value = 150;
        game.isNewBest.value = true;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResultsOverlay(game: game),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull, reason: 'Overflow exception on ResultsOverlay (new best) at $size');
        expect(find.text('GAME OVER'), findsOneWidget);
        expect(find.text('★ NEW BEST! ★'), findsOneWidget);
      });
    }
  });
}
