import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../data/save_service.dart';
import '../widgets/home_zap.dart';
import '../widgets/logo.dart';
import '../widgets/neon_button.dart';

/// The game's Home screen per spec §12.2.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.bgDeep,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Top bar: Settings icon (top-right)
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: NeonIconButton(
                              icon: const Icon(Icons.settings, color: Palette.cyan, size: 24),
                              tooltip: 'Settings',
                              onPressed: () {
                                Navigator.of(context).pushNamed('/settings');
                              },
                            ),
                          ),
                        ),

                        const Spacer(flex: 1),

                        // Logo: "RAGE" (cyan) over "TAP" (magenta)
                        const Logo(fontSize: 64, overlap: 14),
                        const SizedBox(height: 8),

                        // Tagline
                        const Text(
                          'One tap. One mistake. One more try.',
                          style: AppTheme.caption,
                          textAlign: TextAlign.center,
                        ),

                        const Spacer(flex: 2),

                        // Animated Zap on neon ground strip (96x96 with hop)
                        const HomeZap(size: 96, groundWidth: 180),

                        const Spacer(flex: 2),

                        // Big primary PLAY button (240x68)
                        NeonButton.primary(
                          text: 'PLAY',
                          width: 240,
                          height: 68,
                          onPressed: () {
                            Navigator.of(context).pushNamed('/game');
                          },
                        ),

                        const SizedBox(height: 16),

                        // Best score label
                        ValueListenableBuilder<int>(
                          valueListenable: SaveService.instance.bestScoreNotifier,
                          builder: (context, best, _) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
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
                                  '$best',
                                  style: AppTheme.h1.copyWith(
                                    color: Palette.yellow,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const Spacer(flex: 2),

                        // Version text bottom-center
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'v1.0.0',
                            style: AppTheme.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
