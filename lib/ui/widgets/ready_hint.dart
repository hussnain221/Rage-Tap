import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../data/save_service.dart';

/// Ready hint overlay shown only when state is ready:
/// - Pulsing "TAP TO JUMP" (h1, white)
/// - Animated tap ripple icon
/// - If SaveService.firstRunDone is false: "Jump over the hazards. Don't touch them."
class ReadyHint extends StatefulWidget {
  const ReadyHint({
    super.key,
    this.saveService,
  });

  final SaveService? saveService;

  @override
  State<ReadyHint> createState() => _ReadyHintState();
}

class _ReadyHintState extends State<ReadyHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final save = widget.saveService ?? SaveService.instance;
    final isFirstRun = !save.firstRunDone;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Animated tap ripple icon
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final rippleSize = 28.0 + (_rippleAnimation.value * 20.0);
              final rippleAlpha = (1.0 - _rippleAnimation.value).clamp(0.0, 0.8);

              return SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer expanding ripple ring
                    Container(
                      width: rippleSize,
                      height: rippleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Palette.cyan.withValues(alpha: rippleAlpha),
                          width: 2.0,
                        ),
                      ),
                    ),
                    // Center tap icon
                    const Icon(
                      Icons.touch_app,
                      color: Palette.cyan,
                      size: 28,
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // Pulsing "TAP TO JUMP"
          ScaleTransition(
            scale: _scaleAnimation,
            child: Text(
              'TAP TO JUMP',
              style: AppTheme.h1.copyWith(
                color: Palette.white,
                letterSpacing: 2.0,
                shadows: [
                  Shadow(
                    color: Palette.cyan.withValues(alpha: 0.60),
                    blurRadius: 16,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // First run hint
          if (isFirstRun) ...[
            const SizedBox(height: 10),
            Text(
              "Jump over the hazards. Don't touch them.",
              style: AppTheme.caption.copyWith(
                color: Palette.muted,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
