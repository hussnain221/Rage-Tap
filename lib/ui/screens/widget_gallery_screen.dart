import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../../core/theme.dart';
import '../widgets/logo.dart';
import '../widgets/neon_button.dart';

/// Debug-only gallery to visually inspect NeonButton and Logo components.
class WidgetGalleryScreen extends StatefulWidget {
  const WidgetGalleryScreen({super.key});

  @override
  State<WidgetGalleryScreen> createState() => _WidgetGalleryScreenState();
}

class _WidgetGalleryScreenState extends State<WidgetGalleryScreen> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.bgDeep,
      appBar: AppBar(
        backgroundColor: Palette.bgPurple,
        title: const Text('Widget Gallery (Debug)'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('--- LOGO ---', style: AppTheme.caption),
              const SizedBox(height: 12),
              const Logo(),
              const SizedBox(height: 16),
              const Logo(fontSize: 36, overlap: 8),
              const SizedBox(height: 32),

              const Text('--- PRIMARY BUTTONS ---', style: AppTheme.caption),
              const SizedBox(height: 12),
              NeonButton.primary(
                text: 'PLAY NOW ($_counter)',
                width: 260,
                onPressed: () => setState(() => _counter++),
              ),
              const SizedBox(height: 16),
              const NeonButton.primary(
                text: 'DISABLED PRIMARY',
                width: 260,
                onPressed: null,
              ),
              const SizedBox(height: 32),

              const Text('--- SECONDARY BUTTONS ---', style: AppTheme.caption),
              const SizedBox(height: 12),
              NeonButton.secondary(
                text: 'RESTART RUN',
                width: 260,
                onPressed: () => setState(() => _counter++),
              ),
              const SizedBox(height: 16),
              const NeonButton.secondary(
                text: 'DISABLED SECONDARY',
                width: 260,
                onPressed: null,
              ),
              const SizedBox(height: 32),

              const Text('--- DANGER BUTTONS ---', style: AppTheme.caption),
              const SizedBox(height: 12),
              NeonButton.danger(
                text: 'RESET PROGRESS',
                width: 260,
                onPressed: () => setState(() => _counter = 0),
              ),
              const SizedBox(height: 16),
              const NeonButton.danger(
                text: 'DISABLED DANGER',
                width: 260,
                onPressed: null,
              ),
              const SizedBox(height: 32),

              const Text('--- ICON BUTTONS (48x48) ---', style: AppTheme.caption),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  NeonIconButton(
                    icon: const Icon(Icons.settings, color: Palette.cyan),
                    tooltip: 'Settings',
                    onPressed: () => setState(() => _counter++),
                  ),
                  const SizedBox(width: 16),
                  NeonIconButton(
                    icon: const Icon(Icons.pause, color: Palette.cyan),
                    tooltip: 'Pause',
                    onPressed: () => setState(() => _counter++),
                  ),
                  const SizedBox(width: 16),
                  NeonIconButton(
                    icon: const Icon(Icons.refresh, color: Palette.cyan),
                    tooltip: 'Retry',
                    onPressed: () => setState(() => _counter++),
                  ),
                  const SizedBox(width: 16),
                  const NeonIconButton(
                    icon: Icon(Icons.volume_off, color: Palette.cyan),
                    tooltip: 'Disabled Icon',
                    onPressed: null,
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
