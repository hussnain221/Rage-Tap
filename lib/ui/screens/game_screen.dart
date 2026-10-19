import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../../game/game_state.dart';
import '../../game/rage_tap_game.dart';
import '../widgets/hud.dart';
import '../widgets/pause_overlay.dart';
import '../widgets/ready_hint.dart';
import '../widgets/results_overlay.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final RageTapGame _game;
  final ValueNotifier<double> _fpsNotifier = ValueNotifier<double>(0.0);
  Timer? _fpsTimer;

  @override
  void initState() {
    super.initState();
    _game = RageTapGame();

    if (kDebugMode) {
      _fpsTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (mounted) {
          _fpsNotifier.value = _game.currentFps;
        }
      });
    }
  }

  @override
  void dispose() {
    _fpsTimer?.cancel();
    _fpsNotifier.dispose();
    _game.disposeGame();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_game.state.value == GameState.playing) {
          _game.pause();
        } else {
          Navigator.of(context).maybePop();
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
                onPointerDown: (_) => _game.onTapDown(),
                child: RepaintBoundary(
                  child: GameWidget(game: _game),
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

                  // Debug overlay (at bottom-left in kDebugMode)
                  if (kDebugMode)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: ValueListenableBuilder<GameState>(
                        valueListenable: _game.state,
                        builder: (context, state, _) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: ValueListenableBuilder<double>(
                              valueListenable: _fpsNotifier,
                              builder: (context, fps, _) {
                                return Text(
                                  'FPS: ${fps.toStringAsFixed(0)} | State: ${state.name} | Seed: ${_game.seed} | Pattern: ${_game.lastPatternId ?? "none"}',
                                  style: const TextStyle(
                                    color: Palette.cyan,
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),

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
