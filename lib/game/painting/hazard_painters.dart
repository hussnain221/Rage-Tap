import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/palette.dart';

/// Pure painting functions for hazards per spec §7.2.
/// Cached Paint and Path objects to eliminate per-frame allocations.
class HazardPainters {
  const HazardPainters._();

  // --- Spikes cached assets ---
  static final Paint _spikeFillPaint = Paint()
    ..color = Palette.orange
    ..style = PaintingStyle.fill;

  static final Paint _spikeOutlinePaint = Paint()
    ..color = Palette.magenta
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  static final Paint _spikeGlowPaint = Paint()
    ..color = Palette.magenta.withValues(alpha: 0.6)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

  static final Paint _spikeBasePaint = Paint()
    ..color = Palette.bgDeep
    ..strokeWidth = 1.5;

  static final List<Path> _cachedSpikePaths = [
    _createSpikePath(1),
    _createSpikePath(2),
    _createSpikePath(3),
  ];

  static Path _createSpikePath(int count) {
    final path = Path();
    path.moveTo(0, C.spikeH);
    for (int i = 0; i < count; i++) {
      final leftX = i * C.spikeW;
      final tipX = leftX + (C.spikeW / 2);
      final rightX = (i + 1) * C.spikeW;
      path.lineTo(tipX, 0);
      path.lineTo(rightX, C.spikeH);
    }
    path.close();
    return path;
  }

  // --- Barrier cached assets ---
  static final RRect _barrierRRect = RRect.fromRectAndRadius(
    const Rect.fromLTWH(0, 0, C.barrierW, C.barrierH),
    const Radius.circular(6),
  );

  static final Paint _barrierGlowPaint = Paint()
    ..color = Palette.magenta.withValues(alpha: 0.45)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  static final Paint _barrierBodyPaint = Paint()
    ..color = Palette.magenta
    ..style = PaintingStyle.fill;

  static final Paint _barrierStripePaint = Paint()
    ..color = Palette.yellow.withValues(alpha: 0.35)
    ..strokeWidth = 8.0
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.square;

