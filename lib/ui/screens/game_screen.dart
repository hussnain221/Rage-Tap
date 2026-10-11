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

              ],
            ),
          ),
        ],
      ),
    );
  }
}
