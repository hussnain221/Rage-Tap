import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/palette.dart';

class PopupText extends PositionComponent {
  PopupText({required Vector2 initialPosition})
      : _startY = initialPosition.y,
        super(
          position: initialPosition,
          priority: 20,
        );

  final double _startY;
  double _elapsed = 0.0;
  static const double duration = 0.6;
  static const double riseDistance = 24.0;

  static final TextPainter _cachedPainter = TextPainter(
    text: const TextSpan(
      text: 'CLOSE! +5',
      style: TextStyle(
        color: Palette.yellow,
        fontSize: 16,
        fontWeight: FontWeight.w900,
        shadows: [
          Shadow(
            color: Colors.black,
            blurRadius: 4,
          ),
        ],
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= duration) {
      removeFromParent();
      return;
    }

    final progress = (_elapsed / duration).clamp(0.0, 1.0);
    y = _startY - riseDistance * progress;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final progress = (_elapsed / duration).clamp(0.0, 1.0);
    // Scale pop: 1.0 -> 1.3 -> 1.0
    final scale = 1.0 + 0.3 * math.sin(math.pi * progress);
    // Fade out: 1.0 -> 0.0
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    canvas.save();
    // Center alignment for scaling
    final textW = _cachedPainter.width;
    final textH = _cachedPainter.height;

    canvas.translate(-textW * scale / 2, -textH * scale / 2);
    canvas.scale(scale, scale);

    if (opacity < 1.0) {
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, textW, textH),
        Paint()..color = Color.fromRGBO(255, 255, 255, opacity),
      );
      _cachedPainter.paint(canvas, Offset.zero);
      canvas.restore();
    } else {
      _cachedPainter.paint(canvas, Offset.zero);
    }

    canvas.restore();
  }
}
