import 'package:flutter/material.dart';

import '../../core/palette.dart';

/// Data-driven definition of a Zap cosmetic skin per spec §20.3.
class ZapSkin {
  final String id;
  final String name;
  final int price;
  final Color primaryColor;
  final Color darkColor;
  final Color glowColor;
  final bool isTranslucent;
  final bool hasPixelEyes;
  final bool hasLightningMark;
  final bool hasCrown;

  const ZapSkin({
    required this.id,
    required this.name,
    required this.price,
    required this.primaryColor,
    required this.darkColor,
    Color? glowColor,
    this.isTranslucent = false,
    this.hasPixelEyes = false,
    this.hasLightningMark = false,
    this.hasCrown = false,
  }) : glowColor = glowColor ?? primaryColor;

  /// 1. Zap (cyan, free default)
  static const ZapSkin zap = ZapSkin(
    id: 'zap',
    name: 'Zap',
    price: 0,
    primaryColor: Palette.cyan,
    darkColor: Palette.cyanDark,
  );

  /// 2. Blaze (orange, 100 coins)
  static const ZapSkin blaze = ZapSkin(
    id: 'blaze',
    name: 'Blaze',
    price: 100,
    primaryColor: Palette.orange,
    darkColor: Color(0xFFC75000),
  );

  /// 3. Pixel (green with square pixel eyes, 150 coins)
  static const ZapSkin pixel = ZapSkin(
    id: 'pixel',
    name: 'Pixel',
    price: 150,
    primaryColor: Color(0xFF00E676),
    darkColor: Color(0xFF00A344),
    hasPixelEyes: true,
  );

  /// 4. Ghost (white translucent, 250 coins)
  static const ZapSkin ghost = ZapSkin(
    id: 'ghost',
    name: 'Ghost',
    price: 250,
    primaryColor: Colors.white,
    darkColor: Color(0xFFB0BEC5),
    isTranslucent: true,
  );

  /// 5. Bolt (yellow with lightning mark, 400 coins)
  static const ZapSkin bolt = ZapSkin(
    id: 'bolt',
    name: 'Bolt',
    price: 400,
    primaryColor: Palette.yellow,
    darkColor: Color(0xFFC79A00),
    hasLightningMark: true,
  );

  /// 6. Royal (purple with small crown, 600 coins)
  static const ZapSkin royal = ZapSkin(
    id: 'royal',
    name: 'Royal',
    price: 600,
    primaryColor: Color(0xFFAB47BC),
    darkColor: Color(0xFF6A1B9A),
    hasCrown: true,
  );

  static const List<ZapSkin> all = [
    zap,
    blaze,
    pixel,
    ghost,
    bolt,
    royal,
  ];

  static ZapSkin fromId(String? id) {
    if (id == null) return zap;
    return all.firstWhere((s) => s.id == id, orElse: () => zap);
  }
}
