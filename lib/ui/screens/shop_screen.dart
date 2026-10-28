import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../data/save_service.dart';
import '../../game/model/zap_skin.dart';
import '../widgets/home_zap.dart';
import '../widgets/neon_button.dart';

/// Shop screen displaying a 2-column grid of cosmetic Zap skins per spec §20.3.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Back button, Title, Coins balance
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
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
                    'SHOP',
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
            ),

            const SizedBox(height: 8),

            // 2-column Grid of Skins
            Expanded(
              child: ValueListenableBuilder<List<String>>(
                valueListenable: SaveService.instance.ownedSkinsNotifier,
                builder: (context, ownedSkins, _) {
                  return ValueListenableBuilder<String>(
                    valueListenable: SaveService.instance.equippedSkinNotifier,
                    builder: (context, equippedSkinId, _) {
                      return ValueListenableBuilder<int>(
                        valueListenable: SaveService.instance.totalCoinsNotifier,
                        builder: (context, totalCoins, _) {
                          return GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            physics: const BouncingScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.76,
                            ),
                            itemCount: ZapSkin.all.length,
                            itemBuilder: (context, index) {
                              final skin = ZapSkin.all[index];
                              final isOwned = ownedSkins.contains(skin.id) || skin.id == ZapSkin.zap.id;
                              final isEquipped = equippedSkinId == skin.id;
                              final canAfford = totalCoins >= skin.price;

                              return _SkinCard(
                                skin: skin,
                                isOwned: isOwned,
                                isEquipped: isEquipped,
                                canAfford: canAfford,
                                onEquip: () async {
                                  await SaveService.instance.equipSkin(skin.id);
                                },
                                onBuy: () async {
                                  final success = await SaveService.instance.purchaseSkin(skin);
                                  if (!success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Not enough coins!'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkinCard extends StatelessWidget {
  const _SkinCard({
    required this.skin,
    required this.isOwned,
    required this.isEquipped,
    required this.canAfford,
    required this.onEquip,
    required this.onBuy,
  });

  final ZapSkin skin;
  final bool isOwned;
  final bool isEquipped;
  final bool canAfford;
  final VoidCallback onEquip;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final borderColor = isEquipped
        ? Palette.cyan
        : (isOwned ? skin.primaryColor.withValues(alpha: 0.6) : Palette.muted.withValues(alpha: 0.25));

    return Container(
      decoration: BoxDecoration(
        color: Palette.bgPurple,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: isEquipped ? 2.0 : 1.0,
        ),
        boxShadow: isEquipped
            ? [
                BoxShadow(
                  color: Palette.cyan.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Skin animated preview (64px)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: HomeZap(
              size: 56,
              groundWidth: 90,
              skin: skin,
            ),
          ),

          // Skin Name
          Text(
            skin.name,
            style: AppTheme.body.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),

          // Action: EQUIPPED / EQUIP / BUY
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: _buildActionButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (isEquipped) {
      return Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Palette.cyan.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Palette.cyan, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check, color: Palette.cyan, size: 16),
            const SizedBox(width: 4),
            Text(
              'EQUIPPED',
              style: AppTheme.caption.copyWith(
                color: Palette.cyan,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      );
    }

    if (isOwned) {
      return SizedBox(
        width: double.infinity,
        height: 34,
        child: ElevatedButton(
          onPressed: onEquip,
          style: ElevatedButton.styleFrom(
            backgroundColor: Palette.bgDeep,
            foregroundColor: Palette.cyan,
            elevation: 0,
            side: const BorderSide(color: Palette.cyan, width: 1.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: EdgeInsets.zero,
          ),
          child: Text(
            'EQUIP',
            style: AppTheme.caption.copyWith(
              color: Palette.cyan,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ),
      );
    }

    // Unowned: Price & Buy button
    return SizedBox(
      width: double.infinity,
      height: 34,
      child: ElevatedButton(
        onPressed: canAfford ? onBuy : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canAfford ? Palette.yellow.withValues(alpha: 0.18) : Colors.transparent,
          disabledBackgroundColor: Palette.bgDeep.withValues(alpha: 0.3),
          foregroundColor: Palette.yellow,
          elevation: 0,
          side: BorderSide(
            color: canAfford ? Palette.yellow : Palette.muted.withValues(alpha: 0.25),
            width: 1.0,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.monetization_on_rounded,
              color: canAfford ? Palette.yellow : Palette.muted,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '${skin.price}',
              style: AppTheme.caption.copyWith(
                color: canAfford ? Palette.yellow : Palette.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
