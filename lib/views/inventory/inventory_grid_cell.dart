import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../models/inventory.dart';
import '../../models/item.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/game/game_card.dart';
import '../../widgets/game/game_chip.dart';
import '../../widgets/game/game_progress_bar.dart';
import '../../widgets/game/game_tooltip.dart';

/// Inventory grid cell — icon, quantity badge, durability bar; tap → detail
/// sheet, longpress → quick-action menu.
class InventoryGridCell extends StatelessWidget {
  final InventorySlot slot;
  const InventoryGridCell({super.key, required this.slot});

  @override
  Widget build(BuildContext context) {
    final item = slot.item;
    final engine = context.read<GameEngine>();
    final hasDur = slot.maxDurability > 0;
    final durRatio = hasDur ? slot.currentDurability / slot.maxDurability : 0.0;
    final quality = slot.quality;

    return GameTooltip(
      message: '${item.name}\n${item.description}',
      child: GameCard(
        elevation: 1,
        padding: DSSpace.dense,
        accentColor: quality == null ? null : DSColors.quality(quality),
        onTap: () => _showDetailSheet(context, engine, item),
        child: GestureDetector(
          onLongPress: () => _showActionMenu(context, engine, item),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.icon, style: const TextStyle(fontSize: 32)),
              if (slot.quantity > 1)
                GameChip(
                    label: '×${slot.quantity}',
                    size: GameChipSize.sm,
                    color: DSColors.textMuted),
              if (hasDur)
                Padding(
                  padding: const EdgeInsets.only(top: DSSpace.xs),
                  child: GameProgressBar(
                    progress: durRatio.clamp(0.0, 1.0),
                    color:
                        durRatio < 0.25 ? DSColors.warning : DSColors.success,
                    height: 3,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context, GameEngine engine, Item item) {
    // Implemented in Task 24 (shared with item_dashboard_modal replacement).
  }

  void _showActionMenu(BuildContext context, GameEngine engine, Item item) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isEquippable(item))
              ListTile(
                leading: const Text('⚒'),
                title: const Text('Equip'),
                onTap: () {
                  Navigator.pop(ctx);
                  _equip(engine, item);
                },
              ),
            if (item.type == ItemType.food)
              ListTile(
                leading: const Text('🍴'),
                title: const Text('Use'),
                onTap: () {
                  Navigator.pop(ctx);
                  engine.useItem(item, slot.quality, slot.affixIds);
                },
              ),
            ListTile(
              leading: const Text('🔍'),
              title: const Text('Inspect'),
              onTap: () {
                Navigator.pop(ctx);
                _showDetailSheet(context, engine, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isEquippable(Item item) =>
      item.type == ItemType.tool ||
      item.type == ItemType.weapon ||
      item.type == ItemType.armor;

  void _equip(GameEngine engine, Item item) {
    switch (item.type) {
      case ItemType.weapon:
        engine.equipWeapon(item, slot.quality, slot.affixIds);
        break;
      case ItemType.armor:
        engine.equipArmor(item, slot.quality, slot.affixIds);
        break;
      case ItemType.tool:
        engine.equipTool(item, slot.quality, slot.affixIds);
        break;
      default:
        break;
    }
  }
}
