import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../audio/audio_service.dart';
import '../../core/constants.dart';
import '../game_state.dart';
import '../model/zap_skin.dart';
import '../painting/zap_painter.dart';
import '../rage_tap_game.dart';

class Player extends PositionComponent with HasGameReference<RageTapGame> {
  Player()
      : super(
          position: Vector2(C.playerLeft, C.groundTopY - C.playerSize),
          size: Vector2(C.playerSize, C.playerSize),
          priority: 5,
        );

  double vy = 0.0;
  bool grounded = true;
  double jumpBufferTimer = 0.0;
  bool isFalling = false;

  static const double squashDuration = 0.08;
  double _squashTimer = 0.0;
  bool _isTakeoff = false;
  double _scaredTimer = 0.0;
  double animTime = 0.0;
  bool isDead = false;
  bool isRageMode = false;
  ZapExpression? overrideExpression;

  final Paint _debugHitboxPaint = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  final Paint _debugCenterLinePaint = Paint()
    ..color = Colors.yellow
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
    if (isDead) return ZapExpression.dead;
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
    isDead = false;
    isFalling = false;
    isRageMode = false;
  }

  void jump() {
    if (grounded) {
      vy = -C.jumpVelocity;
      grounded = false;
      jumpBufferTimer = 0.0;
      triggerTakeoff();
      AudioService.instance.playJump();
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

    if (isFalling) {
      grounded = false;
      vy += C.gravity * dt;
      y += vy * dt;
      return;
    }

    if (!grounded) {
      vy += C.gravity * dt;
      y += vy * dt;

      if (y >= groundY) {
        y = groundY;
        vy = 0.0;
        grounded = true;
        triggerLanding();
        AudioService.instance.playLand();
        if (isMounted) {
          game.spawnLandingDust(Vector2(x + C.playerSize / 2, C.groundTopY));
        }

        if (jumpBufferTimer > 0) {
          jump();
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final skin = isMounted
        ? ZapSkin.fromId(game.saveService.equippedSkin)
        : ZapSkin.zap;

    ZapPainter.paintZap(
      canvas,
      origin: Offset.zero,
      size: size.x,
      expression: currentExpression,
      t: animTime,
      scaleX: scaleX,
      scaleY: scaleY,
      isRage: isRageMode,
      skin: skin,
    );

    // Hitbox outline in debug mode when toggled on
    if (kDebugMode && (isMounted && game.showHitboxes.value)) {
      canvas.drawRect(
        const Rect.fromLTWH(
          C.playerHitX,
          C.playerHitY,
          C.playerHitW,
          C.playerHitH,
        ),
        _debugHitboxPaint,
      );
      // Player center line
      final centerX = C.playerHitX + (C.playerHitW / 2);
      canvas.drawLine(
        Offset(centerX, C.playerHitY),
        Offset(centerX, C.playerHitY + C.playerHitH),
        _debugCenterLinePaint,
      );
    }
  }
}
