import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'audio/audio_service.dart';
import 'core/theme.dart';
import 'data/ads_service.dart';
import 'ui/screens/daily_challenge_screen.dart';
import 'ui/screens/game_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/shop_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/widget_gallery_screen.dart';

class RageTapApp extends StatefulWidget {
  const RageTapApp({super.key});

  @override
  State<RageTapApp> createState() => _RageTapAppState();
}

class _RageTapAppState extends State<RageTapApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      AudioService.instance.stopAll();
    } else if (state == AppLifecycleState.resumed) {
      AudioService.instance.resumeKeepAliveIfEnabled();
    } else if (state == AppLifecycleState.detached) {
      AudioService.instance.dispose();
      AdsService.instance.dispose();
    }
  }

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
          case '/daily':
            page = const DailyChallengeScreen();
            break;
          case '/shop':
            page = const ShopScreen();
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
