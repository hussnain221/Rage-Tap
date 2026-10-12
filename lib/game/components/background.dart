import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/palette.dart';
import '../game_state.dart';
import '../rage_tap_game.dart';

class _Gear {
  final double x;
  final double y;
  final double radius;
  final double direction;
  final Path path;

  const _Gear({
    required this.x,
    required this.y,
    required this.radius,
    required this.direction,
    required this.path,
  });
}

class _Pipe {
  final double x;
  final List<double> jointYs;
  final double? lampY;

  const _Pipe({
    required this.x,
    required this.jointYs,
    this.lampY,
  });
}

/// Neon Workshop background per spec §11.
/// Implements static sky gradient, far gear parallax layer (0.10x),
/// and mid pipe parallax layer (0.30x) over a 720-unit seamless tile.
class Background extends PositionComponent with HasGameReference<RageTapGame> {
  Background()
      : super(
          position: Vector2.zero(),
          size: Vector2(C.worldW, C.worldH),
          priority: -10,
        );

  static const double tileWidth = 720.0;
  static const double rotationSpeedRad = 6.0 * (math.pi / 180.0); // 6 deg/s

  double _gearScrollX = 0.0;
  double _pipeScrollX = 0.0;
  double _gearRotationAngle = 0.0;

  // Cached Paints and Shaders
  static final Paint _gradientPaint = Paint()
    ..shader = ui.Gradient.linear(
      Offset.zero,
      const Offset(0, C.groundTopY),
      [Palette.bgDeep, Palette.bgPurple],
    );

  static final Paint _gearPaint = Paint()
    ..color = Palette.gearFill
    ..style = PaintingStyle.fill;

  static final Paint _pipePaint = Paint()
    ..color = Palette.pipeFill
    ..style = PaintingStyle.fill;

  static final Paint _jointPaint = Paint()
    ..color = Palette.cyanDark
    ..style = PaintingStyle.fill;

  static final Paint _lampGlowPaint = Paint()
    ..color = Palette.cyan.withValues(alpha: 0.20)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

  static final Paint _lampCorePaint = Paint()
    ..color = Palette.cyan
    ..style = PaintingStyle.fill;

  final List<_Gear> _gears = _createSeededGears();

  static const List<_Pipe> _pipes = [
    _Pipe(x: 75, jointYs: [120, 260, 400], lampY: null),
    _Pipe(x: 210, jointYs: [90, 230, 370], lampY: 230),
    _Pipe(x: 355, jointYs: [140, 280, 420], lampY: null),
    _Pipe(x: 500, jointYs: [100, 240, 380], lampY: 240),
    _Pipe(x: 640, jointYs: [130, 270, 410], lampY: null),
  ];

  static List<_Gear> _createSeededGears() {
    // 8 gears with alternating direction and varying radii (40-90)
    final configs = [
      (x: 80.0, y: 110.0, r: 65.0, teeth: 10, dir: 1.0),
      (x: 170.0, y: 190.0, r: 45.0, teeth: 8, dir: -1.0),
      (x: 275.0, y: 120.0, r: 85.0, teeth: 12, dir: 1.0),
      (x: 370.0, y: 220.0, r: 50.0, teeth: 8, dir: -1.0),
      (x: 450.0, y: 130.0, r: 75.0, teeth: 11, dir: 1.0),
      (x: 540.0, y: 240.0, r: 55.0, teeth: 9, dir: -1.0),
      (x: 625.0, y: 140.0, r: 90.0, teeth: 12, dir: 1.0),
      (x: 705.0, y: 230.0, r: 42.0, teeth: 8, dir: -1.0),
    ];

    return configs.map((c) {
      return _Gear(
        x: c.x,
        y: c.y,
        radius: c.r,
        direction: c.dir,
        path: _generateGearPath(c.r, c.teeth),
      );
    }).toList();
  }

  static Path _generateGearPath(double outerRadius, int teeth) {
    final path = Path();
    final rootRadius = outerRadius * 0.78;
    final holeRadius = outerRadius * 0.28;
    final totalSteps = teeth * 2;
    final stepAngle = (2 * math.pi) / totalSteps;

    // Outer gear profile with teeth
    for (int i = 0; i < totalSteps; i++) {
      final angle = i * stepAngle;
      final isTip = i.isEven;
      final r = isTip ? outerRadius : rootRadius;
      final px = r * math.cos(angle);
      final py = r * math.sin(angle);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();

    // Center hub cutout
    path.addOval(Rect.fromCircle(center: Offset.zero, radius: holeRadius));
    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  void update(double dt) {
    super.update(dt);

    final state = game.state.value;
    double scrollSpeed = 0.0;
    double rotSpeed = 0.0;

    if (state == GameState.playing) {
      scrollSpeed = game.currentSpeed;
      rotSpeed = rotationSpeedRad;
    } else if (state == GameState.ready) {
      // Gentle drift in ready state (20 units/s)
      scrollSpeed = 20.0;
      rotSpeed = rotationSpeedRad;
    }

    if (scrollSpeed > 0) {
      _gearScrollX = (_gearScrollX + (scrollSpeed * 0.10 * dt)) % tileWidth;
      _pipeScrollX = (_pipeScrollX + (scrollSpeed * 0.30 * dt)) % tileWidth;
    }
    if (rotSpeed > 0) {
      _gearRotationAngle = (_gearRotationAngle + (rotSpeed * dt)) % (2 * math.pi);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. Static vertical sky gradient
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _gradientPaint);

    // 2. Far gear layer (0.10x parallax, 720-unit tile)
    final gearOffset1 = -_gearScrollX;
    _renderGears(canvas, gearOffset1);
    _renderGears(canvas, gearOffset1 + tileWidth);

    // 3. Mid pipe layer (0.30x parallax, 720-unit tile)
    final pipeOffset1 = -_pipeScrollX;
    _renderPipes(canvas, pipeOffset1);
    _renderPipes(canvas, pipeOffset1 + tileWidth);
  }

  void _renderGears(Canvas canvas, double offsetX) {
    for (final gear in _gears) {
      final gx = gear.x + offsetX;
      // Skip gears well off-screen
      if (gx + gear.radius < 0 || gx - gear.radius > size.x) continue;

      canvas.save();
      canvas.translate(gx, gear.y);
      canvas.rotate(_gearRotationAngle * gear.direction);
      canvas.drawPath(gear.path, _gearPaint);
      canvas.restore();
    }
  }

  void _renderPipes(Canvas canvas, double offsetX) {
    for (final pipe in _pipes) {
      final px = pipe.x + offsetX;
      if (px + 14 < 0 || px - 14 > size.x) continue;

      // Vertical pipe (width 14 from y=0 to groundTopY)
      canvas.drawRect(
        Rect.fromLTWH(px - 7, 0, 14, C.groundTopY),
        _pipePaint,
      );

      // Cyan joint rings
      for (final jy in pipe.jointYs) {
        final ringRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(px - 9, jy, 18, 6),
          const Radius.circular(2),
        );
        canvas.drawRRect(ringRect, _jointPaint);
      }

      // Lamp glow if present
      if (pipe.lampY != null) {
        final ly = pipe.lampY!;
        canvas.drawCircle(Offset(px, ly), 18, _lampGlowPaint);
        canvas.drawCircle(Offset(px, ly), 4, _lampCorePaint);
      }
    }
  }
}