  static final Paint _barrierHighlightPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.25)
    ..style = PaintingStyle.fill;

  static final RRect _barrierHighlightRRect = RRect.fromRectAndRadius(
    const Rect.fromLTWH(4, 3, 22, 3),
    const Radius.circular(1.5),
  );

  // --- Charging block cached assets ---
  static final RRect _chargeRRect = RRect.fromRectAndRadius(
    const Rect.fromLTWH(0, 0, C.chargeW, C.chargeH),
    const Radius.circular(6),
  );

  static final Paint _chargeGlowPaint = Paint()
    ..color = Palette.orange.withValues(alpha: 0.45)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  static final Paint _chargeBodyPaint = Paint()
    ..color = Palette.orange
    ..style = PaintingStyle.fill;

  static final Paint _speedLinePaint = Paint()
    ..color = Palette.orange.withValues(alpha: 0.50)
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round;

  static final Paint _chevronPaint = Paint()
    ..color = Palette.bgDeep
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  static final Path _chevronsPath = Path()
    ..moveTo(14, 11)
    ..lineTo(9, 17)
    ..lineTo(14, 23)
    ..moveTo(21, 11)
    ..lineTo(16, 17)
    ..lineTo(21, 23)
    ..moveTo(28, 11)
    ..lineTo(23, 17)
    ..lineTo(28, 23);

  // --- Telegraph warning icon cached assets ---
  static final Path _telegraphPath = Path()
    ..moveTo(12, 2)
    ..lineTo(22, 22)
    ..lineTo(2, 22)
    ..close();

  static final Paint _telegraphGlowPaint = Paint()
    ..color = Palette.orange.withValues(alpha: 0.5)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  static final Paint _telegraphTrianglePaint = Paint()
    ..color = Palette.orange
    ..style = PaintingStyle.fill;

  static final Paint _telegraphStrokePaint = Paint()
    ..color = Palette.bgDeep
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  static final Paint _telegraphDotPaint = Paint()
    ..color = Palette.bgDeep
    ..style = PaintingStyle.fill;

  /// Paints spikes: unit 30x28, count 1..3, orange fill, 2-unit magenta outline,
  /// tip glows, dark base line.
  static void paintSpikes(
    Canvas canvas, {
    Offset origin = Offset.zero,
    int count = 1,
  }) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);

    final clampedCount = count.clamp(1, 3);
    final path = _cachedSpikePaths[clampedCount - 1];

    // 1. Soft magenta glow at spike tips
    for (int i = 0; i < clampedCount; i++) {
      final tipX = (i * C.spikeW) + (C.spikeW / 2);
      canvas.drawCircle(Offset(tipX, 2), 4.0, _spikeGlowPaint);
    }

    // 2. Orange body fill
    canvas.drawPath(path, _spikeFillPaint);

    // 3. 2-unit magenta outline
    canvas.drawPath(path, _spikeOutlinePaint);

    // 4. Dark base line along ground
    canvas.drawLine(
      const Offset(0, C.spikeH),
      Offset(clampedCount * C.spikeW, C.spikeH),
      _spikeBasePaint,
    );

    canvas.restore();
  }

  /// Paints barrier: 30x56 rounded rect (radius 6), magenta fill,
  /// yellow@35% diagonal stripes, light top highlight, soft magenta glow.
  static void paintBarrier(
    Canvas canvas, {
    Offset origin = Offset.zero,
  }) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);

    // 1. Soft magenta glow
    canvas.drawRRect(_barrierRRect, _barrierGlowPaint);

    // 2. Magenta body
    canvas.drawRRect(_barrierRRect, _barrierBodyPaint);

    // 3. Diagonal hazard stripes (clipped to body)
    canvas.save();
    canvas.clipRRect(_barrierRRect);
    // Draw 45-degree diagonal stripes spaced by 16 units
    for (double d = -20; d <= 76; d += 16) {
      canvas.drawLine(
        Offset(d, 0),
        Offset(d + 60, 60),
        _barrierStripePaint,
      );
    }
    canvas.restore();

    // 4. Light top highlight
    canvas.drawRRect(_barrierHighlightRRect, _barrierHighlightPaint);

    canvas.restore();
  }

  /// Paints charging block: 34x34 rounded rect (radius 6), orange fill,
  /// three dark chevrons, three trailing speed lines (30, 22, 14; alpha 50%), orange glow.
  static void paintChargingBlock(
    Canvas canvas, {
    Offset origin = Offset.zero,
  }) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);

    // 1. Trailing speed lines to the right (lengths 30, 22, 14 at 50% alpha)
    canvas.drawLine(
      const Offset(C.chargeW, 8),
      const Offset(C.chargeW + 30, 8),
      _speedLinePaint,
    );
    canvas.drawLine(
      const Offset(C.chargeW, 17),
      const Offset(C.chargeW + 22, 17),
      _speedLinePaint,
    );
    canvas.drawLine(
      const Offset(C.chargeW, 26),
      const Offset(C.chargeW + 14, 26),
      _speedLinePaint,
    );

    // 2. Orange glow
    canvas.drawRRect(_chargeRRect, _chargeGlowPaint);

    // 3. Orange body
    canvas.drawRRect(_chargeRRect, _chargeBodyPaint);

    // 4. Three dark chevrons "‹‹‹" pointing left
    canvas.drawPath(_chevronsPath, _chevronPaint);

    canvas.restore();
  }

  /// Paints telegraph warning icon: pulsing orange triangle with "!" (24x24).
  static void paintTelegraph(
    Canvas canvas, {
    Offset origin = Offset.zero,
    double t = 0.0,
  }) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);

    // Subtle scale pulse around center (12, 12)
    final pulseScale = 1.0 + 0.08 * math.sin(t * 12.0);
    canvas.translate(12, 12);
    canvas.scale(pulseScale, pulseScale);
    canvas.translate(-12, -12);

    // 1. Soft orange glow
    canvas.drawPath(_telegraphPath, _telegraphGlowPaint);

    // 2. Orange triangle
    canvas.drawPath(_telegraphPath, _telegraphTrianglePaint);

    // 3. Exclamation mark '!'
    canvas.drawLine(const Offset(12, 8), const Offset(12, 15), _telegraphStrokePaint);
    canvas.drawCircle(const Offset(12, 19), 1.2, _telegraphDotPaint);

    canvas.restore();
  }
}
