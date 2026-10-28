import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/data/save_service.dart';
import 'package:rage_tap/ui/screens/home_screen.dart';
import 'package:rage_tap/ui/widgets/home_zap.dart';
import 'package:rage_tap/ui/widgets/logo.dart';
import 'package:rage_tap/ui/widgets/neon_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'best_score': 456, 'total_coins': 88});
    await SaveService.instance.init();
  });

  testWidgets('HomeScreen renders all elements and navigates to play', (tester) async {
    bool playNavigated = false;

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/home',
        routes: {
          '/home': (context) => const HomeScreen(),
          '/game': (context) {
            playNavigated = true;
            return const Scaffold(body: Text('GAME_SCREEN'));
          },
        },
      ),
    );

    // Initial render
    expect(find.byType(Logo), findsOneWidget);
    expect(find.text('One tap. One mistake. One more try.'), findsOneWidget);
    expect(find.byType(HomeZap), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('456'), findsOneWidget);
    expect(find.text('88'), findsOneWidget);
    expect(find.byIcon(Icons.monetization_on_rounded), findsOneWidget);
    expect(find.text('v1.0.0'), findsOneWidget);
    expect(find.byType(NeonIconButton), findsOneWidget);

    // Tap PLAY -> navigate to /game
    await tester.tap(find.text('PLAY'));
    await tester.pumpAndSettle();
    expect(playNavigated, isTrue);
  });

  testWidgets('HomeScreen settings button navigates to /settings', (tester) async {
    bool settingsNavigated = false;

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/home',
        routes: {
          '/home': (context) => const HomeScreen(),
          '/settings': (context) {
            settingsNavigated = true;
            return const Scaffold(body: Text('SETTINGS_SCREEN'));
          },
        },
      ),
    );

    await tester.tap(find.byType(NeonIconButton));
    await tester.pumpAndSettle();
    expect(settingsNavigated, isTrue);
  });

  testWidgets('HomeScreen does not overflow on small screen 320x568', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(find.text('PLAY'), findsOneWidget);
  });

  testWidgets('HomeScreen does not overflow on tall screen 412x915', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(find.text('PLAY'), findsOneWidget);
  });
}
