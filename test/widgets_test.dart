import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/core/palette.dart';
import 'package:rage_tap/ui/screens/widget_gallery_screen.dart';
import 'package:rage_tap/ui/widgets/logo.dart';
import 'package:rage_tap/ui/widgets/neon_button.dart';

void main() {
  testWidgets('Logo renders RAGE in cyan and TAP in magenta', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Logo(fontSize: 64),
        ),
      ),
    );

    expect(find.text('RAGE'), findsOneWidget);
    expect(find.text('TAP'), findsOneWidget);

    final rageWidget = tester.widget<Text>(find.text('RAGE'));
    final tapWidget = tester.widget<Text>(find.text('TAP'));

    expect(rageWidget.style?.color, equals(Palette.cyan));
    expect(tapWidget.style?.color, equals(Palette.magenta));
    expect(rageWidget.style?.fontSize, equals(64.0));
  });

  testWidgets('NeonButton primary renders and triggers onPressed', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NeonButton.primary(
            text: 'PLAY',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('PLAY'), findsOneWidget);
    await tester.tap(find.text('PLAY'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('NeonButton disabled has 40% opacity and does not trigger onPressed', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NeonButton.primary(
            text: 'DISABLED',
            onPressed: null,
          ),
        ),
      ),
    );

    final opacityWidget = tester.widget<Opacity>(find.byType(Opacity).first);
    expect(opacityWidget.opacity, closeTo(0.40, 0.01));
  });

  testWidgets('NeonButton variants secondary and danger render correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              NeonButton.secondary(
                text: 'RESTART',
                onPressed: () {},
              ),
              NeonButton.danger(
                text: 'RESET',
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('RESTART'), findsOneWidget);
    expect(find.text('RESET'), findsOneWidget);
  });

  testWidgets('NeonIconButton renders icon and triggers callback', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NeonIconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.settings), findsOneWidget);
    await tester.tap(find.byType(NeonIconButton));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('WidgetGalleryScreen mounts and displays all demo widgets', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WidgetGalleryScreen(),
      ),
    );

    expect(find.text('Widget Gallery (Debug)'), findsOneWidget);
    expect(find.byType(Logo), findsNWidgets(2));
    expect(find.textContaining('PLAY NOW'), findsOneWidget);
    expect(find.text('RESTART RUN'), findsOneWidget);
    expect(find.text('RESET PROGRESS'), findsOneWidget);
    expect(find.byType(NeonIconButton), findsNWidgets(4));
  });
}
