import 'dart:io';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../data/save_service.dart';
import 'game_sfx.dart';

/// Preloaded, zero-allocation audio channel using low-latency SoundPool (iOS/fallback).
class _SfxChannel {
  _SfxChannel({
    required this.file,
    required this.volume,
    required this.count,
  });

  final String file;
  final double volume;
  final int count;
  final List<AudioPlayer> _players = [];
  final Set<AudioPlayer> _playing = {};
  int _cursor = 0;

  static final AudioContext _gameAudioContext = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.ambient,
      options: const {},
    ),
  );

  static bool get _isTest {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  Future<void> init() async {
    if (_players.isNotEmpty) return;
    for (int i = 0; i < count; i++) {
      try {
        final player = AudioPlayer()..audioCache = FlameAudio.audioCache;
        player.positionUpdater = null;
        if (!_isTest) {
          await player.setAudioContext(_gameAudioContext);
        }
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setVolume(volume);
        await player.setSource(AssetSource(file));
        _players.add(player);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('AudioService _SfxChannel init warning ($file): $e');
        }
      }
    }
  }

  void play() {
    if (_players.isEmpty) return;
    final player = _players[_cursor];
    _cursor = (_cursor + 1) % _players.length;

    if (_playing.contains(player)) {
      player.stop().then((_) {
        _playing.add(player);
        return player.resume();
      }).catchError((_) {});
    } else {
      _playing.add(player);
      player.resume().catchError((_) {});
    }

    Future.delayed(const Duration(milliseconds: 180), () {
      _playing.remove(player);
      player.stop().catchError((_) {});
    });
  }

  void stop() {
    _playing.clear();
    for (final player in _players) {
      player.stop().catchError((_) {});
    }
  }

  Future<void> dispose() async {
    _playing.clear();
    for (final player in _players) {
      try {
        await player.dispose();
      } catch (_) {}
    }
  }
}

/// Audio service for managing and playing procedural SFX per spec Â§13.2.
///
/// On Android the native [GameSfx] plugin is used so all SoundPool operations
/// run on a THREAD_PRIORITY_URGENT_AUDIO HandlerThread and never block the
/// Choreographer vsync callback â†’ smooth 60 fps even with sound enabled.
/// On iOS the existing audioplayers channel path is kept.
class AudioService {
  AudioService._() {
    _jumpChannel = _SfxChannel(file: sfxJump, volume: 0.85, count: 4);
    _landChannel = _SfxChannel(file: sfxLand, volume: 0.40, count: 1);
    _hitChannel = _SfxChannel(file: sfxHit, volume: 0.90, count: 1);
    _nearMissChannel = _SfxChannel(file: sfxNearMiss, volume: 0.85, count: 2);
    _newBestChannel = _SfxChannel(file: sfxNewBest, volume: 0.95, count: 1);
    _clickChannel = _SfxChannel(file: sfxClick, volume: 0.60, count: 2);
    _fallChannel = _SfxChannel(file: sfxFall, volume: 0.80, count: 1);

    _channels = [
      _jumpChannel,
      _landChannel,
      _hitChannel,
      _nearMissChannel,
      _newBestChannel,
      _clickChannel,
      _fallChannel,
    ];
  }
  static final AudioService instance = AudioService._();

  static const String sfxJump = 'jump.wav';
  static const String sfxLand = 'land.wav';
  static const String sfxHit = 'hit.wav';
  static const String sfxNearMiss = 'near_miss.wav';
  static const String sfxNewBest = 'new_best.wav';
  static const String sfxClick = 'click.wav';
  static const String sfxFall = 'fall.wav';
  static const String sfxSilence = 'silence.wav';

  static const List<String> allFiles = [
    sfxJump,
    sfxLand,
    sfxHit,
    sfxNearMiss,
    sfxNewBest,
    sfxClick,
    sfxFall,
  ];

  late final _SfxChannel _jumpChannel;
  late final _SfxChannel _landChannel;
  late final _SfxChannel _hitChannel;
  late final _SfxChannel _nearMissChannel;
  late final _SfxChannel _newBestChannel;
  late final _SfxChannel _clickChannel;
  late final _SfxChannel _fallChannel;
  late final List<_SfxChannel> _channels;

  bool _initialized = false;
  bool _ready = false;

  // Android: tracks keepAlive state to avoid redundant MethodChannel calls.
  bool _keepAliveActive = false;

  // iOS/fallback: audioplayers keepAlive player.
  AudioPlayer? _keepAlivePlayer;

