import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../../core/theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.bgDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Palette.cyan),
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('RAGE TAP', style: AppTheme.logo),
            const SizedBox(height: 12),
            const Text(
              'One tap. One mistake. One more try.',
              style: AppTheme.caption,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Palette.cyan,
                foregroundColor: Palette.bgDeep,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              ),
              onPressed: () {
                Navigator.of(context).pushNamed('/game');
              },
              child: const Text('PLAY', style: AppTheme.button),
            ),
          ],
        ),
      ),
    );
  }
}
