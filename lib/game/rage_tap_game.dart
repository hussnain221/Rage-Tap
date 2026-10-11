import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/palette.dart';
import 'components/ground.dart';
import 'game_state.dart';

class RageTapGame extends FlameGame {
  RageTapGame()
      : super(
          camera: CameraComponent.withFixedResolution(
            width: C.worldW,
            height: C.worldH,
            viewfinder: Viewfinder()..anchor = Anchor.topLeft,
          ),
        );

  final ValueNotifier<GameState> state = ValueNotifier<GameState>(GameState.ready);
  final ValueNotifier<int> score = ValueNotifier<int>(0);
  final ValueNotifier<int> bestScore = ValueNotifier<int>(0);
  final ValueNotifier<bool> isNewBest = ValueNotifier<bool>(false);
  final ValueNotifier<int> resumeCountdown = ValueNotifier<int>(0);

  FpsComponent? _fpsComponent;

  double get currentFps => _fpsComponent?.fps ?? 0.0;

  @override
  Color backgroundColor() => Palette.bgDeep;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (kDebugMode) {
      _fpsComponent = FpsComponent();
      add(_fpsComponent!);
    }
    await world.add(Ground());
  }

  @override
  void update(double dt) {
    final clampedDt = dt.clamp(0.0, C.maxDt).toDouble();
    super.update(clampedDt);
  }

  void onTapDown() {
    // Empty for now; physics and jumping will be hooked in Prompt 1.3
  }

  void disposeGame() {
    state.dispose();
    score.dispose();
    bestScore.dispose();
    isNewBest.dispose();
    resumeCountdown.dispose();
  }
}
