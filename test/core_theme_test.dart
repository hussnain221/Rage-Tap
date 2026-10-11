import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/core/constants.dart';
import 'package:rage_tap/core/palette.dart';
import 'package:rage_tap/core/theme.dart';

void main() {
  test('Constants, Palette, and Theme smoke test', () {
    expect(C.worldW, 360);
    expect(C.worldH, 640);
    expect(C.groundTopY, 500);
    expect(C.playerSize, 40);
    expect(C.gravity, 2000);
    expect(C.jumpVelocity, 640);

    expect(Palette.bgDeep, const Color(0xFF0B1026));
    expect(Palette.cyan, const Color(0xFF22E3FF));
    expect(Palette.magenta, const Color(0xFFFF2E93));

    expect(AppTheme.logo.fontSize, 64);
    expect(AppTheme.h1.fontSize, 28);
    expect(AppTheme.darkTheme.scaffoldBackgroundColor, Palette.bgDeep);
  });
}
