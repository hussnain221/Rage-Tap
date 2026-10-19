import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../data/save_service.dart';

/// Audio service for managing and playing procedural SFX per spec §13.2.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  static const String sfxJump = 'jump.wav';
  static const String sfxLand = 'land.wav';
  static const String sfxHit = 'hit.wav';
  static const String sfxNearMiss = 'near_miss.wav';
  static const String sfxNewBest = 'new_best.wav';
  static const String sfxClick = 'click.wav';

  static const List<String> allFiles = [
    sfxJump,
    sfxLand,
    sfxHit,
    sfxNearMiss,
    sfxNewBest,
    sfxClick,
  ];

  bool _initialized = false;
  AudioPool? _jumpPool;
  AudioPool? _nearMissPool;

  static bool get _hasBinding {
    try {
      WidgetsBinding.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Preloads all audio files into cache and initializes audio pools without blocking.
  Future<void> init() async {
    if (_initialized || !_hasBinding) return;
    _initialized = true;
    try {
      await FlameAudio.audioCache
          .loadAll(allFiles)
          .timeout(const Duration(milliseconds: 250));
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('AudioService.init cache warning: $e\n$st');
      }
    }
    _initPoolsAsync();
  }

  void _initPoolsAsync() async {
    try {
      _jumpPool = await FlameAudio.createPool(sfxJump, minPlayers: 2, maxPlayers: 4)
          .timeout(const Duration(milliseconds: 500));
    } catch (_) {}

    try {
      _nearMissPool = await FlameAudio.createPool(sfxNearMiss, minPlayers: 2, maxPlayers: 4)
          .timeout(const Duration(milliseconds: 500));
    } catch (_) {}
  }

  void _runAsync(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AudioService error: $e');
      }
    }
  }

  void _safePlay(String file, double volume) {
    if (!SaveService.instance.soundEnabled || !_hasBinding) return;
    _runAsync(() async {
      await FlameAudio.play(file, volume: volume);
    });
  }

  void _safePlayPool(AudioPool? pool, String fallbackFile, double volume) {
    if (!SaveService.instance.soundEnabled || !_hasBinding) return;
    _runAsync(() async {
      if (pool != null) {
        try {
          await pool.start(volume: volume);
        } catch (_) {
          await FlameAudio.play(fallbackFile, volume: volume);
        }
      } else {
        await FlameAudio.play(fallbackFile, volume: volume);
      }
    });
  }

  /// Play jump sound on takeoff.
  void playJump() {
    _safePlayPool(_jumpPool, sfxJump, 0.85);
  }

  /// Play landing thump (low volume) when Zap lands on the ground.
  void playLand() {
    _safePlay(sfxLand, 0.40);
  }

  /// Play crash impact sound when player dies.
  void playHit() {
    _safePlay(sfxHit, 0.90);
  }

  /// Play bright two-tone near-miss sound.
  void playNearMiss() {
    _safePlayPool(_nearMissPool, sfxNearMiss, 0.85);
  }

  /// Play celebratory arpeggio when a new best score is achieved.
  void playNewBest() {
    _safePlay(sfxNewBest, 0.95);
  }

  /// Play UI click blip on button press.
  void playClick() {
    _safePlay(sfxClick, 0.60);
  }

  /// Stop all active audio (e.g. when backgrounding or pausing).
  void stopAll() {
    if (!_initialized || !_hasBinding) return;
    _runAsync(() async {
      await FlameAudio.bgm.stop();
    });
  }
}

/// Haptics wrapper honoring SaveService.hapticsEnabled per spec §13.3.
class HapticsService {
  const HapticsService._();

  static bool get _hasBinding {
    try {
      WidgetsBinding.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Hit -> mediumImpact
  static void hit() {
    if (!SaveService.instance.hapticsEnabled || !_hasBinding) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Near-miss -> lightImpact
  static void nearMiss() {
    if (!SaveService.instance.hapticsEnabled || !_hasBinding) return;
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Button press -> selectionClick
  static void buttonPress() {
    if (!SaveService.instance.hapticsEnabled || !_hasBinding) return;
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }
}
