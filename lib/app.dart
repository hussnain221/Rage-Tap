import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'ui/screens/game_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/widget_gallery_screen.dart';

class RageTapApp extends StatelessWidget {
  const RageTapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rage Tap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/':
            page = const SplashScreen();
            break;
          case '/home':
            page = const HomeScreen();
            break;
          case '/game':
            page = const GameScreen();
            break;
          case '/settings':
            page = const SettingsScreen();
            break;
          case '/widgets':
            if (kDebugMode) {
              page = const WidgetGalleryScreen();
            } else {
              page = const SplashScreen();
            }
            break;
          default:
            page = const SplashScreen();
            break;
        }

        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 180),
        );
      },
    );
  }
}
