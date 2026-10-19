import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../game/rage_tap_game.dart';
import '../../game/systems/result_messages.dart';
import 'neon_button.dart';

/// Results overlay shown upon death per spec §12.5 and Appendix B.
class ResultsOverlay extends StatefulWidget {
  const ResultsOverlay({
    super.key,
    required this.game,
    this.onHomePressed,
  });

  final RageTapGame game;
  final VoidCallback? onHomePressed;

  @override
  State<ResultsOverlay> createState() => _ResultsOverlayState();
}

class _ResultsOverlayState extends State<ResultsOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _badgePulseController;
  late final AnimationController _confettiController;
  late final String _message;
  late final List<_ConfettiParticle> _confetti;

  @override
  void initState() {
    super.initState();

    final result = widget.game.lastResult;
    final isNewBest = widget.game.isNewBest.value;
    final score = widget.game.score.value;
    final best = widget.game.bestScore.value;

    _message = ResultMessages.select(
      isNewBest: isNewBest,
      score: score,
      bestScore: best,
      deathCause: result?.deathCause,
    );

    // 150ms fade-in
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..forward();

    // Pulsing badge (scale 1.0 <-> 1.08 in 0.8s loop)
    _badgePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (isNewBest) {
      _badgePulseController.repeat(reverse: true);
    }

    // 12 confetti squares for new best
    final rand = math.Random();
    const colors = [Palette.cyan, Palette.magenta, Palette.yellow, Palette.green];
    _confetti = List.generate(12, (i) {
      final angle = (rand.nextDouble() - 0.5) * math.pi;
      final speed = 80.0 + rand.nextDouble() * 120.0;
      return _ConfettiParticle(
        x: (rand.nextDouble() - 0.5) * 160.0,
        y: -10.0,
        vx: speed * math.sin(angle),
        vy: -speed * math.cos(angle).abs(),
        color: colors[i % colors.length],
        size: 5.0 + rand.nextDouble() * 3.0,
      );
    });

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (isNewBest) {
      _confettiController.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _badgePulseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final finalScore = widget.game.score.value;
    final bestScore = widget.game.bestScore.value;
    final isNewBest = widget.game.isNewBest.value;

    return FadeTransition(
      opacity: _fadeController,
      child: Container(
        color: Palette.scrim,
        alignment: Alignment.center,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // "GAME OVER" (h1, magenta)
                Text(
                  'GAME OVER',
                  style: AppTheme.h1.copyWith(
                    color: Palette.magenta,
                    letterSpacing: 3.0,
                    shadows: [
                      Shadow(
                        color: Palette.magenta.withValues(alpha: 0.70),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Score count-up (72 sp, white, 0 to final over 300 ms)
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: finalScore),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, val, _) {
                    return Text(
                      '$val',
                      style: AppTheme.scoreResult.copyWith(
                        color: Palette.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.60),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                // Best Score or Pulsing New Best Badge with Confetti
                if (isNewBest) ...[
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Confetti falling squares
                      AnimatedBuilder(
                        animation: _confettiController,
                        builder: (context, _) {
                          final t = _confettiController.value;
                          final alpha = (1.0 - t).clamp(0.0, 1.0);
                          return CustomPaint(
                            painter: _ConfettiPainter(
                              particles: _confetti,
                              progress: t,
                              alpha: alpha,
                            ),
                          );
                        },
                      ),
                      // Pulsing badge
                      ScaleTransition(
                        scale: Tween<double>(begin: 1.0, end: 1.08).animate(
                          CurvedAnimation(
                            parent: _badgePulseController,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Palette.yellow.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Palette.yellow, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Palette.yellow.withValues(alpha: 0.40),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Text(
                            '★ NEW BEST! ★',
                            style: AppTheme.body.copyWith(
                              color: Palette.yellow,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'BEST  ',
                        style: AppTheme.caption.copyWith(
                          color: Palette.yellow,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        '$bestScore',
                        style: AppTheme.body.copyWith(
                          color: Palette.yellow,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),

                // Funny message from Appendix B
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '"$_message"',
                    style: AppTheme.body.copyWith(
                      color: Palette.muted,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const Spacer(flex: 3),

                // RETRY button (primary 280x64, lower third thumb zone)
                NeonButton.primary(
                  text: 'RETRY',
                  width: 280,
                  height: 64,
                  onPressed: () => widget.game.retry(),
                ),

                const SizedBox(height: 12),

                // HOME button (secondary 280x48)
                NeonButton.secondary(
                  text: 'HOME',
                  width: 280,
                  height: 48,
                  onPressed: widget.onHomePressed ?? () => Navigator.of(context).pop(),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
  });

  final double x;
  final double y;
  final double vx;
  final double vy;
  final Color color;
  final double size;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.alpha,
  });

  final List<_ConfettiParticle> particles;
  final double progress;
  final double alpha;
  final Paint _paint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (alpha <= 0.0) return;

    for (final p in particles) {
      final currentX = p.x + p.vx * progress;
      final currentY = p.y + p.vy * progress + 400.0 * progress * progress;

      _paint.color = p.color.withValues(alpha: alpha);
      canvas.drawRect(
        Rect.fromLTWH(currentX, currentY, p.size, p.size),
        _paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.alpha != alpha;
  }
}
