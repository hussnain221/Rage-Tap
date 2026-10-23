import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../game/game_state.dart';
import '../../game/rage_tap_game.dart';
import 'neon_button.dart';

/// In-game Heads Up Display (HUD) per spec §12.3:
/// - BEST (left, caption)
/// - Score (center, 44sp scoreHud style with 120ms 1.0->1.15->1.0 scale pop on bonus)
/// - Pause button (right, 48x48 NeonIconButton, hidden during dying/results)
class GameHud extends StatefulWidget {
  const GameHud({
    super.key,
    required this.game,
  });

  final RageTapGame game;

  @override
  State<GameHud> createState() => _GameHudState();
}

class _GameHudState extends State<GameHud>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scorePopController;
  late final Animation<double> _scoreScaleAnimation;

  @override
  void initState() {
    super.initState();

    _scorePopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _scoreScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_scorePopController);

    widget.game.scoreBonusTrigger.addListener(_onScoreBonus);
  }

  void _onScoreBonus() {
    _scorePopController.forward(from: 0.0);
  }

  @override
  void dispose() {
    widget.game.scoreBonusTrigger.removeListener(_onScoreBonus);
    _scorePopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: BEST score
          SizedBox(
            width: 80,
            child: ValueListenableBuilder<int>(
              valueListenable: widget.game.bestScore,
              builder: (context, best, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BEST',
                      style: AppTheme.caption.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$best',
                      style: AppTheme.body.copyWith(
                        color: Palette.yellow,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Center: Live run score with pop animation and teaching hint below
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _scoreScaleAnimation,
                  child: ValueListenableBuilder<int>(
                    valueListenable: widget.game.score,
                    builder: (context, score, _) {
                      return Text(
                        '$score',
                        style: AppTheme.scoreHud,
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ),
                IgnorePointer(
                  child: ValueListenableBuilder<String?>(
                    valueListenable: widget.game.hint,
                    builder: (context, hintText, _) {
                      return AnimatedOpacity(
                        opacity: hintText != null ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 150),
                        child: Text(
                          hintText ?? '',
                          style: AppTheme.h1.copyWith(
                            fontSize: 22,
                            color: Palette.yellow,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Right: Pause button (hidden during dying/results)
          Container(
            width: 80,
            alignment: Alignment.centerRight,
            child: ValueListenableBuilder<GameState>(
              valueListenable: widget.game.state,
              builder: (context, state, _) {
                final isHidden = state == GameState.dying || state == GameState.results;
                if (isHidden) {
                  return const SizedBox(width: 48, height: 48);
                }
                return NeonIconButton(
                  icon: const Icon(Icons.pause, color: Palette.cyan, size: 24),
                  tooltip: 'Pause',
                  onPressed: () => widget.game.pause(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
