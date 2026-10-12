import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/palette.dart';

enum ZapExpression {
  run,
  air,
  scared,
  dead,
  idle,
}

class ZapPainter {
  const ZapPainter._();

  // Cached Paint objects (no per-frame allocation)
  static final Paint _glowPaint = Paint()
    ..color = Palette.cyan.withValues(alpha: 0.5)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

  static final Paint _bodyPaint = Paint()..color = Palette.cyan;
  static final Paint _deadBodyPaint = Paint()..color = Palette.cyanDark;
  static final Paint _darkBottomPaint = Paint()..color = Palette.cyanDark;
  static final Paint _highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.25);

  static final Paint _eyeWhitePaint = Paint()..color = Colors.white;
  static final Paint _pupilPaint = Paint()..color = Palette.bgDeep;

  static final Paint _browPaint = Paint()
    ..color = Palette.bgDeep
    ..strokeWidth = 3.0
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  static final Paint _mouthLinePaint = Paint()
    ..color = Palette.bgDeep
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  static final Paint _mouthFillPaint = Paint()
    ..color = Palette.bgDeep
    ..style = PaintingStyle.fill;

  static final Paint _footPaint = Paint()..color = Palette.cyanDark;

  static final Paint _sweatPaint = Paint()..color = Palette.cyan;

  static final Paint _xEyePaint = Paint()
    ..color = Palette.bgDeep
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  /// Pure painting function that renders Zap per spec §7.1
  static void paintZap(
    Canvas canvas, {
    Offset origin = Offset.zero,
    double size = 40.0,
    ZapExpression expression = ZapExpression.run,
    double t = 0.0,
    double scaleX = 1.0,
    double scaleY = 1.0,
  }) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);

    final s = size / 40.0;

    // Body bob calculation
    double bobY = 0.0;
    if (expression == ZapExpression.run) {
      bobY = math.sin(t * 18.0) * 1.5;
    } else if (expression == ZapExpression.idle) {
      bobY = math.sin(t * 3.0) * 1.0;
    }

    // Squash / stretch anchored at bottom center: (20 * s, 40 * s)
    final anchorX = 20.0 * s;
    final anchorY = 40.0 * s;
    canvas.translate(anchorX, anchorY);

    double effectiveScaleY = scaleY;
    if (expression == ZapExpression.dead) {
      effectiveScaleY *= 0.6; // squash scaleY 0.6 anchored at ground
    }
    canvas.scale(scaleX, effectiveScaleY);
    canvas.translate(-anchorX, -anchorY + (bobY * s));

    // 1. Running feet (rendered behind/below body, only in run expression)
    if (expression == ZapExpression.run) {
      final stepAlt = ((t / 0.08).floor() % 2 == 0);
      final offset = stepAlt ? 3.0 : -3.0;

      final leftFootRect = RRect.fromRectAndRadius(
        Rect.fromLTWH((8.0 + offset) * s, 36.0 * s, 10.0 * s, 5.0 * s),
        Radius.circular(2.5 * s),
      );
      final rightFootRect = RRect.fromRectAndRadius(
        Rect.fromLTWH((22.0 - offset) * s, 36.0 * s, 10.0 * s, 5.0 * s),
        Radius.circular(2.5 * s),
      );
      canvas.drawRRect(leftFootRect, _footPaint);
      canvas.drawRRect(rightFootRect, _footPaint);
    }

    // 2. Glow (cyan @ 50% alpha, blur 8) - omitted for dead expression
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, 40.0 * s, 40.0 * s),
      Radius.circular(10.0 * s),
    );
    if (expression != ZapExpression.dead) {
      canvas.drawRRect(bodyRRect, _glowPaint);
    }

    // 3. Body: rounded rect 40x40, corner radius 10
    final bodyPaint = expression == ZapExpression.dead ? _deadBodyPaint : _bodyPaint;
    canvas.drawRRect(bodyRRect, bodyPaint);

    // 4. Darker bottom edge strip (4 units) in cyanDark
    canvas.save();
    canvas.clipRRect(bodyRRect);
    canvas.drawRect(
      Rect.fromLTWH(0, 36.0 * s, 40.0 * s, 4.0 * s),
      _darkBottomPaint,
    );
    canvas.restore();

    // 5. Highlight rect (10x4 at (6, 5)) white @ 25%
    canvas.drawRect(
      Rect.fromLTWH(6.0 * s, 5.0 * s, 10.0 * s, 4.0 * s),
      _highlightPaint,
    );

    // 6. Eyes and Pupils
    if (expression == ZapExpression.dead) {
      // Eyes replaced by "X" strokes
      // Left eye X at center (13.5, 18.5)
      canvas.drawLine(
        Offset(9.0 * s, 14.0 * s),
        Offset(18.0 * s, 23.0 * s),
        _xEyePaint,
      );
      canvas.drawLine(
        Offset(18.0 * s, 14.0 * s),
        Offset(9.0 * s, 23.0 * s),
        _xEyePaint,
      );
      // Right eye X at center (26.5, 18.5)
      canvas.drawLine(
        Offset(22.0 * s, 14.0 * s),
        Offset(31.0 * s, 23.0 * s),
        _xEyePaint,
      );
      canvas.drawLine(
        Offset(31.0 * s, 14.0 * s),
        Offset(22.0 * s, 23.0 * s),
        _xEyePaint,
      );
    } else {
      // Idle slow blink every ~3 s (blink duration ~0.15s)
      final isBlinking = expression == ZapExpression.idle && (t % 3.0) < 0.15;

      if (isBlinking) {
        // Closed eye lines
        canvas.drawLine(
          Offset(9.0 * s, 18.5 * s),
          Offset(18.0 * s, 18.5 * s),
          _browPaint,
        );
        canvas.drawLine(
          Offset(22.0 * s, 18.5 * s),
          Offset(31.0 * s, 18.5 * s),
          _browPaint,
        );
      } else {
        double eyeW = 9.0 * s;
        double eyeH = 11.0 * s;
        double pupilW = 4.0 * s;
        double pupilH = 6.0 * s;
        double pupilShiftX = 3.0 * s;

        if (expression == ZapExpression.air) {
          // Eyes wider in air (10x12)
          eyeW = 10.0 * s;
          eyeH = 12.0 * s;
          pupilW = 4.5 * s;
          pupilH = 6.5 * s;
        } else if (expression == ZapExpression.scared) {
          // Eyes wide with tiny pupils
          eyeW = 11.0 * s;
          eyeH = 13.0 * s;
          pupilW = 2.5 * s;
          pupilH = 3.5 * s;
          pupilShiftX = 2.0 * s;
        }

        // Left eye & pupil
        final leftEyeRect = Rect.fromCenter(
          center: Offset(13.5 * s, 18.5 * s),
          width: eyeW,
          height: eyeH,
        );
        canvas.drawOval(leftEyeRect, _eyeWhitePaint);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset((13.5 * s) + pupilShiftX, 18.5 * s),
            width: pupilW,
            height: pupilH,
          ),
          _pupilPaint,
        );

        // Right eye & pupil
        final rightEyeRect = Rect.fromCenter(
          center: Offset(26.5 * s, 18.5 * s),
          width: eyeW,
          height: eyeH,
        );
        canvas.drawOval(rightEyeRect, _eyeWhitePaint);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset((26.5 * s) + pupilShiftX, 18.5 * s),
            width: pupilW,
            height: pupilH,
          ),
          _pupilPaint,
        );
      }
    }

    // 7. Brows: 3-unit thick round-cap lines angled inward (determined/angry)
    if (expression != ZapExpression.dead) {
      canvas.drawLine(
        Offset(7.0 * s, 11.0 * s),
        Offset(17.0 * s, 14.0 * s),
        _browPaint,
      );
      canvas.drawLine(
        Offset(33.0 * s, 11.0 * s),
        Offset(23.0 * s, 14.0 * s),
        _browPaint,
      );
    }

    // 8. Mouth
    if (expression == ZapExpression.air) {
      // Small open oval 8x6
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(20.0 * s, 31.0 * s),
          width: 8.0 * s,
          height: 6.0 * s,
        ),
        _mouthFillPaint,
      );
    } else if (expression == ZapExpression.scared) {
      // Small open mouth oval 6x6
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(20.0 * s, 31.0 * s),
          width: 6.0 * s,
          height: 6.0 * s,
        ),
        _mouthFillPaint,
      );
    } else {
      // Flat line (14, 31) -> (26, 31), 2 units thick
      canvas.drawLine(
        Offset(14.0 * s, 31.0 * s),
        Offset(26.0 * s, 31.0 * s),
        _mouthLinePaint,
      );
    }

    // 9. Scared sweat drop: cyan 4x6 at upper-right (32, 6)
    if (expression == ZapExpression.scared) {
      canvas.drawOval(
        Rect.fromLTWH(32.0 * s, 6.0 * s, 4.0 * s, 6.0 * s),
        _sweatPaint,
      );
    }

    canvas.restore();
  }
}