  static bool get _hasBinding {
    try {
      WidgetsBinding.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  // True when running on real Android (not test, not web).
  static bool get _isAndroid {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  /// Preloads all audio files and initialises audio channels.
  Future<void> init() async {
    if (_initialized || !_hasBinding) return;
    _initialized = true;

    if (_SfxChannel._isTest) {
      _ready = true;
      return;
    }

    if (_isAndroid) {
      // â”€â”€ Android path â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      // Load all sounds into the native SoundPool on a background thread.
      // Sound files are ready well before the splash screen finishes (~500 ms).
      GameSfx.load([...allFiles, sfxSilence]);

      _ready = true;

      // Start the inaudible keepAlive loop after a short delay so silence.wav
      // has time to be loaded into the native SoundPool.
      if (SaveService.instance.soundEnabled) {
        Future.delayed(const Duration(milliseconds: 600), () {
          GameSfx.setKeepAlive(enable: true);
          _keepAliveActive = true;
        });
      }
    } else {
      // â”€â”€ iOS / other path â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      try {
        await AudioPlayer.global.setAudioContext(_SfxChannel._gameAudioContext);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('AudioService.init global audio context warning: $e');
        }
      }

      try {
        await FlameAudio.audioCache
            .loadAll([...allFiles, sfxSilence])
            .timeout(const Duration(milliseconds: 1000));
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('AudioService.init cache warning: $e\n$st');
        }
      }

      try {
        await Future.wait(_channels.map((c) => c.init()))
            .timeout(const Duration(milliseconds: 1500));
      } catch (e) {
        if (kDebugMode) {
          debugPrint('AudioService.init channels warning: $e');
        }
      }

      // Inaudible silence loop keeps the DAC awake between game sounds.
      try {
        final keepAlive = AudioPlayer()..audioCache = FlameAudio.audioCache;
        keepAlive.positionUpdater = null;
        await keepAlive.setAudioContext(_SfxChannel._gameAudioContext);
        await keepAlive.setPlayerMode(PlayerMode.lowLatency);
        await keepAlive.setReleaseMode(ReleaseMode.loop);
        await keepAlive.setVolume(0.001);
        await keepAlive.setSource(AssetSource(sfxSilence));
        _keepAlivePlayer = keepAlive;
        if (SaveService.instance.soundEnabled) {
          await keepAlive.resume();
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('AudioService keepAlive init warning: $e');
        }
      }

      _ready = true;
    }
  }

  void _syncKeepAlive() {
    if (_SfxChannel._isTest) return;

    if (_isAndroid) {
      final want = SaveService.instance.soundEnabled;
      if (want != _keepAliveActive) {
        _keepAliveActive = want;
        GameSfx.setKeepAlive(enable: want);
      }
    } else {
      if (_keepAlivePlayer == null) return;
      if (SaveService.instance.soundEnabled) {
        if (_keepAlivePlayer!.state != PlayerState.playing) {
          _keepAlivePlayer!.resume().catchError((_) {});
        }
      } else {
        if (_keepAlivePlayer!.state == PlayerState.playing) {
          _keepAlivePlayer!.stop().catchError((_) {});
        }
      }
    }
  }

  void _playChannel(_SfxChannel channel) {
    if (!SaveService.instance.soundEnabled || !_hasBinding || !_ready) return;
    _syncKeepAlive();

    if (_isAndroid) {
      // Android: native bg-thread SoundPool, no main-thread blocking.
      GameSfx.play(channel.file, channel.volume);
    } else {
      // iOS/other: audioplayers channel.
      channel.play();
    }
  }

  /// Play jump sound on takeoff.
  void playJump() => _playChannel(_jumpChannel);

  /// Play landing thump (low volume) when Zap lands on the ground.
  void playLand() => _playChannel(_landChannel);

  /// Play crash impact sound when player dies.
  void playHit() => _playChannel(_hitChannel);

  /// Play bright two-tone near-miss sound.
  void playNearMiss() => _playChannel(_nearMissChannel);

  /// Play celebratory arpeggio when a new best score is achieved.
  void playNewBest() => _playChannel(_newBestChannel);

  /// Play UI click blip on button press.
  void playClick() => _playChannel(_clickChannel);

  /// Play fall sound when player falls into a pit.
  void playFall() {
    try {
      _playChannel(_fallChannel);
    } catch (_) {}
  }

  /// Stop all active audio (e.g. when backgrounding or pausing).
  void stopAll() {
    if (!_hasBinding) return;
    if (_isAndroid) {
      if (_keepAliveActive) {
        GameSfx.setKeepAlive(enable: false);
        _keepAliveActive = false;
      }
    } else {
      _keepAlivePlayer?.stop().catchError((_) {});
      for (final channel in _channels) {
        channel.stop();
      }
    }
  }

  /// Release resources when disposing service.
  Future<void> dispose() async {
    _ready = false;
    if (_isAndroid) {
      GameSfx.setKeepAlive(enable: false);
      _keepAliveActive = false;
    } else {
      try {
        await _keepAlivePlayer?.dispose();
      } catch (_) {}
      _keepAlivePlayer = null;
      for (final channel in _channels) {
        await channel.dispose();
      }
    }
  }
}

/// Haptics wrapper honoring SaveService.hapticsEnabled per spec Â§13.3.
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

  /// Fall into pit -> mediumImpact
  static void fall() {
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
