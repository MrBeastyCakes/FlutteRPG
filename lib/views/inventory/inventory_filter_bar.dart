import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../engine/game_engine.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/game/game_input.dart';
import '../../widgets/game/game_chip.dart';
import '../../widgets/game/game_button.dart';
import 'inventory_filter_state.dart';

/// Inventory filter bar — search + filter chips + sort.
class InventoryFilterBar extends StatelessWidget {
  const InventoryFilterBar({super.key});

  String _label(InventoryFilter f) => switch (f) {
        InventoryFilter.all => 'All',
        InventoryFilter.tool => 'Tools',
        InventoryFilter.weapon => 'Weapons',
        InventoryFilter.armor => 'Armor',
        InventoryFilter.food => 'Food',
        InventoryFilter.quest => 'Quest',
      };

  String _sortLabel(InventorySort s) => switch (s) {
        InventorySort.name => 'Name',
        InventorySort.quality => 'Quality',
        InventorySort.type => 'Type',
      };

  bool _hasQuestItems(GameEngine engine) {
    // TODO(implementer): real quest-item predicate. Until confirmed, false.
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    final state = context.watch<InventoryFilterState>();

    final filters = <InventoryFilter>[
      InventoryFilter.all,
      InventoryFilter.tool,
      InventoryFilter.weapon,
      InventoryFilter.armor,
      InventoryFilter.food,
      if (_hasQuestItems(engine)) InventoryFilter.quest,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GameInput(
          hintText: 'Search items...',
          prefixIcon: const Icon(Icons.search),
          onChanged: state.setQuery,
        ),
        const SizedBox(height: DSSpace.sm),
        Wrap(
          spacing: DSSpace.sm,
          runSpacing: DSSpace.sm,
          children: [
            for (final f in filters)
              GameChip(
                label: _label(f),
                size: GameChipSize.sm,
                color: state.filter == f
                    ? DSColors.goldAccent
                    : DSColors.textMuted,
                outlined: state.filter != f,
                onTap: () => state.setFilter(f),
              ),
          ],
        ),
        const SizedBox(height: DSSpace.sm),
        Align(
          alignment: Alignment.centerRight,
          child: GameButton(
            label: 'Sort: ${_sortLabel(state.sort)}',
            icon: Icons.sort,
            variant: GameButtonVariant.ghost,
            size: GameButtonSize.sm,
            onPressed: () => _showSortMenu(context, state),
          ),
        ),
      ],
    );
  }

  void _showSortMenu(BuildContext context, InventoryFilterState state) async {
    final selected = await showModalBottomSheet<InventorySort>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in InventorySort.values)
              ListTile(
                title: Text(_sortLabel(s)),
                onTap: () => Navigator.pop(ctx, s),
              ),
          ],
        ),
      ),
    );
    if (selected != null) state.setSort(selected);
  }
}
