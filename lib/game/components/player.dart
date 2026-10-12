import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../game_state.dart';
import '../painting/zap_painter.dart';
import '../rage_tap_game.dart';

class Player extends PositionComponent with HasGameReference<RageTapGame> {
  Player()
      : super(
          position: Vector2(C.playerLeft, C.groundTopY - C.playerSize),
          size: Vector2(C.playerSize, C.playerSize),
        );

  double vy = 0.0;
  bool grounded = true;
  double jumpBufferTimer = 0.0;

  static const double squashDuration = 0.08;
  double _squashTimer = 0.0;
  bool _isTakeoff = false;
  double _scaredTimer = 0.0;
  double animTime = 0.0;
  ZapExpression? overrideExpression;

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

  ZapExpression get currentExpression {
    if (overrideExpression != null) return overrideExpression!;
    if (isMounted) {
      final state = game.state.value;
      if (state == GameState.dying || state == GameState.results) {
        return ZapExpression.dead;
      }
      if (state == GameState.ready) {
        return ZapExpression.idle;
      }
    }
    if (_scaredTimer > 0) {
      return ZapExpression.scared;
    }
    if (!grounded) {
      return ZapExpression.air;
    }
    return ZapExpression.run;
  }

  double get scaleX {
    if (_squashTimer <= 0) return 1.0;
    final progress = _squashTimer / squashDuration;
    return _isTakeoff
        ? 1.0 + (0.85 - 1.0) * progress
        : 1.0 + (1.20 - 1.0) * progress;
  }

  double get scaleY {
    if (_squashTimer <= 0) return 1.0;
    final progress = _squashTimer / squashDuration;
    return _isTakeoff
        ? 1.0 + (1.20 - 1.0) * progress
        : 1.0 + (0.80 - 1.0) * progress;
  }

  void triggerTakeoff() {
    _squashTimer = squashDuration;
    _isTakeoff = true;
  }

  void triggerLanding() {
    _squashTimer = squashDuration;
    _isTakeoff = false;
  }

  void triggerScared() {
    _scaredTimer = 0.4;
  }

  void resetAnimation() {
    _squashTimer = 0.0;
    _scaredTimer = 0.0;
    animTime = 0.0;
  }

  void jump() {
    if (grounded) {
      vy = -C.jumpVelocity;
      grounded = false;
      jumpBufferTimer = 0.0;
      triggerTakeoff();
    } else {
      jumpBufferTimer = C.jumpBufferSec;
    }
  }

  void step(double dt) {
    animTime += dt;
    if (_squashTimer > 0) {
      _squashTimer = math.max(0.0, _squashTimer - dt);
    }
    if (_scaredTimer > 0) {
      _scaredTimer = math.max(0.0, _scaredTimer - dt);
    }

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
        triggerLanding();

        if (jumpBufferTimer > 0) {
          jump();
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    ZapPainter.paintZap(
      canvas,
      origin: Offset.zero,
      size: size.x,
      expression: currentExpression,
      t: animTime,
      scaleX: scaleX,
      scaleY: scaleY,
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
