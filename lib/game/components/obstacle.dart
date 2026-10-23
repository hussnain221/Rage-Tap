import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../painting/hazard_painters.dart';
import '../rage_tap_game.dart';
import '../systems/hazard_geometry.dart';

export '../systems/hazard_geometry.dart' show HazardType;
typedef ObstacleType = HazardType;

class Obstacle extends PositionComponent with HasGameReference<RageTapGame> {
  Obstacle({
    required this.type,
    required double initialX,
    this.count = 1,
    this.pitWidth = 0,
  })  : geometry = geometryFor(type, count: count, pitWidth: pitWidth),
        super(
          position: Vector2(
            initialX,
            _computeY(geometryFor(type, count: count, pitWidth: pitWidth)),
          ),
          size: geometryFor(type, count: count, pitWidth: pitWidth).visualSize,
          priority: 2,
        );

  static double _computeY(HazardGeometry geo) {
    switch (geo.anchor) {
      case HazardAnchor.ground:
        return C.groundTopY - geo.visualSize.y;
      case HazardAnchor.top:
        return C.beamDroneTopY;
      case HazardAnchor.hole:
        return C.groundTopY;
    }
  }

  factory Obstacle.spike({required double x, int count = 1}) {
    return Obstacle(
      type: HazardType.spike,
      initialX: x,
      count: count,
    );
  }

  factory Obstacle.barrier({required double x}) {
    return Obstacle(
      type: HazardType.barrier,
      initialX: x,
      count: 1,
    );
  }

  factory Obstacle.charging({required double x}) {
    return Obstacle(
      type: HazardType.charging,
      initialX: x,
      count: 1,
    );
  }

  factory Obstacle.tallWall({required double x}) {
    return Obstacle(
      type: HazardType.tallWall,
      initialX: x,
      count: 1,
    );
  }

  factory Obstacle.beam({required double x}) {
    return Obstacle(
      type: HazardType.beam,
      initialX: x,
      count: 1,
    );
  }

  factory Obstacle.pit({required double x, required double width}) {
    return Obstacle(
      type: HazardType.pit,
      initialX: x,
      pitWidth: width,
    );
  }

  final HazardType type;
  final int count;
  final double pitWidth;
  final HazardGeometry geometry;

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

  Rect get relativeHitbox => geometry.relativeHitbox;

  Rect get hitbox => Rect.fromLTWH(
        x + relativeHitbox.left,
        y + relativeHitbox.top,
        relativeHitbox.width,
        relativeHitbox.height,
      );

  void move(double scrollSpeed, double dt) {
    final speed = scrollSpeed + geometry.extraSpeed;
    x -= speed * dt;
  }

  final Paint _debugHitboxPaint = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    switch (type) {
      case HazardType.spike:
        HazardPainters.paintSpikes(canvas, count: count);
        break;
      case HazardType.barrier:
        HazardPainters.paintBarrier(canvas);
        break;
      case HazardType.charging:
        HazardPainters.paintChargingBlock(canvas);
        break;
      case HazardType.tallWall:
        HazardPainters.paintTallWall(canvas, t: isMounted ? game.runTime : 0.0);
        break;
      case HazardType.beam:
        HazardPainters.paintOverheadBeam(canvas, t: isMounted ? game.runTime : 0.0);
        break;
      case HazardType.pit:
        HazardPainters.paintPit(canvas, width: pitWidth > 0 ? pitWidth : size.x);
        break;
    }

    // Hitbox outline in debug mode when toggled on
    if (kDebugMode && (isMounted && game.showHitboxes.value)) {
      if (type == HazardType.pit) {
        // Draw the danger hole interval (inset by pitCenterInset)
        canvas.drawRect(
          Rect.fromLTWH(
            C.pitCenterInset,
            0,
            width - (C.pitCenterInset * 2),
            size.y,
          ),
          _debugHitboxPaint,
        );
      } else {
        canvas.drawRect(relativeHitbox, _debugHitboxPaint);
      }
    }
  }
}
