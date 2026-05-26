import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../engine/game_engine.dart';
import '../models/item.dart';
import '../theme/game_theme.dart';

class QuickSlotBar extends StatelessWidget {
  const QuickSlotBar({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = Provider.of<GameEngine>(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: GameTheme.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GameTheme.border, width: 1),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: [
          const Text('Quick:', style: TextStyle(color: GameTheme.textMuted, fontSize: 11)),
          const SizedBox(width: 4),
          for (int i = 0; i < 3; i++) _buildSlot(context, engine, i),
        ],
      ),
    );
  }

  Widget _buildSlot(BuildContext context, GameEngine engine, int index) {
    final itemId = engine.quickslots[index];
    final item = itemId == null ? null : Items.findById(itemId);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () {
          if (item != null) {
            _confirmAndUse(context, engine, index, item);
          } else {
            _showPicker(context, engine, index);
          }
        },
        onLongPress: () => _showPicker(context, engine, index),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: item != null ? GameTheme.accentGold.withOpacity(0.08) : Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: item != null ? GameTheme.accentGold : GameTheme.border,
              width: 1,
            ),
          ),
          child: Center(
            child: item != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.icon, style: const TextStyle(fontSize: 22)),
                      Text(
                        '${index + 1}',
                        style: const TextStyle(color: GameTheme.textMuted, fontSize: 9),
                      ),
                    ],
                  )
                : const Icon(Icons.add, color: GameTheme.textMuted, size: 20),
          ),
        ),
      ),
    );
  }

  static bool _firstUseShown = false;

  void _confirmAndUse(BuildContext context, GameEngine engine, int index, Item item) {
    if (_firstUseShown) {
      engine.useQuickslot(index);
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: GameTheme.cardBg,
        title: const Text('Quick-Slot Use', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Quick-Slot items are consumed on use. Continue?',
          style: TextStyle(color: GameTheme.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _firstUseShown = true;
              Navigator.pop(context);
              engine.useQuickslot(index);
            },
            child: const Text('Use'),
          ),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context, GameEngine engine, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GameTheme.cardBg,
      builder: (_) => _buildPickerSheet(context, engine, index),
    );
  }

  Widget _buildPickerSheet(BuildContext context, GameEngine engine, int index) {
    final foods = engine.inventory.slots
        .where((slot) => slot.item.isFood)
        .toList();
    return ListView(
      shrinkWrap: true,
      children: [
        const ListTile(title: Text('Set Quick-Slot', style: TextStyle(color: Colors.white))),
        if (engine.quickslots[index] != null)
          ListTile(
            leading: const Icon(Icons.close, color: GameTheme.healthRed),
            title: const Text('Clear slot', style: TextStyle(color: GameTheme.textLight)),
            onTap: () {
              engine.setQuickslot(index, null);
              Navigator.pop(context);
            },
          ),
        if (foods.isEmpty)
          const ListTile(
            title: Text('No food in inventory', style: TextStyle(color: GameTheme.textMuted, fontSize: 13)),
          ),
        for (final slot in foods)
          ListTile(
            leading: Text(slot.item.icon, style: const TextStyle(fontSize: 22)),
            title: Text(slot.item.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text('+${slot.item.healAmount} HP, +${slot.item.energyAmount} energy',
                style: const TextStyle(color: GameTheme.textMuted)),
            trailing: Text('×${slot.quantity}', style: const TextStyle(color: GameTheme.textMuted)),
            onTap: () {
              engine.setQuickslot(index, slot.item.id);
              Navigator.pop(context);
            },
          ),
      ],
    );
  }
}
