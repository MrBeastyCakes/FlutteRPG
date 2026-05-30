import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/game/game_chip.dart';

/// Inventory header — title + gold chip.
class InventoryHeader extends StatelessWidget {
  const InventoryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<GameEngine>().playerStats;
    return Row(
      children: [
        Text('Inventory', style: DSText.headingLarge(context)),
        const Spacer(),
        GameChip(
          label: '${stats.gold} gold',
          icon: Icons.attach_money,
          color: DSColors.goldAccent,
          size: GameChipSize.md,
        ),
      ],
    );
  }
}
