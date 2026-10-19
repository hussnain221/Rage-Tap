import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/data/save_service.dart';
import 'package:rage_tap/ui/screens/splash_screen.dart';
import 'package:rage_tap/ui/widgets/logo.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('SplashScreen displays Logo and navigates to /home after 0.8s', (tester) async {
    SharedPreferences.setMockInitialValues({'best_score': 100});

    bool navigatedToHome = false;

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/home': (context) {
            navigatedToHome = true;
            return const Scaffold(body: Text('HOME_SCREEN'));
          },
        },
      ),
    );

    expect(find.byType(Logo), findsOneWidget);

    // Fade in animation runs over 500ms
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(Logo), findsOneWidget);

    // After 900ms (>800ms min delay), transition happens
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(navigatedToHome, isTrue);
    expect(find.text('HOME_SCREEN'), findsOneWidget);
    expect(SaveService.instance.bestScore, equals(100));
  });
}
