import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/core/constants.dart';
import 'package:rage_tap/data/save_service.dart';
import 'package:rage_tap/ui/screens/settings_screen.dart';
import 'package:rage_tap/ui/widgets/neon_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'best_score': 350,
      'total_runs': 42,
      'sound_enabled': true,
      'haptics_enabled': true,
    });
    await SaveService.instance.init();
  });

  testWidgets('SettingsScreen renders all tiles and version', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsScreen(),
      ),
    );

    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('Sound Effects'), findsOneWidget);
    expect(find.text('Vibration'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Credits'), findsOneWidget);
    expect(find.text('RESET PROGRESS'), findsOneWidget);
    expect(find.text(C.appVersion), findsOneWidget);
  });

  testWidgets('SettingsScreen toggles sound and vibration switches', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsScreen(),
      ),
    );

    expect(SaveService.instance.soundEnabled, isTrue);
    expect(SaveService.instance.hapticsEnabled, isTrue);

    // Toggle sound switch
    final switches = find.byType(Switch);
    expect(switches, findsNWidgets(2));

    await tester.tap(switches.at(0));
    await tester.pumpAndSettle();
    expect(SaveService.instance.soundEnabled, isFalse);

    // Toggle vibration switch
    await tester.tap(switches.at(1));
    await tester.pumpAndSettle();
    expect(SaveService.instance.hapticsEnabled, isFalse);
  });

  testWidgets('SettingsScreen opens Credits dialog', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsScreen(),
      ),
    );

    await tester.tap(find.text('Credits'));
    await tester.pumpAndSettle();

    expect(find.textContaining('made by ${C.publisherName}'), findsOneWidget);
    expect(find.textContaining('Sound effects generated procedurally'), findsOneWidget);

    // Close credits
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sound effects generated procedurally'), findsNothing);
  });

  testWidgets('SettingsScreen opens Privacy Policy dialog when URL is unset', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsScreen(),
      ),
    );

    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Information we collect'), findsOneWidget);

    // Close privacy policy
    await tester.tap(find.text('CLOSE'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Information we collect'), findsNothing);
  });

  testWidgets('SettingsScreen reset progress flow cancels without wiping', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsScreen(),
      ),
    );

    await tester.tap(find.text('RESET PROGRESS'));
    await tester.pumpAndSettle();

    expect(find.text('Reset Progress?'), findsOneWidget);
    expect(find.text('This resets your best score. This cannot be undone.'), findsOneWidget);

    // Cancel
    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();

    expect(SaveService.instance.bestScore, equals(350));
    expect(SaveService.instance.totalRuns, equals(42));
  });

  testWidgets('SettingsScreen reset progress flow confirms and resets score', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsScreen(),
      ),
    );

    await tester.tap(find.text('RESET PROGRESS'));
    await tester.pumpAndSettle();

    // Confirm RESET
    await tester.tap(find.text('RESET'));
    await tester.pumpAndSettle();

    expect(SaveService.instance.bestScore, equals(0));
    expect(SaveService.instance.totalRuns, equals(0));
    expect(find.text('Progress reset successfully.'), findsOneWidget);
  });

  testWidgets('SettingsScreen back button navigates back', (tester) async {
    bool popped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(
          onGenerateRoute: (settings) => MaterialPageRoute(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ).then((_) => popped = true);
                  },
                  child: const Text('OPEN'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    expect(find.text('SETTINGS'), findsOneWidget);

    // Tap back button
    await tester.tap(find.byType(NeonIconButton));
    await tester.pumpAndSettle();

    expect(popped, isTrue);
  });
}
