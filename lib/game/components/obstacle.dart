import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/palette.dart';

enum ObstacleType {
  spike,
  barrier,
  charging,
}

class Obstacle extends PositionComponent {
  Obstacle({
    required this.type,
    required double initialX,
    this.count = 1,
  }) : super(
          position: Vector2(
            initialX,
            C.groundTopY - _computeHeight(type),
          ),
          size: Vector2(
            _computeWidth(type, count),
            _computeHeight(type),
          ),
        );

  factory Obstacle.spike({required double x, int count = 1}) {
    return Obstacle(
      type: ObstacleType.spike,
      initialX: x,
      count: count,
    );
  }

  factory Obstacle.barrier({required double x}) {
    return Obstacle(
      type: ObstacleType.barrier,
      initialX: x,
      count: 1,
    );
  }

  factory Obstacle.charging({required double x}) {
    return Obstacle(
      type: ObstacleType.charging,
      initialX: x,
      count: 1,
    );
  }

  final ObstacleType type;
  final int count;

  bool passed = false;
  double minClearance = double.infinity;

  void updateClearance(Rect playerHitbox) {
    final obsHitbox = hitbox;
    final horizontalOverlap =
        playerHitbox.left < obsHitbox.right && playerHitbox.right > obsHitbox.left;
    if (horizontalOverlap) {
      final clearance = obsHitbox.top - playerHitbox.bottom;
      if (clearance >= 0.0 && clearance < minClearance) {
        minClearance = clearance;
      }
    }
  }

  static double _computeWidth(ObstacleType type, int count) {
    switch (type) {
      case ObstacleType.spike:
        return C.spikeW * count;
      case ObstacleType.barrier:
        return C.barrierW;
      case ObstacleType.charging:
        return C.chargeW;
    }
  }

  static double _computeHeight(ObstacleType type) {
    switch (type) {
      case ObstacleType.spike:
        return C.spikeH;
      case ObstacleType.barrier:
        return C.barrierH;
      case ObstacleType.charging:
        return C.chargeH;
    }
  }

  Rect get relativeHitbox {
    switch (type) {
      case ObstacleType.spike:
        return Rect.fromLTWH(
          C.spikeHitX,
          C.spikeHitY,
          size.x - (C.spikeHitX * 2),
          C.spikeHitH,
        );
      case ObstacleType.barrier:
        return const Rect.fromLTWH(
          C.barrierHitX,
          C.barrierHitY,
          C.barrierHitW,
          C.barrierHitH,
        );
      case ObstacleType.charging:
        return const Rect.fromLTWH(
          C.chargeHitX,
          C.chargeHitY,
          C.chargeHitW,
          C.chargeHitH,
        );
    }
  }

  Rect get hitbox => Rect.fromLTWH(
        x + relativeHitbox.left,
        y + relativeHitbox.top,
        relativeHitbox.width,
        relativeHitbox.height,
      );

  void move(double scrollSpeed, double dt) {
    final speed = type == ObstacleType.charging
        ? scrollSpeed + C.chargingExtraSpeed
        : scrollSpeed;
    x -= speed * dt;
  }

  final Paint _paint = Paint();
  final Paint _debugHitboxPaint = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    switch (type) {
      case ObstacleType.spike:
        _paint.color = Palette.orange;
        break;
      case ObstacleType.barrier:
        _paint.color = Palette.magenta;
        break;
      case ObstacleType.charging:
        _paint.color = Palette.orange;
        break;
    }

    // Placeholder colored rectangle
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      _paint,
    );

    // Hitbox outline in debug mode
    if (kDebugMode) {
      canvas.drawRect(relativeHitbox, _debugHitboxPaint);
    }
  }
}
