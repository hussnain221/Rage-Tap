import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../../game/game_state.dart';
import '../../game/rage_tap_game.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final RageTapGame _game;
  Timer? _fpsTimer;
  double _fps = 0.0;

  @override
  void initState() {
    super.initState();
    _game = RageTapGame();
    if (kDebugMode) {
      _fpsTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (mounted) {
          setState(() {
            _fps = _game.currentFps;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _fpsTimer?.cancel();
    _game.disposeGame();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.bgDeep,
      body: Stack(
        children: [
          // Bottom layer: GameWidget with pointer down listener
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => _game.onTapDown(),
              child: GameWidget(game: _game),
            ),
          ),
          // Above it: SafeArea Stack for UI and overlays
          SafeArea(
            child: Stack(
              children: [
                // Debug overlay (only if kDebugMode)
                if (kDebugMode)
                  Positioned(
                    top: 8,
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
                          child: Text(
                            'FPS: ${_fps.toStringAsFixed(0)} | State: ${state.name}',
                            style: const TextStyle(
                              color: Palette.cyan,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (kDebugMode)
                  Positioned(
                    top: 40,
                    left: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () => _game.pause(),
                          child: const Text('Pause'),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton(
                          onPressed: () => _game.beginResume(),
                          child: const Text('Resume'),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton(
                          onPressed: () => _game.retry(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),

                // Temporary HUD: Best score top-left
                Positioned(
                  top: kDebugMode ? 74 : 16,
                  left: 12,
                  child: ValueListenableBuilder<int>(
                    valueListenable: _game.bestScore,
                    builder: (context, best, _) {
                      return Text(
                        'BEST $best',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),

                // Temporary HUD: Score top-center
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ValueListenableBuilder<int>(
                      valueListenable: _game.score,
                      builder: (context, score, _) {
                        return Text(
                          '$score',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Temporary Results UI with score, best, and retry button
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
    );
  }
}
