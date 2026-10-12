import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/palette.dart';
import '../game_state.dart';
import '../rage_tap_game.dart';

/// Ground component per spec §11.
/// Implements ground body (groundFill), glowing 3-unit cyan top edge,
/// scrolling vertical grid lines every 40 units (1.0x scroll),
/// and one horizontal grid line at world y=540 (cyan@15%).
class Ground extends PositionComponent with HasGameReference<RageTapGame> {
  Ground()
      : super(
          position: Vector2(0, C.groundTopY),
          size: Vector2(C.worldW, C.worldH - C.groundTopY),
          priority: 0,
        );

  double _scrollX = 0.0;

  static final Paint _bodyPaint = Paint()..color = Palette.groundFill;
  static final Paint _linePaint = Paint()..color = Palette.cyan;
  static final Paint _lineGlowPaint = Paint()
    ..color = Palette.cyan.withValues(alpha: 0.5)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _gridPaint = Paint()
    ..color = Palette.cyan.withValues(alpha: 0.15)
    ..strokeWidth = 1.0;

  @override
  void update(double dt) {
    super.update(dt);

    final state = game.state.value;
    double speed = 0.0;

    if (state == GameState.playing) {
      speed = game.currentSpeed;
    } else if (state == GameState.ready) {
      speed = 20.0;
    }

    if (speed > 0) {
      _scrollX = (_scrollX + speed * dt) % 40.0;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. Ground body
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      _bodyPaint,
    );

    // 2. Horizontal grid line at world y=540 (y=40 relative to Ground)
    canvas.drawLine(
      const Offset(0, 40),
      Offset(size.x, 40),
      _gridPaint,
    );

    // 3. Vertical grid lines every 40 units scrolling at 1.0x
    final startX = -_scrollX;
    for (double x = startX; x <= size.x; x += 40.0) {
      if (x >= 0) {
        canvas.drawLine(
          Offset(x, 3),
          Offset(x, size.y),
          _gridPaint,
        );
      }
    }

    // 4. Glowing 3-unit cyan line on top edge
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, 3),
      _lineGlowPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, 3),
      _linePaint,
    );
  }
}
