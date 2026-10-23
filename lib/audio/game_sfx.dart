import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dart wrapper for the native [GameSfx] Android plugin.
///
/// All SoundPool operations run on a THREAD_PRIORITY_URGENT_AUDIO HandlerThread
/// in Kotlin, so soundPool.play() never blocks Android's Choreographer vsync
/// callback. result.success(null) is returned to Dart before any SoundPool work,
/// meaning every call here is effectively fire-and-forget with zero blocking.
///
/// On non-Android platforms (iOS, tests) all methods are no-ops.
class GameSfx {
  static const _ch = MethodChannel('com.ragetap/sfx');

  static bool get _active {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid &&
          !Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  /// Preload [filenames] from assets/audio/ into the native SoundPool.
  /// Fire-and-forget; loading happens on the bg thread.
  static void load(List<String> filenames) {
    if (!_active) return;
    _ch
        .invokeMethod<void>('load', {
          'sounds': filenames.map((f) => {'name': f, 'file': f}).toList(),
        })
        .catchError((_) {});
  }

  /// Play a preloaded sound. Truly fire-and-forget; runs on bg thread.
  static void play(String filename, double volume) {
    if (!_active) return;
    _ch
        .invokeMethod<void>('play', {'name': filename, 'volume': volume})
        .catchError((_) {});
  }

  /// Start (enable=true) or stop (enable=false) the inaudible silence loop
  /// that keeps the audio DAC and mixer thread awake between game sounds.
  static void setKeepAlive({required bool enable}) {
    if (!_active) return;
    _ch
        .invokeMethod<void>('keepAlive', {'enable': enable})
        .catchError((_) {});
  }
}
