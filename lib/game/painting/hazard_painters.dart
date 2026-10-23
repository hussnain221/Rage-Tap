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

  // --- Tall wall cached assets ---
  static final RRect _tallWallRRect = RRect.fromRectAndRadius(
    const Rect.fromLTWH(0, 0, C.tallW, C.tallH),
    const Radius.circular(6),
  );

  static final Paint _tallWallGlowPaint = Paint()
    ..color = Palette.magenta.withValues(alpha: 0.45)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

  static final Paint _tallWallBodyPaint = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Palette.magenta, Palette.magentaDark],
    ).createShader(const Rect.fromLTWH(0, 0, C.tallW, C.tallH));

  static final Paint _tallWallStripePaint = Paint()
    ..color = Palette.yellow.withValues(alpha: 0.35)
    ..strokeWidth = 3.0
    ..style = PaintingStyle.stroke;

  static final Paint _tallAntennaPaint = Paint()
    ..color = Palette.yellow
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round;

  static final Paint _tallAntennaTipPaint = Paint()
    ..color = Palette.yellow
    ..style = PaintingStyle.fill;

  static final Paint _tallAntennaTipGlowPaint = Paint()
    ..color = Palette.yellow
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

  // --- Overhead beam cached assets ---
  static const double _beamDroneW = C.beamDroneW; // 44
  static const double _beamDroneH = C.beamDroneH; // 30
  static const double _beamTotalH = C.beamBottomY - C.beamDroneTopY; // 354
  static const double _beamColW = 10.0;
  static const double _beamColX = (_beamDroneW - _beamColW) / 2; // 17

  static final RRect _droneRRect = RRect.fromRectAndRadius(
    const Rect.fromLTWH(0, 0, _beamDroneW, _beamDroneH),
    const Radius.circular(10),
  );

  static final RRect _droneStripRRect = RRect.fromRectAndRadius(
    const Rect.fromLTWH(6, 3, 32, 4),
    const Radius.circular(2),
  );

  static final Paint _droneBodyPaint = Paint()
    ..color = Palette.magentaDark
    ..style = PaintingStyle.fill;

  static final Paint _droneStripPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.25)
    ..style = PaintingStyle.fill;

  static final Paint _droneEyePaint = Paint()
    ..color = Palette.orange
    ..style = PaintingStyle.fill;

  static final Paint _droneRotorPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.40)
    ..style = PaintingStyle.fill;

  static const Rect _beamColRect = Rect.fromLTWH(
    _beamColX,
    _beamDroneH,
    _beamColW,
    _beamTotalH - _beamDroneH,
  );

  static final Paint _beamColumnPaint = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Palette.orange, Palette.magenta],
    ).createShader(_beamColRect);

  static final Paint _beamGlowPaint = Paint()
    ..color = Palette.magenta.withValues(alpha: 0.40)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  static final Paint _emitterGlowPaint = Paint()
    ..color = Palette.orange.withValues(alpha: 0.60)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  static final Paint _emitterCorePaint = Paint()
    ..color = Palette.white
    ..style = PaintingStyle.fill;

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

  /// Paints tall wall: 30x68 rounded rect (radius 6), vertical gradient from
  /// magenta to magentaDark, horizontal yellow@35% stripes on lower half,
  /// 2-unit antenna (8 units high) at top center with pulsing yellow tip (radius 3),
  /// soft magenta glow (blur 8).
  static void paintTallWall(
    Canvas canvas, {
    Offset origin = Offset.zero,
    double t = 0.0,
  }) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);

    // 1. Soft magenta glow around body (blur 8)
    canvas.drawRRect(_tallWallRRect, _tallWallGlowPaint);

    // 2. Body with vertical gradient
    canvas.drawRRect(_tallWallRRect, _tallWallBodyPaint);

    // 3. Horizontal yellow@35% hazard stripes on lower half (y: 34 to 68)
    canvas.save();
    canvas.clipRRect(_tallWallRRect);
    for (double y = 40.0; y < C.tallH; y += 8.0) {
      canvas.drawLine(Offset(0, y), Offset(C.tallW, y), _tallWallStripePaint);
    }
    canvas.restore();

    // 4. Thin 2-unit antenna (8 units high) at top center (x = 15)
    canvas.drawLine(const Offset(15, 0), const Offset(15, -8), _tallAntennaPaint);

    // 5. Glowing yellow tip at (15, -8) pulsing at ~1.5 Hz
    final pulse = 0.6 + 0.4 * math.sin(t * 1.5 * 2 * math.pi);
    _tallAntennaTipGlowPaint.color = Palette.yellow.withValues(alpha: 0.5 * pulse);
    canvas.drawCircle(const Offset(15, -8), 3.0, _tallAntennaTipGlowPaint);
    canvas.drawCircle(const Offset(15, -8), 3.0, _tallAntennaTipPaint);

    canvas.restore();
  }

  /// Paints overhead beam: 44x354 drone body at top, vertical beam column,
  /// glowing emitter tip at y=354.
  static void paintOverheadBeam(
    Canvas canvas, {
    Offset origin = Offset.zero,
    double t = 0.0,
  }) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);

    // 1. Beam outer glow (soft pulse at ~2.5 Hz, alpha 0.75-1.0)
    final pulse = 0.75 + 0.25 * math.sin(t * 2.5 * 2 * math.pi);
    _beamGlowPaint.color = Palette.magenta.withValues(alpha: 0.40 * pulse);
    canvas.drawRect(_beamColRect, _beamGlowPaint);

    // 2. Beam column (width 10, vertical gradient orange to magenta)
    canvas.drawRect(_beamColRect, _beamColumnPaint);

    // 3. Emitter tip at y=354: glowing circle radius 8 (orange glow, white core)
    const tipCenter = Offset(_beamDroneW / 2, _beamTotalH);
    canvas.drawCircle(tipCenter, 8.0, _emitterGlowPaint);
    canvas.drawCircle(tipCenter, 4.0, _emitterCorePaint);

    // 4. Drone body (44x30 rounded rect radius 10 in magentaDark)
    canvas.drawRRect(_droneRRect, _droneBodyPaint);

    // 5. Lighter top strip
    canvas.drawRRect(_droneStripRRect, _droneStripPaint);

    // 6. Orange eye light in center (radius 4)
    canvas.drawCircle(const Offset(_beamDroneW / 2, _beamDroneH / 2), 4.0, _droneEyePaint);

    // 7. Two tiny rotor ellipses on sides (rotating at 12 Hz)
    final rotorW = 8.0 + 4.0 * math.sin(t * 12.0 * 2 * math.pi);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(3, 8), width: rotorW.abs(), height: 3.5),
      _droneRotorPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(_beamDroneW - 3, 8), width: rotorW.abs(), height: 3.5),
      _droneRotorPaint,
    );

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

  // --- Pit cached assets ---
  static final Paint _pitVoidPaint = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF04020A), Colors.black],
    ).createShader(const Rect.fromLTWH(0, 0, 100, 140));

  static final Paint _pitGlowPaint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, Palette.magenta.withValues(alpha: 0.25)],
    ).createShader(const Rect.fromLTWH(0, 70, 100, 70));

  static final Paint _pitDepthLinePaint = Paint()
    ..color = Palette.cyan.withValues(alpha: 0.08)
    ..strokeWidth = 1.0;

  static final Paint _pitEdgeLinePaint = Paint()
    ..color = Palette.cyan
    ..strokeWidth = 3.0;

  static final Paint _pitEdgeGlowPaint = Paint()
    ..color = Palette.cyan.withValues(alpha: 0.45)
    ..strokeWidth = 5.0
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

  static final Paint _pitWarningDarkPaint = Paint()
    ..color = Palette.bgDeep
    ..style = PaintingStyle.fill;

  static final Paint _pitWarningStripePaint = Paint()
    ..color = Palette.orange
    ..strokeWidth = 3.0;

  /// Paints pit: void rectangle from y=groundTopY to bottom across hole width,
  /// vertical gradient from bgDeep darkened to black, faint vertical depth lines (cyan@8%),
  /// soft magenta glow rising from bottom (alpha 0.25 gradient), two 3-unit cyan edge lines
  /// with soft glow, and 14-unit-wide orange/dark diagonal lip warning stripes on each side.
  static void paintPit(
    Canvas canvas, {
    required double width,
    Offset origin = Offset.zero,
  }) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);

    const double pitH = C.worldH - C.groundTopY; // 140.0

    // 1. Void rectangle from y=0 to bottom across width (breaks the ground's top line)
    canvas.drawRect(Rect.fromLTWH(0, 0, width, pitH), _pitVoidPaint);

    // 2. Faint vertical depth lines (cyan @ 8%)
    for (double dx = 16.0; dx < width; dx += 16.0) {
      canvas.drawLine(Offset(dx, 12), Offset(dx, pitH - 8), _pitDepthLinePaint);
    }

    // 3. Soft magenta glow rising from the bottom (alpha 0.25 gradient)
    canvas.drawRect(Rect.fromLTWH(0, 70, width, 70), _pitGlowPaint);

    // 4. Edges: two 3-unit Palette.cyan vertical lines with soft glow at both hole edges
    canvas.drawLine(Offset.zero, const Offset(0, pitH), _pitEdgeGlowPaint);
    canvas.drawLine(Offset.zero, const Offset(0, pitH), _pitEdgeLinePaint);
    canvas.drawLine(Offset(width, 0), Offset(width, pitH), _pitEdgeGlowPaint);
    canvas.drawLine(Offset(width, 0), Offset(width, pitH), _pitEdgeLinePaint);

    // 5. Lip warning: 14-unit-wide orange/dark diagonal warning stripes on ground top
    _paintLipWarning(canvas, -14.0, 0.0);
    _paintLipWarning(canvas, width, width + 14.0);

    canvas.restore();
  }

  static void _paintLipWarning(Canvas canvas, double left, double right) {
    const double h = 8.0;
    final w = right - left;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(left, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(left, 0, w, h), _pitWarningDarkPaint);
    for (double sx = left - h; sx < right + h; sx += 6.0) {
      canvas.drawLine(Offset(sx, h), Offset(sx + h, 0), _pitWarningStripePaint);
    }
    canvas.restore();
  }
}
