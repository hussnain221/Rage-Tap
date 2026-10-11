import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/palette.dart';

class Ground extends PositionComponent {
  Ground()
      : super(
          position: Vector2(0, C.groundTopY),
          size: Vector2(C.worldW, C.worldH - C.groundTopY),
        );

  final Paint _bodyPaint = Paint()..color = Palette.groundFill;
  final Paint _linePaint = Paint()..color = Palette.cyan;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Ground body
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      _bodyPaint,
    );
    // 3-unit cyan line on top
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, 3),
      _linePaint,
    );
  }
}
