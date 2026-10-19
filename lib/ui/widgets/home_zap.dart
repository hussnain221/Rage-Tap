import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../../game/painting/zap_painter.dart';

/// Animated Zap at 96x96 running in place on a short neon ground strip,
/// hopping every 2 seconds.
class HomeZap extends StatefulWidget {
  const HomeZap({
    super.key,
    this.size = 96.0,
    this.groundWidth = 180.0,
  });

  final double size;
  final double groundWidth;

  @override
  State<HomeZap> createState() => _HomeZapState();
}

class _HomeZapState extends State<HomeZap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final totalSeconds = _controller.value * 2.0; // 0.0 to 2.0s
        final cycleTime = totalSeconds % 2.0;

        ZapExpression expression;
        double hopY = 0.0;
        double scaleX = 1.0;
        double scaleY = 1.0;

        // Hop occurs between 1.6s and 2.0s (duration 0.4s)
        if (cycleTime >= 1.6) {
          final hopProgress = (cycleTime - 1.6) / 0.4; // 0.0 to 1.0
          hopY = -math.sin(hopProgress * math.pi) * 26.0;
          expression = ZapExpression.air;

          // Takeoff squash/stretch during first 0.08s of hop
          if (hopProgress < 0.2) {
            scaleX = 0.88;
            scaleY = 1.15;
          }
          // Landing squash during last 0.08s of hop
          else if (hopProgress > 0.8) {
            scaleX = 1.15;
            scaleY = 0.88;
          }
        } else {
          expression = ZapExpression.run;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _HomeZapPainter(
                  size: widget.size,
                  time: totalSeconds * 3.0,
                  expression: expression,
                  hopY: hopY,
                  scaleX: scaleX,
                  scaleY: scaleY,
                ),
              ),
            ),
            // Short neon ground strip
            Container(
              width: widget.groundWidth,
              height: 12,
              decoration: BoxDecoration(
                color: Palette.groundFill,
                borderRadius: BorderRadius.circular(4),
                border: const Border(
                  top: BorderSide(color: Palette.cyan, width: 3.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Palette.cyan.withValues(alpha: 0.50),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HomeZapPainter extends CustomPainter {
  const _HomeZapPainter({
    required this.size,
    required this.time,
    required this.expression,
    required this.hopY,
    required this.scaleX,
    required this.scaleY,
  });

  final double size;
  final double time;
  final ZapExpression expression;
  final double hopY;
  final double scaleX;
  final double scaleY;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    ZapPainter.paintZap(
      canvas,
      origin: Offset(0, hopY),
      size: size,
      expression: expression,
      t: time,
      scaleX: scaleX,
      scaleY: scaleY,
    );
  }

  @override
  bool shouldRepaint(covariant _HomeZapPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.expression != expression ||
        oldDelegate.hopY != hopY;
  }
}
