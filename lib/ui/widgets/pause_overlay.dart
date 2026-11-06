import 'package:flutter/material.dart';

import '../../audio/audio_service.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../data/save_service.dart';
import '../../game/rage_tap_game.dart';
import 'neon_button.dart';

/// Pause card overlay and resume countdown per spec §12.4.
class PauseOverlay extends StatefulWidget {
  const PauseOverlay({
    super.key,
    required this.game,
    this.saveService,
    this.onHomePressed,
  });

  final RageTapGame game;
  final SaveService? saveService;
  final VoidCallback? onHomePressed;

  @override
  State<PauseOverlay> createState() => _PauseOverlayState();
}

class _PauseOverlayState extends State<PauseOverlay> {
  late bool _sound;
  late bool _haptics;

  SaveService get _save => widget.saveService ?? SaveService.instance;

  @override
  void initState() {
    super.initState();
    _sound = _save.soundEnabled;
    _haptics = _save.hapticsEnabled;
  }

  void _toggleSound() {
    setState(() {
      _sound = !_sound;
      _save.setSoundEnabled(_sound);
      AudioService.instance.onSoundEnabledChanged(_sound);
    });
  }

  void _toggleHaptics() {
    setState(() {
      _haptics = !_haptics;
      _save.setHapticsEnabled(_haptics);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Palette.scrim,
      alignment: Alignment.center,
      child: Container(
        width: 300,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Palette.bgPurple,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Palette.cyan.withValues(alpha: 0.50),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.60),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title
            Text(
              'PAUSED',
              style: AppTheme.h1.copyWith(
                color: Palette.white,
                letterSpacing: 2.5,
                shadows: [
                  Shadow(
                    color: Palette.cyan.withValues(alpha: 0.60),
                    blurRadius: 16,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // RESUME (primary 260x56)
            NeonButton.primary(
              text: 'RESUME',
              width: 260,
              height: 56,
              onPressed: () => widget.game.beginResume(),
            ),
            const SizedBox(height: 12),

            // RESTART (secondary 260x48)
            NeonButton.secondary(
              text: 'RESTART',
              width: 260,
              height: 48,
              onPressed: () => widget.game.retry(),
            ),
            const SizedBox(height: 12),

            // HOME (secondary 260x48)
            NeonButton.secondary(
              text: 'HOME',
              width: 260,
              height: 48,
              onPressed: () {
                if (widget.game.score.value > widget.game.bestScore.value) {
                  widget.game.bestScore.value = widget.game.score.value;
                }
                _save.setBestIfHigher(widget.game.score.value);
                if (widget.onHomePressed != null) {
                  widget.onHomePressed!();
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
            const SizedBox(height: 20),

            // Sound & Haptics toggles
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NeonIconButton(
                  icon: Icon(
                    _sound ? Icons.volume_up : Icons.volume_off,
                    color: _sound ? Palette.cyan : Palette.muted,
                    size: 24,
                  ),
                  tooltip: _sound ? 'Sound On' : 'Sound Off',
                  onPressed: _toggleSound,
                ),
                const SizedBox(width: 20),
                NeonIconButton(
                  icon: Icon(
                    _haptics ? Icons.vibration : Icons.mobile_off,
                    color: _haptics ? Palette.cyan : Palette.muted,
                    size: 24,
                  ),
                  tooltip: _haptics ? 'Vibration On' : 'Vibration Off',
                  onPressed: _toggleHaptics,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 3-2-1 resume countdown overlay (96sp with scale pop each step).
class ResumeCountdownOverlay extends StatelessWidget {
  const ResumeCountdownOverlay({
    super.key,
    required this.game,
  });

  final RageTapGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Palette.scrim,
      alignment: Alignment.center,
      child: ValueListenableBuilder<int>(
        valueListenable: game.resumeCountdown,
        builder: (context, count, _) {
          if (count <= 0) return const SizedBox.shrink();

          return TweenAnimationBuilder<double>(
            key: ValueKey<int>(count),
            tween: Tween<double>(begin: 1.30, end: 1.0),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: Text(
              '$count',
              style: AppTheme.scoreResult.copyWith(
                fontSize: 96,
                color: Palette.cyan,
                shadows: [
                  Shadow(
                    color: Palette.cyan.withValues(alpha: 0.80),
                    blurRadius: 28,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
