import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../../core/theme.dart';

/// The game's neon title logo: "RAGE" (cyan) over "TAP" (magenta) with glowing shadows.
class Logo extends StatelessWidget {
  const Logo({
    super.key,
    this.fontSize = 64.0,
    this.overlap = 14.0,
  });

  final double fontSize;
  final double overlap;

  @override
  Widget build(BuildContext context) {
    final rageStyle = AppTheme.logo.copyWith(
      fontSize: fontSize,
      color: Palette.cyan,
      height: 0.9,
      shadows: [
        Shadow(
          color: Palette.cyan.withValues(alpha: 0.60),
          blurRadius: 18,
        ),
      ],
    );

    final tapStyle = AppTheme.logo.copyWith(
      fontSize: fontSize,
      color: Palette.magenta,
      height: 0.9,
      shadows: [
        Shadow(
          color: Palette.magenta.withValues(alpha: 0.60),
          blurRadius: 18,
        ),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'RAGE',
          style: rageStyle,
          textAlign: TextAlign.center,
        ),
        Transform.translate(
          offset: Offset(0, -overlap),
          child: Text(
            'TAP',
            style: tapStyle,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
