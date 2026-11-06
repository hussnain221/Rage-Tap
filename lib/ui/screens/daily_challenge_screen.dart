import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../data/save_service.dart';
import '../../game/model/daily_challenge.dart';
import '../widgets/neon_button.dart';

/// Screen for the Daily Challenge per spec §20.4.
class DailyChallengeScreen extends StatelessWidget {
  const DailyChallengeScreen({
    super.key,
    this.currentDate,
  });

  final DateTime? currentDate;

  @override
  Widget build(BuildContext context) {
    final now = currentDate ?? DateTime.now();
    final challenge = DailyChallenge.forDate(now);

    return Scaffold(
      backgroundColor: Palette.bgDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top bar: Back button, Title, Coins indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  NeonIconButton(
                    icon: const Icon(Icons.arrow_back, color: Palette.cyan, size: 24),
                    tooltip: 'Back',
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushReplacementNamed('/home');
                      }
                    },
                  ),
                  Text(
                    'DAILY',
                    style: AppTheme.h1.copyWith(
                      color: Palette.cyan,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: SaveService.instance.totalCoinsNotifier,
                    builder: (context, coins, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Palette.bgPurple,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Palette.yellow.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on_rounded, color: Palette.yellow, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '$coins',
                              style: AppTheme.body.copyWith(
                                color: Palette.yellow,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),

              const Spacer(flex: 1),

              // Challenge Card
              ValueListenableBuilder<String?>(
                valueListenable: SaveService.instance.lastDailyCompletedDateNotifier,
                builder: (context, _, __) {
                  final isCompleted = SaveService.instance.isDailyCompleted(challenge.dateKey);

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Palette.bgPurple,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isCompleted ? Palette.green : Palette.yellow.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isCompleted ? Palette.green : Palette.yellow).withValues(alpha: 0.25),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCompleted ? Icons.check_circle_rounded : Icons.stars_rounded,
                          color: isCompleted ? Palette.green : Palette.yellow,
                          size: 56,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'GOAL OF THE DAY',
                          style: AppTheme.caption.copyWith(
                            color: Palette.muted,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          challenge.goalDescription,
                          style: AppTheme.h1.copyWith(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Reward
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on_rounded, color: Palette.yellow, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              '+${challenge.rewardCoins} coins reward',
                              style: AppTheme.body.copyWith(
                                color: Palette.yellow,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Palette.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Palette.green),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check, color: Palette.green, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'COMPLETED TODAY',
                                  style: AppTheme.caption.copyWith(
                                    color: Palette.green,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          NeonButton.primary(
                            text: 'START RUN',
                            width: 200,
                            height: 52,
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                '/game',
                                arguments: challenge,
                              );
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),

              const Spacer(flex: 2),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
