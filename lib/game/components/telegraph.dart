import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/palette.dart';
import '../game_state.dart';
import '../rage_tap_game.dart';
import 'obstacle.dart';

class TelegraphComponent extends PositionComponent with HasGameReference<RageTapGame> {
  TelegraphComponent()
      : super(
          position: Vector2(332, C.groundTopY - 36),
          size: Vector2(24, 24),
          priority: 10,
        );

  final Paint _trianglePaint = Paint()..color = Palette.orange;
  final Paint _strokePaint = Paint()
    ..color = Palette.bgDeep
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round;
  final Paint _dotPaint = Paint()..color = Palette.bgDeep;

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

    // Draw warning triangle (24x24)
    final path = Path()
      ..moveTo(12, 2)
      ..lineTo(22, 22)
      ..lineTo(2, 22)
      ..close();
    canvas.drawPath(path, _trianglePaint);

    // Draw exclamation mark '!'
    canvas.drawLine(const Offset(12, 8), const Offset(12, 15), _strokePaint);
    canvas.drawCircle(const Offset(12, 19), 1.2, _dotPaint);
  }
}
