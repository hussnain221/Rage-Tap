import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../audio/audio_service.dart';
import '../../core/constants.dart';
import '../../core/palette.dart';
import '../../game/game_state.dart';
import '../../game/rage_tap_game.dart';
import '../widgets/hud.dart';
import '../widgets/pause_overlay.dart';
import '../widgets/ready_hint.dart';
import '../widgets/results_overlay.dart';

import '../../game/systems/difficulty.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.game,
  });

  final RageTapGame? game;

  @override
  State<GameScreen> createState() => GameScreenState();
}

class _DebugInfo {
  final double fps;
  final double speed;
  final double runTime;
  final int tier;
  final String patternId;
  final int seed;
  final String state;

  const _DebugInfo({
    required this.fps,
    required this.speed,
    required this.runTime,
    required this.tier,
    required this.patternId,
    required this.seed,
    required this.state,
  });
}

class GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final RageTapGame _game;
  ValueNotifier<_DebugInfo>? _debugNotifier;
  Timer? _debugTimer;
  int? _activePointerId;

  RageTapGame get game => _game;

  _DebugInfo get _currentDebugInfo => _DebugInfo(
        fps: _game.currentFps,
        speed: _game.currentSpeed,
        runTime: _game.runTime,
        tier: Difficulty.tier(_game.runTime),
        patternId: _game.lastPatternId ?? 'none',
        seed: _game.seed,
        state: _game.state.value.name,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = widget.game ?? RageTapGame();

    if (kDebugMode) {
      _debugNotifier = ValueNotifier<_DebugInfo>(_currentDebugInfo);
      _debugTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (mounted && _debugNotifier != null) {
          _debugNotifier!.value = _currentDebugInfo;
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debugTimer?.cancel();
    _debugNotifier?.dispose();
    if (widget.game == null) {
      _game.disposeGame();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_game.state.value == GameState.playing) {
        _game.pause();
      }
      AudioService.instance.stopAll();
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_activePointerId != null) {
      // Ignore additional touches (multi-touch) beyond the primary finger
      return;
    }
    _activePointerId = event.pointer;
    _game.onTapDown();
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer == _activePointerId) {
      _activePointerId = null;
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer == _activePointerId) {
      _activePointerId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        switch (_game.state.value) {
          case GameState.playing:
            _game.pause();
            break;
          case GameState.resuming:
            _game.pause();
            break;
          case GameState.paused:
          case GameState.ready:
          case GameState.results:
            Navigator.of(context).maybePop();
            break;
          case GameState.dying:
            // Ignore back during 0.42s death sequence so run results finalize cleanly
            break;
        }
      },
      child: Scaffold(
        backgroundColor: Palette.bgDeep,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Bottom layer: GameWidget wrapped in RepaintBoundary and Listener
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: _onPointerDown,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerCancel,
                child: RepaintBoundary(
                  child: GameWidget(game: _game),
                ),
              ),
            ),

            // Rage Mode screen edge tint (§20.1)
            if (C.rageEnabled)
              Positioned.fill(
                child: IgnorePointer(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _game.isRageActive,
                    builder: (context, isRage, _) {
                      return AnimatedOpacity(
                        opacity: isRage ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 150),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              radius: 1.1,
                              colors: [
                                Colors.transparent,
                                Palette.magenta.withValues(alpha: C.rageOverlayAlpha),
                              ],
                              stops: const [0.75, 1.0],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Above it: SafeArea Stack for UI and HUD
            SafeArea(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // HUD at the top
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: GameHud(game: _game),
                  ),

                  // Debug overlay & hitbox toggle corner (kDebugMode only)
                  if (kDebugMode) ...[
                    Positioned(
                      top: 0,
                      left: 0,
                      child: _DebugCornerHitboxToggle(game: _game),
                    ),
                    if (_debugNotifier != null)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _game.showHitboxes,
                          builder: (context, hitboxesOn, _) {
                            return ValueListenableBuilder<_DebugInfo>(
                              valueListenable: _debugNotifier!,
                              builder: (context, info, _) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Palette.cyan.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'FPS: ${info.fps.toStringAsFixed(0)} | Speed: ${info.speed.toStringAsFixed(0)} | Time: ${info.runTime.toStringAsFixed(1)}s | Tier: ${info.tier} | Pattern: ${info.patternId} | Seed: ${info.seed} | State: ${info.state} | Hitbox: ${hitboxesOn ? "ON" : "OFF"}',
                                    style: const TextStyle(
                                      color: Palette.cyan,
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                  ],

                  // Ready hint when in ready state (wrapped in IgnorePointer)
                  ValueListenableBuilder<GameState>(
                    valueListenable: _game.state,
                    builder: (context, state, _) {
                      if (state == GameState.ready) {
                        return const IgnorePointer(
                          child: ReadyHint(),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                    // Pause Overlay (shown when state == GameState.paused)
                    ValueListenableBuilder<GameState>(
                      valueListenable: _game.state,
                      builder: (context, state, _) {
                        if (state == GameState.paused) {
                          return PauseOverlay(game: _game);
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    // Resume Countdown Overlay (shown when state == GameState.resuming)
                    ValueListenableBuilder<GameState>(
                      valueListenable: _game.state,
                      builder: (context, state, _) {
                        if (state == GameState.resuming) {
                          return ResumeCountdownOverlay(game: _game);
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    // Results Overlay (shown when state == GameState.results)
                    ValueListenableBuilder<GameState>(
                      valueListenable: _game.state,
                      builder: (context, state, _) {
                        if (state == GameState.results) {
                          return ResultsOverlay(game: _game);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}

class _DebugCornerHitboxToggle extends StatefulWidget {
  const _DebugCornerHitboxToggle({required this.game});
  final RageTapGame game;

  @override
  State<_DebugCornerHitboxToggle> createState() => _DebugCornerHitboxToggleState();
}

class _DebugCornerHitboxToggleState extends State<_DebugCornerHitboxToggle> {
  Timer? _timer;

  void _onPointerDown(PointerDownEvent event) {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        widget.game.showHitboxes.value = !widget.game.showHitboxes.value;
      }
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    _timer?.cancel();
    _timer = null;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: const SizedBox(
        width: 64,
        height: 64,
      ),
    );
  }
}
