import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rage_tap/data/save_service.dart';
import 'package:rage_tap/game/model/zap_skin.dart';
import 'package:rage_tap/game/painting/zap_painter.dart';
import 'package:rage_tap/ui/screens/shop_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ZapSkin data-driven definitions (§20.3)', () {
    test('Contains exactly 6 cosmetic skins with correct spec properties', () {
      expect(ZapSkin.all.length, 6);

      final zap = ZapSkin.zap;
      expect(zap.id, 'zap');
      expect(zap.price, 0);

      final blaze = ZapSkin.blaze;
      expect(blaze.id, 'blaze');
      expect(blaze.price, 100);

      final pixel = ZapSkin.pixel;
      expect(pixel.id, 'pixel');
      expect(pixel.price, 150);
      expect(pixel.hasPixelEyes, isTrue);

      final ghost = ZapSkin.ghost;
      expect(ghost.id, 'ghost');
      expect(ghost.price, 250);
      expect(ghost.isTranslucent, isTrue);

      final bolt = ZapSkin.bolt;
      expect(bolt.id, 'bolt');
      expect(bolt.price, 400);
      expect(bolt.hasLightningMark, isTrue);

      final royal = ZapSkin.royal;
      expect(royal.id, 'royal');
      expect(royal.price, 600);
      expect(royal.hasCrown, isTrue);
    });

    test('ZapSkin.fromId returns corresponding skin or defaults to zap', () {
      expect(ZapSkin.fromId('blaze'), ZapSkin.blaze);
      expect(ZapSkin.fromId('ghost'), ZapSkin.ghost);
      expect(ZapSkin.fromId('non_existent'), ZapSkin.zap);
      expect(ZapSkin.fromId(null), ZapSkin.zap);
    });
  });

  group('SaveService skins and purchase logic (§20.3)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await SaveService.instance.init();
    });

    test('Default skin is zap, owned and equipped', () async {
      final saveService = SaveService.instance;
      expect(saveService.equippedSkin, 'zap');
      expect(saveService.isSkinOwned('zap'), isTrue);
      expect(saveService.isSkinOwned('blaze'), isFalse);
      expect(saveService.ownedSkins, contains('zap'));
    });

    test('Cannot equip unowned skin', () async {
      final saveService = SaveService.instance;
      final equipped = await saveService.equipSkin('royal');
      expect(equipped, isFalse);
      expect(saveService.equippedSkin, 'zap');
    });

    test('Purchase fails if already owned', () async {
      final saveService = SaveService.instance;
      await saveService.addCoins(500);

      final result = await saveService.purchaseSkin(ZapSkin.zap);
      expect(result, isFalse);
      expect(saveService.totalCoins, 500);
    });

    test('Purchase fails if not enough coins', () async {
      final saveService = SaveService.instance;
      await saveService.addCoins(50); // Blaze is 100

      final result = await saveService.purchaseSkin(ZapSkin.blaze);
      expect(result, isFalse);
      expect(saveService.totalCoins, 50);
      expect(saveService.isSkinOwned('blaze'), isFalse);
      expect(saveService.equippedSkin, 'zap');
    });

    test('Purchase succeeds with enough coins: subtracts once, marks owned, equips, and saves', () async {
      final saveService = SaveService.instance;
      await saveService.addCoins(250);

      // Buy Blaze (100 coins)
      final result = await saveService.purchaseSkin(ZapSkin.blaze);
      expect(result, isTrue);
      expect(saveService.totalCoins, 150);
      expect(saveService.isSkinOwned('blaze'), isTrue);
      expect(saveService.equippedSkin, 'blaze');

      // Equipping previously owned zap works
      final equippedZap = await saveService.equipSkin('zap');
      expect(equippedZap, isTrue);
      expect(saveService.equippedSkin, 'zap');

      // Re-equipping blaze works
      final reEquippedBlaze = await saveService.equipSkin('blaze');
      expect(reEquippedBlaze, isTrue);
      expect(saveService.equippedSkin, 'blaze');
    });

    test('Purchased skins persist across re-initialization', () async {
      final saveService = SaveService.instance;
      await saveService.addCoins(300);
      await saveService.purchaseSkin(ZapSkin.pixel);

      expect(saveService.equippedSkin, 'pixel');
      expect(saveService.isSkinOwned('pixel'), isTrue);

      // Re-init from same underlying SharedPreferences
      await saveService.init();
      expect(saveService.equippedSkin, 'pixel');
      expect(saveService.isSkinOwned('pixel'), isTrue);
      expect(saveService.totalCoins, 150);
    });
  });

  group('ZapPainter renders all 6 skins cleanly without error', () {
    test('Paints all skins in all expressions', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      for (final skin in ZapSkin.all) {
        for (final expr in ZapExpression.values) {
          ZapPainter.paintZap(
            canvas,
            origin: Offset.zero,
            size: 40.0,
            expression: expr,
            skin: skin,
            isRage: false,
          );
          ZapPainter.paintZap(
            canvas,
            origin: Offset.zero,
            size: 40.0,
            expression: expr,
            skin: skin,
            isRage: true,
          );
        }
      }
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });

  group('ShopScreen widget tests (§20.3)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({'total_coins': 200});
      await SaveService.instance.init();
    });

    testWidgets('ShopScreen renders header, coins balance, and all 6 skins', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: ShopScreen(),
        ),
      );

      expect(find.text('SHOP'), findsOneWidget);
      expect(find.text('200'), findsOneWidget);

      for (final skin in ZapSkin.all) {
        expect(find.text(skin.name), findsOneWidget);
      }

      // Default Zap is EQUIPPED
      expect(find.text('EQUIPPED'), findsOneWidget);

      // Blaze (100) is affordable with 200 coins
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('Tapping BUY on affordable skin purchases and equips it', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ShopScreen(),
        ),
      );

      // Tap buy on Blaze (100)
      await tester.tap(find.text('100'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(SaveService.instance.isSkinOwned('blaze'), isTrue);
      expect(SaveService.instance.equippedSkin, 'blaze');
      expect(SaveService.instance.totalCoins, 100);

      // Now Zap should have EQUIP button and Blaze should be EQUIPPED
      expect(find.text('EQUIP'), findsOneWidget);
    });
  });
}
