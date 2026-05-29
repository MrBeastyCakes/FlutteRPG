import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/game/game_card.dart';
import '../../widgets/game/game_avatar.dart';
import '../../widgets/game/game_button.dart';
import 'inventory_filter_state.dart';
import 'inventory_filter_logic.dart';
import 'inventory_grid_cell.dart';

/// Inventory grid — 4-column grid of cells, with empty + no-results states.
class InventoryGrid extends StatelessWidget {
  const InventoryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    final state = context.watch<InventoryFilterState>();
    final allSlots = engine.inventory.slots;

    if (allSlots.isEmpty) {
      return GameCard(
        elevation: 0,
        padding: DSSpace.section,
        child: Column(
          children: [
            const GameAvatar(emoji: '🎒', size: GameAvatarSize.lg),
            const SizedBox(height: DSSpace.sm),
            Text('Your pack is empty.', style: DSText.headingSmall(context)),
            const SizedBox(height: DSSpace.xs),
            Text('Gather, craft, or buy something to fill it up.',
                style: DSText.bodySmall(context)
                    .copyWith(color: DSColors.textMuted),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    final visible =
        applyInventoryFilter(allSlots, state.filter, state.sort, state.query);

    if (visible.isEmpty) {
      return GameCard(
        elevation: 0,
        padding: DSSpace.section,
        child: Column(
          children: [
            Text(
              state.query.isNotEmpty
                  ? 'No items match "${state.query}". Try a different filter or clear search.'
                  : 'No items match this filter.',
              style:
                  DSText.bodySmall(context).copyWith(color: DSColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DSSpace.sm),
            GameButton(
              label: 'Clear filters',
              variant: GameButtonVariant.ghost,
              size: GameButtonSize.sm,
              onPressed: state.clear,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: DSSpace.sm,
        crossAxisSpacing: DSSpace.sm,
        childAspectRatio: 0.85,
      ),
      itemCount: visible.length,
      itemBuilder: (_, i) => InventoryGridCell(slot: visible[i]),
    );
  }
}
