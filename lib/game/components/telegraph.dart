import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../game_state.dart';
import '../painting/hazard_painters.dart';
import '../rage_tap_game.dart';
import 'obstacle.dart';

class TelegraphComponent extends PositionComponent with HasGameReference<RageTapGame> {
  TelegraphComponent()
      : super(
          position: Vector2(332, C.groundTopY - 36),
          size: Vector2(24, 24),
          priority: 10,
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (game.state.value != GameState.playing) return;

    final hasChargingOffscreen = game.world.children
        .whereType<Obstacle>()
        .any((obs) => obs.type == ObstacleType.charging && obs.x > C.worldW);

    if (!hasChargingOffscreen) return;

    // Pulse/flash at ~6 Hz (6 full cycles per second)
    final flashOn = (game.runTime * 12).floor() % 2 == 0;
    if (!flashOn) return;

    HazardPainters.paintTelegraph(canvas, t: game.runTime);
  }
}
