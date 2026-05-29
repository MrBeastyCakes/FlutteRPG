import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../models/item.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/game/game_card.dart';

/// Quickslot Bar — 3 inline food slots; one tap consumes (no popover).
class QuickslotBar extends StatelessWidget {
  const QuickslotBar({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    return Row(
      children: [
        for (int i = 0; i < 3; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DSSpace.xs),
              child: _QuickslotCell(index: i, engine: engine),
            ),
          ),
      ],
    );
  }
}

class _QuickslotCell extends StatelessWidget {
  final int index;
  final GameEngine engine;
  const _QuickslotCell({required this.index, required this.engine});

  @override
  Widget build(BuildContext context) {
    final id = engine.quickslots[index];
    final item = id == null ? null : Items.findById(id);
    final isSelected = engine.activeCombat?.pendingQuickslotIndex == index;

    if (item == null) {
      return GameCard(
        elevation: 0,
        padding: DSSpace.dense,
        child: Center(
          child: Text('Empty',
              style:
                  DSText.label(context).copyWith(color: DSColors.textDisabled)),
        ),
      );
    }

    return GameCard(
      elevation: 1,
      padding: DSSpace.dense,
      accentColor: isSelected ? DSColors.borderAccent : null,
      onTap: () => engine.useQuickslot(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item.icon, style: const TextStyle(fontSize: 24)),
          Text(item.name,
              style: DSText.label(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text('+${item.healAmount}❤ +${item.energyAmount}⚡',
              style: DSText.label(context).copyWith(color: DSColors.textMuted)),
        ],
      ),
    );
  }
}
