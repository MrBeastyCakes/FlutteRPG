import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../models/inventory.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/game/game_card.dart';
import '../../widgets/game/game_chip.dart';

/// Equipped strip — collapsed equipment count; expands to show slot cards.
class EquippedStrip extends StatefulWidget {
  const EquippedStrip({super.key});

  @override
  State<EquippedStrip> createState() => _EquippedStripState();
}

class _EquippedStripState extends State<EquippedStrip> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    final equipped = _collectEquipped(engine);

    return GameCard(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Equipped (${equipped.length}/3)',
                    style: DSText.label(context)
                        .copyWith(color: DSColors.textSecondary)),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                    color: DSColors.textMuted),
              ],
            ),
          ),
          if (_expanded && equipped.isNotEmpty) ...[
            const SizedBox(height: DSSpace.sm),
            Row(
              children: [
                for (final e in equipped)
                  Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: DSSpace.xs),
                      child: _slotCard(context, e),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Collects the player's currently equipped weapon, armor and tools.
  /// Only filled slots are returned (progressive discovery — empty equip
  /// slots are never shown as greyed placeholders).
  List<_EquippedEntry> _collectEquipped(GameEngine engine) {
    final slots = <InventorySlot>[
      if (engine.equippedWeaponSlot != null) engine.equippedWeaponSlot!,
      if (engine.equippedArmorSlot != null) engine.equippedArmorSlot!,
      ...engine.equippedToolSlots.values,
    ];
    return [
      for (final s in slots)
        _EquippedEntry(
          icon: s.item.icon,
          name: s.item.name,
          currentDurability: s.currentDurability,
          maxDurability: s.maxDurability,
        ),
    ];
  }

  Widget _slotCard(BuildContext context, _EquippedEntry e) {
    final isWorn = e.maxDurability > 0 && e.currentDurability == 0;
    return GameCard(
      elevation: 2,
      padding: DSSpace.dense,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(e.icon, style: const TextStyle(fontSize: 28)),
          Text(e.name,
              style: DSText.label(context),
              maxLines: 2,
              textAlign: TextAlign.center),
          if (isWorn)
            GameChip(
                label: 'Worn',
                size: GameChipSize.sm,
                color: DSColors.warning,
                outlined: true),
        ],
      ),
    );
  }
}

class _EquippedEntry {
  final String icon;
  final String name;
  final int currentDurability;
  final int maxDurability;
  const _EquippedEntry({
    required this.icon,
    required this.name,
    required this.currentDurability,
    required this.maxDurability,
  });
}
