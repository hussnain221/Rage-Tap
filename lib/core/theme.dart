import 'package:flutter/material.dart';

import 'palette.dart';

class AppTheme {
  const AppTheme._();

  static const TextStyle logo = TextStyle(
    fontSize: 64,
    fontWeight: FontWeight.w900,
    letterSpacing: 2,
    color: Palette.white,
    shadows: [
      Shadow(
        color: Color(0x9922E3FF),
        blurRadius: 18,
      ),
    ],
  );

  static const TextStyle scoreHud = TextStyle(
    fontSize: 44,
    fontWeight: FontWeight.w800,
    color: Palette.white,
    shadows: [
      Shadow(
        color: Colors.black54,
        blurRadius: 6,
      ),
    ],
  );

  static const TextStyle scoreResult = TextStyle(
    fontSize: 72,
    fontWeight: FontWeight.w900,
    color: Palette.white,
  );

  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: Palette.white,
  );

  static const TextStyle button = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
    color: Palette.white,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Palette.white,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Palette.muted,
  );

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Palette.bgDeep,
        colorScheme: const ColorScheme.dark(
          surface: Palette.bgDeep,
          primary: Palette.cyan,
          secondary: Palette.magenta,
        ),
      );
}
