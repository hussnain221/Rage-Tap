import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../audio/audio_service.dart';
import '../../core/palette.dart';
import '../../data/save_service.dart';
import '../widgets/logo.dart';

/// Splash screen that animates the neon Logo in over 0.5s, initializes
/// SaveService in parallel, and fades to Home after 0.8s - 1.2s.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();
    _startParallelInitialization();
  }

  Future<void> _startParallelInitialization() async {
    final minWait = Future.delayed(const Duration(milliseconds: 800));

    final initTask = () async {
      try {
        await SaveService.instance.init();
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('SaveService init warning in splash: $e\n$st');
        }
      }
    }();

    final initAudio = () async {
      try {
        await AudioService.instance.init();
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('AudioService init warning in splash: $e\n$st');
        }
      }
    }();

    try {
      await Future.wait([minWait, initTask, initAudio]).timeout(
        const Duration(milliseconds: 1200),
        onTimeout: () => [null, null, null],
      );
    } catch (_) {
      // Continue with defaults on any error or timeout
    }

    if (mounted && !_navigated) {
      _navigated = true;
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.bgDeep,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: const Logo(fontSize: 64),
        ),
      ),
    );
  }
}
