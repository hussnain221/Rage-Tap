import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../model/zap_skin.dart';

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

  // Rage Mode paints (§20.1)
  static final Paint _rageGlowPaint = Paint()
    ..color = const Color(0xFFFF2E4C).withValues(alpha: 0.7)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

  static final Paint _rageFlameOutlinePaint = Paint()
    ..color = Palette.orange
    ..strokeWidth = 2.5
    ..style = PaintingStyle.stroke;

  static final Paint _rageBrowPaint = Paint()
    ..color = const Color(0xFFFF2E4C)
    ..strokeWidth = 3.5
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  // Special skin paints (§20.3)
  static final Paint _lightningPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  static final Paint _crownPaint = Paint()
    ..color = Palette.yellow
    ..style = PaintingStyle.fill;

  static final Paint _crownOutlinePaint = Paint()
    ..color = Palette.bgDeep
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  /// Pure painting function that renders Zap per spec §7.1, §20.1, and §20.3
  static void paintZap(
    Canvas canvas, {
    Offset origin = Offset.zero,
    double size = 40.0,
    ZapExpression expression = ZapExpression.run,
    double t = 0.0,
    double scaleX = 1.0,
    double scaleY = 1.0,
    bool isRage = false,
    ZapSkin skin = ZapSkin.zap,
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
      _footPaint.color = skin.darkColor;
      canvas.drawRRect(leftFootRect, _footPaint);
      canvas.drawRRect(rightFootRect, _footPaint);
    }

    // 2. Glow (skin glow @ alpha, blur 8, or red/flame in Rage Mode) - omitted for dead expression
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, 40.0 * s, 40.0 * s),
      Radius.circular(10.0 * s),
    );
    if (expression != ZapExpression.dead) {
      _glowPaint.color = skin.glowColor.withValues(alpha: skin.isTranslucent ? 0.35 : 0.5);
      canvas.drawRRect(bodyRRect, isRage ? _rageGlowPaint : _glowPaint);
    }

    // 3. Body: rounded rect 40x40, corner radius 10
    _bodyPaint.color = expression == ZapExpression.dead
        ? skin.darkColor
        : (skin.isTranslucent
            ? skin.primaryColor.withValues(alpha: 0.65)
            : skin.primaryColor);
    canvas.drawRRect(bodyRRect, _bodyPaint);

    if (isRage && expression != ZapExpression.dead) {
      canvas.drawRRect(bodyRRect.inflate(1.5 * s), _rageFlameOutlinePaint);
    }

    // 4. Darker bottom edge strip (4 units)
    _darkBottomPaint.color = skin.darkColor.withValues(alpha: skin.isTranslucent ? 0.65 : 1.0);
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

    // Cosmetic: Lightning mark for Bolt (§20.3)
    if (skin.hasLightningMark && expression != ZapExpression.dead) {
      final lightningPath = Path()
        ..moveTo(21.0 * s, 5.0 * s)
        ..lineTo(17.0 * s, 11.0 * s)
        ..lineTo(19.5 * s, 11.0 * s)
        ..lineTo(18.0 * s, 16.0 * s)
        ..lineTo(23.0 * s, 9.5 * s)
        ..lineTo(20.5 * s, 9.5 * s)
        ..close();
      canvas.drawPath(lightningPath, _lightningPaint);
    }

    // Cosmetic: Crown for Royal (§20.3)
    if (skin.hasCrown && expression != ZapExpression.dead) {
      final crownPath = Path()
        ..moveTo(12.0 * s, 2.0 * s)
        ..lineTo(11.0 * s, -4.0 * s)
        ..lineTo(16.0 * s, -1.0 * s)
        ..lineTo(20.0 * s, -7.0 * s)
        ..lineTo(24.0 * s, -1.0 * s)
        ..lineTo(29.0 * s, -4.0 * s)
        ..lineTo(28.0 * s, 2.0 * s)
        ..close();
      canvas.drawPath(crownPath, _crownPaint);
      canvas.drawPath(crownPath, _crownOutlinePaint);
    }

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
        final leftPupilRect = Rect.fromCenter(
          center: Offset((13.5 * s) + pupilShiftX, 18.5 * s),
          width: pupilW,
          height: pupilH,
        );

        // Right eye & pupil
        final rightEyeRect = Rect.fromCenter(
          center: Offset(26.5 * s, 18.5 * s),
          width: eyeW,
          height: eyeH,
        );
        final rightPupilRect = Rect.fromCenter(
          center: Offset((26.5 * s) + pupilShiftX, 18.5 * s),
          width: pupilW,
          height: pupilH,
        );

        if (skin.hasPixelEyes) {
          // Pixel skin square eyes (§20.3)
          canvas.drawRect(leftEyeRect, _eyeWhitePaint);
          canvas.drawRect(leftPupilRect, _pupilPaint);
          canvas.drawRect(rightEyeRect, _eyeWhitePaint);
          canvas.drawRect(rightPupilRect, _pupilPaint);
        } else {
          canvas.drawOval(leftEyeRect, _eyeWhitePaint);
          canvas.drawOval(leftPupilRect, _pupilPaint);
          canvas.drawOval(rightEyeRect, _eyeWhitePaint);
          canvas.drawOval(rightPupilRect, _pupilPaint);
        }
      }
    }

    // 7. Brows: 3-unit thick round-cap lines angled inward (determined/angry), glowing red in Rage
    if (expression != ZapExpression.dead) {
      final browPaint = isRage ? _rageBrowPaint : _browPaint;
      canvas.drawLine(
        Offset(7.0 * s, 11.0 * s),
        Offset(17.0 * s, 14.0 * s),
        browPaint,
      );
      canvas.drawLine(
        Offset(33.0 * s, 11.0 * s),
        Offset(23.0 * s, 14.0 * s),
        browPaint,
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
