import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../../core/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.bgDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Settings', style: AppTheme.h1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Palette.cyan),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Text(
          'Settings',
          style: AppTheme.body,
        ),
      ),
    );
  }
}
