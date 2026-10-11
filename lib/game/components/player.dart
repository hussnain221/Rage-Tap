import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';

class Player extends PositionComponent {
  Player()
      : super(
          position: Vector2(C.playerLeft, C.groundTopY - C.playerSize),
          size: Vector2(C.playerSize, C.playerSize),
        );

  double vy = 0.0;
  bool grounded = true;
  double jumpBufferTimer = 0.0;

  final Paint _grayPaint = Paint()..color = const Color(0xFF888888);
  final Paint _debugHitboxPaint = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  static const double groundY = C.groundTopY - C.playerSize;

  Rect get hitbox => Rect.fromLTWH(
        x + C.playerHitX,
        y + C.playerHitY,
        C.playerHitW,
        C.playerHitH,
      );

  void jump() {
    if (grounded) {
      vy = -C.jumpVelocity;
      grounded = false;
      jumpBufferTimer = 0.0;
    } else {
      jumpBufferTimer = C.jumpBufferSec;
    }
  }

  void step(double dt) {
    if (jumpBufferTimer > 0) {
      jumpBufferTimer -= dt;
      if (jumpBufferTimer < 0) {
        jumpBufferTimer = 0;
      }
    }

    if (!grounded) {
      vy += C.gravity * dt;
      y += vy * dt;

      if (y >= groundY) {
        y = groundY;
        vy = 0.0;
        grounded = true;

        if (jumpBufferTimer > 0) {
          jump();
        }
      }
    }
  }



  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Placeholder gray 40x40 rounded rect
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(10),
      ),
      _grayPaint,
    );

    // Hitbox outline in debug mode
    if (kDebugMode) {
      canvas.drawRect(
        const Rect.fromLTWH(
          C.playerHitX,
          C.playerHitY,
          C.playerHitW,
          C.playerHitH,
        ),
        _debugHitboxPaint,
      );
    }
  }
}
