import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../../game/game_state.dart';
import '../../game/rage_tap_game.dart';
import '../widgets/hud.dart';

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
        body: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _game.onTapDown(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Bottom layer: GameWidget wrapped in RepaintBoundary
              Positioned.fill(
                child: RepaintBoundary(
                  child: GameWidget(game: _game),
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

                    // Ready hint when in ready state (until Prompt 3.5 replaces it)
                    ValueListenableBuilder<GameState>(
                      valueListenable: _game.state,
                      builder: (context, state, _) {
                        if (state == GameState.ready) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'READY',
                                  style: TextStyle(
                                    color: Palette.cyan,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4.0,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'TAP TO JUMP',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    // Temporary Results UI with score, best, and retry button (until Prompt 3.7)
                    ValueListenableBuilder<GameState>(
                      valueListenable: _game.state,
                      builder: (context, state, _) {
                        if (state == GameState.results) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ValueListenableBuilder<int>(
                                  valueListenable: _game.score,
                                  builder: (context, score, _) {
                                    return Text(
                                      'SCORE: $score',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 6),
                                ValueListenableBuilder<int>(
                                  valueListenable: _game.bestScore,
                                  builder: (context, best, _) {
                                    return Text(
                                      'BEST: $best',
                                      style: const TextStyle(
                                        color: Palette.yellow,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                                ValueListenableBuilder<bool>(
                                  valueListenable: _game.isNewBest,
                                  builder: (context, isNewBest, _) {
                                    if (isNewBest) {
                                      return const Padding(
                                        padding: EdgeInsets.only(top: 6),
                                        child: Text(
                                          '★ NEW BEST! ★',
                                          style: TextStyle(
                                            color: Palette.yellow,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Palette.cyan,
                                    foregroundColor: Palette.bgDeep,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 40,
                                      vertical: 18,
                                    ),
                                  ),
                                  onPressed: () => _game.retry(),
                                  child: const Text(
                                    'Retry',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
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
      ),
    );
  }
}
